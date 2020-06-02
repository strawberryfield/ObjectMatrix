{$F+,O+,X+}

unit bbslib;

interface

uses  objects,textview,views,fviewer,dos,menus;

type PTermWin = ^TTermWin;
     TTermWin = object(TWindow)
       t : PTerminal;
       constructor init(var r : Trect; Aname : string);
       end;

     PActivity = ^TActivity;
     TActivity = object(TTermWin)
       constructor init(var r : Trect);
       end;

     Pbanner = ^TBanner;
     TBanner = object(TView)
       constructor init(var bounds : TRect; s1,s2,s3 : String);
       procedure newline(x : byte; s : string);
       procedure draw; virtual;
       function GetPalette : PPalette; virtual;
       destructor done; virtual;
     private
       lines : array[0..2] of PString;
       end;

const CBanner = #72;
      CBannerColor = #$2F;
      CBannerBlackWhite = #$70;
      CBannerMonochrome = #$70;

implementation

uses drivers;

constructor TTermWin.init(var r : Trect; Aname : string);
begin
TWindow.init(r,Aname,wnNoNumber);
flags := 0;
r.grow(-1,-1);
growmode := gfGrowHiY;
setstate(sfShadow,false);
new(t,init(r,
  StandardScrollBar(sbHorizontal),
  StandardScrollBar(sbVertical),8000));
insert(t);
end;

constructor TActivity.init(var r : TRect);
begin
TTermWin.init(r,'Attivit… recente');
end;

constructor TBanner.init(var Bounds : TRect; s1,s2,s3 : String);
begin
TView.init(Bounds);
GrowMode := gfGrowAll;
lines[0] := newstr(s1);
lines[1] := newstr(s2);
lines[2] := newstr(s3);
end;

procedure TBanner.newline(x : byte; s : string);
begin
if lines[x] <> nil then disposestr(lines[x]);
lines[x] := newstr(s);
draw;
end;

procedure TBanner.draw;
var B : TDrawBuffer;
    color,y : byte;
begin
color := getcolor(1);
for y := 0 to 2 do begin
  movechar(b,' ',color,size.x);
  if lines[y] <> nil then movestr(b,copy(lines[y]^,1,size.x),color);
  writeline(0,y,size.x,1,b);
  end;
end;

function TBanner.GetPalette : PPalette;
const p : string[Length(CBanner)] = CBanner;
begin
GetPalette := @P;
end;

destructor TBanner.done;
var y : byte;
begin
for y := 0 to 2 do
  if lines[y] <> nil then disposestr(lines[y]);
TView.done;
end;

end.
