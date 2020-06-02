{$F+,O+}

unit omunpack;

interface

const msgUnpacking = 80;
      msgPktName   = 81;
      msgMsgFrom   = 82;
      msgMsgInPkt  = 83;
      msgTotPkt    = 84;
      msgTotMsg    = 85;
      msgPrgName   = 86;
      msg2plus     = 87;

procedure unpack(s : string);

implementation

uses ifna,dos,bbsinit,objects,omkill;

procedure unpack(s : string);
var p : Tpacket;
    mes : Pmessage;
    di : searchrec;
    totpkt,msginpkt,totmsg,himsg : longint;
    indir : string;
    kl : PstringCollection;
begin
new(kl,init(2,1));
if s <> '' then
  indir := s
else
  if inbound = nil then indir := '.\' else indir := inbound^;
totpkt := 0;
totmsg := 0;
logf^.print(1,lang^.get(msgUnpacking));
himsg := succ(HighMsg);
findfirst(indir+'*.pkt',archive,di);
while doserror = 0 do with p do begin
  inc(totpkt);
  msginpkt := 0;
  load(indir+di.name);
  kl^.insert(newstr(indir+di.name));
  logf^.printf2s(2,lang^.get(msgPktName),di.name,h^.orig.getstr);
  str(h^.productcode,s);
  logf^.printf2s(3,lang^.get(msgPrgName),
    lang^.get(h^.productcode+10000),s);
  if h^.fsc48 then logf^.print(3,lang^.get(msg2plus));
  Mread;
  while m^.terminator = false do begin
    inc(msginpkt);
    new(mes,init);
    m^.export(mes);
    str(himsg,s);
    mes^.store(msgpath^+s+'.msg');
    inc(himsg);
    logf^.printf2s(3,lang^.get(msgMsgFrom),
      mes^.h^.orig.getstr,mes^.h^.des.getstr);
    dispose(mes,done);
    Mread;
    end;
  done;
  logf^.printf(2,lang^.get(msgMsgInPkt),msginpkt);
  totmsg := totmsg + msginpkt;
  findnext(di);
  end;
logf^.printf(1,lang^.get(msgTotPkt),totpkt);
logf^.printf(2,lang^.get(msgTotMsg),totmsg);
killcollection(kl);
dispose(kl,done);
end;

end.
