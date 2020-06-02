{$M 20480 30000 655360}
{$ifdef ovr}
  {$F+}
  {$endif}

program Object_Matrix;

uses
  bbsinit,omparse,bbsconf,omapp,bbsstart,ompack2,swkey
  {$ifdef ovr}  ,overlay  {$endif}
  ;

{$ifdef ovr}
  {$O ompack2}
  {$O omkill}
  {$O ompost}
  {$O omunpack}
  {$O omattach}
  {$O omclean}
  {$O omnode}
  {$O omnodevr}
  {$O omnodecf}
  {$O omtools}
  {$O omdmail}
  {$O qbase}
  {$O omquinex}
  {$O omparse}
  {$O omapp}
  {$O omhlpparser}
  {$O omdump}
  {$O ompackcf}
  {$O omobj}

  {$I bbsovl.inc}
  {$endif}


{ procedura di uscita del programma principale
  serve a tenere il log degli errori }

{$F+}
procedure uscita;
begin
exitproc := olduscita;
termina;
end;

begin
IsInteractive := (paramcount = 0) or
                 (paramstr(1) = '/?') or
                 (paramstr(2) = '?');
prgname := 'ObjectMatrix';
prgver := '2.00';
prgspot := 'Tool di integrazione per sistemi Fidonet compatibili';
prgCopyright := '(c) 1991-1992 Roberto Ceccarelli';
writeln(prgbanner,' - ',prgCopyright);
writeln(prgspot);
writeln;
init;

{$ifdef ovr}
StartOverlay;
if IsInteractive then OvrSetBuf(80 * 1024) else OvrSetBuf(20 * 1024);
{$endif}

readlng;
RegisterOmPack;
new(logf,init('obma'));
readcfg;
keynum := decode(keystr,sysop^);
If IsInteractive then begin
  a := new(POmApp,init);
  fsiinit;
  end;

olduscita := exitproc;
exitproc := @uscita;

startup;
if not IsInteractive then ParseCmdLine;

end.
