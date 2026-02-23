unit ogcLas;

{$mode Delphi}{$H+}

interface

uses
 Classes, SysUtils,
 ogcBasic, ogcGeometry, ogcRects,
 uLasMmapSource24, uLasViewRenderer, ogcDrawer32, GR32, dglOpenGL;

type
 TogsLas = class(TogsRectLineString)
 protected
  fSource: TLasMmapSource24;
  fRenderer: TLasViewRenderer;
  fFileName: String;
  fBaseX: Double;
  fBaseY: Double;
  fScale: Double;
  fFlipY: Boolean;
  fZBase: Double;
  fZStep: Double;
  fZLayerIndex: Integer;
  fZFilterMode: TZFilterMode;
  fBlendEnabled: Boolean;
  fBlendAlpha: Byte;
  fMode: TLasRenderMode;
  fMaxPoints: Int64;
  procedure UpdateRectPoints;
  function GetLoaded: Boolean;
 public
  constructor Create(ogsSelector_: TogsSelector);
  destructor Destroy; override;
  constructor CreateAs(ogsObject: TogsBasic); override;
  constructor Load(Stream: TogsStream); override;
  procedure Store(Stream: TogsStream); override;
  function Assign(ogsObject: TogsBasic): boolean; override;
  procedure Draw(Drawer: TogsDrawer); override;
  function OpenLasFile(const AFileName: String; const startX: Double = 0; const startY: Double = 0): Boolean;
  procedure CloseLas;
  procedure AutoZLayers(const Layers: Integer = 256);
  property Source: TLasMmapSource24 read fSource;
  property Renderer: TLasViewRenderer read fRenderer;
  property FileName: String read fFileName;
  property Loaded: Boolean read GetLoaded;
  property BaseX: Double read fBaseX write fBaseX;
  property BaseY: Double read fBaseY write fBaseY;
  property Scale: Double read fScale write fScale;
  property FlipY: Boolean read fFlipY write fFlipY;
  property ZBase: Double read fZBase write fZBase;
  property ZStep: Double read fZStep write fZStep;
  property ZLayerIndex: Integer read fZLayerIndex write fZLayerIndex;
  property ZFilterMode: TZFilterMode read fZFilterMode write fZFilterMode;
  property BlendEnabled: Boolean read fBlendEnabled write fBlendEnabled;
  property BlendAlpha: Byte read fBlendAlpha write fBlendAlpha;
  property Mode: TLasRenderMode read fMode write fMode;
  property MaxPoints: Int64 read fMaxPoints write fMaxPoints;
 end;

implementation

procedure TogsLas.UpdateRectPoints;
var
 wM, hM: Double;
 hx0, hx1, hy0, hy1: Double;
begin
 if (fSource = nil) or (not fSource.IsOpen) then Exit;

 if fScale = 0 then fScale := 1;

 hx0 := fSource.Header.MinX;
 hx1 := fSource.Header.MaxX;
 hy0 := fSource.Header.MinY;
 hy1 := fSource.Header.MaxY;

 wM := Abs(hx1 - hx0) * fScale;
 hM := Abs(hy1 - hy0) * fScale;
 if (wM <= 0) or (hM <= 0) then Exit;

 BeginRecalcLock;
 inherited Clear;
 inherited AddPoint(fBaseX,      fBaseY,      0);
 inherited AddPoint(fBaseX + wM, fBaseY,      0);
 inherited AddPoint(fBaseX + wM, fBaseY + hM, 0);
 inherited AddPoint(fBaseX,      fBaseY + hM, 0);
 inherited AddPoint(fBaseX,      fBaseY,      0);
 fWidth := Abs(wM);
 fHeight := Abs(hM);
 fAngleRad := 0;
 EndRecalcLock;
end;

constructor TogsLas.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 fSource := nil;
 fRenderer := TLasViewRenderer.Create(nil);
 fRenderer.Source := nil;
 fFileName := '';
 fBaseX := 0;
 fBaseY := 0;
 fScale := 1;
 fFlipY := False;
 fZBase := 0;
 fZStep := 0;
 fZLayerIndex := 0;
 fZFilterMode := zfmSlice;
 fBlendEnabled := False;
 fBlendAlpha := 64;
 fMode := lrmHeight;
 fMaxPoints := 0;
end;

destructor TogsLas.Destroy;
begin
 CloseLas;
 FreeAndNil(fRenderer);
 inherited Destroy;
end;

constructor TogsLas.CreateAs(ogsObject: TogsBasic);
begin
 fSource := nil;
 fRenderer := nil;
 fFileName := '';
 fBaseX := 0;
 fBaseY := 0;
 fScale := 1;
 fFlipY := False;
 fZBase := 0;
 fZStep := 0;
 fZLayerIndex := 0;
 fZFilterMode := zfmSlice;
 fBlendEnabled := False;
 fBlendAlpha := 64;
 fMode := lrmHeight;
 fMaxPoints := 0;

 if not Assign(ogsObject) then
  raise Exception.Create(ClassName + '.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);

 fRenderer := TLasViewRenderer.Create(nil);
 fRenderer.Source := nil;

 if (fFileName <> '') and FileExists(fFileName) then
  OpenLasFile(fFileName);
end;

constructor TogsLas.Load(Stream: TogsStream);
var
 s: AnsiString;
 m: Integer;
begin
 Stream.Read(fBaseX, SizeOf(fBaseX));
 Stream.Read(fBaseY, SizeOf(fBaseY));
 Stream.Read(fScale, SizeOf(fScale));
 Stream.Read(fZBase, SizeOf(fZBase));
 Stream.Read(fZStep, SizeOf(fZStep));
 Stream.Read(fZLayerIndex, SizeOf(fZLayerIndex));
 if fZStep < 0 then fZStep := 0;
 Stream.Read(m, SizeOf(m));
 if (m >= Ord(Low(TLasRenderMode))) and (m <= Ord(High(TLasRenderMode))) then
  fMode := TLasRenderMode(m)
 else
  fMode := lrmHeight;
 Stream.Read(fMaxPoints, SizeOf(fMaxPoints));

 inherited Load(Stream);

 s := '';
 Stream.ReadString(s);
 fFileName := String(s);

 fSource := nil;
 fRenderer := TLasViewRenderer.Create(nil);
 fRenderer.Source := nil;

 if (fFileName <> '') and FileExists(fFileName) then
  OpenLasFile(fFileName);
end;

procedure TogsLas.Store(Stream: TogsStream);
var
 s: AnsiString;
 m: Integer;
begin
 Stream.Write(fBaseX, SizeOf(fBaseX));
 Stream.Write(fBaseY, SizeOf(fBaseY));
 Stream.Write(fScale, SizeOf(fScale));
 Stream.Write(fZBase, SizeOf(fZBase));
 Stream.Write(fZStep, SizeOf(fZStep));
 Stream.Write(fZLayerIndex, SizeOf(fZLayerIndex));
 m := Ord(fMode);
 Stream.Write(m, SizeOf(m));
 Stream.Write(fMaxPoints, SizeOf(fMaxPoints));

 inherited Store(Stream);

 s := AnsiString(fFileName);
 Stream.WriteString(s);
end;

function TogsLas.Assign(ogsObject: TogsBasic): boolean;
var
 src: TogsLas;
begin
 Result := False;
 if not (ogsObject is TogsLas) then Exit;
 if not inherited Assign(ogsObject) then Exit;

 src := TogsLas(ogsObject);
 fFileName := src.fFileName;
 fBaseX := src.fBaseX;
 fBaseY := src.fBaseY;
 fScale := src.fScale;
 fZBase := src.fZBase;
 fZStep := src.fZStep;
 fZLayerIndex := src.fZLayerIndex;
 fZFilterMode := src.fZFilterMode;
 fBlendEnabled := src.fBlendEnabled;
 fBlendAlpha := src.fBlendAlpha;
 fMode := src.fMode;
 fMaxPoints := src.fMaxPoints;
 Result := True;
end;

procedure TogsLas.CloseLas;
begin
 if fSource <> nil then
 begin
  fSource.Close;
  FreeAndNil(fSource);
 end;
end;

procedure TogsLas.AutoZLayers(const Layers: Integer);
var
 dz: Double;
 n: Integer;
begin
 if (fSource = nil) or (not fSource.IsOpen) then Exit;
 n := Layers;
 if n <= 0 then n := 256;
 dz := fSource.Header.MaxZ - fSource.Header.MinZ;
 fZBase := fSource.Header.MinZ;
 if dz > 0 then
  fZStep := dz / Double(n)
 else
  fZStep := 0;
 fZLayerIndex := 0;
end;

function TogsLas.OpenLasFile(const AFileName: String; const startX: Double; const startY: Double): Boolean;
begin
 Result := False;
 CloseLas;
 if not FileExists(AFileName) then Exit;

 fFileName := AFileName;

 fSource := TLasMmapSource24.Create(nil);
 try
  fSource.FileName := AFileName;
  if not fSource.Open then
  begin
   CloseLas;
   Exit;
  end;
 except
  CloseLas;
  Exit;
 end;

 if (startX <> 0) or (startY <> 0) then
 begin
  fBaseX := startX;
  fBaseY := startY;
 end
 else
 begin
  fBaseX := fSource.Header.MinX;
  fBaseY := fSource.Header.MinY;
 end;

 if fScale = 0 then fScale := 1;
 UpdateRectPoints;

 Result := True;
end;

function TogsLas.GetLoaded: Boolean;
begin
 Result := (fSource <> nil) and fSource.IsOpen;
end;

procedure TogsLas.Draw(Drawer: TogsDrawer);
var
 d32: TogsDrawer32;
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

 if not ogsRect.VisibleIn(ogsSelector.ActiveRect) then Exit;
//
 d32 := TogsDrawer32(Drawer);
 if d32.Image.Bitmap = nil then Exit;
 if fRenderer = nil then Exit;
//
 fRenderer.Source := fSource;
 fRenderer.Mode := fMode;
 fRenderer.BaseX := fBaseX;
 fRenderer.BaseY := fBaseY;
 fRenderer.Scale := fScale;
 fRenderer.FlipY := fFlipY;
 fRenderer.ZBase := fZBase;
 fRenderer.ZStep := fZStep;
 fRenderer.ZLayerIndex := fZLayerIndex;
 fRenderer.ZFilterMode := fZFilterMode;
 fRenderer.BlendEnabled := fBlendEnabled;
 fRenderer.BlendAlpha := fBlendAlpha;
 fRenderer.MaxPoints := fMaxPoints;
//
//  fRenderer.RenderToDrawer32(d32);
//
 inherited Draw(Drawer);
end;

end.
