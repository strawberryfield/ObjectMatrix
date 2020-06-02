unit omhc;
{ costanti per l'help context-sensitive }

interface

uses ompost,ompack2,omtools,omunpack,omnode,omquinex,
     omkill,omattach,omdmail,omclean,omdump;

const hcCasasoft   = 2001;
      hcPackMenu   = 2002;
      hcMaintMenu  = 2003;
      hcNodeMenu   = 2004;
      hcMsgMenu    = 2005;
      hcDumpMenu   = 2006;
      hcQBmenu     = 2012;

      hcAdjust   = msgAdjusting   + 1000;
      hcAttach   = msgAttached    + 1000;
      hcCleanOut = msgCleaning    + 1000;
      hcDiskMail = msgCopymail    + 1000;
      hcKill     = msgKilling     + 1000;
      hcPurge    = msgPurgeSent   + 1000;
      hcNodelist = msgNodelist    + 1000;
      hcPack     = msgmakepacket  + 1000;
      hcPost     = msgPosted      + 1000;
      hcRename   = msgRenaming    + 1000;
      hcRenum    = msgRenumbering + 1000;
      hcReply    = msgReplying    + 1000;
      hcRequest  = msgRequested   + 1000;
      hcUnpack   = msgUnpacking   + 1000;
      hcDump     = msgDump        + 1000;
      hcPollPkt  = msgPollPkt     + 1000;
      hcKillPkt  = msgKillPkt     + 1000;
      hcInboundDump = msgInboundDump + 1000;
      hcOutboundDump = msgOutboundDump + 1000;
      hcListPkt  = msgListPkt     + 1000;
      hcExport   = msgExport      + 1000;
      hcRescan   = msgRescan      + 1000;
      hcImport   = msgImport      + 1000;

implementation

end.
