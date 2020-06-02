{$F+,O+}

unit omnode;
{ compilazione della nodelist (versione 6) }

interface

uses address,objects,omnodevr;

const unitid = 2;
      unitcode = unitid * 256;

{ costanti per i messaggi del log }

      msgNodelist = 120;
      msgStLouis =  121;
      msgAddZone =  122;
      msgText   =   123;
      msgV6 =       124;
      msgFidoUser = 125;

      B_hub = 1;
      B_host = 2;
      B_region = 4;
      B_zone = 8;
      B_point = $1000;
      B_CM = $10;

type PNodelist = ^TNodelist;
     TNodelist = object(TAddressList)
       procedure compile;
       procedure StLouis(f : string);
       procedure elenco;
       procedure version6;
       procedure fidouser;
       end;

procedure NodeList;

procedure RegisterOmNode;

implementation

{ Definizione di due collections ordinate per mantenere
  i dati dei costi e delle sostituzioni nei numeri telefonici }

uses ifna,stringhe,drivers,dos,bbsinit,omnodecf,inifile;

{ Definizione tipo Nodelist }

const RNode : TStreamRec = (
        ObjType : unitcode + 1;
        VmtLink : Ofs(TypeOf(TNode)^);
        Load : @TNode.Load;
        Store : @TNode.Store);

      RNodeList : TStreamRec = (
        ObjType : unitcode + 2;
        VmtLink : Ofs(TypeOf(TNodeList)^);
        Load : @TNodeList.Load;
        Store : @TNodeList.Store);


procedure TNodelist.compile;

  function HiList : string;
  var di : searchrec;
      max,x : longint;
      err : integer;
      s : string;
  begin
  max := 0;
  findfirst(path^+'nodelist.*',archive,di);
  while doserror = 0 do begin
    val(copy(di.name,succ(pos('.',di.name)),3),x,err);
    if (err = 0) and (x > max) then max := x;
    findnext(di);
    end;
  if max <> 0 then begin
    formatstr(s,'nodelist.%03d',max);
    hilist := s;
    end
  else hilist := '';
  end;

  procedure mylists(item : Pstring); far;
  begin
  if item <> nil then StLouis(item^);
  end;

var s : string;
    dat : TBufStream;
begin
logf^.print(1,lang^.get(msgNodeList));
s := HiList;
if s <> '' then StLouis(s);
ml^.foreach(@mylists);
dat.init(prgpath+'nodelist.om',stCreate,2048);
dat.done;
dat.init(prgpath+'nodelist.om',stOpenWrite,2048);
store(dat);
dat.done;
if hrlist then elenco;
if v6 then version6;
if fu then fidouser;
end;

procedure TNodelist.StLouis(f : string);
label endnode;
var t : text;
    txtbuf : PTxtBuf;
    field : array[1..7] of string;
    l,hp : string;
    cz,cn,ch,cb : word;
    j,k : byte;
    e : integer;
    n : PNode;
    p : PPrefix;
    a : PAddress;

  function CheckPath(s : string) : string;
  var D: DirStr;
      N: NameStr;
      E: ExtStr;
  begin
  fsplit(s,d,n,e);
  if d = '' then d := path^;
  CheckPath := d+n+e;
  end;

  function HasZone(a : PNode) : boolean;  far;
  begin
  HasZone := ((a^.flags and B_zone) <> 0)
             and (a^.zone = myaddress^.zone);
  end;

  procedure CheckModem(a : PCostTable); far;
  begin
  if pos(a^.s^,l) > 0 then
    n^.modemtype := n^.modemtype or a^.cost;
  end;

begin
cz := myaddress^.zone;
cn := myaddress^.net;
ch := myaddress^.node;
cb := myaddress^.node;
hp := ' ';
logf^.print(2,lang^.get(msgStLouis)+' '+f);
assign(t,CheckPath(f));
new(txtbuf);
SetTextBuf(t,txtbuf^,sizeof(TTxtBuf));
reset(t);
repeat
  readln(t,l);
  if l[1] <> ';' then begin
    n := new(PNode,init);
    l := NoUnderscore(l);
    for k := 1 to 7 do begin
      j := pos(',',l);
      field[k] := copy(l,1,j);
      dec(field[k,0]);
      l := copy(l,succ(j),255);
      end;
    val(field[2],n^.node,e);
    val(field[7],n^.speed,e);
    n^.zone := cz;
    n^.net := cn;
    n^.hubnode := ch;
    n^.flags := 0;
    n^.point := 0;
    n^.name := newstr(field[3]);
    n^.location := newstr(field[4]);
    n^.sysop := newstr(field[5]);
    n^.cost := dc;

    { numero di nodo }
    field[1] := uppercase(field[1]);

    if field[1] = 'ZONE' then begin
      cz := n^.node;
      cn := n^.node;
      ch := 0;
      cb := 0;
      hp := field[6];
      n^.zone := cz;
      n^.net := cn;
      n^.node := 0;
      n^.flags := B_zone;
      n^.hubnode := 0;
      logf^.print(3,'Zone '+field[2]);
      goto endnode;
      end;

    if (field[1] = 'HOST') or
       (field[1] = 'REGION') then begin
      cn := n^.node;
      ch := 0;
      cb := 0;
      hp := field[6];
      n^.net := cn;
      n^.node := 0;
      n^.hubnode := 0;
      if field[1] = 'HOST' then begin
        n^.flags := B_host;
        logf^.print(3,'Network '+field[2]);
        end
      else begin
        n^.flags := B_region;
        logf^.print(3,'Region '+field[2]);
        end;
      goto endnode;
      end;

    if field[1] = 'HUB' then begin
      ch := n^.node;
      cb := n^.node;
      hp := field[6];
      n^.hubnode := 0;
      n^.flags := B_hub;
      goto endnode;
      end;

    if (field[1] = 'PVT') or
       (field[1] = 'HOLD') or
       (field[1] = 'DOWN') then begin
      field[6] := hp;
      cb := n^.node;
      goto endnode;
      end;

    if field[1] = 'POINT' then begin
      n^.point := n^.node;
      n^.node := cb;
      n^.flags := B_point;
      goto endnode;
      end;

    cb := n^.node;

    endnode:

    { numeri telefonici }
    if field[6] = '-Unpublished-' then field[6] := hp;
    if dt^.cerca(field[6],p) then
      if PDialTable(p)^.dial = nil then
        n^.phone := newstr(copy(field[6],succ(length(p^.s^)),255))
      else
        n^.phone := newstr(PDialTable(p)^.dial^ +
          copy(field[6],succ(length(p^.s^)),255))
    else
      if dp <> nil then
        n^.phone := newstr(dp^+field[6])
      else
        n^.phone := newstr(field[6]);

    { costo delle chiamate }
    if ct^.cerca(field[6],p) then
      n^.cost := PCostTable(p)^.cost;

    { altri flags }
    if pos('CM',l) > 0 then n^.flags := n^.flags or B_CM;
    mt^.foreach(@checkmodem);

    { dati di nodo specifico }
    ni^.update(n);

    n^.complete := newstr(addstr(n^.zone,n^.net,n^.node,n^.point));
    insert(n);
    end;
  until eof(t);
close(t);
dispose(txtbuf);

{ Inserisce una entry di zona se necessario e richiesto }
if fz and (FirstThat(@HasZone) = nil) then begin
  n := new(PNode,init);
  n^.zone := myaddress^.zone;
  n^.net := myaddress^.zone;
  n^.node := 0;
  n^.flags := B_zone;
  n^.hubnode := 0;
  n^.cost := maxint;
  n^.sysop := newstr('Zone Definition');
  n^.name := newstr(prgbanner);
  n^.phone := newstr(' ');
  n^.location := newstr(' ');
  n^.complete := newstr(addstr(n^.zone,n^.net,n^.node,0));
  insert(n);
  logf^.print(2,lang^.get(msgAddZone));
  end;
end;

procedure TNodelist.elenco;
var f : text;

  procedure doelenco(n : PNode); far;
  var dati : array[1..5] of pointer;
      s : string;
  begin
  dati[1] := n^.complete;
  dati[2] := n^.sysop;
  dati[3] := n^.name;
  dati[4] := n^.location;
  dati[5] := n^.phone;
  formatstr(s,'%-14s %-22s %-30s %-20s %18s',dati);
  writeln(f,s);
  end;

begin
logf^.print(2,lang^.get(msgText));
assign(f,path^+'nodelist.txt');
rewrite(f);
ForEach(@doelenco);
close(f);
end;

type PFidoUser = ^TFidoUser;
     TFidoUser = object(TStringCollection)
       function compare(key1,key2 : pointer) : integer; virtual;
       end;

function TFidouser.compare(key1,key2 : pointer) : integer;
var k1,k2 : string;
begin
k1 := copy(PString(key1)^,1,40);
k2 := copy(PString(key2)^,1,40);
if k1 = k2 then compare := 0 else
if k1 < k2 then compare := -1 else compare := 1;
end;

procedure TNodelist.fidouser;
var f : text;
    ful : PFidoUser;

  procedure doelenco(n : PNode); far;
  var s1,s2 : string;
      j : byte;
  begin
  splitline(n^.sysop^,s1,s2);
  s1 := s2 + ', ' + s1;
  j := pos('/',n^.complete^);
  s1 := copy(s1+spaces(54),1,54-j) + n^.complete^;
  ful^.insert(newstr(s1));
  end;

  procedure writelist(n : PString); far;
  begin
  writeln(f,n^);
  end;

begin
logf^.print(2,lang^.get(msgFidoUser));
new(ful,init(100,10));
ForEach(@doelenco);
assign(f,path^+'fidouser.lst');
rewrite(f);
ful^.ForEach(@writelist);
close(f);
dispose(ful,done);
end;

procedure TNodelist.version6;
var dat,idx : TBufStream;

  procedure dov6(n : PNode); far;
  var s : string;
      x : byte;
      w : word;
  begin
  dat.write(n^.net,2);
  dat.write(n^.node,2);
  dat.write(n^.cost,2);
  s := copy(n^.name^,1,33)+chars(#0,40);
  dat.write(s[1],34);
  s := copy(n^.phone^,1,39)+chars(#0,40);
  dat.write(s[1],40);
  s := copy(n^.location^,1,29)+chars(#0,40);
  dat.write(s[1],30);
  s := copy(n^.password,1,8)+chars(#0,40);
  dat.write(s[1],8);
  dat.write(n^.cost,2);
  if (n^.flags and B_point) <> 0 then dat.write(n^.point,2)
  else dat.write(n^.hubnode,2);
  x := n^.speed div 300;
  dat.write(x,1);
  dat.write(n^.modemtype,1);
  dat.write(n^.flags,2);
  w := 0;
  dat.write(w,2);

  w := n^.node;
  case n^.flags and $f of
    b_region : w := $ffff;
    b_zone : w := $fffe;
    end;
  idx.write(w,2);
  idx.write(n^.net,2);
  end;

  procedure header;
  var s,s1 : string;
  begin
  fillchar(s,sizeof(s),#0);
  s[1] := #$ff;
  s[2] := #$ff;
  s[3] := #6;
  s1 := prgbanner;
  move(s1,s[7],length(s1));
  dat.write(s[1],128);
  idx.write(s[3],2);
  idx.write(s[1],2);
  end;

begin
logf^.print(2,lang^.get(msgV6));
dat.init(path^+'nodelist.dat',stCreate,2048);
dat.done;
dat.init(path^+'nodelist.dat',stOpenWrite,2048);
idx.init(path^+'nodelist.idx',stCreate,2048);
idx.done;
idx.init(path^+'nodelist.idx',stOpenWrite,2048);
header;
foreach(@dov6);
dat.done;
idx.done;
end;


{ Interfaccia Compilazione Nodelist per parser }

procedure NodeList;
var nl : PNodelist;
begin
new(nl,init(200,40));
NodeListCfg;
nl^.compile;
ClearNodeListCfg;
dispose(nl,done);
end;

{ Procedura di registrazione tipi }

procedure RegisterOmNode;
begin
RegisterType(RNode);
RegisterType(RNodeList);
end;

end.