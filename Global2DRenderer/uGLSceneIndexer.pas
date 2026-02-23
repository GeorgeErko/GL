unit uGLSceneIndexer;

{$mode objfpc}

interface

uses
 Classes, SysUtils, Math, fgl,
 ogcBasic;

type
 TGLObjectId = Int64;
 TGLTileId = Int64;
 TGLObjectIdArray = array of TGLObjectId;
 TGLTileIdArray = array of TGLTileId;

 TGLSceneObjectEntry = class
 public
  Id: TGLObjectId;
  BBox: TogsRect;
  Tiles: TGLTileIdArray;
  constructor Create(AId: TGLObjectId);
  destructor Destroy; override;
 end;

 TGLSceneTileBucket = class
 public
  TileId: TGLTileId;
  ObjectIds: array of TGLObjectId;
  ObjectCount: Integer;
  constructor Create(ATileId: TGLTileId);
  procedure AddObject(AId: TGLObjectId);
  procedure RemoveObject(AId: TGLObjectId);
 end;

 TGLSceneObjectMap = specialize TFPGMap<TGLObjectId, TGLSceneObjectEntry>;
 TGLSceneTileMap = specialize TFPGMap<TGLTileId, TGLSceneTileBucket>;

 TGLSceneIndexer = class
 private
  FTileSize: Double;
  FTestSplit4: Boolean;
  FObjects: TGLSceneObjectMap;
  FTiles: TGLSceneTileMap;
  function MakeTileId(tx, ty: LongInt): TGLTileId;
  procedure TileXY(TileId: TGLTileId; out tx, ty: LongInt);
  procedure RectToTileRange(const BBox: TogsRect; out tx0, ty0, tx1, ty1: LongInt);
  function GetOrCreateTile(TileId: TGLTileId): TGLSceneTileBucket;
  procedure CollectTilesForRect(const BBox: TogsRect; out Tiles: TGLTileIdArray);
  procedure CollectTilesForObject(AId: TGLObjectId; const BBox: TogsRect; out Tiles: TGLTileIdArray);
 public
  constructor Create(ATileSize: Double);
  destructor Destroy; override;
  procedure Clear;
  procedure AddObject(AId: TGLObjectId; const BBox: TogsRect);
  procedure RemoveObject(AId: TGLObjectId);
  procedure UpdateObject(AId: TGLObjectId; const NewBBox: TogsRect);
  function TryGetObjectTiles(AId: TGLObjectId; out Tiles: TGLTileIdArray): Boolean;
  procedure QueryVisibleTiles(const ViewRect: TogsRect; out Tiles: TGLTileIdArray);
  procedure QueryObjectsAtPoint(X, Y: Double; out ObjectIds: TGLObjectIdArray);
  property TileSize: Double read FTileSize write FTileSize;
  property TestSplit4: Boolean read FTestSplit4 write FTestSplit4;
 end;

implementation

constructor TGLSceneObjectEntry.Create(AId: TGLObjectId);
begin
 inherited Create;
 Id := AId;
 BBox := TogsRect.Create;
 SetLength(Tiles, 0);
end;

destructor TGLSceneObjectEntry.Destroy;
begin
 FreeAndNil(BBox);
 inherited Destroy;
end;

constructor TGLSceneTileBucket.Create(ATileId: TGLTileId);
begin
 inherited Create;
 TileId := ATileId;
 SetLength(ObjectIds, 0);
 ObjectCount := 0;
end;

procedure TGLSceneTileBucket.AddObject(AId: TGLObjectId);
begin
 if ObjectCount >= Length(ObjectIds) then
  if Length(ObjectIds) = 0 then SetLength(ObjectIds, 32) else SetLength(ObjectIds, Length(ObjectIds) * 2);
 ObjectIds[ObjectCount] := AId;
 Inc(ObjectCount);
end;

procedure TGLSceneTileBucket.RemoveObject(AId: TGLObjectId);
var i: Integer;
begin
 for i := 0 to ObjectCount - 1 do
  if ObjectIds[i] = AId then
  begin
   Dec(ObjectCount);
   ObjectIds[i] := ObjectIds[ObjectCount];
   Exit;
  end;
end;

procedure TGLSceneIndexer.CollectTilesForObject(AId: TGLObjectId; const BBox: TogsRect; out Tiles: TGLTileIdArray);
var cx, cy: Double;
    tx, ty: LongInt;
begin
 if FTestSplit4 then
 begin
  SetLength(Tiles, 4);
  if FTileSize > 0 then
  begin
   cx := (BBox.XMin + BBox.XMax) * 0.5;
   cy := (BBox.YMin + BBox.YMax) * 0.5;
   tx := Floor(cx / FTileSize);
   ty := Floor(cy / FTileSize);
  end else
  begin
   tx := 0;
   ty := 0;
  end;
  Tiles[0] := MakeTileId(tx, ty);
  Tiles[1] := MakeTileId(tx + 1, ty);
  Tiles[2] := MakeTileId(tx, ty + 1);
  Tiles[3] := MakeTileId(tx + 1, ty + 1);
 end else
  CollectTilesForRect(BBox, Tiles);
end;

constructor TGLSceneIndexer.Create(ATileSize: Double);
begin
 inherited Create;
 FTileSize := ATileSize;
 FTestSplit4 := False;
 FObjects := TGLSceneObjectMap.Create;
 FObjects.Sorted := True;
 FTiles := TGLSceneTileMap.Create;
 FTiles.Sorted := True;
end;

destructor TGLSceneIndexer.Destroy;
begin
 Clear;
 FreeAndNil(FObjects);
 FreeAndNil(FTiles);
 inherited Destroy;
end;

procedure TGLSceneIndexer.Clear;
var i: Integer;
begin
 if FObjects <> nil then
  for i := 0 to FObjects.Count - 1 do FObjects.Data[i].Free;
 if FTiles <> nil then
  for i := 0 to FTiles.Count - 1 do FTiles.Data[i].Free;
 if FObjects <> nil then FObjects.Clear;
 if FTiles <> nil then FTiles.Clear;
end;

function TGLSceneIndexer.MakeTileId(tx, ty: LongInt): TGLTileId;
begin
 Result := (Int64(tx) shl 32) or (Int64(ty) and $FFFFFFFF);
end;

procedure TGLSceneIndexer.TileXY(TileId: TGLTileId; out tx, ty: LongInt);
begin
 tx := LongInt(TileId shr 32);
 ty := LongInt(TileId and $FFFFFFFF);
end;

procedure TGLSceneIndexer.RectToTileRange(const BBox: TogsRect; out tx0, ty0, tx1, ty1: LongInt);
var x0, y0, x1, y1: Double;
begin
 if FTileSize <= 0 then
 begin
  tx0 := 0; ty0 := 0; tx1 := -1; ty1 := -1;
  Exit;
 end;
 x0 := Min(BBox.XMin, BBox.XMax);
 x1 := Max(BBox.XMin, BBox.XMax);
 y0 := Min(BBox.YMin, BBox.YMax);
 y1 := Max(BBox.YMin, BBox.YMax);
 tx0 := Floor(x0 / FTileSize);
 tx1 := Floor(x1 / FTileSize);
 ty0 := Floor(y0 / FTileSize);
 ty1 := Floor(y1 / FTileSize);
end;

function TGLSceneIndexer.GetOrCreateTile(TileId: TGLTileId): TGLSceneTileBucket;
var idx: Integer;
begin
 idx := FTiles.IndexOf(TileId);
 if idx >= 0 then Exit(FTiles.Data[idx]);
 Result := TGLSceneTileBucket.Create(TileId);
 FTiles.Add(TileId, Result);
end;

procedure TGLSceneIndexer.CollectTilesForRect(const BBox: TogsRect; out Tiles: TGLTileIdArray);
var tx0, ty0, tx1, ty1: LongInt;
    tx, ty: LongInt;
    n, i: Integer;
begin
 RectToTileRange(BBox, tx0, ty0, tx1, ty1);
 if (tx1 < tx0) or (ty1 < ty0) then
 begin
  SetLength(Tiles, 0);
  Exit;
 end;
 n := (tx1 - tx0 + 1) * (ty1 - ty0 + 1);
 SetLength(Tiles, n);
 i := 0;
 for ty := ty0 to ty1 do
  for tx := tx0 to tx1 do
  begin
   Tiles[i] := MakeTileId(tx, ty);
   Inc(i);
  end;
end;

procedure TGLSceneIndexer.AddObject(AId: TGLObjectId; const BBox: TogsRect);
var idx, i: Integer;
    entry: TGLSceneObjectEntry;
    tile: TGLSceneTileBucket;
begin
 idx := FObjects.IndexOf(AId);
 if idx >= 0 then Exit;
 entry := TGLSceneObjectEntry.Create(AId);
 entry.BBox.Assign(BBox);
 CollectTilesForObject(AId, entry.BBox, entry.Tiles);
 FObjects.Add(AId, entry);
 for i := 0 to Length(entry.Tiles) - 1 do
 begin
  tile := GetOrCreateTile(entry.Tiles[i]);
  tile.AddObject(AId);
 end;
end;

procedure TGLSceneIndexer.RemoveObject(AId: TGLObjectId);
var idx, i: Integer;
    entry: TGLSceneObjectEntry;
    tid: TGLTileId;
    tileIdx: Integer;
begin
 idx := FObjects.IndexOf(AId);
 if idx < 0 then Exit;
 entry := FObjects.Data[idx];
 for i := 0 to Length(entry.Tiles) - 1 do
 begin
  tid := entry.Tiles[i];
  tileIdx := FTiles.IndexOf(tid);
  if tileIdx >= 0 then FTiles.Data[tileIdx].RemoveObject(AId);
 end;
 FObjects.Delete(idx);
 entry.Free;
end;

procedure TGLSceneIndexer.UpdateObject(AId: TGLObjectId; const NewBBox: TogsRect);
begin
 RemoveObject(AId);
 AddObject(AId, NewBBox);
end;

function TGLSceneIndexer.TryGetObjectTiles(AId: TGLObjectId; out Tiles: TGLTileIdArray): Boolean;
var idx: Integer;
    entry: TGLSceneObjectEntry;
begin
 SetLength(Tiles, 0);
 if FObjects = nil then Exit(False);
 idx := FObjects.IndexOf(AId);
 if idx < 0 then Exit(False);
 entry := FObjects.Data[idx];
 if entry = nil then Exit(False);
 Tiles := Copy(entry.Tiles, 0, Length(entry.Tiles));
 Result := True;
end;

procedure TGLSceneIndexer.QueryVisibleTiles(const ViewRect: TogsRect; out Tiles: TGLTileIdArray);
var tmp: TGLTileIdArray;
    i, idx: Integer;
begin
 if FTestSplit4 then
 begin
  SetLength(Tiles, 0);
  if FTiles = nil then Exit;
  SetLength(Tiles, FTiles.Count);
  for i := 0 to FTiles.Count - 1 do Tiles[i] := FTiles.Keys[i];
  Exit;
 end;
 CollectTilesForRect(ViewRect, tmp);
 SetLength(Tiles, 0);
 if Length(tmp) = 0 then Exit;
 SetLength(Tiles, Length(tmp));
 idx := 0;
 for i := 0 to Length(tmp) - 1 do
  if FTiles.IndexOf(tmp[i]) >= 0 then
  begin
   Tiles[idx] := tmp[i];
   Inc(idx);
  end;
 SetLength(Tiles, idx);
end;

procedure TGLSceneIndexer.QueryObjectsAtPoint(X, Y: Double; out ObjectIds: TGLObjectIdArray);
var
 tx0, ty0, tx, ty: LongInt;
 tid: TGLTileId;
 tileIdx, i, j, k: Integer;
 tile: TGLSceneTileBucket;
 id: TGLObjectId;
 entry: TGLSceneObjectEntry;
 tol: Double;

function HasId(AId: TGLObjectId): Boolean;
var k: Integer;
begin
 Result := False;
 for k := 0 to Length(ObjectIds) - 1 do
  if ObjectIds[k] = AId then Exit(True);
end;

procedure AddId(AId: TGLObjectId);
var n: Integer;
begin
 if HasId(AId) then Exit;
 n := Length(ObjectIds);
 SetLength(ObjectIds, n + 1);
 ObjectIds[n] := AId;
end;

begin
 SetLength(ObjectIds, 0);
 if (FObjects = nil) then Exit;

 // In TestSplit4 mode objects are currently bucketed by bbox CENTER into 4 tiles.
 // For long/large objects this creates dead-zones: point can be on the object while
 // being far from its center tile. For picking we therefore use bbox filtering.
 if FTestSplit4 then
 begin
  tol := 0;
  for i := 0 to FObjects.Count - 1 do
  begin
   entry := FObjects.Data[i];
   if (entry = nil) or (entry.BBox = nil) then Continue;
   if (X >= Min(entry.BBox.XMin, entry.BBox.XMax) - tol) and
      (X <= Max(entry.BBox.XMin, entry.BBox.XMax) + tol) and
      (Y >= Min(entry.BBox.YMin, entry.BBox.YMax) - tol) and
      (Y <= Max(entry.BBox.YMin, entry.BBox.YMax) + tol) then
     AddId(entry.Id);
  end;
  Exit;
 end;

 if FTiles = nil then Exit;
 if (FTileSize <= 0) then
 begin
  SetLength(ObjectIds, FObjects.Count);
  for i := 0 to FObjects.Count - 1 do ObjectIds[i] := FObjects.Keys[i];
  Exit;
 end;
 tx0 := Floor(X / FTileSize);
 ty0 := Floor(Y / FTileSize);
 for j := -1 to 1 do
  for i := -1 to 1 do
  begin
   tx := tx0 + i;
   ty := ty0 + j;
   tid := MakeTileId(tx, ty);
   tileIdx := FTiles.IndexOf(tid);
   if tileIdx < 0 then Continue;
   tile := FTiles.Data[tileIdx];
   if tile = nil then Continue;
   for k := 0 to tile.ObjectCount - 1 do
   begin
    id := tile.ObjectIds[k];
    AddId(id);
   end;
  end;
end;

end.
