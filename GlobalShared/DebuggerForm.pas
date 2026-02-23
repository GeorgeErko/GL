unit DebuggerForm;

{$mode Delphi}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 ComboEx, ButtonPanel, Menus, ComCtrls, lazUtf8,
 ogcWriter, syncobjs;

type

{ TReadInThread }

  TReadInThread = class(TThread)
   KeyPressed:boolean;
   procedure Execute; override;
   procedure KeyDown(Sender: TObject);
  end;

{ TDebugger }

 TDebugger = class(TForm)
  Button1: TButton;
  Button2: TButton;
  Button3: TButton;
  clr: TButton;
  Memo1: TMemo;
  PageControl: TPageControl;
  Panel1: TPanel;
  Panel2: TPanel;
  Panel3: TPanel;
  Panel4: TPanel;
  Splitter1: TSplitter;
  thr: TButton;
  thr1: TButton;
  Timer1: TTimer;
  procedure Button1Click(Sender: TObject);
  procedure Button2Click(Sender: TObject);
  procedure Button3Click(Sender: TObject);
  procedure clrClick(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure FormDestroy(Sender: TObject);
  procedure PageControlChange(Sender: TObject);
  procedure Panel2Click(Sender: TObject);
  procedure thr1Click(Sender: TObject);
  procedure thrClick(Sender: TObject);
  procedure Timer1Timer(Sender: TObject);
 private
  Procedure OnUpdateText(Sender: TObject);
 public
  Stopped: boolean;
  function wd: TWriterDesk;
  Procedure AddItem;
  Procedure DeleteItem;
  Procedure Stop;
  Procedure ShowStopForm(StopFrm: TCustomForm);
 end;

var
 Debugger: TDebugger;
 CriticalSection: TCriticalSection;
 ReadInThread: TReadInThread;

implementation uses StopForm;

{$R *.frm}

{ TRedInThread }

procedure TReadInThread.Execute;
begin
 CriticalSection.Enter;
 Debugger.thr.OnClick := KeyDown;
 Debugger.Stop;
 Writein(['StoppedProcess.....'], Debugger.wd);
 While not KeyPressed do begin
  Writein([Random(100000)], Debugger.wd);
  sleep(100000);
 end;
 CriticalSection.Leave;
end;

procedure TReadInThread.KeyDown(Sender: TObject);
begin
 KeyPressed := True;
 Debugger.Stopped := False;
 WriteIn(['StertProcess....']);
end;

{ TDebugger }

procedure TDebugger.Stop;
begin
 Stopped := True;
 While Stopped do ;
end;

procedure TDebugger.ShowStopForm(StopFrm: TCustomForm);
var P1,P2:TPoint;
begin
 With Panel3.ClientRect do begin
  P1 := ClientToScreen(Point(Left, Top));
  P2 := ClientToScreen(Point(Right, Bottom));
 end;
 StopFrm := TStopFrm.Create(Debugger);
 StopFrm.Left := P1.X ; StopFrm.Top := P1.Y + Panel3.Top;
// StopFrm.Width := Panel3.Width; StopFrm.Height := Panel3.Height;
 StopFrm.ShowModal;
end;

procedure TDebugger.FormCreate(Sender: TObject);
begin
 CriticalSection := TCriticalSection.Create;
 AddItem;
end;

procedure TDebugger.FormDestroy(Sender: TObject);
begin
 CriticalSection.Free;
end;

function TDebugger.wd: TWriterDesk;
begin
 Result := wdCollection[wdCollection.Active];
 Result.OnUpdateText := OnUpdateText;
end;

procedure TDebugger.OnUpdateText(Sender: TObject);
var Lines: TStrings;
begin
 If PageControl.PageCount = 0 then exit;
 Lines := TMemo(PageControl.ActivePage.Controls[0]).Lines;
 If TWriterDesk(Sender).outPgr then
  Lines[Lines.Count - 1] := (TWriterDesk(Sender).outString) else Lines.Add(TWriterDesk(Sender).outString);
end;

procedure TDebugger.AddItem;
var TS: TTabSheet; Memo: TMemo;
begin
 TS := PageControl.AddTabSheet;
 Memo := TMemo.Create(TS);
 Memo.Text := Fmt(['Name_',wdCollection.Count]);
 TS.InsertControl(Memo);
 Memo.Align := alClient;
 Memo.BorderSpacing.Around := Memo1.BorderSpacing.Around;
 Memo.BorderStyle := Memo1.BorderStyle;
 Memo.ScrollBars := ssVertical;
 OpenWriter('qwerty.txt', TStringList.Create, [wdRewriteFile]);
 Memo.Text := wd.outList.Text;
 Memo.WordWrap := False;
 TS.Caption := Fmt(['[',wdCollection.Count,'] ' + ExtractFileName(wd.outFile)]);
 PageControl.ActivePage := TS;
end;

procedure TDebugger.PageControlChange(Sender: TObject);
begin
 wdCollection.Active := PageControl.TabIndex;
end;

procedure TDebugger.Panel2Click(Sender: TObject);
begin

end;

procedure TDebugger.thr1Click(Sender: TObject);
var I:integer;
begin
 WriteIn([]);
 For I:=0 to 1000 do begin
 // WriteNl([I]); Sleep(1000);
  If I mod 10 = 0 then begin
    ReadInThread:=TReadInThread.Create(true);
    ReadInThread.FreeOnTerminate:=true;
    ReadInThread.Priority:=tpLower;
    thr.OnClick:=ReadInThread.KeyDown;
    ReadInThread.Resume;
  end;
 end;
end;

procedure TDebugger.thrClick(Sender: TObject);
begin

end;

procedure TDebugger.Timer1Timer(Sender: TObject);
begin
 WriteIn(['Timer',TimeToStr(now)]);
end;

procedure TDebugger.DeleteItem;
begin
 PageControl.ActivePage.Free;
 CloseWriter(wd);
 PageControl.ActivePage := PageControl.Pages[wdCollection.Active];
end;

procedure TDebugger.Button1Click(Sender: TObject);
var I: Integer;
begin
 AddItem;
end;

procedure TDebugger.Button2Click(Sender: TObject);
begin
 If PageControl.TabIndex = 0 then exit;
 DeleteItem;
 CloseWriter(wd);
end;

procedure TDebugger.Button3Click(Sender: TObject);
var i: integer;w: TWriterDesk;
begin
 WriteIn([Memo1.Text],wd);
 Memo1.Clear;;
end;

procedure TDebugger.clrClick(Sender: TObject);
begin
 wd.outList.Clear;
 TMemo(PageControl.ActivePage.Controls[0]).Clear;;
end;

end.

