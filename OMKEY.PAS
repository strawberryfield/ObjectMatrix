program registrazioni_OM;

uses swkey,omobj;

var s,k : string;
    n : word;

begin
writeln(prgname,' - Registrazione Utenti');
writeln;
write('Chiave n. ');  readln(n);
write('Nome Utente > ');  readln(s);
writeln;
k := code(s,n);
writeln('La chiave e'': ',k);
writeln;
writeln('Numero chiave: ',decode(k,s));
end.