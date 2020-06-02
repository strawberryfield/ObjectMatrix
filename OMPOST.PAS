{$O+,F+}

unit ompost;

interface

const msgPosted  = 70;

      msgReplying  = 40;
      msgReplySubj = 41;
      msgReplyDate = 42;
      msgReplyTo   = 43;
      msgReplyGenerated = 44;

procedure reply;
procedure post(destin,addr,subject,f,priority : string);

implementation

uses omobj,address,ifna,stringhe,objects,drivers,bbsinit;

procedure post(destin,addr,subject,f,priority : string);
var s : string;
    m : Pmessage;
    t : text;
begin
new(m,init);
with m^ do begin
  with h^ do begin
    mitt := newstr(sysop^);
    dest := newstr(copy(NoUnderscore(destin),1,36));
    subj := newstr(copy(NoUnderscore(subject),1,72));
    des.putstr(addr);
    attribute := fKillSent + fPrivate + fRetReq;
    if priority <> '' then begin
      if UpCase(priority[1]) = 'C' then attribute := attribute + fCrash;
      if UpCase(priority[1]) = 'H' then attribute := attribute + fHold;
      end;
    end;
  m^.puthidden('ORIG '+myaddress^.complete^);
  m^.putinfo(h);
  with m^ do begin
    putstr(prgpid+#13);
    assign(t,f);
    reset(t);
    repeat
      read(t,b^[size]);
      inc(size);
      until eof(t);
    close(t);
    putstr(#13+prgtear+#13);
    end;
  store(newmsg);
  end;
dispose(m,done);
logf^.printf2s(1,lang^.get(msgPosted),NoUnderscore(destin),addr);
end;



{ Generazione ricevute di ritorno }

type Phead = ^Thead;
     Thead = object(Tobject)
       h : PMsgHeader;
       id,fm : pstring;
       constructor init(m : PMessage);
       destructor done; virtual;
       end;

     Preply = ^Treply;
     Treply = object(TIterable)
       list : Tcollection;
       constructor init;
       procedure dojob(m : pmessage); virtual;
       destructor done; virtual;
       end;

var hm : longint;

constructor Thead.init(m : Pmessage);
begin
new(h,init);
h^.copyFrom(m^.h);
id := newstr(m^.m^.gethidden('MSGID:'));
fm := newstr(m^.m^.gethidden('ORIG'));
end;

destructor Thead.done;
begin
dispose(h,done);
if id <> nil then disposestr(id);
if fm <> nil then disposestr(fm);
end;

function ToReply(m : pmessage) : boolean;
begin
ToReply := ToMe(m) and (
  ((m^.h^.attribute and fRetReq) <> 0 ) or
  ( pos('*RR*', m^.h^.subj^) <> 0) );
end;

constructor Treply.init;
begin
Titerable.init(ToReply);
list.init(10,2);
end;

procedure Treply.dojob(m : pmessage);
var n : string;
    j : byte;
begin
list.insert(new(Phead,init(m)));
with m^ do begin
  with h^ do begin
    j := pos('*RR*',subj^);
    if j <> 0 then begin
      n := subj^;
      system.delete(n,j,4);
      disposestr(subj);
      subj := newstr(n);
      end;
    attribute := attribute and not fRetReq;
    logf^.printf2s(3,lang^.get(msgReplyTo),mitt^,orig.getstr);
    end;
  m^.insstr(#1+lang^.get(msgReplyGenerated)+#13);
  store(name^);
  end;
end;


destructor Treply.done;

  procedure CreateMsg(oh : phead); far;
  var n : string;
      m : Tmessage;
  begin
  inc(hm);
  formatstr(n,msgpath^+'%d'+'.msg',hm);
  with m do begin
    init;
    with h^ do begin
      attribute := fLocal + fPrivate + fKillSent + fIsRetReq;
      des.copyFrom(oh^.h^.orig);
      mitt := newstr(sysop^);
      subj := newstr(lang^.get(msgReplySubj));
      dest := newstr(oh^.h^.mitt^);
      end;
    with m^ do begin
      puthidden('ORIG '+myaddress^.complete^);
      if oh^.fm <> nil then puthidden('DEST '+oh^.fm^);
      putinfo(h);
      if oh^.id <> nil then puthidden('REPLY: '+oh^.id^);
      putstr(prgpid+#13);
      putstr(systemname^+' ('+myaddress^.complete^+')'+#13);
      putstr(lang^.get(msgReplyDate)+' '+oh^.h^.datetime^+#13);
      putstr('('+oh^.h^.subj^+')'+#13);
      putstr(#13+prgtear+#13);
      end;
    store(n);
    done;
    end;
  end;

begin
list.forEach(@createMsg);
list.done;
Titerable.done;
end;


procedure reply;
var job : Preply;
begin
logf^.print(1,lang^.get(msgReplying));
hm := highmsg;
new(job,init);
iterate(job);
dispose(job,done);
end;

end.
