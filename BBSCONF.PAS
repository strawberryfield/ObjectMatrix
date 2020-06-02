{$F+,O+,X+}

unit bbsconf;
{ inizializzazioni e configurazione standard }

interface

uses inifile;

procedure readcfg;

function inistart(var ini : PIni) : boolean;
function iniparse(var ini : PIni; section : string; f : scanproc) : boolean;

implementation

uses drivers,ifna,address,bbsinit,objects;

{ Errore non recuperabile }

procedure Abort(msg : word);
begin
logf^.print(0,lang^.get(msg));
logf^.done;
halt(10);
end;

{ Lettura della configurazione }

{$F+}
procedure scancfgfile(st,par : string; var error : boolean);
label endloop;
begin
error := false;

if st = 'AKA' then begin
   akas^.insert(new(paddress,get(par)));
   goto endloop;
   end;

if st = 'MSGPATH' then begin
   msgpath := getpath(par);
   goto endloop;
   end;

if st = 'OUTBOUND' then begin
   outbound := getpath(par);
   goto endloop;
   end;

if st = 'INBOUND' then begin
   inbound := getpath(par);
   goto endloop;
   end;

if st = 'SYSOP' then begin
   sysop := newstr(par);
   goto endloop;
   end;

if st = 'SYSTEM' then begin
   systemname := newstr(par);
   goto endloop;
   end;

if myaddress^.config(st,par) then goto endloop;

{ non restituisce piu' errori dalla 1.15 per poter leggere
  i dati anche solo parzialmente }
{ error := true; }
endloop:
end;

procedure scan4log(st,par : string; var error : boolean);
begin
error := not logf^.config(st,par);
end;

procedure scankey(st,par : string; var error : boolean);
begin
error := false;
if st = 'KEY' then keystr := copy(par,1,12);
end;
{$F-}


procedure readcfg;
var Ini : PIni;
begin
{ Inizializza con valori nulli le stringhe obbligatorie }

sysop := nil;
systemname := nil;
new(myaddress,init);
new(akas,init(5,1));

{ Registra i tipi per gli stream }

RegisterAddress;

{ Legge il file di configurazione }

if not inistart(ini) then exit;
if not iniparse(ini,'SYSTEM',scancfgfile) then exit;
if not iniparse(ini,'LOGFILE',scan4log) then exit;
ini^.parsesection(prgname,scankey);
dispose(ini,done);
if sysop = nil then abort(msgNoSysop);
if systemname = nil then abort(msgNoSystem);
if msgpath = nil then abort(msgNoMsgpath);
if outbound = nil then abort(msgNoOutbound);
if myaddress^.complete = nil then abort(msgNoAddress);
end;

function inistart(var ini : PIni) : boolean;
var p : PString;
begin
p := newstr(prgpath+prgfile+'.ini');
new(ini,init(p^));
if ini^.error = 1 then begin
  logf^.printf(0,lang^.get(msgNoCfgFile),p);
  inistart := false;
  end
else inistart := true;
end;

function iniparse(var ini : PIni; section : string; f : scanproc) : boolean;
var p : pointer;
begin
ini^.parsesection(section,f);
p := @section;
iniparse := false;
case ini^.error of
  2 : logf^.printf(0,lang^.get(msgNoCfgSection),p);
  3 : logf^.printf(0,lang^.get(msgUnkStatement),p);
  else iniparse := true;
  end;
end;

end.
