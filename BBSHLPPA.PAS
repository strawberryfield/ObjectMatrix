{$F+,O+}

unit bbshlpparser;

interface

uses objects;

type PBbsHelpItem = ^TBbsHelpItem;
     TBbsHelpItem = object(TObject)
       name : PString;
       hc : word;
       constructor init(s : string; v : word);
       destructor done; virtual;
       end;

     PBbsHelpList = ^TBbsHelpList;
     TBbsHelpList = object(TCollection)
       function FindHelp(s : string) : word;
       function FindCommand(x : word) : string;
       end;

procedure sethelp(var hl : PBbsHelpList);

implementation

uses Bbshc;

constructor TBbsHelpItem.init(s : string; v : word);
begin
name := newstr(s);
hc := v;
end;

destructor TBbsHelpItem.done;
begin
disposestr(name);
end;

function TBbsHelpList.FindHelp(s : string) : word;

  function cerca(item : PBbsHelpItem) : boolean; far;
  begin
  cerca := s = item^.name^;
  end;

var found : PBbsHelpItem;
begin
found := firstThat(@cerca);
if found = nil then FindHelp := 0 else FindHelp := found^.hc;
end;

function TBbsHelpList.FindCommand(x : word) : string;

  function cerca(item : PBbsHelpItem) : boolean; far;
  begin
  cerca := x = item^.hc;
  end;

var found : PBbsHelpItem;
begin
found := firstThat(@cerca);
if found = nil then FindCommand := '' else FindCommand := found^.name^;
end;


procedure sethelp(var hl : PBbsHelpList);
begin
new(hl,init(20,2));
hl^.insert(new(PBbsHelpItem,init( 'REMARK',hcRemark)));
end;

end.