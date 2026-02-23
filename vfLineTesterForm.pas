unit vfLineTesterForm;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Types, Math, ComCtrls, PythonEngine, vfLineStyles, P4DLaz;

type
  { TfrmVFLineTester }
  TfrmVFLineTester = class(TForm)
    btnCreateStyle: TButton;
    btnInitDashed: TButton;
    btnPythonLib: TButton;
    edtThickness: TEdit;
    edtDash: TEdit;
    edtDashOffset: TEdit;
    edtGap: TEdit;
    edtTrimEnd: TEdit;
    edtTrimStart: TEdit;
    lblDash: TLabel;
    lblDashOffset: TLabel;
    lblGap: TLabel;
    lblThickness: TLabel;
    lblHint: TLabel;
    lblTrimEnd: TLabel;
    lblTrimStart: TLabel;
    pbPreview: TPaintBox;
    procedure btnCreateStyleClick(Sender: TObject);
    procedure btnInitDashedClick(Sender: TObject);
    procedure btnPythonLibClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbPreviewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbPreviewPaint(Sender: TObject);
  private
    FLineStyle: TVFLineStyle;
    FPoints: array of TPointF;
    FInputActive: Boolean;
    FPython: TPythonEngine;
    FPythonModule: TPythonModule;
    FOverlayCallback: PPyObject;
    FOverlayCanvas: TCanvas;
    FInOverlayPaint: Boolean;
    FOverlayErrorShown: Boolean;
    function PySetEvenDashScale(self, args: PPyObject): PPyObject; cdecl;
    function PySetOverlayCallback(self, args: PPyObject): PPyObject; cdecl;
    function PyClearOverlayCallback(self, args: PPyObject): PPyObject; cdecl;
    function PySetPen(self, args: PPyObject): PPyObject; cdecl;
    function PyDrawPolyline(self, args: PPyObject): PPyObject; cdecl;
    function PyDrawPolygon(self, args: PPyObject): PPyObject; cdecl;
    function GetCurrentEvenDashScale: Double;
    function ExecutePythonLibDialog(out ACode: AnsiString): Boolean;
    procedure InvokeOverlay(const Polygons: TVFLinePolygonArray);
    function GetTrimmedPoints(const Src: TVFLinePolygon; const TrimStart,
      TrimEnd: Double): TVFLinePolygon;
    procedure CreateSolidStyle(const AThickness: Double);
    procedure CreateDashedStyle(const AThickness, ADash, AGap, ADashOffset,
      ATrimStart, ATrimEnd: Double);
    procedure ResetPolyline(const KeepPoints: Boolean = False);
    procedure AddPoint(const AX, AY: Integer);
  public
    procedure UpdatePreview;
  end;

var
  frmVFLineTester: TfrmVFLineTester;

implementation uses ogcWriter;

{$R *.frm}

const
  DEFAULT_TEST_THICKNESS = 14.0;

type
  TPythonLibDialog = class(TForm)
  private
    FMemo: TMemo;
    FTrack: TTrackBar;
    FEdtScale: TEdit;
    procedure TrackChanged(Sender: TObject);
    procedure ScaleEditingDone(Sender: TObject);
    function FormatScaleText(const V: Double): string;
    function ReadScaleFromUI: Double;
    procedure UpdateScaleInMemo(const ScaleText: string);
    procedure SyncScaleToUI(const V: Double);
  public
    constructor CreateDialog(AOwner: TComponent);
    procedure Init(const InitialScale: Double);
    function GetCode: AnsiString;
  end;

{ TfrmVFLineTester }

procedure TfrmVFLineTester.FormCreate(Sender: TObject);
begin
  FLineStyle := nil;
  FPython := nil;
  FPythonModule := nil;
  FOverlayCallback := nil;
  FOverlayCanvas := nil;
  FInOverlayPaint := False;
  FOverlayErrorShown := False;
  ResetPolyline(False);
  CreateSolidStyle(DEFAULT_TEST_THICKNESS);
  edtThickness.Text := FloatToStr(DEFAULT_TEST_THICKNESS);

  try
    FPython := TPythonEngine.Create(Self);
    FPython.DllName := 'C:\Users\geoma\AppData\Local\Python\pythoncore-3.14-64\python314.dll';
    FPython.UseWindowsConsole := True;
    FPython.RedirectIO := False;

    FPythonModule := TPythonModule.Create(Self);
    FPythonModule.Engine := FPython;
    FPythonModule.ModuleName := 'vfline';
    FPythonModule.AddDelphiMethod('set_even_dash_scale', PySetEvenDashScale,
      'set_even_dash_scale(scale: float) -> None');
    FPythonModule.AddDelphiMethod('set_overlay_callback', PySetOverlayCallback,
      'set_overlay_callback(func) -> None');
    FPythonModule.AddDelphiMethod('clear_overlay_callback', PyClearOverlayCallback,
      'clear_overlay_callback() -> None');
    FPythonModule.AddDelphiMethod('set_pen', PySetPen,
      'set_pen(r: int, g: int, b: int, width: int = 1) -> None');
    FPythonModule.AddDelphiMethod('draw_polyline', PyDrawPolyline,
      'draw_polyline(points: list[(x,y)], closed: bool = False) -> None');
    FPythonModule.AddDelphiMethod('draw_polygon', PyDrawPolygon,
      'draw_polygon(points: list[(x,y)]) -> None');

    FPython.LoadDll;
    FPythonModule.Initialize;
    FPython.ExecString('print("hello from embedded python")');
  except
    on E: Exception do
    begin
      FreeAndNil(FPython);
      FreeAndNil(FPythonModule);
      MessageDlg('Python init error: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmVFLineTester.FormDestroy(Sender: TObject);
begin
  if (FPython <> nil) and (FOverlayCallback <> nil) then
    FPython.Py_DecRef(FOverlayCallback);
  FOverlayCallback := nil;
  FreeAndNil(FPythonModule);
  FreeAndNil(FPython);
  FreeAndNil(FLineStyle);
end;

function TfrmVFLineTester.PySetOverlayCallback(self, args: PPyObject): PPyObject; cdecl;
var
  FuncObj: PPyObject;
begin
  Result := nil;
  if FPython = nil then
    Exit;

  FuncObj := nil;
  if FPython.PyArg_ParseTuple(args, 'O', @FuncObj) = 0 then
    Exit;

  if (FuncObj = nil) or (FPython.PyCallable_Check(FuncObj) = 0) then
    Exit;

  if FOverlayCallback <> nil then
    FPython.Py_DecRef(FOverlayCallback);
  FPython.Py_IncRef(FuncObj);
  FOverlayCallback := FuncObj;
  FOverlayErrorShown := False;

  Result := FPython.ReturnNone;
end;

function TfrmVFLineTester.PyClearOverlayCallback(self, args: PPyObject): PPyObject; cdecl;
begin
  Result := nil;
  if FPython = nil then
    Exit;
  if FOverlayCallback <> nil then
    FPython.Py_DecRef(FOverlayCallback);
  FOverlayCallback := nil;
  FOverlayErrorShown := False;
  Result := FPython.ReturnNone;
end;

function TfrmVFLineTester.PySetPen(self, args: PPyObject): PPyObject; cdecl;
var
  R, G, B: Integer;
  W: Integer;
begin
  Result := nil;
  if (FPython = nil) or (not FInOverlayPaint) or (FOverlayCanvas = nil) then
    Exit;

  W := 1;
  if FPython.PyArg_ParseTuple(args, 'iii|i', @R, @G, @B, @W) = 0 then
    Exit;

  R := EnsureRange(R, 0, 255);
  G := EnsureRange(G, 0, 255);
  B := EnsureRange(B, 0, 255);
  if W < 1 then
    W := 1;

  FOverlayCanvas.Pen.Style := psSolid;
  FOverlayCanvas.Pen.Color := RGBToColor(Byte(R), Byte(G), Byte(B));
  FOverlayCanvas.Pen.Width := W;
 // FOverlayCanvas.Brush.Style := bsClear;

  Result := FPython.ReturnNone;
end;

function TfrmVFLineTester.PyDrawPolyline(self, args: PPyObject): PPyObject; cdecl;
var
  SeqObj: PPyObject;
  ClosedObj: PPyObject;
  Closed: Boolean;
  I, N: Integer;
  Item: PPyObject;
  XObj, YObj: PPyObject;
  X, Y: Double;
  Pts: array of TPoint;
begin
  Result := nil;
  if (FPython = nil) or (not FInOverlayPaint) or (FOverlayCanvas = nil) then
    Exit;

  SeqObj := nil;
  ClosedObj := nil;
  if FPython.PyArg_ParseTuple(args, 'O|O', @SeqObj, @ClosedObj) = 0 then
    Exit;

  Closed := False;
  if ClosedObj <> nil then
    Closed := FPython.PyObject_IsTrue(ClosedObj) <> 0;

  N := FPython.PySequence_Length(SeqObj);
  if N <= 0 then
  begin
    Result := FPython.ReturnNone;
    Exit;
  end;

  SetLength(Pts, N + Ord(Closed));
  for I := 0 to N - 1 do
  begin
    Item := FPython.PySequence_GetItem(SeqObj, I);
    if (Item = nil) or (FPython.PyTuple_Check(Item) = false) or (FPython.PyTuple_Size(Item) < 2) then
    begin
      if Item <> nil then
        FPython.Py_DecRef(Item);
      Exit;
    end;
    try
      XObj := FPython.PyTuple_GetItem(Item, 0);
      YObj := FPython.PyTuple_GetItem(Item, 1);
      X := FPython.PyFloat_AsDouble(XObj);
      Y := FPython.PyFloat_AsDouble(YObj);
      Pts[I].X := Round(X);
      Pts[I].Y := Round(Y);
    finally
      FPython.Py_DecRef(Item);
    end;
  end;

  if Closed then
    Pts[N] := Pts[0];
  FOverlayCanvas.Polyline(Pts);
  Result := FPython.ReturnNone;
end;

function TfrmVFLineTester.PyDrawPolygon(self, args: PPyObject): PPyObject; cdecl;
var
  SeqObj: PPyObject;
  I, N: Integer;
  Item: PPyObject;
  XObj, YObj: PPyObject;
  X, Y: Double;
  Pts: array of TPoint;
begin
  Result := nil;
  if (FPython = nil) or (not FInOverlayPaint) or (FOverlayCanvas = nil) then
    Exit;

  SeqObj := nil;
  if FPython.PyArg_ParseTuple(args, 'O', @SeqObj) = 0 then
    Exit;

  N := FPython.PySequence_Length(SeqObj);
  if N <= 0 then
  begin
    Result := FPython.ReturnNone;
    Exit;
  end;

  SetLength(Pts, N);
  for I := 0 to N - 1 do
  begin
    Item := FPython.PySequence_GetItem(SeqObj, I);
    if (Item = nil) or (FPython.PyTuple_Check(Item) = false) or (FPython.PyTuple_Size(Item) < 2) then
    begin
      if Item <> nil then
        FPython.Py_DecRef(Item);
      Exit;
    end;
    try
      XObj := FPython.PyTuple_GetItem(Item, 0);
      YObj := FPython.PyTuple_GetItem(Item, 1);
      X := FPython.PyFloat_AsDouble(XObj);
      Y := FPython.PyFloat_AsDouble(YObj);
      Pts[I].X := Round(X);
      Pts[I].Y := Round(Y);
    finally
      FPython.Py_DecRef(Item);
    end;
  end;

  // draw outline only (no fill) to avoid relying on Brush.Style values
  if N >= 2 then
  begin
    SetLength(Pts, N + 1);
    Pts[N] := Pts[0];
    FOverlayCanvas.Polyline(Pts);
  end;
  Result := FPython.ReturnNone;
end;

procedure TfrmVFLineTester.InvokeOverlay(const Polygons: TVFLinePolygonArray);
var
  PolysObj, PolyObj, PtObj, Args, Res: PPyObject;
  I, J: Integer;
begin
  if (FPython = nil) or (FOverlayCallback = nil) then
    Exit;
  if FInOverlayPaint then
    Exit;
  if (FOverlayCanvas = nil) then
    Exit;

  PolysObj := nil;
  Args := nil;
  Res := nil;

  FInOverlayPaint := True;
  try
    PolysObj := FPython.PyList_New(Length(Polygons));
    if PolysObj = nil then
      Exit;

    for I := 0 to High(Polygons) do
    begin
      PolyObj := FPython.PyList_New(Length(Polygons[I]));
      if PolyObj = nil then
        Exit;
      for J := 0 to High(Polygons[I]) do
      begin
        PtObj := FPython.Py_BuildValue('(dd)', Polygons[I][J].X, Polygons[I][J].Y);
        if PtObj = nil then
          Exit;
        FPython.PyList_SetItem(PolyObj, J, PtObj);
      end;
      FPython.PyList_SetItem(PolysObj, I, PolyObj);
    end;

    Args := FPython.PyTuple_New(1);
    if Args = nil then
      Exit;
    FPython.PyTuple_SetItem(Args, 0, PolysObj);
    PolysObj := nil;

    Res := FPython.PyObject_CallObject(FOverlayCallback, Args);
    if Res = nil then
    begin
      if not FOverlayErrorShown then
      begin
        FOverlayErrorShown := True;
        FPython.PyErr_Print;
        MessageDlg('Python overlay error (see console output).', mtError, [mbOK], 0);
      end
      else
        FPython.PyErr_Clear;
    end;
  finally
    if Res <> nil then
      FPython.Py_DecRef(Res);
    if Args <> nil then
      FPython.Py_DecRef(Args);
    if PolysObj <> nil then
      FPython.Py_DecRef(PolysObj);
    FInOverlayPaint := False;
  end;
end;

procedure TfrmVFLineTester.btnPythonLibClick(Sender: TObject);
var
  Code: AnsiString;
begin
  if FPython = nil then
    Exit;

  if not ExecutePythonLibDialog(Code) then
    Exit;

  try
    if Trim(string(Code)) <> '' then
      FPython.ExecString(Code);
  except
    on E: Exception do
      MessageDlg('Python error: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

function TfrmVFLineTester.GetCurrentEvenDashScale: Double;
var
  L: TVFLineLayer;
begin
  Result := 1.0;
  if (FLineStyle = nil) or (FLineStyle.LayerCount <= 0) then
    Exit;
  L := FLineStyle.Layer[0];
  if L is TVFLinePatternLayer then
    Result := TVFLinePatternLayer(L).EvenDashThicknessScale;
end;

function TfrmVFLineTester.ExecutePythonLibDialog(out ACode: AnsiString): Boolean;
var
  Dlg: TPythonLibDialog;
  InitialScale: Double;

begin
  ACode := '';
  Result := False;

  InitialScale := GetCurrentEvenDashScale;

  Dlg := TPythonLibDialog.CreateDialog(Self);
  try
    Dlg.Init(InitialScale);

    if Dlg.ShowModal = mrOk then
    begin
      ACode := Dlg.GetCode;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TPythonLibDialog }

constructor TPythonLibDialog.CreateDialog(AOwner: TComponent);
var
  BtnRun, BtnCancel: TButton;
  LblScale: TLabel;
begin
  inherited CreateNew(AOwner);

  BorderStyle := bsSizeable;
  Position := poOwnerFormCenter;
  Caption := 'PythonLib';
  ClientWidth := 720;
  ClientHeight := 420;

  LblScale := TLabel.Create(Self);
  LblScale.Parent := Self;
  LblScale.Left := 12;
  LblScale.Top := 12;
  LblScale.Caption := 'Even dash thickness scale:';

  FTrack := TTrackBar.Create(Self);
  FTrack.Parent := Self;
  FTrack.Left := 12;
  FTrack.Top := 32;
  FTrack.Width := 520;
  FTrack.Height := 32;
  FTrack.Min := 10;
  FTrack.Max := 400;
  FTrack.Frequency := 10;
  FTrack.PageSize := 10;
  FTrack.TickStyle := tsAuto;
  FTrack.OnChange := TrackChanged;

  FEdtScale := TEdit.Create(Self);
  FEdtScale.Parent := Self;
  FEdtScale.Left := 544;
  FEdtScale.Top := 32;
  FEdtScale.Width := 80;
  FEdtScale.OnEditingDone := ScaleEditingDone;

  BtnRun := TButton.Create(Self);
  BtnRun.Parent := Self;
  BtnRun.Caption := 'Run';
  BtnRun.Left := 636;
  BtnRun.Top := 30;
  BtnRun.Width := 70;
  BtnRun.ModalResult := mrOk;

  BtnCancel := TButton.Create(Self);
  BtnCancel.Parent := Self;
  BtnCancel.Caption := 'Cancel';
  BtnCancel.Left := 636;
  BtnCancel.Top := 64;
  BtnCancel.Width := 70;
  BtnCancel.ModalResult := mrCancel;

  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.Left := 12;
  FMemo.Top := 80;
  FMemo.Width := ClientWidth - 24;
  FMemo.Height := ClientHeight - 92;
  FMemo.Anchors := [akLeft, akTop, akRight, akBottom];
  FMemo.ScrollBars := ssAutoBoth;
  FMemo.WordWrap := False;
end;

procedure TPythonLibDialog.Init(const InitialScale: Double);
begin
  FMemo.Lines.BeginUpdate;
  try
    FMemo.Lines.Clear;
    FMemo.Lines.Add('import vfline');
    FMemo.Lines.Add('vfline.set_even_dash_scale(1.00)');
  finally
    FMemo.Lines.EndUpdate;
  end;

  SyncScaleToUI(InitialScale);
end;

function TPythonLibDialog.GetCode: AnsiString;
begin
  Result := AnsiString(FMemo.Lines.Text);
end;

procedure TPythonLibDialog.TrackChanged(Sender: TObject);
var
  V: Double;
begin
  V := FTrack.Position / 100.0;
  FEdtScale.Text := FormatScaleText(V);
  UpdateScaleInMemo(FEdtScale.Text);
end;

procedure TPythonLibDialog.ScaleEditingDone(Sender: TObject);
begin
  SyncScaleToUI(ReadScaleFromUI);
end;

function TPythonLibDialog.FormatScaleText(const V: Double): string;
begin
  Result := FormatFloat('0.00', V);
end;

function TPythonLibDialog.ReadScaleFromUI: Double;
begin
  if not TryStrToFloat(Trim(FEdtScale.Text), Result) then
    Result := FTrack.Position / 100.0;
  if Result <= 0 then
    Result := 1.0;
end;

procedure TPythonLibDialog.UpdateScaleInMemo(const ScaleText: string);
var
  I, P0, P1: Integer;
  S: string;
  Prefix: string;
begin
  Prefix := 'vfline.set_even_dash_scale(';
  for I := 0 to FMemo.Lines.Count - 1 do
  begin
    S := FMemo.Lines[I];
    P0 := Pos(Prefix, S);
    if P0 > 0 then
    begin
      P1 := Pos(')', Copy(S, P0 + Length(Prefix), MaxInt));
      if P1 > 0 then
      begin
        P1 := P0 + Length(Prefix) + P1 - 1;
        FMemo.Lines[I] := Copy(S, 1, P0 + Length(Prefix) - 1) + ScaleText + Copy(S, P1, MaxInt);
      end
      else
        FMemo.Lines[I] := Copy(S, 1, P0 + Length(Prefix) - 1) + ScaleText + ')';
      Exit;
    end;
  end;
  FMemo.Lines.Add(Prefix + ScaleText + ')');
end;

procedure TPythonLibDialog.SyncScaleToUI(const V: Double);
var
  S: string;
begin
  FTrack.Position := EnsureRange(Round(V * 100.0), FTrack.Min, FTrack.Max);
  S := FormatScaleText(V);
  FEdtScale.Text := S;
  UpdateScaleInMemo(S);
end;

function TfrmVFLineTester.PySetEvenDashScale(self, args: PPyObject): PPyObject; cdecl;
var
  Scale: Double;
  L: TVFLineLayer;
  P: TVFLinePatternLayer;
begin
  Result := nil;
  if (FPython = nil) or (FLineStyle = nil) then
    Exit;
  Scale := 1.0;
  if FPython.PyArg_ParseTuple(args, 'd', @Scale) = 0 then
    Exit;

  if Scale <= 0 then
    Scale := 1.0;

  if FLineStyle.LayerCount > 0 then
  begin
    L := FLineStyle.Layer[0];
    if L is TVFLinePatternLayer then
    begin
      P := TVFLinePatternLayer(L);
      P.EvenDashThicknessScale := Scale;
      UpdatePreview;
    end;
  end;

  Result := FPython.ReturnNone;
end;

procedure TfrmVFLineTester.btnCreateStyleClick(Sender: TObject);
var
  Thickness: Double;
begin
  if not TryStrToFloat(edtThickness.Text, Thickness) then
  begin
    MessageDlg('Некорректное значение толщины.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if Thickness <= 0 then
  begin
    MessageDlg('Толщина должна быть больше нуля.', mtWarning, [mbOK], 0);
    Exit;
  end;

  CreateSolidStyle(Thickness);
end;

procedure TfrmVFLineTester.btnInitDashedClick(Sender: TObject);
var
  Thickness, DashLen, GapLen, DashOffset, TrimStart, TrimEnd: Double;
begin
  if not TryStrToFloat(edtThickness.Text, Thickness) then
    Thickness := DEFAULT_TEST_THICKNESS;
  if not TryStrToFloat(edtDash.Text, DashLen) then
    DashLen := 30;
  if not TryStrToFloat(edtGap.Text, GapLen) then
    GapLen := 12;
  if not TryStrToFloat(edtDashOffset.Text, DashOffset) then
    DashOffset := 0;
  if not TryStrToFloat(edtTrimStart.Text, TrimStart) then
    TrimStart := 0;
  if not TryStrToFloat(edtTrimEnd.Text, TrimEnd) then
    TrimEnd := 0;

  CreateDashedStyle(Thickness, DashLen, GapLen, DashOffset, TrimStart, TrimEnd);

  SetLength(FPoints, 5);
  FPoints[0] := VFPointF(60, 220);
  FPoints[1] := VFPointF(180, 160);
  FPoints[2] := VFPointF(320, 260);
  FPoints[3] := VFPointF(460, 150);
  FPoints[4] := VFPointF(580, 240);
  FInputActive := False;
  UpdatePreview;
end;

procedure TfrmVFLineTester.pbPreviewMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  case Button of
    mbLeft: AddPoint(X, Y);
    mbRight:
      begin
        if Length(FPoints) > 1 then
          FInputActive := False
        else
          ResetPolyline(False);
        UpdatePreview;
      end;
  end;
end;

procedure TfrmVFLineTester.pbPreviewPaint(Sender: TObject);
var
  I, J: Integer;
  Layer: TVFLineLayer;
  SolidLayer: TVFLineSolidLayer;
  PatternLayer: TVFLinePatternLayer;
  Polygons: TVFLinePolygonArray;
  Poly: TVFLinePolygon;
  Outline: array of TPoint;
  Trimmed: TVFLinePolygon;
begin
  pbPreview.Canvas.Brush.Color := clWhite;
  pbPreview.Canvas.FillRect(pbPreview.ClientRect);

  FOverlayCanvas := pbPreview.Canvas;

  if (FLineStyle = nil) or (FLineStyle.LayerCount = 0) or (Length(FPoints) = 0) then
    Exit;

  Layer := FLineStyle.Layer[0];

  if (Length(FPoints) > 1) and (Layer is TVFLinePatternLayer) then
  begin
    PatternLayer := TVFLinePatternLayer(Layer);
    BuildDashedPolygons(PatternLayer, FPoints, Polygons);
    pbPreview.Canvas.Brush.Style := bsSolid;
    pbPreview.Canvas.Pen.Style := psSolid;
    pbPreview.Canvas.Brush.Color := PatternLayer.Color;
    pbPreview.Canvas.Pen.Color := PatternLayer.Color;
    for I := 0 to High(Polygons) do
    begin
      Poly := Polygons[I];
      SetLength(Outline, Length(Poly));
      for J := 0 to High(Poly) do
      begin
        Outline[J].X := Round(Poly[J].X);
        Outline[J].Y := Round(Poly[J].Y);
      end;
      pbPreview.Canvas.Polygon(Outline);
    end;

    InvokeOverlay(Polygons);
    Exit;
  end;

  Trimmed := GetTrimmedPoints(FPoints, Layer.TrimStart, Layer.TrimEnd);

  if (Length(Trimmed) > 1) and (Layer is TVFLineSolidLayer) then
  begin
    SolidLayer := TVFLineSolidLayer(Layer);
   // BuildSolidPolygons(SolidLayer, Trimmed, Polygons);
    BuildSolidButtMiterPolygons2(SolidLayer, Trimmed, Polygons);
    WriteIn(['polys=', High(Polygons)]);
    if Length(Polygons) > 0 then
    begin
      pbPreview.Canvas.Brush.Color := SolidLayer.Color;
      pbPreview.Canvas.Brush.Style := bsSolid;
      pbPreview.Canvas.Pen.Color := SolidLayer.Color;
      pbPreview.Canvas.Pen.Style := psSolid;
      WriteIn(['polys=', High(Polygons)]);
      for I := 0 to High(Polygons) do begin
        Poly := Polygons[I];
        WriteIn(['Points=', High(Poly)]);
        SetLength(Outline, Length(Poly));
        for J := 0 to High(Poly) do begin
          {
         If J = 0 then pbPreview.Canvas.MoveTo(Round(Poly[J].X), Round(Poly[J].Y))
          else
           pbPreview.Canvas.LineTo(Round(Poly[J].X), Round(Poly[J].Y));
          }
          Outline[J].X := Round(Poly[J].X);
          Outline[J].Y := Round(Poly[J].Y);
        end;
       pbPreview.Canvas.Brush.Color := SolidLayer.Color;
       pbPreview.Canvas.Polygon(Outline)
      end;
      {
      for Poly in Polygons do
      begin
        SetLength(Outline, Length(Poly));
        for J := 0 to High(Poly) do
        begin
          Outline[J].X := Round(Poly[J].X);
          Outline[J].Y := Round(Poly[J].Y);
        end;
        pbPreview.Canvas.Polygon(Outline);
      end;
      }
    end
    else
    begin
      pbPreview.Canvas.Pen.Color := Layer.Color;
      pbPreview.Canvas.Pen.Width := 0; Max(1, Round(Layer.BaseThickness));
      pbPreview.Canvas.MoveTo(Round(FPoints[0].X), Round(FPoints[0].Y));
      for I := 1 to High(FPoints) do
        pbPreview.Canvas.LineTo(Round(FPoints[I].X), Round(FPoints[I].Y));
    end;
  end;

{  for I := 0 to High(FPoints) do
  begin
    pbPreview.Canvas.Brush.Color := clMaroon;
    pbPreview.Canvas.Pen.Color := clMaroon;
    pbPreview.Canvas.Ellipse(Round(FPoints[I].X) - 3, Round(FPoints[I].Y) - 3,
      Round(FPoints[I].X) + 3, Round(FPoints[I].Y) + 3);
  end;
}
end;

function TfrmVFLineTester.GetTrimmedPoints(const Src: TVFLinePolygon;
  const TrimStart, TrimEnd: Double): TVFLinePolygon;
const
  EPS = 1e-6;
var
  I: Integer;
  TotalLen, CutStart, CutEnd: Double;
  Acc, SegLen: Double;
  P0, P1: TPointF;
  DX, DY: Double;
  T0, T1: Double;
  A, B: TPointF;
  N: Integer;

  procedure AddPoint(const P: TPointF);
  begin
    N := Length(Result);
    if (N = 0) or (Abs(Result[N - 1].X - P.X) > 1e-9) or (Abs(Result[N - 1].Y - P.Y) > 1e-9) then
    begin
      SetLength(Result, N + 1);
      Result[N] := P;
    end;
  end;

begin
  Result := nil;
  if Length(Src) < 2 then
    Exit;

  TotalLen := 0;
  for I := 0 to High(Src) - 1 do
    TotalLen := TotalLen + Hypot(Src[I + 1].X - Src[I].X, Src[I + 1].Y - Src[I].Y);
  if TotalLen <= EPS then
    Exit;

  CutStart := Max(0, TrimStart);
  CutEnd := Max(0, TrimEnd);
  if CutStart + CutEnd >= TotalLen - EPS then
    Exit;

  Acc := 0;
  for I := 0 to High(Src) - 1 do
  begin
    P0 := Src[I];
    P1 := Src[I + 1];
    DX := P1.X - P0.X;
    DY := P1.Y - P0.Y;
    SegLen := Hypot(DX, DY);
    if SegLen <= EPS then
      Continue;

    T0 := 0;
    T1 := 1;

    if CutStart > Acc + EPS then
      T0 := (CutStart - Acc) / SegLen;
    if (TotalLen - CutEnd) < (Acc + SegLen - EPS) then
      T1 := (TotalLen - CutEnd - Acc) / SegLen;

    if T1 <= 0 then
      Break;
    if T0 >= 1 then
    begin
      Acc := Acc + SegLen;
      Continue;
    end;

    T0 := EnsureRange(T0, 0, 1);
    T1 := EnsureRange(T1, 0, 1);
    if T1 <= T0 + 1e-12 then
    begin
      Acc := Acc + SegLen;
      Continue;
    end;

    A.X := P0.X + DX * T0;
    A.Y := P0.Y + DY * T0;
    B.X := P0.X + DX * T1;
    B.Y := P0.Y + DY * T1;

    AddPoint(A);
    AddPoint(B);

    Acc := Acc + SegLen;
    if T1 < 1 - 1e-12 then
      Break;
  end;
end;

procedure TfrmVFLineTester.CreateSolidStyle(const AThickness: Double);
var
  Layer: TVFLineSolidLayer;
  Thickness: Double;
begin
  Thickness := AThickness;
  if Thickness <= 0 then
    Thickness := DEFAULT_TEST_THICKNESS;

  if FLineStyle = nil then
    FLineStyle := TVFLineStyle.Create
  else
    FLineStyle.ClearLayers;

  Layer := FLineStyle.AddSolidLayer;
  Layer.BaseThickness := Thickness;
  Layer.Color := clNavy;
  Layer.CapKind := lckButt;
//  Layer.JoinKind := ljkBevel;

  FLineStyle.UpdateThinFlag(1.0);
  UpdatePreview;
end;

procedure TfrmVFLineTester.CreateDashedStyle(const AThickness, ADash, AGap,
  ADashOffset, ATrimStart, ATrimEnd: Double);
var
  Layer: TVFLinePatternLayer;
  Thickness: Double;
begin
  Thickness := AThickness;
  if Thickness <= 0 then
    Thickness := DEFAULT_TEST_THICKNESS;

  if FLineStyle = nil then
    FLineStyle := TVFLineStyle.Create
  else
    FLineStyle.ClearLayers;

  Layer := TVFLinePatternLayer(FLineStyle.AddPatternLayer);
  Layer.BaseThickness := Thickness;
  Layer.Color := clNavy;
  Layer.CapKind := lckButt;
  Layer.JoinKind := ljkMiter;
  Layer.DashOffset := ADashOffset;
  Layer.DashPattern.Clear;
  Layer.DashPattern.AddSegment(Abs(ADash));
  Layer.DashPattern.AddSegment(Abs(AGap));
  Layer.SetTrimRange(ATrimStart, ATrimEnd);

  FLineStyle.UpdateThinFlag(1.0);
  UpdatePreview;
end;

procedure TfrmVFLineTester.ResetPolyline(const KeepPoints: Boolean);
begin
  if not KeepPoints then
    SetLength(FPoints, 0);
  FInputActive := True;
  UpdatePreview;
end;

function PointF(X, Y: Double): TPointF;
begin
 Result.X := X; Result.Y := Y;
end;

procedure TfrmVFLineTester.AddPoint(const AX, AY: Integer);
var
  NewIndex: Integer;
begin
  if not FInputActive then
    ResetPolyline(False);

  NewIndex := Length(FPoints);
  SetLength(FPoints, NewIndex + 1);
  FPoints[NewIndex] := PointF(AX, AY);
  UpdatePreview;
end;

procedure TfrmVFLineTester.UpdatePreview;
begin
  if Assigned(pbPreview) then
    pbPreview.Invalidate;
end;

end.
