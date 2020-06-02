{$O+,F+}

unit omattach;

interface

const msgAttached  = 100;
      msgRequested  = 90;

procedure filereq(addr,subject : string);
procedure fileattach(addr,subject,priority,mode : string);
procedure hatch(addr,subject,area,desc,priority : string);

implementation

uses bbsinit,ifna,objects,datestr,stringhe,crc;

procedure makemsg(var addr,subject : string; attr : word);
var m : Pmessage;
begin
new(m,init);
with m^ do begin
  with h^ do begin
    mitt := newstr(prgname);
    dest := newstr('SysOp');
    subj := newstr(subject);
    des.putstr(addr);
    attribute := attr or (fLocal + fKillSent + fPrivate);
    end;
  m^.puthidden('ORIG '+myaddress^.complete^);
  m^.putinfo(h);
  m^.putstr(prgpid+#13);
  store(newmsg);
  end;
dispose(m,done);
end;

procedure fileattach(addr,subject,priority,mode : string);
var attr : word;
    a : Taddr;
begin
if priority = '' then priority := 'Hold';
if mode = '' then mode := 'NoProcess';
attr := fAttach;
case upcase(priority[1]) of
  'C' : attr := attr + fCrash;
  'H' : attr := attr + fHold;
  end;
makemsg(addr,subject,attr);
logf^.printf2s(1,lang^.get(msgAttached),subject,addr);
end;


procedure hatch(addr,subject,area,desc,priority : string);
var tic : text;
    ticname : string;
begin
fileattach(addr,subject,priority,'');
ticname := 'OM'+copy(timestamp,3,8)+'.TIC';
assign(tic,ticname);
rewrite(tic);

writeln(tic,'Area '+area);
writeln(tic,'Origin '+myaddress^.complete^);
writeln(tic,'From '+myaddress^.fakestring);
writeln(tic,'File '+subject);
writeln(tic,'Desc '+desc);
writeln(tic,'Crc '+hexlong(filecrc(subject)));
writeln(tic,'Created by ',prgbanner+' - ',prgcopyright);
writeln(tic,'Path ',myaddress^.fakestring,' ',unixstamp);
writeln(tic,'Seenby '+myaddress^.fakestring);
writeln(tic,'Seenby '+addr);
close(tic);
fileattach(addr,ticname,priority,'Delete');
end;



procedure filereq(addr,subject : string);
var a : Taddr;
begin
makemsg(addr,subject,fReq);
logf^.printf2s(1,lang^.get(msgRequested),subject,addr);
end;

end.