{$F+,O+,X+}

unit bbsapp;

interface

uses  app,objects,drivers,views,dialogs,gadgets,bbsdia,bbslib,menus,
      bbshlpparser,dos;

const msgNoHelp   = 501;
      msgTypeExit = 502;
      msgReadCfg  = 503;

type PBbsApp = ^TBbsApp;
     TBBsApp = object(TApplication)
       activity : Pactivity;
       clock : PClockView;
       heap : PHeapView;
       banner : PBanner;
       helpList : PBbsHelpList;
       constructor init;
       destructor done; virtual;
       procedure ShowHelp(AhelpCtx : word);
       procedure dohelp(sh : string);
       procedure savedesk(s : string);
       procedure loaddesk(s : string);
       function GetFile(WildCard,Title : PathStr) : string;
       procedure DosShell(prg : string);
       procedure GetEvent(var Event: TEvent); virtual;
       procedure handleevent(var Event : TEvent); virtual;
       procedure InitStatusLine; virtual;
       procedure InitBanner(s1,s2,s3 : string);
       procedure viewdump(f : string);
       procedure about;
       function GetPalette : PPalette; virtual;
       procedure idle; virtual;
       procedure OutOfMemory; virtual;
       end;

     PBbsStatusLine = ^TBbsStatusLine;
     TBbsStatusLIne = object(TStatusLine)
       function hint(AHelpCtx : word) : string; virtual;
       end;

function SystemMenu(next : PMenuItem) : PMenuItem;
function DeskTopMenu(next : PMenuItem) : PMenuItem;
function HelpMenu(next : PMenuItem) : PMenuItem;
function WindowsMenu(next : PMenuItem) : PMenuItem;

implementation

uses fviewer,helpfile,msgbox,desk,memory,bbshc,bbsinit,stddlg,
     shellcfg,bbslogo;

const CBbsColor = CColor + CHelpColor + CbannerColor;
      CBbsBlackWhite = CBlackWhite + CHelpBlackWhite + CBannerBlackWhite;
      CBbsMonochrome = CMonochrome + CHelpMonochrome + CBannerMonochrome;

type TDeskData = record
       MouseDelay : word;
       MouseReverse : boolean;
       Palette : string;
       VideoMode : word;
       end;


var ds : PStringList;

function TBbsStatusLine.hint(AHelpCtx : word) : string;
begin
if AHelpCtx < 3000 then hint := lang^.get(AHelpCtx)
else hint := ds^.get(AHelpCtx);
end;


function CalcHelpName: PathStr;
begin
calchelpname := prgpath+prgfile+'.hlp';
end;

constructor TBbsApp.init;
var r : Trect;
    s : string;
begin
Tapplication.init;
RegisterMenus;
RegisterViews;
RegisterHelpFile;
RegisterApp;
RegisterFViewer;
RegisterDialogs;

ds := PStringList(res.get('desktop'));
InitBanner('','',lang^.get(msgReadCfg));
desktop^.insert(banner);

{ Inizializza finestra logfile }

desktop^.getextent(r);
dec(r.b.y,3);
new(Activity,init(r));
desktop^.insert(Activity);

GetExtent(R);
R.A.X := R.B.X - 9; R.B.Y := R.A.Y + 1;
Clock := New(PClockView, Init(R));
Insert(Clock);

desktop^.GetExtent(R);
dec(r.b.x);
r.a.y := pred(r.b.y);
r.a.x := r.b.x - 7;
Heap := New(PHeapView, Init(R));
heap^.growmode := gfGrowAll;
desktop^.Insert(Heap);

sethelp(HelpList);
if FileExists(prgpath+prgfile+'.dsk') then loaddesk(prgpath+prgfile+'.dsk');

s := logoname;
if s <> '' then dosshell(s) else about;
end;

destructor TBBsApp.done;
begin
dispose(ds,done);
TApplication.done;
end;

procedure TBbsApp.ShowHelp(AhelpCtx : word);
var W: PWindow;
    HFile: PHelpFile;
    HelpStrm: PDosStream;
const HelpInUse: Boolean = False;
begin
if not HelpInUse then begin
  HelpInUse := True;
  HelpStrm := New(PDosStream, Init(CalcHelpName, stOpenRead));
  HFile := New(PHelpFile, Init(HelpStrm));
  if HelpStrm^.Status <> stOk then begin
    MessageBox(lang^.get(msgNoHelp), nil, mfError + mfOkButton);
    Dispose(HFile, Done);
    end
  else begin
    W := New(PHelpWindow,Init(HFile, AHelpCtx));
    if ValidView(W) <> nil then begin
      ExecView(W);
      Dispose(W, Done);
      end;
    end;
  HelpInUse := False;
  end;
end;

procedure TBbsApp.dohelp(sh : String);
begin
showhelp(HelpList^.findhelp(sh));
end;

procedure TBbsApp.savedesk(s : string);
var f : file of TDeskData;
    d : TDeskData;
begin
d.MouseDelay := DoubleDelay;
d.MouseReverse := MouseReverse;
d.palette := application^.getpalette^;
d.videomode := ScreenMode;
assign(f,s);
rewrite(f);
write(f,d);
close(f);
end;

procedure TBbsApp.loaddesk(s : string);
var f : file of TDeskData;
    d : TDeskData;
begin
assign(f,s);
reset(f);
read(f,d);
close(f);
setScreenMode(d.videomode);
DoubleDelay := d.MouseDelay;
MouseReverse := d.MouseReverse;
application^.getpalette^ := d.palette;
end;

function TBbsApp.GetFile(WildCard,Title : PathStr) : string;
var d : PFileDialog;
begin
getfile := '';
d := new(PFileDialog,
  init(WildCard,Title,'~N~ame',fdOkButton,1));
if desktop^.execview(d) <> cmCancel then begin
  d^.getfilename(wildcard);
  GetFile := WildCard;
  end;
dispose(d,done);
end;

procedure TBbsApp.DosShell(prg : string);

  procedure runprg;
  var j : integer;
      arg : string;
      path : dirstr;
      name : namestr;
      ext : extstr;
  begin
  j := pos(' ',prg);
  if j = 0 then arg := ''
  else begin
    arg := copy(prg,succ(j),255);
    prg := copy(prg,1,pred(j));
    end;
  fsplit(prg,path,name,ext);
  if path[length(path)] = '\' then dec(path[0]);
  getdir(0,prg);
  chdir(path);
  exec(name+ext,arg);
  chdir(prg);
  end;

begin
DoneSysError;
DoneEvents;
DoneVideo;
DoneMemory;
SetMemTop(HeapPtr);
if prg = '' then PrintStr(lang^.get(msgTypeExit)+#13#10);
SwapVectors;
if prg = '' then Exec(GetEnv('COMSPEC'), '')
else runprg;
SwapVectors;
SetMemTop(HeapEnd);
InitMemory;
InitVideo;
InitEvents;
InitSysError;
Redraw;
end;

procedure TBbsApp.GetEvent(var Event: TEvent);
begin
TApplication.GetEvent(Event);
case Event.What of
  evCommand: if Event.Command = hcHelp then begin
    clearevent(event);
    showhelp(Gethelpctx);
    end;
  evMouseDown: if Event.Buttons <> 1 then Event.What := evNothing;
  end;
end;


procedure TBbsApp.handleevent(var Event : TEvent);
var control : word;

  procedure Tile;
  var R: TRect;
  begin
  Desktop^.GetExtent(R);
  Desktop^.Tile(R);
  end;

  procedure Cascade;
  var R: TRect;
  begin
  Desktop^.GetExtent(R);
  Desktop^.Cascade(R);
  end;


var args,labels : string;
begin
TApplication.handleevent(Event);
if event.what = evCommand then begin
  case event.command of

    hcHelp : showhelp(gethelpctx);

    hcHelpOnHelp : showhelp(10000);

    hcHelpIndex : showhelp(10001);

    hcGlobalHelp : showhelp(0);

    hcAbout : About;

    hcDosShell : DosShell('');

    hcExternal : begin
      args := GetShell;
      if args <> '' then DosShell(args);
      end;

    hcRemark : begin
      labels := '6Testo da inserire';
      args := '';
      case MultiDialog(labels,args,1,'Annotazione nel LogFile') of
        cmOk,cmDefault : logf^.print(0,args);
        end;
      end;


    hcVideoMode : begin
      control := ScreenMode xor smFont8x8;
      if control and smFont8x8 <> 0 then  ShadowSize.X := 1
      else ShadowSize.X := 2;
      SetScreenMode(control);
      end;

    hcMouseDlg : mouse;

    hcColors : begin
      colors(ds);
      redraw;
      end;

    hcTile : Tile;

    hcCascade : Cascade;

    hcSaveDesk : savedesk(getfile('*.dsk','Save Desktop'));

    hcLoadDesk : loaddesk(getfile('*.dsk','Load Desktop'));

    else exit;
    end;

  clearevent(event);
  end;
end;


procedure TBbsApp.viewdump(f : string);
var s : Pathstr;
    w : PWindow;
begin
s := copy(prgpath+f,1,pred(sizeof(pathstr)));
w := new(PFileWindow,init(s));
w^.helpCtx := hcInViewer;
if validview(w) <> nil then desktop^.insert(w);
end;

procedure TBbsApp.About;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 40, 11);
  D := New(PDialog, Init(R, 'Info '+prgName));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Grow(-1, -1);
    Dec(R.B.Y, 3);
    Insert(New(PStaticText, Init(R, #13+
    ^C+prgbanner+#13#13+
    ^C+prgcopyright)));

    R.Assign(15, 8, 25, 10);
    Insert(New(PButton, Init(R, 'O~K', cmOk, bfDefault)));
  end;
  if ValidView(D) <> nil then
  begin
    Desktop^.ExecView(D);
    Dispose(D, Done);
  end;
end;

function TBbsApp.GetPalette: PPalette;
const P: array[apColor..apMonochrome] of string[Length(CBbsColor)] =
    (CBbsColor, CBbsBlackWhite, CBbsMonochrome);
begin
  GetPalette := @P[AppPalette];
end;

procedure TBbsApp.initBanner(s1,s2,s3 : string);
var r : TRect;
begin
desktop^.getextent(r);
r.a.y := r.b.y - 3;
new(banner,init(r,s1,s2,s3));
end;

procedure TBbsApp.idle;
begin
TApplication.idle;
clock^.update;
heap^.update;
end;

procedure TBbsApp.OutOfMemory;
begin
MessageBox('Memoria insufficiente', nil, mfError + mfOkButton);
end;

procedure TBbsApp.InitStatusLine;
var r : Trect;
begin
getextent(r);
r.a.y := r.b.y - 1;
StatusLine := new(PBbsStatusLine,init(r,
  NewStatusDef(0,999,
    NewStatuskey('~F1~ Help',kbF1,hcHelp,
    NewStatuskey('~F10~ Menu',kbF10,cmMenu,
    NewStatuskey('~Alt-X~ Exit',kbAltX,cmQuit,nil))),
  NewStatusDef(1000,3099,
    NewStatuskey('~F1~ Help',kbF1,hcHelp,
    NewStatuskey('~Alt-X~ Exit',kbAltX,cmQuit,nil)),
  NewStatusDef(3100,3100,
    NewStatuskey('~F1~ Help',kbF1,hcHelp,
    NewStatuskey('~Alt-F3~ Close',kbAltF3,cmClose,
    NewStatuskey('~F5~ Zoom',kbF5,cmZoom,
    NewStatuskey('~Ctrl-F5~ Resize',kbCtrlF5,cmResize,
    NewStatuskey('~Alt-X~ Exit',kbAltX,cmQuit,nil))))),
  NewStatusDef(3101,$ffff,
    NewStatuskey('~F1~ Help',kbF1,hcHelp,
    NewStatuskey('~F10~ Menu',kbF10,cmMenu,
    NewStatuskey('~Alt-X~ Exit',kbAltX,cmQuit,nil))),
  nil))))));
end;

function SystemMenu(next : PMenuItem) : PMenuItem;
begin
SystemMenu :=
  newsubmenu('~ð~',hcSystemMenu,newmenu(
    newitem('~I~nfo...','',0,hcAbout,hcAbout,
    newline(
    DesktopMenu(
    WindowsMenu(
    Newline(
    newitem('~R~emark...','',0,hcRemark,hcRemark,
    newitem('~E~xternal...','Alt-F10',kbAltF10,hcExternal,hcExternal,
    newitem('~D~os shell','',0,hcDosShell,hcDosShell,
    newline(
    newitem('E~x~it','Alt-X',kbAltX,cmQuit,hcQuit,
    nil))))))))))),
  next);
end;

function DeskTopMenu(next : PMenuItem) : PMenuItem;
begin
DeskTopMenu :=
  newsubmenu('Des~k~top',hcDeskMenu,newmenu(
    NewItem('~V~ideo Mode','',0,hcVideoMode,hcVideoMode,
    NewItem('~M~ouse','',0,hcMouseDlg,hcMouseDlg,
    NewItem('~C~olors','',0,hcColors,hcColors,
    newline(
    NewItem('~S~ave options','',0,hcSaveDesk,hcSaveDesk,
    NewItem('~L~oad options','',0,hcLoadDesk,hcLoadDesk,  nil))))))),
    next);
end;

function HelpMenu(next : PMenuItem) : PMenuItem;
begin
HelpMenu :=
  newsubmenu('~H~elp',hcHelpMenu,newmenu(
    NewItem('~G~eneral','',0,hcGlobalHelp,hcGlobalHelp,
    NewItem('~I~ndex','Shift-F1',kbShiftF1,hcHelpIndex,hcHelpIndex,
    newline(
    NewItem('~H~elp on help','',0,hcHelpOnHelp,hcHelpOnHelp,
    nil))))),
  next);
end;

function WindowsMenu(next : PMenuItem) : PMenuItem;
begin
WindowsMenu :=
  NewSubMenu('~W~indows', hcWindowsMenu, NewMenu(
    NewItem('~R~esize/move','Ctrl-F5', kbCtrlF5, cmResize, hcReSize,
    NewItem('~Z~oom', 'F5', kbF5, cmZoom, hcZoom,
    NewItem('~N~ext', 'F6', kbF6, cmNext, hcNext,
    NewItem('~P~rev', 'Shift-F6', kbShiftF6, cmPrev, hcPrev,
    NewItem('~C~lose', 'Alt-F3', kbAltF3, cmClose, hcClose,
    NewItem('~T~ile', '', kbNoKey, hcTile, hcTile,
    NewItem('C~a~scade', '', kbNoKey, hcCascade, hcCascade, nil)))))))),
  next);
end;

end.
