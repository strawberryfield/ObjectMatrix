{$F+,O+,X+}

unit omapp;

interface

uses  bbsapp,objects,views,bbslib,drivers,omhc,dialogs;

type POMApp = ^TOMApp;
     TOMApp = object(TBBSApp)
       constructor init;
       procedure handleevent(var Event : TEvent); virtual;
       procedure InitMenuBar; virtual;
       end;


implementation

uses omparse,bbsdia,bbsinit,app,menus,
     omhlpparser,outbview,ifna;

var args,labels : TPar;

constructor TOMApp.init;
var r : Trect;
begin
TBBsapp.init;
sethelp(helpList);
end;

procedure TOMApp.handleevent(var Event : TEvent);
var control : word;

  procedure OutMan;
  var m : POutboundDialog;
  begin
  new(m,init('*.*','Outbound Manager',1));
  m^.setdata(outbound^);
  desktop^.execview(m);
  end;

begin
TBBsApp.handleevent(Event);
if event.what = evCommand then begin
  case event.command of

    hcPurge : begin
      Args[1] := 'PURGE';
      Args[2] := purgeWho;
      if args[2] <> '' then parse(args);
      end;

    hcAttach : begin
      cleanpar(Args);
      Args[1] := 'ATTACH';
      Labels[1] := '4~D~estination';
      Labels[2] := '1~F~ile';
      case MultiDialogPriority(labels,args[2],2,'File Attach') of
        cmOk,cmDefault : parse(args);
        end;
      end;

    hcPost : begin
      cleanpar(Args);
      Args[1] := 'POST';
      Labels[1] := '3~T~o';
      Labels[2] := '4~N~ode';
      Labels[3] := '6~S~ubject';
      Labels[4] := '1~F~ile';
      case MultiDialogPriority(labels,args[2],4,'Post Text File') of
        cmOk,cmDefault : parse(args);
        end;
      end;

    hcPack : begin
      cleanpar(Args);
      Args[1] := 'PACK';
      Labels[1] := '6Schedule';
      case MultiDialog(labels,args[2],1,'Packer Schedule') of
        cmOk,cmDefault : parse(args);
        end;
      end;

    hcPollPkt : begin
      cleanpar(args);
      Args[1] := 'FORCEPOLL';
      labels[1] := '4Nodo';
      case MultiDialog(labels,args[2],1,'Crea pacchetto per polling') of
        cmOk,cmDefault : parse(args);
        end;
      end;

    hcDiskMail : begin
      Args[1] := 'DISKMAIL';
      Args[2] := '';
      Args[3] := 'A:\';
      labels[1] := '4~N~odo destinatario';
      labels[2] := '5~D~irectory destinazione';
      case MultiDialog(labels,args[2],2,'Esporta posta su dischetto') of
        cmOk,cmDefault : parse(args);
        end;
      end;

    hcDump : begin
      cleanpar(args);
      Args[1] := 'DUMP';
      Args[2] := 'MAIL';
      parse(args);
      viewdump('MAILDUMP.OM');
      end;

    hcInboundDump : begin
      cleanpar(args);
      Args[1] := 'DUMP';
      Args[2] := 'INBOUND';
      parse(args);
      viewdump('INBOUND.OM');
      end;

    hcOutboundDump : begin
      cleanpar(args);
      Args[1] := 'DUMP';
      Args[2] := 'OUTBOUND';
      parse(args);
      viewdump('OUTBOUND.OM');
      end;

    hcListPkt : begin
      cleanpar(args);
      Args[1] := 'LISTPKT';
      parse(args);
      viewdump('PKTLIST.OM');
      end;

    hcKill : begin
      Args[1] := 'KILL';
      Args[2] := 'ARCmail';
      labels[1] := '3Mittente';
      case MultiDialog(labels,args[2],1,'Cancella messaggi inutili') of
        cmOk,cmDefault : parse(args);
        end;
      end;

    hcRequest : begin
      cleanpar(args);
      Args[1] := 'REQUEST';
      labels[1] := '4~N~ode';
      labels[2] := '2~F~ile(s)';
      labels[3] := '6~P~assword';
      case MultiDialog(labels,args[2],3,'File Request') of
        cmOk,cmDefault : parse(args);
        end;
      end;

    hcRename : begin
      Args[1] := 'RENAME';
      Args[2] := 'Sysop';
      args[3] := sysop^;
      labels[1] := '3~O~riginal';
      labels[2] := '3~M~odified';
      case MultiDialog(labels,args[2],2,'Rename destinatario') of
        cmOk,cmDefault : parse(args);
        end;
      end;

    hcExport : begin
      Args[1] := 'QUICKBASE';
      Args[2] := 'EXPORT';
      parse(args);
      end;

    hcImport : begin
      Args[1] := 'QUICKBASE';
      Args[2] := 'IMPORT';
      parse(args);
      end;

    hcRescan : begin
      Args[1] := 'QUICKBASE';
      Args[2] := 'RESCAN';
      parse(args);
      end;

    else begin
      Args[1] := helplist^.findcommand(event.command);
      if args[1] <> '' then parse(args) else exit;
      end;

    end;
  clearevent(Event);
  end;
end;


procedure TOMApp.InitMenuBar;
var r : TRect;
begin
getextent(r);
R.B.Y := R.A.Y+1;
MenuBar := new(PMenuBar,init(r,newmenu(
  SystemMenu(
  newsubmenu('~P~acker',hcPackmenu,newmenu(
    newitem('~P~ack...','',0,hcPack,hcPack,
    newitem('~U~npack','',0,hcunpack,hcunpack,
    newline(
    newitem('~C~leanOut','',0,hcCleanOut,hcCleanOut,
    newitem('~K~ill Packets','',0,hcKillPkt,hcKillPkt,
    newitem('P~o~ll Node...','',0,hcPollPkt,hcPollPkt,
    newline(
    newitem('~D~isk Mail...','',0,hcDiskMail,hcDiskMail,
    nil ))))))))),
  newsubmenu('~M~aint',hcMaintmenu,newmenu(
    newitem('~A~djust','',0,hcAdjust,hcAdjust,
    newitem('~K~ill...','',0,hcKill,hcKill,
    newitem('~P~urge...','',0,hcPurge,hcPurge,
    newitem('~R~enum','',0,hcRenum,hcRenum,
    newitem('Re~n~ame...','',0,hcRename,hcRename, nil)))))),
  newsubmenu('~D~ump',hcDumpMenu,newmenu(
    newitem('~I~nbound','',0,hcInboundDump,hcInboundDump,
    newitem('~O~utbound','',0,hcOutboundDump,hcOutboundDump,
    newitem('~L~ist Pkt','',0,hcListPkt,hcListPkt,
    newline(
    newitem('~M~sg','',0,hcDump,hcDump, nil )))))),
  newsubmenu('P~o~st',hcMsgmenu,newmenu(
    newitem('~P~ost...','',0,hcPost,hcPost,
    newitem('~A~ttach...','',0,hcAttach,hcAttach,
    newitem('~R~equest...','',0,hcRequest,hcRequest,
    newitem('R~e~ply','',0,hcReply,hcReply, nil ))))),
  newsubmenu('~Q~uickBase',hcQBmenu,newmenu(
    newitem('~E~xport','',0,hcExport,hcExport,
    newitem('~R~escan','',0,hcRescan,hcRescan,
    newline(
    newitem('~I~mport','',0,hcImport,hcImport, nil))))),
  newsubmenu('~N~odelist',hcNodelist,newmenu(
    newitem('~N~odelist','',0,hcNodelist,hcNodelist, nil )),
  HelpMenu(
    nil))))))))
  )));
end;

end.
