{$O+,F+}

unit omkill;

interface

uses objects;

const msgKilling       = 50;
      msgKilled        = 51;
      msgKillingL      = 52;
      msgKilledF       = 53;
      msgKFile         = 54;
      msgTotKilled     = 55;
      msgTotTrunc      = 56;
      msgTFile         = 57;
      msgFileNotFound  = 58;

      msgPurgeSent     = 150;
      msgPurgeReceived = 151;

procedure killer(s : string);
procedure purge(s : string);
procedure killCollection(c : PstringCollection);
procedure truncCollection(c : PstringCollection);

implementation

uses ifna,omobj,stringhe,address,inifile,bbsinit;

var Klist : PstringCollection;

type Pkiller = ^Tkiller;
     Tkiller = object(TIterable)
       c : PstringCollection;
       constructor init;
       procedure dojob(m : pmessage); virtual;
       destructor done; virtual;
       end;

     PFalqui = ^TFalqui;
     TFalqui = object(TKiller)
       constructor init(cf : condfunct);
       procedure dojob(m : PMessage); virtual;
       end;

var tk : string;

{ Funzioni per la scelta dei messaggi da cancellare }

function ToKill(m : pmessage) : boolean;
var s : string;

  function Check(item : Pstring) : boolean;
  begin
  Check := beginof(item^,s);
  end;

begin
s := uppercase(m^.h^.mitt^);
if tk <> '' then ToKill := ToMe(m) and BeginOf(tk,s)
else ToKill := ToMe(m) and (Klist^.FirstThat(@check) <> nil);
end;

function isSent(m : PMessage) : boolean;
begin
isSent := (m^.h^.attribute and fSent) <> 0;
end;

function isReceived(m : PMessage) : boolean;
begin
isReceived := (m^.h^.attribute and fReceived) <> 0;
end;

{ Implementazione degli iteratori }

constructor Tkiller.init;
begin
new(c,init(10,2));
Titerable.init(ToKill);
end;

procedure Tkiller.dojob(m : pmessage);
var s : string;
    p : pointer;
begin
with m^.h^ do begin
  if tk = '' then logf^.printf(3,lang^.get(msgKilledF),mitt);
  logf^.printf2s(3,lang^.get(msgKilled),orig.getstr,dest^);
  end;
c^.insert(newstr(m^.name^));
end;

destructor Tkiller.done;
begin
killCollection(c);
dispose(c,done);
Titerable.done;
end;

constructor TFalqui.init(cf : condfunct);
begin
new(c,init(10,2));
Titerable.init(cf);
end;

procedure TFalqui.dojob(m : pmessage);
begin
c^.insert(newstr(m^.name^));
end;

{ Procedura che cancella effettivamente i messaggi della lista }

procedure killCollection(c : PstringCollection);
var tk : longint;

  procedure kill(p : pstring); far;
  var f : file;
  begin
  assign(f,p^);
  {$I-}
  erase(f);
  {$I+}
  if ioresult = 0 then begin
    logf^.printf(3,lang^.get(msgKFile),p);
    inc(tk);
    end
  else  logf^.printf(0,lang^.get(msgFileNotFound),p);
  end;

begin
tk := 0;
c^.foreach(@kill);
logf^.printf(2,lang^.get(msgTotKilled),tk);
if tk > 0 then omexitcode := 1;
end;

procedure truncCollection(c : PstringCollection);
var tk : longint;

  procedure trunc(p : pstring); far;
  var f : file;
  begin
  assign(f,p^);
  {$I-}
  reset(f);
  {$I+}
  if ioresult = 0 then begin
    logf^.printf(3,lang^.get(msgTFile),p);
    system.truncate(f);
    close(f);
    inc(tk);
    end
  else  logf^.printf(0,lang^.get(msgFileNotFound),p);
  end;

begin
tk := 0;
c^.foreach(@trunc);
logf^.printf(2,lang^.get(msgTotTrunc),tk);
if tk > 0 then omexitcode := 1;
end;

{$F+}
procedure namelist(st,par : string; var error : boolean);
begin
error := false;
klist^.insert(newstr(st));
end;
{$F-}

{ Procedure di interfaccia esterna }

procedure killer(s : string);
var job : Pkiller;
    p : pointer;
    ini : PIni;
begin
tk := uppercase(s);
new(klist,init(5,2));
new(ini,init(prgpath+prgfile+'.ini'));
if ini^.error = 0 then begin
  ini^.scansection('KILL',' ',namelist);
  if ini^.error = 0 then dispose(ini,done);
  end;
if (s = '') and (Klist^.count = 0) then tk := 'ARCMAIL';
if tk = '' then logf^.print(1,lang^.get(msgKillingL))
else begin
  p := @tk;
  logf^.printf(1,lang^.get(msgKilling),p);
  end;
new(job,init);
iterate(job);
dispose(job,done);
dispose(klist,done);
end;

procedure purge(s : string);
var job : PFalqui;
begin
case UpCase(s[1]) of
  'S' : begin
        logf^.print(1,lang^.get(msgPurgeSent));
        new(job,init(isSent));
        end;
  'R' : begin
        logf^.print(1,lang^.get(msgPurgeReceived));
        new(job,init(isReceived));
        end;
   else exit;
   end;
iterate(job);
dispose(job,done);
end;

end.
