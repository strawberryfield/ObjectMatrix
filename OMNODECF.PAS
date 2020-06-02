{$F+,O+}

unit omnodecf;
{ configurazione per compilazione della nodelist }

interface

procedure NodeListCfg;
procedure ClearNodelistCfg;

implementation

uses inifile,omnodevr,bbsconf,objects;

procedure scan(st,par : string; var err : boolean);
label endloop;
var p1,p2 : string;
    c,x : word;
    a : boolean;
begin
err := false;
splitstat(par,' ',p1,p2);

if st = 'DIAL' then begin
  dt^.insert(new(PDialTable,init(p1,p2)));
  goto endloop;
  end;

if st = 'DEFAULTCOST' then begin
  val(p1,dc,x);
  goto endloop;
  end;

if st = 'DEFAULTPREFIX' then begin
  dp := newstr(p1);
  goto endloop;
  end;

if st = 'COST' then begin
  val(p2,c,x);
  ct^.insert(new(PCostTable,init(p1,c)));
  goto endloop;
  end;

if st = 'MODEMTYPE' then begin
  val(p2,c,x);
  mt^.insert(new(PCostTable,init(p1,c)));
  goto endloop;
  end;

if st = 'NODELISTPATH' then begin
   path := getpath(p1);
   goto endloop;
   end;

if st = 'MYLIST' then begin
   ml^.insert(newstr(p1));
   goto endloop;
   end;

if st = 'FORCEZONE' then begin
   fz := IsTrue(p1);
   goto endloop;
   end;

if st = 'VERSION6' then begin
   v6 := IsTrue(p1);
   goto endloop;
   end;

if st = 'TEXTLIST' then begin
   hrlist := IsTrue(p1);
   goto endloop;
   end;

if st = 'FIDOUSER' then begin
   fu := IsTrue(p1);
   goto endloop;
   end;

a := ni^.config(st,p1,p2);

endloop:
end;


procedure NodeListCfg;
var ini : PIni;
begin
new(dt,init(10,2));
new(ct,init(10,2));
new(mt,init(2,2));
new(ml,init(2,1));
new(ni,init);
if not inistart(ini) then exit;
if iniparse(ini,'NODELIST',scan) then exit;
dispose(ini,done);
if path = nil then path := newstr('.\');
end;

procedure ClearNodelistCfg;
begin
if dt <> nil then dispose(dt,done);
if ct <> nil then dispose(ct,done);
if mt <> nil then dispose(mt,done);
if ml <> nil then dispose(ml,done);
if dp <> nil then disposestr(dp);
if ni <> nil then dispose(ni,done);
disposestr(path);
end;

end.