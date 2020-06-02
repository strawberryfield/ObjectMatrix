{$O+,F+}

unit swkey;
{ Codice per codifica/decodifica chiave shareware }

interface

const chk1 : string[4] = 'HAFF';
      chk2 : string[4] = 'HGFE';
      chk3 : string[4] = 'ADCH';

function code(c : string; n : word) : string;
function decode(k,c : string) : word;

implementation

uses crc;

function code(c : string; n : word) : string;
var s : string;

  function translate(x : word; c : string) : string;
  var s : string[4];
      j : byte;
  begin
  for j := 1 to 4 do begin
    s[j] := chr((x and $0f) + ord(c[j]));
    x := x shr 4;
    end;
  s[0] := #4;
  translate := s;
  end;

begin
s := translate(n,chk1);
s := s + translate(stringcrc(c),chk2);
s := s + translate(stringcrc(s),chk3);
code := s;
end;

function decode(k,c : string) : word;
var crc,ser,cs : word;

  function translate(x,c : string) : word;
  var res : word;
      j : byte;
  begin
  res := 0;
  for j := 1 to 4 do
    res := res + ((ord(x[j]) - ord(c[j])) and $0f) shl (4 * pred(j));
  translate := res;
  end;

begin
ser := translate(copy(k,1,4),chk1);
crc := translate(copy(k,5,4),chk2);
cs := translate(copy(k,9,4),chk3);
if (stringcrc(copy(k,1,8)) = cs) and (stringcrc(c) = crc)
  then decode := ser else decode := 0;
end;

end.