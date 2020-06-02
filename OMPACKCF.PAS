{$F+,O+}

unit ompackcf;

interface

procedure GetPackerConfig(s : string);

implementation

uses inifile,omobj,ompack2,ifna,address,bbsconf;

{ Lettura della configurazione }

{$F+}
procedure scancfgfile(st,par : string; var error : boolean);
label endloop;
begin
error := false;

if st = 'BOSS' then begin
   myboss.putstr(par);
   goto endloop;
   end;

if st = 'UPLINK' then begin
   myboss.putstr(par);
   goto endloop;
   end;

if st = 'NOROUTE' then begin
   noroute^.insert(new(PAddress,get(par)));
   goto endloop;
   end;

if st = 'CRASH' then begin
   crashl^.insert(new(PAddress,get(par)));
   goto endloop;
   end;

if st = 'HOLD' then begin
   holdl^.insert(new(PAddress,get(par)));
   goto endloop;
   end;

endloop:
end;
{$F-}

procedure GetPackerConfig(s : string);
var Ini : PIni;
begin
myboss.putstr(myaddress^.complete^);
if not inistart(ini) then exit;
if not iniparse(ini,'PACKER',scancfgfile) then exit;
if s <> '' then if not iniparse(ini,'SCHEDULE '+s,scancfgfile) then exit;
dispose(ini,done);

with myboss do
  if myaddress^.equal(zone,net,node,point) then begin
    if point <> 0 then point := 0 else node := 0;
    end;
end;

end.