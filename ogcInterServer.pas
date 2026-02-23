unit ogcInterServer;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, DateUtils, WSClient,  ogcProperties;

const
  GlobalMsgID : Integer = 0;
 // MSGID's
  MSGID_Standart = 0;
  MSGID_Connect = 1;
  MSGID_CreateSession = 2;
  MSGID_Confirm = 3;

type

 { TMsgItem }

 TMsgItem = class
 public
 // уникальный заголовок сообщения
  msgGUID: TGUID;
  msgTime: TDateTime; // время в целочисленном виде
 //
  msgText: string;
  constructor Create(AGUID: TGUID; AMsgTime: TDateTime; AMsgText: string);
 end;

 { TMsgHistory }

 TMsgHistory = class
 private
  FIndex: Integer;
  procedure SetIndex(AValue: Integer);
 public
  SendMsg: TMsgItem;
  ReceiveMsg: TMsgItem;
  constructor Create(ASendMsg: TMsgItem);
  destructor Destroy; override;
  property Index: Integer read FIndex write SetIndex;
 end;

 { TMsgHistoryList }

 TMsgHistoryList = class(TFPObjectList)
 private
 // хранение элементов, на которые был получен ответ от сервера
  fCreateContainer: Boolean;
  fContainer: TMsgHistoryList;
  function GetItem(Index: Integer): TMsgHistory;
  procedure SetItem(Index: Integer; AValue: TMsgHistory);
  procedure ReindexFrom(StartIndex: Integer);
  function FindByPrefixAndTime(AGUID: TGUID; AMsgTime: TDateTime): TMsgHistory;
 public
  constructor Create(CreateContainer: boolean = True);
  destructor Destroy; override;
  property Items[Index: Integer]: TMsgHistory read GetItem write SetItem; default;
  property Container: TMsgHistoryList read FContainer;
  function Add(AItem: TMsgHistory): Integer;
  function AddReceive(AItem: TMsgItem): TMsgHistory;
  function Insert(Index: Integer; AItem: TMsgHistory): Integer;
  function Delete(Index: Integer): Integer;
  function Remove(AItem: TMsgHistory): Integer;
  function Search(AGUID: TGUID; ATime: TDateTime): Integer;
 end;

 { TBaseWebSocketClient }

 TBaseWebSocketClient = class(TComponent)
 private
   fConnected: Boolean;
   fClientID,
   fSessionID: string;
   urlAddr, Port: String;
   Login, Password: String;
   FWS: TogswsClient;
   fToken: string;
   fHistoryList: TMsgHistoryList;
  //
   function GetAthorized: Boolean;
   procedure wsReceive(const aData: String);
 protected
   function GetConnected: Boolean; virtual;
 public
   constructor Create(AOwner: TComponent; urlAddr_, Port_: String);
   destructor Destroy; override;
   function GetToken(Login_, Password_: String): string; virtual;
   function Connect: Boolean; virtual;
   procedure Disconnect; virtual;
   function SendMsg(MSGID: Integer; AMsgText: string): Boolean; virtual;
   function CheckMessage(MSGID: Integer; propValue: TogsPropValue): Boolean; virtual;

   property Authorized: Boolean read GetAthorized;
   property Connected: Boolean read GetConnected;
   property Token: string read FToken;
   property ClientID : string read fClientID;
   property SessionID: string read fSessionID;
   property HistoryList: TMsgHistoryList read fHistoryList;
   property WSClient: TogswsClient read FWS;
  //
 end;

implementation uses ogcWriter, synachar,
                     IdHTTP, IdMultipartFormData, IdGlobal;

// Unix time <-> Win time

function DateTimeToUnix(const AValue: TDateTime): Int64;
const
  UnixStartDate: TDateTime = 25569.0; // 01/01/1970
begin
  Result := Round((AValue - UnixStartDate) * 86400);
end;

function UnixToDateTime(const AValue: Int64): TDateTime;
const
  UnixStartDate: TDateTime = 25569.0; // 01/01/1970
begin
  Result := (AValue / 86400) + UnixStartDate;
end;

{ TMsgItem }

constructor TMsgItem.Create(AGUID: TGUID; AMsgTime: TDateTime; AMsgText: string);
begin
 inherited Create;
 msgGUID := AGUID;
 msgTime := AMsgTime;
 msgText := AMsgText;
end;

{ TMsgHistory }

constructor TMsgHistory.Create(ASendMsg: TMsgItem);
begin
 inherited Create;
 SendMsg := ASendMsg;
 ReceiveMsg := nil;
 FIndex := -1; // Will be set when added to list
end;

procedure TMsgHistory.SetIndex(AValue: Integer);
begin
 FIndex := AValue;
end;

destructor TMsgHistory.Destroy;
begin
 SendMsg.Free;
 if Assigned(ReceiveMsg) then
   ReceiveMsg.Free;
 inherited Destroy;
end;

{ TMsgHistoryList }

constructor TMsgHistoryList.Create(CreateContainer: boolean);
begin
 inherited Create(True);
 fCreateContainer := CreateContainer;
 If CreateContainer then
  FContainer := TMsgHistoryList.Create(False); // не создаем вложенный контейнер
                                               // не используем AddReceive
end;

destructor TMsgHistoryList.Destroy;
begin
 FContainer.Free;
 inherited Destroy;
end;

function TMsgHistoryList.GetItem(Index: Integer): TMsgHistory;
begin
 Result := TMsgHistory(inherited Items[Index]);
end;

procedure TMsgHistoryList.SetItem(Index: Integer; AValue: TMsgHistory);
begin
 inherited Items[Index] := AValue;
end;

function TMsgHistoryList.Add(AItem: TMsgHistory): Integer;
var i: Integer;
begin
 Result := Count;
 for i := 0 to Count - 1 do
 begin
  if CompareByte(Items[i].SendMsg.msgGUID, AItem.SendMsg.msgGUID, SizeOf(TGUID)) = 1 then
   begin
    Result := i;
    Break;
   end;
 end;
 Result := Insert(Result, AItem);
end;

function TMsgHistoryList.Insert(Index: Integer; AItem: TMsgHistory): Integer;
begin
 inherited Insert(Index, AItem);
 AItem.Index := Index;
 ReindexFrom(Index + 1);
 Result := Index;
end;

function TMsgHistoryList.Delete(Index: Integer): Integer;
begin
 inherited Delete(Index);
 ReindexFrom(Index);
 Result := Count;
end;

function TMsgHistoryList.Remove(AItem: TMsgHistory): Integer;
var
  i: Integer;
begin
 i := inherited IndexOf(AItem);
 if i >= 0 then
   Result := Delete(i)
 else
   Result := -1;
end;

procedure TMsgHistoryList.ReindexFrom(StartIndex: Integer);
var
  i: Integer;
begin
 for i := StartIndex to Count - 1 do
   Items[i].Index := i;
end;

function TMsgHistoryList.FindByPrefixAndTime(AGUID: TGUID; AMsgTime: TDateTime): TMsgHistory;
var Index: Integer;
begin
 Index := Search(AGUID, AMsgTime);
 If Index = -1 then
  Result := nil
   else
    Result := List[Index];
end;

function TMsgHistoryList.AddReceive(AItem: TMsgItem): TMsgHistory;
var
  HistoryItem: TMsgHistory;
  Index: Integer;
begin
 if not fCreateContainer then raise Exception.Create('TMsgHistoryList.AddReceive. Ban to use Container');
  Result := nil;
  HistoryItem := nil;
  // Ищем соответствующий элемент в основном списке
 // HistoryItem := FindByPrefixAndTime(AItem.GUID, AItem.MsgTime);
  Index := Search(AItem.msgGUID, AItem.msgTime);
  If Index > -1 then
   HistoryItem := Items[Index];

  if Assigned(HistoryItem) then
  begin
    // Найден существующий элемент - обновляем его
    if Assigned(HistoryItem.ReceiveMsg) then
      HistoryItem.ReceiveMsg.Free;
    HistoryItem.ReceiveMsg := AItem;
    Result := HistoryItem;

    // Перемещаем в контейнер истории
    Index := HistoryItem.Index; // индекс в коллекции
    if Index >= 0 then
    begin
      // Удаляем из основного списка, но не уничтожаем объект
      // !!!! inherited Delete(Index);
      List.Delete(Index);
      // Добавляем в контейнер истории
      FContainer.Add(HistoryItem);
      // Переиндексируем оставшиеся элементы
      ReindexFrom(Index);
    end;
  end;
end;

function TMsgHistoryList.Search(AGUID: TGUID; ATime: TDateTime): Integer;
var
  L, H, I: Integer;
  CompareRes: Integer;
begin
  Result := -1;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) div 2;
    CompareRes := CompareByte(Items[I].SendMsg.msgGUID, AGUID, SizeOf(TGUID));
    if CompareRes = 0 then
     Exit(I)
    else if CompareRes < 0 then
      L := I + 1
    else
      H := I - 1;
  end;
end;

{ TBaseWebSocketClient }

constructor TBaseWebSocketClient.Create(AOwner: TComponent; urlAddr_, Port_: String);
begin
  inherited Create(AOwner);
  urlAddr := urlAddr_;
  Port := Port_;
  fHistoryList := TMsgHistoryList.Create;
  FWS := nil;
  fToken := '';
  fClientID := '';
end;

destructor TBaseWebSocketClient.Destroy;
begin
  Disconnect;
  fHistoryList.Free;
  inherited Destroy;
end;

function TBaseWebSocketClient.GetToken(Login_, Password_: String): string;
var IdHTTP: TIdHTTP; PostData: TIdMultipartFormDataStream; DestEncoding: IIdTextEncoding;
    sAnswer: TStrings;
    S: String;
    Props: TogsPropObject;
begin
 Result := '';
// инициализация переменных
 Login :=Login_; Password := Password_;
 IdHTTP:=TIdHTTP.Create(nil);
 PostData := TIdMultipartFormDataStream.Create;
 sAnswer := TStringList.Create;
// вызоы
 try
  PostData.AddFormField('login', Login, 'utf-8').ContentTransfer := '8bit';
  PostData.AddFormField('password', Password, 'utf-8').ContentTransfer := '8bit';
  sAnswer.Text := IdHTTP.Post('http://5.129.252.72:4001/auth/authenticate', PostData, IndyTextEncoding(encUTF8));
  Props := TogsPropObject.Create;
  Props.FromString(sAnswer.Text);
 // WriteIn([Props.ToString]);
   If Props.FindByNames(['validated'], S).asBoolean then begin
    fToken := Props.FindByNames(['data','token'], S).AsString;
    fClientID := Props.FindByNames(['data','client_id'], S).AsString;
   // fSessionID := Props.FindByNames(['data','session_id'], S).AsString;
    Result := fToken;
    WriteIn(['Token is validated']);
   end else begin
    fToken := '';
    WriteIn(['Not Found Validated Key', Props.FindByNames(['data','text'], S).AsString]);
   end;
  Props.Free;
 finally
  sAnswer.Free;
  PostData.Free;
  IdHttp.Free;
 end;
end;

function TBaseWebSocketClient.Connect: Boolean;
begin
 Result := False;
 if fToken = '' then begin
  raise Exception.Create('Connect: token is empty' );
 end else begin
  try
   FWS := TogswsClient.Create(urlAddr, Port, '/?token=' + Token);
   WSClient.OnReceive := wsReceive;
   WriteIn(['wsClient created']);
   WSClient.Start;
   WriteIn(['wsClient started']);
   Result := True;
  except
    raise;
  end;
 // проверка на успешнsй старт
 //
 end;
end;

procedure TBaseWebSocketClient.Disconnect;
begin
 If Assigned(WSClient) then
  WSClient.Stop;
end;

function TBaseWebSocketClient.GetAthorized: Boolean;
begin
 Result := Token <> '';
end;

function TBaseWebSocketClient.GetConnected: Boolean;
begin
 Result := fConnected;// and WSClient.Connected;
end;

{const
  MSGID_Standart = 0;
  MSGID_Connect = 1;
  MSGID_SessionCreate = 2;
}

procedure TBaseWebSocketClient.wsReceive(const aData: String);
var propValue: TogsPropValue;
    nfStr: String;
    uxTime: Int64;
begin
 WriteIn(['Receive', #13#10, aData]);
 propValue := TogsPropObject.Create;
 try
  propValue.FromString(aData);
  If propValue.FindByNames(['connected'], nfStr).AsBoolean then
   CheckMessage(MSGID_Connect, propValue.FindByNames(['client'], nfStr)) else
  If propValue.FindByNames(['type'], nfStr).AsString = 'session_create' then
   CheckMessage(MSGID_CreateSession, propValue) else
  If propValue.FindByNames(['type'], nfStr).AsString = 'session_create' then begin
  // стандартная обработка события
   CheckMessage(MSGID_Standart, propValue.FindByNames(['data'], nfStr));
  end;
 finally
  propValue.Free;
 end;
end;

function TBaseWebSocketClient.SendMsg(MSGID: Integer; AMsgText: string): Boolean;
var propValue: TogsPropValue;
    Msg: TMsgItem;
    GUID_: TGUID;
begin
// формируем json
 propValue := TogsPropObject.Create;
// client
 With propValue.AddItem(TogsProperty.Create('client', TogsPropObject.Create)).PropValue do begin
  AddItem(TogsProperty.Create('token', Token));
  AddItem(TogsProperty.Create('client_id', ClientID));
  AddItem(TogsProperty.Create('session_id', SessionID));
 end;
//
 case MSGID of
  MSGID_CreateSession:begin
                   //  WriteIn([propValue.ToString]);
                     propValue.AddItem(TogsProperty.Create('type', 'session_create'));
                    //
                     With propValue.AddItem(TogsProperty.Create('data', TogsPropObject.Create)).PropValue do begin
                       SysUtils.CreateGUID(GUID_);
                       AddItem(TogsProperty.Create('message_id', SysUtils.GUIDToString(GUID_)));
                       AddItem(TogsProperty.Create('object', AMsgText));
                     end;
                    end;
  MSGID_Confirm:begin
                 propValue.AddItem(TogsProperty.Create('type', 'confirm'));
                 With propValue.AddItem(TogsProperty.Create('data', TogsPropObject.Create)).PropValue do begin
                  SysUtils.CreateGUID(GUID_);
                  AddItem(TogsProperty.Create('message_id', SysUtils.GUIDToString(GUID_)));
                 end;
                end;
 end;
 WriteIn([propValue.ToString]);
 Msg := TMsgItem.Create(GUID_, DateTimeToUnix(Time), AMsgText);
 HistoryList.Add(TMsgHistory.Create(Msg));
 WSClient.SendText(CharsetConversion(propValue.ToString, GetCurCP, UTF_8));
// WSClient.SendTextContinuation(CharsetConversion(propValue.ToString, GetCurCP, UTF_8));
 propValue.Free;
end;

{
const
  MSGID_Standart = 0;
  MSGID_Connect = 1;
  MSGID_SessionCreate = 2;
}

function TBaseWebSocketClient.CheckMessage(MSGID: Integer; propValue: TogsPropValue): Boolean;
var Msg: TMsgItem; nfStr: String;
    GUIDStr, MsgText: String;
    GUID: TGUID;
begin
 Msg := nil;
 case MSGID of
  MSGID_Connect:If propValue.FindByNames(['client_id'], nfStr) <> nilObject then begin
                 WriteIn(['MSGID_Connect']);
                 fClientID := propValue.FindByNames(['client_id'], nfStr).AsString;
                 fConnected := True;
                 Exit(True);
                end;
  MSGID_CreateSession:If propValue.FindByNames(['session','session_id'], nfStr) <> nilObject then  begin
                       WriteIn(['MSGID_CreateSession']);
                       fSessionID := propValue.FindByNames(['session', 'session_id'], nfStr).AsString;
                       GUIDStr := propValue.FindByNames(['data', 'message_id'], nfStr).AsString;
                       MsgText := propValue.FindByNames(['data', 'text_msg'], nfStr).AsString;
                       GUID := StringToGUID(GUIDStr);
                      // отсылаем ответ о получении
                       SendMsg(MSGID_Confirm, '');
                      //
                       Msg := TMsgItem.Create(GUID, DateTimeToUnix(Time), MsgText);
                      end;
 // MSGID_Standart:If propValue.FindByNames(['data'])
 end;
 WriteIn(['Receive.PrevRec', 'History.Count', HistoryList.Count, 'Container.Count', HistoryList.Container.Count]);
 If Msg <> nil then
  If HistoryList.AddReceive(Msg) = nil then
    Msg.Free;
 WriteIn(['Receive.NextRec', 'History.Count', HistoryList.Count, 'Container.Count', HistoryList.Container.Count]);
 Exit(True);
end;

end.


