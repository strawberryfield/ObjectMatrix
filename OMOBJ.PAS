{$F+,O+}

unit omobj;

interface

uses objects,ifna,address,logfile,dos;


       { ** Definizioni per iterazione funzioni ** }

type condfunct = function(m : pmessage) : boolean;
     PIterable = ^TIterable;
     TIterable = object
       cond : condfunct;
       processed : word;
       constructor init(c : condfunct);
       procedure dojob(m : pmessage); virtual;
       destructor done; virtual;
       end;

procedure iterate(p : PIterable);
function FromMe(m : pmessage) : boolean;
function ToMe(m : pmessage) : boolean;
function AllMsgs(m : pmessage) : boolean;

implementation

uses drivers,bbsinit;

       { ** Definizioni per iterazione funzioni ** }

constructor TIterable.init(c : condfunct);
begin
cond := c;
processed := 0;
end;

procedure TIterable.dojob(m : pmessage);
begin
Abstract;
end;

destructor TIterable.done;
var p : longint;
begin
p := processed;
logf^.printf(2,lang^.get(msgNumProcessed),p);
if processed > 0 then omexitcode := 1;
end;

procedure iterate(p : PIterable);
var di : searchrec;
    m : pmessage;
begin
findfirst(msgpath^+'*.msg',archive,di);
while doserror = 0 do begin
  new(m,load(msgpath^+di.name));
  if p^.cond(m) then begin
    p^.dojob(m);
    inc(p^.processed);
    end;
  dispose(m,done);
  findnext(di);
  end;
end;

{$F+}
function FromMe(m : pmessage) : boolean;

  function check(item : Paddress) : boolean;
  begin
  with m^.h^.orig do
    check := item^.equal(zone,net,node,point);
  end;

begin
with m^.h^.orig do
  FromMe := myaddress^.equal(zone,net,node,point)
         or ((akas^.count <> 0) and (akas^.FirstThat(@check) <> nil));
end;

function ToMe(m : pmessage) : boolean;

  function check(item : Paddress) : boolean;
  begin
  with m^.h^.des do
    check := item^.equal(zone,net,node,point);
  end;

begin
with m^.h^.des do
  ToMe := myaddress^.equal(zone,net,node,point)
         or ((akas^.count <> 0) and (akas^.FirstThat(@check) <> nil));
end;

function AllMsgs(m : pmessage) : boolean;
begin
AllMsgs := true;
end;
{$F-}

end.
