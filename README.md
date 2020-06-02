# CASASOFT ObjectMatrix
## Tool di integrazione per sistemi FidoNet compatibili
### versione 2.00 per DOS

Questo repository ha esclusivamente interesse storico: il programma non è più sviluppato e mantenuto da 25 anni.

Recentemente ho iniziato un progetto per una BBS completa che potete trovare nel repository [BBS](https://github.com/strawberryfield/BBS)

L'introduzione che segue è tratta dal [manuale](https://github.com/strawberryfield/ObjectMatrix/blob/master/manual/OM.DOC) originale.

## BREVE STORIA DI OBJECTMATRIX

Questo programma nasce dalla necessita' di disporre di un
packer piu' rapido e semplice da usare del vecchio (benche'
efficiente) Dutchie che mi era stato dato assieme al
binkley.  
Mio scopo era semplicemente fare dei pacchetti dei messaggi
senza necessita' di scheduling o routing, visto che come
point non ne avevo la necessita'.  
La prima versione (che in realta' si chiamava IfnaPack) era
proprio brutale: basti pensare che gli indirizzi erano
hard-coded nel programma stesso.  
Quando ebbi necessita' di fornire il software per dei point
che dovevo installare aggiunsi un piccolo file di
configurazione dove mettere indirizzo e fakenet, ma senza
alcuna indicazione.  
Qualcuno mi fece notare che "l'interfaccia utente e' un po'
bruttina" ed in silenzio accolsi la sfida e mi scrissi una
unit per gestire in modo piu' completo il file di
configurazione.  
Poi il mio boss mi chiese se era possibile fare qualcosa
per eliminare dall'area matrix tutti quei messaggi che
creano i packer per mandare la posta visto che gli venivano
segnalati dall'editor e lui, per non perdere i matrix
importanti, se li doveva leggere tutti sciupando del gran
tempo.  
Poi si comincio' a parlare di "ricevute di ritorno" e
pensai bene di inserire anche questa feature.  
Infine con l'uscita del BinkleyTerm 2.50 e' nata anche
l'esigenza delle nodelist a quattro dimensioni e anche
questa viene soddisfatta.  
Cosi', un passo dopo l'altro, e' venuto fuori questo
programma che si propone di eliminare tutte quelle utility
che ingombrano gli hard disk, ognuna con la sua
configurazione e con compiti spesso sovrapposti.

Dalla versione 2 ObjectMatrix diventa lo strumento per
integrare funzionalmente i vari programmi necessari ad un
point o ad un bbs.  
Una "centrale di comando" attraverso la quale controllare e
gestire tutto il traffico che transita sul proprio sistema.
