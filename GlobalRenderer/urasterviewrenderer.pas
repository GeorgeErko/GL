unit uRasterViewRenderer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Graphics, Types,
  uBmpMmapSource24, GR32;

type
  TRasterViewRenderer = class(TComponent)
  protected
    FSource: TBmpMmapSource24;
    FZoom: Double;
    FAngleRad: Double;
    FPanX: Double;
    FPanY: Double;
    FBackgroundColor: TColor;
    FZoomOutRotatedFactor: Double;

    procedure SetSource(const AValue: TBmpMmapSource24);
    procedure SetZoom(const AValue: Double);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Renders the current view into a standard TBitmap (framebuffer-sized).
    // The bitmap is resized to match DestRect size.
    procedure RenderToBitmap(ABitmap: TBitmap; const DestRect: TRect);

    // Same rendering, but writes directly into Graphics32 bitmap.
    procedure RenderToBitmap32(ABitmap32: TBitmap32; const DestRect: TRect);

    property Source: TBmpMmapSource24 read FSource write SetSource;

    // Zoom factor: 1.0 means 1 screen px = 1 source px.
    property Zoom: Double read FZoom write SetZoom;

    // Rotation angle in radians (positive = CCW).
    property AngleRad: Double read FAngleRad write FAngleRad;

    // Pan in source pixel coordinates (added after rotation).
    property PanX: Double read FPanX write FPanX;
    property PanY: Double read FPanY write FPanY;

    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor;

    // Experimental: when Zoom < 1 and image is rotated, increase downsample step by this factor.
    property ZoomOutRotatedFactor: Double read FZoomOutRotatedFactor write FZoomOutRotatedFactor;
  end;

  TRasterViewRendererXY = class(TRasterViewRenderer)
  private
   FZoomX: Double;
   FZoomY: Double;
   procedure SetZoomX(const AValue: Double);
   procedure SetZoomY(const AValue: Double);
  public
   constructor Create(AOwner: TComponent); override;
   procedure RenderToBitmap(ABitmap: TBitmap; const DestRect: TRect);
   procedure RenderToBitmap32(ABitmap32: TBitmap32; const DestRect: TRect);
   property ZoomX: Double read FZoomX write SetZoomX;
   property ZoomY: Double read FZoomY write SetZoomY;
  end;

implementation

constructor TRasterViewRenderer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSource := nil;
  FZoom := 1.0;
  FAngleRad := 0.0;
  FPanX := 0.0;
  FPanY := 0.0;
  FBackgroundColor := clBtnFace;
  FZoomOutRotatedFactor := 1.5;
end;

destructor TRasterViewRenderer.Destroy;
begin
  inherited Destroy;
end;

procedure TRasterViewRenderer.SetSource(const AValue: TBmpMmapSource24);
begin
  if FSource = AValue then Exit;
  FSource := AValue;
end;

procedure TRasterViewRenderer.SetZoom(const AValue: Double);
begin
  if AValue <= 0 then
    FZoom := 1.0
  else
    FZoom := AValue;
end;

constructor TRasterViewRendererXY.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 FZoomX := 1.0;
 FZoomY := 1.0;
end;

procedure TRasterViewRendererXY.SetZoomX(const AValue: Double);
begin
 if AValue <= 0 then
  FZoomX := 1.0
 else
  FZoomX := AValue;
end;

procedure TRasterViewRendererXY.SetZoomY(const AValue: Double);
begin
 if AValue <= 0 then
  FZoomY := 1.0
 else
  FZoomY := AValue;
end;

procedure TRasterViewRenderer.RenderToBitmap(ABitmap: TBitmap; const DestRect: TRect);
var
  w, h: Integer;
  bmp: TBitmap;
  cx, cy: Double;
  scx, scy: Double;
  c, s: Double;
  rotEps: Double;
  x, y: Integer;
  dy: Double;
  sx, sy: Double;
  invZoom: Double;
  dx0: Double;
  sxRow, syRow: Double;
  stepSX, stepSY: Double;
  ix, iy: Integer;
  col: LongWord;
  bg: TColor;
  bgR, bgG, bgB: Byte;
  bgBGRA: Cardinal;
  dst: PCardinal;
  k: Integer;
  lastIx, lastIy: Integer;
  lastCol: LongWord;
  lastValid: Boolean;
  useTemp: Boolean;
  p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y: Double;
  minSX, minSY, maxSX, maxSY: Double;
  srcMinX, srcMinY, srcMaxX, srcMaxY: Integer;
  tmpW, tmpH: Integer;
  tmp: array of LongWord;
  tx, ty: Integer;
  baseX, baseY: Integer;
  tcol: LongWord;
begin
  if (ABitmap = nil) then Exit;

  w := DestRect.Right - DestRect.Left;
  h := DestRect.Bottom - DestRect.Top;
  if (w <= 0) or (h <= 0) then Exit;

  rotEps := 1e-12;
  if FZoom < 1.0 then
  begin
    if Abs(FAngleRad) > rotEps then
      k := Round((1.0 / FZoom) * FZoomOutRotatedFactor)
    else
      k := Round(1.0 / FZoom);
    if k < 1 then k := 1;
  end
  else
    k := 1;

  bmp := ABitmap;
  bmp.PixelFormat := pf32bit;
  bmp.SetSize(w, h);

  bg := ColorToRGB(FBackgroundColor);
  bgR := Byte(bg);
  bgG := Byte(bg shr 8);
  bgB := Byte(bg shr 16);
  bgBGRA := Cardinal(bgB) or (Cardinal(bgG) shl 8) or (Cardinal(bgR) shl 16) or (Cardinal(255) shl 24);

  // Fill the destination first: pixels outside the rotated source area should
  // show the background ("transparent to background").
  for y := 0 to h - 1 do
  begin
    dst := PCardinal(bmp.ScanLine[y]);
    for x := 0 to w - 1 do
      dst[x] := bgBGRA;
  end;

  if (FSource = nil) or (not FSource.IsOpen) then
    Exit;

  cx := (w - 1) * 0.5;
  cy := (h - 1) * 0.5;

  scx := (FSource.Width - 1) * 0.5 + FPanX;
  scy := (FSource.Height - 1) * 0.5 + FPanY;

  c := Cos(FAngleRad);
  s := Sin(FAngleRad);

  invZoom := 1.0 / FZoom;
  stepSX := c * invZoom;
  stepSY := -s * invZoom;
  dx0 := (-cx) * invZoom;

  useTemp := (k > 1) and (Abs(FAngleRad) > 1e-12);
  if useTemp then
  begin
    // 4 corners of the destination view in source space
    p0x := scx + (c * ((0 - cx) * invZoom) + s * ((0 - cy) * invZoom));
    p0y := scy + (-s * ((0 - cx) * invZoom) + c * ((0 - cy) * invZoom));

    p1x := scx + (c * (((w - 1) - cx) * invZoom) + s * ((0 - cy) * invZoom));
    p1y := scy + (-s * (((w - 1) - cx) * invZoom) + c * ((0 - cy) * invZoom));

    p2x := scx + (c * (((w - 1) - cx) * invZoom) + s * (((h - 1) - cy) * invZoom));
    p2y := scy + (-s * (((w - 1) - cx) * invZoom) + c * (((h - 1) - cy) * invZoom));

    p3x := scx + (c * ((0 - cx) * invZoom) + s * (((h - 1) - cy) * invZoom));
    p3y := scy + (-s * ((0 - cx) * invZoom) + c * (((h - 1) - cy) * invZoom));

    minSX := Min(Min(p0x, p1x), Min(p2x, p3x));
    maxSX := Max(Max(p0x, p1x), Max(p2x, p3x));
    minSY := Min(Min(p0y, p1y), Min(p2y, p3y));
    maxSY := Max(Max(p0y, p1y), Max(p2y, p3y));

    srcMinX := Floor(minSX) - 2;
    srcMinY := Floor(minSY) - 2;
    srcMaxX := Ceil(maxSX) + 2;
    srcMaxY := Ceil(maxSY) + 2;

    if srcMinX < 0 then srcMinX := 0;
    if srcMinY < 0 then srcMinY := 0;
    if srcMaxX >= FSource.Width then srcMaxX := FSource.Width - 1;
    if srcMaxY >= FSource.Height then srcMaxY := FSource.Height - 1;

    if (srcMaxX < srcMinX) or (srcMaxY < srcMinY) then
      useTemp := False
    else
    begin
      baseX := (srcMinX div k) * k;
      baseY := (srcMinY div k) * k;
      if baseX < 0 then baseX := 0;
      if baseY < 0 then baseY := 0;

      tmpW := ((srcMaxX - baseX) div k) + 1;
      tmpH := ((srcMaxY - baseY) div k) + 1;
      if (tmpW <= 0) or (tmpH <= 0) then
        useTemp := False
      else
      begin
        SetLength(tmp, tmpW * tmpH);
        for ty := 0 to tmpH - 1 do
        begin
          iy := baseY + ty * k;
          for tx := 0 to tmpW - 1 do
          begin
            ix := baseX + tx * k;
            if (ix >= 0) and (ix < FSource.Width) and (iy >= 0) and (iy < FSource.Height) then
            begin
              if FSource.GetPixelBGRA(ix, iy, tcol) then
                tmp[ty * tmpW + tx] := tcol
              else
                tmp[ty * tmpW + tx] := LongWord(bgBGRA);
            end
            else
              tmp[ty * tmpW + tx] := LongWord(bgBGRA);
          end;
        end;
      end;
    end;
  end;

  for y := 0 to h - 1 do
  begin
    dst := PCardinal(bmp.ScanLine[y]);
    lastValid := False;

    dy := (y - cy) * invZoom;
    sxRow := scx + (c * dx0 + s * dy);
    syRow := scy + (-s * dx0 + c * dy);
    sx := sxRow;
    sy := syRow;

    for x := 0 to w - 1 do
    begin
      ix := Floor(sx + 0.5);
      iy := Floor(sy + 0.5);

      sx := sx + stepSX;
      sy := sy + stepSY;

      if useTemp then
      begin
        tx := (ix - baseX) div k;
        ty := (iy - baseY) div k;
        if (tx >= 0) and (tx < tmpW) and (ty >= 0) and (ty < tmpH) then
          dst[x] := Cardinal(tmp[ty * tmpW + tx])
        else
          Continue;
      end
      else
      begin
        if k > 1 then
        begin
          ix := (ix div k) * k;
          iy := (iy div k) * k;
        end;

        if (ix >= 0) and (ix < FSource.Width) and (iy >= 0) and (iy < FSource.Height) then
        begin
          if lastValid and (ix = lastIx) and (iy = lastIy) then
            dst[x] := Cardinal(lastCol)
          else
          begin
            if FSource.GetPixelBGRA(ix, iy, col) then
            begin
              dst[x] := Cardinal(col);
              lastIx := ix;
              lastIy := iy;
              lastCol := col;
              lastValid := True;
            end
            else
              Continue;
          end;
        end
        else
          Continue;
      end;
    end;
  end;
end;

procedure TRasterViewRenderer.RenderToBitmap32(ABitmap32: TBitmap32; const DestRect: TRect);
var
  w, h: Integer;
  cx, cy: Double;
  scx, scy: Double;
  c, s: Double;
  rotEps: Double;
  x, y: Integer;
  dy: Double;
  sx, sy: Double;
  invZoom: Double;
  dx0: Double;
  sxRow, syRow: Double;
  stepSX, stepSY: Double;
  ix, iy: Integer;
  col: LongWord;
  bg: TColor;
  bgR, bgG, bgB: Byte;
  bgBGRA: Cardinal;
  dstLine: PColor32Array;
  k: Integer;
  lastIx, lastIy: Integer;
  lastCol: LongWord;
  lastValid: Boolean;
  useTemp: Boolean;
  p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y: Double;
  minSX, minSY, maxSX, maxSY: Double;
  srcMinX, srcMinY, srcMaxX, srcMaxY: Integer;
  tmpW, tmpH: Integer;
  tmp: array of LongWord;
  tx, ty: Integer;
  baseX, baseY: Integer;
  tcol: LongWord;
  bg32: TColor32;
begin
  if (ABitmap32 = nil) then Exit;

  w := DestRect.Right - DestRect.Left;
  h := DestRect.Bottom - DestRect.Top;
  if (w <= 0) or (h <= 0) then Exit;

  rotEps := 1e-12;
  if FZoom < 1.0 then
  begin
    if Abs(FAngleRad) > rotEps then
      k := Round((1.0 / FZoom) * FZoomOutRotatedFactor)
    else
      k := Round(1.0 / FZoom);
    if k < 1 then k := 1;
  end
  else
    k := 1;

  ABitmap32.SetSize(w, h);

  bg := ColorToRGB(FBackgroundColor);
  bgR := Byte(bg);
  bgG := Byte(bg shr 8);
  bgB := Byte(bg shr 16);
  bgBGRA := Cardinal(bgB) or (Cardinal(bgG) shl 8) or (Cardinal(bgR) shl 16) or (Cardinal(255) shl 24);
  ABitmap32.Clear(TColor32(bgBGRA));

  if (FSource = nil) or (not FSource.IsOpen) then
    Exit;

  cx := (w - 1) * 0.5;
  cy := (h - 1) * 0.5;

  scx := (FSource.Width - 1) * 0.5 + FPanX;
  scy := (FSource.Height - 1) * 0.5 + FPanY;

  c := Cos(FAngleRad);
  s := Sin(FAngleRad);

  invZoom := 1.0 / FZoom;
  stepSX := c * invZoom;
  stepSY := -s * invZoom;
  dx0 := (-cx) * invZoom;

  useTemp := (k > 1) and (Abs(FAngleRad) > 1e-12);
  if useTemp then
  begin
    p0x := scx + (c * ((0 - cx) * invZoom) + s * ((0 - cy) * invZoom));
    p0y := scy + (-s * ((0 - cx) * invZoom) + c * ((0 - cy) * invZoom));

    p1x := scx + (c * (((w - 1) - cx) * invZoom) + s * ((0 - cy) * invZoom));
    p1y := scy + (-s * (((w - 1) - cx) * invZoom) + c * ((0 - cy) * invZoom));

    p2x := scx + (c * (((w - 1) - cx) * invZoom) + s * (((h - 1) - cy) * invZoom));
    p2y := scy + (-s * (((w - 1) - cx) * invZoom) + c * (((h - 1) - cy) * invZoom));

    p3x := scx + (c * ((0 - cx) * invZoom) + s * (((h - 1) - cy) * invZoom));
    p3y := scy + (-s * ((0 - cx) * invZoom) + c * (((h - 1) - cy) * invZoom));

    minSX := Min(Min(p0x, p1x), Min(p2x, p3x));
    maxSX := Max(Max(p0x, p1x), Max(p2x, p3x));
    minSY := Min(Min(p0y, p1y), Min(p2y, p3y));
    maxSY := Max(Max(p0y, p1y), Max(p2y, p3y));

    srcMinX := Floor(minSX) - 2;
    srcMinY := Floor(minSY) - 2;
    srcMaxX := Ceil(maxSX) + 2;
    srcMaxY := Ceil(maxSY) + 2;

    if srcMinX < 0 then srcMinX := 0;
    if srcMinY < 0 then srcMinY := 0;
    if srcMaxX >= FSource.Width then srcMaxX := FSource.Width - 1;
    if srcMaxY >= FSource.Height then srcMaxY := FSource.Height - 1;

    if (srcMaxX < srcMinX) or (srcMaxY < srcMinY) then
      useTemp := False
    else
    begin
      baseX := (srcMinX div k) * k;
      baseY := (srcMinY div k) * k;
      if baseX < 0 then baseX := 0;
      if baseY < 0 then baseY := 0;

      tmpW := ((srcMaxX - baseX) div k) + 1;
      tmpH := ((srcMaxY - baseY) div k) + 1;
      if (tmpW <= 0) or (tmpH <= 0) then
        useTemp := False
      else
      begin
        SetLength(tmp, tmpW * tmpH);
        for ty := 0 to tmpH - 1 do
        begin
          iy := baseY + ty * k;
          for tx := 0 to tmpW - 1 do
          begin
            ix := baseX + tx * k;
            if (ix >= 0) and (ix < FSource.Width) and (iy >= 0) and (iy < FSource.Height) then
            begin
              if FSource.GetPixelBGRA(ix, iy, tcol) then
                tmp[ty * tmpW + tx] := tcol
              else
                tmp[ty * tmpW + tx] := LongWord(bgBGRA);
            end
            else
              tmp[ty * tmpW + tx] := LongWord(bgBGRA);
          end;
        end;
      end;
    end;
  end;

  for y := 0 to h - 1 do
  begin
    dstLine := PColor32Array(ABitmap32.ScanLine[y]);
    lastValid := False;

    dy := (y - cy) * invZoom;
    sxRow := scx + (c * dx0 + s * dy);
    syRow := scy + (-s * dx0 + c * dy);
    sx := sxRow;
    sy := syRow;

    for x := 0 to w - 1 do
    begin
      ix := Floor(sx + 0.5);
      iy := Floor(sy + 0.5);

      sx := sx + stepSX;
      sy := sy + stepSY;

      if useTemp then
      begin
        tx := (ix - baseX) div k;
        ty := (iy - baseY) div k;
        if (tx >= 0) and (tx < tmpW) and (ty >= 0) and (ty < tmpH) then
          dstLine^[x] := TColor32(tmp[ty * tmpW + tx])
        else
          Continue;
      end
      else
      begin
        if k > 1 then
        begin
          ix := (ix div k) * k;
          iy := (iy div k) * k;
        end;

        if (ix >= 0) and (ix < FSource.Width) and (iy >= 0) and (iy < FSource.Height) then
        begin
          if lastValid and (ix = lastIx) and (iy = lastIy) then
            dstLine^[x] := TColor32(lastCol)
          else
          begin
            if FSource.GetPixelBGRA(ix, iy, col) then
            begin
              // TBmpMmapSource24 returns BGRA-packed LongWord.
              dstLine^[x] := TColor32(col);
              lastIx := ix;
              lastIy := iy;
              lastCol := col;
              lastValid := True;
            end
            else
              Continue;
          end;
        end
        else
          Continue;
      end;
    end;
  end;
end;

procedure TRasterViewRendererXY.RenderToBitmap(ABitmap: TBitmap; const DestRect: TRect);
var
 w, h: Integer;
 bmp: TBitmap;
 cx, cy: Double;
 scx, scy: Double;
 c, s: Double;
 rotEps: Double;
 x, y: Integer;
 dx0, dy0: Double;
 rx, ry: Double;
 rxRow, ryRow: Double;
 sx, sy: Double;
 invZoomX, invZoomY: Double;
 stepRX, stepRY: Double;
 ix, iy: Integer;
 col: LongWord;
 bg: TColor;
 bgR, bgG, bgB: Byte;
 bgBGRA: Cardinal;
 dst: PCardinal;
 kX, kY: Integer;
 lastIx, lastIy: Integer;
 lastCol: LongWord;
 lastValid: Boolean;
 useTemp: Boolean;
 srcMinX, srcMinY, srcMaxX, srcMaxY: Integer;
 minSX, minSY, maxSX, maxSY: Double;
 p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y: Double;
 baseX, baseY: Integer;
 tmpW, tmpH: Integer;
 tx, ty: Integer;
 tcol: LongWord;
 tmp: array of LongWord;
begin
 if (ABitmap = nil) then Exit;

 w := DestRect.Right - DestRect.Left;
 h := DestRect.Bottom - DestRect.Top;
 if (w <= 0) or (h <= 0) then Exit;

 bmp := ABitmap;
 bmp.PixelFormat := pf32bit;
 bmp.SetSize(w, h);

 bg := ColorToRGB(FBackgroundColor);
 bgR := Byte(bg);
 bgG := Byte(bg shr 8);
 bgB := Byte(bg shr 16);
 bgBGRA := Cardinal(bgB) or (Cardinal(bgG) shl 8) or (Cardinal(bgR) shl 16) or (Cardinal(255) shl 24);

 for y := 0 to h - 1 do
 begin
  dst := PCardinal(bmp.ScanLine[y]);
  for x := 0 to w - 1 do
   dst[x] := bgBGRA;
 end;

 if (FSource = nil) or (not FSource.IsOpen) then
  Exit;

 rotEps := 1e-12;
 kX := 1;
 kY := 1;
 if (FZoomX < 1.0) or (FZoomY < 1.0) then
 begin
  if FZoomX < 1.0 then
  begin
   if Abs(FAngleRad) > rotEps then
    kX := Round((1.0 / FZoomX) * FZoomOutRotatedFactor)
   else
    kX := Round(1.0 / FZoomX);
   if kX < 1 then kX := 1;
  end;
  if FZoomY < 1.0 then
  begin
   if Abs(FAngleRad) > rotEps then
    kY := Round((1.0 / FZoomY) * FZoomOutRotatedFactor)
   else
    kY := Round(1.0 / FZoomY);
   if kY < 1 then kY := 1;
  end;
 end;

 cx := (w - 1) * 0.5;
 cy := (h - 1) * 0.5;

 scx := (FSource.Width - 1) * 0.5 + FPanX;
 scy := (FSource.Height - 1) * 0.5 + FPanY;

 c := Cos(FAngleRad);
 s := Sin(FAngleRad);

 invZoomX := 1.0 / FZoomX;
 invZoomY := 1.0 / FZoomY;

 // Correct inverse mapping for anisotropic scale:
 // [rx; ry] = R(-a) * ([x - cx; y - cy])
 // srcX = scx + rx / ZoomX
 // srcY = scy + ry / ZoomY
 dx0 := (-cx);
 stepRX := c;
 stepRY := -s;

 useTemp := False;
 if (kX > 1) or (kY > 1) then
 begin
  rx := c * (0 - cx) + s * (0 - cy);
  ry := -s * (0 - cx) + c * (0 - cy);
  p0x := scx + rx * invZoomX;
  p0y := scy + ry * invZoomY;

  rx := c * (((w - 1) - cx)) + s * (0 - cy);
  ry := -s * (((w - 1) - cx)) + c * (0 - cy);
  p1x := scx + rx * invZoomX;
  p1y := scy + ry * invZoomY;

  rx := c * (((w - 1) - cx)) + s * (((h - 1) - cy));
  ry := -s * (((w - 1) - cx)) + c * (((h - 1) - cy));
  p2x := scx + rx * invZoomX;
  p2y := scy + ry * invZoomY;

  rx := c * (0 - cx) + s * (((h - 1) - cy));
  ry := -s * (0 - cx) + c * (((h - 1) - cy));
  p3x := scx + rx * invZoomX;
  p3y := scy + ry * invZoomY;

  minSX := Min(Min(p0x, p1x), Min(p2x, p3x));
  maxSX := Max(Max(p0x, p1x), Max(p2x, p3x));
  minSY := Min(Min(p0y, p1y), Min(p2y, p3y));
  maxSY := Max(Max(p0y, p1y), Max(p2y, p3y));

  srcMinX := Floor(minSX) - 2;
  srcMinY := Floor(minSY) - 2;
  srcMaxX := Ceil(maxSX) + 2;
  srcMaxY := Ceil(maxSY) + 2;

  if srcMinX < 0 then srcMinX := 0;
  if srcMinY < 0 then srcMinY := 0;
  if srcMaxX >= FSource.Width then srcMaxX := FSource.Width - 1;
  if srcMaxY >= FSource.Height then srcMaxY := FSource.Height - 1;

  if (srcMaxX >= srcMinX) and (srcMaxY >= srcMinY) then
  begin
   baseX := (srcMinX div kX) * kX;
   baseY := (srcMinY div kY) * kY;
   if baseX < 0 then baseX := 0;
   if baseY < 0 then baseY := 0;

   tmpW := ((srcMaxX - baseX) div kX) + 1;
   tmpH := ((srcMaxY - baseY) div kY) + 1;
   if (tmpW > 0) and (tmpH > 0) then
   begin
    SetLength(tmp, tmpW * tmpH);
    for ty := 0 to tmpH - 1 do
    begin
     iy := baseY + ty * kY;
     for tx := 0 to tmpW - 1 do
     begin
      ix := baseX + tx * kX;
      if (ix >= 0) and (ix < FSource.Width) and (iy >= 0) and (iy < FSource.Height) then
      begin
       if FSource.GetPixelBGRA(ix, iy, tcol) then
        tmp[ty * tmpW + tx] := tcol
       else
        tmp[ty * tmpW + tx] := LongWord(bgBGRA);
      end
      else
       tmp[ty * tmpW + tx] := LongWord(bgBGRA);
     end;
    end;
    useTemp := True;
   end;
  end;
 end;

 for y := 0 to h - 1 do
 begin
  dst := PCardinal(bmp.ScanLine[y]);
  lastValid := False;

  dy0 := (y - cy);
  rxRow := c * dx0 + s * dy0;
  ryRow := -s * dx0 + c * dy0;
  rx := rxRow;
  ry := ryRow;

  for x := 0 to w - 1 do
  begin
   sx := scx + rx * invZoomX;
   sy := scy + ry * invZoomY;
   ix := Floor(sx + 0.5);
   iy := Floor(sy + 0.5);

   rx := rx + stepRX;
   ry := ry + stepRY;

   if useTemp then
   begin
    tx := (ix - baseX) div kX;
    ty := (iy - baseY) div kY;
    if (tx >= 0) and (tx < tmpW) and (ty >= 0) and (ty < tmpH) then
     dst[x] := Cardinal(tmp[ty * tmpW + tx]);
   end
   else
   begin
    if kX > 1 then ix := (ix div kX) * kX;
    if kY > 1 then iy := (iy div kY) * kY;

    if (ix >= 0) and (ix < FSource.Width) and (iy >= 0) and (iy < FSource.Height) then
    begin
     if lastValid and (ix = lastIx) and (iy = lastIy) then
      dst[x] := Cardinal(lastCol)
     else
     begin
      if FSource.GetPixelBGRA(ix, iy, col) then
      begin
       dst[x] := Cardinal(col);
       lastIx := ix;
       lastIy := iy;
       lastCol := col;
       lastValid := True;
      end;
     end;
    end;
   end;
  end;
 end;
end;

procedure TRasterViewRendererXY.RenderToBitmap32(ABitmap32: TBitmap32; const DestRect: TRect);
var
 w, h: Integer;
 cx, cy: Double;
 scx, scy: Double;
 c, s: Double;
 rotEps: Double;
 x, y: Integer;
 dx0, dy0: Double;
 rx, ry: Double;
 rxRow, ryRow: Double;
 sx, sy: Double;
 invZoomX, invZoomY: Double;
 stepRX, stepRY: Double;
 ix, iy: Integer;
 col: LongWord;
 bg: TColor;
 bgR, bgG, bgB: Byte;
 bgBGRA: Cardinal;
 dstLine: PColor32Array;
 kX, kY: Integer;
 lastIx, lastIy: Integer;
 lastCol: LongWord;
 lastValid: Boolean;
 useTemp: Boolean;
 srcMinX, srcMinY, srcMaxX, srcMaxY: Integer;
 minSX, minSY, maxSX, maxSY: Double;
 p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y: Double;
 baseX, baseY: Integer;
 tmpW, tmpH: Integer;
 tx, ty: Integer;
 tcol: LongWord;
 tmp: array of LongWord;
begin
 if (ABitmap32 = nil) then Exit;

 w := DestRect.Right - DestRect.Left;
 h := DestRect.Bottom - DestRect.Top;
 if (w <= 0) or (h <= 0) then Exit;

 ABitmap32.SetSize(w, h);

 bg := ColorToRGB(FBackgroundColor);
 bgR := Byte(bg);
 bgG := Byte(bg shr 8);
 bgB := Byte(bg shr 16);
 bgBGRA := Cardinal(bgB) or (Cardinal(bgG) shl 8) or (Cardinal(bgR) shl 16) or (Cardinal(255) shl 24);
 ABitmap32.Clear(TColor32(bgBGRA));

 if (FSource = nil) or (not FSource.IsOpen) then
  Exit;

 rotEps := 1e-12;
 kX := 1;
 kY := 1;
 if (FZoomX < 1.0) or (FZoomY < 1.0) then
 begin
  if FZoomX < 1.0 then
  begin
   if Abs(FAngleRad) > rotEps then
    kX := Round((1.0 / FZoomX) * FZoomOutRotatedFactor)
   else
    kX := Round(1.0 / FZoomX);
   if kX < 1 then kX := 1;
  end;
  if FZoomY < 1.0 then
  begin
   if Abs(FAngleRad) > rotEps then
    kY := Round((1.0 / FZoomY) * FZoomOutRotatedFactor)
   else
    kY := Round(1.0 / FZoomY);
   if kY < 1 then kY := 1;
  end;
 end;

 cx := (w - 1) * 0.5;
 cy := (h - 1) * 0.5;

 scx := (FSource.Width - 1) * 0.5 + FPanX;
 scy := (FSource.Height - 1) * 0.5 + FPanY;

 c := Cos(FAngleRad);
 s := Sin(FAngleRad);

 invZoomX := 1.0 / FZoomX;
 invZoomY := 1.0 / FZoomY;

 // Correct inverse mapping for anisotropic scale:
 // [rx; ry] = R(-a) * ([x - cx; y - cy])
 // srcX = scx + rx / ZoomX
 // srcY = scy + ry / ZoomY
 dx0 := (-cx);
 stepRX := c;
 stepRY := -s;

 useTemp := False;
 if (kX > 1) or (kY > 1) then
 begin
  rx := c * (0 - cx) + s * (0 - cy);
  ry := -s * (0 - cx) + c * (0 - cy);
  p0x := scx + rx * invZoomX;
  p0y := scy + ry * invZoomY;

  rx := c * (((w - 1) - cx)) + s * (0 - cy);
  ry := -s * (((w - 1) - cx)) + c * (0 - cy);
  p1x := scx + rx * invZoomX;
  p1y := scy + ry * invZoomY;

  rx := c * (((w - 1) - cx)) + s * (((h - 1) - cy));
  ry := -s * (((w - 1) - cx)) + c * (((h - 1) - cy));
  p2x := scx + rx * invZoomX;
  p2y := scy + ry * invZoomY;

  rx := c * (0 - cx) + s * (((h - 1) - cy));
  ry := -s * (0 - cx) + c * (((h - 1) - cy));
  p3x := scx + rx * invZoomX;
  p3y := scy + ry * invZoomY;

  minSX := Min(Min(p0x, p1x), Min(p2x, p3x));
  maxSX := Max(Max(p0x, p1x), Max(p2x, p3x));
  minSY := Min(Min(p0y, p1y), Min(p2y, p3y));
  maxSY := Max(Max(p0y, p1y), Max(p2y, p3y));

  srcMinX := Floor(minSX) - 2;
  srcMinY := Floor(minSY) - 2;
  srcMaxX := Ceil(maxSX) + 2;
  srcMaxY := Ceil(maxSY) + 2;

  if srcMinX < 0 then srcMinX := 0;
  if srcMinY < 0 then srcMinY := 0;
  if srcMaxX >= FSource.Width then srcMaxX := FSource.Width - 1;
  if srcMaxY >= FSource.Height then srcMaxY := FSource.Height - 1;

  if (srcMaxX >= srcMinX) and (srcMaxY >= srcMinY) then
  begin
   baseX := (srcMinX div kX) * kX;
   baseY := (srcMinY div kY) * kY;
   if baseX < 0 then baseX := 0;
   if baseY < 0 then baseY := 0;

   tmpW := ((srcMaxX - baseX) div kX) + 1;
   tmpH := ((srcMaxY - baseY) div kY) + 1;
   if (tmpW > 0) and (tmpH > 0) then
   begin
    SetLength(tmp, tmpW * tmpH);
    for ty := 0 to tmpH - 1 do
    begin
     iy := baseY + ty * kY;
     for tx := 0 to tmpW - 1 do
     begin
      ix := baseX + tx * kX;
      if (ix >= 0) and (ix < FSource.Width) and (iy >= 0) and (iy < FSource.Height) then
      begin
       if FSource.GetPixelBGRA(ix, iy, tcol) then
        tmp[ty * tmpW + tx] := tcol
       else
        tmp[ty * tmpW + tx] := LongWord(bgBGRA);
      end
      else
       tmp[ty * tmpW + tx] := LongWord(bgBGRA);
     end;
    end;
    useTemp := True;
   end;
  end;
 end;

 for y := 0 to h - 1 do
 begin
  dstLine := PColor32Array(ABitmap32.ScanLine[y]);
  lastValid := False;

  dy0 := (y - cy);
  rxRow := c * dx0 + s * dy0;
  ryRow := -s * dx0 + c * dy0;
  rx := rxRow;
  ry := ryRow;

  for x := 0 to w - 1 do
  begin
   sx := scx + rx * invZoomX;
   sy := scy + ry * invZoomY;
   ix := Floor(sx + 0.5);
   iy := Floor(sy + 0.5);

   rx := rx + stepRX;
   ry := ry + stepRY;

   if useTemp then
   begin
    tx := (ix - baseX) div kX;
    ty := (iy - baseY) div kY;
    if (tx >= 0) and (tx < tmpW) and (ty >= 0) and (ty < tmpH) then
     dstLine^[x] := TColor32(tmp[ty * tmpW + tx]);
   end
   else
   begin
    if kX > 1 then ix := (ix div kX) * kX;
    if kY > 1 then iy := (iy div kY) * kY;

    if (ix >= 0) and (ix < FSource.Width) and (iy >= 0) and (iy < FSource.Height) then
    begin
     if lastValid and (ix = lastIx) and (iy = lastIy) then
      dstLine^[x] := TColor32(lastCol)
     else
     begin
      if FSource.GetPixelBGRA(ix, iy, col) then
      begin
       dstLine^[x] := TColor32(col);
       lastIx := ix;
       lastIy := iy;
       lastCol := col;
       lastValid := True;
      end;
     end;
    end;
   end;
  end;
 end;
end;

end.
