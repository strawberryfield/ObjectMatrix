{$F+,O+}

unit omdump;
{ Visualizza il contenuto dei messaggi in area netmail }

interface

const msgDump         = 210;
      msgInboundDump  = 211;
      msgOutboundDump = 212;

procedure dumpfile(fname : string);
procedure dumpInbound(fname : string);
procedure dumpOutbound(fname : string);

implementation

uses ifna,omobj,bbsinit,dos;

type PReader = ^TReader;
     TReader = object(TIterable)
       f : text;
       constructor init(fname : string);
       procedure dojob(m : pmessage); virtual;
       destructor done; virtual;
       end;

constructor Treader.init(fname : string);
begin
TIterable.init(AllMsgs);
assign(f,fname);
rewrite(f);
end;

destructor TReader.done;
begin
close(f);
TIterable.done;
end;

procedure TReader.dojob(m : PMessage);
begin
m^.dump(f);
end;

procedure dumpfile(fname : string);
var job : PReader;
begin
logf^.print(1,lang^.get(msgDump));
if fname = '' then fname := 'MAILDUMP.OM';
new(job,init(fname));
iterate(job);
dispose(job,done);
end;


procedure dumpInbound(fname : string);
var sr : SearchRec;
    p : Ppacket;
    f : text;
begin
logf^.print(1,lang^.get(msgInboundDump));
if fname = '' then fname := 'INBOUND.OM';
assign(f,fname);
rewrite(f);
findfirst(inbound^+'*.pkt',archive,sr);
while doserror = 0 do begin
  writeln(f,'Packet ',inbound^,sr.name);
  new(p,load(inbound^+sr.name));
  p^.dump(f);
  dispose(p,done);
  findnext(sr);
  end;
close(f);
end;

procedure dumpOutbound(fname : string);
var sr : SearchRec;
    p : Ppacket;
    f : text;
begin
logf^.print(1,lang^.get(msgInboundDump));
if fname = '' then fname := 'OUTBOUND.OM';
assign(f,fname);
rewrite(f);
findfirst(inbound^+'*.?ut',archive,sr);
while doserror = 0 do begin
  writeln(f,'Packet ',outbound^,sr.name);
  new(p,load(inbound^+sr.name));
  p^.dump(f);
  dispose(p,done);
  findnext(sr);
  end;
close(f);
end;

end.
