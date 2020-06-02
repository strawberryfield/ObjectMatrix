{$F+,O+}

unit bbsdia;
{ Gestione box di input a piu' linee }

interface

uses dialogs,objects;

type POkCancBox = ^TOkCancBox;
     TOkCancBox = object(TDialog)
       constructor init(ASize : TRect; Atitle : string);
       end;

     PMultiLineBox = ^TMultiLineBox;
     TMultiLineBox = object(TOkCancBox)
       constructor init(Asize : TRect; lines : byte;
                        var lbl; Atitle : string);
       end;

     PMultiLine = ^TMultiLine;
     TMultiLine = object(TMultiLineBox)
       constructor init(lines : byte; var lbl; Atitle : string);
       end;

     PRadioStr = ^TRadioStr;
     TRadioStr = object(TRadioButtons)
       constructor init(Asize : TRect; AStrings,outs : PSItem);
       procedure getdata(var rec);  virtual;
       destructor done; virtual;
     private
       risultati : PSItem;
       end;

     PPrioritySel = ^TPrioritySel;
     TPrioritySel = object(TRadioStr)
       constructor init(ASize : TRect);
       end;


function MultiDialog(var lbl,args; lines : byte; Atitle : string) : word;
function MultiDialogPriority(var lbl,args; lines : byte; Atitle : string) : word;
function PurgeWho : string;

implementation

uses views,app,popinput;

{ Definizione dei box di dialogo multi linea }

constructor TOkCancBox.init(ASize : TRect; Atitle : string);
begin
TDialog.init(ASize,atitle);

ASize.assign(size.x - 12, size.y - 3, size.x - 2, size.y - 1);
insert(new(PButton,init(ASize,'Cancel',cmCancel,bfNormal)));
ASize.move(-12,0);
insert(new(PButton,init(ASize,'O~K~',cmOk,bfDefault)));
options := options or ofCentered
end;

{ Gestisce finestre di dialogo con piu' input lines
  Il primo carattere della label determina il tipo di input
  richiesto cosi' che si possa attivare una history appropriata
  o una specifica dialog box

  I Caratteri sinora assegnati sono:
  1 : File
  2 : Richiesta o subject
  3 : Nome mittente o destinatario
  4 : Indirizzo
  5 : Directory
  6 : Varie
}


constructor TMultiLineBox.init(Asize : TRect; lines : byte;
                               var lbl; Atitle : string);
var j : byte;
    l : array[1..10] of string absolute lbl;
    control : PInputLine;
begin
TOkCancBox.init(ASize,atitle);

for j := 1 to lines do begin
  ASize.assign(2,j*3,58,succ(j*3));
  control := new(PInputLine,init(ASize,255));
  insert(control);
  ASize.move(0,-1);
  insert(new(Plabel,init(ASize,copy(l[j],2,255),control)));
  ASize.assign(58,j*3,61,succ(j*3));
  case l[j,1] of
    '1' : insert(new(PPopFile,init(ASize,control,1)));
    '5' : insert(new(PPopDir,init(ASize,control,5)));
    else insert(new(PHistory,init(ASize,control,ord(l[j,1])-ord('0'))));
    end;
  end;
end;

constructor TMultiLine.init(lines : byte; var lbl; Atitle : string);
var r : TRect;
begin
r.assign(0,0,63,6+3*lines);
TMultiLineBox.init(r,lines,lbl,atitle);
end;

{ Definizione Cluster con uscita a stringa anziche' word }

constructor TRadioStr.init(Asize : TRect; AStrings,outs : PSItem);
begin
TRadioButtons.init(Asize,AStrings);
risultati := outs;
end;

procedure TRadioStr.getData(var Rec);
var uscita : string absolute Rec;
    j : integer;
    p : PSitem;
begin
p := risultati;
for j := 1 to value do p := p^.next;
uscita := p^.value^
end;

destructor TRadioStr.done;
var p : PSitem;
begin
repeat
  p := risultati^.next;
  dispose(risultati);
  risultati := p;
  until p = nil;
TRadioButtons.done;
end;

constructor TPrioritySel.init(ASize : TRect);
var modo : word;
begin
TRadioStr.init(Asize,
  newSItem('~N~ormal',
  newSItem('~C~rash',
  newSItem('~H~old', nil))),

  newSItem('Normal',
  newSItem('Crash',
  newSItem('Hold', nil)))
  );
modo := 0;
setdata(modo);
end;

{ Funzioni applicative }

function MultiDialog(var lbl,args; lines : byte; Atitle : string) : word;
var d : PMultiLine;
    c : word;
begin
new(d,init(lines,lbl,Atitle));
d^.setdata(args);
c := desktop^.execview(d);
if c <> cmCancel then d^.getdata(args);
dispose(d,done);
MultiDialog := c;
end;

function MultiDialogPriority(var lbl,args; lines : byte; Atitle : string) : word;
var d : PDialog;
    p : PPrioritySel;
    c : word;
    r : TRect;
begin
r.assign(0,0,63,8+3*lines);
d := new(PMultiLineBox,init(r,lines,lbl,atitle));
d^.setdata(args);
d^.getextent(r);
r.move(2,-2);
r.b.x := r.a.x + 16;
r.a.y := r.b.y - 3;
new(p,init(r));
d^.insert(p);
r.move(0,-1);
r.b.y := succ(r.a.y);
d^.insert(new(Plabel,init(r,'~P~riority',p)));
c := desktop^.execview(d);
if c <> cmCancel then d^.getdata(args);
dispose(d,done);
MultiDialogPriority := c;
end;

function PurgeWho : string;
var d : PDialog;
    r : TRect;
    b : PCluster;
    modo : word;
    s : string;
begin
  R.Assign(0, 0, 32, 11);
  D := New(POkCancBox, Init(R, 'Pulizia messaggi'));
  with D^ do
  begin
    r.assign(5,3,27,5);
    b := new(PRadioStr,init(r,
      newsitem('~R~eceived',
      newsitem('~S~ent', nil)),

      newsitem('Received',
      newsitem('Sent',nil))
      ));
    insert(b);
    r.assign(5,2,25,3);
    insert(new(PLabel,init(r,'Flag da testare',b)));
  end;
  modo := 1;
  d^.setdata(modo);
  s := '';
  if Desktop^.ExecView(D) <> cmCancel then d^.getdata(s);
  Dispose(D, Done);
  PurgeWho := s;
end;


end.