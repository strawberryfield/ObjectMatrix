{$F+,O+}

unit bbslogo;
{ Identifica la scheda grafica e lancia il logo appropriato }

interface

function logoname : string;

implementation

uses graph,bbsinit;

var gm,gd : integer;
    okmode : set of byte;

function exists(s : string) : boolean;
begin
Exists := FileExists(prgpath+prgfile+s);
end;

function logoname : string;
label mainprg;
var result : string;

  procedure run(s1,s2 : string);
  begin
  result := prgpath+prgfile+s1+' '+s2;
  end;

begin
result := '';
detectgraph(gd,gm);
{ if not graphics skip logo }
if gd = -2 then goto mainprg;

{ if VGA, MCGA, 8514 display 320x200 256col }
okmode := [VGA,MCGA,IBM8514];
if (gd in okmode) and exists('.vga') then begin
  run('.vga','/vga');
  goto mainprg;
  end;

{ if EGA 256k or above 640x350 16col }
okmode := okmode + [EGA];
if (gd in okmode) and exists('.ega') then begin
  run('.ega','/ega');
  goto mainprg;
  end;

{ if CGA, EGA 64k or mono, Olivetti 640x200 2col }
okmode := okmode + [CGA,EGA64,EGAmono,ATT400];
if (gd in okmode) and exists('.cga') then begin
  run('.cga','/cga');
  goto mainprg;
  end;

{ if Hercules 720x350 or 640x200 B/W }
if gd = HercMono then begin
  if exists('.her') then run('.her','/her')
  else if exists('.cga') then run('.cga','/her');
  goto mainprg;
  end;

mainprg:
logoname := result;
end;

end.