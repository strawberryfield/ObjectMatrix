{$F+,O+}

unit shellcfg;
{ Lettura dei programmi esterni definiti nel file di configurazione }

interface

uses objects,dialogs;

type PShellColl = ^TShellColl;
     TShellColl = object(TSortedCollection)
       function compare(key1, key2 : pointer) : integer;  virtual;
       end;

     PShellBox = ^TShellBox;
     TShellBox = object(TListBox)
       function GetText(item : integer; MaxLen : integer) : string;  virtual;
       end;

var ShellColl : PShellColl;

procedure getShellColl;
function GetShell : string;

implementation

uses inifile,bbsconf,bbsdia,views,app;

type PStrCouple = ^TStrCouple;
     TStrCouple = object(TObject)
       Name, Prg : PString;
       constructor init(s,s1 : string);
       destructor done; virtual;
       end;

constructor TStrCouple.init(s,s1 : string);
begin
name := newstr(s);
prg := newstr(s1);
end;

destructor TStrCouple.done;
begin
if name <> nil then disposestr(name);
if prg <> nil then disposestr(prg);
end;

function TShellColl.compare(key1, key2 : pointer) : integer;
begin
if PStrCouple(key1)^.name^ = PStrCouple(key2)^.name^ then compare := 0
else if PStrCouple(key1)^.name^ > PStrCouple(key2)^.name^ then compare := 1
else compare := -1;
end;

procedure scan(st,par : string; var err : boolean);
begin
ShellColl^.insert(new(PStrCouple,init(st,par)));
err := false;
end;

procedure GetShellColl;
var ini : PIni;
begin
if not inistart(ini) then exit;
if iniparse(ini,'EXTERNALS',scan) then exit;
dispose(ini,done);
end;

function TShellBox.GetText(item : integer; MaxLen : integer) : string;
begin
if List = nil then GetText := ''
else GetText := copy(PStrCouple(list^.at(item))^.name^,1,MaxLen);
end;

function GetShell : string;
var d : POkCancBox;
    l : PShellBox;
    vs : PScrollBar;
    r,r1 : TRect;
    c : integer;
begin
GetShell := '';
new(ShellColl,init(10,2));
GetShellColl;

r.assign(0,0,40,15);
new(d,init(r,'External programs'));

r.grow(-3,-2);
dec(r.b.y, 2);
dec(r.b.x);
r1.copy(r);
r1.move(1,0);
r1.a.x := pred(r1.b.x);
new(vs,init(r1));
d^.insert(vs);
new(l,init(r,1,vs));
l^.newlist(ShellColl);
d^.insert(l);

c := desktop^.execview(d);
if c = cmCancel then exit;
GetShell := PStrCouple(ShellColl^.at(l^.focused))^.prg^;
dispose(d,done);
dispose(ShellColl,done);
end;

end.