unit Collect;
interface
 Uses  Classes, SysUtils,  ClipStrm, ClipBrd, {$IFDEF WIN64} Windows,{$ENDIF}
       BufStream;
{ Корневой объект для примитивов }


 Const CollectVer:Integer=10;
       cmRead=0;
       cmWrite=1;
       Collect432:Boolean = False;
       BLOCK_DEBUG:Boolean = False;

 var FA:TextFile;
     CF_Ver25OBJECT:Word;

 type
 TExtendedSect = packed record
  Left,Top,Right,Bottom:Extended;
 end;

 TExtended80Sect = packed record
  Left,Top,Right,Bottom:TExtended80Rec;
 end;

  Type
   TBufStream = Class;

{M+}
   TTwgObject=class
     Constructor  Load(Reader:TBufStream);Virtual;Abstract;
     Procedure   Store(Writer:TBufStream);Virtual;Abstract;
     Constructor BINLoad(Reader:TBufStream);Virtual;Abstract;
     Procedure   BINStore(Writer:TBufStream);Virtual;Abstract;
    end;
{M-}

 TStreamClass=Class of TTwgObject;

 TBufStream = Class(TTwgObject)
  Private
    FCloseFile  : Boolean;
  Public
    Status:Integer;
//    Str:TStream;
    FStream : TStream;
   {}
    List:TList;
   {}
    Selector:Pointer;
//    FontColEx:Pointer;
    Function GetPos : Longint;
    Procedure SetPos(Pos : Longint);
    Function GetSize : Longint;
    Function GetHandle : Longint;
   {}
    Constructor Create(fMem:boolean=True);
    Constructor InitHandleStream(AHandle : THandle);
    Constructor InitFileStream(FileName : AnsiString; Mode : Word);
//    Constructor InitBlobStream(Blob:TBlobStream);
    Constructor InitClipboard(Mode:Word);

    Function Get : TTwgObject;
    Procedure Put(P : TTwgObject);

    Function ReadStr : AnsiString;

    Function StrRead : PAnsiChar;

    Procedure WriteStr(P : AnsiString);
    Procedure StrWrite(P : PAnsiChar);
  //
    Procedure WriteString(P : AnsiString);
    Function  ReadString : AnsiString;

    Function Read(var Buffer; Count : Longint): Longint;
    Function Write(const Buffer; Count : Longint): Longint;
    Function ReadExtended: Extended;
    Procedure WriteExtended(Ext:Extended);
    Function ReadSect: TExtendedSect;
    Procedure WriteSect(Sect:TExtendedSect);
    Function Seek(Offset : Longint; Origin : Word): Longint;
    Function FlushBuffer:boolean;
    Function CopyFrom(Source : TStream; Count : Longint): Longint;
    property Position : Longint read GetPos write SetPos;
    property Size : Longint read GetSize;
    property Stream :TStream read FStream;

    property Handle : integer read GetHandle;
    property CloseFile : Boolean read FCloseFile write FCloseFile;

   {}
    Destructor Destroy;override;
  end;

   TTwgStream=Class(TBufStream)
   end;

 { Коллекция }

 PCollection = Class(TTwgObject)
  Protected
    Procedure CheckList;
    Function Get(Index: Integer): Pointer;virtual;
    Procedure Put(Index: Integer; Item: Pointer);virtual;
    Function GetCount:Integer;
  Public
    FList       : TList;
   // FArray:TPointerList;
    Constructor Create(ALimit : Integer);
  {}
    Constructor Load(S : TBufStream); Override;
    Procedure Store(S :TBufStream); Override;
    Function GetItem(S : TBufStream): Pointer; Virtual;
    Procedure PutItem(S : TBufStream;Item: Pointer); Virtual;


    Function InsertItem(Item : Pointer) : Pointer; Virtual;
    Procedure Insert(Item : Pointer); Virtual;
    Procedure AtInsert(Index : Integer; Item: Pointer);
    Procedure AtPut(Index : Integer; Item: Pointer);
    Procedure AtReplace(Index: Integer; Item: Pointer);

    Function At(Index : Integer): Pointer;
    Function IndexOf(Item : Pointer): Integer; Virtual;

    Procedure AtDelete(Index : Integer);
    Procedure Delete(Item : Pointer);
    Procedure DeleteAll;

    Procedure FreeItem(Item : Pointer); Virtual;
    Procedure AtFree(Index : Integer);
    Procedure Remove(Item : Pointer);
    Procedure FreeAll;

    Procedure Pack;
    Procedure SetLimit(ALimit : Integer);

    Property List  : TList read FList;
    Property Items[index : Integer]: Pointer read Get write Put; default;
    Property Count:Integer read GetCount;
  {}
    Destructor Destroy;Override;
  end;

{}
 TCollection=class(PCollection)
    constructor Load(S: TBufStream);Override;
    procedure   Store(S: TBufStream);Override;
  end;

 TSortedCollection=class(TCollection)
 public
    Duplicates: Boolean;
    constructor Create(ALimit: Integer);
    constructor Load(S: TBufStream);Override;
    procedure   Store(S: TBufStream);Override;
    function    Compare(Key1, Key2: Pointer): Integer; virtual;abstract;
    function    IndexOf(Item: Pointer): Integer; virtual;
    procedure   Insert(Item: Pointer); virtual;
    function    KeyOf(Item: Pointer): Pointer; virtual;
    function    Search(Key: Pointer; var Index: Integer): Boolean; virtual;
  end;


 TStrClass=Class(TTwgObject)
 public
   S:AnsiString;
    constructor Create(SS:AnsiString);
    constructor Load(B: TBufStream);Override;
    procedure   Store(B: TBufStream);Override;
    Destructor  Destroy;Override;
   end;


 TCStrings=class(PCollection)
     Procedure InsertStr(Item:AnsiString);Virtual;
     Procedure InsertStrings(S:TStrings);
     Function  GetStrings(Sorted:boolean = false):TStrings;
     Procedure FillStrings(FS:TStrings);
   {}
     Function Get(Index: Integer): AnsiString;
     Procedure Put(Index: Integer; Item: AnsiString);
   {}
     Property Strings[index : Integer]: AnsiString read Get write Put; default;
     Function IndexOf(S:AnsiString): Integer;
  end;


Procedure RegisterObject(CType  : TStreamClass;RCode   : SmallInt);
Procedure ReplaceRegister(replaceFrom,replaceTo:Integer);

implementation uses Dialogs, newExtendedProcs, LConvEncoding, ogcWriter;

type
  TStreamRec = record
    ObjType     : SmallInt;
    VmtLink     : TStreamClass;
  end;

  TStreamRecArray       = array[1..1] of TStreamRec;
  PStreamRecArray       = ^TStreamRecArray;

const
  RecordIncrement       = 8;
  ArrayIncrement        = RecordIncrement * SIZEOF(TStreamRec);
  NrOfStRecs            : WORD = 0;
  MaxNrOfStRecs         : WORD = 0;
  StreamRecords         : PStreamRecArray = nil;

{==========================================================}
Procedure ReplaceRegister(replaceFrom,replaceTo:Integer);
var I:Integer;
begin
  Repeat
    If StreamRecords^[I].ObjType = replaceFrom then begin
      StreamRecords^[I].ObjType:=replaceTo;
      Break;
    end;
    INC(I);
  Until i > NrOfStRecs;
end;

Procedure RegisterObject(CType   : TStreamClass;
                                RCode   : SmallInt);
var
  CurrentSize : WORD;
  i     : SmallInt;
begin
// Writeln(CType.ClassName,' ',RCode);
  If    (CType  = nil) then
    Raise EStreamError.CreateFmt('Нельзя зарегистрировать nil',[RCode]);
  If    (RCode  = 0) then
    Raise EStreamError.CreateFmt('Нулевой код регистрации',[CType.ClassName]);
  If NOT(CType.InheritsFrom(TTwgObject)) then
    Raise EStreamError.CreateFmt('Класс невозможно зарегистрировать',[CType.ClassName,RCode]);
  If NrOfStRecs > 0 then
  begin
    i   := 1;
    Repeat
      With StreamRecords^[i] do begin
        If (ObjType = RCode) then begin
           If (VmtLink = CType) then exit { Object is registered correctly }
           else begin
           //  Writeln('isREgistered ',RCode,' ',CType.ClassName);
            // Raise EStreamError.CreateFmt('Код регистрации уже был',[CType.ClassName,VmtLink.ClassName,RCode]);
           end;
        end;
      end;
      INC(I);
    until i > NrOfStRecs;
  end else begin
    StreamRecords       := AllocMem(ArrayIncrement);
    MaxNrOfStRecs       := RecordIncrement;
  end;
  If MaxNrOfStRecs = NrOfStRecs then begin
    CurrentSize         := MaxNrOfStRecs * SIZEOF(TStreamRec);
  {$IfDef Ver80}
    StreamRecords:=ReAllocMem(  StreamRecords,
                                        CurrentSize,
                                        CurrentSize + ArrayIncrement);
  {$Else}
    ReAllocMem(  StreamRecords,
                                        CurrentSize + ArrayIncrement);
  {$EndIf}
    Inc(MaxNrOfStRecs,RecordIncrement);
  end;
  INC(NrOfStRecs);
  With StreamRecords^[NrOfStRecs] do begin
   ObjType     := RCode;
   VmtLink     := CType;
//   Writeln(FA,RCode,' ',CType.ClassName);
  end;
end;

{ TBufStream }


Function TBufStream.FlushBuffer: boolean;
 begin
  Result:=True;
  TBufferedFileStream(FStream).Flush;
 end;

Constructor TBufStream.Create(fMem:boolean=True);
begin
  FStream:=TMemoryStream.Create;
  Status:=0;
end;

destructor TBufStream.Destroy;
begin
  If FCloseFile and FStream.InheritsFrom(THandleStream) then
   FileClose(THandleStream(FStream).Handle);
 FStream.Free;
end;

Constructor TBufStream.InitHandleStream(AHandle: THandle);
begin
  FStream := THandleStream.Create(AHandle);
  Status:=0;
end;

Constructor TBufStream.InitFileStream(FileName: AnsiString; Mode: Word);
begin
  FStream := TBufferedFileStream.Create(FileName,Mode);
  Status:=0;
end;

{Constructor TBufStream.InitBlobStream;
begin
  Str := Blob;
  FStream:=TS_BufStream.Create(Str);
  Status:=0;
end;
}

Constructor TBufStream.InitClipBoard(Mode:Word);
begin
  FStream := TClipboardStream.Create(CF_Ver25OBJECT, TClipboardMode(Mode));
  Status:=0;
end;


Function TBufStream.Get: TTwgObject;
var
  OType : SmallInt;
  i     : WORD;
begin
{000}
//  If NrOfStRecs = 0 then
//    Raise EStreamError.Create('Нет зарегистрированных типов');
//  If BLOCK_DEBUG then WriteS(['GET_BEGIN']);
  FStream.Read(OType, SIZEOF(OType));
//  If BLOCK_DEBUG then WriteS(['OTYPE=',OType]);
   If OType=0 then begin
    Get:=nil;exit;
   end;
  i := 1;
  Repeat
    If StreamRecords^[I].ObjType = OType then
      Break;
    INC(I);
  Until i > NrOfStRecs;
  If i > NrOfStRecs then
  begin
//    If BLOCK_DEBUG then WriteS(['Not_Found']);
    Raise EStreamError.CreateFmt('Не зарегистрирован тип %d',[OType]);
  end else begin
 //   If BLOCK_DEBUG then WriteS(['Load_begin']);
    Get        := StreamRecords^[i].VmtLink.Load(Self);
//    If BLOCK_DEBUG then WriteS(['Load_end']);
  end;
end;

Procedure TBufStream.Put(P :TTwgObject);
var
  OType,
  i: WORD;
begin
//  If NrOfStRecs = 0 then
//    Raise EStreamError.Create('Нет зарегистрированных типов');
   If P=nil then begin OType:=0;FStream.Write(OType, SIZEOF(OType));exit;end;
  i := 1;
//  Writeln(P.ClassName);
  Repeat
    If StreamRecords^[i].VmtLink = P.ClassType then
     begin
      Break;
     end;
    INC(I);
  Until i > NrOfStRecs;
  If i > NrOfStRecs then begin
  // Writeln('raise');
    Raise EStreamError.CreateFmt('Не зарегистрирован тип %d',[0]);
  end;
  With StreamRecords^[i] do
  begin
    FStream.Write(ObjType, SIZEOF(ObjType));
    P.Store(Self);
  end;
end;

Function TBufStream.ReadStr:AnsiString;
var
  L: Byte;
  L1:Integer;
  S:AnsiString;
begin
  Result := '';
  If CollectVer=9 then
  begin
   FStream.Read(L, SIZEOF(L));
    If L<>0 then
     begin
      SetLength(S,L);
      FStream.Read(S[1],L);
      Result:=CP1251ToUtf8(S);
     end else
      Result:='';
     Exit;
  end;
  FStream.Read(L1, SIZEOF(L1));
{  ShowMessage(IntTostr(L));}
  If L1<>0 then
  begin
    SetLength(S,L1);
{    Result^[0] := CHAR(L); for Win31 }
    FStream.Read(S[1],L1);
    Result:=CP1251ToUtf8(S);
//    If S = 'Тест' then WriteIn(['Тест1=',Result, S]);
{    ShowMessage(S);}
  end else
    Result:='';
end;

Procedure TBufStream.WriteStr(P: AnsiString);
 var L:Integer;
begin
  If P <> '' then
   begin
   { ShowMessage(IntToStr(Length(P^)));}
    L:=Length(P);P:=Utf8ToCP1251(P);
    FStream.Write(L,SizeOf(L));
    FStream.Write(P[1],L);
   end
  Else
   begin
    L:=0;
    FStream.Write(L,SizeOf(L));
   end;
end;

Function TBufStream.StrRead: PAnsiChar;
var
  L : WORD;
  S: AnsiString;
begin
  Result := nil;
  FStream.Read(L, SizeOf(L));
  If L = 0 then
    StrRead := nil
  Else
  begin
    Result:= {//TY Ansi}StrAlloc(L + 1);
    FStream.Read(Result[0], L);
    Result[L] := #0;
    S:= Result;
    Result:=PAnsiChar(CP1251ToUtf8(AnsiString(Result)));
  end;
end;

Procedure TBufStream.WriteString(P : AnsiString);
 var L:Integer;
begin
 L:=Length(P);P:=Utf8ToCP1251(P);
 FStream.Write(L,SizeOf(L));
 FStream.Write(P[1],L);
end;

Function TBufStream.ReadString:AnsiString;
 var L : Integer;
begin
  FStream.Read(L, SizeOf(L));
  If L = 0 then
    Result:=''
  else
  begin
    SetLength(Result,L);
    FStream.Read(Result[1], L);
    Result:=CP1251ToUtf8(Result);
  end;
end;

(*Procedure TBufStream.WriteFString;
 var L:Integer;
begin
 L:=Length(P);
 FStream.Write(L,SizeOf(L));
 FStream.Write(P[1],L);
end;

Function TBufStream.ReadFString:AnsiString;
 var L : Integer;
begin
  FStream.Read(L, SizeOf(L));
  If L = 0 then
    Result:=''
  else
  begin
    SetLength(Result,L);
    FStream.Read(Result[1], L);
  end;
end;
*)
Procedure TBufStream.StrWrite(P: PAnsiChar);
var
  L: Word;S:AnsiString;
begin
  If P = nil then
    L := 0
  Else
    L := StrLen(P);
  FStream.Write(L, SizeOf(Word));
  If P <> nil then begin
    S:=Utf8ToCP1251(P);
    FStream.Write(S[1], L);
  end;
end;


{$ASMMODE INTEL}

PROCEDURE ExtendedToIntel(VAR D : Extended {Double} ; VAR E : TExtended); ASSEMBLER;
  ASM
                FLD     QWORD PTR [RCX]
                FSTP    TBYTE PTR [RDX]
                FWAIT
  END;

PROCEDURE IntelToExtended(VAR E : TExtended ; VAR D : Extended {Double} ); ASSEMBLER;
  ASM
                FLD     TBYTE PTR [RCX]
                FSTP    QWORD PTR [RDX]
                FWAIT
  END;

{$ASMMODE ATT}

function TBufStream.ReadExtended: Extended;
var Ext:Extended;extExt:TExtended80Rec;
begin
{$IFDEF UNIX}
 Read(Ext,SizeOf(Extended));Result:=Ext;
{$ELSE WIN64}
 Read(extExt,SizeOf(TExtended80Rec));
 IntelToExtended(extExt,Ext);
 Result:=Ext;
{$ENDIF}
end;

function TBufStream.ReadSect: TExtendedSect;
var extExt:TExtended80Rec;Sect:TExtendedSect;
begin
 {$IFDEF UNIX}
 FStream.Read(Sect,SizeOf(Sect));
 With Result do begin
  Left:=Sect.Left;Top:=Sect.Top;Right:=Sect.Right;Bottom:=Sect.Bottom;
 end;
 {$ELSE WIN64}
 With Result do begin
  FStream.Read(extExt,SizeOf(extExt));IntelToExtended(extExt,Left);
  FStream.Read(extExt,SizeOf(extExt));IntelToExtended(extExt,Top);
  FStream.Read(extExt,SizeOf(extExt));IntelToExtended(extExt,Right);
  FStream.Read(extExt,SizeOf(extExt));IntelToExtended(extExt,Bottom);
 end;
 {$ENDIF}
end;

Function TBufStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result        := FStream.Read(Buffer,Count);
end;

Procedure TBufStream.WriteExtended(Ext:Extended);
var extExt:TExtended80Rec;
begin
{$IFDEF UNIX}
 FStream.Write(Ext,SizeOf(Extended));
{$ELSE WIN64}
// extExt:=ToExtended80(Ext);
 ExtendedToIntel(Ext,extExt);
 FStream.Write(extExt,SizeOf(TExtended80Rec));
{$ENDIF}
end;

procedure TBufStream.WriteSect(Sect: TExtendedSect);
var extSect:TExtended80Sect;
begin
 {$IFDEF UNIX}
  FStream.Write(Sect,SizeOf(Sect));
 {$ELSE WIN64}
 // Запись не работает !!!
  With extSect do begin
   ExtendedToIntel(Sect.Left,Left);
   ExtendedToIntel(Sect.Right,Right);
   ExtendedToIntel(Sect.Top,Top);
   ExtendedToIntel(Sect.Bottom,Bottom);
  end;
  FStream.Write(extSect,SizeOf(extSect));
 {$ENDIF}
end;

Function TBufStream.Write(Const Buffer; Count: Longint): Longint;
begin
  Result        := FStream.Write(Buffer,Count);
end;

Function TBufStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result        := FStream.Seek(Offset,Origin);
end;

Function TBufStream.CopyFrom(Source: TStream; Count: Longint): Longint;
begin
  Result        := FStream.CopyFrom(Source,Count);
end;

Function TBufStream.GetPos: Longint;
begin
  Result        := FStream.Position;
end;

Procedure TBufStream.SetPos(Pos: Longint);
begin
  FStream.Position := Pos;
end;

Function TBufStream.GetSize: Longint;

begin
  Result        := FStream.Size;
end;

Function TBufStream.GetHandle: INTEGER;

begin
  If FStream IS THandleStream then
    Result      := THandleStream(FStream).Handle
  Else
    Raise EStreamError.CreateFmt('GetHandle ошибка в',[FStream.ClassName,THandleStream.ClassName]);
end;


 { PCollection }


Function PCollection.GetCount: Integer;
 begin
  GetCount:=FList.Count;
 end;

Procedure PCollection.CheckList;
begin
  If Flist = nil then
    Raise EListError.Create('Коллекция пуста')
end;

Function PCollection.Get(Index: Integer): Pointer;
begin
//  CheckList;
  Result := FList[Index];
end;

Procedure PCollection.Put(Index: Integer; Item: Pointer);

begin
//  If Item = nil then exit;
  CheckList;
  FList[Index]  := InsertItem(Item);
end;

Constructor PCollection.Create(ALimit : Integer);

begin
  FList         := TList.Create;
  FList.Capacity:= ALimit;
//  FArray:= FList.List;
end;



Constructor PCollection.Load(S:TBufStream);
var
  I,
  Count1,
  Capacity1,
  Delta1 : SmallInt;
  Obj:TObject;
begin
  S.Read(Count1, SizeOf(Count1));
// If Collect432 then Count1 :=0;
  S.Read(Capacity1, SizeOf(Capacity1));
  S.Read(Delta1, SizeOf(Delta1));       { The old PCollectionObject had this field also. }
  if Capacity1<=0 then Capacity1:=1;
  Create(Capacity1);
  For I := 1 TO Count1 do begin
 {   If BLOCK_DEBUG then begin
      WriteS(['BI=',I]);
      If I=2 then
        WriteS(['beginDebug']);
    end;
 }
    Obj:=TObject(GetItem(S));
    FList.Add(Obj);
//    If BLOCK_DEBUG then WriteS(['EI=',I,Obj.ClassName]);
  end;
{   Writeln(FList.Count);}
{  S.Read(I, 2);
  Writeln('I=',I);}
end;

Procedure PCollection.Store(S: TBufStream);
var
  I,
  Count1,
  Capacity1      : SmallInt;
  Delta1 : SmallInt;
begin
 Delta1:=1;Capacity1:=1;
  If Assigned(FList) then
  begin
    Count1       := FList.Count;
    Capacity1    := FList.Capacity;
  end Else
  begin
    Count1       := 0;
    Capacity1    := 0;
  end;
  S.Write(Count1,SizeOf(Count1));
  S.Write(Capacity1, SizeOf(Capacity1));
  S.Write(Delta1, SizeOf(Delta1));       { The old PCollectionObject had this field also. }
{  S.Write(Capacity, SizeOf(Capacity));}
  For I := 0 TO Count-1 do
    PutItem(S,FList[I])
end;

Function PCollection.GetItem(S: TBufStream): Pointer;
begin
  GetItem := S.Get;
end;

Procedure PCollection.PutItem(S: TBufStream; Item: Pointer);
begin
  S.Put(TTwgObject(Item));
end;


Function PCollection.InsertItem(Item: Pointer) : Pointer;
begin
  InsertItem    := Item;                                     
end;

Procedure PCollection.Insert(Item: Pointer);
begin
  If Item = nil then
    Raise EListError.CreateFmt('Нельзя вставить nil в',[Self.ClassName]);
  FList.Add(Item);
{  Writeln('FlistCnt=',Flist.Count);}
end;

Procedure PCollection.AtInsert(Index: Integer; Item: Pointer);

begin
  If Item = nil then
    Raise EListError.CreateFmt('Нельзя вставить nil в',[Self.ClassName]);
  CheckList;
  FList.Insert(Index, InsertItem(Item));
end;

Procedure PCollection.AtPut(Index: Integer; Item: Pointer);

begin
  If Item = nil then
    Raise EListError.CreateFmt('Нельзя вставить nil в',[Self.ClassName]);
  CheckList;
  FList.Items[Index] := InsertItem(Item);
end;

Procedure PCollection.AtReplace(Index: Integer; Item: Pointer);

begin
  If Item = nil then
    Raise EListError.CreateFmt('Нельзя вставить nil в',[Self.ClassName]);
  CheckList;
  With FList do
  begin
    FreeItem(Items[Index]);
    Items[Index] := InsertItem(Item);
  end;
end;

Function PCollection.IndexOf(Item: Pointer): Integer;
begin
  CheckList;
  Result        := FList.IndexOf(Item);
end;

Function PCollection.At(Index: Integer): Pointer;
begin
//  CheckList;
{   writeln('F=',Index);}
// Result := FList.Items[Index];
 Result:=FList[Index];
{   writeln('L=',Index);}                            
end;

Procedure PCollection.AtDelete(Index: Integer);

begin
  CheckList;
  FList.Delete(Index);
end;

Procedure PCollection.Delete(Item: Pointer);

begin
  CheckList;
  FList.Remove(Item);
end;

Procedure PCollection.Remove(Item: Pointer);
begin
  CheckList;
  FList.Remove(Item);
  FreeItem(Item);
end;

Procedure PCollection.DeleteAll;
begin
  If Flist <> nil then
   begin
    FList.Count := 0;
   end;
end;

Procedure PCollection.FreeItem(Item: Pointer);
begin
  TTwgObject(Item).Free;
end;

Procedure PCollection.AtFree(Index: Integer);
begin
  CheckList;
  With FList do
  begin
    FreeItem(Items[Index]);
    Delete(Index);
  end;
end;

Procedure PCollection.FreeAll;
var
  I: Integer;
begin
  If Flist <> nil then
    With FList do
    begin
      For I := 0 TO Count - 1 do
       begin
       If BLOCK_DEBUG then begin
//         WriteS(['I=',I]);
 //        WriteS(['Beg',I,TObject(FList[I]).ClassName]);
       end;
        FreeItem(FList[I]);
 //      If BLOCK_DEBUG then WriteS(['End',I]);
       end;
      Count := 0;
    end;
end;

{Function PCollection.FirstThat(Test: Pointer): Pointer; EXTERNAL;

Procedure PCollection.ForEach(Action: Pointer); EXTERNAL;

Function PCollection.LastThat(Test: Pointer): Pointer; EXTERNAL;}

Procedure PCollection.Pack;
begin
  If Flist <> nil then
    FList.Pack;
end;

Procedure PCollection.SetLimit(ALimit: Integer);
begin
  If FList = nil then
    FList       := TList.Create;
  FList.Capacity        := ALimit;
end;


Destructor PCollection.Destroy;
 begin
   FreeAll;
   FList.Free;
   Inherited Destroy;
 end;


{--------------------------------------------------------------}
Constructor TCollection.Load(S:TBufStream);
var
  I,
  Count1,
  Capacity1,
  Delta1 : Integer;
begin
  S.Read(Count1, SizeOf(Count1));
  S.Read(Capacity1, SizeOf(Capacity1));
  S.Read(Delta1, SizeOf(Delta1));
  Create(Capacity1);
  For I := 1 to Count1 do
    FList.Add(GetItem(S));
end;

Procedure TCollection.Store(S: TBufStream);
var
  I,
  Count1,
  Capacity1:Integer;
  Delta1   :Integer;
begin
 Delta1:=1;Capacity1:=1;
  If Assigned(FList) then
  begin
    Count1       := FList.Count;
    Capacity1    := FList.Capacity;
  end else
  begin
    Count1       := 0;
    Capacity1    := 0;
  end;
  S.Write(Count1,SizeOf(Count1));
  S.Write(Capacity1, SizeOf(Capacity1));
  S.Write(Delta1, SizeOf(Delta1));
  For I := 0 to Count-1 do
    PutItem(S,FList[I])
end;
{--------------------------------------------------------------}

constructor TSortedCollection.Create(ALimit: Integer);
begin
  Inherited Create(ALimit);
  Duplicates := False;
end;


function TSortedCollection.IndexOf(Item: Pointer): Integer;
var
  I: Integer;
begin
  IndexOf := -1;
//  Writeln(Search(KeyOf(Item), I));
  if Search(KeyOf(Item), I) then
  begin
    if Duplicates then
      while (I < Count) and (Item <> Items[I]) do Inc(I);
    if I < Count then IndexOf := I;
  end;
end;

procedure TSortedCollection.Insert(Item: Pointer);
var I: Integer;
begin
  if not Search(KeyOf(Item),I) or Duplicates  then begin AtInsert(I, Item);end;
end;

function TSortedCollection.KeyOf(Item: Pointer): Pointer;
begin
  KeyOf := Item;
end;

function TSortedCollection.Search(Key: Pointer; var Index: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Search := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := Compare(KeyOf(Items[I]), Key);
    if C < 0 then L := I + 1 else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Search := True;
        if not Duplicates then L := I;
      end;
    end;
  end;
  Index := L;
end;

constructor TSortedCollection.Load(S: TBufStream);
begin
  inherited Load(S);                
  S.Read(Duplicates, SizeOf(Boolean));
end;

procedure TSortedCollection.Store(S: TBufStream);
begin
  Inherited Store(S);
  S.Write(Duplicates, SizeOf(Boolean));
end;

{--------------------------------------------------------------}
  Constructor TStrClass.Create(SS:AnsiString);
   begin
    S:=SS;
   end;

  Constructor TStrClass.Load(B:TBufStream);
  var S1:String;
   begin
    S:=B.ReadStr;
    S1:=Utf8Encode(S);
   // S:=UTF8Encode(S1);
   // S:=S1;
   end;

  Procedure TStrClass.Store(B:TBufStream);
   begin
    B.WriteStr(S);
   end;                   

  Destructor TStrClass.Destroy;
   begin
//    If BLOCK_DEBUG then WriteS(['sd=',S]);
    SetLength(S,0);
//    If BLOCK_DEBUG then WriteS(['sd2']);
   end;

  Procedure TCStrings.InsertStrings(S:TStrings);
   var I:Integer;
   begin
     For I:=0 to S.Count-1 do
      InsertStr(S[I]);
   end;

  Function TCStrings.GetStrings(Sorted:boolean = false):TStrings;
   var I:Integer;
   begin
    Result:=TStringList.Create;
    TStringList(Result).Sorted:=Sorted;
    For I:=0 to Count-1 do
     Result.Add(Strings[I]);
   end;

  Procedure TCStrings.FillStrings(FS:TStrings);
   var I:Integer;
   begin
    For I:=0 to Count-1 do
      FS.Add(Strings[I]);
   end;

  Procedure TCStrings.InsertStr(Item:AnsiString);
   begin
    Insert(TStrClass.Create(Item));
   end;

  Procedure TCStrings.Put(Index: Integer; Item: AnsiString);
   var P:TStrClass;
   begin
    TStrClass(Items[Index]).S:=Item;
   {
    P:=TStrClass(Items[Index]);
    DisposeStr(P.S);
    P.S:=NewStr(Item);
   }
   end;

  Function TCStrings.Get(Index: Integer):AnsiString;
   begin
    Result:=TStrClass(Items[Index]).S;
   end;

function TCStrings.IndexOf(S: AnsiString): Integer;
var I:Integer;
begin
 Result:=-1;
 For I:=0 to Count-1 do
  If Strings[I]=S then begin
   Result:=I;
   exit;
  end;
end;

Initialization
//  AssignFile(FA,'C:\D\Collect_Typhon.txt');
//  Rewrite(FA);
  CF_Ver25OBJECT:=RegisterClipboardFormat('VER25');
  RegisterObject(PCollection,50);
  RegisterObject(TSortedCollection,51);
  RegisterObject(TCStrings,52);
  RegisterObject(TStrClass,53);
finalization
//  CloseFile(FA);
end.                                                        
