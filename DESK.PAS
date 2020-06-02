{$F+,O+}

unit desk;

interface

uses objects;

procedure colors(l : PStringList);
procedure mouse;

implementation

uses colorsel,mousedlg,dialogs,app,views,memory,drivers;

procedure Colors(l : PStringList);
var
  D: PColorDialog;
begin
  D := New(PColorDialog, Init('',
  { DeskTop }
    ColorGroup(l^.get(100),
      ColorItem(l^.get(32),             32, nil),
  { Menus }
    ColorGroup(l^.get(101),
      ColorItem(l^.get(2),            2,
      ColorItem(l^.get(3),          3,
      ColorItem(l^.get(4),          4,
      ColorItem(l^.get(5),          5,
      ColorItem(l^.get(6), 6,
      ColorItem(l^.get(7), 7, nil)))))),
  { Dialogs }
    ColorGroup(l^.get(102),
      ColorItem(l^.get(33),  33,
      ColorItem(l^.get(34),       34,
      ColorItem(l^.get(35),   35,
      ColorItem(l^.get(36),  36,
      ColorItem(l^.get(37),       37,
      ColorItem(l^.get(61),61, nil)))))),
  { Labels }
    ColorGroup(l^.get(103),
      ColorItem(l^.get(38),      38,
      ColorItem(l^.get(39),    39,
      ColorItem(l^.get(40),    40, nil))),
  { Buttons }
    ColorGroup(l^.get(104),
      ColorItem(l^.get(41),     41,
      ColorItem(l^.get(42),    42,
      ColorItem(l^.get(43),   43,
      ColorItem(l^.get(44),   44,
      ColorItem(l^.get(45),   45,
      ColorItem(l^.get(46),     46, nil)))))),
   { Cluster }
    ColorGroup(l^.get(105),
      ColorItem(l^.get(47),    47,
      ColorItem(l^.get(48),  48,
      ColorItem(l^.get(49),  49, nil))),
   { Input lines }
    ColorGroup(l^.get(106),
      ColorItem(l^.get(50),      50,
      ColorItem(l^.get(51),    51,
      ColorItem(l^.get(52),       52, nil))),
   { History }
    ColorGroup(l^.get(107),
      ColorItem(l^.get(53),    53,
      ColorItem(l^.get(54),     54,
      ColorItem(l^.get(55),  55,
      ColorItem(l^.get(56), 56, nil)))),
   { Liste }
    ColorGroup(l^.get(108),
      ColorItem(l^.get(57),       57,
      ColorItem(l^.get(58),      58,
      ColorItem(l^.get(59),     59,
      ColorItem(l^.get(60),      60, nil)))),
   { Viewer }
    ColorGroup(l^.get(109),
      ColorItem(l^.get(8),      8,
      ColorItem(l^.get(9),       9,
      ColorItem(l^.get(10),       10,
      ColorItem(l^.get(11),   11,
      ColorItem(l^.get(12),  12,
      ColorItem(l^.get(13),  13,
      ColorItem(l^.get(14),  14, nil))))))),
    nil))))))))))));

D^.SetData(Application^.GetPalette^);
if Desktop^.ExecView(D) <> cmCancel then
begin
  Application^.GetPalette^ := D^.Pal;
  DoneMemory;  { Dispose all group buffers }
end;
Dispose(D, Done);
end;

procedure Mouse;
var D: PDialog;
begin
D := New(PMouseDialog, Init);
D^.SetData(MouseReverse);
if Desktop^.ExecView(D) <> cmCancel then D^.GetData(MouseReverse);
end;

end.