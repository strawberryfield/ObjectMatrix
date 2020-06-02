{$F+,O+}

unit bbsinit;
{ gruppo di variabili comuni e relative inizializzazioni }

interface

uses objects,dos,logfile;

var prgname, prgver, prgCopyright, prgSpot : string;

const keynum : longint = 0;
      keystr : string[12] = '';

      { ** Definizioni codici messaggi ** }

      msgUnkCmdLine   = 10;
      msgNumProcessed = 11;
      msgRunError     = 12;
      msgExitCode     = 13;
      msgFewParam     = 14;
      msgBeginScript  = 15;
      msgUnkScript    = 16;

      msgNoSysop    = 60;
      msgNoSystem   = 61;
      msgNoMsgPath  = 62;
      msgNoOutbound = 63;
      msgNoAddress  = 64;
      msgNoCfgFile  = 65;
      msgNoCfgSection = 66;
      msgUnkStatement = 67;


procedure init;
function prgsign : string;
function regnumstr : string;
function prgpid : string;
function prgtear : string;
function PrgBanner : string;
function IsRegistered : boolean;
function FileExists(s : string) : boolean;

      { ** Definizioni per le procedure di uscita ** }

const omexitcode : byte = 0;
var olduscita : pointer;

    sysop,systemname : Pstring;
    prgpath : dirstr;
    prgfile : namestr;
    Akas : Pcollection;
    logf : PLogFido;
    lang,errors : PStringList;
    res : TResourceFile;

implementation

uses drivers,stringhe;

procedure init;
var e : extstr;
    s : string;
begin
if lo(dosversion) < 3 then begin
  writeln('This Hi-Tech Program requires DOS 3.0 or newer!');
  halt(255);
  end;
fsplit(paramstr(0),prgpath,prgfile,e);
s := prgpath;
if s[length(s)] = '\' then dec(s[0]);
chdir(s);
end;


function regnumstr : string;
var s : string;
begin
if keynum = 0 then s := 'NR' else formatstr(s,'%05d',keynum);
regnumstr := '['+s+']';
end;

function IsRegistered : boolean;
begin
IsRegistered := keynum <> 0;
end;

function prgsign : string;
begin
prgsign := uppercase(prgfile)+' '+prgver+' '+regnumstr;
end;

function prgpid : string;
begin
prgpid := #01 + 'PID: ' + prgsign;
end;

function prgtear : string;
begin
prgtear := '--- ' + prgbanner + ' ' + regnumstr;
end;

function prgbanner : string;
begin
prgbanner := 'CASASOFT ' + prgname + ' v.' + prgver;
end;

function FileExists(s : string) : boolean;
var sr : SearchRec;
begin
findfirst(s,Archive,sr);
FileExists := doserror = 0;
end;

end.
