{$F+,O+}

unit popinput;

interface

uses dialogs,drivers,objects,stddlg;

type PPopUp = ^TPopUp;
     TPopUp = object(THistory)
       function DoCommand(var Event : TEvent) : boolean;
       end;

     PPopFile = ^TPopFile;
     TPopFile = object(TPopUp)
       procedure HandleEvent(var Event : TEvent);  virtual;
       end;

     PSelDir = ^TSelDir;
     TSelDir = object(TChDirDialog)
       function valid(command : word) : boolean; virtual;
       function getdir : string;
       end;

     PPopDir = ^TPopDir;
     TPopDir = object(TPopUp)
       procedure HandleEvent(var Event : TEvent);  virtual;
       end;


implementation

uses app,dos,views;

{ Questa funzione determina se l'evento in atto riguarda
  l'icona attuale }

function TPopUp.DoCommand(var Event : TEvent) : boolean;
begin
if (((link^.state and sfFocused) <> 0) and
   (event.what = evKeyDown) and
   (CtrlToArrow(event.keycode) = kbDown)) or

   ((event.what = evMouseDown) and
   mouseInView(event.where)) then
     DoCommand := true else DoCommand := false;
end;


{ Procedura di attivazione del dialog box per i files }

procedure TPopFile.HandleEvent(var Event : TEvent);
var d : PFileDialog;
    fname : PathStr;
begin
if DoCommand(Event) then begin
  d := new(PFileDialog,init('*.*','Select File','~N~ame',fdOkButton,HistoryID));
  d^.setdata(link^.data^);
  if desktop^.execview(d) <> cmCancel then begin
    d^.getfilename(fname);
    link^.data^ := fname;
    link^.select;
    link^.draw;
    end;
  clearevent(Event);
  end;
end;

{ Tipo che ridefinisce il box delle directory in modo che non effettui
  il cambio e restituisca una stringa }

function TSelDir.valid(command : word) : boolean;
begin
valid := true;
end;

function TSelDir.getdir : string;
var p : pathstr;
begin
p := FExpand(dirinput^.data^);
if p[length(p)] <> '\' then p := p +'\';
getdir := p;
end;


{ Procedura di attivazione del box delle directory }

procedure TPopDir.HandleEvent(var Event : TEvent);
var d : PSelDir;
begin
if DoCommand(Event) then begin
  d := new(PSelDir,init(cdNormal,HistoryID));
  if desktop^.execview(d) <> cmCancel then begin
    link^.data^ := d^.getdir;
    link^.select;
    link^.draw;
    end;
  clearevent(Event);
  end;
end;

end.