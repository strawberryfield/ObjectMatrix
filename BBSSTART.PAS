{$F+,O+}

unit bbsStart;
{ Procedure di avvio dei programmi OM-Engine }

interface

uses bbsapp;

var a : PBbsApp;
    IsInteractive : boolean;

procedure fsiinit;
procedure termina;
procedure startup;
procedure readlng;

implementation

uses  bbsinit,stringhe,textview,objects;

procedure fsiinit;
begin
with a^.banner^ do begin
  newline(0,prgbanner+' - '+prgcopyright);
  newline(1,prgspot);
  end;
close(logf^.scr);
AssignDevice(logf^.scr,a^.activity^.t);
rewrite(logf^.scr);
end;

{ procedura di uscita del programma principale
  serve a tenere il log degli errori }

procedure termina;
var datierr : array[1..3] of longint;
begin
logf^.quiet := false;

if erroraddr <> nil then begin
  datierr[1] := exitcode;
  datierr[2] := seg(erroraddr);
  datierr[3] := ofs(erroraddr);
  logf^.printf(0,lang^.get(msgRunError),datierr);
  logf^.print(0,errors^.get(exitcode));
  erroraddr := nil;
  exitcode := 255;
  end
else exitcode := omexitcode;

datierr[1] := exitcode;
if exitcode <> 0 then
  logf^.printf(3,lang^.get(msgExitCode),datierr);

if not IsRegistered then
  logf^.print(0,'Trova il tempo per registrarti!');

dispose(logf,done);
dispose(lang,done);
dispose(errors,done);
if IsInteractive then dispose(a,done);
res.done;
end;

procedure readlng;
var name : string;
    f : file;
begin
RegisterObjects;
RegisterType(RStringList);

{ Carica il file di linguaggio }

name := prgpath+prgfile+'.lng';
assign(f,name);
{$I-}
reset(f);
{$I+}
if ioresult <> 0 then name := paramstr(0) else close(f);
res.init(new(PBufStream,init(name,stOpenRead,2048)));
lang := PStringList(res.get('stringhe'));
errors := PStringList(res.get('errori'));
end;

procedure startup;
label quit;
begin
if IsInteractive then
  if IsRegistered then a^.banner^.newline(2,'Versione Registrata a '+sysop^)
  else a^.banner^.newline(2,'Versione Dimostrativa non registrata!')
else begin
  if IsRegistered then writeln('Versione Registrata a '+sysop^)
  else writeln('Versione Dimostrativa non registrata!');
  writeln;
  end;

if (paramcount = 0) then begin
  a^.run;
  goto quit;
  end;

if (paramstr(1) = '/?') then begin
  a^.dohelp('GLOBAL');
  a^.run;
  goto quit;
  end;

if paramstr(2) = '?' then begin
  a^.dohelp(uppercase(paramstr(1)));
  a^.run;
  goto quit;
  end;

quit:
end;

end.
