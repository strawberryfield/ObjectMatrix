{ CASASOFT ObjectMatrix Engine
  file da includere in caso di compilazione con overlay

  contiene l'elenco delle unit da mettere in overlay e la
  procedura di inizializzazione del sistema  }

  {$O bbsstart}
  {$O ifna}
  {$O address}
  {$O objects}
  {$O bbsconf}
  {$O inifile}
  {$O logfile}

  {$O app}
  {$O bbsapp}
  {$O views}
  {$O menus}
  {$O bbsdia}
  {$O bbslib}
  {$O helpfile}
  {$O dialogs}
  {$O fviewer}
  {$O msgbox}
  {$O bbshlpparser}
  {$O desk}
  {$O mousedlg}
  {$O colorsel}
  {$O textview}
  {$O histlist}
  {$O datestr}
  {$O stringhe}
  {$O popinput}
  {$O stddlg}
  {$O shellcfg}
  {$O bbslogo}

procedure StartOverlay;
var OvrName : string[79];
    f : boolean;
begin
OvrInit(prgpath+prgfile+'.ovr');
if OvrResult <> ovrOk then begin
  OvrName := paramstr(0);
  f := true;
  Repeat
    OvrInit(OvrName);
    if OvrResult <> ovrOk then begin
      if f then
        writeln('CASASOFT ObjectMatrix Engine 1.00 Overlay manager');
      case OvrResult of
        -1 : begin
             writeln('General failure: program halted.');
             halt(255);
             end;
        -2 : begin
             writeln;
             writeln('Overlay file not found!');
             if f then begin
               writeln('Program has searched for:');
               writeln(paramstr(0));
               writeln(prgpath+prgfile+'.ovr');
               writeln;
               f := false;
               end;
             writeln('Please enter correct overlay file name (Enter = Abort)');
             write(' => ');  readln(OvrName);
             if OvrName = '' then halt(254);
             end;
        end;
      end;
    until OvrResult = ovrOk;
end;

OvrInitEms;
if OvrResult = ovrOk then
  writeln('EMS memory initialized')
else case OvrResult of
  ovrNoEmsDriver : writeln('EMS memory not found: use disk swapping');
  ovrNoEmsMemory : writeln('EMS memory insufficient: use disk swapping');
  end;
end;

