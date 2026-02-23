unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, Menus,
 uToolWindow, uDockContainers, ogcRegistry, ogcBasic, Types;

type

  { TToolForm }

  TToolForm = class(TForm)
    MainMenu1: TMainMenu;
    miTool: TMenuItem;
    miToolCreate: TMenuItem;
    miToolDelete: TMenuItem;
    miSettings: TMenuItem;
    miSettingsLoad: TMenuItem;
    miSettingsSave: TMenuItem;
    pnlTop: TPanel;
    pnlBottom: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    StaticText1: TStaticText;
    procedure Edit1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure miSettingsLoadClick(Sender: TObject);
    procedure miSettingsSaveClick(Sender: TObject);
    procedure miToolCreateClick(Sender: TObject);
    procedure miToolDeleteClick(Sender: TObject);
  private
    FWindows: TFPList;
    FActiveWindow: TToolWindow;
    FContainers: TList;
    procedure ToolActivate(Sender: TObject);
    procedure SetActiveWindow(W: TToolWindow);
    procedure ApplyToolPlacementFromReg(W: TToolWindow; Reg: TogsVarRegistry);
    function FindToolWindowByName(const AName: String): TToolWindow;
    function CreateToolWindowFromReg(Reg: TogsVarRegistry; const AName: String): TToolWindow;
    function CreateToolWindow(const ACaption: string; ALeft, ATop, ABtnWidth, ABtnHeight: Integer): TToolWindow;
    procedure DeleteToolWindow(W: TToolWindow);
  public
  end;

var ToolForm: TToolForm;

implementation

{$R *.frm}

function TToolForm.CreateToolWindow(const ACaption: string; ALeft, ATop, ABtnWidth,
  ABtnHeight: Integer): TToolWindow;
begin
  Result := TToolWindow.Create(Self);
  Result.avlContainers := FContainers;
  Result.BtnWidth := ABtnWidth;
  Result.BtnHeight := ABtnHeight;
  Result.pnlHeader.Caption := ACaption;
  Result.OnToolActivate := @ToolActivate;

  Result.SetBounds(ALeft, ATop, Result.GetUndockedPxWidth, Result.GetUndockedPxHeight);

  Result.Visible := True;
  FWindows.Add(Result);
  SetActiveWindow(Result);
end;

procedure TToolForm.DeleteToolWindow(W: TToolWindow);
var
  I: Integer;
begin
  if W = nil then Exit;
  if FWindows <> nil then begin
    I := FWindows.IndexOf(W);
    if I >= 0 then
      FWindows.Delete(I);
  end;
  if FActiveWindow = W then
   SetActiveWindow(nil);
  W.Free;
end;

procedure TToolForm.FormCreate(Sender: TObject);
begin
 FWindows := TFPList.Create;
 SetActiveWindow(nil);
 FContainers := TList.Create;
 FContainers.Add(pnlTop); FContainers.Add(pnlBottom);
 FContainers.Add(pnlLeft); FContainers.Add(pnlRight);
end;

procedure TToolForm.FormDestroy(Sender: TObject);
begin
 FreeAndNil(FWindows);
 FreeAndNil(FContainers);
end;

procedure TToolForm.ToolActivate(Sender: TObject);
begin
 if Sender is TToolWindow then
  SetActiveWindow(TToolWindow(Sender));
end;

procedure TToolForm.SetActiveWindow(W: TToolWindow);
var S: String;
begin
 FActiveWindow := W;
 if (FActiveWindow <> nil) and (FActiveWindow.pnlHeader <> nil) then
  S := FActiveWindow.pnlHeader.Caption
 else if FActiveWindow <> nil then
  S := FActiveWindow.Name
 else
  S := '';
 StaticText1.Caption := ' Выделено: ' + S;
end;

procedure TToolForm.ApplyToolPlacementFromReg(W: TToolWindow; Reg: TogsVarRegistry);
var
 Pfx: AnsiString;
 Docked1: Boolean;
 HostName: String;
 Host: TWinControl;
 RowKey: Integer;
 XPos: Integer;
 ColKey: Integer;
 YPos: Integer;
 BtnW, BtnH: Integer;
 C: TDockContainerBase;
 P0: TPoint;
 HR: TRect;
 FormW, FormH: Integer;
 FormL, FormT: Integer;
begin
 if (W = nil) or (Reg = nil) then Exit;
 Pfx := 'ToolWins\' + AnsiString(W.Name) + '\';
 Docked1 := Reg.GetBool(Pfx + 'Docked', False);
 HostName := String(Reg.GetStr(Pfx + 'Host', ''));
 RowKey := Reg.GetInt(Pfx + 'DockRowKey', 0);
 XPos := Reg.GetInt(Pfx + 'DockX', 0);
 ColKey := Reg.GetInt(Pfx + 'DockColKey', 0);
 YPos := Reg.GetInt(Pfx + 'DockY', 0);
 BtnW := Reg.GetInt(Pfx + 'DockBtnW', 0);
 BtnH := Reg.GetInt(Pfx + 'DockBtnH', 0);
 FormL := Reg.GetInt(Pfx + 'Left', W.Left);
 FormT := Reg.GetInt(Pfx + 'Top', W.Top);
 FormW := Reg.GetInt(Pfx + 'Width', W.Width);
 FormH := Reg.GetInt(Pfx + 'Height', W.Height);

 Host := nil;
 if SameText(HostName, 'pnlTop') then
  Host := pnlTop
 else if SameText(HostName, 'pnlBottom') then
  Host := pnlBottom
 else if SameText(HostName, 'pnlLeft') then
  Host := pnlLeft
 else if SameText(HostName, 'pnlRight') then
  Host := pnlRight;

 if Docked1 and (Host <> nil) and ((Host.Align = alTop) or (Host.Align = alBottom)) then begin
  W.AddContainer(Host);
  C := AcquireDockContainer(Host);
  try
   if BtnW < 1 then BtnW := 12;
   if BtnH < 1 then BtnH := 1;
   C.SetCaptureTool(W.Name, BtnW, BtnH, W);
   P0 := Host.ClientToScreen(Point(0, 0));
   if C is THContainer then
    THContainer(C).ApplyDock(P0.X + XPos + 1, P0.Y + RowKey + 1);
   if (C is THContainer) and THContainer(C).GetDockedRectByName(W.Name, HR) then begin
    W.Docked := True;
    W.BorderStyle := bsNone;
    W.Parent := Host;
    W.RecreateToolHandle;
    W.SetBounds(HR.Left, HR.Top, HR.Right - HR.Left, HR.Bottom - HR.Top);
    if W.pnlHeader <> nil then
     W.pnlHeader.Visible := False;
    W.BringToFront;
   end;
  finally
   C.Release;
  end;
 end else if Docked1 and (Host <> nil) and ((Host.Align = alLeft) or (Host.Align = alRight)) then begin
  W.AddContainer(Host);
  C := AcquireDockContainer(Host);
  try
   if BtnW < 1 then BtnW := 1;
   if BtnH < 1 then BtnH := 12;
   C.SetCaptureTool(W.Name, BtnW, BtnH, W);
   P0 := Host.ClientToScreen(Point(0, 0));
   if C is TVContainer then
    TVContainer(C).ApplyDock(P0.X + ColKey + 1, P0.Y + YPos + 1);
   if (C is TVContainer) and TVContainer(C).GetDockedRectByName(W.Name, HR) then begin
    W.Docked := True;
    W.BorderStyle := bsNone;
    W.Parent := Host;
    W.RecreateToolHandle;
    W.SetBounds(HR.Left, HR.Top, HR.Right - HR.Left, HR.Bottom - HR.Top);
    if W.pnlHeader <> nil then
     W.pnlHeader.Visible := False;
    W.BringToFront;
   end;
  finally
   C.Release;
  end;
 end else begin
  W.Docked := False;
  W.Parent := nil;
  W.BorderStyle := bsNone;
  W.RecreateToolHandle;
  W.SetBounds(FormL, FormT, FormW, FormH);
  if W.pnlHeader <> nil then
   W.pnlHeader.Visible := True;
 end;
end;

function TToolForm.FindToolWindowByName(const AName: String): TToolWindow;
var I: Integer;
    W: TToolWindow;
begin
 Result := nil;
 if FWindows = nil then Exit;
 for I := 0 to FWindows.Count - 1 do begin
  W := TToolWindow(FWindows[I]);
  if (W <> nil) and (CompareText(W.Name, AName) = 0) then
   Exit(W);
 end;
end;

function TToolForm.CreateToolWindowFromReg(Reg: TogsVarRegistry; const AName: String): TToolWindow;
begin
 Result := TToolWindow.Create(Self);
 Result.avlContainers := FContainers;
 Result.Name := AName;
 Result.SyncDockName;
 Result.OnToolActivate := @ToolActivate;
 Result.Visible := True;
 FWindows.Add(Result);
end;

procedure TToolForm.Edit1Change(Sender: TObject);
begin

end;

procedure TToolForm.miToolCreateClick(Sender: TObject);
var
  N: Integer;
begin
  Sender := Sender;
  if FWindows <> nil then
    N := FWindows.Count
  else
    N := 0;
  CreateToolWindow('Tool' + IntToStr(N + 1), Left + 20 + N * 40, Top + 120 + N * 20, 4, 4);
end;

procedure TToolForm.miToolDeleteClick(Sender: TObject);
var
  W: TToolWindow;
  S: String;
begin
  Sender := Sender;
  W := FActiveWindow;
  if W = nil then begin
   ShowMessage('Выделите инструментальную панель для удаления');
   Exit;
  end;
  if (W <> nil) and (W.pnlHeader <> nil) then
   S := W.pnlHeader.Caption
  else
   S := W.Name;
  if MessageDlg('Удалить: ' + S + ' ?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
   Exit;
  DeleteToolWindow(W);
end;

procedure TToolForm.miSettingsLoadClick(Sender: TObject);
var
  Reg: TogsVarRegistry;
  St: TogsStream;
  I: Integer;
  W: TToolWindow;
  RegFile: String;
  Names: TStringList;
  N: String;
begin
  Sender := Sender;
  RegFile := ExtractFilePath(Application.ExeName) + 'theGrapher.reg';
  Reg := TogsVarRegistry.Create;
  try
    if FileExists(RegFile) then
    begin
      St := TogsStream.CreateFileStream(RegFile, fmOpenRead or fmShareDenyWrite, nil);
      try
        if St.Size > 0 then
          Reg.LoadFromStream(St);
      finally
        St.Free;
      end;
    end;
    if FWindows = nil then
     FWindows := TFPList.Create;
    Names := TStringList.Create;
    try
     Reg.EnumSubKeys('ToolWins\', Names);
     for I := 0 to Names.Count - 1 do begin
      N := Names[I];
      W := FindToolWindowByName(N);
      if W <> nil then
       begin
        W.LoadSettings(Reg);
        ApplyToolPlacementFromReg(W, Reg);
       end
      else
       begin
        W := CreateToolWindowFromReg(Reg, N);
        W.LoadSettings(Reg);
        ApplyToolPlacementFromReg(W, Reg);
       end;
     end;
    finally
     Names.Free;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TToolForm.miSettingsSaveClick(Sender: TObject);
var Reg: TogsVarRegistry;
    St: TogsStream;
    I: Integer;
    W: TToolWindow;
    RegFile: String;
begin
 Sender := Sender;
 RegFile := ExtractFilePath(Application.ExeName) + 'theGrapher.reg';
 Reg := TogsVarRegistry.Create;
 try
  if FileExists(RegFile) then begin
   St := TogsStream.CreateFileStream(RegFile, fmOpenRead or fmShareDenyWrite, nil);
   try
    if St.Size > 0 then
     Reg.LoadFromStream(St);
   finally
    St.Free;
   end;
  end;
 //
  if FWindows <> nil then
   for I := 0 to FWindows.Count - 1 do begin
    W := TToolWindow(FWindows[I]);
    if W <> nil then
     W.SaveSettings(Reg);
   end;
 //
  St := TogsStream.CreateFileStream(RegFile, fmCreate or fmShareDenyWrite, nil);
  try
   Reg.SaveToStream(St);
  finally
   St.Free;
  end;
 finally
  Reg.Free;
 end;
end;

end.
