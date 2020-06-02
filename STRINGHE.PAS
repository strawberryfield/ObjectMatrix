{$F+,O+}

unit stringhe;

interface

uses objects;

const unitid = 1;
      unitcode = unitid * 256 + 20;

type Pstrobj = ^Tstrobj;
     Tstrobj = object(Tobject)
       p : pstring;
       constructor init(s : string);
       constructor load(var s : Tstream);
       procedure store(var s : Tstream); virtual;
       destructor done; virtual;
       end;

function LoCase(c : char) : char;
function uppercase(str : string): string;
function lowercase(str : string): string;
function NoUnderscore(s : string) : string;
function BeginOf(s1,s2 : string) : boolean;
function LTrim(S: String): String;
function RTrim(S: String): String;
function chars(c : char; n : byte) : string;
function spaces(n : byte) : string;
procedure splitline(l : string; var s,p : string);
function hexbyte(x : byte) : string;
function hexword(x : word) : string;
function hexlong(x : longint) : string;
function hex2long(s : string) : longint;

procedure RegisterStringhe;

implementation

uses drivers;

const Rstrobj : TstreamRec = (
        ObjType : unitcode + 1;
        VmtLink : ofs(typeof(Tstrobj)^);
        Load    : @Tstrobj.load;
        Store   : @Tstrobj.store
        );

function LoCase(c : char) : char;
begin
if c in ['A'..'Z'] then LoCase := chr(ord(c) - (ord('a') - ord('A')))
else LoCase := c;
end;

function LowerCase(str : string): string;
var j : byte;
begin
for j := 1 to length(str) do str[j] := LoCase(str[j]);
LowerCase := str;
end;

function UpperCase(str : string): string;
var j : byte;
begin
for j := 1 to length(str) do str[j] := UpCase(str[j]);
UpperCase := str;
end;

function NoUnderscore(s : string) : string; assembler;
asm
  push  ds
  cld
  lds   si, s
  les   di, @result
  lodsb
  stosb
  xor   ah, ah
  mov   cx, ax
  jcxz  @fine

@ciclo:
  lodsb
  cmp   al, '_'
  jnz   @ripeti
  mov   al, ' '

@ripeti:
  stosb
  loop  @ciclo

@fine:
  pop   ds
end;

function BeginOf(s1,s2 : string) : boolean;
begin
s2[0] := s1[0];
BeginOf := s1 = s2;
end;

function LTrim(S: String): String;
var I: Integer;
begin
I := 1;
while (I < Length(S)) and (S[I] = ' ') do Inc(I);
LTrim := Copy(S, I, 255);
end;

function RTrim(S: String): String;
begin
while S[Length(S)] = ' ' do Dec(S[0]);
RTrim := S;
end;

function chars(c : char; n : byte) : string;
var s : string;
begin
fillchar(s[1],n,c);
s[0] := chr(n);
chars := s;
end;

function spaces(n : byte) : string;
begin
spaces := chars(' ',n);
end;

(*
procedure splitline(l : string; var s,p : string);
var j : byte;
begin
s := ltrim(l);
j := pos(' ',l);
if j = 0 then p := ''
else begin
  p := ltrim(copy(l,j,255));
  dec(j);
  s[0] := chr(j);
  end;
end;
*)
procedure splitline(l : string; var s,p : string); assembler;
asm
  push  ds
  cld
  lds   si, l
  lodsb
  xor   ah, ah
  mov   cx, ax

{ inizializza le stringhe destinazione }
  xor   al, al
  les   di, p
  stosb
  les   di, s
  mov   bx, di
  stosb
  jcxz  @fine

{ scarta i blank iniziali }
@lt1:
  lodsb
  cmp   al, ' '
  loopz @lt1
  jcxz  @fine

{ copia prima parte }
  xor dx, dx
@1:
  stosb
  inc   dl
  lodsb
  cmp   al, ' '
  loopnz @1
  je    @nospace
  stosb
  inc   dl
@nospace:
  mov   di, bx
  mov   al, dl
  stosb
  jcxz  @fine

{ cerca inizio seconda parte }
@lt2:
  lodsb
  cmp   al, ' '
  loopz @lt2
  jcxz  @fine

{ copia seconda parte }
@start2:
  les   di, p
  mov   bx, di
  inc   di
  stosb
  mov   dx, cx
  inc   dx
  rep movsb
  mov   di, bx
  mov   al, dl
  stosb

@fine:
  pop ds
end;

constructor Tstrobj.init(s : string);
begin
if s = '' then s := ' ';
p := newstr(s);
end;

constructor Tstrobj.load(var s : Tstream);
begin
p := s.readstr;
end;

procedure Tstrobj.store(var s : Tstream);
begin
s.writestr(p);
end;

destructor Tstrobj.done;
begin
disposestr(p);
end;

const hex : string[16] = '0123456789ABCDEF';

function hexbyte(x : byte) : string;
begin
hexbyte := hex[(x and $f0) shr 4 + 1] + hex[(x and $0f) + 1];
end;

function hexword(x : word) : string;
begin
hexword := hexbyte(hi(x)) + hexbyte(lo(x));
end;

function hexlong(x : longint) : string;
var k : longrec absolute x;
begin
hexlong := hexword(k.hi) + hexword(k.lo);
end;

function hex2long(s : string) : longint;
var x,k : longint;
    j : byte;
begin
k := 1;
x := 0;
for j := length(s) downto 1 do begin
  x := x + pred(pos(s[j],hex)) * k;
  k := k shl 4;
  end;
hex2long := x;
end;

procedure RegisterStringhe;
begin
RegisterType(RstrObj);
end;

end.