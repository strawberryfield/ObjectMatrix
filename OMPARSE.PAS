{$F+,O+}

unit omparse;

interface

const maxpar = 10;
type TPar = array[1..maxpar] of string;

procedure ParseCmdLine;
function parse(var p : Tpar) : boolean;
procedure cleanpar(var p : TPar);

implementation

uses
  stringhe,omnode,omtools,omdmail,inifile,omquinex,bbsconf,
  ompack2,omkill,ompost,omunpack,omattach,omdump,bbsinit;

procedure cleanpar(var p : TPar);
var j : word;
begin
for j := 1 to maxpar do p[j,0] := #0;
end;

function parse(var p : Tpar) : boolean;
label endloop;
var pt : pointer;

  function minpar(x : byte) : boolean;
  var j : boolean;
      k : array[1..2] of longint;
  begin
  j := p[succ(x)] <> '';
  if not j then begin
    k[1] := longint(@p[1]);
    k[2] := x;
    logf^.printf(0,lang^.get(msgFewParam),k);
    end;
  minpar := j;
  end;

begin
parse := true;

if p[1] = 'PACK' then begin
  makepacket(p[2]);
  goto endloop;
  end;

if p[1] = 'CLEANOUT' then begin
  cleanout;
  goto endloop;
  end;

if p[1] = 'KILLPACKETS' then begin
  killpkt;
  goto endloop;
  end;

if p[1] = 'FORCEPOLL' then begin
  pollpkt(p[2]);
  goto endloop;
  end;

if p[1] = 'UNPACK' then begin
  if IsRegistered then
    unpack(p[2])
  else
    unpack('');
  goto endloop;
  end;

if p[1] = 'POST' then begin
  if minpar(4) then post(p[2],p[3],p[4],p[5],p[6]);
  goto endloop;
  end;

if p[1] = 'ATTACH' then begin
  if minpar(2) then fileattach(p[2],p[3],p[4],p[5]);
  goto endloop;
  end;

if p[1] = 'HATCH' then begin
  if minpar(4) then hatch(p[2],p[3],p[4],p[5],p[6]);
  goto endloop;
  end;

if p[1] = 'REQUEST' then begin
  if minpar(2) then filereq(p[2],p[3]);
  goto endloop;
  end;

if p[1] = 'RENAME' then begin
  if isRegistered then
    renamer(p[2],p[3])
  else
    renamer('','');
  goto endloop;
  end;

if p[1] = 'KILL' then begin
  if isRegistered then
    killer(p[2])
  else
    killer('');
  goto endloop;
  end;

if p[1] = 'PURGE' then begin
  if minpar(1) then purge(p[2]);
  goto endloop;
  end;

if p[1] = 'REMARK' then begin
  if minpar(1) then logf^.print(0,p[2]);
  goto endloop;
  end;

if p[1] = 'REPLY' then begin
  reply;
  goto endloop;
  end;

if p[1] = 'ADJUST' then begin
  adjust;
  goto endloop;
  end;

if p[1] = 'RENUM' then begin
  renumber;
  goto endloop;
  end;

if p[1] = 'LISTPKT' then begin
  dumpPacketLink;
  goto endloop;
  end;

if p[1] = 'NODELIST' then begin
  nodelist;
  goto endloop;
  end;

if p[1] = 'DISKMAIL' then begin
  if minpar(2) then diskmail(p[2],p[3]);
  goto endloop;
  end;

if p[1] = 'DUMP' then begin
  if minpar(1) then begin
    p[2] := uppercase(p[2]);

    if p[2] = 'MAIL' then begin
      dumpfile(p[3]);
      goto endloop;
      end;

    if p[2] = 'INBOUND' then begin
      dumpInbound(p[3]);
      goto endloop;
      end;

    if p[2] = 'OUTBOUND' then begin
      dumpOutbound(p[3]);
      goto endloop;
      end;

    end;
  goto endloop;
  end;

if p[1] = 'QUICKBASE' then begin
  if minpar(1) then begin
    p[2] := uppercase(p[2]);

    if p[2] = 'EXPORT' then begin
      omquinex.export;
      goto endloop;
      end;

    if p[2] = 'RESCAN' then begin
      omquinex.rescan;
      goto endloop;
      end;

    if p[2] = 'IMPORT' then begin
      omquinex.import;
      goto endloop;
      end;

    end;
  goto endloop;
  end;

parse := false;
if not IsRegistered then begin
  pt := @p[1];
  logf^.printf(0,lang^.get(msgUnkCmdLine),pt);
  end;

endloop:
end;


{ Gestione degli script }

var p : TPar;

{$F+}
procedure scriptparser(st,par : string; var error : boolean);
var tp : TPar;
    j : byte;
begin
tp[1] := st;
for j := 2 to maxpar do begin
  splitline(par,tp[j],par);
  if tp[j] <> '' then
    if tp[j,1] = '%' then tp[j] := p[succ(ord(tp[j,2])-ord('0'))]
        else tp[j] := noUnderscore(tp[j]);
  end;
error := not parse(tp)
end;
{$F-}

procedure DoScript;
var t : PIni;
    pt : pointer;
begin
pt := @p[1];
if not inistart(t) then exit;
logf^.printf(1,lang^.get(msgBeginScript),pt);
t^.scansection('MACRO '+p[1],' ',scriptparser);
case t^.error of
  2 : begin
      logf^.printf(0,lang^.get(msgUnkScript),pt);
      exit;
      end;
  3 : exit;
  end;
dispose(t,done);
end;

procedure ParseCmdLine;
var j : byte;
begin
for j := 1 to maxpar do p[j] := NoUnderscore(paramstr(j));
p[1] := uppercase(p[1]);
if not(parse(p)) and IsRegistered then DoScript;
end;

end.