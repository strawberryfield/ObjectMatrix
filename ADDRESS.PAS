{$F+,O+}

unit address;

interface

uses objects;

      { ** Definizioni codici identificazione ** }

const unitid = 1;
      unitcode = unitid * 256;

      { ** Definizioni tipi ** }

type Paddress = ^Taddress;
     Taddress = object(Tobject)
       zone,net,node,point,pointnet : word;
       complete : pstring;
       password : string[8];
       constructor init;
       constructor load(var s : Tstream);
       constructor get(p : string);
       procedure assign(p : string);
       procedure store(var s : Tstream); virtual;
       procedure setpointnet(s : string);
       function fakestring : string;
       procedure getpassword(s : string);
       function config(s,p : string) : boolean;
       function equal(azone,anet,anode,apoint : word) : boolean;
       destructor done; virtual;
       end;

     PAddressList = ^TAddressList;
     TAddressList = object(TSortedCollection)
       function compare(key1,key2 : pointer) : integer; virtual;
       end;

procedure parseaddr(add : string; var zona,net,nodo,point : word);
function addstr(zona,net,nodo,point : word) : string;
procedure RegisterAddress;

implementation

uses stringhe;

      { ** Definizioni registrazioni oggetti ** }

const Raddress : TstreamRec = (
        ObjType : unitcode + 1;
        VmtLink : ofs(typeof(Taddress)^);
        Load    : @Taddress.load;
        Store   : @Taddress.store
        );

      RaddressList : TstreamRec = (
        ObjType : unitcode + 2;
        VmtLink : ofs(typeof(TaddressList)^);
        Load    : @TaddressList.load;
        Store   : @TaddressList.store
        );

procedure parseaddr(add : string; var zona,net,nodo,point : word);

  function getelem(c : char) : word;
  var j : byte;
      h,e : word;
  begin
  j := pos(c,add);
  if j <> 0 then begin
    val(copy(add,1,j-1),h,e);
    add := copy(add,j+1,255);
    end
  else h := 0;
  getelem := h;
  end;

begin
if pos('.',add) = 0 then add := add + '.0';
add := add + '@';
zona := getelem(':');
net := getelem('/');
nodo := getelem('.');
point := getelem('@');
end;

function addstr(zona,net,nodo,point : word) : string;
var s,add : string;
begin
add := '';
if zona <> 0 then begin
  str(zona,s);
  add := s + ':';
  end;
str(net,s);
add := add + s + '/';
str(nodo,s);
add := add + s + '.';
str(point,s);
addstr := add + s;
end;

      { ** Definizioni oggetti ** }

constructor Taddress.init;
begin
complete := nil;
pointnet := 0;
password := '';
end;

procedure Taddress.assign(p : string);
begin
complete := newstr(p);
parseaddr(p,zone,net,node,point);
end;

constructor Taddress.get(p : string);
begin
init;
assign(p);
end;


constructor Taddress.load(var s : Tstream);
begin
complete := s.readstr;
parseaddr(complete^,zone,net,node,point);
s.read(pointnet,sizeof(pointnet));
end;

procedure Taddress.store(var s : Tstream);
begin
s.writestr(complete);
s.write(pointnet,sizeof(pointnet));
end;

function TAddress.fakestring : string;
var ss : string;
begin
if point = 0 then ss := addstr(zone,net,node,point)
else ss := addstr(zone,pointnet,point,0);
fakestring := copy(ss,1,pred(pos('.',ss)));
end;

procedure Taddress.setpointnet(s : string);
var e : integer;
begin
val(s,pointnet,e);
end;

procedure Taddress.getpassword(s : string);
begin
password := uppercase(copy(s,1,7));
end;

function Taddress.equal(azone,anet,anode,apoint : word) : boolean;
begin
equal :=  (
    (azone = zone) or (azone = 0)
  ) and (
    ((anet = net) and (anode = node) and (apoint = point))
    or
    ((anode = point) and (anet = pointnet))
  );
end;

function Taddress.config(s,p : string) : boolean;
label endloop;
begin
config := true;

if s = 'ADDRESS' then begin
   assign(p);
   goto endloop;
   end;

if s = 'POINTNET' then begin
   if uppercase(p) = 'REGION33POINTNET' then
     pointnet := 20000 + 1000 * (net mod 10) + node
   else setpointnet(p);
   goto endloop;
   end;


config := false;
endloop:
end;

destructor Taddress.done;
begin
disposestr(complete);
end;


function TAddressList.compare(key1,key2 : pointer) : integer;
label endtest;
var k1,k2 : PAddress;
    j : integer;

  function test(x1,x2 : word) : integer; assembler;
  asm
    xor ax, ax
    mov bx, x1
    cmp bx, x2
    je  @fine
    jg  @bigger
    dec ax
    jmp @fine

  @bigger:
    inc ax

  @fine:
  end;

begin
k1 := PAddress(key1);
k2 := PAddress(key2);

j := test(k1^.zone,k2^.zone);
if j <> 0 then goto endtest;

j := test(k1^.net,k2^.net);
if j <> 0 then goto endtest;

j := test(k1^.node,k2^.node);
if j <> 0 then goto endtest;

j := test(k1^.point,k2^.point);

endtest:
compare := j;
end;

      { ** Registrazioni oggetti ** }

procedure RegisterAddress;
begin
RegisterType(Raddress);
RegisterType(RaddressList);
end;

end.