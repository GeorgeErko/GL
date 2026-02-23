unit ogcWriter;

interface uses LCLType, Classes, Controls, StdCtrls, Forms, SysUtils, Dialogs,
               ogcBasic, stopForm;

type
// режим создания outList TWriterDesk (очищать лог outFile, уничтожать outList)
 TwdOptionEnum = (wdRewriteFile, wdDestroyList);
 TwdOptions = set of TwdOptionEnum;

 // режим TwdCollection при вызове события OnChangeItem
 TChangeMode = (cmAdd, cmDelete, cmNone);
 TOutMode = (omStandard, omConsole);

const
  outDisabled: Boolean = False;
  outMode: TOutMode = omConsole;
  outSpace: String = ' ';
  lastPgrStr: String = '';

 { TWriterDesk }
type
 TWriterDesk = class(TogsBasic)
 private
  stopFrm: TStopFrm;
  fOnUpdateText: TNotifyEvent;
  function GetoutString: String;
 public
   Locked : boolean;
   outFile: String;
   outList: TStrings;
   outName: String;
   Options: TwdOptions;
   outPgr : boolean; // вывод в строку без перевода каретки
   constructor Create(outFile_: string; outList_: TStrings; Options_: TwdOptions);
   destructor Destroy;override;
   function WriteToFile(outString: String): boolean;
   property outString: String read GetoutString;
   property OnUpdateText: TNotifyEvent read fOnUpdateText write fonUpdatetext;
 end;

// коллекция TWriterDesk

 { TwdCollection }

 TwdCollection = class(TogsCollection)
 private
  fActive: Integer;
  fChangeMode: TChangeMode;
  fonChangeItem: TNotifyEvent;
  procedure SetActive(AValue: Integer);
 public
  procedure AddWriter(wd: TWriterDesk);
  procedure DeleteWriter(wd: TWriterDesk);
  destructor Destroy;override;
  function Find(AName: String): Integer;
  property Active: Integer read fActive write SetActive;
  property ChangeMode: TChangeMode read fChangeMode write fChangeMode;
  property OnChangeItem: TNotifyEvent read fOnChangeItem write fOnChangeItem;
 end;

var def_WD: TWriterDesk;
    wdCollection: TwdCollection;

 Function AsParam(Const V: TVarRec; C:Integer = 3): String;
 Function Fmt(Params: Array of Const; C:Integer = 3): String;
// запись в outFile
 Procedure WriteFl(Params: Array of Const; wd:TWriterdesk = nil; C:Integer = 3);
// запись в outList
 Procedure WriteIn(Params: Array of Const; wd:TWriterdesk = nil; C:Integer = 3);
 // перезапмсь последней строки
 Procedure WriteNl(Params: Array of Const; wd:TWriterdesk = nil; C:Integer = 3);
// запись в строку
 Procedure WriteStr(var Str: String;Params: Array of Const; wd:TWriterdesk = nil; C:Integer = 3);
// ShowMessge
 Procedure WriteMsg(Params: Array of Const; C: Integer = 3);
//
 Procedure ClearIn();
 Procedure ClearLn();
 Procedure ReadIn();
//
 Function OpenWriter(outFile_: String; outList_: TStrings; Options_: TwdOptions): TWriterDesk;
 Procedure CloseWriter(Writer: TWriterDesk);

 procedure DisableIn;
 procedure EnableIn;


implementation uses DebuggerForm, LazLoggerBase, LazTracer;

{ TwdCollection }

procedure TwdCollection.SetActive(AValue: Integer);
begin
 If (AValue < 0) and (AValue > Count-1) then raise Exception.Create('Ошибка инициализации потока TwdCollection.SetrActive');
 fActive := AValue;
end;

function TwdCollection.Find(AName: String): Integer;
var I: Integer;
begin
 Result := -1;
 For I := 0 to Count-1 do If TWriterDesk(Items[I]).outName = AName then begin
  Result := I;
  exit;
 end;
end;

procedure TwdCollection.AddWriter(wd: TWriterDesk);
begin
 Add(wd);
 ChangeMode := cmAdd;
 try
  Active := Count - 1;
  If Assigned(fOnChangeItem) then fOnChangeItem(Self)
 finally
  ChangeMode := cmNone;
 end;
end;

procedure TwdCollection.DeleteWriter(wd: TWriterDesk);
var Index: Integer;
begin
 If List.IndexOf(wd) = -1 then raise Exception.Create(Fmt(['Ошибка при деинициализации deleteWriter.outFile',wd.outFile]));
 If Count = 1 then exit;
 Index := List.IndexOf(wd);
 AtFree(List.IndexOf(wd));
 ChangeMode := cmDelete;
 try
  If Assigned(fOnChangeItem) then fOnChangeItem(Self);
  If Index <= Count - 1 then Active := Index else
   If Count > 0 then Active := Index - 1 else Active := -1;
 finally
  ChangeMode := cmNone;
  If Active <> -1 then If Assigned(fOnChangeItem) then fOnChangeItem(Self)
 end;
end;

destructor TwdCollection.Destroy;
begin
 inherited Destroy;
end;

//

function AsParam(const V: TVarRec; C: Integer): String;
var S:AnsiString;
begin
 with V do
  case VType of
   vtWideChar:Result:=V.VWideChar;
   vtUnicodeString:Result:=WideCharToString(V.VUnicodeString);
   vtInt64:begin
               Str(V.VInt64^:-1,S);
               Result:=S;
             end;
   vtInteger:begin
               Str(V.VInteger:-1,S);
               Result:=S;
             end;
   vtBoolean:if V.VBoolean then AsParam:='True' else AsParam:='False' ;
   vtExtended:begin
               Str(V.VExtended^:-1:C,S);
               AsParam:=S;
              end;
   vtString:AsParam:=V.VString^;
   vtAnsiString:begin
                 S:=AnsiString(V.VAnsiString);
                 AsPAram:=S;
                end;
   vtChar:begin
           S:=V.VChar;
           AsPAram:=S;
          end;
   vtPChar:AsPAram:=V.VPChar;
   vtObject,
   vtClass,
   vtPointer:begin
              AsParam:='Object';
             end;
  end;
end;

function Fmt(Params: array of const; C: Integer): String;
var S1,S2,Fmt1:AnsiString;I:Integer;J:TVarRec;V:Variant;
Function AsParam(Const V:TVarRec):AnsiString;
var S:AnsiString;
begin
 with V do
  case VType of
   vtWideChar:Result:=V.VWideChar;
   vtUnicodeString:Result:=WideCharToString(V.VUnicodeString);
//   vtPWideChar:Result:=V.VWideChar;
   vtInt64:begin
            Str(V.VInt64^:-1,S);
            Result:=S;
           end;
   vtInteger:begin
               Str(V.VInteger:-1,S);
               Result:=S;
             end;
   vtBoolean:if V.VBoolean then AsParam:='True' else AsParam:='False' ;
   vtExtended:begin
               Str(V.VExtended^:-1:C,S);
               AsParam:=S;
              end;
   vtString:AsParam:=V.VString^;
   vtAnsiString:begin
                 S:=AnsiString(V.VAnsiString);
                 AsPAram:=S;
                end;
   vtChar:begin
           S:=V.VChar;
           AsPAram:=S;
          end;
   vtPChar:AsPAram:=V.VPChar;
   vtPointer:AsParam:='Ptr ('+IntToStr(Integer(V.VPointer))+')';
   vtObject:If V.VObject is TogsBasic then begin
             AsParam:=TogsBasic(V.VObject).WriteObj([]);
            end else
             AsParam:='Incorrect WriteIn object type '+V.VObject.ClassName;
  end;
end;
begin
 Fmt1:='';
 For I:=Low(Params) to High(Params) do
  begin
    S1:=AsParam(Params[I]);
    Fmt1:=Fmt1 + S1 + outSpace;
  end;
 Result:=Fmt1;
end;

procedure WriteIn(Params: array of const; wd: TWriterdesk; C: Integer);
begin
 If outDisabled then exit;
 If outMode = omConsole then begin
  lastPgrStr := '';
  DebugLn(Fmt(Params));
  exit;
 end;
 If wd = nil then begin
  If wdCollection = nil then exit;
  If wdCollection.Count = 0 then exit;
  wd := TWriterDesk(wdCollection[0]);
  //  Exception.Create('Ошибка  вывода WriteIn:'); exit;
 end;
 If wd.Locked then exit;
 wd.Locked := True;
 try
  If wd.outList<>nil then wd.outList.Add(Fmt(Params,C));
  If Assigned(wd.OnUpdateText) then wd.OnUpdateText(wd);
 finally
  wd.Locked := False;
 end;
end;

procedure WriteNl(Params: array of const; wd: TWriterdesk; C: Integer);
function outBack(S: String): String;
begin
 Result := S;
 lastPgrStr := S;
 FillChar(lastPgrStr[1], Length(S), #8);
// WriteIn(['pgryyy=', lastPgrStr, length(lastPgrStr), Length(S)]);
end;
begin
 If outDisabled then exit;
 If outMode = omConsole then begin
 // DbgOut([lastPgrStr, outBack(Fmt(Params))]);
  Write(lastPgrStr, outBack(Fmt(Params)));
  exit;
 end;
 If wd = nil then begin
  If wdCollection = nil then exit;
  If wdCollection.Count = 0 then exit;
  wd := TWriterDesk(wdCollection[0]);
 //  Exception.Create('Ошибка  вывода WriteIn:'); exit;
 end;
 If wd.Locked then exit;
 wd.Locked := True;
 try
  If wd.outList<>nil then wd.outList[wd.outList.Count-1] := (Fmt(Params,C));
  wd.outPgr := True;
  try
   If Assigned(wd.OnUpdateText) then wd.OnUpdateText(wd);
  finally
   wd.outPgr := False;
  end;
 finally
  wd.Locked := False;
 end;
end;

procedure WriteFl(Params: array of const; wd: TWriterdesk; C: Integer);
begin
 If wd = nil then begin
  If wdCollection = nil then exit;
  If wdCollection.Count = 0 then exit;
  wd := TWriterDesk(wdCollection[wdCollection.Active]);
 // Exception.Create('Ошибка вывода WriteFL')
 end;
 If wd.Locked then exit;
 wd.Locked := True;
 try
  wd.WriteToFile(Fmt(Params,C));
 finally
  wd.Locked := False;
 end;
end;

procedure WriteStr(var Str: String; Params: array of const; wd: TWriterdesk; C: Integer);
begin
 If wd = nil then begin
  If wdCollection = nil then exit;
  If wdCollection.Count = 0 then exit;
  wd := TWriterDesk(wdCollection[wdCollection.Active]);
 // Exception.Create('Ошибка вывода WriteFL')
 end;
 If wd.Locked then exit;
 wd.Locked := True;
 try
  Str := Str + (Fmt(Params,C))+#13#10;
  If Assigned(wd.OnUpdateText) then wd.OnUpdateText(wd);
 finally
  wd.Locked := False;
 end;
end;

procedure WriteMsg(Params: array of const; C: Integer);
begin
 ShowMessage(Fmt(Params,C));
end;

procedure ClearIn;
var wd: TWriterDesk;
begin
 if outDisabled then exit;
 wd := TWriterDesk(wdCollection[0]);
 If wd.outList<>nil then begin
  wd.outList.Clear;
  If Assigned(wd.OnUpdateText) then wd.OnUpdateText(wd);
 end;
end;

procedure ClearLn;
var wd: TWriterDesk;
begin
 if outDisabled then exit;
 wd := TWriterDesk(wdCollection[0]);
 If wd.outList<>nil then begin
  wd.outList[wd.OutList.Count-1] := '';
  If Assigned(wd.OnUpdateText) then wd.OnUpdateText(wd);
 end;
end;

procedure ReadIn;
var wd: TWriterDesk;
begin
 if outDisabled then exit;
 If outMode = omConsole then begin
  Readln;
  exit;
 end;
 wd := TWriterDesk(wdCollection[0]);
 If Debugger = nil then exit;
 Debugger.ShowStopForm(wd.StopFrm);
end;

function OpenWriter(outFile_: String; outList_: TStrings; Options_: TwdOptions): TWriterDesk;
var I: Integer;
begin
{
 For I := 0 to wdCollection.Count - 1 do
  With TWriterDesk(wdCollection[I]) do
   If (outFile = outFile_) and (outList = outList_) then begin
    WriteMsg([outList.Text]);
    Result := TWriterDesk(wdCollection[I]); exit;
   end;
}
 Result := TWriterDesk.Create(outFile_, outList_, Options_);
end;

procedure CloseWriter(Writer: TWriterDesk);
begin
 wdCollection.DeleteWriter(Writer);
end;

procedure DisableIn;
begin
 OutDisabled := True;
end;

procedure EnableIn;
begin
 OutDisabled := False;
end;

{ TWriterDesk }

function TWriterDesk.GetoutString: String;
begin
 Result := outList[outList.Count - 1]
end;

constructor TWriterDesk.Create(outFile_: string; outList_: TStrings; Options_: TwdOptions);
var F: Text;
    Button: TButton;
begin
 outFile := outFile_;
 outList := outList_;
 Options := Options_;
 AssignFile(F, outFile);
 try
  Rewrite(F);
 except
  outFile := '';
  WriteIn(['Ошибка записи в файл TWriterDesk.Create', outFile]); exit;
 end;
 Close(F);
 wdCollection.AddWriter(Self);
 WriteIn(['Writer opened:',TimeToStr(Now)], Self);
//
end;

destructor TWriterDesk.Destroy;
begin
 stopFrm.Free;
 If wdDestroyList in Options then outList.Free;
// showmessage(fmt(['Writer closed ' + outFile + ':',TimeToStr(Now)]));
end;

function TWriterDesk.WriteToFile(outString: String): boolean;
var F: Text;
begin
 AssignFile(F, outFile);
 try
  Append(F);
 except
  WriteIn(['Ошибка записи в файл TWriterDesk.Append',outFile]);
  exit;
 end;
 Writeln(F, outString);
 Close(F);
end;

initialization
 wdCollection := TwdCollection.Create;
finalization
 wdCollection.Free;
end.

