unit uogslasrenderer;

{$mode Delphi}{$H+}

interface

uses
 Classes, SysUtils, Controls, Math, IniFiles,
 OpenGLPanel, ogcLas, uLasPointCloudTiles, uLasPointCloudGpu,
 dglOpenGL, GLU;

type
 TRenderMode = (rmOrtho2D, rm3D);

 TLasRenderer = class
 private
  FOGL: TOpenGLPanel;
  FLas: TogsLas;
  FTiles: TLasPointCloudTiles;
  FMode: TRenderMode;
  FStateFileName: String;
  FPanX: Double;
  FPanY: Double;
  FPanZ: Double;
  FYaw: Double;
  FPitch: Double;
  FFovDeg: Double;
  FOrthoScale: Double;
  FPointSize: Single;
  FAlpha: Single;
  FClipEnabled: Boolean;
  FClipZ: Single;
  FDown: Boolean;
  FDownButton: TMouseButton;
  FLastX: Integer;
  FLastY: Integer;
  FRenderFrac: Single;
  FDistance: Double;
  FAutoDistance: Boolean;
  FUseDyna: Boolean;
  FBlendEnabled: Boolean;
  FPlaneEnabled: Boolean;
  FPlaneDeltaZ: Double;
  FShowTileBBoxes: Boolean;
  procedure SetMode(AValue: TRenderMode);
  procedure SetShowTileBBoxes(AValue: Boolean);
  function DefaultDistance3D: Double;
  procedure Zoom3DBy(const ADeltaDist: Double; const AMouseX, AMouseY: Integer);
 public
  constructor Create(AOGL: TOpenGLPanel; ALas: TogsLas; ATiles: TLasPointCloudTiles);
  destructor Destroy; override;
  procedure InitGL;
  procedure Render;
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseMove(Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint);
  procedure ResetView;
  procedure SaveState;
  procedure LoadState;
  property Mode: TRenderMode read FMode write SetMode;
  property StateFileName: String read FStateFileName write FStateFileName;
  property PanX: Double read FPanX write FPanX;
  property PanY: Double read FPanY write FPanY;
  property PanZ: Double read FPanZ write FPanZ;
  property Yaw: Double read FYaw write FYaw;
  property Pitch: Double read FPitch write FPitch;
  property FovDeg: Double read FFovDeg write FFovDeg;
  property OrthoScale: Double read FOrthoScale write FOrthoScale;
  property PointSize: Single read FPointSize write FPointSize;
  property Alpha: Single read FAlpha write FAlpha;
  property ClipEnabled: Boolean read FClipEnabled write FClipEnabled;
  property ClipZ: Single read FClipZ write FClipZ;
  property RenderFrac: Single read FRenderFrac write FRenderFrac;
  property Distance: Double read FDistance write FDistance;
  property AutoDistance: Boolean read FAutoDistance write FAutoDistance;
  property UseDyna: Boolean read FUseDyna write FUseDyna;
  property BlendEnabled: Boolean read FBlendEnabled write FBlendEnabled;
  property PlaneEnabled: Boolean read FPlaneEnabled write FPlaneEnabled;
  property PlaneDeltaZ: Double read FPlaneDeltaZ write FPlaneDeltaZ;
  property ShowTileBBoxes: Boolean read FShowTileBBoxes write SetShowTileBBoxes;
 end;

implementation

const
 ZoomStepMeters = 5.0;

constructor TLasRenderer.Create(AOGL: TOpenGLPanel; ALas: TogsLas; ATiles: TLasPointCloudTiles);
begin
 inherited Create;
 FOGL := AOGL;
 FLas := ALas;
 FTiles := ATiles;
 FMode := rm3D;
 FPanX := 0;
 FPanY := 0;
 FPanZ := 0;
 FYaw := 0;
 FPitch := 0;
 FFovDeg := 60;
 FOrthoScale := 1;
 FPointSize := 2;
 FAlpha := 1;
 FClipEnabled := False;
 FClipZ := 0;
 FDown := False;
 FDownButton := mbLeft;
 FLastX := 0;
 FLastY := 0;
 FRenderFrac := 1;
 FDistance := 0;
 FAutoDistance := True;
 FUseDyna := False;
 FBlendEnabled := False;
 FStateFileName := '';
 FPlaneEnabled := False;
 FPlaneDeltaZ := 0;
 FShowTileBBoxes := False;
end;

procedure TLasRenderer.SaveState;
var ini: TIniFile;
begin
 if FStateFileName = '' then Exit;
 try
  ini := TIniFile.Create(FStateFileName);
  try
   ini.WriteInteger('Camera', 'Mode', Ord(FMode));
   ini.WriteFloat('Camera', 'PanX', FPanX);
   ini.WriteFloat('Camera', 'PanY', FPanY);
   ini.WriteFloat('Camera', 'PanZ', FPanZ);
   ini.WriteFloat('Camera', 'Yaw', FYaw);
   ini.WriteFloat('Camera', 'Pitch', FPitch);
   ini.WriteFloat('Camera', 'FovDeg', FFovDeg);
   ini.WriteFloat('Camera', 'OrthoScale', FOrthoScale);
   ini.WriteFloat('Camera', 'Distance', FDistance);
   ini.WriteBool('Camera', 'AutoDistance', FAutoDistance);
   ini.WriteInteger('Render', 'PointSize', Round(FPointSize));
   ini.WriteBool('Render', 'Blend', FBlendEnabled);
   ini.WriteInteger('Render', 'Alpha', Round(EnsureRange(FAlpha, 0.0, 1.0) * 255.0));
   ini.WriteBool('Render', 'Plane', FPlaneEnabled);
   ini.WriteFloat('Render', 'PlaneDeltaZ', FPlaneDeltaZ);
   ini.WriteBool('Render', 'ShowTiles', FShowTileBBoxes);
  finally
   ini.Free;
  end;
 except
 end;
end;

procedure TLasRenderer.LoadState;
var ini: TIniFile;
    modeI: Integer;
    alphaI: Integer;
begin
 if (FStateFileName = '') or (not FileExists(FStateFileName)) then Exit;
 try
  ini := TIniFile.Create(FStateFileName);
  try
   modeI := ini.ReadInteger('Camera', 'Mode', Ord(rm3D));
   if modeI = Ord(rmOrtho2D) then
    FMode := rmOrtho2D
   else
    FMode := rm3D;
   FPanX := ini.ReadFloat('Camera', 'PanX', FPanX);
   FPanY := ini.ReadFloat('Camera', 'PanY', FPanY);
   FPanZ := ini.ReadFloat('Camera', 'PanZ', FPanZ);
   FYaw := ini.ReadFloat('Camera', 'Yaw', FYaw);
   FPitch := ini.ReadFloat('Camera', 'Pitch', FPitch);
   FFovDeg := ini.ReadFloat('Camera', 'FovDeg', FFovDeg);
   FOrthoScale := ini.ReadFloat('Camera', 'OrthoScale', FOrthoScale);
   FDistance := ini.ReadFloat('Camera', 'Distance', FDistance);
   FAutoDistance := ini.ReadBool('Camera', 'AutoDistance', FAutoDistance);
   FPointSize := ini.ReadInteger('Render', 'PointSize', Round(FPointSize));
   FBlendEnabled := ini.ReadBool('Render', 'Blend', FBlendEnabled);
   alphaI := ini.ReadInteger('Render', 'Alpha', Round(EnsureRange(FAlpha, 0.0, 1.0) * 255.0));
   if alphaI < 0 then alphaI := 0;
   if alphaI > 255 then alphaI := 255;
   FAlpha := alphaI / 255.0;
   FPlaneEnabled := ini.ReadBool('Render', 'Plane', FPlaneEnabled);
   FPlaneDeltaZ := ini.ReadFloat('Render', 'PlaneDeltaZ', FPlaneDeltaZ);
   SetShowTileBBoxes(ini.ReadBool('Render', 'ShowTiles', FShowTileBBoxes));
  finally
   ini.Free;
  end;
 except
 end;
end;

procedure TLasRenderer.SetShowTileBBoxes(AValue: Boolean);
begin
 if FShowTileBBoxes = AValue then Exit;
 FShowTileBBoxes := AValue;
 if FTiles <> nil then
  FTiles.DrawTileBBoxes := FShowTileBBoxes;
end;

destructor TLasRenderer.Destroy;
begin
 inherited Destroy;
end;

procedure TLasRenderer.SetMode(AValue: TRenderMode);
begin
 if FMode = AValue then Exit;
 FMode := AValue;
end;

procedure TLasRenderer.InitGL;
begin
 if FTiles <> nil then
  FTiles.InitGL;
end;

function TLasRenderer.DefaultDistance3D: Double;
begin
 Result := 10;
 if (FLas = nil) or (not FLas.Loaded) then Exit;
 Result := Max(Max(FLas.Source.Header.MaxX - FLas.Source.Header.MinX,
                   FLas.Source.Header.MaxY - FLas.Source.Header.MinY),
               FLas.Source.Header.MaxZ - FLas.Source.Header.MinZ) * 2;
 if Result < 10 then Result := 10;
end;

procedure TLasRenderer.Zoom3DBy(const ADeltaDist: Double; const AMouseX, AMouseY: Integer);
var w, h: Integer;
    distBefore, distAfter: Double;
    yawRad, pitchRad: Double;
    rightX, rightY, rightZ: Double;
    upX, upY, upZ: Double;
    tanHalfFov: Double;
    wppBefore, wppAfter: Double;
    dxPix, dyPix: Double;
    offBX, offBY, offBZ: Double;
    offAX, offAY, offAZ: Double;
begin
 if FMode <> rm3D then Exit;
 if (FOGL = nil) then Exit;
 w := FOGL.Width;
 h := FOGL.Height;
 if (w <= 0) or (h <= 0) then Exit;
 if FAutoDistance or IsNan(FDistance) or IsInfinite(FDistance) then
 begin
  FAutoDistance := False;
  FDistance := DefaultDistance3D;
 end;
 distBefore := EnsureRange(FDistance, 1E-12, 1E18);
 yawRad := DegToRad(FYaw);
 pitchRad := DegToRad(FPitch);
 rightX := Cos(yawRad);
 rightY := -Sin(yawRad);
 rightZ := 0;
 upX := Sin(yawRad) * Cos(pitchRad);
 upY := Cos(yawRad) * Cos(pitchRad);
 upZ := -Sin(pitchRad);
 tanHalfFov := Tan(DegToRad(FFovDeg) * 0.5);
 if tanHalfFov <= 0 then tanHalfFov := 1E-6;
 wppBefore := (2.0 * distBefore * tanHalfFov) / h;
 dxPix := AMouseX - (w * 0.5);
 dyPix := (h * 0.5) - AMouseY;
 offBX := dxPix * wppBefore * rightX + dyPix * wppBefore * upX;
 offBY := dxPix * wppBefore * rightY + dyPix * wppBefore * upY;
 offBZ := dxPix * wppBefore * rightZ + dyPix * wppBefore * upZ;
 distAfter := EnsureRange(distBefore + ADeltaDist, 1E-12, 1E18);
 wppAfter := (2.0 * distAfter * tanHalfFov) / h;
 offAX := dxPix * wppAfter * rightX + dyPix * wppAfter * upX;
 offAY := dxPix * wppAfter * rightY + dyPix * wppAfter * upY;
 offAZ := dxPix * wppAfter * rightZ + dyPix * wppAfter * upZ;
 FPanX := FPanX + (offBX - offAX);
 FPanY := FPanY + (offBY - offAY);
 FPanZ := FPanZ + (offBZ - offAZ);
 FDistance := distAfter;
end;

procedure TLasRenderer.Render;
var proj, mv, mvp: TMat4;
    w, h: Integer;
    aspect: Double;
    zNear, zFar: Double;
    cx, cy, cz: Double;
    distance: Double;
    defaultDistance: Double;
    effectiveDistance: Double;
    frac: Single;
    effectivePointSize: Single;
    minX, minY, minZ: Double;
    maxX, maxY, maxZ: Double;
    originX, originY, originZ: Double;
    zPlane: Double;
begin
 if (FOGL = nil) or (FTiles = nil) then Exit;
 if (FLas = nil) or (not FLas.Loaded) then Exit;
 w := FOGL.Width;
 h := FOGL.Height;
 if (w <= 0) or (h <= 0) then Exit;
 aspect := w / h;
 glViewport(0, 0, w, h);
 glClearColor(0.5, 0.5, 0.5, 1);
 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
 glEnable(GL_DEPTH_TEST);
 glDepthFunc(GL_LEQUAL);
 glEnable(GL_PROGRAM_POINT_SIZE);
 glMatrixMode(GL_PROJECTION);
 glLoadIdentity;
 if FMode = rmOrtho2D then
 begin
  cx := 0;
  cy := 0;
  distance := Max(FLas.Source.Header.MaxX - FLas.Source.Header.MinX,
                  FLas.Source.Header.MaxY - FLas.Source.Header.MinY) * 0.5 * FOrthoScale;
  if distance < 1 then distance := 1;
  glOrtho(-distance * aspect + FPanX, distance * aspect + FPanX,
          -distance + FPanY, distance + FPanY,
          -10000, 10000);
 end
 else
 begin
  defaultDistance := Max(Max(FLas.Source.Header.MaxX - FLas.Source.Header.MinX,
                             FLas.Source.Header.MaxY - FLas.Source.Header.MinY),
                         FLas.Source.Header.MaxZ - FLas.Source.Header.MinZ) * 2;
  if defaultDistance < 10 then defaultDistance := 10;
  if (not FAutoDistance) and (not IsNan(FDistance)) and (not IsInfinite(FDistance)) then
   effectiveDistance := FDistance
  else
   effectiveDistance := defaultDistance;
  if effectiveDistance <= 0 then effectiveDistance := 1E-6;
  zNear := effectiveDistance * 1E-4;
  if zNear < 1E-6 then zNear := 1E-6;
  zFar := effectiveDistance * 1E4;
  if zFar < 1000 then zFar := 1000;
  gluPerspective(FFovDeg, aspect, zNear, zFar);
 end;
 glGetFloatv(GL_PROJECTION_MATRIX, @proj[0]);
 glMatrixMode(GL_MODELVIEW);
 glLoadIdentity;
 if FMode = rm3D then
 begin
  cx := 0;
  cy := 0;
  cz := 0;
  distance := Max(Max(FLas.Source.Header.MaxX - FLas.Source.Header.MinX,
                      FLas.Source.Header.MaxY - FLas.Source.Header.MinY),
                  FLas.Source.Header.MaxZ - FLas.Source.Header.MinZ) * 2;
  if distance < 10 then distance := 10;
  if FAutoDistance or IsNan(FDistance) or IsInfinite(FDistance) then
   distance := distance
  else
   distance := FDistance;
  if distance <= 0 then distance := 1E-6;
  glTranslated(0, 0, -distance);
  glRotated(FPitch, 1, 0, 0);
  glRotated(FYaw, 0, 0, 1);
  glTranslated(FPanX, FPanY, FPanZ);
 end
 else
 begin
  glTranslated(0, 0, 0);
 end;
 glGetFloatv(GL_MODELVIEW_MATRIX, @mv[0]);
 MatMul(mvp, proj, mv);
 frac := EnsureRange(FRenderFrac, 0.0, 1.0);
 effectivePointSize := EnsureRange(FPointSize, 1.0, 4.0);
 if FMode = rm3D then
 begin
  if FBlendEnabled then
  begin
   glEnable(GL_BLEND);
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  end
  else
   glDisable(GL_BLEND);
  if FUseDyna then
   FTiles.RenderDyna(mvp, effectivePointSize, FAlpha, FClipEnabled, FClipZ)
  else if frac < 1 then
   FTiles.RenderProgress(mvp, effectivePointSize, FAlpha, frac, FClipEnabled, FClipZ)
  else
   FTiles.Render(mvp, effectivePointSize, FAlpha, FClipEnabled, FClipZ);

  if (FLas <> nil) and (FLas.Source <> nil) and (FLas.Source.IsOpen) then
  begin
   minX := FLas.Source.Header.MinX;
   minY := FLas.Source.Header.MinY;
   minZ := FLas.Source.Header.MinZ;
   maxX := FLas.Source.Header.MaxX;
   maxY := FLas.Source.Header.MaxY;
   maxZ := FLas.Source.Header.MaxZ;
   originX := (minX + maxX) * 0.5;
   originY := (minY + maxY) * 0.5;
   originZ := (minZ + maxZ) * 0.5;

   if FTiles <> nil then
    FTiles.RenderTileBBoxes((minZ), (maxZ));

   if FPlaneEnabled then
   begin
    zPlane := (minZ + FPlaneDeltaZ) - originZ;
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_LIGHTING);
    glColor4f(1, 1, 0, 1);
    glBegin(GL_LINE_LOOP);
     glVertex3f((minX - originX), (minY - originY), (zPlane));
     glVertex3f((maxX - originX), (minY - originY), (zPlane));
     glVertex3f((maxX - originX), (maxY - originY), (zPlane));
     glVertex3f((minX - originX), (maxY - originY), (zPlane));
    glEnd;
   end;
  end;
  glDisable(GL_BLEND);
 end
 else
 begin
  if frac < 1 then
   FTiles.RenderProgress(mvp, effectivePointSize, FAlpha, frac, FClipEnabled, FClipZ)
  else
   FTiles.Render(mvp, effectivePointSize, FAlpha, FClipEnabled, FClipZ);
 end;
end;

procedure TLasRenderer.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 FDown := True;
 FDownButton := Button;
 FLastX := X;
 FLastY := Y;
end;

procedure TLasRenderer.MouseMove(Shift: TShiftState; X, Y: Integer);
var dx, dy: Integer;
    worldPerPixel: Double;
    distance: Double;
    minPanDist: Double;
    panDistance: Double;
    yawRad, pitchRad: Double;
    rightX, rightY, rightZ: Double;
    upX, upY, upZ: Double;
begin
 if not FDown then Exit;
 dx := X - FLastX;
 dy := Y - FLastY;
 FLastX := X;
 FLastY := Y;
 if FMode = rmOrtho2D then
 begin
  if FDownButton = mbLeft then
  begin
   if (FLas <> nil) and FLas.Loaded then
   begin
    distance := Max(FLas.Source.Header.MaxX - FLas.Source.Header.MinX,
                    FLas.Source.Header.MaxY - FLas.Source.Header.MinY) * 0.5 * FOrthoScale;
    if distance < 1 then distance := 1;
    if FOGL.Height > 0 then
     worldPerPixel := (2 * distance) / FOGL.Height
    else
     worldPerPixel := 1;
    FPanX := FPanX - dx * worldPerPixel;
    FPanY := FPanY + dy * worldPerPixel;
   end;
  end;
 end
 else
 begin
  if FDownButton = mbLeft then
  begin
   FYaw := FYaw + dx * 0.5;
   FPitch := FPitch + dy * 0.5;
   if FYaw > 360 then FYaw := FYaw - 360;
   if FYaw < -360 then FYaw := FYaw + 360;
   if FPitch > 360 then FPitch := FPitch - 360;
   if FPitch < -360 then FPitch := FPitch + 360;
  end
  else if FDownButton = mbRight then
  begin
   if (FLas <> nil) and FLas.Loaded then
   begin
    distance := FDistance;
    if (distance <= 0) or IsNan(distance) or IsInfinite(distance) then
     distance := 100;
    minPanDist := 1E-3;
    panDistance := distance;
    if panDistance < minPanDist then panDistance := minPanDist;
    if (FOGL.Height > 0) and (FFovDeg > 0) then
     worldPerPixel := (2 * panDistance * Tan((FFovDeg * Pi / 180) * 0.5)) / FOGL.Height
    else if FOGL.Height > 0 then
     worldPerPixel := panDistance / FOGL.Height
    else
     worldPerPixel := 1;
    yawRad := FYaw * Pi / 180;
    pitchRad := FPitch * Pi / 180;
    rightX := Cos(yawRad);
    rightY := -Sin(yawRad);
    rightZ := 0;
    upX := Sin(yawRad) * Cos(pitchRad);
    upY := Cos(yawRad) * Cos(pitchRad);
    upZ := -Sin(pitchRad);
    FPanX := FPanX + dx * worldPerPixel * rightX - dy * worldPerPixel * upX;
    FPanY := FPanY + dx * worldPerPixel * rightY - dy * worldPerPixel * upY;
    FPanZ := FPanZ + dx * worldPerPixel * rightZ - dy * worldPerPixel * upZ;
   end;
  end
  else if FDownButton = mbMiddle then
  begin
   Zoom3DBy(-dy * ZoomStepMeters, X, Y);
  end;
 end;
end;

procedure TLasRenderer.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if Button <> FDownButton then Exit;
 FDown := False;
end;

procedure TLasRenderer.MouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint);
var delta: Double;
begin
 delta := WheelDelta / 120;
 if FMode = rmOrtho2D then
 begin
  FOrthoScale := FOrthoScale * Power(0.9, delta);
  if FOrthoScale < 0.01 then FOrthoScale := 0.01;
  if FOrthoScale > 100 then FOrthoScale := 100;
 end
 else
 begin
  if FAutoDistance then
  begin
   FAutoDistance := False;
   FDistance := DefaultDistance3D;
  end;
  FDistance := FDistance - delta * ZoomStepMeters;
  FDistance := EnsureRange(FDistance, 1E-12, 1E18);
 end;
end;

procedure TLasRenderer.ResetView;
begin
 FPanX := 0;
 FPanY := 0;
 FPanZ := 0;
 FYaw := 0;
 FPitch := -45;
 FFovDeg := 45;
 FDistance := DefaultDistance3D;
 FAutoDistance := True;
 FOrthoScale := 1;
end;

end.
