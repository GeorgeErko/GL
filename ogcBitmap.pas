unit ogcBitmap;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Math,
  ogcBasic, ogcGeometry, ogcRects,
  uBmpMmapSource24, uRasterViewRenderer, ogcDrawer32, GR32, Graphics, Types;

type

  TogsBitmap = class(TogsRectLineString)
  protected
    fSource: TBmpMmapSource24;
    fRenderer: TRasterViewRenderer;
    fRendererXY: TRasterViewRendererXY;
    fFrame: TBitmap;
    fFrame32: TBitmap32;
    fFileName: String;
    fPixelWidth: Integer;
    fPixelHeight: Integer;
    fDpiX: Double;
    fDpiY: Double;
    fScale: Double;
    fDesiredAngleRad: Double; // absolute angle for rebuild

    procedure UpdateRectPoints;
    function GetLoaded: Boolean;
    function EffectiveDpiX: Double;
    function EffectiveDpiY: Double;
  public
    constructor Create(ogsSelector_: TogsSelector);
    destructor Destroy; override;
    constructor CreateAs(ogsObject: TogsBasic); override;
    constructor Load(Stream: TogsStream); override;
    procedure Store(Stream: TogsStream); override;
    function Assign(ogsObject: TogsBasic): boolean; override;

    procedure Draw(Drawer: TogsDrawer); override;

    procedure SetAnchor(const GeoX, GeoY: Double);
    procedure SetImageParams(const APixelWidth, APixelHeight: Integer;
      const ADpiX, ADpiY, AScale, AAngleRad: Double);

    function OpenRasterFile(const AFileName: String; const startX: Double = 0; const startY: Double = 0): Boolean;
    procedure CloseRaster;

    property Source: TBmpMmapSource24 read fSource;
    property FileName: String read fFileName;
    property Loaded: Boolean read GetLoaded;

    property PixelWidth: Integer read fPixelWidth;
    property PixelHeight: Integer read fPixelHeight;
    property DpiX: Double read fDpiX;
    property DpiY: Double read fDpiY;
    property Scale: Double read fScale;
  end;

  TogsBitmapOrtho = class(TogsBitmap)
    procedure Draw(Drawer: TogsDrawer); override;
  end;

implementation uses ogcWriter;

constructor TogsBitmap.Create(ogsSelector_: TogsSelector);
begin
  inherited Create(ogsSelector_);
  fSource := nil;
  fRenderer := TRasterViewRenderer.Create(nil);
  fRenderer.Source := nil;
  fRendererXY := TRasterViewRendererXY.Create(nil);
  fRendererXY.Source := nil;
  fFrame := TBitmap.Create;
  fFrame32 := TBitmap32.Create;
  fFileName := '';
  fPixelWidth := 0;
  fPixelHeight := 0;
  fDpiX := 0;
  fDpiY := 0;
  fScale := 500;
  fDesiredAngleRad := 0;
end;

destructor TogsBitmap.Destroy;
begin
  CloseRaster;
  FreeAndNil(fRenderer);
  FreeAndNil(fRendererXY);
  FreeAndNil(fFrame);
  FreeAndNil(fFrame32);
  inherited Destroy;
end;

constructor TogsBitmap.CreateAs(ogsObject: TogsBasic);
begin
  fSource := nil;
  if not Assign(ogsObject) then
    raise Exception.Create(ClassName + '.CreateAs raised type conversion exception');
  inherited CreateAs(ogsObject);

  if (fFileName <> '') and FileExists(fFileName) then
    OpenRasterFile(fFileName);
end;

constructor TogsBitmap.Load(Stream: TogsStream);
var
  s: AnsiString;
begin
  Stream.Read(fPixelWidth, SizeOf(fPixelWidth));
  Stream.Read(fPixelHeight, SizeOf(fPixelHeight));
  Stream.Read(fDpiX, SizeOf(fDpiX));
  Stream.Read(fDpiY, SizeOf(fDpiY));
  Stream.Read(fScale, SizeOf(fScale));
  Stream.Read(fDesiredAngleRad, SizeOf(fDesiredAngleRad));
  inherited Load(Stream);

  s := '';
  Stream.ReadString(s);
  fFileName := String(s);

  if (fFileName <> '') and FileExists(fFileName) then
    OpenRasterFile(fFileName);
end;

procedure TogsBitmap.Store(Stream: TogsStream);
var
  s: AnsiString;
begin
  Stream.Write(fPixelWidth, SizeOf(fPixelWidth));
  Stream.Write(fPixelHeight, SizeOf(fPixelHeight));
  Stream.Write(fDpiX, SizeOf(fDpiX));
  Stream.Write(fDpiY, SizeOf(fDpiY));
  Stream.Write(fScale, SizeOf(fScale));
  Stream.Write(fDesiredAngleRad, SizeOf(fDesiredAngleRad));
  inherited Store(Stream);

  s := AnsiString(fFileName);
  Stream.WriteString(s);
end;

function TogsBitmap.Assign(ogsObject: TogsBasic): boolean;
var
  src: TogsBitmap;
begin
  Result := False;
  if not (ogsObject is TogsBitmap) then
    Exit;

  src := TogsBitmap(ogsObject);
  if not inherited Assign(ogsObject) then
    Exit;

  fPixelWidth := src.PixelWidth;
  fPixelHeight := src.PixelHeight;
  fDpiX := src.DpiX;
  fDpiY := src.DpiY;
  fScale := src.Scale;
  fDesiredAngleRad := src.fDesiredAngleRad;
  fFileName := src.FileName;
  Result := True;
end;

procedure TogsBitmap.CloseRaster;
begin
  if fSource <> nil then
  begin
    fSource.Close;
    FreeAndNil(fSource);
  end;
end;

function TogsBitmap.OpenRasterFile(const AFileName: String; const startX: Double = 0; const startY: Double = 0): Boolean;
begin
  Result := False;
  CloseRaster;

  if not FileExists(AFileName) then
    Exit;

  fFileName := AFileName;

  fSource := TBmpMmapSource24.Create(nil);
  try
    fSource.FileName := AFileName;
    if not fSource.Open then
    begin
      CloseRaster;
      Exit;
    end;
  except
    CloseRaster;
    Exit;
  end;

  fPixelWidth := fSource.Width;
  fPixelHeight := fSource.Height;

  if (fDpiX <= 0) and (fSource.XPelsPerMeter > 0) then
    fDpiX := Abs(fSource.XPelsPerMeter) * 0.0254;
  if (fDpiY <= 0) and (fSource.YPelsPerMeter > 0) then
    fDpiY := Abs(fSource.YPelsPerMeter) * 0.0254;

  if (startX <> 0) or (startY <> 0) then
  begin
    if Count = 0 then
      inherited AddPoint(startX, startY, 0)
    else
    begin
      Point[0].fX := startX;
      Point[0].fY := startY;
    end;
  end;

  UpdateRectPoints;
  Result := True;
end;

function TogsBitmap.GetLoaded: Boolean;
begin
  Result := (fSource <> nil) and fSource.IsOpen;
end;

function TogsBitmap.EffectiveDpiX: Double;
begin
  if fDpiX > 0 then
    Result := fDpiX
  else
    Result := 96;
end;

function TogsBitmap.EffectiveDpiY: Double;
begin
  if fDpiY > 0 then
    Result := fDpiY
  else
    Result := 96;
end;

procedure TogsBitmap.Draw(Drawer: TogsDrawer);
type
  TPtD = record
    x, y: Double;
  end;
var
  d32: TogsDrawer32;
  bmp: TBitmap32;
  p0, p1, p2, p3: TPtD;
  x0, y0, x1, y1, x2, y2, x3, y3: Double;
  minX, minY, maxX, maxY: Integer;
  x, y: Integer;
  zoomX, zoomY, zoom: Double;
  angleScr: Double;
  sx, sy: Integer;
  bgColor: TColor;
  rowSrc32: PColor32Array;
  col32: TColor32;
  w, h: Integer;
  ax0, ax1, ay0, ay1: Integer;
  clipL, clipR, clipT, clipB: Integer;
  lx0, ly0: Double;
  cx, cy: Double;
  dx, dy: Double;
  cA, sA: Double;
  scx, scy: Double;
  panX, panY: Double;
  useXY: Boolean;
  invZoomX, invZoomY: Double;
  ex, ey: Double;

  function ClampI(const V, AMin, AMax: Integer): Integer;
  begin
    Result := V;
    if Result < AMin then Result := AMin;
    if Result > AMax then Result := AMax;
  end;

  function InsideQuad(const px, py: Double): Boolean;
  var
    ax, ay, bx, by, cx, cy, dx, dy: Double;
    abx, aby, adx, ady: Double;
    apx, apy: Double;
    det, u, v: Double;
  begin
    // Quad is a parallelogram (rotated rectangle). We solve:
    // P = A + u*(B-A) + v*(D-A), with 0<=u<=1 and 0<=v<=1.
    ax := p0.x; ay := p0.y;
    bx := p1.x; by := p1.y;
    dx := p3.x; dy := p3.y;

    abx := bx - ax; aby := by - ay;
    adx := dx - ax; ady := dy - ay;

    apx := px - ax; apy := py - ay;

    det := abx * ady - aby * adx;
    if Abs(det) < 1e-12 then
      Exit(False);

    u := (apx * ady - apy * adx) / det;
    v := (abx * apy - aby * apx) / det;

    Result := (u >= 0.0) and (u <= 1.0) and (v >= 0.0) and (v <= 1.0);
  end;

begin
  if not Loaded then
  begin
   inherited Draw(Drawer);
   Exit;
  end;

  if (Drawer = nil) or not (Drawer is TogsDrawer32) then
  begin
   inherited Draw(Drawer);
   Drawer.DrawBitmap(Self, ogsRect);
   Exit;
  end;

  if Count < 4 then
  begin
    inherited Draw(Drawer);
    Exit;
  end;

  If not ogsRect.VisibleIn(ogsSelector.ActiveRect) then exit;

  d32 := TogsDrawer32(Drawer);
  bmp := d32.Image.Bitmap;
  if bmp = nil then begin
    Writeln('=====================================================');
    Exit;
  end;

  if fRenderer = nil then
    Exit;
  if fFrame = nil then
    Exit;

  fRenderer.Source := fSource;
  if fRendererXY <> nil then
    fRendererXY.Source := fSource;

  x0 := Drawer.ogsSelector.XPix(Point[0].fX);
  y0 := Drawer.ogsSelector.YPix(Point[0].fY);
  x1 := Drawer.ogsSelector.XPix(Point[1].fX);
  y1 := Drawer.ogsSelector.YPix(Point[1].fY);
  x2 := Drawer.ogsSelector.XPix(Point[2].fX);
  y2 := Drawer.ogsSelector.YPix(Point[2].fY);
  x3 := Drawer.ogsSelector.XPix(Point[3].fX);
  y3 := Drawer.ogsSelector.YPix(Point[3].fY);

  p0.x := x0; p0.y := y0;
  p1.x := x1; p1.y := y1;
  p2.x := x2; p2.y := y2;
  p3.x := x3; p3.y := y3;

  minX := Floor(Min(Min(p0.x, p1.x), Min(p2.x, p3.x)));
  maxX := Ceil (Max(Max(p0.x, p1.x), Max(p2.x, p3.x)));
  minY := Floor(Min(Min(p0.y, p1.y), Min(p2.y, p3.y)));
  maxY := Ceil (Max(Max(p0.y, p1.y), Max(p2.y, p3.y)));

  ax0 := Drawer.ogsSelector.XPix(Drawer.ogsSelector.ActiveRect.XMin);
  ax1 := Drawer.ogsSelector.XPix(Drawer.ogsSelector.ActiveRect.XMax);
  ay0 := Drawer.ogsSelector.YPix(Drawer.ogsSelector.ActiveRect.YMin);
  ay1 := Drawer.ogsSelector.YPix(Drawer.ogsSelector.ActiveRect.YMax);

  clipL := Min(ax0, ax1);
  clipR := Max(ax0, ax1);
  clipT := Min(ay0, ay1);
  clipB := Max(ay0, ay1);
  if clipR > clipL then Dec(clipR);
  if clipB > clipT then Dec(clipB);

  clipL := ClampI(clipL, 0, bmp.Width - 1);
  clipR := ClampI(clipR, 0, bmp.Width - 1);
  clipT := ClampI(clipT, 0, bmp.Height - 1);
  clipB := ClampI(clipB, 0, bmp.Height - 1);

  minX := ClampI(minX, clipL, clipR);
  maxX := ClampI(maxX, clipL, clipR);
  minY := ClampI(minY, clipT, clipB);
  maxY := ClampI(maxY, clipT, clipB);
  if (minX > maxX) or (minY > maxY) then
    Exit;

  zoomX := Hypot(p1.x - p0.x, p1.y - p0.y) / Max(1, fPixelWidth);
  zoomY := Hypot(p3.x - p0.x, p3.y - p0.y) / Max(1, fPixelHeight);
  if zoomX < 1e-12 then zoomX := 1e-12;
  if zoomY < 1e-12 then zoomY := 1e-12;
  zoom := Min(zoomX, zoomY);

  angleScr := ArcTan2(p1.y - p0.y, p1.x - p0.x);

//  Writeln(Abs(zoomX - zoomY) , (1e-3 * Max(zoomX, zoomY)));

  useXY := Abs(zoomX - zoomY) > (1e-4);
  if useXY and (fRendererXY <> nil) then
    fRendererXY.AngleRad := angleScr
  else
  begin
    fRenderer.Zoom := zoom;
    fRenderer.AngleRad := angleScr;
  end;

  // Anchor mapping:
  // We render into a temporary frame sized (w,h) = bbox size.
  // Need source pixel (0,0) to land at screen pixel of Point[0] (within that frame).
  w := (maxX - minX) + 1;
  h := (maxY - minY) + 1;
  lx0 := p0.x - minX;
  ly0 := p0.y - minY;
  cx := (w - 1) * 0.5;
  cy := (h - 1) * 0.5;
  ex := (lx0 - cx);
  ey := (ly0 - cy);
  if useXY and (fRendererXY <> nil) then
  begin
    invZoomX := 1.0 / zoomX;
    invZoomY := 1.0 / zoomY;
  end
  else
  begin
    invZoomX := 1.0 / zoom;
    invZoomY := invZoomX;
  end;
  cA := Cos(angleScr);
  sA := Sin(angleScr);

  // TRasterViewRendererXY inverse mapping:
  // rx =  cA*(x-cx) + sA*(y-cy)
  // ry = -sA*(x-cx) + cA*(y-cy)
  // srcX = scx + rx/ZoomX
  // srcY = scy + ry/ZoomY
  // Want source pixel (0,0) at screen (lx0,ly0) =>
  // scx = -rx/ZoomX, scy = -ry/ZoomY.
  scx := -( (cA * ex + sA * ey) * invZoomX );
  scy := -( (-sA * ex + cA * ey) * invZoomY );
  panX := scx - (fPixelWidth - 1) * 0.5;
  panY := scy - (fPixelHeight - 1) * 0.5;
  if useXY and (fRendererXY <> nil) then
  begin
    fRendererXY.ZoomX := zoomX;
    fRendererXY.ZoomY := zoomY;
    fRendererXY.PanX := panX;
    fRendererXY.PanY := panY;
  end
  else
  begin
    fRenderer.PanX := panX;
    fRenderer.PanY := panY;
  end;

  // Render into fFrame for bbox-size view.
  // We render a tight view (minX..maxX, minY..maxY) and then blit it into bmp.
  bgColor := clBtnFace;
  if useXY and (fRendererXY <> nil) then
    fRendererXY.BackgroundColor := bgColor
  else
    fRenderer.BackgroundColor := bgColor;

  if fFrame32 = nil then
    Exit;
  if useXY and (fRendererXY <> nil) then
    fRendererXY.RenderToBitmap32(fFrame32, Rect(0, 0, w, h))
  else
    fRenderer.RenderToBitmap32(fFrame32, Rect(0, 0, w, h));

  for y := 0 to (maxY - minY) do
  begin
    rowSrc32 := PColor32Array(fFrame32.ScanLine[y]);
    for x := 0 to (maxX - minX) do
    begin
      sx := minX + x;
      sy := minY + y;
      if InsideQuad(sx + 0.5, sy + 0.5) then
      begin
        col32 := rowSrc32^[x];
        bmp.Pixel[sx, sy] := col32;
      end;
    end;
  end;
 inherited Draw(Drawer);
end;

procedure TogsBitmap.SetAnchor(const GeoX, GeoY: Double);
begin
  if Count > 0 then
  begin
    Point[0].fX := GeoX;
    Point[0].fY := GeoY;
  end
  else
    inherited AddPoint(GeoX, GeoY, 0);
  UpdateRectPoints;
end;

procedure TogsBitmap.SetImageParams(const APixelWidth, APixelHeight: Integer;
  const ADpiX, ADpiY, AScale, AAngleRad: Double);
begin
  if APixelWidth <> 0 then
    fPixelWidth := APixelWidth;
  if APixelHeight <> 0 then
    fPixelHeight := APixelHeight;

  if ADpiX <> 0 then
    fDpiX := ADpiX;
  if ADpiY <> 0 then
    fDpiY := ADpiY;

  if AScale <> 0 then
  begin
    if AScale > 0 then
      fScale := AScale
    else
      fScale := 500;
  end;

  if AAngleRad <> 0 then
    fDesiredAngleRad := AAngleRad;

  UpdateRectPoints;
end;

procedure TogsBitmap.UpdateRectPoints;
var
  x0, y0: Double;
  wM, hM: Double;
  dpiX, dpiY: Double;
  n: Double;
begin
  if (fPixelWidth <= 0) or (fPixelHeight <= 0) then
    Exit;

  dpiX := EffectiveDpiX;
  dpiY := EffectiveDpiY;
  n := fScale;
  if n <= 0 then
    n := 500;

  wM := (fPixelWidth / dpiX) * 0.0254 * n;
  hM := (fPixelHeight / dpiY) * 0.0254 * n;

  If Count = 0 then begin
   x0 := 0; y0 := 0;
  end else begin
   x0 := Point[0].fX;
   y0 := Point[0].fY;
  end;

  inherited Clear;

  inherited AddPoint(x0,      y0,      0);
  inherited AddPoint(x0 + wM, y0,      0);
  inherited AddPoint(x0 + wM, y0 + hM, 0);
  inherited AddPoint(x0,      y0 + hM, 0);
  inherited AddPoint(x0,      y0,      0);

  fWidth := Abs(wM);
  fHeight := Abs(hM);
  fAngleRad := 0;

  if Abs(fDesiredAngleRad) > 1e-18 then
  begin
    RotatePoints(fDesiredAngleRad, 0);
    fAngleRad := fDesiredAngleRad;
  end;
end;

//===============================================================================
procedure TogsBitmapOrtho.Draw(Drawer: TogsDrawer);
var
 d32: TogsDrawer32;
 bmp: TBitmap32;
 x0, y0, x2, y2: Integer;
 minX, minY, maxX, maxY: Integer;
 clipW, clipH: Integer;
 actW, actH: Integer;
 ax0, ax1, ay0, ay1: Integer;
 clipL, clipR, clipT, clipB: Integer;
 w, h: Integer;
 zoomX, zoomY, zoom: Double;
 panX, panY: Double;
 rowSrc32: PColor32Array;
 col32: TColor32;
 x, y, sx, sy: Integer;
 vis: TSect;
 tmpRect: TogsRect;
 srcX0, srcY0, srcX1, srcY1: Integer;
 srcW, srcH: Integer;
 srcCX, srcCY: Double;
 gW, gH: Double;

 function ClampI(const V, AMin, AMax: Integer): Integer;
 begin
  Result := V;
  if Result < AMin then Result := AMin;
  if Result > AMax then Result := AMax;
 end;

begin
 if not Loaded then
 begin
  inherited Draw(Drawer);
  Exit;
 end;

 if (Drawer = nil) or not (Drawer is TogsDrawer32) then
 begin
  inherited Draw(Drawer);
  Exit;
 end;

 if Count < 4 then
 begin
  inherited Draw(Drawer);
  Exit;
 end;

 if not ogsRect.VisibleIn(ogsSelector.ActiveRect) then Exit;

 d32 := TogsDrawer32(Drawer);
 bmp := d32.Image.Bitmap;
 if bmp = nil then Exit;

 if fRenderer = nil then Exit;
 if fFrame32 = nil then Exit;
 if fSource = nil then Exit;

 fRenderer.Source := fSource;

 // Geo intersection (visible part) = ogsRect ∩ ActiveRect
 vis := ogsRect.IntersectWith(Drawer.ogsSelector.ActiveRect);
 tmpRect := TogsRect.Create;
 try
  tmpRect.SetSect(vis);
  if not tmpRect.isRect then Exit;

  x0 := Drawer.ogsSelector.XPix(tmpRect.XMin);
  y0 := Drawer.ogsSelector.YPix(tmpRect.YMin);
  x2 := Drawer.ogsSelector.XPix(tmpRect.XMax);
  y2 := Drawer.ogsSelector.YPix(tmpRect.YMax);
 finally
  tmpRect.Free;
 end;

 minX := Min(x0, x2);
 maxX := Max(x0, x2);
 minY := Min(y0, y2);
 maxY := Max(y0, y2);

 actW := Drawer.ogsSelector.pixDist(Drawer.ogsSelector.ActiveRect.Width);
 actH := Drawer.ogsSelector.pixDist(Drawer.ogsSelector.ActiveRect.Height);

 ax0 := Drawer.ogsSelector.XPix(Drawer.ogsSelector.ActiveRect.XMin);
 ax1 := Drawer.ogsSelector.XPix(Drawer.ogsSelector.ActiveRect.XMax);
 ay0 := Drawer.ogsSelector.YPix(Drawer.ogsSelector.ActiveRect.YMin);
 ay1 := Drawer.ogsSelector.YPix(Drawer.ogsSelector.ActiveRect.YMax);

 clipL := Min(ax0, ax1);
 clipR := Max(ax0, ax1);
 clipT := Min(ay0, ay1);
 clipB := Max(ay0, ay1);
 if clipR > clipL then Dec(clipR);
 if clipB > clipT then Dec(clipB);

 clipL := ClampI(clipL, 0, bmp.Width - 1);
 clipR := ClampI(clipR, 0, bmp.Width - 1);
 clipT := ClampI(clipT, 0, bmp.Height - 1);
 clipB := ClampI(clipB, 0, bmp.Height - 1);

 minX := ClampI(minX, clipL, clipR);
 maxX := ClampI(maxX, clipL, clipR);
 minY := ClampI(minY, clipT, clipB);
 maxY := ClampI(maxY, clipT, clipB);
 if (minX > maxX) or (minY > maxY) then Exit;

 clipW := (maxX - minX) + 1;
 clipH := (maxY - minY) + 1;

 WriteIn(['BmpClip(px)=', clipW, clipH, 'min=', minX, minY, 'ActRect(px)=', actW, actH]);

 // --- map visible geo-rect to source pixel rect ---
 gW := ogsRect.Width;
 gH := ogsRect.Height;
 if Abs(gW) < 1e-18 then Exit;
 if Abs(gH) < 1e-18 then Exit;

 srcX0 := Floor((vis.XMin - ogsRect.XMin) / gW * (fPixelWidth - 1));
 srcX1 := Ceil((vis.XMax - ogsRect.XMin) / gW * (fPixelWidth - 1));
 srcY0 := Floor((vis.YMin - ogsRect.YMin) / gH * (fPixelHeight - 1));
 srcY1 := Ceil((vis.YMax - ogsRect.YMin) / gH * (fPixelHeight - 1));

 srcX0 := ClampI(srcX0, 0, fPixelWidth - 1);
 srcX1 := ClampI(srcX1, 0, fPixelWidth - 1);
 srcY0 := ClampI(srcY0, 0, fPixelHeight - 1);
 srcY1 := ClampI(srcY1, 0, fPixelHeight - 1);
 if srcX0 > srcX1 then begin x := srcX0; srcX0 := srcX1; srcX1 := x; end;
 if srcY0 > srcY1 then begin y := srcY0; srcY0 := srcY1; srcY1 := y; end;

 srcW := (srcX1 - srcX0) + 1;
 srcH := (srcY1 - srcY0) + 1;
 if (srcW <= 0) or (srcH <= 0) then Exit;

 w := clipW;
 h := clipH;
 zoomX := w / srcW;
 zoomY := h / srcH;
 zoom := Min(zoomX, zoomY);
 if zoom < 1e-12 then zoom := 1e-12;

 // Center the renderer on the center of src rect
 srcCX := (srcX0 + srcX1) * 0.5;
 srcCY := (srcY0 + srcY1) * 0.5;

 fRenderer.Zoom := zoom;
 fRenderer.AngleRad := 0;
 fRenderer.PanX := srcCX - (fPixelWidth - 1) * 0.5;
 fRenderer.PanY := srcCY - (fPixelHeight - 1) * 0.5;

 // NOTE: DestRect.Left/Top are ignored inside RenderToBitmap32 (it resizes bitmap to w/h)
 fRenderer.RenderToBitmap32(fFrame32, Rect(0, 0, w, h));

 for y := 0 to (h - 1) do
 begin
  rowSrc32 := PColor32Array(fFrame32.ScanLine[y]);
  for x := 0 to (w - 1) do
  begin
   sx := minX + x;
   sy := minY + y;
   col32 := rowSrc32^[x];
   bmp.Pixel[sx, sy] := col32;
  end;
 end;

// inherited Draw(Drawer);
end;


end.
