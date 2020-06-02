{$F+,O+}

unit datestr;

interface

const usedow : boolean = false;
      completetext : boolean = false;
      useseconds : boolean = true;
      italiano : boolean = false;

function datastr : string;
function timestr : string;
function filedatastr(var f : file) : string;
function filetimestr(var f : file) : string;
function timestamp : string;
function dayfactor(y,m,d : word) : longint;
function TodayFactor : longint;
function timefactor(h,m,s : word) : longint;
function nowfactor : longint;
function unixstamp : longint;


implementation

uses dos,drivers;

function ds(y,m,d,dow : word) : string;
var s,st : string;
    p : array[1..3] of longint;
begin
if italiano then
  case m of
    1 : st := 'Gennaio';
    2 : st := 'Febbraio';
    3 : st := 'Marzo';
    4 : st := 'Aprile';
    5 : st := 'Maggio';
    6 : st := 'Giugno';
    7 : st := 'Luglio';
    8 : st := 'Agosto';
    9 : st := 'Settembre';
    10 : st := 'Ottobre';
    11 : st := 'Novembre';
    12 : st := 'Dicembre';
    end
else
  case m of
    1 : st := 'January';
    2 : st := 'February';
    3 : st := 'March';
    4 : st := 'April';
    5 : st := 'May';
    6 : st := 'June';
    7 : st := 'July';
    8 : st := 'August';
    9 : st := 'September';
    10 : st := 'October';
    11 : st := 'November';
    12 : st := 'Dicember';
    end;
p[1] := d;
p[2] := longint(@st);
p[3] := y mod 1900;
if completetext then formatstr(s,'%2d %s %2d',p)
else formatstr(s,'%2d %-3s %2d',p);
if usedow then begin
  if italiano then
    case dow of
      0 : st := 'Domenica';
      1 : st := 'Luned';
      2 : st := 'Marted';
      3 : st := 'Mercoled';
      4 : st := 'Gioved';
      5 : st := 'Venerd';
      6 : st := 'Sabato';
      end
  else
    case dow of
      0 : st := 'Sunday';
      1 : st := 'Monday';
      2 : st := 'Tuesday';
      3 : st := 'Wednesday';
      4 : st := 'Thursday';
      5 : st := 'Friday';
      6 : st := 'Saturday';
      end;
  if completetext then s := st + ' ' + s else s := copy(st,1,3) + ' ' + s;
  end;
ds := s;
end;

function ts(h,min,sec : word) : string;
var s : string;
    p : array[1..3] of longint;
begin
p[1] := h;
p[2] := min;
p[3] := sec;
if useseconds then formatstr(s,'%2d:%02d:%02d',p)
else formatstr(s,'%2d:%02d',p);
ts := s;
end;

function datastr : string;
var y,m,d,dow : word;
begin
getdate(y,m,d,dow);
datastr := ds(y,m,d,dow);
end;

function timestr : string;
var h,min,sec,s100 : word;
begin
gettime(h,min,sec,s100);
timestr := ts(h,min,sec);
end;

procedure getfiledt(var f : file; var dt : datetime);
var t : longint;
begin
getftime(f,t);
unpacktime(t,dt);
end;

function filedatastr(var f : file) : string;
var dt : datetime;
    oud : boolean;
begin
getfiledt(f,dt);
oud := usedow;
usedow := false;
with dt do filedatastr := ds(year,month,day,0);
usedow := oud;
end;

function filetimestr(var f : file) : string;
var dt : datetime;
begin
getfiledt(f,dt);
with dt do filetimestr := ts(hour,min,sec);
end;

function dayfactor(y,m,d : word) : longint;

  function default : longint;
  begin
  default := (y - 1900) * 365 + pred(m) * 31 + d;
  end;

  function ycorr(x : word) : longint;
  begin
  ycorr := x div 4 - (3 * succ(x div 100)) div 4;
  end;

  function mcorr : longint;
  begin
  mcorr := (4 * m + 23) div 10;
  end;

begin
if m > 2 then dayfactor := default + mcorr + ycorr(y)
else dayfactor := default + ycorr(pred(y));
end;

function TodayFactor : longint;
var day,month,year,dow : word;
begin
getdate(year,month,day,dow);
TodayFactor := dayfactor(year,month,day);
end;

function timefactor(h,m,s : word) : longint;
const min = 60;
      hour = min * 60;
begin
timefactor := h * hour + m * min + s;
end;

function nowfactor : longint;
var h,m,s,s100 : word;
begin
gettime(h,m,s,s100);
nowfactor := timefactor(h,m,s);
end;

function unixstamp : longint;
const daysize = 60 * 60 * 24;
begin
unixstamp := (todayfactor - dayfactor(1970,1,1)) * daysize + nowfactor;
end;

function timestamp : string;
var today : longint;
    s : string;
begin
today := unixstamp;
formatstr(s,'%x',today);
timestamp := s;
end;

end.