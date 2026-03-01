unit uLasFileContext;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, IniFiles, Math, ogcLas, uLasPointCloudTiles;

type
 TPoslPoint = packed record
  X: Double;
  Y: Double;
  Z: Double;
 end;

 TLasFileContext = class
 private
  FLas: TogsLas;
  FTiles: TLasPointCloudTiles;
  FFileName: String;
  FStateFileName: String;
  FDynaLodTileSize: Double;
  FColorMode: TLasPointColorMode;
  FVisible: Boolean;
  FPoslPoints: array of TPoslPoint;
  function GetIsOpen: Boolean;
  procedure SetColorMode(AValue: TLasPointColorMode);
  procedure ClearPosl;
  procedure LoadPosl;
 public
  constructor Create;
  destructor Destroy; override;

  function Open(const AFileName: String): Boolean;
  procedure Close;
  procedure BuildTiles(const AMaxPointsTotal: Int64 = 0);

  function VirtualTileSizeMeters: Double;

  procedure LoadState;
  procedure SaveState;

  property Las: TogsLas read FLas;
  property Tiles: TLasPointCloudTiles read FTiles;
  property FileName: String read FFileName;
  property StateFileName: String read FStateFileName;
  property IsOpen: Boolean read GetIsOpen;

  property DynaLodTileSize: Double read FDynaLodTileSize write FDynaLodTileSize;
  property ColorMode: TLasPointColorMode read FColorMode write SetColorMode;
  property Visible: Boolean read FVisible write FVisible;

  function PoslPointCount: Integer;
  function GetPoslPoint(Index: Integer; out AX, AY, AZ: Double): Boolean;
 end;

implementation

constructor TLasFileContext.Create;
begin
 inherited Create;
 FLas := TogsLas.Create(nil);
 FTiles := TLasPointCloudTiles.Create;
 FFileName := '';
 FStateFileName := '';
 FDynaLodTileSize := 0;
 FColorMode := lpcmRGB;
 FVisible := True;
 SetLength(FPoslPoints, 0);
end;

destructor TLasFileContext.Destroy;
begin
 Close;
 FreeAndNil(FTiles);
 FreeAndNil(FLas);
 inherited Destroy;
end;

function TLasFileContext.GetIsOpen: Boolean;
begin
 Result := (FLas <> nil) and (FLas.Source <> nil) and FLas.Source.IsOpen;
end;

procedure TLasFileContext.SetColorMode(AValue: TLasPointColorMode);
begin
 FColorMode := AValue;
 if FTiles <> nil then
  FTiles.ColorMode := AValue;
end;

function TLasFileContext.Open(const AFileName: String): Boolean;
begin
 Result := False;
 Close;
 if (AFileName = '') or (not FileExists(AFileName)) then Exit;
 if (FLas = nil) then Exit;

 if not FLas.OpenLasFile(AFileName, 0, 0) then Exit;

 FFileName := AFileName;
 FStateFileName := ChangeFileExt(AFileName, '.lxt');

 if FTiles <> nil then
  FTiles.ColorMode := FColorMode;

 Result := True;
end;

procedure TLasFileContext.Close;
begin
 if FLas <> nil then
  FLas.CloseLas;
 FFileName := '';
 FStateFileName := '';
 ClearPosl;
end;

procedure TLasFileContext.ClearPosl;
begin
 SetLength(FPoslPoints, 0);
end;

procedure TLasFileContext.LoadPosl;
var
 dirPath: String;
 fn2, fn3, fn: String;
 sr: TSearchRec;
 sl: TStringList;
 i: Integer;
 line: String;
 parts: TStringList;
 x, y, z: Double;
 fsDot: TFormatSettings;
 fsComma: TFormatSettings;
 p: TPoslPoint;
begin
 ClearPosl;
 if FFileName = '' then Exit;

 dirPath := IncludeTrailingPathDelimiter(ExtractFileDir(FFileName));
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
 if fn = '' then Exit;

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
   SetLength(FPoslPoints, Length(FPoslPoints) + 1);
   FPoslPoints[High(FPoslPoints)] := p;
  end;
 finally
  parts.Free;
  sl.Free;
 end;
end;

function TLasFileContext.PoslPointCount: Integer;
begin
 Result := Length(FPoslPoints);
end;

function TLasFileContext.GetPoslPoint(Index: Integer; out AX, AY, AZ: Double): Boolean;
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

procedure TLasFileContext.BuildTiles(const AMaxPointsTotal: Int64);
begin
 if (FTiles = nil) or (not IsOpen) then Exit;
 FTiles.BuildFromLas(FLas, AMaxPointsTotal);
end;

function TLasFileContext.VirtualTileSizeMeters: Double;
var
 dx, dy: Double;
begin
 Result := 0;
 if FTiles = nil then Exit;
 dx := 0;
 dy := 0;
 FTiles.GetGridTileStep(dx, dy);
 Result := Hypot(dx, dy);
end;

procedure TLasFileContext.LoadState;
var
 ini: TIniFile;
 cm: Integer;
begin
 if (FStateFileName = '') or (not FileExists(FStateFileName)) then Exit;
 try
  ini := TIniFile.Create(FStateFileName);
  try
   FDynaLodTileSize := ini.ReadFloat('Render', 'DynaLodTileSize', FDynaLodTileSize);
   cm := ini.ReadInteger('Render', 'ColorMode', Ord(FColorMode));
   if (cm >= Ord(Low(TLasPointColorMode))) and (cm <= Ord(High(TLasPointColorMode))) then
    ColorMode := TLasPointColorMode(cm);
  finally
   ini.Free;
  end;
 except
 end;
end;

procedure TLasFileContext.SaveState;
var
 ini: TIniFile;
begin
 if FStateFileName = '' then Exit;
 try
  ini := TIniFile.Create(FStateFileName);
  try
   ini.WriteFloat('Render', 'DynaLodTileSize', FDynaLodTileSize);
   ini.WriteInteger('Render', 'ColorMode', Ord(FColorMode));
  finally
   ini.Free;
  end;
 except
 end;
end;

end.
