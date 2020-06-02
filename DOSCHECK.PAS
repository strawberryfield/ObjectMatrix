{$F+,O+,V-}

unit doscheck;

interface

function DriveValid(Drive: Char): Boolean;
function PathValid(var Path: String): Boolean;
function ValidFileName(var FileName: String): Boolean;
function GetCurDir: String;
function IsWild(var S: String): Boolean;
function IsDir(var S: String): Boolean;

implementation

uses dos;

function DriveValid(Drive: Char): Boolean; assembler;
asm
	MOV	DL,Drive
        MOV	AH,36H
        SUB	DL,'A'-1
        INT	21H
        INC	AX
        JE	@@2
@@1:	MOV	AL,1
@@2:
end;

function PathValid(var Path: String): Boolean;
var
  ExpPath: PathStr;
  F: File;
  SR: SearchRec;
begin
  ExpPath := FExpand(Path);
  if Length(ExpPath) <= 3 then PathValid := DriveValid(ExpPath[1])
  else
  begin
    if ExpPath[Length(ExpPath)] = '\' then Dec(ExpPath[0]);
    FindFirst(ExpPath, Directory, SR);
    PathValid := (DosError = 0) and (SR.Attr and Directory <> 0);
  end;
end;

function ValidFileName(var FileName: String): Boolean;
const
  IllegalChars = ';,=+<>|"[] \';
var
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;

{ Contains returns true if S1 contains any characters in S2 }
function Contains(S1, S2: String): Boolean; near; assembler;
asm
	PUSH	DS
        CLD
        LDS	SI,S1
        LES	DI,S2
        MOV	DX,DI
        XOR	AH,AH
        LODSB
        MOV	BX,AX
        OR      BX,BX
        JZ      @@2
        MOV	AL,ES:[DI]
        XCHG	AX,CX
@@1:	PUSH	CX
	MOV	DI,DX
	LODSB
        REPNE	SCASB
        POP	CX
        JE	@@3
	DEC	BX
        JNZ	@@1
@@2:	XOR	AL,AL
	JMP	@@4
@@3:	MOV	AL,1
@@4:	POP	DS
end;

begin
  ValidFileName := True;
  FSplit(FileName, Dir, Name, Ext);
  if not ((Dir = '') or PathValid(Dir)) or Contains(Name, IllegalChars) or
    Contains(Dir, IllegalChars) then ValidFileName := False;
end;

function GetCurDir: String;
var
  CurDir: DirStr;
begin
  GetDir(0, CurDir);
  if Length(CurDir) > 3 then
  begin
    Inc(CurDir[0]);
    CurDir[Length(CurDir)] := '\';
  end;
  GetCurDir := CurDir;
end;
 
function IsWild(var S: String): Boolean;
begin
  IsWild := (Pos('?',S) > 0) or (Pos('*',S) > 0);
end;

function IsDir(var S: String): Boolean;
var
  SR: SearchRec;
begin
  FindFirst(S, Directory, SR);
  if DosError = 0 then
    IsDir := SR.Attr and Directory <> 0
  else IsDir := False;
end;

end.