{$F+,O+,V-}

unit outbview;
{ Manager delle directory di outbound }

interface

uses stddlg,drivers,dos;

type POutboundDialog = ^TOutboundDialog;
     TOutboundDialog = object(TFileDialog)
       constructor init(AWildCard: PathStr; ATitle: String; HistoryId: Byte);
       procedure HandleEvent(var Event : TEvent); virtual;
       end;

     PPktInfoPane = ^TPktInfoPane;
     TPktInfoPane = object(TFileInfoPane)
       procedure draw; virtual;
       end;

implementation

uses views,objects,dialogs;

constructor TOutboundDialog.Init(AWildCard: TWildStr; ATitle: String; HistoryId: Byte);
var
  Control: PView;
  R: TRect;
  S: String;
  Opt: Word;
  ACurDir: PathStr;
begin
  R.Assign(15,1,64,20);
  TDialog.Init(R, ATitle);
  Options := Options or ofCentered;
  WildCard := AWildCard;

  R.Assign(3,3,31,4);
  FileName := New(PFileInputLine, Init(R, 79));
  FileName^.Data^ := WildCard;
  Insert(FileName);
  R.Assign(2,2,31,3);
  Control := New(PLabel, Init(R, '~B~undle', FileName));
  Insert(Control);
  R.Assign(31,3,34,4);
  Control := New(PHistory, Init(R, FileName, HistoryId));
  Insert(Control);

  R.Assign(3,14,34,15);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3,6,34,14);
  FileList := New(PFileList, Init(R, WildCard, PScrollBar(Control)));
  Insert(FileList);
  R.Assign(2,5,8,6);
  Control := New(PLabel, Init(R, '~F~iles', FileList));
  Insert(Control);

  R.Assign(35,3,46,5);
  Opt := bfDefault;

    Insert(New(PButton, Init(R, '~O~pen', cmFileOpen, Opt)));
    Opt := bfNormal;
    Inc(R.A.Y,2); Inc(R.B.Y,2);

    Insert(New(PButton, Init(R, '~R~eplace',cmFileReplace, Opt)));
    Opt := bfNormal;
    Inc(R.A.Y,2); Inc(R.B.Y,2);

    Insert(New(PButton, Init(R, '~D~elete',cmFileClear, Opt)));
    Opt := bfNormal;
    Inc(R.A.Y,2); Inc(R.B.Y,2);

  Insert(New(PButton, Init(R, 'Quit', cmCancel, bfNormal)));
  Inc(R.A.Y,2); Inc(R.B.Y,2);

    Insert(New(PButton, Init(R, 'Help',cmHelp, bfNormal)));
    Inc(R.A.Y,2); Inc(R.B.Y,2);

  R.Assign(1,16,48,18);
  Control := New(PPktInfoPane, Init(R));
  Insert(Control);

  SelectNext(False);

  ReadDirectory;
end;

procedure TOutboundDialog.HandleEvent(var Event : TEvent);
begin
TFileDialog.HandleEvent(Event);
end;


procedure TPktInfoPane.Draw;
var
  B: TDrawBuffer;
  D: String[9];
  M: String[3];
  Color: Word;
  Time: DateTime;
  Path: PathStr;
  FmtId: String;
  Params: array[0..6] of LongInt;
  Str: String[80];
const
  sDirectoryLine = ' %-12s %-9s %3s %2d, %4d  %2d:%02d';
  sFileLine      = ' %-12s %-9d %3s %2d, %4d  %2d:%02d';
  Month: array[1..12] of String[3] = 
    ('Jan','Feb','Mar','Apr','May','Jun',
     'Jul','Aug','Sep','Oct','Nov','Dec');
begin
  { Display path }
  Path := FExpand(PFileDialog(Owner)^.Directory^);
  Color := GetColor($01);
  MoveChar(B, ' ', Color, Size.X);
  MoveStr(B[1], Path, Color);
  WriteLine(0, 0, Size.X, 1, B);

  { Display file }
  Params[0] := LongInt(@S.Name);
  MoveChar(B, ' ', Color, Size.X);
  Params[0] := LongInt(@S.Name);
  if S.Attr and Directory <> 0 then
  begin
    FmtId := sDirectoryLine;
    D := 'Directory';
    Params[1] := LongInt(@D);
  end else
  begin
    FmtId := sFileLine;
    Params[1] := S.Size;
  end;
  UnpackTime(S.Time, Time);
  M := Month[Time.Month];
  Params[2] := LongInt(@M);
  Params[3] := Time.Day;
  Params[4] := Time.Year;
  Params[5] := Time.Hour;
  Params[6] := Time.Min;
  FormatStr(Str, FmtId, Params);
  MoveStr(B, Str, Color);
  WriteLine(0, 1, Size.X, 1, B);

  { Fill in rest of rectangle }
  MoveChar(B, ' ', Color, Size.X);
  WriteLine(0, 2, Size.X, Size.Y-2, B);
end;



end.