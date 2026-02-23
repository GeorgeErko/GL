unit WSClient;

{$mode Delphi}

interface

uses Classes, SysUtils, ExtCtrls, vswebsocket, ogcProperties;

type
 TReadProc  = procedure(const aData: String) of object;
 TWriteProc = procedure(const aData: String) of object;

{ TogswsClient }

 TogswsClient = class(TswsWebSocketClientConnection)
 private
  function GetConncted: Boolean;
 protected
  fFramedText: string;    //+
  fFramedStream: TMemoryStream;   //+
  fPing: string; //+
  fPong: string; //+
  fConnected: Boolean;
  fOnReceive: TReadProc;
 //
  procedure ProcessText(aFinal, aRes1, aRes2, aRes3: boolean; aData: string); override;      //+
  procedure ProcessTextContinuation(aFinal, aRes1, aRes2, aRes3: boolean; aData: string); override;   //+
 //
  procedure ProcessStream(aFinal, aRes1, aRes2, aRes3: boolean; aData: TMemoryStream); override;
  procedure ProcessStreamContinuation(aFinal, aRes1, aRes2, aRes3: boolean; aData: TMemoryStream); override;
 //
  procedure ProcessPing(aData: string); override; //+
  procedure ProcessPong(aData: string); override;  //+
 //
  procedure SyncTextFrame;   //+
  procedure SyncBinFrame;
 //
  procedure SyncPing; virtual;   //+
  procedure SyncPong; virtual;  //+
 //
  procedure wscRead(aSender: TswsWebSockeCustomConnection; aFinal, aRes1, aRes2,
   aRes3: boolean; aCode: integer; aData: TMemoryStream);
  procedure wscWrite(aSender: TswsWebSockeCustomConnection; aFinal, aRes1, aRes2,
   aRes3: boolean; aCode: integer; aData: TMemoryStream);
  procedure wscOpen(aSender: TswsWebSockeCustomConnection);
  procedure wscClose(aSender: TswsWebSockeCustomConnection; aCloseCode: integer;
                   aCloseReason: string; aClosedByPeer: boolean);
 public
  constructor Create(aHost, aPort, aResourceName: string; aOrigin: string = '-'; aProtocol: string = '-'; aExtension: string = '-'; aCookie: string = '-'; aVersion: integer = 8); override; //+
  destructor Destroy; override;   //+
 //
  property ReadFinal: boolean read fReadFinal;   //+
  property ReadRes1: boolean read fReadRes1;     //+
  property ReadRes2: boolean read fReadRes2;    //+
  property ReadRes3: boolean read fReadRes3;     //+
  property ReadCode: integer read fReadCode;    //+
  property ReadStream: TMemoryStream read fReadStream;  //+
 //
  property WriteFinal: boolean read fWriteFinal; //+
  property WriteRes1: boolean read fWriteRes1; //+
  property WriteRes2: boolean read fWriteRes2; //+
  property WriteRes3: boolean read fWriteRes3;  //+
  property WriteCode: integer read fWriteCode;    //+
  property WriteStream: TMemoryStream read fWriteStream;  //+
 //
  property Connected: Boolean read GetConncted;
 //
  property OnReceive : TReadProc read fOnReceive write fOnReceive;
 // property OnWrite: TWriteProc read fOnWrite write fOnWrite;
 end;

 { TMonitoringWsClient }

 TMonitoringWsClient = class(TogswsClient)
 private
  FTimer: TTimer;
  procedure TimerTimer(Sender: TObject);
  procedure SetTimerInterval(const Value: Integer);
 protected
  // ping-pong
  FLastPingSent: TDateTime;
  FLastPongRecv: TDateTime;
  FPingIntervalSec: Integer;
  FPongTimeoutSec: Integer;
  procedure SyncPing; override;
  procedure SyncPong; override;
 public
  constructor Create(aHost, aPort, aResourceName: string; aOrigin: string = '-'; aProtocol: string = '-'; aExtension: string = '-'; aCookie: string = '-'; aVersion: integer = 8); override;
  destructor Destroy; override;
  procedure StartTimer;
  procedure StopTimer;
  procedure CheckConnection;
  property TimerIntervalSec: Integer read FPingIntervalSec write SetTimerInterval;
 end;

implementation uses StrUtils, synachar, synautil,
                     Math, TypInfo, DateUtils,
                      ogcWriter;

{ TogswsClient }

constructor TogswsClient.Create(aHost, aPort, aResourceName: string;
    aOrigin: string = '-'; aProtocol: string = '-'; aExtension: string = '-';
    aCookie: string = '-'; aVersion: integer = 8);
begin
 inherited;
 fFramedText := '';
 fFramedStream := TMemoryStream.Create;
 OnRead := wscRead;
 OnWrite:= wscWrite;
 OnClose:= wscClose;
 OnOpen := wscOpen;
// заменить на параметр
 SSL := False;
end;

destructor TogswsClient.Destroy;
begin
 fConnected := False;
 fFramedStream.free;
 inherited;
end;

function TogswsClient.GetConncted: Boolean;
begin
 Result := fConnected;
end;

procedure TogswsClient.ProcessText(aFinal, aRes1, aRes2,
  aRes3: boolean; aData: string);
begin
 fFramedText := aData;
end;

procedure TogswsClient.ProcessTextContinuation(aFinal, aRes1,
  aRes2, aRes3: boolean; aData: string);
begin
 fFramedText := fFramedText + aData;
 if (aFinal) then
 begin
   Synchronize(SyncTextFrame);
 end;
end;

procedure TogswsClient.ProcessStream(aFinal, aRes1, aRes2,
  aRes3: boolean; aData: TMemoryStream);
begin
 fFramedStream.Size := 0;
 fFramedStream.CopyFrom(aData, aData.Size);
 WriteIn(['ProcessStream', Index, ord(aFinal), ord(aRes1), ord(aRes2), ord(aRes3), aData.Size]);
 if (aFinal) then
 begin
   Synchronize(SyncBinFrame);
 end;
end;

procedure TogswsClient.ProcessStreamContinuation(aFinal,
  aRes1, aRes2, aRes3: boolean; aData: TMemoryStream);
begin
 fFramedStream.CopyFrom(aData, aData.Size);
 WriteIn(['ProcessStreamContinuation', Index, ord(aFinal), ord(aRes1), ord(aRes2), ord(aRes3), aData.Size]);
 if (aFinal) then
 begin
   Synchronize(SyncBinFrame);
 end;
end;

procedure TogswsClient.ProcessPing(aData: string);
begin
 Pong(aData);
 fPing := aData;
 Synchronize(SyncPing);
end;

procedure TogswsClient.ProcessPong(aData: string);
begin
 fPong := aData;
 Synchronize(SyncPong);
end;

procedure TogswsClient.SyncTextFrame;
begin
  WriteIn(['SyncText',CharsetConversion(fFramedText, UTF_8, GetCurCP)]);
end;

procedure TogswsClient.SyncBinFrame;
//var png : TPortableNetworkGraphic;
begin
  WriteIn(['SyncBin', fFramedStream.Size]);
//  png := TPortableNetworkGraphic.Create;
  fFramedStream.Position := 0;
//  png.LoadFromStream(fFramedStream);
//  png.Free;
end;

procedure TogswsClient.SyncPing;
begin
 WriteIn(['SyncPing', fPing]);
 fConnected := True;
end;

procedure TogswsClient.SyncPong;
begin
 WriteIn(['SyncPong', fPong]);
end;

procedure TogswsClient.wscRead(aSender: TswsWebSockeCustomConnection; aFinal, aRes1, aRes2, aRes3: boolean; aCode: integer; aData: TMemoryStream);
var s, text: string;
    c: TogswsClient;
begin
  c := TogswsClient(aSender);
  WriteIn(['--OnRead',  aSender.Index, ord(aFinal), ord(aRes1), ord(aRes2), ord(aRes3), aCode, aData.Size]);
  s := ReadStrFromStream(c.ReadStream, min(c.ReadStream.size, 10 * 1024));
  if (c.ReadCode = wsCodeText) then begin
  // WriteIn(['CodeText =',CharsetConversion(s, UTF_8, GetCurCP)]);
   if Assigned(OnReceive) then
    OnReceive(CharsetConversion(s, UTF_8, GetCurCP));
  end else begin
  // WriteIn(['String =', S]);
   if Assigned(OnReceive) then
    OnReceive(S);
  end;
  WriteIn(['--']);
end;

procedure TogswsClient.wscWrite(aSender: TswsWebSockeCustomConnection; aFinal, aRes1, aRes2, aRes3: boolean; aCode: integer; aData: TMemoryStream);
var s, text: string;
    c: TogswsClient;
begin
  c := TogswsClient(aSender);
  WriteIn(['OnWrite', aSender.Index, ord(aFinal), ord(aRes1), ord(aRes2), ord(aRes3), aCode, aData.Size]);
  s := ReadStrFromStream(c.WriteStream, min(c.WriteStream.size, 10 * 1024));
  if (c.ReadCode = wsCodeText) then
   // WriteIn(['CodeText =',CharsetConversion(s, UTF_8, GetCurCP)])
  else begin
   //WriteIn(['String =', S]);
  end;
  WriteIn(['--']);
end;

procedure TogswsClient.wscClose(aSender: TswsWebSockeCustomConnection;
  aCloseCode: integer; aCloseReason: string; aClosedByPeer: boolean);
begin
 WriteIn(['OnClose', aSender.Index, aCloseCode, aCloseReason, IfThen(aClosedByPeer, 'closed by peer', 'closed by me')]);
end;

procedure TogswsClient.wscOpen(aSender: TswsWebSockeCustomConnection);
begin
 WriteIn(['OnOpen', aSender.Index]);

end;

{ TMonitoringWsClient }

constructor TMonitoringWsClient.Create(aHost, aPort, aResourceName: string;
    aOrigin: string = '-'; aProtocol: string = '-'; aExtension: string = '-';
    aCookie: string = '-'; aVersion: integer = 8);
begin
  inherited Create(aHost, aPort, aResourceName, aOrigin, aProtocol, aExtension, aCookie, aVersion);
 //
  FPingIntervalSec := 10;
  FPongTimeoutSec  := 10;
  FLastPongRecv    := Now;
 //
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTimer;
  SetTimerInterval(FPingIntervalSec);
end;

procedure TMonitoringWsClient.SetTimerInterval(const Value: Integer);
begin
  FPingIntervalSec := Max(1, Value);
  if Assigned(FTimer) then
    FTimer.Interval := FPingIntervalSec * 1000;
end;

destructor TMonitoringWsClient.Destroy;
begin
  StopTimer;
  FreeAndNil(FTimer);
  inherited Destroy;
end;

procedure TMonitoringWsClient.StartTimer;
begin
  if Assigned(FTimer) then
    FTimer.Enabled := True;
end;

procedure TMonitoringWsClient.StopTimer;
begin
  if Assigned(FTimer) then
    FTimer.Enabled := False;
end;

procedure TMonitoringWsClient.TimerTimer(Sender: TObject);
begin
  if not Connected then
    Exit;
  Ping('hb|' + IntToStr(GetTickCount64));
  FLastPingSent := Now;
  CheckConnection;
end;

procedure TMonitoringWsClient.SyncPing;
begin
  inherited;
  FLastPongRecv := Now;
end;

procedure TMonitoringWsClient.SyncPong;
begin
  inherited;
  FLastPongRecv := Now;
end;

procedure TMonitoringWsClient.CheckConnection;
begin
  if SecondsBetween(Now, FLastPongRecv) > FPongTimeoutSec then
    Close(1001, 'Timer timeout');
end;

initialization
end.

