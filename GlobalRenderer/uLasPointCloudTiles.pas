unit uLasPointCloudTiles;

{$mode Delphi}{$H+}

interface

uses
 Classes, SysUtils, Math,
 ogcLas,
 uLasPointCloudGpu;

type
 TLasTilesProgressEvent = procedure(Sender: TObject; APos, AMax: Integer) of object;

 TLasPointColorMode = (lpcmRGB, lpcmIntensity, lpcmReturnNumber, lpcmClassification, lpcmScanAngleRank);

 TTileRec = record
  MinX: Double;
  MinY: Double;
  MaxX: Double;
  MaxY: Double;
 end;

 TPointBuf = record
  Data: array of TLasPointPacked;
  Count: Integer;
  procedure Add(const P: TLasPointPacked);
 end;

 TLasPointCloudTiles = class
 private
  FTiles: array of TLasPointCloudGpu;
  FTilesDyna: array of TLasPointCloudGpu;
  FTileRects: array of TTileRec;
  FTotalCount: Int64;
  FTotalCountDyna: Int64;
  FGLReady: Boolean;
  FDrawTileBBoxes: Boolean;
  FColorMode: TLasPointColorMode;

  FGridMinX: Double;
  FGridMinY: Double;
  FGridMaxX: Double;
  FGridMaxY: Double;
  FGridNx: Integer;
  FGridNy: Integer;
  FGridDx: Double;
  FGridDy: Double;

  FOriginX: Double;
  FOriginY: Double;
  FOriginZ: Double;

  FOnProgress: TLasTilesProgressEvent;

  function GetTileCount: Integer;
  function GetTile(Index: Integer): TLasPointCloudGpu;
  function GetTileDyna(Index: Integer): TLasPointCloudGpu;
  procedure ClearTiles;
  procedure BuildTileGrid(const AMinX, AMinY, AMaxX, AMaxY: Double; ATileCount: Integer);
  function CalcTargetTileCount(ALas: TogsLas): Integer;
 public
  constructor Create;
  destructor Destroy; override;

  procedure InitGL;
  procedure ReleaseGL;

  procedure BuildFromLas(ALas: TogsLas; AMaxPointsTotal: Int64 = 0);
  procedure Render(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                   AClipEnabled: Boolean = False; AClipZ: Single = 0);
  procedure RenderDyna(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                      AClipEnabled: Boolean = False; AClipZ: Single = 0);
  procedure RenderProgress(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                          AFrac: Single; AClipEnabled: Boolean = False; AClipZ: Single = 0);

  procedure RenderHighlight(const MVP: TMat4; APointSize: Single;
                            APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                            AColR, AColG, AColB, AColA: Single;
                            AClipEnabled: Boolean = False; AClipZ: Single = 0);

  procedure RenderHighlightDyna(const MVP: TMat4; APointSize: Single;
                               APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                               AColR, AColG, AColB, AColA: Single;
                               AClipEnabled: Boolean = False; AClipZ: Single = 0);

  procedure RenderHighlightProgress(const MVP: TMat4; APointSize: Single;
                                   AFrac: Single;
                                   APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                   AColR, AColG, AColB, AColA: Single;
                                   AClipEnabled: Boolean = False; AClipZ: Single = 0);

  procedure RenderHighlightCulled(const MVP: TMat4; APointSize: Single;
                                 APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                 AInterestRadiusXY: Single;
                                 AColR, AColG, AColB, AColA: Single;
                                 AClipEnabled: Boolean = False; AClipZ: Single = 0);

  procedure RenderHighlightDynaCulled(const MVP: TMat4; APointSize: Single;
                                     APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                     AInterestRadiusXY: Single;
                                     AColR, AColG, AColB, AColA: Single;
                                     AClipEnabled: Boolean = False; AClipZ: Single = 0);

  procedure RenderHighlightProgressCulled(const MVP: TMat4; APointSize: Single;
                                         AFrac: Single;
                                         APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                         AInterestRadiusXY: Single;
                                         AColR, AColG, AColB, AColA: Single;
                                         AClipEnabled: Boolean = False; AClipZ: Single = 0);

  procedure RenderTileBBoxes(AMinZ, AMaxZ: Single);

  procedure GetGridXYBBox(out AMinX, AMinY, AMaxX, AMaxY: Double; out AOriginX, AOriginY: Double);

  procedure GetGridTileStep(out ADx, ADy: Double);

  function GetTileRect(Index: Integer; out AMinX, AMinY, AMaxX, AMaxY: Double): Boolean;

  property DrawTileBBoxes: Boolean read FDrawTileBBoxes write FDrawTileBBoxes;

  property ColorMode: TLasPointColorMode read FColorMode write FColorMode;

  property OnProgress: TLasTilesProgressEvent read FOnProgress write FOnProgress;

  property TileCount: Integer read GetTileCount;
  property Tiles[Index: Integer]: TLasPointCloudGpu read GetTile;
  property TilesDyna[Index: Integer]: TLasPointCloudGpu read GetTileDyna;
  property TotalCount: Int64 read FTotalCount;
  property TotalCountDyna: Int64 read FTotalCountDyna;
 end;

implementation uses ogcWriter;

const
 TARGET_TILE_BYTES = Int64(256) * 1024 * 1024;

function ClampF(const V, AMin, AMax: Double): Double;
begin
 if V < AMin then Result := AMin
 else if V > AMax then Result := AMax
 else Result := V;
end;

function RectIntersectsCircle(const R: TTileRec; const CX, CY, Rad: Double): Boolean;
var
 px, py: Double;
 dx, dy: Double;
begin
 px := ClampF(CX, R.MinX, R.MaxX);
 py := ClampF(CY, R.MinY, R.MaxY);
 dx := CX - px;
 dy := CY - py;
 Result := (dx * dx + dy * dy) <= (Rad * Rad);
end;

constructor TLasPointCloudTiles.Create;
begin
 inherited Create;
 FTotalCount := 0;
 FTotalCountDyna := 0;
 FGLReady := False;
 FDrawTileBBoxes := False;
 FColorMode := lpcmRGB;
 FGridMinX := 0;
 FGridMinY := 0;
 FGridMaxX := 0;
 FGridMaxY := 0;
 FGridNx := 0;
 FGridNy := 0;
 FGridDx := 0;
 FGridDy := 0;

 FOriginX := 0;
 FOriginY := 0;
 FOriginZ := 0;
end;

procedure TPointBuf.Add(const P: TLasPointPacked);
var newCap: Integer;
begin
 if Count >= Length(Data) then
 begin
  newCap := Length(Data);
  if newCap < 1024 then newCap := 1024 else newCap := newCap * 2;
  SetLength(Data, newCap);
 end;
 Data[Count] := P;
 Inc(Count);
end;

destructor TLasPointCloudTiles.Destroy;
begin
 ReleaseGL;
 ClearTiles;
 inherited Destroy;
end;

function TLasPointCloudTiles.GetTileCount: Integer;
begin
 Result := Length(FTiles);
end;

function TLasPointCloudTiles.GetTile(Index: Integer): TLasPointCloudGpu;
begin
 if (Index < 0) or (Index >= Length(FTiles)) then Exit(nil);
 Result := FTiles[Index];
end;

function TLasPointCloudTiles.GetTileDyna(Index: Integer): TLasPointCloudGpu;
begin
 if (Index < 0) or (Index >= Length(FTilesDyna)) then Exit(nil);
 Result := FTilesDyna[Index];
end;

procedure TLasPointCloudTiles.ClearTiles;
var i: Integer;
begin
 for i := 0 to High(FTiles) do
  FreeAndNil(FTiles[i]);
 SetLength(FTiles, 0);

 for i := 0 to High(FTilesDyna) do
  FreeAndNil(FTilesDyna[i]);
 SetLength(FTilesDyna, 0);

 SetLength(FTileRects, 0);
 FTotalCount := 0;
 FTotalCountDyna := 0;
end;

procedure TLasPointCloudTiles.InitGL;
var i: Integer;
begin
 FGLReady := True;
 for i := 0 to High(FTiles) do
  if FTiles[i] <> nil then begin
   WriteIn(['Tile1', i]);
   FTiles[i].InitGL;
   WriteIn(['Tile2', i]);
  end;

 WriteIn(['endBaseTiles']);
 for i := 0 to High(FTilesDyna) do
  if FTilesDyna[i] <> nil then
   FTilesDyna[i].InitGL;
 WriteIn(['enddynaTiles']);
end;

procedure TLasPointCloudTiles.ReleaseGL;
var i: Integer;
begin
 for i := 0 to High(FTiles) do
  if FTiles[i] <> nil then
   FTiles[i].ReleaseGL;

 for i := 0 to High(FTilesDyna) do
  if FTilesDyna[i] <> nil then
   FTilesDyna[i].ReleaseGL;

 FGLReady := False;
end;

function TLasPointCloudTiles.CalcTargetTileCount(ALas: TogsLas): Integer;
var
 fs: Int64;
 fn: AnsiString;
 strm: TFileStream;
begin
 Result := 1;
 if (ALas = nil) or (ALas.Source = nil) or (not ALas.Source.IsOpen) then Exit;

 fn := ALas.FileName;
 if fn = '' then Exit;
 if not FileExists(fn) then Exit;

 fs := 0;
 try
  strm := TFileStream.Create(fn, fmOpenRead or fmShareDenyNone);
  try
   fs := strm.Size;
  finally
   strm.Free;
  end;
 except
  fs := 0;
 end;

 if fs <= 0 then Exit;
 Result := Ceil(fs / TARGET_TILE_BYTES);
 if Result < 1 then Result := 1;
end;

procedure TLasPointCloudTiles.BuildTileGrid(const AMinX, AMinY, AMaxX, AMaxY: Double; ATileCount: Integer);
var
 w, h, aspect: Double;
 nx, ny: Integer;
 swapAxes: Boolean;
 ix, iy, idx: Integer;
 dx, dy: Double;
 minX, minY, maxX, maxY: Double;
begin
 if ATileCount < 1 then ATileCount := 1;

 w := AMaxX - AMinX;
 h := AMaxY - AMinY;
 if w <= 0 then w := 1;
 if h <= 0 then h := 1;

 aspect := w / h;
 swapAxes := False;
 if aspect < 1 then
 begin
  swapAxes := True;
  aspect := 1 / aspect;
 end;

 nx := Ceil(Sqrt(ATileCount * aspect));
 if nx < 1 then nx := 1;
 ny := Ceil(ATileCount / nx);
 if ny < 1 then ny := 1;

 if swapAxes then
 begin
  idx := nx;
  nx := ny;
  ny := idx;
 end;

 SetLength(FTileRects, nx * ny);

 FGridMinX := AMinX;
 FGridMinY := AMinY;
 FGridMaxX := AMaxX;
 FGridMaxY := AMaxY;
 FGridNx := nx;
 FGridNy := ny;

 dx := (AMaxX - AMinX) / nx;
 dy := (AMaxY - AMinY) / ny;
 if dx <= 0 then dx := 1;
 if dy <= 0 then dy := 1;

 FGridDx := dx;
 FGridDy := dy;

 idx := 0;
 for iy := 0 to ny - 1 do
  for ix := 0 to nx - 1 do
  begin
   minX := AMinX + ix * dx;
   maxX := AMinX + (ix + 1) * dx;
   minY := AMinY + iy * dy;
   maxY := AMinY + (iy + 1) * dy;

   if ix = nx - 1 then maxX := AMaxX;
   if iy = ny - 1 then maxY := AMaxY;

   FTileRects[idx].MinX := minX;
   FTileRects[idx].MinY := minY;
   FTileRects[idx].MaxX := maxX;
   FTileRects[idx].MaxY := maxY;
   Inc(idx);
  end;
end;

procedure TLasPointCloudTiles.BuildFromLas(ALas: TogsLas; AMaxPointsTotal: Int64);
var
 minX, minY, maxX, maxY: Double;
 headerMinX, headerMinY, headerMaxX, headerMaxY: Double;
 originX, originY, originZ: Double;
 tileTarget: Integer;
 i: Integer;
 perTileMax: Int64;
 cnt: Int64;
 pt: Int64;
 step: Int64;
 stepBBox: Int64;
 x, y, z: Double;
 r, g, b: Word;
 intensity: Word;
 flags: Byte;
 classif: Byte;
 scanAngleRank: ShortInt;
 userData: Byte;
 pointSourceID: Word;
 cR, cG, cB: Byte;
 ix, iy, tileIndex: Integer;
 p: TLasPointPacked;
 bufs: array of TPointBuf;
 dynaCount: Integer;
 j: Integer;
 maxPos: Integer;
 posNow: Integer;
 lastPos: Integer;
 maxIntensity: Word;
 minScanAngle, maxScanAngle: ShortInt;
 useAttrRanges: Boolean;

 function ColorWordToByte(V: Word): Byte;
 begin
  if V <= 255 then Result := Byte(V)
  else Result := Byte(V shr 8);
 end;

function ClampByte(V: Integer): Byte;
begin
 if V < 0 then V := 0;
 if V > 255 then V := 255;
 Result := Byte(V);
end;

function ScaleToByte(V: Int64; Den: Int64): Byte;
begin
 if Den <= 0 then
 begin
  Result := 0;
  Exit;
 end;
 Result := ClampByte(Round(V * 255 / Den));
end;

procedure ColorFromReturnNumber(ReturnNum: Integer; out RR, GG, BB: Byte);
begin
 case ReturnNum and 7 of
  1: begin RR := 255; GG := 0; BB := 0; end;
  2: begin RR := 0; GG := 255; BB := 0; end;
  3: begin RR := 0; GG := 0; BB := 255; end;
  4: begin RR := 255; GG := 255; BB := 0; end;
  5: begin RR := 0; GG := 255; BB := 255; end;
  6: begin RR := 255; GG := 0; BB := 255; end;
  7: begin RR := 255; GG := 255; BB := 255; end;
 else
  begin RR := 0; GG := 0; BB := 0; end;
 end;
end;

procedure ColorFromClassification(ClassId: Integer; out RR, GG, BB: Byte);
begin
 case ClassId of
  0: begin RR := 96; GG := 96; BB := 96; end;
  1: begin RR := 160; GG := 120; BB := 64; end;
  2: begin RR := 0; GG := 200; BB := 0; end;
  3: begin RR := 0; GG := 128; BB := 255; end;
  4: begin RR := 255; GG := 160; BB := 0; end;
  5: begin RR := 255; GG := 255; BB := 0; end;
  6: begin RR := 0; GG := 255; BB := 255; end;
  7: begin RR := 255; GG := 0; BB := 255; end;
  8: begin RR := 180; GG := 180; BB := 180; end;
  9: begin RR := 0; GG := 64; BB := 255; end;
 else
  begin
   RR := Byte((ClassId * 97) and 255);
   GG := Byte((ClassId * 57) and 255);
   BB := Byte((ClassId * 17) and 255);
  end;
 end;
end;

function NextRnd(var S: UInt32): UInt32;
begin
 S := S xor (S shl 13);
 S := S xor (S shr 17);
 S := S xor (S shl 5);
 Result := S;
end;

procedure ShufflePacked(var A: array of TLasPointPacked; N: Integer; Seed: UInt32);
var
 k, idx: Integer;
 tmp: TLasPointPacked;
 s: UInt32;
begin
 if N <= 1 then Exit;
 s := Seed;
 for k := N - 1 downto 1 do
 begin
  idx := Integer(NextRnd(s) mod UInt32(k + 1));
  tmp := A[k];
  A[k] := A[idx];
  A[idx] := tmp;
 end;
end;
begin
 ClearTiles;
 if (ALas = nil) or (ALas.Source = nil) or (not ALas.Source.IsOpen) then Exit;

 maxPos := 1000;
 lastPos := -1;
 if Assigned(FOnProgress) then
  FOnProgress(Self, 0, maxPos);

 headerMinX := ALas.Source.Header.MinX;
 headerMinY := ALas.Source.Header.MinY;
 headerMaxX := ALas.Source.Header.MaxX;
 headerMaxY := ALas.Source.Header.MaxY;

 minX := headerMinX;
 minY := headerMinY;
 maxX := headerMaxX;
 maxY := headerMaxY;

 cnt := ALas.Source.PointCount;
 stepBBox := 1;
 if cnt > 5000000 then
  stepBBox := Ceil(cnt / 5000000);

 if cnt > 0 then
 begin
  minX := 1E300;
  minY := 1E300;
  maxX := -1E300;
  maxY := -1E300;
  pt := 0;
  while pt < cnt do
  begin
   if ALas.Source.GetPointXYZRGBAttrs(pt, x, y, z, intensity, flags, classif, scanAngleRank, userData, pointSourceID, r, g, b) then
   begin
    if x < minX then minX := x;
    if y < minY then minY := y;
    if x > maxX then maxX := x;
    if y > maxY then maxY := y;
   end;
   Inc(pt, stepBBox);
  end;

  if (minX > maxX) or (minY > maxY) then
  begin
   minX := headerMinX;
   minY := headerMinY;
   maxX := headerMaxX;
   maxY := headerMaxY;
  end
  else
  begin
   if (minX > headerMinX) and (headerMinX < headerMaxX) then minX := headerMinX;
   if (minY > headerMinY) and (headerMinY < headerMaxY) then minY := headerMinY;
   if (maxX < headerMaxX) and (headerMinX < headerMaxX) then maxX := headerMaxX;
   if (maxY < headerMaxY) and (headerMinY < headerMaxY) then maxY := headerMaxY;
  end;
 end;

 originX := (minX + maxX) * 0.5;
 originY := (minY + maxY) * 0.5;
 originZ := (ALas.Source.Header.MinZ + ALas.Source.Header.MaxZ) * 0.5;

 FOriginX := originX;
 FOriginY := originY;
 FOriginZ := originZ;

 tileTarget := CalcTargetTileCount(ALas);
 BuildTileGrid(minX, minY, maxX, maxY, tileTarget);

 SetLength(FTiles, Length(FTileRects));
 SetLength(FTilesDyna, Length(FTileRects));

 if (FGridNx <= 0) or (FGridNy <= 0) or (Length(FTileRects) <= 0) then Exit;

 step := 1;
 if (AMaxPointsTotal > 0) and (cnt > AMaxPointsTotal) then
  step := Ceil(cnt / AMaxPointsTotal);

 WriteIn(['BuildFromLas', 'cnt', cnt, 'MaxPointsTotal', AMaxPointsTotal, 'step', step]);

 useAttrRanges := (FColorMode = lpcmIntensity) or (FColorMode = lpcmScanAngleRank);
 if useAttrRanges then
 begin
  maxIntensity := 0;
  minScanAngle := 127;
  maxScanAngle := -127;
  pt := 0;
  while pt < cnt do
  begin
   if not ALas.Source.GetPointXYZRGBAttrs(pt, x, y, z, intensity, flags, classif, scanAngleRank, userData, pointSourceID, r, g, b) then
   begin
    Inc(pt, step);
    Continue;
   end;
   if intensity > maxIntensity then maxIntensity := intensity;
   if scanAngleRank < minScanAngle then minScanAngle := scanAngleRank;
   if scanAngleRank > maxScanAngle then maxScanAngle := scanAngleRank;
   Inc(pt, step);
  end;
  if minScanAngle > maxScanAngle then
  begin
   minScanAngle := 0;
   maxScanAngle := 0;
  end;
 end;

 SetLength(bufs, Length(FTileRects));
 for i := 0 to High(bufs) do
  bufs[i].Count := 0;

 pt := 0;
 while pt < cnt do
 begin
  if (cnt > 0) and (Assigned(FOnProgress)) then
  begin
   posNow := Integer((pt * 700) div cnt);
   if posNow <> lastPos then
   begin
    lastPos := posNow;
    FOnProgress(Self, posNow, maxPos);
   end;
  end;

  if not ALas.Source.GetPointXYZRGBAttrs(pt, x, y, z, intensity, flags, classif, scanAngleRank, userData, pointSourceID, r, g, b) then
  begin
   Inc(pt, step);
   Continue;
  end;

  ix := Trunc((x - FGridMinX) / FGridDx);
  iy := Trunc((y - FGridMinY) / FGridDy);
  if ix < 0 then ix := 0;
  if iy < 0 then iy := 0;
  if ix >= FGridNx then ix := FGridNx - 1;
  if iy >= FGridNy then iy := FGridNy - 1;
  tileIndex := iy * FGridNx + ix;
  if (tileIndex < 0) or (tileIndex > High(bufs)) then
  begin
   Inc(pt, step);
   Continue;
  end;

  case FColorMode of
   lpcmRGB:
    begin
     cR := ColorWordToByte(r);
     cG := ColorWordToByte(g);
     cB := ColorWordToByte(b);
    end;
   lpcmIntensity:
    begin
     cR := ScaleToByte(Intensity, maxIntensity);
     cG := cR;
     cB := cR;
    end;
   lpcmReturnNumber:
    ColorFromReturnNumber(flags and 7, cR, cG, cB);
   lpcmClassification:
    ColorFromClassification(classif and 31, cR, cG, cB);
  else
    begin
     cR := ScaleToByte(scanAngleRank - minScanAngle, Int64(maxScanAngle) - Int64(minScanAngle));
     cG := 0;
     cB := Byte(255 - cR);
    end;
  end;
  p.X := (x - originX);
  p.Y := (y - originY);
  p.Z := (z - originZ);
  p.R := cR;
  p.G := cG;
  p.B := cB;
  p.A := 255;

  bufs[tileIndex].Add(p);
  Inc(pt, step);
 end;

 if AMaxPointsTotal > 0 then
  perTileMax := Ceil(AMaxPointsTotal / Max(1, Length(FTileRects)))
 else
  perTileMax := 0;

 WriteIn(['BuildFromLas', 'TileCount', Length(FTileRects), 'perTileMax', perTileMax]);

 FTotalCount := 0;
 FTotalCountDyna := 0;
 for i := 0 to High(FTiles) do
 begin
  if (Length(FTiles) > 0) and (Assigned(FOnProgress)) then
  begin
   posNow := 700 + Integer((Int64(i + 1) * 300) div Length(FTiles));
   if posNow <> lastPos then
   begin
    lastPos := posNow;
    FOnProgress(Self, posNow, maxPos);
   end;
  end;

  FTiles[i] := TLasPointCloudGpu.Create;
  if FGLReady then FTiles[i].InitGL;

  FTilesDyna[i] := TLasPointCloudGpu.Create;
  if FGLReady then FTilesDyna[i].InitGL;

  if (perTileMax > 0) and (bufs[i].Count > perTileMax) then
   bufs[i].Count := perTileMax;

  if bufs[i].Count > 1 then
   ShufflePacked(bufs[i].Data, bufs[i].Count, UInt32(i) * 747796405 + 2891336453);

  if bufs[i].Count > 0 then
   FTiles[i].BuildFromPacked(@bufs[i].Data[0], bufs[i].Count);

  if bufs[i].Count > 0 then
   FTotalCount := FTotalCount + bufs[i].Count;

  dynaCount := Ceil(bufs[i].Count * 0.2);
  if dynaCount > bufs[i].Count then dynaCount := bufs[i].Count;
  if dynaCount < 0 then dynaCount := 0;

  if dynaCount > 0 then
  begin
   FTilesDyna[i].BuildFromPacked(@bufs[i].Data[0], dynaCount);
   FTotalCountDyna := FTotalCountDyna + dynaCount;
  end;
 end;

 WriteIn(['BuildFromLas', 'TotalCount', FTotalCount, 'TotalCountDyna', FTotalCountDyna]);

 for i := 0 to High(bufs) do
  SetLength(bufs[i].Data, 0);

 if Assigned(FOnProgress) then
  FOnProgress(Self, maxPos, maxPos);
end;

procedure TLasPointCloudTiles.Render(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                                    AClipEnabled: Boolean; AClipZ: Single);
var i: Integer;
begin
 for i := 0 to High(FTiles) do
  if FTiles[i] <> nil then
   FTiles[i].Render(MVP, APointSize, AAlpha, AClipEnabled, AClipZ);
end;

procedure TLasPointCloudTiles.RenderDyna(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                                        AClipEnabled: Boolean; AClipZ: Single);
var i: Integer;
begin
 for i := 0 to High(FTilesDyna) do
  if FTilesDyna[i] <> nil then
   FTilesDyna[i].Render(MVP, APointSize, AAlpha, AClipEnabled, AClipZ);
end;

procedure TLasPointCloudTiles.RenderProgress(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                                            AFrac: Single; AClipEnabled: Boolean; AClipZ: Single);
var
 i: Integer;
 n: Integer;
 frac: Single;
begin
 frac := EnsureRange(AFrac, 0.0, 1.0);
 for i := 0 to High(FTiles) do
  if FTiles[i] <> nil then
  begin
   n := Ceil(FTiles[i].Count * frac);
   FTiles[i].RenderCount(MVP, APointSize, AAlpha, n, AClipEnabled, AClipZ);
  end;
end;

procedure TLasPointCloudTiles.RenderHighlight(const MVP: TMat4; APointSize: Single;
                                             APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                             AColR, AColG, AColB, AColA: Single;
                                             AClipEnabled: Boolean; AClipZ: Single);
var i: Integer;
begin
 for i := 0 to High(FTiles) do
  if FTiles[i] <> nil then
   FTiles[i].RenderHighlight(MVP, APointSize,
                             APickX, APickY, APickZ, APickRadius, APickZRadius,
                             AColR, AColG, AColB, AColA,
                             AClipEnabled, AClipZ);
end;

procedure TLasPointCloudTiles.RenderHighlightDyna(const MVP: TMat4; APointSize: Single;
                                                 APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                                 AColR, AColG, AColB, AColA: Single;
                                                 AClipEnabled: Boolean; AClipZ: Single);
var i: Integer;
begin
 for i := 0 to High(FTilesDyna) do
  if FTilesDyna[i] <> nil then
   FTilesDyna[i].RenderHighlight(MVP, APointSize,
                                 APickX, APickY, APickZ, APickRadius, APickZRadius,
                                 AColR, AColG, AColB, AColA,
                                 AClipEnabled, AClipZ);
end;

procedure TLasPointCloudTiles.RenderHighlightProgress(const MVP: TMat4; APointSize: Single;
                                                     AFrac: Single;
                                                     APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                                     AColR, AColG, AColB, AColA: Single;
                                                     AClipEnabled: Boolean; AClipZ: Single);
var
 i: Integer;
 n: Integer;
 frac: Single;
begin
 frac := EnsureRange(AFrac, 0.0, 1.0);
 for i := 0 to High(FTiles) do
  if FTiles[i] <> nil then
  begin
   n := Ceil(FTiles[i].Count * frac);
   FTiles[i].RenderHighlightCount(MVP, APointSize, n,
                                  APickX, APickY, APickZ, APickRadius, APickZRadius,
                                  AColR, AColG, AColB, AColA,
                                  AClipEnabled, AClipZ);
  end;
end;

procedure TLasPointCloudTiles.RenderTileBBoxes(AMinZ, AMaxZ: Single);
var i: Integer;
begin
 if not FDrawTileBBoxes then Exit;
 for i := 0 to High(FTileRects) do
  TLasPointCloudGpu.DrawBBoxLines((FTileRects[i].MinX - FOriginX), (FTileRects[i].MinY - FOriginY), (AMinZ - FOriginZ),
                                  (FTileRects[i].MaxX - FOriginX), (FTileRects[i].MaxY - FOriginY), (AMaxZ - FOriginZ));
end;

procedure TLasPointCloudTiles.GetGridXYBBox(out AMinX, AMinY, AMaxX, AMaxY: Double; out AOriginX, AOriginY: Double);
begin
 AMinX := FGridMinX;
 AMinY := FGridMinY;
 AMaxX := FGridMaxX;
 AMaxY := FGridMaxY;
 AOriginX := FOriginX;
 AOriginY := FOriginY;
end;

procedure TLasPointCloudTiles.GetGridTileStep(out ADx, ADy: Double);
begin
 ADx := FGridDx;
 ADy := FGridDy;
end;

function TLasPointCloudTiles.GetTileRect(Index: Integer; out AMinX, AMinY, AMaxX, AMaxY: Double): Boolean;
begin
 Result := (Index >= 0) and (Index <= High(FTileRects));
 if not Result then Exit;
 AMinX := FTileRects[Index].MinX;
 AMinY := FTileRects[Index].MinY;
 AMaxX := FTileRects[Index].MaxX;
 AMaxY := FTileRects[Index].MaxY;
end;

procedure TLasPointCloudTiles.RenderHighlightCulled(const MVP: TMat4; APointSize: Single;
                                                   APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                                   AInterestRadiusXY: Single;
                                                   AColR, AColG, AColB, AColA: Single;
                                                   AClipEnabled: Boolean; AClipZ: Single);
var
 i: Integer;
 rad: Double;
begin
 rad := AInterestRadiusXY;
 if rad <= 0 then rad := APickRadius;
 if rad <= 0 then Exit;

 for i := 0 to High(FTiles) do
  if (FTiles[i] <> nil) and RectIntersectsCircle(FTileRects[i], APickX, APickY, rad) then
   FTiles[i].RenderHighlight(MVP, APointSize,
                             APickX, APickY, APickZ, APickRadius, APickZRadius,
                             AColR, AColG, AColB, AColA,
                             AClipEnabled, AClipZ);
end;

procedure TLasPointCloudTiles.RenderHighlightDynaCulled(const MVP: TMat4; APointSize: Single;
                                                       APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                                       AInterestRadiusXY: Single;
                                                       AColR, AColG, AColB, AColA: Single;
                                                       AClipEnabled: Boolean; AClipZ: Single);
var
 i: Integer;
 rad: Double;
begin
 rad := AInterestRadiusXY;
 if rad <= 0 then rad := APickRadius;
 if rad <= 0 then Exit;

 for i := 0 to High(FTilesDyna) do
  if (FTilesDyna[i] <> nil) and RectIntersectsCircle(FTileRects[i], APickX, APickY, rad) then
   FTilesDyna[i].RenderHighlight(MVP, APointSize,
                                 APickX, APickY, APickZ, APickRadius, APickZRadius,
                                 AColR, AColG, AColB, AColA,
                                 AClipEnabled, AClipZ);
end;

procedure TLasPointCloudTiles.RenderHighlightProgressCulled(const MVP: TMat4; APointSize: Single;
                                                           AFrac: Single;
                                                           APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                                           AInterestRadiusXY: Single;
                                                           AColR, AColG, AColB, AColA: Single;
                                                           AClipEnabled: Boolean; AClipZ: Single);
var
 i: Integer;
 n: Integer;
 frac: Single;
 rad: Double;
begin
 rad := AInterestRadiusXY;
 if rad <= 0 then rad := APickRadius;
 if rad <= 0 then Exit;

 frac := EnsureRange(AFrac, 0.0, 1.0);
 for i := 0 to High(FTiles) do
  if (FTiles[i] <> nil) and RectIntersectsCircle(FTileRects[i], APickX, APickY, rad) then
  begin
   n := Ceil(FTiles[i].Count * frac);
   FTiles[i].RenderHighlightCount(MVP, APointSize, n,
                                  APickX, APickY, APickZ, APickRadius, APickZRadius,
                                  AColR, AColG, AColB, AColA,
                                  AClipEnabled, AClipZ);
  end;
end;

end.
