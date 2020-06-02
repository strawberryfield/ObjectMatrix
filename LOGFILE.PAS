{$F+,O+}

unit LogFile;

interface

         { ** Tipo fondamentale per logfile ** }

type PLog = ^TLog;
     TLog = object
       active,quiet : boolean;
       level : byte;
       t,scr : text;
       constructor init;
       function config(s,p : string) : boolean;
       procedure activate(s : string); virtual;
       procedure setlevel(s : string); virtual;
       procedure print(l : byte; s : string); virtual;
       procedure printf(l : byte; s : string; var param); virtual;
       procedure printf2s(l : byte; s,s1,s2 : string);
       destructor done; virtual;
     private
       IsFirst : boolean;
       end;

       { ** Implementa un logfile stile Fido ** }

     PLogFido = ^TLogFido;
     TLogFido = object(TLog)
       prg : string[4];
       constructor init(p : string);
       procedure print(l : byte; s : string); virtual;
       procedure setlevel(s : string); virtual;
       end;

implementation

uses stringhe,datestr,drivers,dos,inifile;

         { ** Tipo fondamentale per logfile ** }

constructor TLog.init;
begin
active := false;
quiet := false;
level := 255;
isFirst := true;
assign(t,'nul');
assign(scr,'');
rewrite(scr);
end;

procedure TLog.activate(s : string);
begin
active := true;
assign(t,s);
{$I-}
append(t);
{$I+}
if ioresult <> 0 then begin
  rewrite(t);
  print(0,'Logfile created');
  end;
end;

procedure TLog.setlevel(s : string);
var e : integer;
begin
val(s,level,e);
if e <> 0 then level := 255;
end;

function TLog.config(s,p : string) : boolean;
label endloop;
begin
config := true;

if s = 'LOGFILE' then begin
   activate(p);
   goto endloop;
   end;

if s = 'LOGLEVEL' then begin
   setlevel(p);
   goto endloop;
   end;

if s = 'QUIET' then begin
   quiet := istrue(p);
   goto endloop;
   end;

config := false;
endloop:
end;

procedure TLog.print(l : byte; s : string);
begin
if l <= level then begin
  if not quiet then writeln(scr,s);
  if active then begin
    if isFirst then begin
      writeln(t,'');
      isFirst := false;
      end;
    writeln(t,s);
    end;
  end;
end;

procedure TLog.printf(l : byte; s : string; var param);
var r : string;
begin
formatstr(r,s,param);
print(l,r);
end;

procedure TLog.printf2s(l : byte; s,s1,s2 : string);
var pp : array[1..2] of pointer;
begin
pp[1] := @s1;
pp[2] := @s2;
printf(l,s,pp);
end;

destructor TLog.done;
begin
if textrec(t).mode <> fmClosed then close(t);
end;


       { ** Implementa un logfile stile Fido ** }

const FidoLevel : array [0..5] of char =
                  ('!','*','+',':','#',' ');

constructor TLogFido.init(p : string);
begin
TLog.init;
prg := uppercase(copy(p+'    ',1,4));
end;

procedure TLogFido.print(l : byte; s : string);
begin
usedow := false;
completetext := false;
useseconds := true;
if l <= level then begin
  if not quiet then
    writeln(scr,FidoLevel[l]+' '+timestr+' '+s);
  if active then begin
    if isFirst then begin
      writeln(t,'');
      isFirst := false;
      end;
    writeln(t,FidoLevel[l]+' '+copy(datastr,1,7)+timestr+' '+prg+' '+s);
    end;
  end;
end;

procedure TLogFido.setlevel(s : string);
var j : byte;
begin
for j := 0 to sizeof(FidoLevel) do
  if s[1] = FidoLevel[j] then begin
    level := j;
    exit;
    end;
Tlog.setlevel(s);
end;

end.