{$X+}

program pktdump;
{ Visualizza il contenuto dei pacchetti passati come argomenti }

uses ifna,dos,app,fviewer,views,objects,menus,drivers,dialogs;

var f : text;

procedure Reader(p : PPacket);
begin
with p^ do begin
  h^.dump(f);
  Mread;
  while m^.terminator = false do begin
    m^.dump(f);
    writeln(f);
    Mread;
    end;
  end;
end;

type myapp = object(TApplication)
       constructor init;
       procedure initmenubar; virtual;
       procedure handleevent(var Event : TEvent); virtual;
       end;

const filename = '\pktdump.dat';

constructor myapp.init;
var fn : pathstr;
    W : pwindow;
begin
TApplication.init;
fn := filename;
w := New(PFileWindow,Init(FN));
w^.flags := w^.flags and $f0;
if ValidView(W) <> nil then
  Desktop^.Insert(W) else halt;
end;

const  cmAbout = 200;

procedure myapp.initmenubar;
var r : TRect;
begin
getextent(r);
R.B.Y := R.A.Y+1;
MenuBar := new(PMenuBar,init(r,newmenu(
  newsubmenu('~ð~ CASASOFT Packets Viewer',hcNoContext,newmenu(
    newitem('~A~bout...','F1',kbF1,cmAbout,hcNoContext,
    newitem('E~x~it','Alt-X',kbAltX,cmQuit,hcNoContext,
    nil))),nil)
  )));
end;

procedure MyApp.handleevent(var Event : TEvent);

  procedure About;
  var D: PDialog;
      Control: PView;
      R: TRect;
  begin
  R.Assign(0, 0, 40, 11);
  D := New(PDialog, Init(R, 'About'));
  with D^ do begin
    Options := Options or ofCentered;
    R.Grow(-1, -1);
    Dec(R.B.Y, 3);
    Insert(New(PStaticText, Init(R,
      #13 +
      ^C'CASASOFT Packets Viewer'#13 +
      #13 +
      ^C'(c) 1992 Roberto Ceccarelli'#13 +
      #13 +
      ^C'release 1.00')));
    R.Assign(15, 8, 25, 10);
    Insert(New(PButton, Init(R, 'O~K', cmOk, bfDefault)));
    end;
  if ValidView(D) <> nil then begin
    Desktop^.ExecView(D);
    Dispose(D, Done);
    end;
  end;

begin
TApplication.handleevent(Event);
if event.what = evCommand then begin
  case event.command of
    cmAbout : About;
    else exit;
    end;
  clearevent(Event);
  end;
end;


var j : byte;
    sr : SearchRec;
    p : PPacket;
    dir : dirstr;
    name : namestr;
    ext : extstr;
    appl : myapp;

begin
if paramcount > 0 then begin
  assign(f,filename);
  rewrite(f);
  for j := 1 to paramcount do begin
    fsplit(paramstr(j),dir,name,ext);
    findfirst(paramstr(j),archive,sr);
    while doserror = 0 do begin
      new(p,load(dir+sr.name));
      reader(p);
      dispose(p,done);
      findnext(sr);
      end;
    end;
  close(f);
  end;
appl.init;
appl.run;
appl.done;
end.
