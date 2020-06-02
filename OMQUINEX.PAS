{$O+,F+}

unit omquinex;

interface

uses qbase;

const msgExport      = 220;
      msgExporting   = 221;
      msgRescan      = 225;
      msgImport      = 230;
      msgImporting   = 231;

type QBcondfunct = function(m : PQBMessage) : boolean;
     PQBIterable = ^TQBIterable;
     TQBIterable = object
       cond : QBcondfunct;
       processed : word;
       constructor init(c : QBcondfunct);
       procedure dojob(m : PQBMessage); virtual;
       destructor done; virtual;
       end;

procedure qbiterate(areanum : byte; p : PQBIterable);
function PendingExport(m : PQBMEssage) : boolean;


procedure export;
procedure rescan;
procedure import;

implementation

uses ifna,objects,omobj,omkill,bbsinit,stringhe;

constructor TQBIterable.init(c : QBcondfunct);
begin
cond := c;
processed := 0;
end;

procedure TQBIterable.dojob(m : PQBMessage);
begin
Abstract;
end;

destructor TQBIterable.done;
var p : longint;
begin
p := processed;
logf^.printf(2,lang^.get(msgNumProcessed),p);
if processed > 0 then omexitcode := 1;
end;

procedure QBiterate(areanum : byte; p : PQBIterable);
var m : PQBMessage;
    nmax,j : word;
begin
new(msgidx,init(qbpath^+'msgidx.bbs',stOpen,2048));
assign(msgtxt,qbpath^+'msgtxt.bbs');
assign(msghdr,qbpath^+'msghdr.bbs');
reset(msgtxt);
reset(msghdr);
nmax := msgidx^.getsize div sizeof(msgidxrecord);

new(m);
with m^ do for j := 0 to pred(nmax) do begin
  fileptr := j;
  msgidx^.read(idx,sizeof(msgidxrecord));
  if (idx.board = areanum) and (idx.msgnum >= 0) then begin
    seek(msghdr,j);
    read(msghdr,hdr);
    if p^.cond(m) then begin
      p^.dojob(m);
      inc(p^.processed);
      end;
    end;
  end;
dispose(msgidx,done);
close(msghdr);
close(msgtxt);
end;

{$F+}
function PendingExport(m : PQBMessage) : boolean;
begin
PendingExport := (m^.hdr.msgattr and 2) <> 0;
end;
{$F-}


type PMatrixExport = ^TMatrixExport;
     TMatrixExport = object(TQBIterable)
       procedure dojob(qm : PQBMessage); virtual;
       end;

procedure TMatrixExport.dojob(qm : PQBMessage);
var fidom : PMessage;
    nb,k : word;
    ss : msgtxtrecord;
    ff : array[1..2] of longint;
begin
ff[1] := qm^.idx.msgnum;
ff[2] := longint(@qm^.hdr.whoto);
logf^.printf(2,lang^.get(msgExporting),ff);
new(fidom,init);
with fidom^ do begin
  with h^ do begin
    mitt := newstr(qm^.hdr.whofrom);
    dest := newstr(qm^.hdr.whoto);
    subj := newstr(qm^.hdr.subject);
    des.net := qm^.hdr.destnet;
    des.node := qm^.hdr.destnode;
    orig.net := qm^.hdr.orignet;
    orig.node := qm^.hdr.orignode;
    attribute := fKillSent;
    if (qm^.hdr.msgattr and 8) <> 0 then attribute := attribute or fPrivate;
    if (qm^.hdr.msgattr and 64) <> 0 then attribute := attribute or fLocal;
    if (qm^.hdr.netattr and 4) <> 0 then attribute := attribute or fAttach;
    if (qm^.hdr.netattr and 8) <> 0 then attribute := attribute or fCrash;
    if (qm^.hdr.netattr and 16) <> 0 then attribute := attribute or fRetReq;
    if (qm^.hdr.netattr and 32) <> 0 then attribute := attribute or fAuditReq;
    if (qm^.hdr.netattr and 64) <> 0 then attribute := attribute or fIsRetReq;
    end;
  seek(msgtxt,qm^.hdr.startblock);
  nb := qm^.hdr.numblocks;
  for k := 1 to nb do begin
    read(msgtxt,ss);
    m^.putstr(ss);
    end;
  adjust;
  store(newmsg);
  end;
dispose(fidom,done);
qm^.hdr.msgattr := qm^.hdr.msgattr and $fd;
seek(msghdr,qm^.fileptr);
write(msghdr,qm^.hdr);
end;

{ Funzioni di interfaccia con il parser per le operazioni  di export }


procedure export;
var job : PMatrixExport;
begin
logf^.print(1,lang^.get(msgExport));
qbconfig(prgpath+prgfile+'.ini');
new(job,init(PendingExport));
qbiterate(netmailarea,job);
dispose(job,done);
end;

{$F+}
function RescanLocals(m : PQBMessage) : boolean;
begin
RescanLocals := (m^.hdr.msgattr and 64) <> 0;
end;

procedure rescan;
var job : PMatrixExport;
begin
logf^.print(1,lang^.get(msgRescan));
qbconfig(prgpath+prgfile+'.ini');
new(job,init(RescanLocals));
qbiterate(netmailarea,job);
dispose(job,done);
end;


{ Iteratore per le funzioni di import }

type PQBImport = ^TQBImport;
     TQBImport = object(TIterable)
       procedure dojob(m : PMessage); virtual;
       destructor done; virtual;
     private
       qbi : PMsgTosser;
       kl : PStringCollection;
       end;

procedure TQBImport.dojob(m : PMessage);
begin
if processed = 0 then begin
  new(qbi,init);
  new(kl,init(10,2));
  end;
with m^.h^ do logf^.printf2s(2,lang^.get(msgImporting),
      orig.getstr,dest^);
qbi^.addNetMail(m,netmailarea);
kl^.insert(newstr(m^.name^));
end;

destructor TQBImport.done;
begin
if processed <> 0 then begin
  dispose(qbi,done);
  killCollection(kl);
  dispose(kl,done);
  end;
TIterable.done;
end;

{$F+}
function MyMatrix(m : pmessage) : boolean;
begin
MyMatrix := ToMe(m) or
  (uppercase(m^.h^.dest^) = uppercase(sysop^));
end;
{$F-}

procedure import;
var job : PQBImport;
begin
logf^.print(1,lang^.get(msgImport));
qbconfig(prgpath+prgfile+'.ini');
new(job,init(MyMatrix));
iterate(job);
dispose(job,done);
end;


end.
