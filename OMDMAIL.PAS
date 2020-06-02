{$F+,O+}

unit omdmail;
{ mailer per dischetti, utile quando si passa da Mario }

interface

const msgCopyMail  = 200;
      msgCopying   = 201;
      msgCopySize  = 202;
      msgCopied    = 203;
      msgTotalSize = 204;

function filecopy(f1,f2 : string) : longint;
procedure diskmail(add,disk : string);

implementation

uses bbsinit,ifna,dos,omkill,objects,doscheck,ompack2;

function filecopy(f1,f2 : string) : longint;
var FromF, ToF: file;
    NumRead, NumWritten: Word;
    buf: array[1..2048] of Char;
    l : longint;
begin
Assign(FromF, f1);
Reset(FromF, 1);
Assign(ToF, f2);
Rewrite(ToF, 1);
l := FileSize(FromF);
logf^.printf2s(2,lang^.get(msgCopying),f1,f2);
repeat
  BlockRead(FromF,buf,SizeOf(buf),NumRead);
  BlockWrite(ToF,buf,NumRead,NumWritten);
  until (NumRead = 0) or (NumWritten <> NumRead);
Close(FromF);
Close(ToF);
logf^.printf(3,lang^.get(msgCopySize),l);
filecopy := l;
end;

procedure diskmail(add,disk : string);
var di : searchrec;
    d : dirstr;
    n : namestr;
    e : extstr;
    ta : Taddr;
    s,bn : string;
    ts,tf : longint;
    kl,tl : PStringCollection;
    t : text;
    err : boolean;
begin
logf^.printf2s(1,lang^.get(msgCopyMail),add,disk);
new(kl,init(10,2));
new(tl,init(10,2));
ta.putstr(add);
bundlename(ta,bn,err);
if not err then begin
  ts := 0;
  tf := 0;
  if not pathvalid(disk) then halt;
  disk := disk +'\';

  findfirst(bn+'.?UT',archive,di);
  while doserror = 0 do begin
    inc(tf);
    fsplit(di.name,d,n,e);
    ts := ts + filecopy(bn+e,disk+pktname+'.pkt');
    kl^.insert(newstr(bn+e));
    findnext(di);
    end;

  findfirst(bn+'.?LO',archive,di);
  while doserror = 0 do begin
    fsplit(di.name,d,n,e);
    kl^.insert(newstr(bn+e));
    assign(t,bn+e);
    reset(t);
    while not eof(t) do begin
      readln(t,s);
      case s[1] of
        '^' : begin
              s := copy(s,2,255);
              kl^.insert(newstr(s));
              end;
        '#' : begin
              s := copy(s,2,255);
              tl^.insert(newstr(s));
              end;
        end;
      fsplit(s,d,n,e);
      inc(tf);
      ts := ts + filecopy(s,disk+n+e);
      end;
    close(t);
    findnext(di);
    end;
  logf^.printf(2,lang^.get(msgCopied),tf);
  logf^.printf(3,lang^.get(msgTotalSize),ts);
  killCollection(kl);
  truncCollection(tl);
  end;
dispose(kl,done);
dispose(tl,done);
end;


end.
