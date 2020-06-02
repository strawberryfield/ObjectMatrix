{$F+,O+}

unit omclean;

interface

const msgCleaning = 110;

procedure cleanout;

implementation

uses dos,omobj,ifna,objects,omkill,bbsinit;

var kl : PStringCollection;

procedure cleandir(dir : string);
var di,dt : searchrec;
    s : string;
    t : text;
begin
findfirst(dir+'*.?ms',archive,di);
while doserror = 0 do begin
  case di.name[10] of
    'P' : s := 'FLO';
    'H' : s := 'HLO';
    'C' : s := 'CLO';
    end;
  findfirst(dir+copy(di.name,1,9)+s,archive,dt);
  if doserror <> 0 then begin
    assign(t,dir+di.name);
    reset(t);
    repeat
      readln(t,s);
      kl^.insert(newstr(s));
      until eof(t);
    close(t);
    kl^.insert(newstr(dir+di.name));
    end;
  findnext(di);
  end;
end;

procedure alldir;
var di,dt : searchrec;
    k,h : string;
    j : byte;
begin

{ Cerca in tutte le zone }

k := copy(outbound^,1,pred(length(outbound^)));
findfirst(k+'.*',directory,di);
while doserror = 0 do begin

{ Analisi della directory di zona }

  j := pos('.',di.name);
  if j <> 0 then h := k + copy(di.name,j,255) + '\'
  else h := k + '\';
  cleandir(h);

{ Analisi delle subdirectory di point }

  findfirst(h+'*.pnt',directory,dt);
  while doserror = 0 do begin
    cleandir(h+dt.name+'\');
    findnext(dt);
    end;

  findnext(di);
  end;
end;

procedure cleanout;
begin
logf^.print(1,lang^.get(msgCleaning));
new(kl,init(10,2));
alldir;
killCollection(kl);
end;

end.
