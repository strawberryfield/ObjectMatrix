{$F+,O+}
Unit qbase;

interface

uses objects,dos,ifna;

  type
    MsgType    = (Local, NetMail, EchoMail);
    FlagType   = Array[1..4] of Byte;
    Time       = String[5];
    Date       = String[8];
    LongDate   = String[9];

    NetNode    = Record
      Zone,
      Net,
      Node   : Word;
    end;

    NetAddress = record
      Zone,
      Net,
      Node,
      Point  : Word;
    end;

    MSGINFOrecord = Record
      LowMsg,
      HighMsg,
      TotalMsgs    : Word;
      TotalOnBoard : Array[1..200] of Word;
    end;

    MSGIDXrecord = Record
      MsgNum : Integer;
      Board  : Byte;
    end;

    MSGTOIDXrecord = String[35];

    MSGHDRrecord = Record
      MsgNum     : Integer;
      PrevReply,
      NextReply,
      TimesRead  : Word;
      StartBlock : Word;
      NumBlocks,
      DestNet,
      DestNode,
      OrigNet,
      OrigNode   : Word;
      DestZone,
      OrigZone   : Byte;
      Cost       : Word;
      MsgAttr,
        {
  1       Bit 0: Deleted
  2       Bit 1: Unmoved Outgoing Net Message
  4       Bit 2: Is a Net Mail Message
  8       Bit 3: Private
  16      Bit 4: Received
          Bit 5: Unmoved Outgoing Echo Message
          Bit 6: Local Bit
          Bit 7: [ Reserved ]
        }
      NetAttr,
        {
          Bit 0: Kill/sent
          Bit 1: Sent
          Bit 2: File Attach
          Bit 3: Crash
          Bit 4: Request Receipt
          Bit 5: Audit Request
          Bit 6: Is a Return Receipt
          Bit 7: [ Reserved ]
        }
      Board      : Byte;
      PostTime   : Time;
      PostDate   : Date;
      WhoTo,
      WhoFrom    : MSGTOIDXrecord;
      Subject    : String[72];
    end;

    MSGTXTrecord   = String[255];

    PQBmessage = ^TQBMessage;
    TQBmessage = record
      fileptr : word;
      idx : msgidxrecord;
      hdr : msghdrrecord;
      end;

    PMsgInfo = ^TMsgInfo;
    TMsgInfo = object(TObject)
      data : MsgInfoRecord;
      constructor init;
      procedure save;
      procedure addMsg(area : byte);
    private
      f : file of MsgInfoRecord;
      end;

    PMsgTosser = ^TMsgTosser;
    TMsgTosser = object
      constructor init;
      procedure addnetmail(m : PMessage; area : word);
      destructor done;
    private
      info : PMsgInfo;
      txtblock : word;
      end;

var msgidx,msgtoidx : PBufStream;
    msghdr : file of msghdrrecord;
    msgtxt : file of msgtxtrecord;
    qbpath : Pstring;
    netmailarea : byte;

procedure qbconfig(s : string);

implementation

uses inifile,stringhe;

constructor TMsgInfo.init;
begin
assign(f,qbpath^+'msginfo.bbs');
reset(f);
read(f,data);
close(f);
end;

procedure TMsgInfo.save;
begin
assign(f,qbpath^+'msginfo.bbs');
rewrite(f);
write(f,data);
close(f);
end;

procedure TMsgInfo.addMsg(area : byte);
begin
with data do begin
  inc(HighMsg);
  inc(TotalMsgs);
  inc(TotalOnBoard[area]);
  end;
end;

constructor TMsgTosser.init;
begin
assign(msgtxt,qbpath^+'msgtxt.bbs');
assign(msghdr,qbpath^+'msghdr.bbs');
reset(msgtxt);
reset(msghdr);
txtblock := filesize(msgtxt);
seek(msgtxt,txtblock);
seek(msghdr,filesize(msghdr));
new(info,init);
new(msgidx,init(qbpath^+'msgidx.bbs',stOpen,2048));
new(msgtoidx,init(qbpath^+'msgtoidx.bbs',stOpen,2048));
msgidx^.seek(msgidx^.getsize);
msgtoidx^.seek(msgtoidx^.getsize);
end;

procedure TMsgTosser.addNetMail(m : PMessage; area : word);
var mh : msghdrrecord;
    idx : msgidxrecord;
    s : msgtxtrecord;
    j : integer;
begin
info^.addmsg(area);
idx.board := area;
idx.msgnum := info^.data.HighMsg;
msgidx^.write(idx,sizeof(idx));
fillchar(mh,sizeof(mh),#0);
with mh do begin
  whoto := copy(m^.h^.dest^,1,35);
  msgtoidx^.write(whoto,sizeof(whoto));
  MsgNum := info^.data.HighMsg;
  DestNet := m^.h^.des.net;
  DestNode := m^.h^.des.node;
  DestZone := (m^.h^.des.zone) and $ff;
  OrigNet := m^.h^.orig.net;
  OrigNode := m^.h^.orig.node;
  OrigZone := (m^.h^.orig.zone) and $ff;
  Board := area;
  WhoFrom := copy(m^.h^.mitt^,1,35);
  Subject := copy(m^.h^.subj^,1,72);

  PostDate := uppercase(copy(m^.h^.datetime^,4,3));
  if PostDate = 'JAN' then PostDate := '01'
  else if PostDate = 'FEB' then PostDate := '02'
  else if PostDate = 'MAR' then PostDate := '03'
  else if PostDate = 'APR' then PostDate := '04'
  else if PostDate = 'MAY' then PostDate := '05'
  else if PostDate = 'JUN' then PostDate := '06'
  else if PostDate = 'JUL' then PostDate := '07'
  else if PostDate = 'AUG' then PostDate := '08'
  else if PostDate = 'SEP' then PostDate := '09'
  else if PostDate = 'OCT' then PostDate := '10'
  else if PostDate = 'NOV' then PostDate := '10'
  else if PostDate = 'DIC' then PostDate := '12' else PostDate := '00';
  PostDate :=  PostDate +
           '-' + copy(m^.h^.datetime^,1,2) + '-' +
           copy(m^.h^.datetime^,8,2);
  PostTime := copy(m^.h^.datetime^,12,5);

  MsgAttr := 4;
  if (m^.h^.attribute and fPrivate) <> 0 then msgattr := msgattr or 8;
  if (m^.h^.attribute and fReceived) <> 0 then msgattr := msgattr or 16;
  if (m^.h^.attribute and fLocal) <> 0 then msgattr := msgattr or 64;
  if (m^.h^.attribute and fKillSent) <> 0 then msgattr := netattr or 1;
  if (m^.h^.attribute and fSent) <> 0 then msgattr := netattr or 2;
  if (m^.h^.attribute and fAttach) <> 0 then msgattr := netattr or 4;
  if (m^.h^.attribute and fCrash) <> 0 then msgattr := netattr or 8;
  if (m^.h^.attribute and fRetReq) <> 0 then msgattr := netattr or 16;
  if (m^.h^.attribute and fAuditReq) <> 0 then msgattr := netattr or 32;
  if (m^.h^.attribute and fIsRetReq) <> 0 then msgattr := netattr or 64;

  StartBlock := txtblock;
  end;
with m^.m^ do begin
  for j := 0 to pred(size div $ff) do begin
    inc(mh.numblocks);
    inc(txtblock);
    move(b^[succ(j*255)],s[1],255);
    s[0] := #255;
    write(msgtxt,s);
    end;
  j := succ(mh.numblocks * 255);
  if j < size then begin
    inc(mh.numblocks);
    inc(txtblock);
    move(b^[succ(j)],s[1],size-j);
    s[0] := chr(size-j);
    write(msgtxt,s);
    end;
  end;
write(msghdr,mh);
end;

destructor TMsgTosser.done;
begin
close(msgtxt);
close(msghdr);
dispose(msgidx,done);
dispose(msgtoidx,done);
info^.save;
dispose(info,done);
end;

{$F+}
procedure qbGetConfig(s,p : string; var error : boolean);
label endloop;
var err : integer;
begin
error := false;

if s = 'PATH' then begin
   qbpath := getpath(p);
   goto endloop;
   end;

if s = 'NETMAILAREA' then begin
   val(p,netmailarea,err);
   goto endloop;
   end;

endloop:
end;
{$F-}

procedure qbconfig(s : string);
var Ini : PIni;
begin
new(ini,init(s));
ini^.parsesection('QUICKBASE',qbGetConfig);
dispose(ini,done);
end;


end.
