unit uLasSceneController;

{$mode Delphi}{$H+}

interface

uses Classes, Controls, SysUtils, Math, OpenGLPanel, ogcLas, uLasPointCloudTiles,
 uLasPointCloudGpu, uLasFileContext, uogslasrenderer, dglOpenGL, GLU;

type
 TLasSceneController = class(TLasRenderer)
 private
  FContexts: TList;
  FBBoxDirty: Boolean;
  FBBoxValid: Boolean;
  FBBoxMinX: Double;
  FBBoxMinY: Double;
  FBBoxMinZ: Double;
  FBBoxMaxX: Double;
  FBBoxMaxY: Double;
  FBBoxMaxZ: Double;
  FPoslLoaded: Boolean;
  FPoslPoints: array of TPoslPoint;
  function GetContextCount: Integer;
  function GetContext(Index: Integer): TLasFileContext;
  procedure InvalidateCombinedBBox;
  procedure RecalcCombinedBBox;
  procedure ClearPosl;
 protected
  function CalcCombinedBBoxVisible(out AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Double): Boolean;
  function DefaultDistance3D: Double; override;
  procedure SetShowTileBBoxes(AValue: Boolean); override;
 public
  constructor Create(AOGL: TOpenGLPanel);
  destructor Destroy; override;

  function GetCombinedBBoxVisible(out AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Double): Boolean;

  function AddContext: TLasFileContext;
  procedure RemoveContext(AIndex: Integer);
  procedure ClearContexts;

  procedure SetContextVisible(AContext: TLasFileContext; AVisible: Boolean);
  procedure MarkBBoxDirty;

  procedure ApplySettingsToAllContexts;

  function LoadPoslOnceFromDir(const ADir: String): Boolean;
  function PoslPointCount: Integer;
  function GetPoslPoint(Index: Integer; out AX, AY, AZ: Double): Boolean;

  procedure InitGL; override;
  procedure Render; override;

  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint); override;

  property ContextCount: Integer read GetContextCount;
  property Contexts[Index: Integer]: TLasFileContext read GetContext;
 end;

implementation uses ogcWriter;

function TLasSceneController.GetCombinedBBoxVisible(out AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Double): Boolean;
begin
 if FBBoxDirty then
  RecalcCombinedBBox;
 Result := FBBoxValid;
 if (not Result) and (FContexts <> nil) and (FContexts.Count > 0) then
 begin
  // contexts may not be open yet (AddContext called before ctx.Open);
  // keep bbox dirty so it will be recalculated once data becomes available
  FBBoxDirty := True;
 end;
 if not Result then
 begin
  AMinX := 0; AMinY := 0; AMinZ := 0;
  AMaxX := 0; AMaxY := 0; AMaxZ := 0;
  Exit;
 end;
 AMinX := FBBoxMinX; AMinY := FBBoxMinY; AMinZ := FBBoxMinZ;
 AMaxX := FBBoxMaxX; AMaxY := FBBoxMaxY; AMaxZ := FBBoxMaxZ;
end;

function MatTranslate(const Dx, Dy, Dz: Double): TMat4;
begin
 Result[0] := 1; Result[4] := 0; Result[8] := 0;  Result[12] := Dx;
 Result[1] := 0; Result[5] := 1; Result[9] := 0;  Result[13] := Dy;
 Result[2] := 0; Result[6] := 0; Result[10] := 1; Result[14] := Dz;
 Result[3] := 0; Result[7] := 0; Result[11] := 0; Result[15] := 1;
end;

procedure TLasSceneController.SetShowTileBBoxes(AValue: Boolean);
begin
 inherited SetShowTileBBoxes(AValue);
 ApplySettingsToAllContexts;
end;

constructor TLasSceneController.Create(AOGL: TOpenGLPanel);
begin
 inherited Create(AOGL, nil, nil);
 FContexts := TList.Create;
 FBBoxDirty := True;
 FBBoxValid := False;
 FPoslLoaded := False;
 SetLength(FPoslPoints, 0);
end;

destructor TLasSceneController.Destroy;
begin
 ClearContexts;
 ClearPosl;
 FreeAndNil(FContexts);
 inherited Destroy;
end;

procedure TLasSceneController.ClearPosl;
begin
 SetLength(FPoslPoints, 0);
 FPoslLoaded := False;
end;

function TLasSceneController.LoadPoslOnceFromDir(const ADir: String): Boolean;
var
 dirPath: String;
 fn2, fn3, fn: String;
 sr: TSearchRec;
 sl: TStringList;
 parts: TStringList;
 i: Integer;
 line: String;
 x, y, z: Double;
 fsDot: TFormatSettings;
 fsComma: TFormatSettings;
 p: TPoslPoint;
begin
 Result := False;
 if FPoslLoaded then
 begin
  Result := (Length(FPoslPoints) > 0);
  Exit;
 end;

 SetLength(FPoslPoints, 0);
 dirPath := Trim(ADir);
 if dirPath = '' then Exit;
 if not DirectoryExists(dirPath) then Exit;
 dirPath := IncludeTrailingPathDelimiter(dirPath);

 fn2 := dirPath + 'posl';
 fn3 := dirPath + 'posl.txt';
 fn := '';

 if FindFirst(dirPath + '*.posl', faAnyFile and (not faDirectory), sr) = 0 then
 begin
  try
   fn := dirPath + sr.Name;
  finally
   FindClose(sr);
  end;
 end
 else if FileExists(fn2) then fn := fn2
 else if FileExists(fn3) then fn := fn3;
 if fn = '' then
 begin
  FPoslLoaded := True;
  Exit;
 end;

 fsDot := DefaultFormatSettings;
 fsDot.DecimalSeparator := '.';
 fsComma := DefaultFormatSettings;
 fsComma.DecimalSeparator := ',';

 sl := TStringList.Create;
 parts := TStringList.Create;
 try
  sl.LoadFromFile(fn);
  for i := 0 to sl.Count - 1 do
  begin
   line := Trim(sl[i]);
   if line = '' then Continue;
   if (line[1] = '#') then Continue;
   if (Length(line) >= 2) and (line[1] = '/') and (line[2] = '/') then Continue;

   line := StringReplace(line, ',', ' ', [rfReplaceAll]);
   line := StringReplace(line, ';', ' ', [rfReplaceAll]);
   line := StringReplace(line, #9, ' ', [rfReplaceAll]);

   parts.Clear;
   ExtractStrings([' '], [], PChar(line), parts);
   if parts.Count < 3 then Continue;

   if parts.Count >= 10 then
   begin
    if (not TryStrToFloat(parts[7], x, fsDot)) and (not TryStrToFloat(parts[7], x, fsComma)) then Continue;
    if (not TryStrToFloat(parts[8], y, fsDot)) and (not TryStrToFloat(parts[8], y, fsComma)) then Continue;
    if (not TryStrToFloat(parts[9], z, fsDot)) and (not TryStrToFloat(parts[9], z, fsComma)) then Continue;
   end
   else
   begin
    if (not TryStrToFloat(parts[0], x, fsDot)) and (not TryStrToFloat(parts[0], x, fsComma)) then Continue;
    if (not TryStrToFloat(parts[1], y, fsDot)) and (not TryStrToFloat(parts[1], y, fsComma)) then Continue;
    if (not TryStrToFloat(parts[2], z, fsDot)) and (not TryStrToFloat(parts[2], z, fsComma)) then Continue;
   end;

   p.X := x;
   p.Y := y;
   p.Z := z;
   WriteIn(['POSL XYZ=', i, p.X, p.Y, p.Z]);
   SetLength(FPoslPoints, Length(FPoslPoints) + 1);
   FPoslPoints[High(FPoslPoints)] := p;
  end;
 finally
  parts.Free;
  sl.Free;
 end;

 FPoslLoaded := True;
 Result := (Length(FPoslPoints) > 0);
end;

function TLasSceneController.PoslPointCount: Integer;
begin
 Result := Length(FPoslPoints);
end;

function TLasSceneController.GetPoslPoint(Index: Integer; out AX, AY, AZ: Double): Boolean;
begin
 Result := (Index >= 0) and (Index < Length(FPoslPoints));
 if not Result then
 begin
  AX := 0;
  AY := 0;
  AZ := 0;
  Exit;
 end;
 AX := FPoslPoints[Index].X;
 AY := FPoslPoints[Index].Y;
 AZ := FPoslPoints[Index].Z;
end;

function TLasSceneController.GetContextCount: Integer;
begin
 if FContexts <> nil then
  Result := FContexts.Count
 else
  Result := 0;
end;

function TLasSceneController.GetContext(Index: Integer): TLasFileContext;
begin
 if (FContexts = nil) or (Index < 0) or (Index >= FContexts.Count) then
  Result := nil
 else
  Result := TLasFileContext(FContexts[Index]);
end;

function TLasSceneController.AddContext: TLasFileContext;
begin
 Result := TLasFileContext.Create;
 if FContexts <> nil then
  FContexts.Add(Result);
 InvalidateCombinedBBox;
 ApplySettingsToAllContexts;
end;

procedure TLasSceneController.RemoveContext(AIndex: Integer);
var
 ctx: TLasFileContext;
begin
 if (FContexts = nil) or (AIndex < 0) or (AIndex >= FContexts.Count) then Exit;
 ctx := TLasFileContext(FContexts[AIndex]);
 FContexts.Delete(AIndex);
 ctx.Free;
 InvalidateCombinedBBox;
end;

procedure TLasSceneController.ClearContexts;
var
 i: Integer;
 ctx: TLasFileContext;
begin
 if FContexts = nil then Exit;
 for i := FContexts.Count - 1 downto 0 do
 begin
  ctx := TLasFileContext(FContexts[i]);
  FContexts.Delete(i);
  ctx.Free;
 end;
 InvalidateCombinedBBox;
end;

procedure TLasSceneController.SetContextVisible(AContext: TLasFileContext; AVisible: Boolean);
begin
 if AContext = nil then Exit;
 if AContext.Visible = AVisible then Exit;
 AContext.Visible := AVisible;
 InvalidateCombinedBBox;
end;

procedure TLasSceneController.InvalidateCombinedBBox;
begin
 FBBoxDirty := True;
end;

procedure TLasSceneController.MarkBBoxDirty;
begin
 InvalidateCombinedBBox;
end;

procedure TLasSceneController.RecalcCombinedBBox;
begin
 FBBoxValid := CalcCombinedBBoxVisible(FBBoxMinX, FBBoxMinY, FBBoxMinZ, FBBoxMaxX, FBBoxMaxY, FBBoxMaxZ);
 FBBoxDirty := False;
end;

procedure TLasSceneController.ApplySettingsToAllContexts;
var
 i: Integer;
 ctx: TLasFileContext;
begin
 if FContexts = nil then Exit;
 for i := 0 to FContexts.Count - 1 do
 begin
  ctx := TLasFileContext(FContexts[i]);
  if ctx = nil then Continue;

  if ctx.Tiles <> nil then
  begin
   ctx.Tiles.DrawTileBBoxes := FShowTileBBoxes;
   ctx.Tiles.ColorMode := ctx.ColorMode;
  end;

  ctx.DynaLodTileSize := FDynaLodTileSize;
 end;
end;

procedure TLasSceneController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 minX, minY, minZ, maxX, maxY, maxZ: Double;
 originZ: Double;
 planeZ: Double;
 ax, ay: Double;
begin
 FDown := True;
 FDownButton := Button;
 FLastX := X;
 FLastY := Y;

 FPanPlaneAnchorValid := False;
 if (FMode = rm3D) and (Button = mbMiddle) and GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ) then
 begin
  originZ := (minZ + maxZ) * 0.5;
  planeZ := (minZ + FPlaneDeltaZ) - originZ;
  FPanPlaneZ := planeZ;
  if RayPlaneIntersect(X, Y, planeZ, ax, ay) then
  begin
   FPanPlaneAnchorX := ax;
   FPanPlaneAnchorY := ay;
   FPanPlaneAnchorValid := True;
  end;
 end;
end;

procedure TLasSceneController.MouseMove(Shift: TShiftState; X, Y: Integer);
var
 dx, dy: Integer;
 worldPerPixel: Double;
 distance: Double;
 minPanDist: Double;
 panDistance: Double;
 yawRad, pitchRad: Double;
 rightX, rightY, rightZ: Double;
 upX, upY, upZ: Double;
 ax, ay: Double;
 minX, minY, minZ, maxX, maxY, maxZ: Double;
 viewDist: Double;
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
   if GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ) then
   begin
    viewDist := Max(maxX - minX, maxY - minY) * 0.5 * FOrthoScale;
    if viewDist < 1 then viewDist := 1;
    if (FOGL <> nil) and (FOGL.Height > 0) then
     worldPerPixel := (2 * viewDist) / FOGL.Height
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
   distance := FDistance;
   if (distance <= 0) or IsNan(distance) or IsInfinite(distance) then
    distance := DefaultDistance3D;
   if distance <= 0 then distance := 100;
   minPanDist := 1E-3;
   panDistance := distance;
   if panDistance < minPanDist then panDistance := minPanDist;
   if (FOGL <> nil) and (FOGL.Height > 0) and (FFovDeg > 0) then
    worldPerPixel := (2 * panDistance * Tan((FFovDeg * Pi / 180) * 0.5)) / FOGL.Height
   else if (FOGL <> nil) and (FOGL.Height > 0) then
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
  end
  else if FDownButton = mbMiddle then
  begin
   if FPanPlaneAnchorValid and RayPlaneIntersect(X, Y, FPanPlaneZ, ax, ay) then
   begin
    FPanX := FPanX + (ax - FPanPlaneAnchorX) * 0.2;
    FPanY := FPanY + (ay - FPanPlaneAnchorY) * 0.2;
   end;
  end;
 end;
end;

procedure TLasSceneController.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if Button <> FDownButton then Exit;
 FDown := False;
end;

procedure TLasSceneController.MouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint);
var
 delta: Double;
 stepDist: Double;
 minX, minY, minZ, maxX, maxY, maxZ: Double;
 originZ: Double;
 zPlane: Double;
 yawRad, pitchRad: Double;
 camX, camY, camZ: Double;
 dirX, dirY, dirZ: Double;
 distance: Double;
 t: Double;
 w, h: Integer;
const
 ZoomStepMetersLocal = 5.0;
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

  stepDist := ZoomStepMetersLocal;
  if FZoomToPlaneEnabled then
  begin
   if GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ) then
   begin
    originZ := (minZ + maxZ) * 0.5;
    zPlane := (minZ + FPlaneDeltaZ) - originZ;

    yawRad := DegToRad(FYaw);
    pitchRad := DegToRad(FPitch);

    if (FDistance <= 0) or IsNan(FDistance) or IsInfinite(FDistance) then
     distance := DefaultDistance3D
    else
     distance := FDistance;
    if distance <= 0 then distance := 1E-6;

    camX := distance * Sin(pitchRad) * Sin(yawRad) - FPanX;
    camY := distance * Sin(pitchRad) * Cos(yawRad) - FPanY;
    camZ := distance * Cos(pitchRad) - FPanZ;

    dirX := -Sin(pitchRad) * Sin(yawRad);
    dirY := -Sin(pitchRad) * Cos(yawRad);
    dirZ := -Cos(pitchRad);
    if Abs(dirZ) > 1E-12 then
    begin
     t := (zPlane - camZ) / dirZ;
     if (t > 0) and (not IsNan(t)) and (not IsInfinite(t)) then
     begin
      stepDist := t * EnsureRange(FZoomToPlaneK, 1E-6, 1E6);
      if stepDist < 1E-6 then stepDist := 1E-6;
     end;
    end;
   end;
  end;

  w := 0;
  h := 0;
  if FOGL <> nil then
  begin
   w := FOGL.Width;
   h := FOGL.Height;
  end;
  if (w > 0) and (h > 0) then
   Zoom3DBy(-delta * stepDist, w div 2, h div 2)
  else
  begin
   FDistance := FDistance - delta * stepDist;
   FDistance := EnsureRange(FDistance, 1E-12, 1E18);
  end;
 end;
end;

function TLasSceneController.CalcCombinedBBoxVisible(out AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Double): Boolean;
var
 i: Integer;
 ctx: TLasFileContext;
 minX, minY, minZ, maxX, maxY, maxZ: Double;
 first: Boolean;
begin
 Result := False;
 AMinX := 0; AMinY := 0; AMinZ := 0;
 AMaxX := 0; AMaxY := 0; AMaxZ := 0;

 if FContexts = nil then Exit;
 first := True;
 for i := FContexts.Count - 1 downto 0 do
 begin
  ctx := TLasFileContext(FContexts[i]);
  if ctx = nil then
  begin
   FContexts.Delete(i);
   Continue;
  end;

  try
   if (not ctx.Visible) or (ctx.Las = nil) or (ctx.Las.Source = nil) or (not ctx.Las.Source.IsOpen) then
    Continue;

   minX := ctx.Las.Source.Header.MinX;
   minY := ctx.Las.Source.Header.MinY;
   minZ := ctx.Las.Source.Header.MinZ;
   maxX := ctx.Las.Source.Header.MaxX;
   maxY := ctx.Las.Source.Header.MaxY;
   maxZ := ctx.Las.Source.Header.MaxZ;

   if first then
   begin
    AMinX := minX; AMinY := minY; AMinZ := minZ;
    AMaxX := maxX; AMaxY := maxY; AMaxZ := maxZ;
    first := False;
   end
   else
   begin
    if minX < AMinX then AMinX := minX;
    if minY < AMinY then AMinY := minY;
    if minZ < AMinZ then AMinZ := minZ;
    if maxX > AMaxX then AMaxX := maxX;
    if maxY > AMaxY then AMaxY := maxY;
    if maxZ > AMaxZ then AMaxZ := maxZ;
   end;
  except
   FContexts.Delete(i);
  end;
 end;

 Result := not first;
end;

function TLasSceneController.DefaultDistance3D: Double;
var
 minX, minY, minZ, maxX, maxY, maxZ: Double;
begin
 Result := 10;
 if not GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ) then Exit;
 Result := Max(Max(maxX - minX, maxY - minY), maxZ - minZ) * 2;
 if Result < 10 then Result := 10;
end;

procedure TLasSceneController.InitGL;
var
 i: Integer;
 ctx: TLasFileContext;
begin
 if FContexts = nil then Exit;
 for i := 0 to FContexts.Count - 1 do
 begin
  ctx := TLasFileContext(FContexts[i]);
  if (ctx <> nil) and (ctx.Tiles <> nil) then
   ctx.Tiles.InitGL;
 end;
end;

procedure TLasSceneController.Render;
var
 proj, mv: TMat4;
 mvp: TMat4;
 w, h: Integer;
 aspect: Double;
 zNear, zFar: Double;
 distance: Double;
 defaultDistance: Double;
 effectiveDistance: Double;
 frac: Single;
 effectivePointSize: Single;
 minX, minY, minZ: Double;
 maxX, maxY, maxZ: Double;
 originX, originY, originZ: Double;
 zPlane: Double;
 yawRad, pitchRad: Double;
 camX, camY: Double;
 tileMinX, tileMinY, tileMaxX, tileMaxY: Double;
 tileCx, tileCy: Double;
 distToTile: Double;
 tileLimit: Double;
 cloudOriginX, cloudOriginY, cloudOriginZ: Double;
 deltaX, deltaY, deltaZ: Double;
 tr: TMat4;
 mvpCloud: TMat4;
 i, ti: Integer;
 pi: Integer;
 px, py, pz: Double;
 ctx: TLasFileContext;
begin
 if (FOGL = nil) then Exit;

 if not GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ) then Exit;

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
  distance := Max(maxX - minX, maxY - minY) * 0.5 * FOrthoScale;
  if distance < 1 then distance := 1;
  glOrtho(-distance * aspect + FPanX, distance * aspect + FPanX,
          -distance + FPanY, distance + FPanY,
          -10000, 10000);
  effectiveDistance := distance;
 end
 else
 begin
  defaultDistance := Max(Max(maxX - minX, maxY - minY), maxZ - minZ) * 2;
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
  distance := effectiveDistance;
  glTranslated(0, 0, -distance);
  glRotated(FPitch, 1, 0, 0);
  glRotated(FYaw, 0, 0, 1);
  glTranslated(FPanX, FPanY, FPanZ);
 end;
 glGetFloatv(GL_MODELVIEW_MATRIX, @mv[0]);

 MatMul(mvp, proj, mv);

 frac := EnsureRange(FRenderFrac, 0.0, 1.0);
 effectivePointSize := EnsureRange(FPointSize, 1.0, 4.0);

 originX := (minX + maxX) * 0.5;
 originY := (minY + maxY) * 0.5;
 originZ := (minZ + maxZ) * 0.5;

 if FBlendEnabled then
 begin
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
 end
 else
  glDisable(GL_BLEND);

 yawRad := DegToRad(FYaw);
 pitchRad := DegToRad(FPitch);
 camX := distance * Sin(pitchRad) * Sin(yawRad) - FPanX;
 camY := distance * Sin(pitchRad) * Cos(yawRad) - FPanY;
 tileLimit := FDynaLodTileSize;

 if FContexts <> nil then
  for i := 0 to FContexts.Count - 1 do
  begin
   ctx := TLasFileContext(FContexts[i]);
   if (ctx = nil) or (not ctx.Visible) then Continue;
   if (ctx.Las = nil) or (ctx.Las.Source = nil) or (not ctx.Las.Source.IsOpen) then Continue;
   if (ctx.Tiles = nil) then Continue;
   ctx.Tiles.GetGridXYBBox(tileMinX, tileMinY, tileMaxX, tileMaxY, cloudOriginX, cloudOriginY);
   cloudOriginZ := (ctx.Las.Source.Header.MinZ + ctx.Las.Source.Header.MaxZ) * 0.5;

   deltaX := cloudOriginX - originX;
   deltaY := cloudOriginY - originY;
   deltaZ := cloudOriginZ - originZ;

   tr := MatTranslate(deltaX, deltaY, deltaZ);
   MatMul(mvpCloud, mvp, tr);

   if FUseDyna then
    ctx.Tiles.RenderDyna(mvpCloud, effectivePointSize, FAlpha, FClipEnabled, FClipZ)
   else if frac < 1 then
    ctx.Tiles.RenderProgress(mvpCloud, effectivePointSize, FAlpha, frac, FClipEnabled, FClipZ)
   else if (tileLimit > 0) then
   begin
    for ti := 0 to ctx.Tiles.TileCount - 1 do
    begin
     if not ctx.Tiles.GetTileRect(ti, tileMinX, tileMinY, tileMaxX, tileMaxY) then
      Continue;
     tileCx := ((tileMinX + tileMaxX) * 0.5) - originX;
     tileCy := ((tileMinY + tileMaxY) * 0.5) - originY;
     distToTile := Hypot(tileCx - camX, tileCy - camY);

     if distToTile >= tileLimit then
     begin
      if ctx.Tiles.TilesDyna[ti] <> nil then
       ctx.Tiles.TilesDyna[ti].Render(mvpCloud, effectivePointSize, FAlpha, FClipEnabled, FClipZ)
      else if ctx.Tiles.Tiles[ti] <> nil then
       ctx.Tiles.Tiles[ti].Render(mvpCloud, effectivePointSize, FAlpha, FClipEnabled, FClipZ);
     end
     else
     begin
      if ctx.Tiles.Tiles[ti] <> nil then
       ctx.Tiles.Tiles[ti].Render(mvpCloud, effectivePointSize, FAlpha, FClipEnabled, FClipZ);
     end;
    end;
   end
   else
    ctx.Tiles.Render(mvpCloud, effectivePointSize, FAlpha, FClipEnabled, FClipZ);

   if FShowTileBBoxes then
   begin
    glPushMatrix;
    glTranslated(deltaX, deltaY, deltaZ);
    ctx.Tiles.RenderTileBBoxes(ctx.Las.Source.Header.MinZ, ctx.Las.Source.Header.MaxZ);
    glPopMatrix;
   end;
  end;

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

 if PoslPointCount >= 2 then
 begin
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_LIGHTING);
  glColor4f(1, 0, 0, 1);
  glLineWidth(2);
  glBegin(GL_LINE_STRIP);
   for pi := 0 to PoslPointCount - 1 do
   begin
    if GetPoslPoint(pi, px, py, pz) then
     glVertex3f((px - originX), (py - originY), (pz - originZ));
   end;
  glEnd;
  glLineWidth(1);
 end;

 glDisable(GL_BLEND);
end;

end.
