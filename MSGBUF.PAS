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

