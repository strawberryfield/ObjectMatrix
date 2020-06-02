{$F+,O+}

unit ifna;

interface

uses objects,address;

const cPacketType = 2;
      cProductCode = $ab;  { ObjectMatrix FTSC product code }
      cMajorRevision = 1;
      cMinorRevision = 99;
      cRevision = cMajorRevision * 256 + cMinorRevision;

      myaddress : Paddress = nil;

      inbound : Pstring = nil;
      outbound : Pstring = nil;
      msgpath : Pstring = nil;

      fPrivate   = 1;
      fCrash     = 2;
      fReceived  = 4;
      fSent      = 8;
      fAttach    = 16;
      fInTransit = 32;
      fOrphan    = 64;
      fKillSent  = 128;
      fLocal     = 256;
      fHold      = 512;
      fUnused    = 1024;
      fReq       = 2048;
      fRetReq    = 4096;
      fIsRetReq  = 8192;
      fAuditReq  = 16384;
      fUpdateReq = 32768;

      fMaskForSend = fPrivate + fCrash + fAttach + fUnused +
                     fRetReq + fIsRetReq + fAuditReq;

      fsPrivate   = 'PVT';
      fsCrash     = 'CRA';
      fsReceived  = 'RCV';
      fsSent      = 'SNT';
      fsAttach    = 'FIL';
      fsKillSent  = 'K/S';
      fsHold      = 'HLD';
      fsReq       = 'FRQ';
      fsRetReq    = 'RRQ';

type TAddr = object
       zone,net,node,point : word;
       procedure putstr(s : string);
       function getstr : string;
       procedure CopyFrom(var a : TAddr);
       end;

     PHeader = ^THeader;
     THeader = object(TObject)
       orig,des : TAddr;
       attribute : word;
       constructor init;
       procedure CopyFrom(h : PHeader);
     private
       procedure putfstr(var s : TStream; x : word; ps : pstring);
       function getfstr(var s : TStream; x : word) : pstring;
       end;

     TPacketTime = object
       year,month,day,hour,min,sec : word;
       procedure load(var s : TStream);
       procedure store(var s : TStream);
       end;

     PPacketHeader = ^TPacketHeader;
     TPacketHeader = object(THeader)
       baud,PacketType,CW,auxnet,
       ProductCode,Revision : word;
       Fsc48 : boolean;
       Password : pstring;
       constructor init;
       constructor load(var s : TStream);
       procedure store(var s : TStream);
       procedure dump(var t : text);
       destructor done; virtual;
     private
       pt : TPacketTime;
       end;

     PMHeader = ^TMHeader;
     TMHeader = object(THeader)
       mitt,dest,subj,datetime : Pstring;
       cost : word;
       constructor init;
       procedure CopyFrom(h : PMHeader);
       destructor done; virtual;
       end;

     PMsgHeader = ^TMsgHeader;
     TMsgHeader = object(TMHeader)
       TimesRead,ReplyTo,NextReply : word;
       constructor load(var s : TStream);
       procedure store(var s : TStream);
       procedure dump(var t : text);
       end;

     PPkdMsgHeader = ^TPkdMsgHeader;
     TPkdMsgHeader = object(TMHeader)
       constructor load(var s : TStream);
       procedure store(var s : TStream);
       procedure dump(var t : text);
     private
       function getPstr(var s : TStream; x : byte) : pstring;
       procedure putPstr(var s : TStream; x : byte; ps : pstring);
       end;

const MsgBufferSize = 20480;

type PMsgBuffer = ^TMsgBuffer;
     TMsgBuffer = array[1..MsgBufferSize] of char;
     PMsgBody = ^TMsgBody;
     TMsgBody = object(TObject)
       b : PMsgBuffer;
       size : word;
       constructor init;
       constructor load(var s : TStream);
       procedure store(var s : TStream);
       procedure putinfo(h : PMHeader);
       procedure putfsc58(h : PMHeader);
       procedure putstr(s : string);
       procedure puthidden(s : string);
       procedure InsStr(s : string);
       function GetHidden(s : string) : string;
       procedure CopyFrom(m : PMsgBody);
       procedure Dump(var t : text);
       destructor done; virtual;
       end;

     PMsgBodyM = ^TMsgBodyM;
     TMsgBodyM = object(TMsgBody)
       constructor load(var s : TStream);
       end;

     PIfnaStream = ^TIfnaStream;
     TIfnaStream = object(TBufStream)
       created : boolean;
       constructor init(n : string);
       constructor load(n : string);
       end;

     PMessage = ^TMessage;
     TMessage = object(TObject)
       s : TIfnaStream;
       h : PMsgHeader;
       m : PMsgBodyM;
       name : Pstring;
       constructor init;
       constructor load(n : string);
       procedure store(n : string);
       procedure adjust;
       procedure dump(var t : text);
       destructor done; virtual;
       end;

     PPkdMessage = ^TPkdMessage;
     TPkdMessage = object(TObject)
       h : PPkdMsgHeader;
       m : PMsgBody;
       terminator : boolean;
       constructor init;
       constructor load(var s : TStream);
       procedure store(var s : TStream);
       constructor import(mm : PMessage);
       procedure export(mm : PMessage);
       procedure dump(var t : text);
       destructor done; virtual;
       end;

     PPacket = ^TPacket;
     TPacket = object(TIfnaStream)
       h : PPacketHeader;
       m : PPkdMessage;
       constructor init(n : string);
       constructor load(n : string);
       procedure MRead;
       procedure MWrite;
       procedure dump(var t : text);
       destructor done; virtual;
     private
       InWrite : boolean;
       end;

     TPriority = (Normal,Crash,Hold,Request,KillNormal,KillCrash,KillHold);
     TAfterSent = (NoProcess,Truncate,Delete);


function highmsg : longint;
function newmsg : string;
function pktname : string;

implementation

uses dos,datestr,drivers,stringhe,doscheck;

{ ----  Funzioni di utilita'  ---- }

function highmsg : longint;
var di : searchrec;
    cmax,c : longint;
    e : integer;
begin
cmax := 0;
findfirst(msgpath^+'*.msg',archive,di);
while doserror = 0 do begin
  val(copy(di.name,1,pos('.',di.name)-1),c,e);
  if e <> 0 then c := 0;
  if c > cmax then cmax := c;
  findnext(di);
  end;
highmsg := cmax;
end;

function newmsg : string;
var s : string;
begin
str(HighMsg + 1,s);
newmsg := msgpath^+s+'.msg';
end;

function pktname : string;
var h,m,s,s1 : word;
    pn : string;
    l : longint;
begin
gettime(h,m,s,s1);
l := (longint((h shl 8) + m) shl 8 + s) shl 8 + s1;
formatstr(pn,'%08x',l);
pktname := pn;
end;

function findbyte(var buf; start,size : word; b : char) : word; assembler;
asm
  les  di,buf
  add  di,start
  mov  cx,size
  sub  cx,start
  mov  al,b
  cld
  repnz scasb
  jz   @trovato

  mov  ax,0ffffh
  jmp  @fine

@trovato:
  mov  ax,size
  sub  ax,cx

@fine:
end;

procedure showflags(x : word; var f : text);
const flags : array[0..15] of string = (
      'Private','Crash','Received','Sent',
      'Attach','InTransit','Orphan','KillSent',
      'Local','Hold','Unused','FileRequest',
      'RetRequest','IsReturnReq','AuditRequest','UpdateRequest');
var k : byte;
    riga : string;
begin
riga := 'Flag:';
for k := 0 to 15 do begin
  if (x and (1 shl k)) <> 0 then
    riga := riga + ' [X] ' + copy(flags[k]+spaces(13),1,13)
  else
    riga := riga + ' [ ] ' + copy(flags[k]+spaces(13),1,13);
  if (k mod 4) = 3 then begin
    writeln(f,riga);
    riga := spaces(5);
    end;
  end;
end;


{ ----  Tipo per gli indirizzi  ---- }

procedure TAddr.putstr(s : string);
begin
parseaddr(s,zone,net,node,point);
if zone = 0 then zone := myaddress^.zone;
end;

function TAddr.getstr : string;
begin
getstr := addstr(zone,net,node,point);
end;

procedure TAddr.copyFrom(var a : Taddr);
begin
move(a.zone,zone,sizeof(Taddr));
if zone = 0 then zone := myaddress^.zone;
end;

{ ----  Tipo fondamentale per gli header  ---- }

constructor THeader.init;
begin
TObject.init;
orig.putstr(myaddress^.complete^);
end;

procedure THeader.CopyFrom(h : PHeader);
begin
move(h^.orig,orig,sizeof(THeader));
end;

procedure THeader.putfstr(var s : TStream; x : word; ps : pstring);
var s1 : string;
begin
fillchar(s1[1],x,#0);
s1[0] := chr(x);
if ps <> nil then s1 := copy(copy(ps^,1,x-1)+s1,1,x);
s.write(s1[1],x);
end;

function THeader.getFstr(var s : TStream; x : word) : pstring;
var s1 : string;
begin
s.read(s1[1],x);
s1[0] := chr(x);
s1[0] := pred(chr(pos(#0,s1)));
if length(s1) = 0 then s1[0] := chr(x);
getFstr := newstr(s1);
end;

{ ----  Timestamp dell'header dei pacchetti  ---- }

procedure TPacketTime.load(var s : Tstream);
begin
s.read(self,sizeof(TPacketTime));
end;

procedure TPacketTime.store(var s : Tstream);
var w : word;
begin
getdate(year,month,day,w);
gettime(hour,min,sec,w);
dec(month);
s.write(self,sizeof(TPacketTime));
end;

{ ----  Header dei pacchetti  ---- }

constructor TPacketHeader.init;
var w : word;
begin
THeader.init;
PacketType := cPacketType;
ProductCode := cProductCode;
Revision := cRevision;
AuxNet := myAddress^.net;
password := newstr(myaddress^.password);
cw := 1;
fsc48 := true;
end;

constructor TPacketHeader.load(var s : TStream);
var w,w1,w2,w3 : word;
begin
s.read(orig.node,sizeof(word));
s.read(des.node,sizeof(word));
pt.load(s);
s.read(baud,sizeof(word));
s.read(PacketType,sizeof(word));
s.read(orig.net,sizeof(word));
s.read(des.net,sizeof(word));
s.read(w1,sizeof(word));
password := getFstr(s,8);
s.read(orig.zone,sizeof(word));
s.read(des.zone,sizeof(word));
s.read(auxnet,sizeof(word));
s.read(w3,sizeof(word));
s.read(w2,sizeof(word));
s.read(cw,sizeof(word));
s.read(orig.zone,sizeof(word));
s.read(des.zone,sizeof(word));
s.read(orig.point,sizeof(word));
s.read(des.point,sizeof(word));
{ fill }
s.read(w,sizeof(word));
s.read(w,sizeof(word));
{ adjust variables }
fsc48 := (cw = swap(w3)) and (cw = 1);
ProductCode := lo(w1);
if fsc48 then ProductCode := ProductCode + lo(w2) shl 8;
Revision := hi(w2) + hi(w1) shl 8;
if fsc48 and (orig.net = $ffff) then orig.net := auxnet;
end;

procedure TPacketHeader.store(var s : TStream);
var w : word;
begin
s.write(orig.node,sizeof(word));
s.write(des.node,sizeof(word));
pt.store(s);
s.write(baud,sizeof(word));
s.write(PacketType,sizeof(word));
if fsc48 and (auxnet <> 0) then orig.net := $ffff;
s.write(orig.net,sizeof(word));
s.write(des.net,sizeof(word));
w := lo(productCode) + hi(Revision) shl 8;
s.write(w,sizeof(word));
putFstr(s,8,password);
s.write(orig.zone,sizeof(word));
s.write(des.zone,sizeof(word));
s.write(auxnet,sizeof(word));
w := swap(CW);
s.write(w,sizeof(word));
w := hi(productCode) + lo(Revision) shl 8;
s.write(w,sizeof(word));
s.write(cw,sizeof(word));
s.write(orig.zone,sizeof(word));
s.write(des.zone,sizeof(word));
s.write(orig.point,sizeof(word));
s.write(des.point,sizeof(word));
{ fill }
s.write(w,sizeof(word));
s.write(w,sizeof(word));
end;

procedure TPacketHeader.dump(var t : text);
begin
writeln(t,chars('=',78));
write(t,  'Tipo: ',packettype);  if fsc48 then write(t,' extended');
writeln(t);
writeln(t,'Da  : ',orig.getstr);
writeln(t,'Per : ',des.getstr);
with pt do
  writeln(t,'Data: ',day,'-',succ(month),'-',year,'  ',
    hour,':',min,':',sec);
writeln(t,'Pasw: ',password^);
write(t,  'Pack: ',productcode,' ',hi(revision));
  if fsc48 then write(t,'.',lo(revision));
  writeln(t);
writeln(t,chars('=',78));
end;

destructor TPacketHeader.done;
begin
if password <> nil then disposestr(password);
THeader.done;
end;

{ ----  Tipo fondamentale per gli header dei messaggi ---- }

constructor TMHeader.init;
begin
THeader.init;
datetime := newstr(datastr+'  '+timestr);
end;

procedure TMHeader.CopyFrom(h : PMHeader);
begin
THeader.CopyFrom(h);
mitt := newstr(h^.mitt^);
dest := newstr(h^.dest^);
subj := newstr(h^.subj^);
disposestr(datetime);
datetime := newstr(copy(h^.datetime^+spaces(19),1,19));
cost := h^.cost;
end;

destructor TMHeader.done;
begin
if datetime <> nil then disposestr(datetime);
if mitt <> nil then disposestr(mitt);
if dest <> nil then disposestr(dest);
if subj <> nil then disposestr(subj);
THeader.done;
end;

{ ----  Header dei messaggi *.msg  ---- }

constructor TMsgHeader.load(var s : TStream);
begin
mitt := getFstr(s,36);
dest := getFstr(s,36);
subj := getFstr(s,72);
datetime := getFstr(s,20);
s.read(timesRead,sizeof(word));
s.read(des.node,sizeof(word));
s.read(orig.node,sizeof(word));
s.read(cost,sizeof(word));
s.read(orig.net,sizeof(word));
s.read(des.net,sizeof(word));
s.read(des.zone,sizeof(word));
s.read(orig.zone,sizeof(word));
s.read(des.point,sizeof(word));
s.read(orig.point,sizeof(word));
s.read(replyTo,sizeof(word));
s.read(attribute,sizeof(word));
s.read(NextReply,sizeof(word));
end;

procedure TMsgHeader.store(var s : TStream);
begin
putFstr(s,36,mitt);
putFstr(s,36,dest);
putFstr(s,72,subj);
putFstr(s,20,datetime);
s.write(timesRead,sizeof(word));
s.write(des.node,sizeof(word));
s.write(orig.node,sizeof(word));
s.write(cost,sizeof(word));
s.write(orig.net,sizeof(word));
s.write(des.net,sizeof(word));
s.write(des.zone,sizeof(word));
s.write(orig.zone,sizeof(word));
s.write(des.point,sizeof(word));
s.write(orig.point,sizeof(word));
s.write(replyTo,sizeof(word));
s.write(attribute,sizeof(word));
s.write(NextReply,sizeof(word));
end;

procedure TMsgHeader.dump(var t : text);
begin
writeln(t,chars('-',78));
writeln(t,'Da  : ',mitt^,' su ',orig.getstr);
writeln(t,'Per : ',dest^,' su ',des.getstr);
writeln(t,'Data: ',datetime^);
writeln(t,'Subj: ',subj^);
showflags(attribute,t);
writeln(t,chars('-',78));
end;

{ ----  Header dei messaggi impacchettati  ---- }

function TPkdMsgHeader.getPstr(var s : TStream; x : byte) : pstring;
var s1 : string;
begin
s1 := '';
repeat
  inc(s1[0]);
  s.read(s1[length(s1)],1);
  until (s1[length(s1)] = #0) or (length(s1) = x);
if length(s1) <> x then dec(s1[0]);
getPstr := newstr(s1);
end;

procedure TPkdMsgHeader.putPstr(var s : TStream; x : byte; ps : pstring);
var s1 : string;
begin
s1 := copy(ps^,1,x-1);
s1 := s1 + #0;
s.write(s1[1],length(s1));
end;

procedure TPkdMsgHeader.store(var s : TStream);
begin
s.write(orig.node,sizeof(word));
s.write(des.node,sizeof(word));
s.write(orig.net,sizeof(word));
s.write(des.net,sizeof(word));
s.write(attribute,sizeof(word));
s.write(cost,sizeof(word));
putFstr(s,20,datetime);
putPstr(s,36,dest);
putPstr(s,36,mitt);
putPstr(s,72,subj);
end;

constructor TPkdMsgHeader.load(var s : TStream);
begin
s.read(orig.node,sizeof(word));
s.read(des.node,sizeof(word));
s.read(orig.net,sizeof(word));
s.read(des.net,sizeof(word));
s.read(attribute,sizeof(word));
s.read(cost,sizeof(word));
datetime := getPstr(s,20);
dest := getPstr(s,36);
mitt := getPstr(s,36);
subj := getPstr(s,72);
end;

procedure TPkdMsgHeader.dump(var t : text);
begin
writeln(t,chars('-',78));
writeln(t,'Da  : ',mitt^,' su ',orig.net,'/',orig.node);
writeln(t,'Per : ',dest^,' su ',des.net,'/',des.node);
writeln(t,'Data: ',datetime^);
writeln(t,'Subj: ',subj^);
showflags(attribute,t);
writeln(t,chars('-',78));
end;


{ ----  Testo dei messaggi  ---- }

constructor TMsgBody.init;
begin
TObject.init;
new(b);
size := 1;
b^[1] := #0;
end;

constructor TMsgBody.load(var s : TStream);
var sz : word;
    c : char;
begin
init;
sz := 0;
repeat
  inc(sz);
  s.read(c,1);
  b^[sz] := c;
  until (c = #0) or (s.status = stReadError);
s.Reset;
if b^[sz] <> #0 then begin
  inc(sz);
  b^[sz] := #0;
  end;
size := sz;
end;

constructor TMsgBodyM.load(var s : TStream);
{ constructor specializzato per messaggi *.msg }
begin
init;
size := s.getsize - s.getpos;
s.read(b^[1],size);
if b^[size] <> #0 then begin
  inc(size);
  b^[size] := #0;
  end;
end;

procedure TMsgBody.store(var s : TStream);
begin
s.write(b^,size);
end;

procedure TMsgBody.putstr(s : string);
begin
move(s[1],b^[size],length(s));
size := size + length(s);
b^[size] := #0;
end;

procedure TMsgBody.PutHidden(s : string);
begin
putstr(#1+s+#13);
end;

procedure TMsgBody.InsStr(s : string);
begin
move(b^[1],b^[succ(length(s))],MsgBufferSize-length(s));
move(s[1],b^[1],length(s));
size := size + length(s);
end;

function TMsgBody.GetHidden(s : string) : string;
var j,k : word;
    l : string;
begin
j := 0;
repeat
  j := findbyte(b^,j,size,#1);
  if j <> $ffff then begin
    k := findbyte(b^,j,size,#13);
    move(b^[succ(j)],l[1],k-j);
    l[0] := pred(chr(k-j));
    j := k;
    if beginof(s,l) then begin
      gethidden := copy(l,succ(pos(' ',l)),255);
      exit;
      end;
    end;
  until j >= size;
gethidden := '';
end;

procedure TMsgBody.putinfo(h : PMHeader);
var s : string;
begin
with h^ do begin
  if (orig.zone <> des.zone) and (orig.zone <> 0) then begin
    putstr(#1+'INTL ');
    s := des.getstr;
    putstr(copy(s,1,pos('.',s)-1)+' ');
    s := orig.getstr;
    putstr(copy(s,1,pos('.',s)-1)+#13);
    end;
  with orig do if point <> 0 then begin
    str(point,s);
    puthidden('FMPT '+s);
    end;
  with des do if point <> 0 then begin
    str(point,s);
    puthidden('TOPT '+s);
    end;
  s := '';
  if (attribute and fPrivate) <> 0 then s := s + ' ' + fsPrivate;
  if (attribute and fCrash) <> 0 then s := s + ' ' + fsCrash;
  if (attribute and fReceived) <> 0 then s := s + ' ' + fsReceived;
  if (attribute and fSent) <> 0 then s := s + ' ' + fsSent;
  if (attribute and fAttach) <> 0 then s := s + ' ' + fsAttach;
  if (attribute and fKillSent) <> 0 then s := s + ' ' + fsKillSent;
  if (attribute and fHold) <> 0 then s := s + ' ' + fsHold;
  if (attribute and fReq) <> 0 then s := s + ' ' + fsReq;
  if (attribute and fRetReq) <> 0 then s := s + ' ' + fsRetReq;
  if s <> '' then puthidden('FLAGS'+s);
  puthidden('MSGID: '+myaddress^.complete^+' '+timestamp);
  end;
putfsc58(h);
end;

procedure TMsgBody.putfsc58(h : PMHeader);
var s : string;
begin
s := gethidden('ORIG');
if s = '' then InsStr(#1+'ORIG '+h^.orig.getstr+#13);
s := gethidden('DEST');
if s = '' then InsStr(#1+'DEST '+h^.des.getstr+#13);
end;

procedure TMsgBody.CopyFrom(m : PMsgBody);
begin
size := m^.size;
move(m^.b^[1],b^[1],size);
end;

procedure TmsgBody.Dump(var t : text);
var j : word;
begin
for j := 1 to size do case b^[j] of
  #1,#32..#127 : write(t,b^[j]);
  #13 : writeln(t);
  end;
end;

destructor TMsgBody.done;
begin
dispose(b);
end;

{ ----  Stream personalizzato  ---- }

const bsize = 2048;

constructor TIfnaStream.init(n : string);
begin
TBufStream.init(n,stOpenWrite,bsize);
if status <> stOk then begin
  reset;
  TBufStream.init(n,stCreate,bsize);
  created := true;
  end;
end;

constructor TIfnaStream.load(n : string);
begin
TBufStream.init(n,stOpenRead,bsize);
end;

{ ----  Messaggio *.msg  ---- }

constructor TMessage.init;
begin
TObject.init;
new(m,init);
new(h,init);
end;

constructor TMessage.load(n : string);
begin
name := newstr(n);
s.load(n);
new(h,load(s));
new(m,load(s));
s.done;
end;

procedure TMessage.store(n : string);
begin
s.init(n);
h^.store(s);
m^.store(s);
s.done;
end;

procedure TMessage.adjust;
var e : integer;
    ss : string;
begin
ss := m^.getHidden('INTL');
if ss = '' then
  if myaddress <> nil then with myaddress^ do begin
    h^.des.zone := zone;
    h^.orig.zone := zone;
    end
  else with h^ do begin
    des.zone := 0;
    orig.zone := 0;
    end
else with h^ do begin
  with des do
    parseaddr(copy(ss,1,pred(pos(' ',ss))),zone,net,node,point);
  with orig do
    parseaddr(copy(ss,succ(pos(' ',ss)),255),zone,net,node,point);
  end;
with h^ do begin
  val(m^.gethidden('FMPT'),orig.point,e);
  if e <> 0 then orig.point := 0;
  val(m^.gethidden('TOPT'),des.point,e);
  if e <> 0 then des.point := 0;
  end;
end;

procedure TMessage.dump(var t : text);
begin
h^.dump(t);
m^.dump(t);
end;

destructor TMessage.done;
begin
dispose(h,done);
dispose(m,done);
if name <> nil then disposestr(name);
end;

{ ----  messaggio impacchettato  ---- }

constructor TPkdMessage.init;
begin
TObject.init;
new(h,init);
new(m,init);
end;

constructor TPkdMessage.load(var s : Tstream);
var w : word;
begin
TObject.init;
s.read(w,sizeof(word));
if w <> 2 then terminator := true
else begin
  new(h,load(s));
  new(m,load(s));
  end;
end;

procedure TPkdMessage.store(var s : Tstream);
var w : word;
begin
w := 2;
s.write(w,sizeof(word));
h^.store(s);
m^.store(s);
end;

constructor TPkdMessage.import(mm : PMessage);
begin
h^.copyFrom(mm^.h);
m^.copyFrom(mm^.m);
end;

procedure TPkdMessage.export(mm : PMessage);
begin
mm^.h^.copyFrom(h);
mm^.m^.copyFrom(m);
mm^.adjust;
end;

procedure TPkdMessage.dump(var t : text);
begin
h^.dump(t);
m^.dump(t);
end;

destructor TPkdMessage.done;
begin
if h <> nil then dispose(h,done);
if m <> nil then dispose(m,done);
end;

{ ----  pacchetto  ---- }

constructor TPacket.init(n : string);
begin
TIfnaStream.init(n);
if created then new(h,init) else seek(getsize - 2);
InWrite := true;
end;

constructor TPacket.load(n : string);
begin
TIfnaStream.load(n);
new(h,load(self));
InWrite := false;
end;

procedure TPacket.MRead;
begin
if m <> nil then dispose(m,done);
new(m,load(self));
end;

procedure TPacket.MWrite;
begin
with m^ do begin
  with h^ do attribute := attribute and fMaskForSend;
  store(self);
  end;
end;

procedure TPacket.dump(var t : text);
begin
h^.dump(t);
Mread;
while m^.terminator = false do begin
  m^.dump(t);
  writeln(t);
  Mread;
  end;
end;

destructor TPacket.done;
var w : word;
begin
if m <> nil then dispose(m,done);
if h <> nil then dispose(h,done);
if InWrite then begin
  w := 0;
  write(w,sizeof(word));
  end;
TIfnaStream.done;
end;

end.
