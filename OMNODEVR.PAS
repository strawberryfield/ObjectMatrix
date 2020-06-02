{$F+,O+}

unit omnodevr;
{ variabili per compilazione della nodelist }

interface

uses address,objects;

type PPrefix = ^TPrefix;
     TPrefix = object(TObject)
       s : Pstring;
       constructor init(p : string);
       destructor done; virtual;
       end;

     PCostTable = ^TCostTable;
     TCostTable = object(TPrefix)
       cost : word;
       constructor init(p : string; c : word);
       end;

     PDialTable = ^TDialTable;
     TDialTable = object(TPrefix)
       dial : pstring;
       constructor init(p : string; d : string);
       destructor done; virtual;
       end;

     PPrefixList = ^TPrefixList;
     TPrefixList = object(TSortedCollection)
       function keyof(item : pointer) : pointer; virtual;
       function compare(key1,key2 : pointer) : integer; virtual;
       function cerca(s : string; var k : PPrefix) : boolean;
       end;

     PAddrInfo = ^TAddrInfo;
     TAddrInfo = object(TAddress)
       ei : PString;
       constructor init;
       destructor done; virtual;
       end;

     PNode = ^TNode;
     TNode = object(TAddress)
       sysop,location,name,phone : pstring;
       cost,speed,flags,hubnode : word;
       modemtype : byte;
       constructor init;
       constructor load(var s : TStream);
       procedure store(var s : TStream); virtual;
       destructor done; virtual;
       end;

     PNodeInfo = ^TNodeInfo;
     TNodeInfo = object
       cost,phone,passw,mtype,name,sysop,location : PAddressList;
       constructor init;
       procedure update(var n : PNode);
       function config(st,p1,p2 : string) : boolean;
       destructor done;
       end;

const v6 : boolean = false;       { Crea nodelist versione 6 }
      fu : boolean = false;       { Crea FidoUser.lst }
      hrlist : boolean = false;   { Crea lista testo }
      fz : boolean = false;       { Forza l'inserimento della zona }
      dc : integer = maxint;      { Costo standard }
      dp : pstring = nil;         { Prefisso standard }

      ct : PPrefixList = nil;       { Tabella dei costi }
      dt : PPrefixList = nil;       { Tabella dei prefissi }
      mt : PPrefixList = nil;       { Tipi di modem }
      ni : PNodeInfo = nil;         { Informazioni per nodi specifici }
      ml : PStringCollection = nil; { Elenco liste personali }
      path : PString = nil;         { Percorso files nodelist }

implementation

{ Definizione di due collections ordinate per mantenere
  i dati dei costi e delle sostituzioni nei numeri telefonici }

uses stringhe;

constructor TPrefix.init(p : string);
begin
s := newstr(p);
end;

destructor TPrefix.done;
begin
disposestr(s);
end;

constructor TCostTable.init(p : string; c : word);
begin
Tprefix.init(p);
cost := c;
end;

constructor TDialTable.init(p : string; d : string);
begin
Tprefix.init(p);
dial := newstr(d);
end;

destructor TDialTable.done;
begin
TPrefix.done;
disposestr(dial);
end;

function TPrefixList.keyof(item : pointer) : pointer;
begin
keyof := PPrefix(item)^.s;
end;

function TPrefixList.compare(key1,key2 : pointer) : integer;
begin
if pstring(key1)^ = pstring(key2)^ then compare := 0
else if pstring(key1)^ < pstring(key2)^ then compare := -1 else compare := 1;
end;


function TPrefixList.cerca(s : string; var k : PPrefix) : boolean;

  function match(pref : PPrefix) : boolean;  far;
  begin
  match := beginof(pref^.s^,s);
  end;

begin
k := lastThat(@match);
cerca := k <> nil;
end;

{ Definizione tipo per dati personalizzati del nodo }

constructor TAddrInfo.init;
begin
TAddress.init;
ei := nil;
end;

destructor TAddrInfo.done;
begin
if ei <> nil then disposestr(ei);
TAddress.done;
end;

{ Oggetto che gestisce le liste dei dati personali }

constructor TNodeInfo.init;
begin
new(cost,init(2,2));
new(phone,init(2,2));
new(passw,init(2,2));
new(mtype,init(2,2));
new(name,init(2,2));
new(sysop,init(2,2));
new(location,init(2,2));
end;

destructor TNodeInfo.done;
begin
dispose(cost,done);
dispose(phone,done);
dispose(passw,done);
dispose(mtype,done);
dispose(name,done);
dispose(sysop,done);
dispose(location,done);
end;

function TNodeInfo.config(st,p1,p2 : string) : boolean;
label endloop;
var a : PAddrInfo;

  procedure initdata(dest : PAddressList);
  begin
  a := new(PAddrInfo,init);
  a^.assign(p1);
  a^.ei := newstr(p2);
  dest^.insert(a);
  end;

begin
config := true;

if st = 'PASSWORD' then begin
   a := new(PAddrInfo,init);
   a^.assign(p1);
   a^.password := copy(p2,1,8);
   passw^.insert(a);
   goto endloop;
   end;

if st = 'NODETYPE' then begin
   initdata(mtype);
   goto endloop;
   end;

if st = 'NODECOST' then begin
   initdata(cost);
   goto endloop;
   end;

if st = 'NODEPHONE' then begin
   initdata(phone);
   goto endloop;
   end;

if st = 'NODENAME' then begin
   initdata(name);
   goto endloop;
   end;

if st = 'NODESYSOP' then begin
   initdata(sysop);
   goto endloop;
   end;

if st = 'NODELOCATION' then begin
   initdata(location);
   goto endloop;
   end;

config := false;
endloop:
end;

procedure TNodeInfo.update(var n : PNode);
var a : PAddrInfo;
    e : integer;

  function HasInfo(a : PAddrInfo) : boolean;  far;
  begin
  HasInfo := a^.equal(n^.zone,n^.net,n^.node,n^.point);
  end;

  procedure updstr(src : PAddressList; dest : PString);
  begin
  a := src^.FirstThat(@HasInfo);
  if a <> nil then begin
    if dest <> nil then disposestr(dest);
    dest := newstr(a^.ei^);
    end;
  end;

begin
a := passw^.FirstThat(@HasInfo);
if a <> nil then n^.password := a^.password;
a := cost^.FirstThat(@HasInfo);
if a <> nil then val(a^.ei^,n^.cost,e);
a := mtype^.FirstThat(@HasInfo);
if a <> nil then val(a^.ei^,n^.modemtype,e);
updstr(phone,n^.phone);
updstr(name,n^.name);
updstr(sysop,n^.sysop);
updstr(location,n^.location);
end;

{ Tipo con i dati dei nodi }

constructor TNode.init;
begin
TObject.init;
TAddress.init;
end;

destructor TNode.done;
begin
if sysop <> nil then disposestr(sysop);
if location <> nil then disposestr(location);
if name <> nil then disposestr(name);
if phone <> nil then disposestr(phone);
TAddress.done;
end;

constructor TNode.load(var s : TStream);
begin
sysop := s.readstr;
location := s.readstr;
name := s.readstr;
phone := s.readstr;
s.read(cost,2);
s.read(speed,2);
s.read(flags,2);
s.read(hubnode,2);
s.read(modemtype,1);
TAddress.Load(s);
end;

procedure TNode.store(var s : TStream);
begin
s.writestr(sysop);
s.writestr(location);
s.writestr(name);
s.writestr(phone);
s.write(cost,2);
s.write(speed,2);
s.write(flags,2);
s.write(hubnode,2);
s.write(modemtype,1);
TAddress.store(s);
end;

end.