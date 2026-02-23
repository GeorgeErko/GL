unit ogcTileLayer;

{$mode Delphi}

interface

uses
  Classes, SysUtils, ogcBasic, ogcGeometry, ogcPlayer, ogcMapObject,
  GR32, GR32_Image, GR32_Blend, ogcDrawer32;

type

  { TogsTileItem}
  TogsTileItem = class(TogsPoint)
  private
    fLevelNum: Integer;
    fIndex: Integer;
    fCol, fRow: Integer;
    fcmdPlayer: TogsCollection;
  public
    constructor Create(ogsSelector_: TogsSelector);
    destructor Destroy; override;
    procedure SetBounds(const Bounds: TogsRect);
    property LevelNum: Integer read fLevelNum write fLevelNum;
    property Index: Integer read fIndex write fIndex;
    property Col: Integer read fCol write fCol;
    property Row: Integer read fRow write fRow;
    property CmdPlayer: TogsCollection read fcmdPlayer write fcmdPlayer;
  end;

  { TogsTileLayer }

  TogsTileLayer = class(TogsGeometryCollection)
  private
   fLayerNum: Integer;
   fTilerSelector: TogsSelector;
   fogsObject: TogsMapObject;
   fPlayer: TgmfPlayer;
   fTileCounter: Integer;
   function GetItem(Index: Integer): TogsTileItem;
   function GetViewRect: TogsRect;
   procedure SetViewRect(AValue: TogsRect);
  public
   constructor Create(ogsObject: TogsMapObject);
   destructor Destroy; override;

   procedure Clear; override;
   procedure BeginCapture;
   function EndCapture: TogsCollection;
   function CaptureCommands(const ViewRect: TogsRect): TogsCollection;
   // Creates a tile and takes ownership of current fPlayer.cmdPlayer.
   procedure CreateCapturedTile(const Bounds: TogsRect; Col, Row, Level: Integer);
  //
   procedure CompileMapLayer();
  //
   property TilerSelector: TogsSelector read fTilerSelector;
   property ViewRect: TogsRect read GetViewRect write SetViewRect;
  //
   function TileVisible(Index: Integer; ViewRect: TogsRect): Boolean;
   procedure PlayTile(Drawer: TogsDrawer; Index: Integer);
   procedure Draw(Drawer: TogsDrawer); override;
  //
   property Tile[Indeg: Integer]: TogsTileItem read GetItem; default;
  end;

implementation uses ogcWriter, ogcRects;

function HasDrawCommands(Cmds: TogsCollection): Boolean;
var
  I: Integer;
  Obj: TObject;
begin
  Result := False;
  if (Cmds = nil) or (Cmds.Count = 0) then Exit;
  for I := 0 to Cmds.Count - 1 do begin
    Obj := TObject(Cmds[I]);
    if (Obj is TgrLine) or (Obj is TgrPolygons) or (Obj is TgrPolyLine) or (Obj is TgrBitmap) then begin
      Result := True;
      Exit;
    end;
  end;
end;

{ TogsTileItem }

constructor TogsTileItem.Create(ogsSelector_: TogsSelector);
begin
  inherited Create(0,0,0,ogsSelector_);
  fcmdPlayer := nil;
end;

destructor TogsTileItem.Destroy;
begin
  FreeAndNil(fcmdPlayer);
  inherited Destroy;
end;

procedure TogsTileItem.SetBounds(const Bounds: TogsRect);
begin
 ogsRect.Assign(Bounds);
end;

{ TogsTileLayer }

constructor TogsTileLayer.Create(ogsObject: TogsMapObject);
begin
  inherited Create(ogsObject.ogsSelector, 1);

  fogsObject := ogsObject;

  // For compilation/tiling we only need ActiveRect and clipping helpers.
  // The Drawer is not required for this stage.
  fTilerSelector := TogsSelector.Create(nil);
  fTilerSelector.sName := 'cmdPlayer';
  fPlayer := TgmfPlayer.Create(fTilerSelector, ogsObject.Drawer, nil);
  fTilerSelector.ogsDrawer := fPlayer;
  fPlayer.cmdPlayer := TogsCollection.Create;
  fTileCounter := 0;
end;

destructor TogsTileLayer.Destroy;
begin
  FreeAndNil(fPlayer);
  FreeAndNil(fTilerSelector);
  inherited Destroy;
end;

procedure TogsTileLayer.Clear;
begin
  inherited Clear;
  if (fPlayer <> nil) and (fPlayer.cmdPlayer <> nil) then
    fPlayer.cmdPlayer.FreeAll;
end;

function TogsTileLayer.GetViewRect: TogsRect;
begin
  Result := fTilerSelector.ActiveRect;
end;

function TogsTileLayer.GetItem(Index: Integer): TogsTileItem;
begin
 Result := Items[Index];
end;

function TogsTileLayer.TileVisible(Index: Integer; ViewRect: TogsRect): Boolean;
begin
 Result := False;
 if (Index < 0) or (Index >= Count) then Exit;
 if ViewRect = nil then Exit;
 if Tile[Index] = nil then Exit;
 Result := Tile[Index].Visible(ViewRect);
end;

procedure TogsTileLayer.PlayTile(Drawer: TogsDrawer; Index: Integer);
var
 T: TogsTileItem;
begin
 if Drawer = nil then Exit;
 if (Index < 0) or (Index >= Count) then Exit;
 T := Tile[Index];
 if (T = nil) or (T.CmdPlayer = nil) or (T.CmdPlayer.Count = 0) then Exit;
 Drawer.cmdPlayer := T.CmdPlayer;
 try
  Drawer.Play(Drawer, T.ogsRect);
 finally
  Drawer.cmdPlayer := nil;
 end;
end;

procedure TogsTileLayer.SetViewRect(AValue: TogsRect);
begin
  fTilerSelector.ActiveRect := AValue;
end;

procedure TogsTileLayer.BeginCapture;
begin
  if fPlayer.cmdPlayer = nil then
    fPlayer.cmdPlayer := TogsCollection.Create;
  fPlayer.cmdPlayer.FreeAll;
end;

function TogsTileLayer.EndCapture: TogsCollection;
begin
  Result := fPlayer.cmdPlayer;
end;

function TogsTileLayer.CaptureCommands(const ViewRect: TogsRect): TogsCollection;
begin
  fTilerSelector.ActiveRect := ViewRect;
  BeginCapture;
  if fogsObject <> nil then
    fogsObject.Draw(fPlayer);
  Result := EndCapture;
end;

procedure TogsTileLayer.CreateCapturedTile(const Bounds: TogsRect; Col, Row, Level: Integer);
var TileItem: TogsTileItem;
begin
  TileItem := TogsTileItem.Create(ogsSelector);
  Inc(fTileCounter);
  TileItem.fIndex := fTileCounter;
  TileItem.fLevelNum := Level;
  TileItem.fCol := Col;
  TileItem.fRow := Row;
  TileItem.SetBounds(Bounds);
  // Transfer ownership of commands to the tile.
  TileItem.fcmdPlayer := fPlayer.cmdPlayer;
  fPlayer.cmdPlayer := nil;

  inherited Add(TileItem);
end;

procedure TogsTileLayer.CompileMapLayer();
var
  objRect, cellRect: TogsRect;
  xCount, yCount, cc, cn, I: Integer;
  cellWidth, cellHeight: Double;
  aCol, aRow: Integer;
  prevSelector: TogsSelector;
  cmds, Rects: TogsCollection;
  Rect: TogsRectLineString;
procedure WriteCmd;
var I: Integer;
begin
  exit;
 For I := 0 to cmds.Count - 1 do begin
  WriteIn([I, TObject(cmds[I]).ClassName]);
 end;
end;
begin
  if fogsObject = nil then Exit;

  objRect := fogsObject.ogsSelector.GlobalRect;
  Rects := TogsCollection.Create;
  // Temporary simple grid: 100x100 cells across the object's global rect.
  xCount := 10;
  yCount := 10;
  if (xCount <= 0) or (yCount <= 0) then Exit;

  cellWidth := objRect.Width / xCount;
  cellHeight := objRect.Height / yCount;

  prevSelector := fogsObject.ogsSelector;
  fogsObject.ogsSelector := fTilerSelector;
  try
    cellRect := TogsRect.Create;
    cc := 0; cn := 0;
    try
      for aCol := 0 to xCount - 1 do
        for aRow := 0 to yCount - 1 do
        begin
          cellRect.XMin := objRect.XMin + cellWidth * aCol;
          cellRect.XMax := cellRect.XMin + cellWidth;
          cellRect.YMin := objRect.YMin + cellHeight * aRow;
          cellRect.YMax := cellRect.YMin + cellHeight;
          cellRect.Iter := 1;
         //
        //  WriteIn([cellRect]);
          cmds := CaptureCommands(cellRect);
          if HasDrawCommands(cmds) then begin
            WriteIn(['CreateTile', aCol, aRow, cmds.Count]);
           // WriteCmd;
            Inc(cc);
            CreateCapturedTile(cellRect, aCol, aRow, 0);
            Rect := TogsRectLineString.Create(prevSelector);
            Rect.SetRectLocal(cellrect.XMin, cellRect.YMin, cellrect.Width, cellRect.Height);
           // WriteIn(['W=', Rect.Width, 'H=', Rect.Height]);
            Rect.Calculate([calcbBox]);
            Rects.Add(Rect);
            BeginCapture;
           // exit;
          end
          else begin
          //  WriteIn(['Invalid---', aCol, aRow]);
            Inc(cn);
            BeginCapture;
          end;
        end;
     // Writein(['CCCN=', CC, CN]);
    finally
      cellRect.Free;
    end;
  finally
    fogsObject.ogsSelector := prevSelector;
  end;
// For I := 0 to rects.Count - 1 do
//  fogsObject.AddPrim(Rects[I]);
// Rects.DeleteAll;
 Rects.Free;
end;

procedure TogsTileLayer.Draw(Drawer: TogsDrawer);
var
 I: Integer;
begin
 if (Drawer = nil) or (Drawer.ogsSelector = nil) then Exit;
 if Drawer.ogsSelector.ActiveRect = nil then Exit;

 For I := 0 to Count - 1 do
  if TileVisible(I, Drawer.ogsSelector.ActiveRect) then
   PlayTile(Drawer, I);
end;

end.
