unit uLas3DViewerForm;

{$mode Delphi}{$H+}

interface

uses
 Classes, SysUtils, Windows, Forms, Controls, ExtCtrls, StdCtrls, ComCtrls,
 OpenGLPanel, ogcLas, Types, uLasPointCloudGpu, uLasPointCloudTiles, Spin, dglOpenGL, GLU;

type

 { TLas3DViewerForm }

 TLas3DViewerForm = class(TForm)
 published
  cbPlane: TCheckBox;
  cbPlaneCapture: TCheckBox;
  DrawTileBoxes: TCheckBox;
  Label1: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  Label4: TLabel;
  LODBtn: TButton;
  PanelXY: TPanel;
  ProgressBar1: TProgressBar;
  ResetBtn: TButton;
  OGL: TOpenGLPanel;
  PlaneDistEdit: TFloatSpinEdit;
  PlaneSizeSpin: TFloatSpinEdit;
  RayRadiusSpin: TFloatSpinEdit;
  MoveTimer: TTimer;
  AlphaBar: TTrackBar;
  BlendCheck: TCheckBox;
  Mode2DCheck: TCheckBox;
  BottomPanel: TPanel;
  LevelSpin: TFloatSpinEdit;
  PlaneShowCheck: TCheckBox;
  PlaneZSpin: TFloatSpinEdit;
  TopPanel: TPanel;
  ZMaxLabel: TLabel;
  ZMinLabel: TLabel;
  procedure cbPlaneCaptureChange(Sender: TObject);
  procedure cbPlaneChange(Sender: TObject);
  procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure Label1Click(Sender: TObject);
  procedure Label3Click(Sender: TObject);
  procedure LODBtnClick(Sender: TObject);
  procedure OGLClick(Sender: TObject);
  procedure ResetBtnClick(Sender: TObject);
  procedure PlaneSizeChanged(Sender: TObject);
  procedure DrawTileBoxesChange(Sender: TObject);
  procedure MoveTimerTimer(Sender: TObject);
  procedure OGLPaint(Sender: TObject);
  procedure OGLMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure OGLMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  procedure OGLMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure OGLMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  procedure UIChanged(Sender: TObject);
  procedure LevelChanged(Sender: TObject);
  procedure PlaneChanged(Sender: TObject);
 //
  procedure FormCreate(Sender: TObject);
  procedure FormDestroy(Sender: TObject);
  procedure OGLResize(Sender: TObject);
  procedure OGLPaintInitBaseFrame(Sender: TObject);
 private
  FLas: TogsLas;

  FTiles: TLasPointCloudTiles;
  FTilesBuilt: Boolean;

  FUpdatingUI: Boolean;

  FPanX: Double;
  FPanY: Double;
  FPanZ: Double;

  FDown: Boolean;
  FDownButton: TMouseButton;
  FLastX: Integer;
  FLastY: Integer;
  FYaw: Double;
  FPitch: Double;
  FRoll: Double;
  FDistance: Double;
  FFovDeg: Double;

  FOrthoScale: Double;

  FGLInited: Boolean;

  FLevelUpdating: Boolean;
  FUserLevelMeters: Double;

  FMouseX: Integer;
  FMouseY: Integer;
  FMouseValid: Boolean;

  FPickQx: Double;
  FPickQy: Double;
  FPickQz: Double;
  FPickValid: Boolean;
  FPickTick: QWord;
  FPickPtX: Double;
  FPickPtY: Double;
  FPickPtZ: Double;
  FPickPtValid: Boolean;
  FPickDirty: Boolean;

  FPanGrabActive: Boolean;
  FPanGrabDepth: Single;
  FPanGrabX: Double;
  FPanGrabY: Double;
  FPanGrabZ: Double;
  FPanGrabStartPanX: Double;
  FPanGrabStartPanY: Double;
  FPanGrabStartPanZ: Double;
  FPanGrabMV: array[0..15] of GLdouble;
  FPanGrabProj: array[0..15] of GLdouble;
  FPanGrabViewport: array[0..3] of GLint;

  FBaseFBO: GLuint;
  FBaseTexture: GLuint;
  FBaseDepth: GLuint;
  FBaseWidth: Integer;
  FBaseHeight: Integer;
  FBaseDirty: Boolean;

  FBaseMaxPoints: Int64;

  FFontBase: TGLuint;
  FFpsLastTick: QWord;
  FFpsFrames: Integer;
  FFpsValue: Single;
 //
  PlaneValue: Double;
 //
  FLastInteractTick: QWord;
  FWasMoving: Boolean;
  FProgStartTick: QWord;
  FProgActive: Boolean;
 //
  function BlendAlpha: Byte;
  function BlendEnabled: Boolean;
  function PointSize: Integer;
  function LevelZ: Double;
  function PlanePickDist: Double;
  function PlanePickZRadius: Double;
  function PerspectiveNear: Double;
  procedure GetLevelPlaneNormal(out NX, NY, NZ: Double);
  procedure SyncUIFromCamera;
  procedure ClampCamera;
  procedure SyncLevelUI;

  procedure UpdateOglCursor;

  procedure ApplyManualLod;

  procedure ResetView;
  procedure LoadUiState;
  procedure SaveUiState;

  procedure TilesProgress(Sender: TObject; APos, AMax: Integer);

  procedure InitBaseFrame;
  procedure ResizeBaseFrame(AWidth, AHeight: Integer);
  procedure FreeBaseFrame;
  procedure RenderBaseFrame;
  procedure RenderOverlay;
  procedure UpdatePickState;

  function FindNearestDepthInFbo(AX, AY: Integer; ARadiusPx: Integer; out XHit, YHit: Integer; out Depth: Single): Boolean;

  procedure InvalidateBase;

  procedure UpdatePanelXY;

  procedure InitGlFont;
  procedure DrawGlText2D(AX, AY: Integer; const S: AnsiString);
 public
  procedure SetLas(ALas: TogsLas);
 end;

implementation uses ogcWriter, Math, IniFiles;

{$R *.frm}

function TLas3DViewerForm.FindNearestDepthInFbo(AX, AY: Integer; ARadiusPx: Integer; out XHit, YHit: Integer; out Depth: Single): Boolean;
var
 x0, y0, w, h: Integer;
 fx0, fy0: Integer;
 buf: array of Single;
 i, ix, iy, row: Integer;
 d: Single;
 bestD: Single;
 bestX, bestY: Integer;
begin
 Result := False;
 XHit := AX;
 YHit := AY;
 Depth := 1;

 if (FBaseFBO = 0) or (FBaseWidth <= 0) or (FBaseHeight <= 0) then Exit;
 if ARadiusPx < 0 then ARadiusPx := 0;

 x0 := AX - ARadiusPx;
 y0 := AY - ARadiusPx;
 w := 2 * ARadiusPx + 1;
 h := 2 * ARadiusPx + 1;
 if x0 < 0 then x0 := 0;
 if y0 < 0 then y0 := 0;
 if x0 + w > FBaseWidth then w := FBaseWidth - x0;
 if y0 + h > FBaseHeight then h := FBaseHeight - y0;
 if (w <= 0) or (h <= 0) then Exit;

 fx0 := x0;
 fy0 := FBaseHeight - (y0 + h);
 if fy0 < 0 then fy0 := 0;

 SetLength(buf, w * h);
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, FBaseFBO);
 glReadPixels(fx0, fy0, w, h, GL_DEPTH_COMPONENT, GL_FLOAT, @buf[0]);
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

 bestD := 1;
 bestX := AX;
 bestY := AY;
 for i := 0 to (w * h - 1) do
 begin
  d := buf[i];
  if (d > 0) and (d < bestD) then
  begin
   ix := i mod w;
   row := i div w;
   iy := (h - 1) - row;
   bestD := d;
   bestX := x0 + ix;
   bestY := y0 + iy;
  end;
 end;

 if (bestD > 0) and (bestD < 1) then
 begin
  Result := True;
  Depth := bestD;
  XHit := bestX;
  YHit := bestY;
 end;

end;

procedure TLas3DViewerForm.FormCreate(Sender: TObject);
begin
 FYaw := 0;
 FPitch := 0;
 FRoll := 0;
 FDistance := 200;
 FFovDeg := 45;
 FOrthoScale := 1;
 FPanX := 0;
 FPanY := 0;
 FPanZ := 0;
 FGLInited := False;

 FLevelUpdating := False;
 FUserLevelMeters := 0;
 FMouseValid := False;

 FPickValid := False;
 FPickTick := 0;
 FPickPtValid := False;
 FPickDirty := True;

 FPanGrabActive := False;
 FPanGrabDepth := 0;
 FPanGrabX := 0;
 FPanGrabY := 0;
 FPanGrabZ := 0;
 FPanGrabStartPanX := 0;
 FPanGrabStartPanY := 0;
 FPanGrabStartPanZ := 0;

 FBaseFBO := 0;
 FBaseTexture := 0;
 FBaseDepth := 0;
 FBaseWidth := 0;
 FBaseHeight := 0;
 FBaseDirty := True;

 FBaseMaxPoints := 0;

 FFontBase := 0;
 FFpsLastTick := 0;
 FFpsFrames := 0;
 FFpsValue := 0;

 FLastInteractTick := 0;
 FWasMoving := False;
 FProgStartTick := 0;
 FProgActive := False;

 FTiles := TLasPointCloudTiles.Create;
 FTiles.OnProgress := TilesProgress;
 FTiles.ColorMode := lpcmIntensity;
 FTilesBuilt := False;

 if DrawTileBoxes <> nil then
  FTiles.DrawTileBBoxes := DrawTileBoxes.Checked;

 if OGL <> nil then
  OGL.OnResize := OGLResize;

 if MoveTimer <> nil then
 begin
  MoveTimer.Interval := 30;
  MoveTimer.OnTimer := MoveTimerTimer;
  MoveTimer.Enabled := True;
 end;

 ClampCamera;
 SyncUIFromCamera;
 SyncLevelUI;
 LoadUiState;
 UpdateOglCursor;
 If not InitOpenGL then
  raise Exception.Create('noInitGL');
end;

procedure TLas3DViewerForm.FormDestroy(Sender: TObject);
begin
 SaveUiState;
 if FTiles <> nil then
 begin
  if (OGL <> nil) and OGL.HandleAllocated then
   try
    if OGL.MakeCurrent then
    begin
     FTiles.ReleaseGL;
     if FFontBase <> 0 then
     begin
      glDeleteLists(FFontBase, 256);
      FFontBase := 0;
     end;
     FreeBaseFrame;
    end;
   except
   end;
  FreeAndNil(FTiles);
 end;
end;

procedure TLas3DViewerForm.ResetView;
begin
 FPanX := 0;
 FPanY := 0;
 FPanZ := 0;
 FYaw := 0;
 FPitch := 0;
 FRoll := 0;
 FFovDeg := 45;
 FOrthoScale := 1;
 FBaseMaxPoints := 0;
 ClampCamera;
 SyncUIFromCamera;
 InvalidateBase;
end;

procedure TLas3DViewerForm.LoadUiState;
var ini: TIniFile;
    fn: AnsiString;
begin
 fn := ChangeFileExt(Application.ExeName, '.ini');
 ini := TIniFile.Create(fn);
 try
  FUpdatingUI := True;
  try
   BlendCheck.Checked := ini.ReadBool('Las3D', 'Blend', BlendCheck.Checked);
   AlphaBar.Position := ini.ReadInteger('Las3D', 'Alpha', AlphaBar.Position);
//   PointSizeBox.ItemIndex := ini.ReadInteger('Las3D', 'PointSize', PointSizeBox.ItemIndex);
   Mode2DCheck.Checked := ini.ReadBool('Las3D', 'Mode2D', Mode2DCheck.Checked);

   LevelSpin.Value := ini.ReadFloat('Las3D', 'Level', LevelSpin.Value);
   PlaneShowCheck.Checked := ini.ReadBool('Las3D', 'PlaneShow', PlaneShowCheck.Checked);
  // PlaneAlphaSpin.Value := ini.ReadFloat('Las3D', 'PlaneAlpha', PlaneAlphaSpin.Value);
   PlaneDistEdit.Value := ini.ReadFloat('Las3D', 'PickRadius', PlaneDistEdit.Value);
   PlaneZSpin.Value := ini.ReadFloat('Las3D', 'PickZRadius', PlaneZSpin.Value);
   PlaneSizeSpin.Value := ini.ReadFloat('Las3D', 'PickPointSize', PlaneSizeSpin.Value);
   if RayRadiusSpin <> nil then
    RayRadiusSpin.Value := ini.ReadFloat('Las3D', 'RayRadius', RayRadiusSpin.Value);
   if cbPlaneCapture <> nil then
    cbPlaneCapture.Checked := ini.ReadBool('Las3D', 'PlaneCapture', cbPlaneCapture.Checked);
   cbPlane.Checked := ini.ReadBool('Las3D', 'PickLock', cbPlane.Checked);
   PlaneValue := ini.ReadFloat('Las3D', 'PickLockValue', PlaneValue);
  finally
   FUpdatingUI := False;
  end;

  UIChanged(nil);
  LevelChanged(nil);
  PlaneChanged(nil);
  UpdateOglCursor;
 finally
  ini.Free;
 end;
end;

procedure TLas3DViewerForm.SaveUiState;
var ini: TIniFile;
    fn: AnsiString;
begin
 fn := ChangeFileExt(Application.ExeName, '.ini');
 ini := TIniFile.Create(fn);
 try
  ini.WriteBool('Las3D', 'Blend', BlendCheck.Checked);
  ini.WriteInteger('Las3D', 'Alpha', AlphaBar.Position);
//  ini.WriteInteger('Las3D', 'PointSize', PointSizeBox.ItemIndex);
  ini.WriteBool('Las3D', 'Mode2D', Mode2DCheck.Checked);

  ini.WriteFloat('Las3D', 'Level', LevelSpin.Value);
  ini.WriteBool('Las3D', 'PlaneShow', PlaneShowCheck.Checked);
 // ini.WriteFloat('Las3D', 'PlaneAlpha', PlaneAlphaSpin.Value);
  ini.WriteFloat('Las3D', 'PickRadius', PlaneDistEdit.Value);
  ini.WriteFloat('Las3D', 'PickZRadius', PlaneZSpin.Value);
  ini.WriteFloat('Las3D', 'PickPointSize', PlaneSizeSpin.Value);
  if RayRadiusSpin <> nil then
   ini.WriteFloat('Las3D', 'RayRadius', RayRadiusSpin.Value);
  if cbPlaneCapture <> nil then
   ini.WriteBool('Las3D', 'PlaneCapture', cbPlaneCapture.Checked);
  ini.WriteBool('Las3D', 'PickLock', cbPlane.Checked);
  ini.WriteFloat('Las3D', 'PickLockValue', PlaneValue);
 finally
  ini.Free;
 end;
end;

procedure TLas3DViewerForm.TilesProgress(Sender: TObject; APos, AMax: Integer);
begin
 if ProgressBar1 = nil then Exit;
 if AMax <= 0 then Exit;
 ProgressBar1.Visible := True;
 ProgressBar1.Min := 0;
 ProgressBar1.Max := AMax;
 if APos < 0 then APos := 0;
 if APos > AMax then APos := AMax;
 ProgressBar1.Position := APos;
 ProgressBar1.Update;
 if APos >= AMax then
  ProgressBar1.Visible := False;
end;

procedure TLas3DViewerForm.InitBaseFrame;
begin

end;

procedure TLas3DViewerForm.UpdateOglCursor;
begin
 if OGL = nil then Exit;
 if (cbPlane <> nil) and cbPlane.Checked then
  OGL.Cursor := crNone
 else
  OGL.Cursor := crDefault;
end;

procedure TLas3DViewerForm.InitGlFont;
var
 dc: HDC;
begin
 if FFontBase <> 0 then Exit;

 if not Assigned(glGenLists) then Exit;
 if not Assigned(wglUseFontBitmaps) then Exit;

 dc := wglGetCurrentDC;
 if dc = 0 then Exit;
 FFontBase := glGenLists(256);
 if FFontBase = 0 then Exit;
 wglUseFontBitmaps(dc, 0, 256, FFontBase);
end;

procedure TLas3DViewerForm.DrawGlText2D(AX, AY: Integer; const S: AnsiString);
begin
 if (FFontBase = 0) or (S = '') then Exit;

 glMatrixMode(GL_PROJECTION);
 glPushMatrix;
 glLoadIdentity;
 glOrtho(0, OGL.Width, 0, OGL.Height, -1, 1);

 glMatrixMode(GL_MODELVIEW);
 glPushMatrix;
 glLoadIdentity;

 glDisable(GL_DEPTH_TEST);
 glDisable(GL_BLEND);
 glColor4f(1, 1, 1, 1);
 glRasterPos2i(AX, AY);
 glListBase(FFontBase);
 glCallLists(Length(S), GL_UNSIGNED_BYTE, PAnsiChar(S));

 glMatrixMode(GL_MODELVIEW);
 glPopMatrix;
 glMatrixMode(GL_PROJECTION);
 glPopMatrix;
 glMatrixMode(GL_MODELVIEW);
 glEnable(GL_DEPTH_TEST);
end;

procedure TLas3DViewerForm.SetLas(ALas: TogsLas);
begin
 FLas := ALas;
 FTilesBuilt := False;
 FBaseMaxPoints := 0;
 if (FLas <> nil) and (FLas.Source <> nil) and (FLas.Source.IsOpen) then
 begin
  FDistance := Max(FLas.Source.Header.MaxX - FLas.Source.Header.MinX,
                   FLas.Source.Header.MaxY - FLas.Source.Header.MinY);
  if FDistance <= 0 then FDistance := 200;
  FDistance := FDistance * 1.5;

  FOrthoScale := 1;
 end;
 ClampCamera;
 SyncUIFromCamera;
 SyncLevelUI;
 InvalidateBase;
end;

function TLas3DViewerForm.BlendAlpha: Byte;
begin
 Result := Byte(AlphaBar.Position);
end;

function TLas3DViewerForm.BlendEnabled: Boolean;
begin
 Result := BlendCheck.Checked;
end;

function TLas3DViewerForm.PointSize: Integer;
begin
 Result := 1;
 {
 case PointSizeBox.ItemIndex of
  1: Result := 2;
  2: Result := 3;
  3: Result := 4;
 else
  Result := 1;
 end;
 }
end;

procedure TLas3DViewerForm.DrawTileBoxesChange(Sender: TObject);
begin
 if FTiles <> nil then
  FTiles.DrawTileBBoxes := (DrawTileBoxes <> nil) and DrawTileBoxes.Checked;
 OGL.Invalidate;
end;

function TLas3DViewerForm.LevelZ: Double;
begin
 if (FLas <> nil) and (FLas.Source <> nil) and (FLas.Source.IsOpen) then
  Result := FLas.Source.Header.MinZ + FUserLevelMeters
 else
  Result := 0;
end;

function TLas3DViewerForm.PlanePickDist: Double;
var s: String;
begin
 Result := 0;
 if PlaneDistEdit = nil then Exit;
 s := Trim(PlaneDistEdit.Text);
 if s = '' then Exit;
 try
  Result := StrToFloat(s);
 except
  Result := 0;
 end;
 if Result < 0 then Result := 0;
end;

function TLas3DViewerForm.PlanePickZRadius: Double;
begin
 Result := 0;
 if PlaneZSpin = nil then Exit;
 Result := PlaneZSpin.Value;
 if Result < 0 then Result := 0;
end;

function TLas3DViewerForm.PerspectiveNear: Double;
begin
 Result := EnsureRange(FDistance * 0.001, 0.000001, 0.1);
end;

procedure TLas3DViewerForm.GetLevelPlaneNormal(out NX, NY, NZ: Double);
begin
 NX := 0;
 NY := 0;
 NZ := 1;
end;

procedure TLas3DViewerForm.SyncUIFromCamera;
begin
 FUpdatingUI := True;
 try
  if Mode2DCheck <> nil then
   Mode2DCheck.Checked := False;
  if BlendCheck <> nil then
   BlendCheck.Checked := False;
  if AlphaBar <> nil then
   AlphaBar.Position := 255;
//  if PointSizeBox <> nil then
 //  PointSizeBox.ItemIndex := 0;
 finally
  FUpdatingUI := False;
 end;

 UIChanged(nil);
 LevelChanged(nil);
 PlaneChanged(nil);
end;

procedure TLas3DViewerForm.ClampCamera;
begin
 if FPitch < -89 then FPitch := -89;
 if FPitch > 89 then FPitch := 89;
 if FFovDeg < 10 then FFovDeg := 10;
 if FFovDeg > 120 then FFovDeg := 120;
 if FDistance < 0.000001 then FDistance := 0.000001;
end;

procedure TLas3DViewerForm.SyncLevelUI;
begin
 if LevelSpin = nil then Exit;
 FLevelUpdating := True;
 try
  LevelSpin.Value := FUserLevelMeters;
 finally
  FLevelUpdating := False;
 end;

 if (ZMinLabel <> nil) and (ZMaxLabel <> nil) then
 begin
  if (FLas <> nil) and (FLas.Source <> nil) and (FLas.Source.IsOpen) then
  begin
   ZMinLabel.Caption := 'ZMin ' + FloatToStrF(FLas.Source.Header.MinZ, ffGeneral, 12, 6);
   ZMaxLabel.Caption := 'ZMax ' + FloatToStrF(FLas.Source.Header.MaxZ, ffGeneral, 12, 6);
  end
  else
  begin
   ZMinLabel.Caption := 'ZMin';
   ZMaxLabel.Caption := 'ZMax';
  end;
 end;
end;

procedure TLas3DViewerForm.LevelChanged(Sender: TObject);
begin
 if FLevelUpdating then Exit;

 if Sender = LevelSpin then
 begin
  FUserLevelMeters := LevelSpin.Value;
  InvalidateBase;
 end;
end;

procedure TLas3DViewerForm.cbPlaneChange(Sender: TObject);
begin
 If cbPlane.Checked then
  If PlaneValue = 0 then
   PlaneDistEdit.Value := 0.2 else
    PlaneDistEdit.Value := PlaneValue
 else begin
  PlaneValue := PlaneDistEdit.Value;
  PlaneDistEdit.Value := 0;
 end;
 UpdateOglCursor;
 OGL.Invalidate;
end;

procedure TLas3DViewerForm.cbPlaneCaptureChange(Sender: TObject);
begin

end;

procedure TLas3DViewerForm.FormKeyDown(Sender: TObject; var Key: Word;
 Shift: TShiftState);
begin
 If Key = 81 then LevelSpin.Value := LevelSpin.Value + LevelSpin.Increment;
 If Key = 65 then LevelSpin.Value := LevelSpin.Value - LevelSpin.Increment;
end;

procedure TLas3DViewerForm.Label1Click(Sender: TObject);
begin

end;

procedure TLas3DViewerForm.Label3Click(Sender: TObject);
begin

end;

procedure TLas3DViewerForm.LODBtnClick(Sender: TObject);
begin
 ApplyManualLod;
end;

procedure TLas3DViewerForm.OGLClick(Sender: TObject);
begin

end;

procedure TLas3DViewerForm.ResetBtnClick(Sender: TObject);
begin
 ResetView;
end;

procedure TLas3DViewerForm.PlaneSizeChanged(Sender: TObject);
begin
 if FUpdatingUI then Exit;
 OGL.Invalidate;
end;

procedure TLas3DViewerForm.PlaneChanged(Sender: TObject);
begin
 InvalidateBase;
end;

procedure TLas3DViewerForm.UIChanged(Sender: TObject);
begin
 if FUpdatingUI then Exit;
 ClampCamera;
 SyncUIFromCamera;
 InvalidateBase;
end;

procedure TLas3DViewerForm.OGLMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if (Button = mbMiddle) and (ssDouble in Shift) then
 begin
  ResetView;
  Exit;
 end;

 FDown := True;
 FDownButton := Button;
 FLastX := X;
 FLastY := Y;
end;

procedure TLas3DViewerForm.OGLMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
 dx, dy: Integer;
 worldPerPixel: Double;
begin
 FMouseX := X;
 FMouseY := Y;
 FMouseValid := True;
 OGL.Invalidate;
 if not FDown then Exit;
 dx := X - FLastX;
 dy := Y - FLastY;
 FLastX := X;
 FLastY := Y;

 if FDownButton = mbLeft then
 begin
  if OGL = nil then Exit;
  worldPerPixel := (2.0 * FDistance * Tan((FFovDeg * Pi / 180.0) * 0.5)) / Max(1, OGL.Height);
  FPanX := FPanX + dx * worldPerPixel;
  FPanY := FPanY - dy * worldPerPixel;
 end
 else
 begin
  if (Mode2DCheck <> nil) and (not Mode2DCheck.Checked) then
  begin
   FYaw := FYaw + dx * 0.5;
   FPitch := FPitch + dy * 0.5;
   ClampCamera;
   SyncUIFromCamera;
  end;
 end;
 OGL.Invalidate;
end;

procedure TLas3DViewerForm.OGLMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if Button <> FDownButton then Exit;
 FDown := False;
end;

procedure TLas3DViewerForm.OGLMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
 if Mode2DCheck <> nil then
 begin
  if Mode2DCheck.Checked then
  begin
   if WheelDelta > 0 then FOrthoScale := FOrthoScale * 0.9 else FOrthoScale := FOrthoScale * 1.1;
   if FOrthoScale < 0.000001 then FOrthoScale := 0.000001;
  end
  else
  begin
   if ssShift in Shift then
   begin
    if WheelDelta > 0 then FFovDeg := FFovDeg - 2 else FFovDeg := FFovDeg + 2;
   end
   else
   begin
    if WheelDelta > 0 then
     FDistance := FDistance * 0.9
    else
     FDistance := FDistance * 1.1;
   end;
  end;
 end;
 ClampCamera;
 SyncUIFromCamera;
 Handled := True;
 OGL.Invalidate;
end;

procedure TLas3DViewerForm.OGLResize(Sender: TObject);
begin
 if not OGL.MakeCurrent then Exit;
 if not FGLInited then Exit;
 InitBaseFrame;
 ResizeBaseFrame(OGL.Width, OGL.Height);
end;

procedure TLas3DViewerForm.OGLPaintInitBaseFrame(Sender: TObject);
begin
 if (FBaseFBO <> 0) and (FBaseTexture <> 0) then Exit;
 if not Assigned(glGenFramebuffersEXT) then Exit;
 if not Assigned(glBindFramebufferEXT) then Exit;
 if not Assigned(glFramebufferTexture2DEXT) then Exit;
 if not Assigned(glDeleteFramebuffersEXT) then Exit;
 if not Assigned(glGenRenderbuffersEXT) then Exit;
 if not Assigned(glBindRenderbufferEXT) then Exit;
 if not Assigned(glRenderbufferStorageEXT) then Exit;
 if not Assigned(glFramebufferRenderbufferEXT) then Exit;
 if not Assigned(glDeleteRenderbuffersEXT) then Exit;

 glGenFramebuffersEXT(1, @FBaseFBO);
 glGenTextures(1, @FBaseTexture);
 glGenRenderbuffersEXT(1, @FBaseDepth);
 ResizeBaseFrame(OGL.Width, OGL.Height);
end;

procedure TLas3DViewerForm.ResizeBaseFrame(AWidth, AHeight: Integer);
begin
 if (AWidth <= 0) or (AHeight <= 0) then Exit;
 if (FBaseWidth = AWidth) and (FBaseHeight = AHeight) then Exit;
 if FBaseFBO = 0 then Exit;
 if FBaseTexture = 0 then Exit;
 if FBaseDepth = 0 then Exit;

 if FBaseTexture <> 0 then glDeleteTextures(1, @FBaseTexture);
 glGenTextures(1, @FBaseTexture);
 glBindTexture(GL_TEXTURE_2D, FBaseTexture);
 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, AWidth, AHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
 glBindTexture(GL_TEXTURE_2D, 0);

 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, FBaseFBO);
 glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, FBaseTexture, 0);

 glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, FBaseDepth);
 glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, AWidth, AHeight);
 glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, FBaseDepth);
 glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0);

 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

 FBaseWidth := AWidth;
 FBaseHeight := AHeight;
 InvalidateBase;
end;

procedure TLas3DViewerForm.FreeBaseFrame;
begin
 if FBaseTexture <> 0 then
 begin
  glDeleteTextures(1, @FBaseTexture);
  FBaseTexture := 0;
 end;
 if FBaseDepth <> 0 then
 begin
  if Assigned(glDeleteRenderbuffersEXT) then
   glDeleteRenderbuffersEXT(1, @FBaseDepth);
  FBaseDepth := 0;
 end;
 if FBaseFBO <> 0 then
 begin
  if Assigned(glDeleteFramebuffersEXT) then
   glDeleteFramebuffersEXT(1, @FBaseFBO);
  FBaseFBO := 0;
 end;
 FBaseWidth := 0;
 FBaseHeight := 0;
end;

procedure TLas3DViewerForm.InvalidateBase;
begin
 FBaseDirty := True;
 FPickDirty := True;
 OGL.Invalidate;
end;

procedure TLas3DViewerForm.UpdatePanelXY;
begin

end;

procedure TLas3DViewerForm.RenderBaseFrame;
var
 cx, cy, cz: Double;
 sizeX, sizeY: Double;
 halfX, halfY: Double;
 zRange: Double;
 proj, mv, mvp: TMat4;
 colA: Single;
 clipEnabled: Boolean;
 qz: Double;
 tick0, tick1: QWord;
 buildNowMax: Int64;
 moving: Boolean;
 progT: Single;
 progNow: Boolean;
 progFrac: Single;
begin
 if (FLas = nil) or (FLas.Source = nil) or (not FLas.Source.IsOpen) then Exit;
 if (FBaseFBO = 0) or (FBaseTexture = 0) then Exit;
 if (FBaseWidth <= 0) or (FBaseHeight <= 0) then Exit;

 tick0 := GetTickCount64;
 moving := (FLastInteractTick <> 0) and (tick0 >= FLastInteractTick) and ((tick0 - FLastInteractTick) <= 250);

 if moving then
  FProgActive := False;
 progNow := (not moving) and FProgActive;
 if progNow then
 begin
  if tick0 <= FProgStartTick then
   progT := 0
  else
   progT := EnsureRange((tick0 - FProgStartTick) / 250.0, 0.0, 1.0);
  if progT >= 1 then
   FProgActive := False;
 end
 else
  progT := 1;
 progFrac := 0.2 + (1.0 - 0.2) * progT;

 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, FBaseFBO);
 glViewport(0, 0, FBaseWidth, FBaseHeight);
 glClearColor(0.5, 0.5, 0.5, 1);
 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
 glEnable(GL_DEPTH_TEST);

 cx := (FLas.Source.Header.MinX + FLas.Source.Header.MaxX) * 0.5;
 cy := (FLas.Source.Header.MinY + FLas.Source.Header.MaxY) * 0.5;
 cz := (FLas.Source.Header.MinZ + FLas.Source.Header.MaxZ) * 0.5;

 glMatrixMode(GL_PROJECTION);
 glLoadIdentity;
 if Mode2DCheck.Checked then
 begin
  sizeX := (FLas.Source.Header.MaxX - FLas.Source.Header.MinX);
  sizeY := (FLas.Source.Header.MaxY - FLas.Source.Header.MinY);
  if sizeX <= 0 then sizeX := 1;
  if sizeY <= 0 then sizeY := 1;

  halfX := 0.5 * sizeX * FOrthoScale;
  halfY := 0.5 * sizeY * FOrthoScale;
  if halfX / Max(1, FBaseWidth) > halfY / Max(1, FBaseHeight) then
   halfY := halfX * Max(1, FBaseHeight) / Max(1, FBaseWidth)
  else
   halfX := halfY * Max(1, FBaseWidth) / Max(1, FBaseHeight);

  zRange := (FLas.Source.Header.MaxZ - FLas.Source.Header.MinZ);
  if zRange <= 0 then zRange := 1;
  zRange := zRange * 4;
  glOrtho(-halfX, halfX, -halfY, halfY, -zRange, zRange);
 end
 else
  gluPerspective(FFovDeg, FBaseWidth / Max(1, FBaseHeight), PerspectiveNear, 1000000.0);

 glMatrixMode(GL_MODELVIEW);
 glLoadIdentity;
 if Mode2DCheck.Checked then
 begin
  glTranslatef(-cx + FPanX, -cy + FPanY, -cz);
 end
 else
 begin
  glTranslatef(0, 0, -FDistance);
  glRotatef(FPitch, 1, 0, 0);
  glRotatef(FYaw, 0, 1, 0);
  glRotatef(FRoll, 0, 0, 1);
  glTranslatef(-cx + FPanX, -cy + FPanY, -cz + FPanZ);
 end;

 glPointSize(PointSize);
 if BlendEnabled then
 begin
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
 end
 else
  glDisable(GL_BLEND);

 colA := BlendAlpha / 255.0;
 qz := LevelZ;
 progNow := (not moving) and FProgActive;
 if progNow then
 begin
  if GetTickCount64 <= FProgStartTick then
   progT := 0
  else
   progT := EnsureRange((GetTickCount64 - FProgStartTick) / 250.0, 0.0, 1.0);
  progFrac := 0.2 + (1.0 - 0.2) * progT;
 end
 else
  progFrac := 1;

 moving := (FLastInteractTick <> 0) and (GetTickCount64 >= FLastInteractTick) and ((GetTickCount64 - FLastInteractTick) <= 250);

 if (FTiles <> nil) and (not FTilesBuilt) then
 begin
  if ProgressBar1 <> nil then
  begin
   ProgressBar1.Visible := True;
   ProgressBar1.Position := 0;
  end;
  buildNowMax := FBaseMaxPoints;
  if buildNowMax < 0 then buildNowMax := 0;
  WriteIn([buildNowMax]);
  FTiles.BuildFromLas(FLas, buildNowMax);
  FTilesBuilt := True;
  if ProgressBar1 <> nil then
   ProgressBar1.Visible := False;
 end;

 glGetFloatv(GL_PROJECTION_MATRIX, @proj[0]);
 glGetFloatv(GL_MODELVIEW_MATRIX, @mv[0]);
 MatMul(mvp, proj, mv);

 clipEnabled := PlaneShowCheck.Checked;// and (PlaneAlphaSpin.Value <= 0.0);
 if FTiles <> nil then
 begin
  if moving then
   FTiles.RenderDyna(mvp, PointSize, colA, clipEnabled, qz)
  else if progNow and (progT < 1) then
   FTiles.RenderProgress(mvp, PointSize, colA, progFrac, clipEnabled, qz)
  else
   FTiles.Render(mvp, PointSize, colA, clipEnabled, qz);
 end;

 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
 glDisable(GL_BLEND);
 FBaseDirty := False;

 { Авто-LOD отключен, оставляем только ручной LOD по кнопке.
 tick1 := GetTickCount64;
 if (tick1 > tick0) and ((tick1 - tick0) >= 120) and (FPointGpu <> nil) and FPointGpuBuilt then
 begin
  if FBaseMaxPoints <= 0 then
   buildNowMax := FPointGpu.Count
  else
   buildNowMax := FBaseMaxPoints;
  buildNowMax := Trunc(buildNowMax / 1.5);
  if buildNowMax < 10000 then buildNowMax := 10000;
  if buildNowMax <> FBaseMaxPoints then
  begin
   FBaseMaxPoints := buildNowMax;
   FPointGpuBuilt := False;
   FBaseDirty := True;
   OGL.Invalidate;
  end;
 end;
 }
end;

procedure TLas3DViewerForm.ApplyManualLod;
var
 baseNow, baseNext: Int64;
begin
 if (FLas = nil) or (FLas.Source = nil) or (not FLas.Source.IsOpen) then Exit;

 if FBaseMaxPoints > 0 then
  baseNow := FBaseMaxPoints
 else if (FTiles <> nil) and FTilesBuilt and (FTiles.TotalCount > 0) then
  baseNow := FTiles.TotalCount
 else
  baseNow := FLas.Source.PointCount;

 baseNext := Trunc(baseNow / 1.5);
 if baseNext < 10000 then baseNext := 10000;
 if baseNext = baseNow then Exit;

 FBaseMaxPoints := baseNext;
 FTilesBuilt := False;
 InvalidateBase;
end;

procedure TLas3DViewerForm.RenderOverlay;
const cxR = 1.5;
var
 cx, cy, cz: Double;
 minX, minY, maxX, maxY: Double;
 sizeX, sizeY: Double;
 halfX, halfY: Double;
 zRange: Double;
 qz: Double;
 proj, mv, mvp: TMat4;
 pickRadius: Double;
 zPickRadius: Double;
 moving: Boolean;
 progNow: Boolean;
 progT: Single;
 progFrac: Single;
 nx, ny, nz: Double;
 len: Double;
 x0, y0, z0: Double;
 x1, y1, z1: Double;
 depth: Single;
 sx0, sy0, sz0: GLdouble;
 sx1, sy1, sz1: GLdouble;
 viewportI: array[0..3] of GLint;
 cursorPix: Double;
begin
 if (FLas = nil) or (FLas.Source = nil) or (not FLas.Source.IsOpen) then Exit;

 glViewport(0, 0, OGL.Width, OGL.Height);
 glClearColor(0.5, 0.5, 0.5, 1);
 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
 glEnable(GL_DEPTH_TEST);

 if (FBaseTexture <> 0) and (FBaseWidth > 0) and (FBaseHeight > 0) then
 begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, OGL.Width, 0, OGL.Height, -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glDisable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, FBaseTexture);
  glColor4f(1, 1, 1, 1);
  glBegin(GL_QUADS);
   glTexCoord2f(0, 0); glVertex2f(0, 0);
   glTexCoord2f(1, 0); glVertex2f(OGL.Width, 0);
   glTexCoord2f(1, 1); glVertex2f(OGL.Width, OGL.Height);
   glTexCoord2f(0, 1); glVertex2f(0, OGL.Height);
  glEnd;
  glBindTexture(GL_TEXTURE_2D, 0);
  glDisable(GL_TEXTURE_2D);
  glEnable(GL_DEPTH_TEST);
 end;

 cx := (FLas.Source.Header.MinX + FLas.Source.Header.MaxX) * 0.5;
 cy := (FLas.Source.Header.MinY + FLas.Source.Header.MaxY) * 0.5;
 cz := (FLas.Source.Header.MinZ + FLas.Source.Header.MaxZ) * 0.5;
 minX := FLas.Source.Header.MinX;
 minY := FLas.Source.Header.MinY;
 maxX := FLas.Source.Header.MaxX;
 maxY := FLas.Source.Header.MaxY;
 qz := LevelZ;

 glMatrixMode(GL_PROJECTION);
 glLoadIdentity;
 if Mode2DCheck.Checked then
 begin
  sizeX := (FLas.Source.Header.MaxX - FLas.Source.Header.MinX);
  sizeY := (FLas.Source.Header.MaxY - FLas.Source.Header.MinY);
  if sizeX <= 0 then sizeX := 1;
  if sizeY <= 0 then sizeY := 1;

  halfX := 0.5 * sizeX * FOrthoScale;
  halfY := 0.5 * sizeY * FOrthoScale;
  if halfX / Max(1, OGL.Width) > halfY / Max(1, OGL.Height) then
   halfY := halfX * Max(1, OGL.Height) / Max(1, OGL.Width)
  else
   halfX := halfY * Max(1, OGL.Width) / Max(1, OGL.Height);

  zRange := (FLas.Source.Header.MaxZ - FLas.Source.Header.MinZ);
  if zRange <= 0 then zRange := 1;
  zRange := zRange * 4;
  glOrtho(-halfX, halfX, -halfY, halfY, -zRange, zRange);
 end
 else
  gluPerspective(FFovDeg, OGL.Width / Max(1, OGL.Height), PerspectiveNear, 1000000.0);

 glMatrixMode(GL_MODELVIEW);
 glLoadIdentity;
 if Mode2DCheck.Checked then
 begin
  glTranslatef(-cx + FPanX, -cy + FPanY, -cz);
 end
 else
 begin
  glTranslatef(0, 0, -FDistance);
  glRotatef(FPitch, 1, 0, 0);
  glRotatef(FYaw, 0, 1, 0);
  glRotatef(FRoll, 0, 0, 1);
  glTranslatef(-cx + FPanX, -cy + FPanY, -cz + FPanZ);
 end;

 if FTiles <> nil then
 begin
  glDisable(GL_BLEND);
  glLineWidth(1);
  glDisable(GL_DEPTH_TEST);
  glColor4f(0, 1, 1, 1);
  FTiles.RenderTileBBoxes(FLas.Source.Header.MinZ, FLas.Source.Header.MaxZ);
  glEnable(GL_DEPTH_TEST);
 end;

 if FPickDirty then
 begin
  if (FBaseFBO <> 0) and Assigned(glBindFramebufferEXT) then
   glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, FBaseFBO);
  UpdatePickState;
  if (FBaseFBO <> 0) and Assigned(glBindFramebufferEXT) then
   glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
 end;

 if PlaneShowCheck.Checked then
 begin
  glDisable(GL_BLEND);
  glLineWidth(2);
  glDisable(GL_DEPTH_TEST);
  glColor4f(1, 0, 0, 1);
  glBegin(GL_LINE_LOOP);
   glVertex3f(minX, minY, qz);
   glVertex3f(maxX, minY, qz);
   glVertex3f(maxX, maxY, qz);
   glVertex3f(minX, maxY, qz);
  glEnd;
  glEnable(GL_DEPTH_TEST);
 end;

 if FPickValid then
 begin
  glDisable(GL_BLEND);
  glLineWidth(1);
  glDisable(GL_DEPTH_TEST);
  if (FPickQx < minX) or (FPickQx > maxX) or (FPickQy < minY) or (FPickQy > maxY) then
   glColor4f(1, 0, 1, 1)
  else
   glColor4f(1, 1, 0, 1);
  glBegin(GL_LINE_LOOP);
   glVertex3f(FPickQx - cxR, FPickQy - cxR, FPickQz);
   glVertex3f(FPickQx + cxR, FPickQy - cxR, FPickQz);
   glVertex3f(FPickQx + cxR, FPickQy + cxR, FPickQz);
   glVertex3f(FPickQx - cxR, FPickQy + cxR, FPickQz);
  glEnd;
  glBegin(GL_LINES);
   glVertex3f(FPickQx - cxR, FPickQy, FPickQz);
   glVertex3f(FPickQx + cxR, FPickQy, FPickQz);
   glVertex3f(FPickQx, FPickQy - cxR, FPickQz);
   glVertex3f(FPickQx, FPickQy + cxR, FPickQz);
  glEnd;
  glEnable(GL_DEPTH_TEST);

  if OGL <> nil then
  begin
   glGetFloatv(GL_PROJECTION_MATRIX, @proj[0]);
   glGetFloatv(GL_MODELVIEW_MATRIX, @mv[0]);
   glGetIntegerv(GL_VIEWPORT, @viewportI[0]);
   if (gluProject(FPickQx, FPickQy, FPickQz, @mv[0], @proj[0], @viewportI[0], @sx0, @sy0, @sz0) <> 0) and
      (gluProject(FPickQx + cxR, FPickQy, FPickQz, @mv[0], @proj[0], @viewportI[0], @sx1, @sy1, @sz1) <> 0) then
   begin
    cursorPix := Abs(sx1 - sx0);
    if cursorPix < 10 then
     OGL.Cursor := crDefault
    else
     OGL.Cursor := crNone;
   end
   else
    OGL.Cursor := crDefault;
  end;

  if RayRadiusSpin <> nil then
   pickRadius := RayRadiusSpin.Value
  else
   pickRadius := 0.5;
  if pickRadius < 0.1 then pickRadius := 0.1;
  if pickRadius > 1.0 then pickRadius := 1.0;
  if (FTiles <> nil) and (pickRadius > 0) and (cbPlane <> nil) and cbPlane.Checked then
  begin
   zPickRadius := (FLas.Source.Header.MaxZ - FLas.Source.Header.MinZ) * 2;
   if zPickRadius <= 0 then zPickRadius := 1000000;

   glGetFloatv(GL_PROJECTION_MATRIX, @proj[0]);
   glGetFloatv(GL_MODELVIEW_MATRIX, @mv[0]);
   MatMul(mvp, proj, mv);

   glEnable(GL_BLEND);
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
   glDisable(GL_DEPTH_TEST);
   progNow := (not moving) and FProgActive;
   if progNow then
   begin
    if GetTickCount64 <= FProgStartTick then
     progT := 0
    else
     progT := EnsureRange((GetTickCount64 - FProgStartTick) / 250.0, 0.0, 1.0);
    progFrac := 0.2 + (1.0 - 0.2) * progT;
   end
   else
    progFrac := 1;

   if moving then
    FTiles.RenderHighlightDynaCulled(mvp, PlaneSizeSpin.Value,
                                    FPickQx, FPickQy, FPickQz, pickRadius, zPickRadius,
                                    5,
                                    0, 1, 0, 0.55,
                                    False, qz)
   else if progNow and (progFrac < 1) then
    FTiles.RenderHighlightProgressCulled(mvp, PlaneSizeSpin.Value, progFrac,
                                        FPickQx, FPickQy, FPickQz, pickRadius, zPickRadius,
                                        5,
                                        0, 1, 0, 0.55,
                                        False, qz)
   else
    FTiles.RenderHighlightCulled(mvp, PlaneSizeSpin.Value,
                                FPickQx, FPickQy, FPickQz, pickRadius, zPickRadius,
                                5,
                                0, 1, 0, 0.55,
                                False, qz);
   glEnable(GL_DEPTH_TEST);
   glDisable(GL_BLEND);
  end;
 end;
end;

procedure TLas3DViewerForm.UpdatePickState;
var
 projD, mvD: array[0..15] of GLdouble;
 viewport: array[0..3] of GLint;
 wx0, wy0, wz0: GLdouble;
 wx1, wy1, wz1: GLdouble;
 t: Double;
 qx, qy, qz: Double;
 depth: Single;
begin
 FPickDirty := False;
 if (FLas = nil) or (FLas.Source = nil) or (not FLas.Source.IsOpen) or (not FMouseValid) then
 begin
  FPickValid := False;
  FPickPtValid := False;
  Exit;
 end;

 glGetIntegerv(GL_VIEWPORT, @viewport[0]);
 glGetDoublev(GL_PROJECTION_MATRIX, @projD[0]);
 glGetDoublev(GL_MODELVIEW_MATRIX, @mvD[0]);

 if gluUnProject(FMouseX, viewport[3] - 1 - FMouseY, 0.0, @mvD[0], @projD[0], @viewport[0], @wx0, @wy0, @wz0) = 0 then
 begin
  FPickValid := False;
  FPickPtValid := False;
  Exit;
 end;
 if gluUnProject(FMouseX, viewport[3] - 1 - FMouseY, 1.0, @mvD[0], @projD[0], @viewport[0], @wx1, @wy1, @wz1) = 0 then
 begin
  FPickValid := False;
  FPickPtValid := False;
  Exit;
 end;

 qz := LevelZ;
 if Abs(wz1 - wz0) <= 1e-12 then
 begin
  FPickValid := False;
  FPickPtValid := False;
  Exit;
 end;
 t := (qz - wz0) / (wz1 - wz0);
 qx := wx0 + (wx1 - wx0) * t;
 qy := wy0 + (wy1 - wy0) * t;

 FPickQx := qx;
 FPickQy := qy;
 FPickQz := qz;
 FPickValid := True;

 depth := 1;
 glReadPixels(FMouseX, viewport[3] - 1 - FMouseY, 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, @depth);
 if (depth >= 0) and (depth < 1) then
 begin
  if gluUnProject(FMouseX, viewport[3] - 1 - FMouseY, depth, @mvD[0], @projD[0], @viewport[0], @wx0, @wy0, @wz0) <> 0 then
  begin
   FPickPtX := wx0;
   FPickPtY := wy0;
   FPickPtZ := wz0;
   FPickPtValid := True;
  end
  else
   FPickPtValid := False;
 end
 else
  FPickPtValid := False;

 if ((cbPlaneCapture = nil) or (not cbPlaneCapture.Checked)) and FPickPtValid then
 begin
  FPickQx := FPickPtX;
  FPickQy := FPickPtY;
  FPickQz := FPickPtZ;
 end;

 FPickTick := GetTickCount64;
end;

procedure TLas3DViewerForm.OGLPaint(Sender: TObject);
var
 tickNow, dt: QWord;
 moving: Boolean;
 zText: String;
 zPlaneText: String;
 fpsText: String;
begin
 if (FLas = nil) or (FLas.Source = nil) or (not FLas.Source.IsOpen) then Exit;
 if not OGL.MakeCurrent then Exit;

 tickNow := GetTickCount64;
 if FFpsLastTick = 0 then FFpsLastTick := tickNow;
 Inc(FFpsFrames);
 dt := tickNow - FFpsLastTick;
 if dt >= 500 then
 begin
  FFpsValue := (FFpsFrames * 1000.0) / Max(1, dt);
  FFpsFrames := 0;
  FFpsLastTick := tickNow;
 end;

 if not FGLInited then
 begin
  ReadExtensions;
  ReadImplementationProperties;
  FGLInited := True;
  if FTiles <> nil then
   FTiles.InitGL;
 end;

 moving := (FLastInteractTick <> 0) and (tickNow >= FLastInteractTick) and ((tickNow - FLastInteractTick) <= 250);
 if FWasMoving and (not moving) then
 begin
  FProgStartTick := tickNow;
  FProgActive := True;
  InvalidateBase;
 end;
 FWasMoving := moving;

 InitGlFont;
 InitBaseFrame;

 if FBaseDirty then
  RenderBaseFrame;
 RenderOverlay;

 if FPickPtValid then
  zText := Format('%.3f', [FPickPtZ])
 else
  zText := '-0';
 if FPickValid then
  zPlaneText := Format('%.3f', [FPickQz])
 else
  zPlaneText := '-0';
 if (cbPlaneCapture <> nil) and cbPlaneCapture.Checked then
  fpsText := Format('FPS: %.1f  Zp: %s  Z: %s', [FFpsValue, zPlaneText, zText])
 else
  fpsText := Format('FPS: %.1f  Z: %s', [FFpsValue, zText]);
 DrawGlText2D(5, OGL.Height - 15, AnsiString(fpsText));
 OGL.SwapBuffers;
end;

procedure TLas3DViewerForm.MoveTimerTimer(Sender: TObject);
var nowTick: QWord;
    moving: Boolean;
begin
 if OGL = nil then Exit;
 nowTick := GetTickCount64;
 moving := (FLastInteractTick <> 0) and (nowTick >= FLastInteractTick) and ((nowTick - FLastInteractTick) <= 250);
 if FProgActive then
  InvalidateBase
 else if moving or FWasMoving or FBaseDirty then
  OGL.Invalidate;
end;
end.
