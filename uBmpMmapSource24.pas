unit uBmpMmapSource24;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics,
  uPartialFileMapping;

type
  TBmpFileHeader = packed record
    bfType: Word;
    bfSize: LongWord;
    bfReserved1: Word;
    bfReserved2: Word;
    bfOffBits: LongWord;
  end;

  TBmpInfoHeader = packed record
    biSize: LongWord;
    biWidth: LongInt;
    biHeight: LongInt;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: LongWord;
    biSizeImage: LongWord;
    biXPelsPerMeter: LongInt;
    biYPelsPerMeter: LongInt;
    biClrUsed: LongWord;
    biClrImportant: LongWord;
  end;

  TRGBQuad = packed record
    b: Byte;
    g: Byte;
    r: Byte;
    a: Byte;
  end;

  TGetPixelBGRAFunc = function(X, Y: Integer; out ColorBGRA: LongWord): Boolean of object;

  TBmpMmapSource24 = class(TComponent)
  private
    FMapping: TPartialFileMapping;
    FOwnsMapping: Boolean;

    FFileName: string;
    FIsOpen: Boolean;

    FWidth: Integer;
    FHeight: Integer;
    FStride: Integer;
    FDataOffset: Int64;
    FTopDown: Boolean;

    FXPelsPerMeter: LongInt;
    FYPelsPerMeter: LongInt;

    FBitCount: Integer;
    FCompression: LongWord;
    FColorsUsed: Integer;
    FPaletteBGRA: array of LongWord;

    FMaskR: LongWord;
    FMaskG: LongWord;
    FMaskB: LongWord;
    FMaskA: LongWord;
    FHasAlphaMask: Boolean;

    FGetPixelBGRA: TGetPixelBGRAFunc;

    FTransparentEnabled: Boolean;
    // For paletted BMP (1/4/8 bpp): if >=0 then this palette index is treated as transparent.
    FTransparentIndex: Integer;
    // For 24/32 bpp: if enabled, pixel is transparent when its RGB matches this value (alpha ignored).
    FTransparentRGB: LongWord;

    FOverview4: PCardinal;
    FOverview4Valid: Boolean;
    FOverview4W: Integer;
    FOverview4H: Integer;

    FOverview8: PCardinal;
    FOverview8Valid: Boolean;
    FOverview8W: Integer;
    FOverview8H: Integer;

    FOverview16: PCardinal;
    FOverview16Valid: Boolean;
    FOverview16W: Integer;
    FOverview16H: Integer;

    procedure SetFileName(const AValue: string);
    procedure EnsureMapping;
    procedure InvalidateOverviews;
    function BuildOverview(Factor: Integer; var ABuf: PCardinal; out OutW, OutH: Integer): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Open: Boolean;
    procedure Close;

    function ScanlinePtr(Y: Integer): PByte;

    function GetPixelBGRA(X, Y: Integer; out ColorBGRA: LongWord): Boolean;

    function PaletteCount: Integer;
    function GetPaletteEntryBGRA(Index: Integer; out ColorBGRA: LongWord): Boolean;
    function SetPaletteEntryBGRA(Index: Integer; ColorBGRA: LongWord): Boolean;

    function EnsureOverview4: Boolean;
    function HasOverview4: Boolean;
    function Overview4Width: Integer;
    function Overview4Height: Integer;
    function GetOverview4PixelBGRA(X, Y: Integer; out ColorBGRA: LongWord): Boolean;

    function EnsureOverview8: Boolean;
    function HasOverview8: Boolean;
    function Overview8Width: Integer;
    function Overview8Height: Integer;
    function GetOverview8PixelBGRA(X, Y: Integer; out ColorBGRA: LongWord): Boolean;

    function EnsureOverview16: Boolean;
    function HasOverview16: Boolean;
    function Overview16Width: Integer;
    function Overview16Height: Integer;
    function GetOverview16PixelBGRA(X, Y: Integer; out ColorBGRA: LongWord): Boolean;

    procedure SaveOverviewsToFiles(const BaseName: string);

    property TransparentEnabled: Boolean read FTransparentEnabled write FTransparentEnabled;
    property TransparentIndex: Integer read FTransparentIndex write FTransparentIndex;
    property TransparentRGB: LongWord read FTransparentRGB write FTransparentRGB;

    property Mapping: TPartialFileMapping read FMapping;
    property IsOpen: Boolean read FIsOpen;

    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Stride: Integer read FStride;
    property DataOffset: Int64 read FDataOffset;
    property TopDown: Boolean read FTopDown;
    property BitCount: Integer read FBitCount;
    property XPelsPerMeter: LongInt read FXPelsPerMeter;
    property YPelsPerMeter: LongInt read FYPelsPerMeter;
  published
    property FileName: string read FFileName write SetFileName;
  end;

implementation

type
  TBitmapFileHeader = packed record
    bfType: Word;
    bfSize: LongWord;
    bfReserved1: Word;
    bfReserved2: Word;
    bfOffBits: LongWord;
  end;

  TBitmapInfoHeader = packed record
    biSize: LongWord;
    biWidth: LongInt;
    biHeight: LongInt;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: LongWord;
    biSizeImage: LongWord;
    biXPelsPerMeter: LongInt;
    biYPelsPerMeter: LongInt;
    biClrUsed: LongWord;
    biClrImportant: LongWord;
  end;

procedure SaveBGRA32ToBmpFile(const FileName: string; Buf: PCardinal; W, H: Integer);
var
  fs: TFileStream;
  fh: TBitmapFileHeader;
  ih: TBitmapInfoHeader;
  pixelBytes: SizeUInt;
begin
  if (Buf = nil) or (W <= 0) or (H <= 0) then Exit;

  pixelBytes := SizeUInt(W) * SizeUInt(H) * SizeUInt(SizeOf(Cardinal));

  FillChar(fh, SizeOf(fh), 0);
  FillChar(ih, SizeOf(ih), 0);
  fh.bfType := $4D42;
  fh.bfOffBits := SizeOf(TBitmapFileHeader) + SizeOf(TBitmapInfoHeader);
  fh.bfSize := fh.bfOffBits + LongWord(pixelBytes);

  ih.biSize := SizeOf(TBitmapInfoHeader);
  ih.biWidth := W;
  ih.biHeight := -H;
  ih.biPlanes := 1;
  ih.biBitCount := 32;
  ih.biCompression := 0;
  ih.biSizeImage := LongWord(pixelBytes);

  fs := TFileStream.Create(FileName, fmCreate);
  try
    fs.WriteBuffer(fh, SizeOf(fh));
    fs.WriteBuffer(ih, SizeOf(ih));
    fs.WriteBuffer(Buf^, pixelBytes);
  finally
    fs.Free;
  end;
end;

procedure TBmpMmapSource24.SaveOverviewsToFiles(const BaseName: string);
begin
  if BaseName = '' then Exit;
  if EnsureOverview4 and HasOverview4 then
    SaveBGRA32ToBmpFile(BaseName + '_ov4.bmp', FOverview4, FOverview4W, FOverview4H);
  if EnsureOverview8 and HasOverview8 then
    SaveBGRA32ToBmpFile(BaseName + '_ov8.bmp', FOverview8, FOverview8W, FOverview8H);
  if EnsureOverview16 and HasOverview16 then
    SaveBGRA32ToBmpFile(BaseName + '_ov16.bmp', FOverview16, FOverview16W, FOverview16H);
end;

constructor TBmpMmapSource24.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMapping := nil;
  FOwnsMapping := False;
  FFileName := '';
  FIsOpen := False;

  FWidth := 0;
  FHeight := 0;
  FStride := 0;
  FDataOffset := 0;
  FTopDown := False;

  FXPelsPerMeter := 0;
  FYPelsPerMeter := 0;

  FBitCount := 0;
  FCompression := 0;
  FColorsUsed := 0;
  SetLength(FPaletteBGRA, 0);

  FMaskR := 0;
  FMaskG := 0;
  FMaskB := 0;
  FMaskA := 0;
  FHasAlphaMask := False;

  FGetPixelBGRA := nil;

  FTransparentEnabled := False;
  FTransparentIndex := -1;
  FTransparentRGB := 0;

  FOverview4 := nil;
  FOverview4Valid := False;
  FOverview4W := 0;
  FOverview4H := 0;

  FOverview8 := nil;
  FOverview8Valid := False;
  FOverview8W := 0;
  FOverview8H := 0;

  FOverview16 := nil;
  FOverview16Valid := False;
  FOverview16W := 0;
  FOverview16H := 0;
end;

destructor TBmpMmapSource24.Destroy;
begin
  Close;
  if FOwnsMapping then
    FreeAndNil(FMapping);
  if FOverview4 <> nil then
    FreeMem(FOverview4);
  if FOverview8 <> nil then
    FreeMem(FOverview8);
  if FOverview16 <> nil then
    FreeMem(FOverview16);
  inherited Destroy;
end;

procedure TBmpMmapSource24.SetFileName(const AValue: string);
begin
  if FFileName = AValue then Exit;
  if FIsOpen then
    raise Exception.Create('Cannot change FileName while open');
  FFileName := AValue;
  InvalidateOverviews;
end;

procedure TBmpMmapSource24.InvalidateOverviews;
begin
  FOverview4Valid := False;
  FOverview8Valid := False;
  FOverview16Valid := False;
end;

procedure TBmpMmapSource24.EnsureMapping;
begin
  if FMapping <> nil then Exit;

  FMapping := TPartialFileMapping.Create(nil);
  FMapping.ReadOnly := True;
  // Keep granularity unified with Win64 behavior (64KB). Valid on Linux too.
  FMapping.MappingGranularity := 65536;
  // Default window; can be changed later if you expose it.
  FMapping.WindowSize := 64 * 1024 * 1024;
  FOwnsMapping := True;
end;

function TBmpMmapSource24.Open: Boolean;
var
  fh: TBmpFileHeader;
  ih: TBmpInfoHeader;
  p: PByte;
  absH: Int64;
  rowBytes: Int64;
  pad: Int64;
  hdrSize: Int64;
  palCount: Int64;
  paletteOffset: Int64;
  i: Integer;
  q: TRGBQuad;
  masksOffset: Int64;
  mr, mg, mb, ma: LongWord;
begin
  Result := False;
  if FIsOpen then Exit(True);
  if FFileName = '' then Exit;

  EnsureMapping;
  if FMapping = nil then Exit;

  FMapping.FileName := FFileName;

  if not FMapping.Open then Exit;

  // Read minimal headers first.
  if not FMapping.EnsureRange(0, SizeUInt(SizeOf(TBmpFileHeader) + SizeOf(TBmpInfoHeader))) then Exit;

  p := FMapping.PtrAt(0);
  if p = nil then Exit;

  Move(p^, fh, SizeOf(fh));
  Inc(p, SizeOf(fh));
  Move(p^, ih, SizeOf(ih));

  if fh.bfType <> $4D42 { 'BM' } then Exit;
  if ih.biPlanes <> 1 then Exit;

  FBitCount := ih.biBitCount;
  FCompression := ih.biCompression;

  FXPelsPerMeter := ih.biXPelsPerMeter;
  FYPelsPerMeter := ih.biYPelsPerMeter;

  if not (FBitCount in [1, 4, 8, 24, 32]) then Exit;
  if not (FCompression in [0, 3]) then Exit; // BI_RGB or BI_BITFIELDS

  FWidth := ih.biWidth;
  FTopDown := (ih.biHeight < 0);
  absH := ih.biHeight;
  if absH < 0 then absH := -absH;
  if absH > High(Integer) then Exit;
  FHeight := Integer(absH);

  if (FWidth <= 0) or (FHeight <= 0) then Exit;

  // Stride in BMP is padded to 4 bytes.
  rowBytes := (Int64(FWidth) * Int64(FBitCount) + 7) div 8;
  pad := (4 - (rowBytes mod 4)) mod 4;
  FStride := Integer(rowBytes + pad);

  FDataOffset := fh.bfOffBits;
  if FDataOffset <= 0 then Exit;

  // Determine palette count for 1/4/8 bpp.
  if FBitCount <= 8 then
  begin
    if ih.biClrUsed <> 0 then
      palCount := ih.biClrUsed
    else
      palCount := Int64(1) shl FBitCount;
    if palCount < 0 then Exit;
    if palCount > 256 then Exit;
    FColorsUsed := Integer(palCount);
  end
  else
  begin
    FColorsUsed := 0;
  end;

  // Read variable header size, palette and masks.
  hdrSize := ih.biSize;
  if hdrSize < SizeOf(TBmpInfoHeader) then hdrSize := SizeOf(TBmpInfoHeader);

  paletteOffset := SizeOf(TBmpFileHeader) + hdrSize;
  if (FBitCount <= 8) and (FColorsUsed > 0) then
  begin
    SetLength(FPaletteBGRA, FColorsUsed);
    if not FMapping.EnsureRange(paletteOffset, SizeUInt(Int64(FColorsUsed) * SizeOf(TRGBQuad))) then Exit;
    for i := 0 to FColorsUsed - 1 do
    begin
      p := FMapping.PtrAt(paletteOffset + Int64(i) * SizeOf(TRGBQuad));
      if p = nil then Exit;
      Move(p^, q, SizeOf(q));
      // store as BGRA (little-endian LongWord: B at lowest byte)
      FPaletteBGRA[i] := LongWord(q.b) or (LongWord(q.g) shl 8) or (LongWord(q.r) shl 16) or (LongWord($FF) shl 24);
    end;
  end
  else
  begin
    SetLength(FPaletteBGRA, 0);
  end;

  FMaskR := 0;
  FMaskG := 0;
  FMaskB := 0;
  FMaskA := 0;
  FHasAlphaMask := False;

  if (FBitCount = 32) and (FCompression = 3) then
  begin
    // For BI_BITFIELDS, masks follow immediately after the DIB header (3 masks for v3, 4 for v4/v5).
    masksOffset := SizeOf(TBmpFileHeader) + hdrSize;
    if not FMapping.EnsureRange(masksOffset, SizeUInt(3 * SizeOf(LongWord))) then Exit;
    p := FMapping.PtrAt(masksOffset);
    if p = nil then Exit;
    Move(p^, mr, SizeOf(LongWord)); Inc(p, SizeOf(LongWord));
    Move(p^, mg, SizeOf(LongWord)); Inc(p, SizeOf(LongWord));
    Move(p^, mb, SizeOf(LongWord));

    ma := 0;
    // If header is V4+ (>=108), alpha mask exists.
    if hdrSize >= 108 then
    begin
      if not FMapping.EnsureRange(masksOffset + 3 * SizeOf(LongWord), SizeUInt(SizeOf(LongWord))) then Exit;
      p := FMapping.PtrAt(masksOffset + 3 * SizeOf(LongWord));
      if p = nil then Exit;
      Move(p^, ma, SizeOf(LongWord));
    end;

    FMaskR := mr;
    FMaskG := mg;
    FMaskB := mb;
    FMaskA := ma;
    FHasAlphaMask := (ma <> 0);
  end;

  FIsOpen := True;

  // Select decoder once.
  case FBitCount of
    24: FGetPixelBGRA := @Self.GetPixelBGRA;
    32: FGetPixelBGRA := @Self.GetPixelBGRA;
    8:  FGetPixelBGRA := @Self.GetPixelBGRA;
    4:  FGetPixelBGRA := @Self.GetPixelBGRA;
    1:  FGetPixelBGRA := @Self.GetPixelBGRA;
  else
    FGetPixelBGRA := nil;
  end;

  Result := True;
end;

procedure TBmpMmapSource24.Close;
begin
  FIsOpen := False;
  FWidth := 0;
  FHeight := 0;
  FStride := 0;
  FDataOffset := 0;
  FTopDown := False;

  FBitCount := 0;
  FCompression := 0;
  FColorsUsed := 0;
  SetLength(FPaletteBGRA, 0);
  FMaskR := 0;
  FMaskG := 0;
  FMaskB := 0;
  FMaskA := 0;
  FHasAlphaMask := False;
  FGetPixelBGRA := nil;

  FTransparentEnabled := False;
  FTransparentIndex := -1;
  FTransparentRGB := 0;

  InvalidateOverviews;
  if FOverview4 <> nil then
  begin
    FreeMem(FOverview4);
    FOverview4 := nil;
  end;
  if FOverview8 <> nil then
  begin
    FreeMem(FOverview8);
    FOverview8 := nil;
  end;
  if FOverview16 <> nil then
  begin
    FreeMem(FOverview16);
    FOverview16 := nil;
  end;
  FOverview4W := 0;
  FOverview4H := 0;
  FOverview8W := 0;
  FOverview8H := 0;
  FOverview16W := 0;
  FOverview16H := 0;

  if FMapping <> nil then
    FMapping.Close;
end;

function TBmpMmapSource24.ScanlinePtr(Y: Integer): PByte;
var
  fileY: Int64;
  fileOffset: Int64;
begin
  Result := nil;
  if not FIsOpen then Exit;
  if (Y < 0) or (Y >= FHeight) then Exit;

  if FTopDown then
    fileY := Y
  else
    fileY := Int64(FHeight - 1 - Y);

  fileOffset := FDataOffset + fileY * Int64(FStride);

  if not FMapping.EnsureRange(fileOffset, SizeUInt(FStride)) then Exit;
  Result := FMapping.PtrAt(fileOffset);
end;

function TBmpMmapSource24.GetPixelBGRA(X, Y: Integer; out ColorBGRA: LongWord): Boolean;
var
  srcLine: PByte;
  b: Byte;
  idx: Integer;
  rgb: LongWord;
  bit: Integer;
begin
  Result := False;
  ColorBGRA := 0;
  if not FIsOpen then Exit;
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then Exit;

  srcLine := ScanlinePtr(Y);
  if srcLine = nil then Exit;

  case FBitCount of
    24:
      begin
        srcLine := srcLine + X * 3;
        // B,G,R
        ColorBGRA := LongWord(srcLine^) or (LongWord((srcLine + 1)^) shl 8) or (LongWord((srcLine + 2)^) shl 16) or (LongWord($FF) shl 24);
        if FTransparentEnabled then
        begin
          rgb := ColorBGRA and $00FFFFFF;
          if rgb = (FTransparentRGB and $00FFFFFF) then Exit(False);
        end;
        Result := True;
      end;
    32:
      begin
        srcLine := srcLine + X * 4;
        // Default BMP 32bpp in practice is B,G,R,X. Treat alpha as opaque unless we have an alpha mask.
        if FHasAlphaMask then
          ColorBGRA := LongWord(srcLine^) or (LongWord((srcLine + 1)^) shl 8) or (LongWord((srcLine + 2)^) shl 16) or (LongWord((srcLine + 3)^) shl 24)
        else
          ColorBGRA := LongWord(srcLine^) or (LongWord((srcLine + 1)^) shl 8) or (LongWord((srcLine + 2)^) shl 16) or (LongWord($FF) shl 24);
        if FTransparentEnabled then
        begin
          rgb := ColorBGRA and $00FFFFFF;
          if rgb = (FTransparentRGB and $00FFFFFF) then Exit(False);
        end;
        Result := True;
      end;
    8:
      begin
        if Length(FPaletteBGRA) = 0 then Exit;
        idx := PByte(srcLine + X)^;
        if FTransparentEnabled and (FTransparentIndex >= 0) and (idx = FTransparentIndex) then Exit(False);
        if (idx < 0) or (idx >= Length(FPaletteBGRA)) then Exit;
        ColorBGRA := FPaletteBGRA[idx];
        Result := True;
      end;
    4:
      begin
        if Length(FPaletteBGRA) = 0 then Exit;
        b := PByte(srcLine + (X shr 1))^;
        if (X and 1) = 0 then
          idx := (b shr 4) and $F
        else
          idx := b and $F;
        if FTransparentEnabled and (FTransparentIndex >= 0) and (idx = FTransparentIndex) then Exit(False);
        if (idx < 0) or (idx >= Length(FPaletteBGRA)) then Exit;
        ColorBGRA := FPaletteBGRA[idx];
        Result := True;
      end;
    1:
      begin
        if Length(FPaletteBGRA) = 0 then Exit;
        b := PByte(srcLine + (X shr 3))^;
        bit := 7 - (X and 7);
        idx := (b shr bit) and 1;
        if FTransparentEnabled and (FTransparentIndex >= 0) and (idx = FTransparentIndex) then Exit(False);
        ColorBGRA := FPaletteBGRA[idx];
        Result := True;
      end;
  else
    Exit;
  end;
end;

function TBmpMmapSource24.PaletteCount: Integer;
begin
  Result := Length(FPaletteBGRA);
end;

function TBmpMmapSource24.GetPaletteEntryBGRA(Index: Integer; out ColorBGRA: LongWord): Boolean;
begin
  Result := False;
  ColorBGRA := 0;
  if (Index < 0) or (Index >= Length(FPaletteBGRA)) then Exit;
  ColorBGRA := FPaletteBGRA[Index];
  Result := True;
end;

function TBmpMmapSource24.SetPaletteEntryBGRA(Index: Integer; ColorBGRA: LongWord): Boolean;
begin
  Result := False;
  if (Index < 0) or (Index >= Length(FPaletteBGRA)) then Exit;
  FPaletteBGRA[Index] := ColorBGRA;
  InvalidateOverviews;
  Result := True;
end;

function TBmpMmapSource24.EnsureOverview4: Boolean;
begin
  if not FIsOpen then Exit(False);
  if FOverview4Valid then Exit(True);
  Result := BuildOverview(4, FOverview4, FOverview4W, FOverview4H);
  FOverview4Valid := Result;
end;

function TBmpMmapSource24.HasOverview4: Boolean;
begin
  Result := FOverview4Valid and (FOverview4 <> nil);
end;

function TBmpMmapSource24.Overview4Width: Integer;
begin
  if not HasOverview4 then Exit(0);
  Result := FOverview4W;
end;

function TBmpMmapSource24.Overview4Height: Integer;
begin
  if not HasOverview4 then Exit(0);
  Result := FOverview4H;
end;

function TBmpMmapSource24.GetOverview4PixelBGRA(X, Y: Integer; out ColorBGRA: LongWord): Boolean;
begin
  Result := False;
  ColorBGRA := 0;
  if not HasOverview4 then Exit;
  if (X < 0) or (X >= FOverview4W) or (Y < 0) or (Y >= FOverview4H) then Exit;
  ColorBGRA := PCardinal(FOverview4)[Y * FOverview4W + X];
  if (ColorBGRA shr 24) = 0 then Exit(False);
  Result := True;
end;

function TBmpMmapSource24.EnsureOverview8: Boolean;
begin
  if not FIsOpen then Exit(False);
  if FOverview8Valid then Exit(True);
  Result := BuildOverview(8, FOverview8, FOverview8W, FOverview8H);
  FOverview8Valid := Result;
end;

function TBmpMmapSource24.HasOverview8: Boolean;
begin
  Result := FOverview8Valid and (FOverview8 <> nil);
end;

function TBmpMmapSource24.Overview8Width: Integer;
begin
  if not HasOverview8 then Exit(0);
  Result := FOverview8W;
end;

function TBmpMmapSource24.Overview8Height: Integer;
begin
  if not HasOverview8 then Exit(0);
  Result := FOverview8H;
end;

function TBmpMmapSource24.GetOverview8PixelBGRA(X, Y: Integer; out ColorBGRA: LongWord): Boolean;
begin
  Result := False;
  ColorBGRA := 0;
  if not HasOverview8 then Exit;
  if (X < 0) or (X >= FOverview8W) or (Y < 0) or (Y >= FOverview8H) then Exit;
  ColorBGRA := PCardinal(FOverview8)[Y * FOverview8W + X];
  if (ColorBGRA shr 24) = 0 then Exit(False);
  Result := True;
end;

function TBmpMmapSource24.EnsureOverview16: Boolean;
begin
  if not FIsOpen then Exit(False);
  if FOverview16Valid then Exit(True);
  Result := BuildOverview(16, FOverview16, FOverview16W, FOverview16H);
  FOverview16Valid := Result;
end;

function TBmpMmapSource24.HasOverview16: Boolean;
begin
  Result := FOverview16Valid and (FOverview16 <> nil);
end;

function TBmpMmapSource24.Overview16Width: Integer;
begin
  if not HasOverview16 then Exit(0);
  Result := FOverview16W;
end;

function TBmpMmapSource24.Overview16Height: Integer;
begin
  if not HasOverview16 then Exit(0);
  Result := FOverview16H;
end;

function TBmpMmapSource24.GetOverview16PixelBGRA(X, Y: Integer; out ColorBGRA: LongWord): Boolean;
begin
  Result := False;
  ColorBGRA := 0;
  if not HasOverview16 then Exit;
  if (X < 0) or (X >= FOverview16W) or (Y < 0) or (Y >= FOverview16H) then Exit;
  ColorBGRA := PCardinal(FOverview16)[Y * FOverview16W + X];
  if (ColorBGRA shr 24) = 0 then Exit(False);
  Result := True;
end;

function TBmpMmapSource24.BuildOverview(Factor: Integer; var ABuf: PCardinal; out OutW, OutH: Integer): Boolean;
var
  ow, oh: Integer;
  ox, oy: Integer;
  x0, y0: Integer;
  x1, y1: Integer;
  x, y: Integer;
  c: LongWord;
  sumB, sumG, sumR: Int64;
  cnt: Int64;
  b, g, r: Byte;
  dst: PCardinal;
  dstIdx: NativeInt;
  pixCount: NativeInt;
begin
  Result := False;
  if not FIsOpen then Exit;

  if Factor <= 0 then Exit;

  ow := (FWidth + Factor - 1) div Factor;
  oh := (FHeight + Factor - 1) div Factor;
  if (ow <= 0) or (oh <= 0) then Exit;

  pixCount := NativeInt(ow) * NativeInt(oh);
  if pixCount <= 0 then Exit;

  if ABuf <> nil then
  begin
    FreeMem(ABuf);
    ABuf := nil;
  end;
  GetMem(ABuf, SizeUInt(pixCount) * SizeUInt(SizeOf(Cardinal)));
  if ABuf = nil then Exit;

  dst := ABuf;
  dstIdx := 0;
  for oy := 0 to oh - 1 do
  begin
    y0 := oy * Factor;
    y1 := y0 + Factor;
    if y1 > FHeight then y1 := FHeight;

    for ox := 0 to ow - 1 do
    begin
      x0 := ox * Factor;
      x1 := x0 + Factor;
      if x1 > FWidth then x1 := FWidth;

      sumB := 0;
      sumG := 0;
      sumR := 0;
      cnt := 0;

      for y := y0 to y1 - 1 do
        for x := x0 to x1 - 1 do
          if GetPixelBGRA(x, y, c) then
          begin
            Inc(cnt);
            sumB := sumB + Byte(c);
            sumG := sumG + Byte(c shr 8);
            sumR := sumR + Byte(c shr 16);
          end;

      if cnt > 0 then
      begin
        b := Byte(sumB div cnt);
        g := Byte(sumG div cnt);
        r := Byte(sumR div cnt);
        dst[dstIdx] := Cardinal(b) or (Cardinal(g) shl 8) or (Cardinal(r) shl 16) or (Cardinal(255) shl 24);
      end
      else
      begin
        dst[dstIdx] := 0;
      end;

      Inc(dstIdx);
    end;
  end;

  OutW := ow;
  OutH := oh;
  Result := True;
end;

end.
