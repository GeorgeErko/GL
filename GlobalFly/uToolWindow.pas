unit uToolWindow;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
 Buttons, StdCtrls, Menus, Types, LCLType, LCLIntf,
 uDockContainers, uDockRepack2D, uToolSettingsForm, ogcRegistry, ogcBasic, ogcProcs,
 BGRAResizeSpeedButton,
 uFlyControlCreateForm, uChildSpeedButtonForm, uChildComboBoxForm,
 uChildLabelForm, uChildEditForm;

const
  fmBtnSize  = 24;
  fmBtnSpace = 0;
  fmBorderIndent = 4;
  fmLeftIndent = 6;
  fmTopIndent = fmBorderIndent;
  fmResizeGrip = 2;


type
 { TDockDragFrame }
  TDockDragFrame = class(TForm)
  public
   CapturedContainer: TDockContainerBase;
   PlacementRect: TRect;
   procedure FramePaint(Sender: TObject);
  protected
   procedure Paint; override;
   procedure CreateParams(var Params: TCreateParams); override;
  end;

 { TToolWindow }
 TToolWindow = class(TForm)
  pnlResizeTop: TPanel;
  pnlResizeBottom: TPanel;
  pnlResizeLeft: TPanel;
  pnlResizeRight: TPanel;
  pnlHeader: TPanel;
  pnkClient: TPanel;
  sbSettings: TSpeedButton;
  procedure pnkClientClick(Sender: TObject);
  procedure pnkClientResize(Sender: TObject);
  procedure pnlHeaderClick(Sender: TObject);
  procedure sbSettingsClick(Sender: TObject);
 private
  FContainers: TFPList;
  FBtnWidth: Integer;
  FBtnHeight: Integer;
  FInitToolBtnWidth: Integer;
  FInitToolBtnHeight: Integer;
  FInitHBtnWidth: Integer;
  FInitHBtnHeight: Integer;
  FInitVBtnWidth: Integer;
  FInitVBtnHeight: Integer;
  FDocked: Boolean;
  FDragging: Boolean;
  FDragOffset: TPoint;
  FMoveFrame: TDockDragFrame;
  FPlaceFrame: TDockDragFrame;
  FCapturedContainer: TDockContainerBase;
  FDockSection: TflySection;
  FDragSource: TWinControl;
  FOnToolActivate: TNotifyEvent;
  FResizing: Boolean;
  FResizeMask: Byte;
  FResizeStartP: TPoint;
  FResizeStartR: TRect;
  FPopupMenu: TPopupMenu;
  miFlyAdd: TMenuItem;
  miFlyIns: TMenuItem;
  miFlyEdit: TMenuItem;
  miFlyContent: TMenuItem;
  miFlyContentSB: TMenuItem;
  miFlyContentCB: TMenuItem;
  miFlyContentLbl: TMenuItem;
  miFlyContentEdt: TMenuItem;
  miFlyDel: TMenuItem;
  FPopupCell: TPoint;
  FSelectedFly: TflyControl;
  procedure RebuildFlyControlsUI;
  procedure ReplaceControls;
  function FlyControlIndexAtCell(const Cell: TPoint): Integer;
  procedure InitNewFlyControl(FC: TflyControl);
  function FillNewFlyControlFromDialog(FC: TflyControl): Boolean;
  function BaseOriginPx: TPoint;
  function FindFirstFreeCell(AW, AH: Integer; out Cell: TPoint): Boolean;
  procedure AsyncRebuild(Data: PtrInt);
  procedure FlyPopupPopup(Sender: TObject);
  procedure FlyAddClick(Sender: TObject);
  procedure FlyInsClick(Sender: TObject);
  procedure FlyEditClick(Sender: TObject);
  procedure FlyContentSBClick(Sender: TObject);
  procedure FlyContentCBClick(Sender: TObject);
  procedure FlyContentLblClick(Sender: TObject);
  procedure FlyContentEdtClick(Sender: TObject);
  procedure FlyDelClick(Sender: TObject);
  procedure FlyControlMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure LayoutPanelContent(P: TPanel);
  function NextFlyControlName: String;
  procedure DoToolActivate;
  procedure HeaderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure HeaderMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  procedure HeaderMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure ResizeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure ResizeMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  procedure ResizeMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure UpdateHeaderVisibility;
  procedure EnsureMoveFrame;
  procedure EnsurePlaceFrame;
  procedure HideDragFrames;
  procedure UpdateMoveFrame(ALeft, ATop: Integer);
  procedure UpdatePlaceFrame(AContainer: TDockContainerBase; const PlacementR: TRect);
  function FloatPxWidth: Integer;
  function FloatPxHeight: Integer;
  function UndockedFloatPxWidth: Integer;
  function UndockedFloatPxHeight: Integer;
 protected
  procedure CreateParams(var Params: TCreateParams); override;
  function FindDockedSection: TflySection;
  function DockBtnWidth: Integer;
  function DockBtnHeight: Integer;
 public
  avlContainers: TList; // список панелей-контейнеров из Parent
  constructor Create(TheOwner: TComponent); override;
  destructor Destroy; override;
  procedure AddContainer(AHost: TWinControl); overload;
  procedure AddContainer(AHost: TWinControl; ABtnWidth, ABtnHeight: Integer); overload;
  procedure LoadSettings(Reg: TogsVarRegistry);
  procedure SaveSettings(Reg: TogsVarRegistry);
  procedure SyncDockName;
  procedure RecreateToolHandle;
  function GetUndockedPxWidth: Integer;
  function GetUndockedPxHeight: Integer;
  property OnToolActivate: TNotifyEvent read FOnToolActivate write FOnToolActivate;
  property BtnWidth: Integer read FBtnWidth write FBtnWidth;
  property BtnHeight: Integer read FBtnHeight write FBtnHeight;
  property Docked: Boolean read FDocked write FDocked;
 end;

var
 ToolWindow2: TToolWindow;

implementation uses uBitHash;

{$R *.frm}

procedure TDockDragFrame.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW;
  Params.Style := (Params.Style or WS_POPUP) and not WS_CHILD;
  Params.WndParent := TForm(Owner).Handle;
end;

procedure TDockDragFrame.FramePaint(Sender: TObject);
var
  HC: THContainer;
  HostP: TPoint;
  S: Integer;
  Sec: TflySection;
  R: TRect;
  IgnoreCtrl: TWinControl;
begin
  Canvas.Pen.Mode := pmCopy;
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psDot;
  Canvas.Pen.Color := clLime;

  if (CapturedContainer <> nil) and (CapturedContainer is THContainer) and (CapturedContainer.Host <> nil) then begin
   HC := THContainer(CapturedContainer);
   IgnoreCtrl := CapturedContainer.CaptureControl;
   HostP := CapturedContainer.Host.ClientToScreen(Point(0, 0));
   HostP.X := HostP.X - Left;
   HostP.Y := HostP.Y - Top;

   if HC.flySections <> nil then
     for S := 0 to HC.flySections.Count - 1 do begin
       Sec := TflySection(HC.flySections[S]);
       if Sec = nil then Continue;
       if (IgnoreCtrl <> nil) and (Sec.Control = IgnoreCtrl) then Continue;
       R := Rect(HostP.X + Sec.X, HostP.Y + Sec.Y,
                 HostP.X + Sec.X + Sec.Width, HostP.Y + Sec.Y + Sec.Height);
       Canvas.Rectangle(R);
     end;
  end else if CapturedContainer = nil then begin
    Canvas.Rectangle(0, 0, Width, Height);
  end;

  if (PlacementRect.Right > PlacementRect.Left) and (PlacementRect.Bottom > PlacementRect.Top) then begin
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Color := clRed;
    R := PlacementRect;
    OffsetRect(R, -Left, -Top);
    Canvas.Rectangle(R);
  end;
end;

procedure TToolWindow.RebuildFlyControlsUI;
var
 I: Integer;
 FC: TflyControl;
 P: TPanel;
 SB: TSpeedButton;
  C: TControl;
 W, H: Integer;
 BaseP: TPoint;
 MaxCols: Integer;
 Xc, Yc: Integer;
 RowH: Integer;
begin
  Writeln('RUI=1');
 if pnkClient = nil then Exit;

 BaseP := BaseOriginPx;

 MaxCols := (pnkClient.ClientWidth - BaseP.X) div fmBtnSize;
 if MaxCols < 1 then
  MaxCols := 1;

 I := pnkClient.ControlCount - 1;
 while I >= 0 do begin
  C := pnkClient.Controls[I];
  if (C <> nil) and (C <> sbSettings) then
   C.Free;
  Dec(I);
 end;
 Writeln('RUI=2');

 if (FDockSection = nil) or (FDockSection.flyControls = nil) then Exit;

 Xc := 0;
 Yc := 0;
 RowH := 1;

 for I := 0 to FDockSection.flyControls.Count - 1 do begin
  FC := TflyControl(FDockSection.flyControls[I]);
  if FC = nil then Continue;

  W := FC.BtnWidth;
  H := FC.BtnHeight;
  if W < 1 then W := 1;
  if H < 1 then H := 1;

  if Xc + W > MaxCols then begin
   Xc := 0;
   Inc(Yc, RowH);
   RowH := 1;
  end;
  FC.X := Xc;
  FC.Y := Yc;
  Inc(Xc, W);
  if H > RowH then
   RowH := H;

  if FC.Kind = fckSpeedButton then begin
  Writeln('RUI=11');
   SB := TSpeedButton.Create(Self);
   SB.Parent := pnkClient;
   SB.Caption := FC.Caption;
   SB.Hint := FC.Hint;
   SB.ShowHint := FC.Hint <> '';
   if BitHashCollect <> nil then
    FC.BitHashItem := BitHashCollect.FindItemByHash(FC.GlyphHash)
   else
    FC.BitHashItem := nil;
   if (FC.BitHashItem <> nil) and (FC.BitHashItem.Bitmap <> nil) then
    SB.Glyph.Assign(FC.BitHashItem.Bitmap)
   else if FC.GlyphData <> '' then
    try
     LoadBitmapFromHex(SB.Glyph, AnsiString(FC.GlyphData));
    except
    end;
   Writeln('RUI=12');
   SB.SetBounds(BaseP.X + FC.X * fmBtnSize, BaseP.Y + FC.Y * fmBtnSize, W * fmBtnSize, H * fmBtnSize);
   SB.OnClick := @pnkClientClick;
   SB.OnMouseDown := @FlyControlMouseDown;
   SB.PopupMenu := FPopupMenu;
   SB.Tag := PtrInt(FC);
   FC.Control := SB;
   Writeln('RUI=13');
  end else begin
    Writeln('RUI=21');
   P := TPanel.Create(Self);
   P.Parent := pnkClient;
   P.Caption := FC.Caption;
   P.Alignment := taLeftJustify;
   P.Hint := FC.Hint;
   P.ShowHint := FC.Hint <> '';
   P.SetBounds(BaseP.X + FC.X * fmBtnSize, BaseP.Y + FC.Y * fmBtnSize, W * fmBtnSize, H * fmBtnSize);
   P.OnClick := @pnkClientClick;
   P.OnMouseDown := @FlyControlMouseDown;
   P.PopupMenu := FPopupMenu;
   P.Tag := PtrInt(FC);
   FC.Control := P;
   Writeln('RUI=22');
  end;
 end;
 Writeln('RUI2=1');
end;

procedure TToolWindow.pnkClientResize(Sender: TObject);
begin
 Sender := Sender;
 RebuildFlyControlsUI;
end;

procedure TToolWindow.ReplaceControls;
var
 I, J: Integer;
 X, Y: Integer;
 FC, PC: TflyControl;
 W, H: Integer;
 PW, PH: Integer;
 Fits: Boolean;
 FoundPos: Boolean;
begin
 if (FDockSection = nil) or (FDockSection.flyControls = nil) then Exit;
 if FBtnWidth < 1 then Exit;
 if FBtnHeight < 1 then Exit;

 for I := 0 to FDockSection.flyControls.Count - 1 do begin
  FC := TflyControl(FDockSection.flyControls[I]);
  if FC = nil then Continue;
  W := FC.BtnWidth;
  H := FC.BtnHeight;
  if W < 1 then W := 1;
  if H < 1 then H := 1;
  if W > FBtnWidth then W := FBtnWidth;
  if H > FBtnHeight then H := FBtnHeight;

  FoundPos := False;
  for Y := 0 to FBtnHeight - H do begin
   for X := 0 to FBtnWidth - W do begin
    Fits := True;
    for J := 0 to I - 1 do begin
     PC := TflyControl(FDockSection.flyControls[J]);
     if PC = nil then Continue;
     PW := PC.BtnWidth;
     PH := PC.BtnHeight;
     if PW < 1 then PW := 1;
     if PH < 1 then PH := 1;
     if (X < PC.X + PW) and (X + W > PC.X) and
        (Y < PC.Y + PH) and (Y + H > PC.Y) then begin
      Fits := False;
      Break;
     end;
    end;
    if Fits then begin
     FC.X := X;
     FC.Y := Y;
     FoundPos := True;
     Break;
    end;
   end;
   if FoundPos then
    Break;
  end;
 end;
end;

function TToolWindow.FlyControlIndexAtCell(const Cell: TPoint): Integer;
var
 I: Integer;
 FC: TflyControl;
 W, H: Integer;
begin
 Result := -1;
 if (FDockSection = nil) or (FDockSection.flyControls = nil) then Exit;
 for I := 0 to FDockSection.flyControls.Count - 1 do begin
  FC := TflyControl(FDockSection.flyControls[I]);
  if FC = nil then Continue;
  W := FC.BtnWidth;
  H := FC.BtnHeight;
  if W < 1 then W := 1;
  if H < 1 then H := 1;
  if (Cell.X >= FC.X) and (Cell.X < FC.X + W) and
     (Cell.Y >= FC.Y) and (Cell.Y < FC.Y + H) then
   Exit(I);
 end;
end;

procedure TToolWindow.InitNewFlyControl(FC: TflyControl);
begin
 if FC = nil then Exit;
 FC.Name := NextFlyControlName;
 FC.Caption := '';
 FC.Hint := '';
 FC.BitHashItem := nil;
 FC.Width := 0;
 FC.Height := 0;
 FC.BtnWidth := 1;
 FC.BtnHeight := 1;
 FC.Kind := fckPanel;
 FC.Control := nil;
end;

function TToolWindow.FillNewFlyControlFromDialog(FC: TflyControl): Boolean;
var
 Nm: String;
 Cap: String;
 Hnt: String;
 W, H: Integer;
 K: Integer;
 Dlg: TFlyControlCreateForm;
 GD: AnsiString;
 GH: String;
begin
 Result := False;
 if FC = nil then Exit;

 Nm := FC.Name;
 Cap := FC.Caption;
 Hnt := FC.Hint;
 W := FC.BtnWidth;
 H := FC.BtnHeight;
 if FC.Kind = fckSpeedButton then
  K := 0
 else
  K := 1;

 GD := FC.GlyphData;
 GH := FC.GlyphHash;

 Dlg := TFlyControlCreateForm.Create(Self);
 try
  if not Dlg.Execute(Nm, Cap, Hnt, W, H, K, GD, GH) then
   Exit;
 finally
  Dlg.Free;
 end;

 FC.Name := Nm;
 FC.Caption := Cap;
 FC.Hint := Hnt;
 FC.BtnWidth := W;
 FC.BtnHeight := H;
 if K = 0 then
  FC.Kind := fckSpeedButton
 else
  FC.Kind := fckPanel;
 FC.GlyphData := GD;
 FC.GlyphHash := GH;
 if (FC.Kind = fckSpeedButton) and (BitHashCollect <> nil) then
  FC.BitHashItem := BitHashCollect.FindItemByHash(FC.GlyphHash)
 else
  FC.BitHashItem := nil;
 Result := True;
end;

function TToolWindow.BaseOriginPx: TPoint;
begin
 if not FDocked then
  Exit(Point(fmBorderIndent, fmBorderIndent));

 if (Parent <> nil) then begin
  case Parent.Align of
   alTop, alBottom:
    Exit(Point(fmLeftIndent, fmBorderIndent));
   alLeft, alRight:
    Exit(Point(fmBorderIndent, fmTopIndent));
  end;
 end;
 Result := Point(fmBorderIndent, fmBorderIndent);
end;

function TToolWindow.FindFirstFreeCell(AW, AH: Integer; out Cell: TPoint): Boolean;
var
 X, Y: Integer;
 I: Integer;
 FC: TflyControl;
 W, H: Integer;
 Fits: Boolean;
begin
 Result := False;
 Cell := Point(0, 0);
 if (FDockSection = nil) or (FDockSection.flyControls = nil) then Exit;

 if AW < 1 then AW := 1;
 if AH < 1 then AH := 1;
 if FBtnWidth < 1 then Exit;
 if FBtnHeight < 1 then Exit;
 if AW > FBtnWidth then Exit;
 if AH > FBtnHeight then Exit;

 for Y := 0 to FBtnHeight - AH do
  for X := 0 to FBtnWidth - AW do begin
   Fits := True;
   for I := 0 to FDockSection.flyControls.Count - 1 do begin
    FC := TflyControl(FDockSection.flyControls[I]);
    if FC = nil then Continue;
    W := FC.BtnWidth; H := FC.BtnHeight;
    if W < 1 then W := 1;
    if H < 1 then H := 1;
    if (X < FC.X + W) and (X + AW > FC.X) and
       (Y < FC.Y + H) and (Y + AH > FC.Y) then begin
     Fits := False;
     Break;
    end;
   end;
   if Fits then begin
    Cell := Point(X, Y);
    Exit(True);
   end;
  end;
end;

procedure TToolWindow.AsyncRebuild(Data: PtrInt);
begin
 Data := Data;
 RebuildFlyControlsUI;
end;

procedure TToolWindow.FlyPopupPopup(Sender: TObject);
begin
 Sender := Sender;
 if miFlyContent <> nil then
  miFlyContent.Visible := (FSelectedFly <> nil) and (FSelectedFly.Kind = fckPanel);
 if miFlyEdit <> nil then
  miFlyEdit.Enabled := FSelectedFly <> nil;
 if miFlyDel <> nil then
  miFlyDel.Enabled := FSelectedFly <> nil;
end;

procedure TToolWindow.FlyContentSBClick(Sender: TObject);
var
 P: TPanel;
 B: TSpeedButton;
 Dlg: TChildSpeedButtonForm;
 Cap: String;
 Hnt: String;
 BW: Integer;
begin
 Sender := Sender;
 if (FSelectedFly = nil) or (FSelectedFly.Kind <> fckPanel) then Exit;
 if (FSelectedFly.Control = nil) or not (FSelectedFly.Control is TPanel) then Exit;
 P := TPanel(FSelectedFly.Control);
 B := TSpeedButton.Create(Self);
 B.Parent := P;
 B.Caption := '';
 B.PopupMenu := FPopupMenu;
 B.OnMouseDown := @FlyControlMouseDown;
 B.Tag := PtrInt(FSelectedFly);
 Cap := '';
 Hnt := '';
 BW := 4;
 Dlg := TChildSpeedButtonForm.Create(Self);
 try
  if not Dlg.Execute(Cap, Hnt, BW) then begin
   B.Free;
   Exit;
  end;
 finally
  Dlg.Free;
 end;
 B.Caption := Cap;
 B.Hint := Hnt;
 B.ShowHint := Hnt <> '';
 B.Width := BW * fmBtnSize;
 B.Height := fmBtnSize;
 LayoutPanelContent(P);
end;

procedure TToolWindow.FlyContentCBClick(Sender: TObject);
var
 P: TPanel;
 Cb: TComboBox;
 Dlg: TChildComboBoxForm;
 ItemsStr: String;
 Hnt: String;
 BW: Integer;
begin
 Sender := Sender;
 if (FSelectedFly = nil) or (FSelectedFly.Kind <> fckPanel) then Exit;
 if (FSelectedFly.Control = nil) or not (FSelectedFly.Control is TPanel) then Exit;
 P := TPanel(FSelectedFly.Control);
 Cb := TComboBox.Create(Self);
 Cb.Parent := P;
 Cb.PopupMenu := FPopupMenu;
 Cb.OnMouseDown := @FlyControlMouseDown;
 Cb.Tag := PtrInt(FSelectedFly);

 ItemsStr := '';
 Hnt := '';
 BW := 6;
 Dlg := TChildComboBoxForm.Create(Self);
 try
  if not Dlg.Execute(ItemsStr, Hnt, BW) then begin
   Cb.Free;
   Exit;
  end;
 finally
  Dlg.Free;
 end;

 Cb.Items.Delimiter := ';';
 Cb.Items.StrictDelimiter := True;
 Cb.Items.DelimitedText := ItemsStr;
 Cb.Hint := Hnt;
 Cb.ShowHint := Hnt <> '';
 Cb.Width := BW * fmBtnSize;
 Cb.Height := fmBtnSize;
 LayoutPanelContent(P);
end;

procedure TToolWindow.FlyContentLblClick(Sender: TObject);
var
 P: TPanel;
 L: TLabel;
 Dlg: TChildLabelForm;
 Cap: String;
 Hnt: String;
 BW: Integer;
begin
 Sender := Sender;
 if (FSelectedFly = nil) or (FSelectedFly.Kind <> fckPanel) then Exit;
 if (FSelectedFly.Control = nil) or not (FSelectedFly.Control is TPanel) then Exit;
 P := TPanel(FSelectedFly.Control);
 L := TLabel.Create(Self);
 L.Parent := P;
 L.Caption := '';
 L.Transparent := True;
 L.PopupMenu := FPopupMenu;
 L.OnMouseDown := @FlyControlMouseDown;
 L.Tag := PtrInt(FSelectedFly);
 Cap := '';
 Hnt := '';
 BW := 4;
 Dlg := TChildLabelForm.Create(Self);
 try
  if not Dlg.Execute(Cap, Hnt, BW) then begin
   L.Free;
   Exit;
  end;
 finally
  Dlg.Free;
 end;
 L.Caption := Cap;
 L.Hint := Hnt;
 L.ShowHint := Hnt <> '';
 L.Width := BW * fmBtnSize;
 L.Height := fmBtnSize;
 LayoutPanelContent(P);
end;

procedure TToolWindow.FlyContentEdtClick(Sender: TObject);
var
 P: TPanel;
 E: TEdit;
 Dlg: TChildEditForm;
 Txt: String;
 Hnt: String;
 BW: Integer;
begin
 Sender := Sender;
 if (FSelectedFly = nil) or (FSelectedFly.Kind <> fckPanel) then Exit;
 if (FSelectedFly.Control = nil) or not (FSelectedFly.Control is TPanel) then Exit;
 P := TPanel(FSelectedFly.Control);
 E := TEdit.Create(Self);
 E.Parent := P;
 E.Text := '';
 E.PopupMenu := FPopupMenu;
 E.OnMouseDown := @FlyControlMouseDown;
 E.Tag := PtrInt(FSelectedFly);
 Txt := '';
 Hnt := '';
 BW := 6;
 Dlg := TChildEditForm.Create(Self);
 try
  if not Dlg.Execute(Txt, Hnt, BW) then begin
   E.Free;
   Exit;
  end;
 finally
  Dlg.Free;
 end;
 E.Text := Txt;
 E.Hint := Hnt;
 E.ShowHint := Hnt <> '';
 E.Width := BW * fmBtnSize;
 E.Height := fmBtnSize;
 LayoutPanelContent(P);
end;

procedure TToolWindow.LayoutPanelContent(P: TPanel);
var
 I: Integer;
 C: TControl;
 Y: Integer;
 M: Integer;
 G: Integer;
 MaxW: Integer;
 W: Integer;
 H: Integer;
begin
 if P = nil then Exit;
 M := 4;
 G := 4;
 Y := M;
 MaxW := P.ClientWidth - M * 2;
 if MaxW < 10 then MaxW := 10;
 for I := 0 to P.ControlCount - 1 do begin
  C := P.Controls[I];
  if C = nil then Continue;
  W := C.Width;
  H := C.Height;
  if W < 10 then W := 10;
  if H < 10 then H := 10;
  if W > MaxW then W := MaxW;
  C.SetBounds(M, Y, W, H);
  Y := Y + H + G;
 end;
end;

function TToolWindow.NextFlyControlName: String;
var
 I, N: Integer;
 Nm: String;
 Found: Boolean;
begin
 N := 1;
 while True do begin
  Nm := 'Ctrl' + IntToStr(N);
  if (FDockSection = nil) or (FDockSection.flyControls = nil) then
   Exit(Nm);
  Found := False;
  for I := 0 to FDockSection.flyControls.Count - 1 do
   if (TflyControl(FDockSection.flyControls[I]) <> nil) and
      SameText(TflyControl(FDockSection.flyControls[I]).Name, Nm) then begin
     Found := True;
     Break;
   end;
  if not Found then
   Exit(Nm);
  Inc(N);
 end;
end;

procedure TToolWindow.FlyAddClick(Sender: TObject);
var
 FC: TflyControl;
 Cell: TPoint;
 BW, BH: Integer;
begin
 Sender := Sender;
 if FDockSection = nil then Exit;
 if FDockSection.flyControls = nil then Exit;

 Writeln(1);
 FC := TflyControl.Create;
 InitNewFlyControl(FC);
 if not FillNewFlyControlFromDialog(FC) then begin
  FC.Free;
  Exit;
 end;
 Writeln(2);
 BW := FC.BtnWidth;
 BH := FC.BtnHeight;
 if not FindFirstFreeCell(BW, BH, Cell) then begin
  FC.Free;
  Exit;
 end;
 Writeln(3);

 FC.X := Cell.X;
 FC.Y := Cell.Y;
 FDockSection.AddControl(FC);
 Writeln(4);
 Application.QueueAsyncCall(@AsyncRebuild, 0);
 Writeln(5);
end;

procedure TToolWindow.FlyInsClick(Sender: TObject);
var
 FC: TflyControl;
 Idx: Integer;
begin
 Sender := Sender;
 if (FDockSection = nil) or (FDockSection.flyControls = nil) then Exit;

 Idx := FlyControlIndexAtCell(FPopupCell);
 if Idx < 0 then
  Idx := FDockSection.flyControls.Count;

 FC := TflyControl.Create;
 InitNewFlyControl(FC);
 if not FillNewFlyControlFromDialog(FC) then begin
  FC.Free;
  Exit;
 end;
 FC.X := 0;
 FC.Y := 0;
 FDockSection.flyControls.Insert(Idx, FC);
 ReplaceControls;
 Application.QueueAsyncCall(@AsyncRebuild, 0);
end;

procedure TToolWindow.FlyEditClick(Sender: TObject);
begin
 Sender := Sender;
 if (FDockSection = nil) or (FDockSection.flyControls = nil) then Exit;
 if FSelectedFly = nil then Exit;

 if not FillNewFlyControlFromDialog(FSelectedFly) then Exit;
 ReplaceControls;
 Application.QueueAsyncCall(@AsyncRebuild, 0);
end;

procedure TToolWindow.FlyDelClick(Sender: TObject);
var
 Idx: Integer;
begin
 Sender := Sender;
 if (FDockSection = nil) or (FDockSection.flyControls = nil) then Exit;
 if FSelectedFly = nil then Exit;

 Idx := FDockSection.flyControls.IndexOf(FSelectedFly);
 if Idx >= 0 then begin
  FDockSection.flyControls.Delete(Idx);
  FSelectedFly.Free;
 end;
 FSelectedFly := nil;
 ReplaceControls;
 Application.QueueAsyncCall(@AsyncRebuild, 0);
end;

procedure TToolWindow.FlyControlMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
var
 C: TControl;
 BaseP: TPoint;
 Px: TPoint;
begin
 if Sender = pnkClient then
  FSelectedFly := nil;
 if (Button = mbLeft) and (Sender = pnkClient) then begin
  HeaderMouseDown(Sender, Button, Shift, X, Y);
  Exit;
 end;

 Shift := Shift;
 if (Sender is TControl) and (Sender <> pnkClient) then begin
  C := TControl(Sender);
  FSelectedFly := TflyControl(Pointer(C.Tag));
 end;

 if Button = mbRight then begin
  if pnkClient <> nil then begin
   BaseP := BaseOriginPx;
   if Sender is TControl then
    Px := Point(TControl(Sender).Left + X, TControl(Sender).Top + Y)
   else
    Px := Point(X, Y);

   Px.X := Px.X - BaseP.X;
   Px.Y := Px.Y - BaseP.Y;
   if Px.X < 0 then Px.X := 0;
   if Px.Y < 0 then Px.Y := 0;
   FPopupCell := Point(Px.X div fmBtnSize, Px.Y div fmBtnSize);
  end;
 end;
end;

procedure TDockDragFrame.Paint;
begin
  inherited Paint;
  FramePaint(Self);
end;

{ TToolWindow }

constructor TToolWindow.Create(TheOwner: TComponent);
begin
 inherited Create(TheOwner);
 sbSettings.Visible := ParamStr(1) = 'tooleditor';
//
 FContainers := TFPList.Create;
 FSelectedFly := nil;
 FPopupCell := Point(0, 0);
 FPopupMenu := TPopupMenu.Create(Self);
 FPopupMenu.OnPopup := @FlyPopupPopup;
 miFlyAdd := TMenuItem.Create(FPopupMenu);
 miFlyAdd.Caption := 'Добавить';
 miFlyAdd.OnClick := @FlyAddClick;
 FPopupMenu.Items.Add(miFlyAdd);
 miFlyIns := TMenuItem.Create(FPopupMenu);
 miFlyIns.Caption := 'Вставить';
 miFlyIns.OnClick := @FlyInsClick;
 FPopupMenu.Items.Add(miFlyIns);
 miFlyEdit := TMenuItem.Create(FPopupMenu);
 miFlyEdit.Caption := 'Редактировать';
 miFlyEdit.OnClick := @FlyEditClick;
 FPopupMenu.Items.Add(miFlyEdit);
 miFlyContent := TMenuItem.Create(FPopupMenu);
 miFlyContent.Caption := 'Содержание';
 FPopupMenu.Items.Add(miFlyContent);
 miFlyContentSB := TMenuItem.Create(miFlyContent);
 miFlyContentSB.Caption := 'TSpeedButton';
 miFlyContentSB.OnClick := @FlyContentSBClick;
 miFlyContent.Add(miFlyContentSB);
 miFlyContentCB := TMenuItem.Create(miFlyContent);
 miFlyContentCB.Caption := 'TComboBox';
 miFlyContentCB.OnClick := @FlyContentCBClick;
 miFlyContent.Add(miFlyContentCB);
 miFlyContentLbl := TMenuItem.Create(miFlyContent);
 miFlyContentLbl.Caption := 'TLabel';
 miFlyContentLbl.OnClick := @FlyContentLblClick;
 miFlyContent.Add(miFlyContentLbl);
 miFlyContentEdt := TMenuItem.Create(miFlyContent);
 miFlyContentEdt.Caption := 'TEdit';
 miFlyContentEdt.OnClick := @FlyContentEdtClick;
 miFlyContent.Add(miFlyContentEdt);
 miFlyDel := TMenuItem.Create(FPopupMenu);
 miFlyDel.Caption := 'Удалить';
 miFlyDel.OnClick := @FlyDelClick;
 FPopupMenu.Items.Add(miFlyDel);
 FBtnWidth := 6;
 FBtnHeight := 4;
 FInitToolBtnWidth := FBtnWidth;
 FInitToolBtnHeight := FBtnHeight;
 FInitHBtnWidth := 12;
 FInitHBtnHeight := 1;
 FInitVBtnWidth := 1;
 FInitVBtnHeight := 4;
 FDockSection := TflySection.Create;
 FDockSection.Control := Self;
 FDockSection.Name := Name;
 FDockSection.BtnWidth := FInitHBtnWidth;
 FDockSection.BtnHeight := FInitHBtnHeight;
 FDocked := False;
 FDragging := False;
 FMoveFrame := nil;
 FPlaceFrame := nil;
 FDragSource := nil;
 FResizing := False;
 FResizeMask := 0;
 sbSettings.OnClick := @sbSettingsClick;
 pnlHeader.OnClick := @pnlHeaderClick;
 pnkClient.OnClick := @pnkClientClick;
 pnkClient.PopupMenu := FPopupMenu;
 pnkClient.OnMouseDown := @FlyControlMouseDown;
 pnlHeader.OnMouseDown := @HeaderMouseDown;
 pnlHeader.OnMouseMove := @HeaderMouseMove;
 pnlHeader.OnMouseUp := @HeaderMouseUp;
 pnkClient.OnMouseMove := @HeaderMouseMove;
 pnkClient.OnMouseUp := @HeaderMouseUp;
 pnkClient.OnResize := @pnkClientResize;
 pnlResizeLeft.OnMouseDown := @ResizeMouseDown;
 pnlResizeLeft.OnMouseMove := @ResizeMouseMove;
 pnlResizeLeft.OnMouseUp := @ResizeMouseUp;
 pnlResizeRight.OnMouseDown := @ResizeMouseDown;
 pnlResizeRight.OnMouseMove := @ResizeMouseMove;
 pnlResizeRight.OnMouseUp := @ResizeMouseUp;
 pnlResizeTop.OnMouseDown := @ResizeMouseDown;
 pnlResizeTop.OnMouseMove := @ResizeMouseMove;
 pnlResizeTop.OnMouseUp := @ResizeMouseUp;
 pnlResizeBottom.OnMouseDown := @ResizeMouseDown;
 pnlResizeBottom.OnMouseMove := @ResizeMouseMove;
 pnlResizeBottom.OnMouseUp := @ResizeMouseUp;
 UpdateHeaderVisibility;
end;

procedure TToolWindow.ResizeMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
var
 P: TPoint;
begin
 Shift := Shift;
 X := X; Y := Y;
 if Button <> mbLeft then Exit;
 if FDocked then Exit;
 FResizing := True;
 FResizeMask := 0;
 if Sender = pnlResizeLeft then FResizeMask := 1 else
  if Sender = pnlResizeRight then FResizeMask := 2 else
   if Sender = pnlResizeTop then FResizeMask := 4 else
    if Sender = pnlResizeBottom then FResizeMask := 8;
 P := Mouse.CursorPos;
 FResizeStartP := P;
 FResizeStartR := BoundsRect;
 if Sender is TWinControl then
  SetCapture(TWinControl(Sender).Handle);
end;

procedure TToolWindow.ResizeMouseMove(Sender: TObject; Shift: TShiftState; X,
 Y: Integer);
var
 P: TPoint;
 DX, DY: Integer;
 L, T, W, H: Integer;
 MinW, MinH: Integer;
 BW, BH: Integer;
begin
 Sender := Sender;
 Shift := Shift;
 X := X; Y := Y;
 if not FResizing then Exit;
 P := Mouse.CursorPos;
 DX := P.X - FResizeStartP.X;
 DY := P.Y - FResizeStartP.Y;
 L := FResizeStartR.Left;
 T := FResizeStartR.Top;
 W := FResizeStartR.Right - FResizeStartR.Left;
 H := FResizeStartR.Bottom - FResizeStartR.Top;

 MinW := 50;
 MinH := 50;
 if pnlHeader <> nil then
  MinH := pnlHeader.Height + 20;

 if (FResizeMask and 1) <> 0 then begin
  L := L + DX;
  W := W - DX;
 end else if (FResizeMask and 2) <> 0 then
  W := W + DX;

 if (FResizeMask and 4) <> 0 then begin
  T := T + DY;
  H := H - DY;
 end else if (FResizeMask and 8) <> 0 then
  H := H + DY;

 if W < MinW then begin
  if (FResizeMask and 1) <> 0 then
   L := L - (MinW - W);
  W := MinW;
 end;
 if H < MinH then begin
  if (FResizeMask and 4) <> 0 then
   T := T - (MinH - H);
  H := MinH;
 end;

 BW := (W - fmLeftIndent - fmBorderIndent - fmResizeGrip * 2 + fmBtnSize div 2) div fmBtnSize;
 BH := (H - pnlHeader.Height - fmBorderIndent * 2 - fmResizeGrip * 2 + fmBtnSize div 2) div fmBtnSize;
 if BW < 1 then BW := 1;
 if BH < 1 then BH := 1;
 FBtnWidth := BW;
 FBtnHeight := BH;
 W := fmLeftIndent + fmBtnSize * BW + fmBorderIndent + fmResizeGrip * 2;
 H := pnlHeader.Height + fmBtnSize * BH + fmBorderIndent * 2 + fmResizeGrip * 2;
 if (FResizeMask and 1) <> 0 then
  L := FResizeStartR.Right - W;
 if (FResizeMask and 4) <> 0 then
  T := FResizeStartR.Bottom - H;
 SetBounds(L, T, W, H);
end;

procedure TToolWindow.ResizeMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 Sender := Sender;
 Shift := Shift;
 X := X; Y := Y;
 if Button <> mbLeft then Exit;
 if not FResizing then Exit;
 FResizing := False;
 ReleaseCapture;
end;

procedure TToolWindow.LoadSettings(Reg: TogsVarRegistry);
var
  Pfx: AnsiString;
  pL, pT, pR, pB: Boolean;
  I: Integer;
  Cnt: Integer;
  CtrlPfx: AnsiString;
  FC: TflyControl;
  Nm: AnsiString;
  Cap: AnsiString;
  Pn: TPanel;
  K: Integer;
  LegacyGlyphFile: AnsiString;
  Bmp: TBitmap;
begin
  if Reg = nil then Exit;
  Pfx := 'ToolWins\' + AnsiString(Name) + '\';

  Left := Reg.GetInt(Pfx + 'Left', Left);
  Top := Reg.GetInt(Pfx + 'Top', Top);
  Width := Reg.GetInt(Pfx + 'Width', Width);
  Height := Reg.GetInt(Pfx + 'Height', Height);
  FDocked := Reg.GetBool(Pfx + 'Docked', FDocked);
  if pnlHeader <> nil then
   pnlHeader.Caption := String(Reg.GetStr(Pfx + 'Caption', AnsiString(pnlHeader.Caption)));
  //
  pL := Reg.GetBool(Pfx + 'AllowL', True);
  pT := Reg.GetBool(Pfx + 'AllowT', True);
  pR := Reg.GetBool(Pfx + 'AllowR', True);
  pB := Reg.GetBool(Pfx + 'AllowB', True);
  if (avlContainers <> nil) and (FContainers <> nil) then begin
   FContainers.Clear;
   for I := 0 to avlContainers.Count - 1 do begin
    if TObject(avlContainers[I]) is TPanel then begin
     Pn := TPanel(avlContainers[I]);
     if (Pn.Align = alLeft) and pL then AddContainer(Pn) else
      if (Pn.Align = alTop) and pT then AddContainer(Pn) else
       if (Pn.Align = alRight) and pR then AddContainer(Pn) else
        if (Pn.Align = alBottom) and pB then AddContainer(Pn);
    end;
   end;
  end;
  //
  FInitToolBtnWidth := Reg.GetInt(Pfx + 'ToolBtnW', FInitToolBtnWidth);
  FInitToolBtnHeight := Reg.GetInt(Pfx + 'ToolBtnH', FInitToolBtnHeight);
  FInitHBtnWidth := Reg.GetInt(Pfx + 'HBtnW', FInitHBtnWidth);
  FInitHBtnHeight := Reg.GetInt(Pfx + 'HBtnH', FInitHBtnHeight);
  FInitVBtnWidth := Reg.GetInt(Pfx + 'VBtnW', FInitVBtnWidth);
  FInitVBtnHeight := Reg.GetInt(Pfx + 'VBtnH', FInitVBtnHeight);

  if FDockSection <> nil then begin
    FDockSection.BtnWidth := FInitHBtnWidth;
    FDockSection.BtnHeight := FInitHBtnHeight;
    FDockSection.ClearControls(True);
    Cnt := Reg.GetInt(Pfx + 'CtrlsCount', 0);
    for I := 0 to Cnt - 1 do begin
      CtrlPfx := Pfx + 'Ctrls\' + AnsiString(IntToStr(I)) + '\';
      Nm := Reg.GetStr(CtrlPfx + 'Name', '');
      if Nm = '' then Continue;
      FC := TflyControl.Create;
      FC.Name := String(Nm);
      Cap := Reg.GetStr(CtrlPfx + 'Caption', '');
      FC.Caption := String(Cap);
      FC.Hint := String(Reg.GetStr(CtrlPfx + 'Hint', ''));
      FC.X := Reg.GetInt(CtrlPfx + 'X', 0);
      FC.Y := Reg.GetInt(CtrlPfx + 'Y', 0);
      FC.Width := Reg.GetInt(CtrlPfx + 'Width', 0);
      FC.Height := Reg.GetInt(CtrlPfx + 'Height', 0);
      FC.BtnWidth := Reg.GetInt(CtrlPfx + 'BtnW', 1);
      FC.BtnHeight := Reg.GetInt(CtrlPfx + 'BtnH', 1);
      K := Reg.GetInt(CtrlPfx + 'Kind', 1);
      if K = 0 then
       FC.Kind := fckSpeedButton
      else
       FC.Kind := fckPanel;
      FC.GlyphData := Reg.GetStr(CtrlPfx + 'GlyphData', '');
      if (FC.GlyphData = '') and Reg.Exists(CtrlPfx + 'GlyphFile') then begin
       LegacyGlyphFile := Reg.GetStr(CtrlPfx + 'GlyphFile', '');
       if (LegacyGlyphFile <> '') and FileExists(String(LegacyGlyphFile)) then begin
        Bmp := TBitmap.Create;
        try
         try
          Bmp.LoadFromFile(String(LegacyGlyphFile));
          FC.GlyphData := BitmapToHex(Bmp);
         except
         end;
        finally
         Bmp.Free;
        end;
       end;
      end;
      FC.GlyphHash := String(Reg.GetStr(CtrlPfx + 'GlyphHash', ''));
      if (FC.Kind = fckSpeedButton) and (BitHashCollect <> nil) then
       FC.BitHashItem := BitHashCollect.FindItemByHash(FC.GlyphHash)
      else
       FC.BitHashItem := nil;
      FC.Control := nil;
      FDockSection.AddControl(FC);
    end;
    RebuildFlyControlsUI;
  end;
end;

procedure TToolWindow.SaveSettings(Reg: TogsVarRegistry);
var
  Pfx: AnsiString;
  DS: TflySection;
  I: Integer;
  Cnt: Integer;
  CtrlPfx: AnsiString;
  FC: TflyControl;
  pL, pT, pR, pB: Boolean;
begin
  if Reg = nil then Exit;
  Pfx := 'ToolWins\' + AnsiString(Name) + '\';

  Reg.SetInt(Pfx + 'Left', Left);
  Reg.SetInt(Pfx + 'Top', Top);
  Reg.SetInt(Pfx + 'Width', Width);
  Reg.SetInt(Pfx + 'Height', Height);
  Reg.SetBool(Pfx + 'Docked', FDocked);
  if Parent <> nil then
   Reg.SetStr(Pfx + 'Host', AnsiString(Parent.Name))
  else
   Reg.SetStr(Pfx + 'Host', '');

  pL := False; pT := False; pR := False; pB := False;
  if FContainers <> nil then
   for I := 0 to FContainers.Count - 1 do
    if (TDockContainerBase(FContainers[I]) <> nil) and (TDockContainerBase(FContainers[I]).Host is TPanel) then
     with TPanel(TDockContainerBase(FContainers[I]).Host) do begin
      if Align = alLeft then pL := True else
       if Align = alTop then pT := True else
        if Align = alRight then pR := True else
         if Align = alBottom then pB := True;
     end;
  Reg.SetBool(Pfx + 'AllowL', pL);
  Reg.SetBool(Pfx + 'AllowT', pT);
  Reg.SetBool(Pfx + 'AllowR', pR);
  Reg.SetBool(Pfx + 'AllowB', pB);

  DS := FindDockedSection;
  if DS <> nil then begin
   if (Parent <> nil) and ((Parent.Align = alLeft) or (Parent.Align = alRight)) then begin
    Reg.SetInt(Pfx + 'DockColKey', DS.RowKey);
    Reg.SetInt(Pfx + 'DockY', DS.Y);
   end else begin
    Reg.SetInt(Pfx + 'DockRowKey', DS.RowKey);
    Reg.SetInt(Pfx + 'DockX', DS.X);
   end;
   Reg.SetInt(Pfx + 'DockBtnW', DS.BtnWidth);
   Reg.SetInt(Pfx + 'DockBtnH', DS.BtnHeight);
  end;
  if pnlHeader <> nil then
   Reg.SetStr(Pfx + 'Caption', AnsiString(pnlHeader.Caption));
  //
  Reg.SetInt(Pfx + 'ToolBtnW', FInitToolBtnWidth);
  Reg.SetInt(Pfx + 'ToolBtnH', FInitToolBtnHeight);
  Reg.SetInt(Pfx + 'HBtnW', FInitHBtnWidth);
  Reg.SetInt(Pfx + 'HBtnH', FInitHBtnHeight);
  Reg.SetInt(Pfx + 'VBtnW', FInitVBtnWidth);
  Reg.SetInt(Pfx + 'VBtnH', FInitVBtnHeight);

  if FDockSection <> nil then begin
    if FDockSection.flyControls <> nil then
      Cnt := FDockSection.flyControls.Count
    else
      Cnt := 0;
    Reg.SetInt(Pfx + 'CtrlsCount', Cnt);
    for I := 0 to Cnt - 1 do begin
      FC := TflyControl(FDockSection.flyControls[I]);
      if FC = nil then Continue;
      CtrlPfx := Pfx + 'Ctrls\' + AnsiString(IntToStr(I)) + '\';
      Reg.SetStr(CtrlPfx + 'Name', AnsiString(FC.Name));
      Reg.SetStr(CtrlPfx + 'Caption', AnsiString(FC.Caption));
      Reg.SetStr(CtrlPfx + 'Hint', AnsiString(FC.Hint));
      Reg.SetInt(CtrlPfx + 'X', FC.X);
      Reg.SetInt(CtrlPfx + 'Y', FC.Y);
      Reg.SetInt(CtrlPfx + 'Width', FC.Width);
      Reg.SetInt(CtrlPfx + 'Height', FC.Height);
      if FC.BtnWidth < 1 then
        Reg.SetInt(CtrlPfx + 'BtnW', 1)
      else
        Reg.SetInt(CtrlPfx + 'BtnW', FC.BtnWidth);
      if FC.BtnHeight < 1 then
        Reg.SetInt(CtrlPfx + 'BtnH', 1)
      else
        Reg.SetInt(CtrlPfx + 'BtnH', FC.BtnHeight);

      if FC.Kind = fckSpeedButton then
       Reg.SetInt(CtrlPfx + 'Kind', 0)
      else
       Reg.SetInt(CtrlPfx + 'Kind', 1);

      Reg.SetStr(CtrlPfx + 'GlyphData', AnsiString(FC.GlyphData));
      Reg.SetStr(CtrlPfx + 'GlyphHash', AnsiString(FC.GlyphHash));
    end;
  end;
end;

procedure TToolWindow.SyncDockName;
begin
 if FDockSection <> nil then
  FDockSection.Name := Name;
end;

procedure TToolWindow.RecreateToolHandle;
begin
 RecreateWnd(Self);
end;

destructor TToolWindow.Destroy;
var
 I: Integer;
 C: TDockContainerBase;
begin
 FreeAndNil(FMoveFrame);
 FreeAndNil(FPlaceFrame);
 FreeAndNil(FDockSection);
 if FContainers <> nil then begin
  for I := 0 to FContainers.Count - 1 do begin
   C := TDockContainerBase(FContainers[I]);
   if C <> nil then
    begin
      C.NotifyControlDestroyed(Self);
      C.Release;
    end;
  end;
  FreeAndNil(FContainers);
 end;
 inherited Destroy;
end;

procedure TToolWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if not FDocked then begin
    Params.Style := (Params.Style or WS_POPUP) and not WS_CHILD;
    Params.WndParent := 0;
  end else begin
    Params.Style := (Params.Style or WS_CHILD) and not WS_POPUP;
    if (Parent <> nil) and (Parent is TWinControl) then
      Params.WndParent := TWinControl(Parent).Handle
    else
      Params.WndParent := TForm(Owner).Handle;
  end;
end;

function TToolWindow.DockBtnWidth: Integer;
begin
  if (FDockSection <> nil) and (FDockSection.BtnWidth > 0) then
    Exit(FDockSection.BtnWidth);
  Result := FBtnWidth;
end;

function TToolWindow.DockBtnHeight: Integer;
begin
  if (FDockSection <> nil) and (FDockSection.BtnHeight > 0) then
    Exit(FDockSection.BtnHeight);
  Result := FBtnHeight;
end;

function TToolWindow.FloatPxWidth: Integer;
var
  DS: TflySection;
begin
  if FDocked then begin
    DS := FindDockedSection;
    if (DS <> nil) and (DS.BtnWidth > 0) then
      Exit(fmLeftIndent + fmBtnSize * DS.BtnWidth + fmBorderIndent);
  end;

  if FBtnWidth < 1 then
    Result := fmLeftIndent + fmBtnSize * 1 + fmBorderIndent
  else
    Result := fmLeftIndent + fmBtnSize * FBtnWidth + fmBorderIndent;

  Result := Result + fmResizeGrip * 2;
end;

function TToolWindow.FloatPxHeight: Integer;
var
  DS: TflySection;
begin
  if FDocked then begin
    DS := FindDockedSection;
    if (DS <> nil) and (DS.BtnHeight > 0) then
      Exit(fmBtnSize * DS.BtnHeight + fmBorderIndent * 2);
  end;

  if FBtnHeight < 1 then
    Result := fmBtnSize * 1 + fmBorderIndent * 2
  else
    Result := fmBtnSize * FBtnHeight + fmBorderIndent * 2;

  Result := Result + fmResizeGrip * 2;
  if (pnlHeader <> nil) and not FDocked then
   Result := Result + pnlHeader.Height;
end;

function TToolWindow.UndockedFloatPxWidth: Integer;
begin
  if FBtnWidth < 1 then
    Result := fmLeftIndent + fmBtnSize * 1 + fmBorderIndent
  else
    Result := fmLeftIndent + fmBtnSize * FBtnWidth + fmBorderIndent;

  Result := Result + fmResizeGrip * 2;
end;

function TToolWindow.UndockedFloatPxHeight: Integer;
begin
  if FBtnHeight < 1 then
    Result := fmBtnSize * 1 + fmBorderIndent * 2
  else
    Result := fmBtnSize * FBtnHeight + fmBorderIndent * 2;

  Result := Result + fmResizeGrip * 2;
  if pnlHeader <> nil then
   Result := Result + pnlHeader.Height;
end;

function TToolWindow.GetUndockedPxWidth: Integer;
begin
 Result := UndockedFloatPxWidth;
end;

function TToolWindow.GetUndockedPxHeight: Integer;
begin
 Result := UndockedFloatPxHeight;
end;

procedure TToolWindow.EnsureMoveFrame;
begin
  if FMoveFrame <> nil then Exit;
  FMoveFrame := TDockDragFrame.CreateNew(Owner);
  FMoveFrame.BorderStyle := bsNone;
  FMoveFrame.Position := poDesigned;
  FMoveFrame.ShowInTaskBar := stNever;
  FMoveFrame.FormStyle := fsStayOnTop;
//  FDragFrame.ShowActivated := False;
 // FDragFrame.Color := clRed;
  FMoveFrame.AlphaBlend := True;
  FMoveFrame.AlphaBlendValue := 150;
  FMoveFrame.Enabled := True;
  FMoveFrame.Visible := False;
  TDockDragFrame(FMoveFrame).OnPaint := @TDockDragFrame(FMoveFrame).FramePaint;
end;

procedure TToolWindow.EnsurePlaceFrame;
begin
  if FPlaceFrame <> nil then Exit;
  FPlaceFrame := TDockDragFrame.CreateNew(Owner);
  FPlaceFrame.BorderStyle := bsNone;
  FPlaceFrame.Position := poDesigned;
  FPlaceFrame.ShowInTaskBar := stNever;
  FPlaceFrame.FormStyle := fsStayOnTop;
  FPlaceFrame.AlphaBlend := True;
  FPlaceFrame.AlphaBlendValue := 150;
  FPlaceFrame.Enabled := True;
  FPlaceFrame.Visible := False;
  TDockDragFrame(FPlaceFrame).OnPaint := @TDockDragFrame(FPlaceFrame).FramePaint;
end;

procedure TToolWindow.HideDragFrames;
begin
  FreeAndNil(FMoveFrame);
  FreeAndNil(FPlaceFrame);
end;

procedure TToolWindow.UpdateMoveFrame(ALeft, ATop: Integer);
begin
  EnsureMoveFrame;
  TDockDragFrame(FMoveFrame).CapturedContainer := nil;
  TDockDragFrame(FMoveFrame).PlacementRect := Rect(0, 0, 0, 0);
  FMoveFrame.SetBounds(ALeft, ATop, FloatPxWidth, FloatPxHeight);
  FMoveFrame.Show;
  FMoveFrame.BringToFront;
end;

procedure TToolWindow.UpdatePlaceFrame(AContainer: TDockContainerBase;
  const PlacementR: TRect);
var
  BoundsR: TRect;
  HC: THContainer;
  HostP: TPoint;
  S: Integer;
  Sec: TflySection;
  CR: TRect;
  IgnoreCtrl: TWinControl;
begin
  EnsurePlaceFrame;
  TDockDragFrame(FPlaceFrame).CapturedContainer := AContainer;
  TDockDragFrame(FPlaceFrame).PlacementRect := PlacementR;

  BoundsR := PlacementR;

  if (AContainer <> nil) and (AContainer is THContainer) and (AContainer.Host <> nil) then begin
    HC := THContainer(AContainer);
    IgnoreCtrl := AContainer.CaptureControl;
    HostP := AContainer.Host.ClientToScreen(Point(0, 0));

    if HC.flySections <> nil then
      for S := 0 to HC.flySections.Count - 1 do begin
        Sec := TflySection(HC.flySections[S]);
        if Sec = nil then Continue;
        if (IgnoreCtrl <> nil) and (Sec.Control = IgnoreCtrl) then Continue;
        CR := Rect(HostP.X + Sec.X, HostP.Y + Sec.Y,
                   HostP.X + Sec.X + Sec.Width, HostP.Y + Sec.Y + Sec.Height);
        UnionRect(BoundsR, BoundsR, CR);
      end;
  end;

  if BoundsR.Right <= BoundsR.Left then
    BoundsR.Right := BoundsR.Left + 1;
  if BoundsR.Bottom <= BoundsR.Top then
    BoundsR.Bottom := BoundsR.Top + 1;
  FPlaceFrame.SetBounds(BoundsR.Left, BoundsR.Top, BoundsR.Right - BoundsR.Left, BoundsR.Bottom - BoundsR.Top);
  FPlaceFrame.Show;
  FPlaceFrame.BringToFront;
  FPlaceFrame.HandleNeeded;
  FPlaceFrame.Invalidate;
  FPlaceFrame.Update;
end;

procedure TToolWindow.DoToolActivate;
begin
 if Assigned(FOnToolActivate) then
  FOnToolActivate(Self);
end;

procedure TToolWindow.pnkClientClick(Sender: TObject);
begin
 DoToolActivate;
end;

procedure TToolWindow.pnlHeaderClick(Sender: TObject);
begin
 DoToolActivate;
end;

procedure TToolWindow.sbSettingsClick(Sender: TObject);
var I, ToolW, ToolH: Integer;
    HW, HH: Integer;
    VW, VH: Integer;
    Nm: String;
    pL, pT, pR, pB: Boolean;
begin
 ToolW := btnWidth;
 ToolH := btnHeight;
 HW := FInitHBtnWidth;
 HH := FInitHBtnHeight;
 VW := FInitVBtnWidth;
 VH := FInitVBtnHeight;
 Nm := pnlHeader.Caption;
 pL := False; pT := False; pR := False; pB := False;
 For I := 0 to FContainers.Count - 1 do
  With TPanel(TDockContainerBase(FContainers[I]).Host) do begin
   If Align = alLeft then pL := True else
    If Align = alTop then pT := True else
     If Align = alRight then pR := True else
      If Align = alBottom then pB := True;
  end;
//
 ToolSettingsForm := TToolSettingsForm.Create(Self);
 if ToolSettingsForm.Execute(Nm, ToolW, ToolH, HW, HH, VW, VH, pL, pT, pR, pB) then begin
  FInitToolBtnWidth := ToolW;
  FInitToolBtnHeight := ToolH;
  FInitHBtnWidth := HW;
  FInitHBtnHeight := HH;
  FInitVBtnWidth := VW;
  FInitVBtnHeight := VH;
  FBtnWidth := FInitToolBtnWidth;
  FBtnHeight := FInitToolBtnHeight;
 //
 pnlHeader.Caption := Nm;
 FContainers.Clear;
 For I := 0 to avlContainers.Count - 1 do
  With TPanel(avlContainers[I]) do
   If (Align = alLeft) and pL then AddContainer(TPanel(avlContainers[I])) else
    If (Align = alTop) and pT then AddContainer(TPanel(avlContainers[I])) else
     If (Align = alRight) and pR then AddContainer(TPanel(avlContainers[I])) else
      If (Align = alBottom) and pB then AddContainer(TPanel(avlContainers[I]));
 //
  if FDockSection <> nil then begin
   FDockSection.BtnWidth := FInitHBtnWidth;
   FDockSection.BtnHeight := FInitHBtnHeight;
  end;
 end;
end;

procedure TToolWindow.HeaderMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if Button <> mbLeft then Exit;
  DoToolActivate;
  HideDragFrames;
  FDragging := True;
  FDragOffset := Point(X, Y);
  if Sender is TWinControl then
    FDragSource := TWinControl(Sender)
  else
    FDragSource := pnlHeader;
  if (Parent <> nil) and not FDocked then
    P := Parent.ClientToScreen(Point(Left, Top))
  else
    P := Point(Left, Top);
  UpdateMoveFrame(P.X, P.Y);
  FCapturedContainer := nil;
  if FDocked then begin
    BringToFront;
   // if HandleAllocated then
   //   BringWindowToTop(Handle);
  end;
  if FDragSource <> nil then
    SetCapture(FDragSource.Handle);
end;

procedure TToolWindow.HeaderMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  ScreenP: TPoint;
  NewLeft, NewTop: Integer;
  I: Integer;
  C: TDockContainerBase;
  R: TRect;
  BW, BH: Integer;
begin
  if not FDragging then Exit;
  if FDragSource <> nil then
    ScreenP := FDragSource.ClientToScreen(Point(X, Y))
  else
    ScreenP := pnlHeader.ClientToScreen(Point(X, Y));
  NewLeft := ScreenP.X - FDragOffset.X;
  NewTop := ScreenP.Y - FDragOffset.Y;

  FCapturedContainer := nil;
  if FContainers <> nil then
    for I := 0 to FContainers.Count - 1 do begin
      C := TDockContainerBase(FContainers[I]);
      if C = nil then Continue;
      BW := DockBtnWidth;
      BH := DockBtnHeight;
      if (C.Host <> nil) then begin
        case C.Host.Align of
          alTop, alBottom: begin
            BW := FInitHBtnWidth;
            BH := FInitHBtnHeight;
          end;
          alLeft, alRight: begin
            BW := FInitVBtnWidth;
            BH := FInitVBtnHeight;
          end;
        end;
      end;
      C.SetCaptureTool(Name, BW, BH, Self);
      if C.GetCapture(ScreenP.X, ScreenP.Y, R) then begin
        FCapturedContainer := C;
        UpdatePlaceFrame(C, R);
        Break;
      end;
    end;

  if FCapturedContainer = nil then
    FreeAndNil(FPlaceFrame);

  if FCapturedContainer = nil then
    FMoveFrame.SetBounds(NewLeft, NewTop, UndockedFloatPxWidth, UndockedFloatPxHeight);

end;

procedure TToolWindow.HeaderMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  ScreenP: TPoint;
  HR: TRect;
  I: Integer;
  C: TDockContainerBase;
begin
  if Button <> mbLeft then Exit;
  if not FDragging then Exit;
  FDragging := False;
  ReleaseCapture;

  if FDragSource <> nil then
    ScreenP := FDragSource.ClientToScreen(Point(X, Y))
  else
    ScreenP := pnlHeader.ClientToScreen(Point(X, Y));

  if (FCapturedContainer <> nil) and (FCapturedContainer is THContainer) then begin
    THContainer(FCapturedContainer).ApplyDock(ScreenP.X, ScreenP.Y);
    if (FCapturedContainer.Host <> nil) and
       THContainer(FCapturedContainer).GetDockedRectByName(Name, HR) then begin
      FDocked := True;
      BorderStyle := bsNone;
      Parent := FCapturedContainer.Host;
      RecreateWnd(Self);
      SetBounds(HR.Left, HR.Top, HR.Right - HR.Left, HR.Bottom - HR.Top);
      UpdateHeaderVisibility;
      BringToFront;
     // if HandleAllocated then
      //  BringWindowToTop(Handle);
    end;
  end
  else if (FCapturedContainer <> nil) and (FCapturedContainer is TVContainer) then begin
    TVContainer(FCapturedContainer).ApplyDock(ScreenP.X, ScreenP.Y);
    if (FCapturedContainer.Host <> nil) and
       TVContainer(FCapturedContainer).GetDockedRectByName(Name, HR) then begin
      FDocked := True;
      BorderStyle := bsNone;
      Parent := FCapturedContainer.Host;
      RecreateWnd(Self);
      SetBounds(HR.Left, HR.Top, HR.Right - HR.Left, HR.Bottom - HR.Top);
      UpdateHeaderVisibility;
      BringToFront;
    end;
  end
  else if FMoveFrame <> nil then begin
    if FDocked then begin
      if FContainers <> nil then
        for I := 0 to FContainers.Count - 1 do begin
          C := TDockContainerBase(FContainers[I]);
          if C <> nil then
            C.NotifyControlDestroyed(Self);
        end;
      FDocked := False;
      Parent := nil;
      BorderStyle := bsNone;
      RecreateWnd(Self);
      UpdateHeaderVisibility;
    end;

    if Parent <> nil then begin
      P := Parent.ScreenToClient(Point(FMoveFrame.Left, FMoveFrame.Top));
      SetBounds(P.X, P.Y, FloatPxWidth, FloatPxHeight);
    end else
      SetBounds(FMoveFrame.Left, FMoveFrame.Top, FloatPxWidth, FloatPxHeight);
  end;

  HideDragFrames;
  FDragSource := nil;
end;

procedure TToolWindow.UpdateHeaderVisibility;
begin
 pnlHeader.Visible := not FDocked;
 pnlResizeLeft.Visible := not FDocked;
 pnlResizeRight.Visible := not FDocked;
 pnlResizeTop.Visible := not FDocked;
 pnlResizeBottom.Visible := not FDocked;
end;

procedure TToolWindow.AddContainer(AHost: TWinControl);
begin
 AddContainer(AHost, 0, 0);
end;

procedure TToolWindow.AddContainer(AHost: TWinControl; ABtnWidth,
 ABtnHeight: Integer);
var
  C: TDockContainerBase;
  DS: TflySection;
  I: Integer;
begin
 if AHost = nil then Exit;
 if FContainers = nil then
  FContainers := TFPList.Create;
 for I := 0 to FContainers.Count - 1 do begin
  C := TDockContainerBase(FContainers[I]);
  if (C <> nil) and (C.Host = AHost) then Exit;
 end;
 if FDockSection <> nil then begin
  case AHost.Align of
   alTop, alBottom: begin
    FDockSection.BtnWidth := FInitHBtnWidth;
    FDockSection.BtnHeight := FInitHBtnHeight;
   end;
   alLeft, alRight: begin
    FDockSection.BtnWidth := FInitVBtnWidth;
    FDockSection.BtnHeight := FInitVBtnHeight;
   end;
  else begin
    if ABtnWidth > 0 then
      FDockSection.BtnWidth := ABtnWidth;
    if ABtnHeight > 0 then
      FDockSection.BtnHeight := ABtnHeight;
  end;
  end;
 end;

 C := AcquireDockContainer(AHost);
 FContainers.Add(C);

 if FDocked then begin
   DS := FindDockedSection;
   if DS <> nil then begin
     if ABtnWidth > 0 then
       DS.BtnWidth := ABtnWidth;
     if ABtnHeight > 0 then
       DS.BtnHeight := ABtnHeight;
   end;
 end;
end;

function TToolWindow.FindDockedSection: TflySection;
var
  I, S: Integer;
  C: TDockContainerBase;
  HC: THContainer;
  VC: TVContainer;
  Sec: TflySection;
begin
  Result := nil;
  if not FDocked then Exit;
  if (FContainers = nil) then Exit;

  for I := 0 to FContainers.Count - 1 do begin
    C := TDockContainerBase(FContainers[I]);
    if not (C is THContainer) then Continue;
    HC := THContainer(C);
    if HC.flySections = nil then Continue;
    for S := 0 to HC.flySections.Count - 1 do begin
      Sec := TflySection(HC.flySections[S]);
      if Sec = nil then Continue;
      if Sec.Control = Self then
        Exit(Sec);
    end;
  end;

  for I := 0 to FContainers.Count - 1 do begin
    C := TDockContainerBase(FContainers[I]);
    if not (C is TVContainer) then Continue;
    VC := TVContainer(C);
    if VC.flySections = nil then Continue;
    for S := 0 to VC.flySections.Count - 1 do begin
      Sec := TflySection(VC.flySections[S]);
      if Sec = nil then Continue;
      if Sec.Control = Self then
        Exit(Sec);
    end;
  end;
end;

end.

