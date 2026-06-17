unit uLasMmapSource24;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils,
 uPartialFileMapping;

type
 TLASHeader = packed record
  Signature: array[0..3] of AnsiChar;
  FileSourceID: Word;
  GlobalEncoding: Word;
  ProjectID1: LongWord;
  ProjectID2: Word;
  ProjectID3: Word;
  ProjectID4: array[0..7] of Byte;
  VersionMajor: Byte;
  VersionMinor: Byte;
  SystemIdentifier: array[0..31] of AnsiChar;
  GeneratingSoftware: array[0..31] of AnsiChar;
  FileCreationDayOfYear: Word;
  FileCreationYear: Word;
  HeaderSize: Word;
  OffsetToPointData: LongWord;
  NumberOfVLR: LongWord;
  PointDataRecordFormat: Byte;
  PointDataRecordLength: Word;
  LegacyNumberOfPointRecords: LongWord;
  LegacyNumberOfPointsByReturn: array[0..4] of LongWord;
  ScaleX: Double;
  ScaleY: Double;
  ScaleZ: Double;
  OffsetX: Double;
  OffsetY: Double;
  OffsetZ: Double;
  MaxX: Double;
  MinX: Double;
  MaxY: Double;
  MinY: Double;
  MaxZ: Double;
  MinZ: Double;
 end;

 TLASPointRecordFormat0 = packed record
  X: LongInt;
  Y: LongInt;
  Z: LongInt;
  Intensity: Word;
  Flags: Byte;
  Classification: Byte;
  ScanAngleRank: ShortInt;
  UserData: Byte;
  PointSourceID: Word;
 end;

 TLASPointRecordFormat2 = packed record
  X: LongInt;
  Y: LongInt;
  Z: LongInt;
  Intensity: Word;
  Flags: Byte;
  Classification: Byte;
  ScanAngleRank: ShortInt;
  UserData: Byte;
  PointSourceID: Word;
  Red: Word;
  Green: Word;
  Blue: Word;
 end;

 TLasMmapSource24 = class(TComponent)
 private
  FMapping: TPartialFileMapping;
  FOwnsMapping: Boolean;
  FFileName: string;
  FIsOpen: Boolean;
  FHeader: TLASHeader;
  FPointCount: Int64;
  procedure SetFileName(const AValue: string);
  procedure EnsureMapping;
  function HasSignature: Boolean;
  function PointRecordOffset(Index: Int64): Int64;
  function ReadU64At(AOffset: Int64; out AValue: QWord): Boolean;
 public
  constructor Create(AOwner: TComponent); override;
  destructor Destroy; override;
  function Open: Boolean;
  procedure Close;
  function GetPointXYZ(Index: Int64; out X, Y, Z: Double): Boolean;
  function GetPointXYZRGB(Index: Int64; out X, Y, Z: Double; out R, G, B: Word): Boolean;
  function GetPointXYZRGBAttrs(Index: Int64; out X, Y, Z: Double;
                             out Intensity: Word; out Flags: Byte; out Classification: Byte;
                             out ScanAngleRank: ShortInt; out UserData: Byte; out PointSourceID: Word;
                             out R, G, B: Word): Boolean;
  property Mapping: TPartialFileMapping read FMapping;
  property IsOpen: Boolean read FIsOpen;
  property Header: TLASHeader read FHeader;
  property PointCount: Int64 read FPointCount;
  property FileName: string read FFileName write SetFileName;
 end;

implementation

constructor TLasMmapSource24.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 FMapping := nil;
 FOwnsMapping := False;
 FFileName := '';
 FIsOpen := False;
 FillChar(FHeader, SizeOf(FHeader), 0);
 FPointCount := 0;
end;

destructor TLasMmapSource24.Destroy;
begin
 Close;
 if FOwnsMapping then
  FreeAndNil(FMapping);
 inherited Destroy;
end;

procedure TLasMmapSource24.SetFileName(const AValue: string);
begin
 if FFileName = AValue then Exit;
 if FIsOpen then
  raise Exception.Create('Cannot change FileName while open');
 FFileName := AValue;
end;

procedure TLasMmapSource24.EnsureMapping;
begin
 if FMapping <> nil then Exit;
 FMapping := TPartialFileMapping.Create(nil);
 FMapping.ReadOnly := True;
 FMapping.MappingGranularity := 65536;
 FMapping.WindowSize := 64 * 1024 * 1024;
 FOwnsMapping := True;
end;

function TLasMmapSource24.HasSignature: Boolean;
begin
 Result := (FHeader.Signature[0] = 'L') and (FHeader.Signature[1] = 'A') and
           (FHeader.Signature[2] = 'S') and (FHeader.Signature[3] = 'F');
end;

function TLasMmapSource24.PointRecordOffset(Index: Int64): Int64;
begin
 Result := Int64(FHeader.OffsetToPointData) + Index * Int64(FHeader.PointDataRecordLength);
end;

function TLasMmapSource24.ReadU64At(AOffset: Int64; out AValue: QWord): Boolean;
var
 p: PByte;
begin
 Result := False;
 AValue := 0;
 if (FMapping = nil) or (AOffset < 0) then Exit;
 if not FMapping.EnsureRange(AOffset, SizeUInt(SizeOf(AValue))) then Exit;
 p := FMapping.PtrAt(AOffset);
 if p = nil then Exit;
 Move(p^, AValue, SizeOf(AValue));
 Result := True;
end;

function TLasMmapSource24.Open: Boolean;
var
 p: PByte;
 need: SizeUInt;
 hdrSize: SizeUInt;
 extCount: QWord;
begin
 Result := False;
 if FIsOpen then Exit(True);
 if FFileName = '' then Exit;
 EnsureMapping;
 if FMapping = nil then Exit;
 FMapping.FileName := FFileName;
 if not FMapping.Open then Exit;

 hdrSize := SizeUInt(SizeOf(TLASHeader));
 need := hdrSize;
 if not FMapping.EnsureRange(0, need) then Exit;
 p := FMapping.PtrAt(0);
 if p = nil then Exit;
 Move(p^, FHeader, SizeOf(FHeader));

 if not HasSignature then Exit;
 if (FHeader.HeaderSize < 227) then Exit;
 if (FHeader.PointDataRecordLength = 0) then Exit;

 FPointCount := Int64(FHeader.LegacyNumberOfPointRecords);
 if (FHeader.VersionMajor = 1) and (FHeader.VersionMinor = 4) then
 begin
  if (FPointCount = 0) and ReadU64At(247, extCount) then
   FPointCount := Int64(extCount);
 end;

 if FPointCount < 0 then Exit;
 if Int64(FHeader.OffsetToPointData) < 0 then Exit;
 if (Int64(FHeader.OffsetToPointData) + FPointCount * Int64(FHeader.PointDataRecordLength) > FMapping.FileSize) then
  Exit;

 FIsOpen := True;
 Result := True;
end;

procedure TLasMmapSource24.Close;
begin
 FIsOpen := False;
 FillChar(FHeader, SizeOf(FHeader), 0);
 FPointCount := 0;
 if FMapping <> nil then
  FMapping.Close;
end;

function TLasMmapSource24.GetPointXYZ(Index: Int64; out X, Y, Z: Double): Boolean;
var
 off: Int64;
 p: PByte;
 recX, recY, recZ: LongInt;
begin
 Result := False;
 X := 0;
 Y := 0;
 Z := 0;
 if not FIsOpen then Exit;
 if (Index < 0) or (Index >= FPointCount) then Exit;
 if Int64(FHeader.PointDataRecordLength) < 12 then Exit;
 off := PointRecordOffset(Index);
 if not FMapping.EnsureRange(off, SizeUInt(12)) then Exit;
 p := FMapping.PtrAt(off);
 if p = nil then Exit;
 Move(p^, recX, SizeOf(recX)); Inc(p, SizeOf(recX));
 Move(p^, recY, SizeOf(recY)); Inc(p, SizeOf(recY));
 Move(p^, recZ, SizeOf(recZ));
 X := recX * FHeader.ScaleX + FHeader.OffsetX;
 Y := recY * FHeader.ScaleY + FHeader.OffsetY;
 Z := recZ * FHeader.ScaleZ + FHeader.OffsetZ;
 Result := True;
end;

function TLasMmapSource24.GetPointXYZRGB(Index: Int64; out X, Y, Z: Double; out R, G, B: Word): Boolean;
var
 off: Int64;
 p: PByte;
 pr: TLASPointRecordFormat2;
 pr0: TLASPointRecordFormat0;
 recX, recY, recZ: LongInt;
 gpsTime: Double;
 rgbOff: Int64;
begin
 Result := False;
 X := 0;
 Y := 0;
 Z := 0;
 R := 0;
 G := 0;
 B := 0;
 if not FIsOpen then Exit;
 if (Index < 0) or (Index >= FPointCount) then Exit;
 if Int64(FHeader.PointDataRecordLength) < 12 then Exit;
 if (FHeader.PointDataRecordFormat = 0) or (FHeader.PointDataRecordFormat = 1) then
 begin
  if (FHeader.PointDataRecordLength < SizeOf(TLASPointRecordFormat0)) then Exit;
  off := PointRecordOffset(Index);
  if not FMapping.EnsureRange(off, SizeUInt(SizeOf(TLASPointRecordFormat0))) then Exit;
  p := FMapping.PtrAt(off);
  if p = nil then Exit;
  Move(p^, pr0, SizeOf(pr0));
  X := pr0.X * FHeader.ScaleX + FHeader.OffsetX;
  Y := pr0.Y * FHeader.ScaleY + FHeader.OffsetY;
  Z := pr0.Z * FHeader.ScaleZ + FHeader.OffsetZ;
  R := 0;
  G := 0;
  B := 0;
  Result := True;
  Exit;
 end;
 if (FHeader.PointDataRecordFormat = 2) then
 begin
  if (FHeader.PointDataRecordLength < SizeOf(TLASPointRecordFormat2)) then Exit;
  off := PointRecordOffset(Index);
  if not FMapping.EnsureRange(off, SizeUInt(SizeOf(TLASPointRecordFormat2))) then Exit;
  p := FMapping.PtrAt(off);
  if p = nil then Exit;
  Move(p^, pr, SizeOf(pr));
  X := pr.X * FHeader.ScaleX + FHeader.OffsetX;
  Y := pr.Y * FHeader.ScaleY + FHeader.OffsetY;
  Z := pr.Z * FHeader.ScaleZ + FHeader.OffsetZ;
  R := pr.Red;
  G := pr.Green;
  B := pr.Blue;
  Result := True;
  Exit;
 end;

 if (FHeader.PointDataRecordFormat = 3) then
 begin
  if (FHeader.PointDataRecordLength < 34) then Exit;
  off := PointRecordOffset(Index);
  if not FMapping.EnsureRange(off, 34) then Exit;
  p := FMapping.PtrAt(off);
  if p = nil then Exit;
  Move(p^, recX, SizeOf(recX)); Inc(p, SizeOf(recX));
  Move(p^, recY, SizeOf(recY)); Inc(p, SizeOf(recY));
  Move(p^, recZ, SizeOf(recZ)); Inc(p, SizeOf(recZ));
  Inc(p, 8);
  Move(p^, gpsTime, SizeOf(gpsTime)); Inc(p, SizeOf(gpsTime));
  Move(p^, R, SizeOf(R)); Inc(p, SizeOf(R));
  Move(p^, G, SizeOf(G)); Inc(p, SizeOf(G));
  Move(p^, B, SizeOf(B));
  X := recX * FHeader.ScaleX + FHeader.OffsetX;
  Y := recY * FHeader.ScaleY + FHeader.OffsetY;
  Z := recZ * FHeader.ScaleZ + FHeader.OffsetZ;
  Result := True;
  Exit;
 end;

 if (FHeader.PointDataRecordFormat = 7) then
 begin
  if (FHeader.PointDataRecordLength < 36) then Exit;
  off := PointRecordOffset(Index);
  if not FMapping.EnsureRange(off, SizeUInt(FHeader.PointDataRecordLength)) then Exit;
  p := FMapping.PtrAt(off);
  if p = nil then Exit;
  Move(p^, recX, SizeOf(recX)); Inc(p, SizeOf(recX));
  Move(p^, recY, SizeOf(recY)); Inc(p, SizeOf(recY));
  Move(p^, recZ, SizeOf(recZ));
  rgbOff := off + 30;
  if not FMapping.EnsureRange(rgbOff, 6) then Exit;
  p := FMapping.PtrAt(rgbOff);
  if p = nil then Exit;
  Move(p^, R, SizeOf(R)); Inc(p, SizeOf(R));
  Move(p^, G, SizeOf(G)); Inc(p, SizeOf(G));
  Move(p^, B, SizeOf(B));
  X := recX * FHeader.ScaleX + FHeader.OffsetX;
  Y := recY * FHeader.ScaleY + FHeader.OffsetY;
  Z := recZ * FHeader.ScaleZ + FHeader.OffsetZ;
  Result := True;
  Exit;
 end;
end;

function TLasMmapSource24.GetPointXYZRGBAttrs(Index: Int64; out X, Y, Z: Double;
                                             out Intensity: Word; out Flags: Byte; out Classification: Byte;
                                             out ScanAngleRank: ShortInt; out UserData: Byte; out PointSourceID: Word;
                                             out R, G, B: Word): Boolean;
var
 off: Int64;
 p: PByte;
 pr: TLASPointRecordFormat2;
 pr0: TLASPointRecordFormat0;
 recX, recY, recZ: LongInt;
 gpsTime: Double;
 flags2: Word;
 scanAngleS: SmallInt;
 rgbOff: Int64;
begin
 Result := False;
 X := 0;
 Y := 0;
 Z := 0;
 Intensity := 0;
 Flags := 0;
 Classification := 0;
 ScanAngleRank := 0;
 UserData := 0;
 PointSourceID := 0;
 R := 0;
 G := 0;
 B := 0;
 if not FIsOpen then Exit;
 if (Index < 0) or (Index >= FPointCount) then Exit;
 if Int64(FHeader.PointDataRecordLength) < 12 then Exit;

 if (FHeader.PointDataRecordFormat = 0) or (FHeader.PointDataRecordFormat = 1) then
 begin
  if (FHeader.PointDataRecordLength < SizeOf(TLASPointRecordFormat0)) then Exit;
  off := PointRecordOffset(Index);
  if not FMapping.EnsureRange(off, SizeUInt(SizeOf(TLASPointRecordFormat0))) then Exit;
  p := FMapping.PtrAt(off);
  if p = nil then Exit;
  Move(p^, pr0, SizeOf(pr0));
  X := pr0.X * FHeader.ScaleX + FHeader.OffsetX;
  Y := pr0.Y * FHeader.ScaleY + FHeader.OffsetY;
  Z := pr0.Z * FHeader.ScaleZ + FHeader.OffsetZ;
  Intensity := pr0.Intensity;
  Flags := pr0.Flags;
  Classification := pr0.Classification;
  ScanAngleRank := pr0.ScanAngleRank;
  UserData := pr0.UserData;
  PointSourceID := pr0.PointSourceID;
  R := 0;
  G := 0;
  B := 0;
  Result := True;
  Exit;
 end;

 if (FHeader.PointDataRecordFormat = 2) then
 begin
  if (FHeader.PointDataRecordLength < SizeOf(TLASPointRecordFormat2)) then Exit;
  off := PointRecordOffset(Index);
  if not FMapping.EnsureRange(off, SizeUInt(SizeOf(TLASPointRecordFormat2))) then Exit;
  p := FMapping.PtrAt(off);
  if p = nil then Exit;
  Move(p^, pr, SizeOf(pr));
  X := pr.X * FHeader.ScaleX + FHeader.OffsetX;
  Y := pr.Y * FHeader.ScaleY + FHeader.OffsetY;
  Z := pr.Z * FHeader.ScaleZ + FHeader.OffsetZ;
  Intensity := pr.Intensity;
  Flags := pr.Flags;
  Classification := pr.Classification;
  ScanAngleRank := pr.ScanAngleRank;
  UserData := pr.UserData;
  PointSourceID := pr.PointSourceID;
  R := pr.Red;
  G := pr.Green;
  B := pr.Blue;
  Result := True;
  Exit;
 end;

 if (FHeader.PointDataRecordFormat = 3) then
 begin
  if (FHeader.PointDataRecordLength < 34) then Exit;
  off := PointRecordOffset(Index);
  if not FMapping.EnsureRange(off, 34) then Exit;
  p := FMapping.PtrAt(off);
  if p = nil then Exit;
  Move(p^, recX, SizeOf(recX)); Inc(p, SizeOf(recX));
  Move(p^, recY, SizeOf(recY)); Inc(p, SizeOf(recY));
  Move(p^, recZ, SizeOf(recZ)); Inc(p, SizeOf(recZ));
  Move(p^, Intensity, SizeOf(Intensity)); Inc(p, SizeOf(Intensity));
  Move(p^, Flags, SizeOf(Flags)); Inc(p, SizeOf(Flags));
  Move(p^, Classification, SizeOf(Classification)); Inc(p, SizeOf(Classification));
  Move(p^, ScanAngleRank, SizeOf(ScanAngleRank)); Inc(p, SizeOf(ScanAngleRank));
  Move(p^, UserData, SizeOf(UserData)); Inc(p, SizeOf(UserData));
  Move(p^, PointSourceID, SizeOf(PointSourceID)); Inc(p, SizeOf(PointSourceID));
  Move(p^, gpsTime, SizeOf(gpsTime)); Inc(p, SizeOf(gpsTime));
  Move(p^, R, SizeOf(R)); Inc(p, SizeOf(R));
  Move(p^, G, SizeOf(G)); Inc(p, SizeOf(G));
  Move(p^, B, SizeOf(B));
  X := recX * FHeader.ScaleX + FHeader.OffsetX;
  Y := recY * FHeader.ScaleY + FHeader.OffsetY;
  Z := recZ * FHeader.ScaleZ + FHeader.OffsetZ;
  Result := True;
  Exit;
 end;

 if (FHeader.PointDataRecordFormat = 7) then
 begin
  if (FHeader.PointDataRecordLength < 36) then Exit;
  off := PointRecordOffset(Index);
  if not FMapping.EnsureRange(off, SizeUInt(FHeader.PointDataRecordLength)) then Exit;
  p := FMapping.PtrAt(off);
  if p = nil then Exit;
  Move(p^, recX, SizeOf(recX)); Inc(p, SizeOf(recX));
  Move(p^, recY, SizeOf(recY)); Inc(p, SizeOf(recY));
  Move(p^, recZ, SizeOf(recZ));

  X := recX * FHeader.ScaleX + FHeader.OffsetX;
  Y := recY * FHeader.ScaleY + FHeader.OffsetY;
  Z := recZ * FHeader.ScaleZ + FHeader.OffsetZ;

  if not FMapping.EnsureRange(off + 12, 18) then Exit;
  p := FMapping.PtrAt(off + 12);
  if p = nil then Exit;
  Move(p^, Intensity, SizeOf(Intensity)); Inc(p, SizeOf(Intensity));
  Move(p^, flags2, SizeOf(flags2)); Inc(p, SizeOf(flags2));
  Flags := Byte(flags2 and $FF);
  Move(p^, Classification, SizeOf(Classification)); Inc(p, SizeOf(Classification));
  Move(p^, UserData, SizeOf(UserData)); Inc(p, SizeOf(UserData));
  Move(p^, scanAngleS, SizeOf(scanAngleS)); Inc(p, SizeOf(scanAngleS));
  if scanAngleS < -128 then ScanAngleRank := -128
  else if scanAngleS > 127 then ScanAngleRank := 127
  else ScanAngleRank := ShortInt(scanAngleS);
  Move(p^, PointSourceID, SizeOf(PointSourceID));

  if not FMapping.EnsureRange(off + 22, SizeUInt(SizeOf(gpsTime))) then Exit;
  p := FMapping.PtrAt(off + 22);
  if p = nil then Exit;
  Move(p^, gpsTime, SizeOf(gpsTime));

  rgbOff := off + 30;
  if not FMapping.EnsureRange(rgbOff, 6) then Exit;
  p := FMapping.PtrAt(rgbOff);
  if p = nil then Exit;
  Move(p^, R, SizeOf(R)); Inc(p, SizeOf(R));
  Move(p^, G, SizeOf(G)); Inc(p, SizeOf(G));
  Move(p^, B, SizeOf(B));

  Result := True;
  Exit;
 end;
end;

end.
