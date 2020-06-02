{$F+,O+}

unit omhlpparser;

interface

uses BbsHlpParser;

procedure sethelp(var hl : PBbsHelpList);

implementation

uses omhc;

procedure sethelp(var hl : PBbsHelpList);
begin
hl^.insert(new(PBbsHelpItem,init( 'PACK',hcPack)));
hl^.insert(new(PBbsHelpItem,init( 'KILLPACKETS',hcKillPkt)));
hl^.insert(new(PBbsHelpItem,init( 'FORCEPOLL',hcPollPkt)));
hl^.insert(new(PBbsHelpItem,init( 'CLEANOUT',hcCleanOut)));
hl^.insert(new(PBbsHelpItem,init( 'UNPACK',hcUnPack)));
hl^.insert(new(PBbsHelpItem,init( 'POST',hcPost)));
hl^.insert(new(PBbsHelpItem,init( 'ATTACH',hcAttach)));
hl^.insert(new(PBbsHelpItem,init( 'HATCH',hcAttach)));
hl^.insert(new(PBbsHelpItem,init( 'REQUEST',hcRequest)));
hl^.insert(new(PBbsHelpItem,init( 'RENAME',hcRename)));
hl^.insert(new(PBbsHelpItem,init( 'KILL',hcKill)));
hl^.insert(new(PBbsHelpItem,init( 'PURGE',hcPurge)));
hl^.insert(new(PBbsHelpItem,init( 'REPLY',hcReply)));
hl^.insert(new(PBbsHelpItem,init( 'ADJUST',hcAdjust)));
hl^.insert(new(PBbsHelpItem,init( 'RENUM',hcRenum)));
hl^.insert(new(PBbsHelpItem,init( 'DUMP',hcDumpMenu)));
hl^.insert(new(PBbsHelpItem,init( 'NODELIST',hcNodelist)));
hl^.insert(new(PBbsHelpItem,init( 'DISKMAIL',hcDiskMail)));
hl^.insert(new(PBbsHelpItem,init( 'QUICKBASE',hcQBmenu)));
end;

end.