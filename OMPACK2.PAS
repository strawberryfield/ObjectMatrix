{$F+,O+}

unit ompack2;

interface

uses ifna,address,objects;

const msgMakePacket = 20;
      msgPacking    = 21;
      msgRequest    = 22;
      msgAttach     = 23;
      msgNoZone     = 24;
      msgRequestFw  = 25;
      msgNoPoint    = 26;
      msgCleaning   = 110;
      msgKillPkt    = 111;
      msgListPkt    = 112;
      msgPollPkt    = 115;

      unitid = 2;
      unitcode = unitid * 256 + 16;

var myboss : TAddr;
    noroute,holdl,crashl : PAddressList;

procedure makepacket(s : string);
procedure DumpPacketLink;
procedure pollpkt(s : string);
procedure killpkt;
procedure cleanout;
procedure bundlename(var a : TAddr; var n : string; var error : boolean);
procedure RegisterOmPack;


implementation

uses dos,omkill,omobj,stringhe,drivers,doscheck,ompackcf,datestr,bbsinit;


{ Tipi per la gestione del processing a spedizione avvenuta }

type PMsgAfterSent = ^TMsgAfterSent;
     TMsgAfterSent = object(TObject)
       name : PString;
       flag : char;
       constructor init(m : PMessage);
       constructor load(var s : TStream);
       procedure store(var s : TStream);
       destructor done; virtual;
       procedure process;
       procedure dump(var t : text);
       end;

     PPktAfterSent = ^TPktAfterSent;
     TPktAfterSent = object(TCollection)
       name : PString;
       processed : boolean;
       constructor init(filename : string);
       constructor load(var s : TStream);
       procedure store(var s : TStream);
       destructor done; virtual;
       procedure process;
       procedure kill;
       procedure dump(var t : text);
       end;

     PPktLink = ^TPktLink;
     TPktLink = object(TCollection)
       procedure cleanout;
       procedure kill;
       function findlist(filename : string) : PPktAfterSent;
       procedure dump(var t : text);
       end;

{ Iteratore sulla base messaggi }

     Ppacker = ^Tpacker;
     Tpacker = object(TIterable)
       banner : string;
       mlink : PPktLink;
       constructor init;
       procedure dojob(m : pmessage); virtual;
       destructor done; virtual;
     private
       pkln : string;
       end;

{ Procedure per stabilire i nomi in outbound in stile binkley }

procedure bundlename(var a : TAddr; var n : string; var error : boolean);
var par : array[1..2] of longint;
begin
error := false;

{ Gestione zona }

if (a.zone <> myaddress^.zone) and (a.zone <> 0) then begin
  par[1] := a.zone;
  formatstr(n,
    copy(outbound^,1,pred(length(outbound^))) + '.%03x\',
    par[1]);
  if not pathvalid(n) then begin
    logf^.printf(1,lang^.get(msgNoZone),par[1]);
    error := true;
    exit;
    end;
  if n[length(n)] <> '\' then n := n + '\';
  end
else n := outbound^;

{ Gestione nodo }

par[1] := a.net;
par[2] := a.node;
formatstr(n,n+'%04x%04x',par);

{ Gestione point }

if a.point <> 0 then begin
  n := n + '.pnt\';
  if not pathvalid(n) then begin
    n := a.getstr;
    par[1] := longint(@n);
    logf^.printf(1,lang^.get(msgNoPoint),par[1]);
    error := true;
    exit;
    end;
  if n[length(n)] <> '\' then n := n + '\';
  par[1] := a.point;
  formatstr(n,n+'%08x',par[1]);
  end;
end;

{ Binkley-Style flow files manager }

type PBinkFlow = ^TBinkFlow;
     TBinkFlow = object(TObject)
       name : PString;
       error : boolean;
       constructor init(var a : Taddr; mode : TPriority);
       procedure append(s : string; mode : TAfterSent);
       destructor done; virtual;
       end;

constructor TBinkFlow.init(var a : Taddr; mode : TPriority);
var s : string;
begin
TObject.init;
bundlename(a,s,error);
if error then exit;
case mode of
  normal  : name := newstr(s+'.flo');
  crash   : name := newstr(s+'.clo');
  hold    : name := newstr(s+'.hlo');
  request : name := newstr(s+'.req');
  end;
end;

procedure TBinkFlow.append(s : string; mode : TAfterSent);
var t : text;
    s1,s2 : string;
begin
assign(t,name^);
{$I-}
system.append(t);
{$I+}
if ioresult <> 0 then rewrite(t);
repeat
  splitline(s,s1,s2);
  case mode of
    truncate : s1 := '#'+s1;
    delete   : s1 := '^'+s1;
    end;
  writeln(t,s1);
  s := s2;
  until s = '';
close(t);
end;

destructor TBinkFlow.done;
begin
if name <> nil then disposestr(name);
end;


{ Binkley-Style netmail packets manager }

type PBinkBundle = ^TBinkBundle;
     TBinkBundle = object(TPacket)
       name : PString;
       err : boolean;
       constructor init(var a : Taddr; mode : TPriority);
       procedure append(sm : PMessage);
       destructor done; virtual;
       end;

constructor TBinkBundle.init(var a : Taddr; mode : TPriority);
var s : string;
begin
name := nil;
bundlename(a,s,err);
if err then exit;
case mode of
  normal  : s := s+'.out';
  crash   : s := s+'.cut';
  hold    : s := s+'.hut';
  end;
TPacket.init(s);
name := newstr(s);
if created then begin
  h^.des.copyfrom(a);
  h^.store(self);
  end;
end;

procedure TBinkBundle.append(sm : PMessage);
begin
new(m,init);
m^.import(sm);
mwrite;
dispose(m,done);
m := nil;
end;

destructor TBinkBundle.done;
begin
if name <> nil then disposestr(name);
TPacket.done;
end;


{ Gestione del file indice PKTLINK.OM }

function GetPacketLink : PPktLink;
var pkln : string;
    s : PBufStream;
begin
pkln := prgpath + 'PKTLINK.OM';
new(s,init(pkln,stOpenRead,2048));
if s^.status = 0 then GetPacketLink := PPktLink(s^.get)
else GetPacketLink := new(PPktLink,init(20,4));
s^.reset;
dispose(s,done);
end;

procedure PutPacketLink(l : PPktLink);
var pkln : string;
    s : PBufStream;
begin
pkln := prgpath + 'PKTLINK.OM';
new(s,init(pkln,stOpenWrite,2048));
if s^.status <> 0 then begin
  s^.reset;
  new(s,init(pkln,stCreate,2048));
  dispose(s,done);
  new(s,init(pkln,stOpenWrite,2048));
  end;
s^.put(l);
s^.truncate;
dispose(s,done);
dispose(l,done);
end;

procedure DumpPacketLink;
var mlink : PPktLink;
    t : text;
begin
logf^.print(1,lang^.get(msgListPkt));
mlink := GetPacketLink;
assign(t,prgpath+'PKTLIST.OM');
rewrite(t);
mlink^.dump(t);
close(t);
dispose(mlink,done);
end;


{ Procedura per creare un pacchetto fittizio per il poll }

procedure pollpkt(s : string);
var f : PBinkFlow;
    a : Taddr;
    mlink : PPktLink;
    dum   : PPktAfterSent;
    p : pointer;
begin
p := @s;
logf^.printf(1,lang^.get(msgPollPkt),p);
a.putstr(s);
new(f,init(a,crash));
if not f^.error then begin
  f^.append('',NoProcess);
  mlink := GetPacketLink;
  dum := mlink^.findlist(f^.name^);
  PutPacketLink(mlink);
  end;
dispose(f,done);
end;

var kl : PStringCollection;


{ Modulo contenente il nome del file e del flag per il processing }

constructor TMsgAfterSent.init(m : PMessage);
begin
name := newstr(m^.name^);
if (m^.h^.attribute and fKillSent) <> 0 then flag := 'K' else flag := 'S';
end;

constructor TMsgAfterSent.load(var s : TStream);
begin
name := s.readstr;
s.read(flag,sizeof(char));
end;

procedure TMsgAfterSent.store(var s : TStream);
begin
s.writestr(name);
s.write(flag,sizeof(char));
end;

destructor TMsgAfterSent.done;
begin
if name <> nil then disposestr(name);
end;

procedure TMsgAfterSent.process;

  procedure kill;
  begin
  kl^.insert(newstr(name^));
  end;

  procedure sent;
  var m : PMessage;
  begin
  new(m,load(name^));
  with m^.h^ do attribute := attribute or fSent;
  dispose(m,done);
  end;

begin
case flag of
  'K' : kill;
  'S' : sent;
  end;
end;

procedure TMsgAfterSent.dump(var t : text);
begin
writeln(t,' (',flag,') ',name^);
end;


{ Lista dei messaggi contenuti nei singoli pacchetti }

constructor TPktAfterSent.init(filename : string);
begin
TCollection.init(10,2);
name := newstr(filename);
processed := false;
end;

constructor TPktAfterSent.load(var s : TStream);
begin
name := s.readstr;
TCollection.load(s);
processed := false;
end;

procedure TPktAfterSent.store(var s : TStream);
begin
s.writestr(name);
TCollection.store(s);
end;

destructor TPktAfterSent.done;
begin
if name <> nil then disposestr(name);
TCollection.done;
end;

procedure TPktAfterSent.process;
var di : searchrec;

  procedure processa(x : PMsgAfterSent); far;
  begin
  x^.process;
  end;

begin
findfirst(name^,archive,di);
if doserror <> 0 then begin
  foreach(@processa);
  processed := true;
  end;
end;

procedure TPktAfterSent.kill;
begin
kl^.insert(newstr(name^));
end;

procedure TPktAfterSent.dump(var t : text);

  procedure stampa(p : PMsgAfterSent);  far;
  begin
  p^.dump(t);
  end;

begin
writeln(t,name^);
foreach(@stampa);
writeln(t);
end;


{ Lista principale che contiene tutti i nomi dei pacchetti }

procedure TPktLink.cleanout;

  procedure processa(p : PPktAfterSent); far;
  begin
  p^.process;
  if p^.processed then free(p);
  end;

begin
foreach(@processa);
end;

procedure TPktLink.kill;

  procedure processa(p : PPktAfterSent); far;
  begin
  p^.kill;
  end;

begin
foreach(@processa);
freeall;
end;

function TPktLink.findlist(filename : string) : PPktAfterSent;
var tmp : PPktAfterSent;

  function cerca(p : PPktAfterSent) : boolean; far;
  begin
  cerca := p^.name^ = filename;
  end;

begin
tmp := FirstThat(@cerca);
if tmp = nil then begin
  new(tmp,init(filename));
  insert(tmp);
  end;
findlist := tmp;
end;

procedure TPktLink.dump(var t : text);

  procedure stampa(p : PPktAfterSent);  far;
  begin
  p^.dump(t);
  end;

begin
foreach(@stampa);
end;


{ Procedura che effettua il post-processing dei messaggi }

procedure cleanout;
var mlink : PPktLink;
begin
logf^.print(1,lang^.get(msgCleaning));
mlink := GetPacketLink;
new(kl,init(20,4));
mlink^.cleanout;
putPacketLink(mlink);
killcollection(kl);
dispose(kl,done);
end;

procedure KillPkt;
var mlink : PPktLink;
begin
logf^.print(1,lang^.get(msgKillPkt));
new(kl,init(20,4));
mlink := GetPacketLink;
mlink^.kill;
PutPacketLink(mlink);
killcollection(kl);
dispose(kl,done);
end;

{ Routines di packing }

function ToPack(m : pmessage) : boolean;
begin
ToPack := (not ToMe(m)) and
          ((m^.h^.attribute and fSent) = 0);
end;

constructor Tpacker.init;
begin
Titerable.init(ToPack);
new(kl,init(20,4));
mlink := GetPacketLink;
usedow := true;
banner := #13#1+'Via node '+myaddress^.complete^+
          ' '+datastr+' '+timestr+' ('+prgsign+')'+#13;
usedow := false;
end;

destructor TPacker.done;
begin
PutPacketLink(mlink);
killcollection(kl);
dispose(kl,done);
TIterable.done;
end;


function IsMail(s : string) : boolean;
begin
s := uppercase(copy(s,succ(pos('.',s)),2));
IsMail := (s = 'MO') or (s = 'TU') or (s = 'WE') or
          (s = 'TH') or (s = 'FR') or (s = 'SA') or (s = 'SU');
end;


{ Nucleo centrale delle operazioni di packing }

procedure TPacker.dojob(m : Pmessage);

  procedure UpdateMlink(pk : Pstring);
  var pas : PPktAfterSent;
  begin
  pas := mlink^.findlist(pk^);
  pas^.insert(new(PMsgAfterSent,init(m)));
  end;

  procedure FileRequest;
  var f : PBinkFlow;
  begin
  with m^.h^ do begin
    logf^.printf2s(3,lang^.get(msgRequest),subj^,des.getstr);
    new(f,init(des,Request));
    if not f^.Error then begin
      f^.append(subj^,NoProcess);
      updateMLink(f^.name);
      end;
    end;
  dispose(f,done);
  end;

  procedure FileRequestError;
  begin
  with m^.h^ do logf^.printf2s(0,lang^.get(msgRequestFw),orig.getstr,des.getstr);
  kl^.insert(newstr(m^.name^));
  end;

  procedure PackMsg(a : TAddr; mode : TPriority);
  var p : PBinkBundle;

    procedure Attach;
    var f : PBinkFlow;
    begin
    with m^.h^ do begin
      logf^.printf2s(3,lang^.get(msgAttach),subj^,des.getstr);
      new(f,init(a,mode));
      if not f^.Error then begin
        if Ismail(subj^) then f^.append(subj^,Truncate)
        else f^.append(subj^,NoProcess);
        UpdateMlink(f^.name);
        end;
      end;
    dispose(f,done);
    end;

  begin
  with m^.h^ do begin
    if (attribute and fAttach) <> 0 then begin
      Attach;
      if IsMail(subj^) then exit;
      end;
    logf^.printf2s(3,lang^.get(msgPacking),dest^,des.getstr);
    new(p,init(a,mode));
    if not p^.Err then begin
      m^.m^.putstr(banner);
      p^.append(m);
      if (attribute and fAttach) = 0 then updateMlink(p^.name);
      end;
    dispose(p,done);
    end;
  end;

  procedure PackMyHold;
  begin
  PackMsg(m^.h^.des,Hold);
  end;

  procedure PackMyCrash;
  var a : TAddr;
  begin
  a.copyfrom(m^.h^.des);
  a.point := 0;
  PackMsg(a,Crash);
  end;

var PackTo : TAddr;

  function IsThere(x : PAddress) : boolean;  far;
  begin
  with PackTo do IsThere := x^.equal(zone,net,node,point);
  end;

label endloop,again;
begin
with m^.h^ do begin

  if FromMe(m) then begin
    if (attribute and fReq) <> 0 then begin
      FileRequest;
      goto endloop;
      end;

    if (attribute and fHold) <> 0 then begin
      PackMyHold;
      goto endloop;
      end;

    if (attribute and fCrash) <> 0 then begin
      PackMyCrash;
      goto endloop;
      end;
    end

  else if (attribute and fReq) <> 0 then begin
    FileRequestError;
    goto endloop;
    end;

  packto.copyfrom(des);

again:
  if holdl^.firstThat(@IsThere) <> nil then begin
    PackMsg(packto,hold);
    goto endloop;
    end;

  if crashl^.firstThat(@IsThere) <> nil then begin
    PackMsg(packto,crash);
    goto endloop;
    end;

  if noroute^.firstThat(@IsThere) <> nil then begin
    PackMsg(packto,normal);
    goto endloop;
    end;

  if packto.getstr <> myboss.getstr then begin
    Packto.copyfrom(myboss);
    goto again;
    end
  else PackMsg(myboss,normal);
  end;

endloop:
end;


{ procedura di interfaccia con le unit esterne }

procedure makepacket(s : string);
var job : Ppacker;
begin
logf^.print(1,lang^.get(msgMakePacket));
new(noroute,init(10,2));
new(crashl,init(10,2));
new(holdl,init(10,2));
GetPackerConfig(s);
new(job,init);
iterate(job);
dispose(job,done);
dispose(noroute,done);
dispose(crashl,done);
dispose(holdl,done);
end;


{ Procedure e definizioni di servizio }

const RMsgAfterSent : TStreamRec = (
        ObjType : unitcode + 1;
        VmtLink : ofs(typeof(TMsgAfterSent)^);
        Load    : @TMsgAfterSent.load;
        Store   : @TMsgAfterSent.store
        );
      RPktAfterSent : TStreamRec = (
        ObjType : unitcode + 2;
        VmtLink : ofs(typeof(TPktAfterSent)^);
        Load    : @TPktAfterSent.load;
        Store   : @TPktAfterSent.store
        );
      RPktLink : TStreamRec = (
        ObjType : unitcode + 3;
        VmtLink : ofs(typeof(TPktLink)^);
        Load    : @TPktLink.load;
        Store   : @TPktLink.store
        );

procedure RegisterOmPack;
begin
RegisterType(RMsgAfterSent);
RegisterType(RPktAfterSent);
RegisterType(RPktLink);
end;

end.