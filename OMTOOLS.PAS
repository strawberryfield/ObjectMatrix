{$O+,F+}

unit omtools;

interface

const msgAdjusting = 130;

      msgRenaming = 30;
      msgRenamed  = 31;

      msgRenumbering = 140;

procedure adjust;
procedure renamer(s1,s2 : string);
procedure renumber;

implementation

uses ifna,omobj,stringhe,address,objects,dos,bbsinit;


{ Procedura di correzione zona e point }

type PAdjust = ^TAdjust;
     TAdjust = object(TIterable)
       procedure dojob(m : pmessage); virtual;
       end;

procedure TAdjust.dojob(m : pmessage);
begin
m^.adjust;
m^.store(m^.name^);
end;


procedure Adjust;
var job : PAdjust;
begin
logf^.print(1,lang^.get(msgAdjusting));
new(job,init(AllMsgs));
iterate(job);
dispose(job,done);
end;



{ Funzione Rename }

type Prenamer = ^Trenamer;
     Trenamer = object(TIterable)
       procedure dojob(m : pmessage); virtual;
       end;

var orign,newn : string;

function ToRename(m : pmessage) : boolean;
begin
ToRename := ToMe(m) and BeginOf(orign,uppercase(m^.h^.dest^));
end;

procedure Trenamer.dojob(m : pmessage);
begin
with m^.h^ do begin
  logf^.printf2s(3,lang^.get(msgRenamed),orig.getstr,dest^);
  if dest <> nil then disposestr(dest);
  dest := newstr(newn);
  end;
m^.store(m^.name^);
end;

procedure renamer(s1,s2 : string);
var job : Prenamer;
begin
if s1 = '' then orign := 'SYSOP' else orign := uppercase(s1);
if s2 = '' then newn := sysop^ else newn := s2;
logf^.printf2s(1,lang^.get(msgRenaming),orign,newn);
new(job,init(ToRename));
iterate(job);
dispose(job,done);
end;



{ Funzione Renumber }

type PMsgNum = ^TMsgNum;
     TMsgNum = object(TObject)
       constructor init(di : searchrec);
     private
       n : longint;
       end;

     PMNList = ^TMNList;
     TMNList = object(TSortedCollection)
       function compare(key1,key2 : pointer) : integer; virtual;
       end;

constructor TMsgNum.init(di : searchrec);
var err : integer;
begin
dec(di.name[0],4);
val(di.name,n,err);
end;

function TMNList.compare(key1,key2 : pointer) : integer;
begin
if PMsgNum(key1)^.n = PMsgNum(key2)^.n then compare := 0
else if PMsgNum(key1)^.n > PMsgNum(key2)^.n then compare := 1
else compare := -1;
end;

procedure renumber;
var rl : PMNList;
    di : SearchRec;
    j : longint;

  procedure ren(x : PMsgNum);  far;
  var s : string;
      f : file;
  begin
  inc(j);
  if j <> x^.n then begin
    str(x^.n,s);
    assign(f,msgpath^+s+'.msg');
    str(j,s);
    rename(f,msgpath^+s+'.msg');
    end;
  end;

begin
logf^.print(1,lang^.get(msgRenumbering));
new(rl,init(20,5));
findfirst(msgpath^+'*.msg',archive,di);
while doserror = 0 do begin
  rl^.insert(new(PMsgNum,init(di)));
  findnext(di);
  end;
j := 0;
rl^.foreach(@ren);
logf^.printf(2,lang^.get(msgNumProcessed),j);
dispose(rl,done);
end;

end.
