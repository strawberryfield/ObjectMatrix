{$O+,F+}

unit inifile;

interface

uses objects;

const remchar : char = ';';

type scanproc = procedure(st,par : string; var error : boolean);

     PTxtBuf = ^TTxtBuf;
     TTxtBuf = array[1..10240] of char;

     PIni = ^TIni;
     TIni = object(TObject)
       error : byte;
       constructor init(name : string);
       procedure ScanSection(name : string; sep : char; p : scanproc);
       procedure ParseSection(name : string; p : scanproc);
       destructor done; virtual;
     private
       f : text;
       buf : PTxtBuf;
       line : word;
       end;

{ Il campo error puo' assumere i seguenti valori:
  1: File Not Found
  2: Section Not Found
  3: Unknown Statement
}

procedure splitstat(l : string; sep : char; var s,p : string);

function IsTrue(s : string) : boolean;
function getpath(s : string) : pstring;
function getFileName(s : string) : pstring;
function getDrive(s : string) : char;

implementation

uses stringhe,doscheck,dos;

procedure splitline(l : string; sep : char; var s,p : string);
var j : byte;
begin
s := ltrim(l);
j := pos(sep,l);
if j = 0 then p := ''
else begin
  p := ltrim(copy(l,j+1,255));
  dec(j);
  s[0] := chr(j);
  end;
end;

procedure splitstat(l : string; sep : char; var s,p : string);
var k : byte;
begin
splitline(l,sep,s,p);
k := pos(remchar,p);
if k > 0 then p[0] := pred(chr(k));
p := rtrim(p);
s := uppercase(s);
end;

constructor TIni.init(name : string);
begin
error := 0;
new(buf);
assign(f,name);
SetTextBuf(f,buf^,sizeof(TTxtBuf));
{$I-}
reset(f);
{$I+}
if ioresult <> 0 then begin
  error := 1;
  dispose(buf);
  exit;
  end;
line := 0;
end;

destructor TIni.done;
begin
close(f);
dispose(buf);
end;

procedure TIni.ScanSection(name : string; sep : char; p : scanproc);
label endloop,endsection;
var l,st,par : string;
    err : boolean;
begin

{ Cerca la sezione desiderata }

name := uppercase(name);
reset(f);
repeat
  readln(f,l);
  inc(line);
  until (uppercase(l) = '['+name+']') or eof(f);

  if eof(f) then begin
    error := 2;
    done;
    exit;
    end;

{ Esamina le righe }

repeat
  readln(f,l);
  inc(line);
  if (l = '') then goto endloop;
  if l[1] = remchar then goto endloop;
  if l[1] = '[' then goto endsection;

  splitstat(l,sep,st,par);
  p(st,par,err);
  if err then begin
    error := 3;
    done;
    exit;
    end;

endloop:
  until eof(f);
endsection:
end;

procedure TIni.parseSection(name : string; p : scanproc);
begin
ScanSection(name,'=',p);
end;


{ Funzioni di utilita' per le routines utente }

function IsTrue(s : string) : boolean;
begin
s := uppercase(s);
IsTrue := (s = 'TRUE') or (s = 'YES') or (s = '1') or (s = 'ON');
end;

function getpath(s : string) : pstring;
begin
getpath := nil;
if s = '' then s := '.';
if pathValid(s) then begin
  if s[length(s)] <> '\' then s := s + '\';
  getpath := newstr(s);
  end
else writeln('Invalid directory "',s,'"');
end;

function getdrive(s : string) : char;
begin
getdrive := #0;
if DriveValid(s[1]) then
  getdrive := UpCase(s[1])
else writeln('Invalid drive "',s,'"');
end;

function getFileName(s : string) : pstring;
begin
getFileName := nil;
if ValidFileName(s) then
  getFileName := newstr(s)
else writeln('Invalid filename "',s,'"');
end;

end.