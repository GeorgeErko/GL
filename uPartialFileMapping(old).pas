unit uPartialFileMapping;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
  {$IFDEF MSWINDOWS}
  , Windows
  {$ELSE}
  , BaseUnix, UnixType
  {$ENDIF}
  ;

type
  TMappedSpan = record
    BaseOffset: Int64;
    MapSize: SizeUInt;
    Delta: SizeUInt;
    BasePtr: PByte;
  end;

  TPartialFileMapping = class(TComponent)
  private
    FFileName: string;
    FMappingGranularity: Int64;
    FWindowSize: SizeUInt;
    FReadOnly: Boolean;

    FFileSize: Int64;

    FSpan: TMappedSpan;

    {$IFDEF MSWINDOWS}
    FFileHandle: THandle;
    FMapHandle: THandle;
    {$ELSE}
    FFD: cint;
    {$ENDIF}

    procedure SetFileName(const AValue: string);
    procedure SetMappingGranularity(const AValue: Int64);
    procedure SetWindowSize(const AValue: SizeUInt);

    procedure UnmapInternal;
    function MapInternal(AlignedOffset: Int64; MapSize: SizeUInt): Boolean;

    function AlignDown(Value, Align: Int64): Int64;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Open: Boolean;
    procedure Close;

    function EnsureRange(FileOffset: Int64; NeedSize: SizeUInt): Boolean;
    function PtrAt(FileOffset: Int64): PByte;

    property Span: TMappedSpan read FSpan;
    property FileSize: Int64 read FFileSize;
  published
    property FileName: string read FFileName write SetFileName;
    property MappingGranularity: Int64 read FMappingGranularity write SetMappingGranularity default 65536;
    property WindowSize: SizeUInt read FWindowSize write SetWindowSize;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default True;
  end;

implementation

constructor TPartialFileMapping.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMappingGranularity := 65536;
  FWindowSize := 64 * 1024 * 1024;
  FReadOnly := True;

  FFileSize := -1;

  FSpan.BaseOffset := -1;
  FSpan.MapSize := 0;
  FSpan.Delta := 0;
  FSpan.BasePtr := nil;

  {$IFDEF MSWINDOWS}
  FFileHandle := INVALID_HANDLE_VALUE;
  FMapHandle := 0;
  {$ELSE}
  FFD := -1;
  {$ENDIF}
end;

destructor TPartialFileMapping.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TPartialFileMapping.SetFileName(const AValue: string);
begin
  if FFileName = AValue then Exit;
  if (FSpan.BasePtr <> nil) then
    raise Exception.Create('Cannot change FileName while mapped');
  FFileName := AValue;
end;

procedure TPartialFileMapping.SetMappingGranularity(const AValue: Int64);
begin
  if FMappingGranularity = AValue then Exit;
  if AValue <= 0 then
    raise Exception.Create('MappingGranularity must be > 0');
  if (FSpan.BasePtr <> nil) then
    raise Exception.Create('Cannot change MappingGranularity while mapped');
  FMappingGranularity := AValue;
end;

procedure TPartialFileMapping.SetWindowSize(const AValue: SizeUInt);
begin
  if FWindowSize = AValue then Exit;
  if AValue = 0 then
    raise Exception.Create('WindowSize must be > 0');
  if (FSpan.BasePtr <> nil) then
    raise Exception.Create('Cannot change WindowSize while mapped');
  FWindowSize := AValue;
end;

function TPartialFileMapping.AlignDown(Value, Align: Int64): Int64;
begin
  if Align <= 0 then
    raise Exception.Create('Align must be > 0');
  if Value >= 0 then
    Result := Value - (Value mod Align)
  else
    Result := Value;
end;

function TPartialFileMapping.Open: Boolean;
{$IFDEF MSWINDOWS}
var
  access: DWORD;
  share: DWORD;
  disp: DWORD;
  protect: DWORD;
  sizeLow, sizeHigh: DWORD;
  err: DWORD;
{$ELSE}
var
  cur: Int64;
{$ENDIF}
begin
  Result := False;
  if FFileName = '' then Exit;

  {$IFDEF MSWINDOWS}
  if FFileHandle <> INVALID_HANDLE_VALUE then
  begin
    if (FFileSize < 0) then
    begin
      sizeHigh := 0;
      sizeLow := GetFileSize(FFileHandle, @sizeHigh);
      if (sizeLow = INVALID_FILE_SIZE) then
      begin
        err := GetLastError;
        if err <> NO_ERROR then
          FFileSize := -1
        else
          FFileSize := (Int64(sizeHigh) shl 32) or sizeLow;
      end
      else
        FFileSize := (Int64(sizeHigh) shl 32) or sizeLow;
    end;
    Result := True;
    Exit;
  end;

  if FReadOnly then access := GENERIC_READ else access := GENERIC_READ or GENERIC_WRITE;
  share := FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE;
  disp := OPEN_EXISTING;

  FFileHandle := CreateFile(PChar(FFileName), access, share, nil, disp, FILE_ATTRIBUTE_NORMAL, 0);
  if FFileHandle = INVALID_HANDLE_VALUE then
  begin
    err := GetLastError;
    Writeln('CreateFile failed: ', FFileName, ' err=', err);
    Exit;
  end;

  sizeHigh := 0;
  sizeLow := GetFileSize(FFileHandle, @sizeHigh);
  if (sizeLow = INVALID_FILE_SIZE) then
  begin
    err := GetLastError;
    if err <> NO_ERROR then
    begin
      CloseHandle(FFileHandle);
      FFileHandle := INVALID_HANDLE_VALUE;
      Exit;
    end;
  end;
  FFileSize := (Int64(sizeHigh) shl 32) or sizeLow;

  if FReadOnly then protect := PAGE_READONLY else protect := PAGE_READWRITE;

  FMapHandle := CreateFileMapping(FFileHandle, nil, protect, 0, 0, nil);
  Writeln('MapHandle=',FMapHandle, GetLastError);
  if FMapHandle = 0 then
  begin
    CloseHandle(FFileHandle);
    FFileHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  Result := True;
  {$ELSE}
  if FFD >= 0 then begin Result := True; Exit; end;
  if FReadOnly then
    FFD := fpOpen(PChar(FFileName), O_RDONLY)
  else
    FFD := fpOpen(PChar(FFileName), O_RDWR);
  if (FFD < 0) then Exit;

  cur := fpLseek(FFD, 0, SEEK_CUR);
  FFileSize := fpLseek(FFD, 0, SEEK_END);
  fpLseek(FFD, cur, SEEK_SET);
  Result := (FFileSize >= 0);
  {$ENDIF}
end;

procedure TPartialFileMapping.Close;
begin
  UnmapInternal;

  FFileSize := -1;

  {$IFDEF MSWINDOWS}
  if FMapHandle <> 0 then
  begin
    CloseHandle(FMapHandle);
    FMapHandle := 0;
  end;
  if FFileHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FFileHandle);
    FFileHandle := INVALID_HANDLE_VALUE;
  end;
  {$ELSE}
  if FFD >= 0 then
  begin
    fpClose(FFD);
    FFD := -1;
  end;
  {$ENDIF}
end;

procedure TPartialFileMapping.UnmapInternal;
begin
  {$IFDEF MSWINDOWS}
  if FSpan.BasePtr <> nil then
    UnmapViewOfFile(FSpan.BasePtr);
  {$ELSE}
  if (FSpan.BasePtr <> nil) and (FSpan.MapSize <> 0) then
    fpMunmap(FSpan.BasePtr, FSpan.MapSize);
  {$ENDIF}

  FSpan.BaseOffset := -1;
  FSpan.MapSize := 0;
  FSpan.Delta := 0;
  FSpan.BasePtr := nil;
end;

function TPartialFileMapping.MapInternal(AlignedOffset: Int64; MapSize: SizeUInt): Boolean;
{$IFDEF MSWINDOWS}
var
  desiredAccess: DWORD;
  offLow, offHigh: DWORD;
  err: DWORD;
{$ELSE}
var
  prot, flags: cint;
  p: Pointer;
{$ENDIF}
begin
  Result := False;

  UnmapInternal;

  if MapSize = 0 then Exit;

  {$IFDEF MSWINDOWS}
  if FMapHandle = 0 then Exit;

  if FReadOnly then desiredAccess := FILE_MAP_READ else desiredAccess := FILE_MAP_WRITE;
  offLow := DWORD(AlignedOffset and $FFFFFFFF);
  offHigh := DWORD((AlignedOffset shr 32) and $FFFFFFFF);

  FSpan.BasePtr := PByte(MapViewOfFile(FMapHandle, desiredAccess, offHigh, offLow, MapSize));
  if FSpan.BasePtr = nil then
  begin
    err := GetLastError;
    Writeln('MapViewOfFile failed. err=', err, ' alignedOffset=', AlignedOffset, ' mapSize=', MapSize);
    Exit;
  end;

  FSpan.BaseOffset := AlignedOffset;
  FSpan.MapSize := MapSize;

  Result := True;
  {$ELSE}
  if FFD < 0 then Exit;

  if FReadOnly then prot := PROT_READ else prot := PROT_READ or PROT_WRITE;
  flags := MAP_SHARED;

  p := fpMMap(nil, MapSize, prot, flags, FFD, AlignedOffset);
  if (p = MAP_FAILED) then Exit;

  FSpan.BasePtr := PByte(p);
  FSpan.BaseOffset := AlignedOffset;
  FSpan.MapSize := MapSize;

  Result := True;
  {$ENDIF}
end;

function TPartialFileMapping.EnsureRange(FileOffset: Int64; NeedSize: SizeUInt): Boolean;
var
  alignedOffset: Int64;
  delta: SizeUInt;
  mapSize: SizeUInt;
  remaining: Int64;
begin
  Result := False;
  if NeedSize = 0 then Exit(True);
  if FileOffset < 0 then Exit;

  if not Open then Exit;

  if (FSpan.BasePtr <> nil) and
     (FileOffset >= FSpan.BaseOffset) and
     (FileOffset + Int64(NeedSize) <= FSpan.BaseOffset + Int64(FSpan.MapSize)) then
  begin
    FSpan.Delta := SizeUInt(FileOffset - FSpan.BaseOffset);
    Exit(True);
  end;

  alignedOffset := AlignDown(FileOffset, FMappingGranularity);
  delta := SizeUInt(FileOffset - alignedOffset);

  mapSize := FWindowSize;
  if mapSize < delta + NeedSize then
    mapSize := delta + NeedSize;

  // Clamp to file size (MapViewOfFile/mmap cannot map beyond end of file).
  if FFileSize >= 0 then
  begin
    remaining := FFileSize - alignedOffset;
    if remaining <= 0 then Exit(False);
    if Int64(delta) + Int64(NeedSize) > remaining then Exit(False);
    if Int64(mapSize) > remaining then
      mapSize := SizeUInt(remaining);
  end;

  Result := MapInternal(alignedOffset, mapSize);
  if Result then
    FSpan.Delta := delta;
end;

function TPartialFileMapping.PtrAt(FileOffset: Int64): PByte;
begin
  if (FSpan.BasePtr = nil) then Exit(nil);
  if (FileOffset < FSpan.BaseOffset) or (FileOffset >= FSpan.BaseOffset + Int64(FSpan.MapSize)) then
    Exit(nil);
  Result := FSpan.BasePtr + (FileOffset - FSpan.BaseOffset);
end;

end.
