unit ogcRects;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Math, ogcBasic, ogcGeometry;

type

  { TogsRectLineString }

  TogsRectLineString = class(TogsLineString)
  protected
    fWidth: Double;
    fHeight: Double;
    fAngleRad: Double;
    fRecalcLock: Integer;
    procedure BeginRecalcLock;
    procedure EndRecalcLock;
    function RecalcLocked: Boolean;
    procedure RecalcRectPoints;
    procedure SetWidth(const AValue: Double); virtual;
    procedure SetHeight(const AValue: Double); virtual;
    procedure SetAngleRad(const AValue: Double); virtual;
    procedure EnsureClosed;
    procedure AddPoint(X, Y, Z: Double); override;
    procedure AddPoint(P: TogsDot); overload;
  public
    constructor Create(ogsSelector_: TogsSelector);
    constructor CreateAs(ogsObject: TogsBasic); override;
    constructor Load(Stream: TogsStream); override;
    procedure Store(Stream: TogsStream); override;
    function Assign(ogsObject: TogsBasic): boolean; override;

    procedure SetRectLocal(const ABaseX, ABaseY, AWidth, AHeight: Double);
    procedure RotatePoints(const AAngleRad: Double; const APivotIndex: Integer = 0);

    property Width: Double read fWidth write SetWidth;
    property Height: Double read fHeight write SetHeight;
    property AngleRad: Double read fAngleRad write SetAngleRad;
  end;

  TogsScaledRect = class(TogsRectLineString)
  protected
    fBaseWidth: Double;
    fBaseHeight: Double;
    fScaleX: Double;
    fScaleY: Double;
    procedure SetBaseWidth(const AValue: Double);
    procedure SetBaseHeight(const AValue: Double);
    procedure SetScale(const AValue: Double);
    procedure SetScaleX(const AValue: Double);
    procedure SetScaleY(const AValue: Double);
    procedure UpdateScalesFromSize;
    procedure UpdateSizeFromScales;
    procedure SetWidth(const AValue: Double); override;
    procedure SetHeight(const AValue: Double); override;
  public
    constructor Create(ogsSelector_: TogsSelector);
    constructor CreateAs(ogsObject: TogsBasic); override;
    constructor Load(Stream: TogsStream); override;
    procedure Store(Stream: TogsStream); override;
    function Assign(ogsObject: TogsBasic): boolean; override;

    property BaseWidth: Double read fBaseWidth write SetBaseWidth;
    property BaseHeight: Double read fBaseHeight write SetBaseHeight;
    property Scale: Double write SetScale;
    property ScaleX: Double read fScaleX write SetScaleX;
    property ScaleY: Double read fScaleY write SetScaleY;
  end;

implementation

constructor TogsRectLineString.Create(ogsSelector_: TogsSelector);
begin
  inherited Create(ogsSelector_);
  fWidth := 0;
  fHeight := 0;
  fAngleRad := 0;
  fRecalcLock := 0;
end;

constructor TogsRectLineString.CreateAs(ogsObject: TogsBasic);
begin
  if not (ogsObject is TogsRectLineString) then
    raise Exception.Create(ClassName + '.CreateAs raised type conversion exception');
  inherited CreateAs(ogsObject);
  fWidth := TogsRectLineString(ogsObject).Width;
  fHeight := TogsRectLineString(ogsObject).Height;
  fAngleRad := TogsRectLineString(ogsObject).AngleRad;
end;

constructor TogsRectLineString.Load(Stream: TogsStream);
begin
  BeginRecalcLock;
  Stream.Read(fWidth, SizeOf(fWidth));
  Stream.Read(fHeight, SizeOf(fHeight));
  Stream.Read(fAngleRad, SizeOf(fAngleRad));
  inherited Load(Stream);
  EndRecalcLock;
end;

procedure TogsRectLineString.Store(Stream: TogsStream);
begin
  Stream.Write(fWidth, SizeOf(fWidth));
  Stream.Write(fHeight, SizeOf(fHeight));
  Stream.Write(fAngleRad, SizeOf(fAngleRad));
  inherited Store(Stream);
end;

function TogsRectLineString.Assign(ogsObject: TogsBasic): boolean;
var
  src: TogsRectLineString;
  i: Integer;
begin
  Result := False;
  if not (ogsObject is TogsRectLineString) then
    Exit;

  src := TogsRectLineString(ogsObject);

  BeginRecalcLock;
  inherited Clear;
  for i := 0 to src.Count - 1 do
    inherited AddPoint(src.Point[i].fX, src.Point[i].fY, src.Point[i].Z);
  EnsureClosed;

  fWidth := src.Width;
  fHeight := src.Height;
  fAngleRad := src.AngleRad;
  EndRecalcLock;
  Result := True;
end;

procedure TogsRectLineString.BeginRecalcLock;
begin
 Inc(fRecalcLock);
end;

procedure TogsRectLineString.EndRecalcLock;
begin
 if fRecalcLock > 0 then
  Dec(fRecalcLock);
end;

function TogsRectLineString.RecalcLocked: Boolean;
begin
 Result := fRecalcLock > 0;
end;

procedure TogsRectLineString.RecalcRectPoints;
var
 x0, y0: Double;
 c, s: Double;
 x1, y1, x2, y2, x3, y3: Double;
begin
 if RecalcLocked then Exit;
 if (fWidth <= 0) or (fHeight <= 0) then Exit;

 if Count < 1 then Exit;
 x0 := Point[0].fX;
 y0 := Point[0].fY;

 c := Cos(fAngleRad);
 s := Sin(fAngleRad);

 x1 := x0 + fWidth * c;
 y1 := y0 + fWidth * s;

 x3 := x0 - fHeight * s;
 y3 := y0 + fHeight * c;

 x2 := x1 - fHeight * s;
 y2 := y1 + fHeight * c;

 BeginRecalcLock;
 try
  inherited Clear;
  inherited AddPoint(x0, y0, 0);
  inherited AddPoint(x1, y1, 0);
  inherited AddPoint(x2, y2, 0);
  inherited AddPoint(x3, y3, 0);
  inherited AddPoint(x0, y0, 0);
  EnsureClosed;
 finally
  EndRecalcLock;
 end;
end;

procedure TogsRectLineString.SetWidth(const AValue: Double);
var
 v: Double;
begin
 v := Abs(AValue);
 if v = fWidth then Exit;
 fWidth := v;
 RecalcRectPoints;
end;

procedure TogsRectLineString.SetHeight(const AValue: Double);
var
 v: Double;
begin
 v := Abs(AValue);
 if v = fHeight then Exit;
 fHeight := v;
 RecalcRectPoints;
end;

procedure TogsRectLineString.SetAngleRad(const AValue: Double);
begin
 if AValue = fAngleRad then Exit;
 fAngleRad := AValue;
 RecalcRectPoints;
end;

procedure TogsRectLineString.EnsureClosed;
begin
  if Count <= 0 then
    Exit;
  if (Count = 1) or (Point[Count - 1].fX <> Point[0].fX) or (Point[Count - 1].fY <> Point[0].fY) then
    inherited AddPoint(Point[0].fX, Point[0].fY, 0);
end;

procedure TogsRectLineString.AddPoint(X, Y, Z: Double);
begin
 if Count < 5 then inherited AddPoint(X, Y, Z);
end;

procedure TogsRectLineString.AddPoint(P: TogsDot);
begin
 if Count < 5 then inherited AddPoint(P);
end;

procedure TogsRectLineString.SetRectLocal(const ABaseX, ABaseY, AWidth, AHeight: Double);
var
  w, h: Double;
begin
  BeginRecalcLock;
  inherited Clear;
  w := Abs(AWidth);
  h := Abs(AHeight);
  if (w <= 0) or (h <= 0) then
  begin
    EndRecalcLock;
    Exit;
  end;

  fWidth := w;
  fHeight := h;
  fAngleRad := 0;

  inherited AddPoint(ABaseX,     ABaseY,     0);
  inherited AddPoint(ABaseX + w, ABaseY,     0);
  inherited AddPoint(ABaseX + w, ABaseY + h, 0);
  inherited AddPoint(ABaseX,     ABaseY + h, 0);
  inherited AddPoint(ABaseX,     ABaseY,     0);
  EnsureClosed;
  EndRecalcLock;
end;

procedure TogsRectLineString.RotatePoints(const AAngleRad: Double; const APivotIndex: Integer);
var
  i: Integer;
  px, py: Double;
  dx, dy: Double;
  c, s: Double;
  xNew, yNew: Double;
  lastIsClosure: Boolean;
begin
  if (Count < 2) then
    Exit;
  if (APivotIndex < 0) or (APivotIndex >= Count) then
    Exit;
  if Abs(AAngleRad) <= 1e-18 then
    Exit;

  fAngleRad := fAngleRad + AAngleRad;

  BeginRecalcLock;

  lastIsClosure := (Count >= 2) and (Point[Count - 1].fX = Point[0].fX) and (Point[Count - 1].fY = Point[0].fY);

  px := Point[APivotIndex].fX;
  py := Point[APivotIndex].fY;
  c := Cos(AAngleRad);
  s := Sin(AAngleRad);

  for i := 0 to Count - 1 do
  begin
    if lastIsClosure and (i = Count - 1) then
      Continue;
    dx := Point[i].fX - px;
    dy := Point[i].fY - py;
    xNew := px + dx * c - dy * s;
    yNew := py + dx * s + dy * c;
    Point[i].fX := xNew;
    Point[i].fY := yNew;
  end;

  if lastIsClosure then
  begin
    Point[Count - 1].fX := Point[0].fX;
    Point[Count - 1].fY := Point[0].fY;
  end
  else
    EnsureClosed;

  EndRecalcLock;
end;

constructor TogsScaledRect.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 fBaseWidth := 1;
 fBaseHeight := 1;
 fScaleX := 1;
 fScaleY := 1;
end;

constructor TogsScaledRect.CreateAs(ogsObject: TogsBasic);
begin
 if not (ogsObject is TogsScaledRect) then
  raise Exception.Create(ClassName + '.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 fBaseWidth := TogsScaledRect(ogsObject).BaseWidth;
 fBaseHeight := TogsScaledRect(ogsObject).BaseHeight;
 fScaleX := TogsScaledRect(ogsObject).ScaleX;
 fScaleY := TogsScaledRect(ogsObject).ScaleY;
end;

constructor TogsScaledRect.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
 Stream.Read(fBaseWidth, SizeOf(fBaseWidth));
 Stream.Read(fBaseHeight, SizeOf(fBaseHeight));
 Stream.Read(fScaleX, SizeOf(fScaleX));
 Stream.Read(fScaleY, SizeOf(fScaleY));
 if fBaseWidth = 0 then fBaseWidth := 1;
 if fBaseHeight = 0 then fBaseHeight := 1;
end;

procedure TogsScaledRect.Store(Stream: TogsStream);
begin
 inherited Store(Stream);
 Stream.Write(fBaseWidth, SizeOf(fBaseWidth));
 Stream.Write(fBaseHeight, SizeOf(fBaseHeight));
 Stream.Write(fScaleX, SizeOf(fScaleX));
 Stream.Write(fScaleY, SizeOf(fScaleY));
end;

function TogsScaledRect.Assign(ogsObject: TogsBasic): boolean;
begin
 Result := inherited Assign(ogsObject);
 if not Result then Exit;
 if ogsObject is TogsScaledRect then
 begin
  BeginRecalcLock;
  fBaseWidth := TogsScaledRect(ogsObject).BaseWidth;
  fBaseHeight := TogsScaledRect(ogsObject).BaseHeight;
  fScaleX := TogsScaledRect(ogsObject).ScaleX;
  fScaleY := TogsScaledRect(ogsObject).ScaleY;
  EndRecalcLock;
 end
 else
 begin
  BeginRecalcLock;
  fBaseWidth := Width;
  fBaseHeight := Height;
  fScaleX := 1;
  fScaleY := 1;
  EndRecalcLock;
 end;
end;

procedure TogsScaledRect.SetBaseWidth(const AValue: Double);
var
 v: Double;
begin
 v := Abs(AValue);
 if v = 0 then v := 1;
 if v = fBaseWidth then Exit;
 BeginRecalcLock;
 fBaseWidth := v;
 UpdateScalesFromSize;
 EndRecalcLock;
end;

procedure TogsScaledRect.SetBaseHeight(const AValue: Double);
var
 v: Double;
begin
 v := Abs(AValue);
 if v = 0 then v := 1;
 if v = fBaseHeight then Exit;
 BeginRecalcLock;
 fBaseHeight := v;
 UpdateScalesFromSize;
 EndRecalcLock;
end;

procedure TogsScaledRect.SetScale(const AValue: Double);
begin
 BeginRecalcLock;
 try
  fScaleX := AValue;
  fScaleY := AValue;
  UpdateSizeFromScales;
 finally
  EndRecalcLock;
 end;
end;

procedure TogsScaledRect.SetScaleX(const AValue: Double);
begin
 if AValue = fScaleX then Exit;
 BeginRecalcLock;
 try
  fScaleX := AValue;
  UpdateSizeFromScales;
 finally
  EndRecalcLock;
 end;
end;

procedure TogsScaledRect.SetScaleY(const AValue: Double);
begin
 if AValue = fScaleY then Exit;
 BeginRecalcLock;
 try
  fScaleY := AValue;
  UpdateSizeFromScales;
 finally
  EndRecalcLock;
 end;
end;

procedure TogsScaledRect.UpdateScalesFromSize;
begin
 if fBaseWidth <> 0 then fScaleX := Width / fBaseWidth;
 if fBaseHeight <> 0 then fScaleY := Height / fBaseHeight;
end;

procedure TogsScaledRect.UpdateSizeFromScales;
begin
 inherited SetWidth(fBaseWidth * fScaleX);
 inherited SetHeight(fBaseHeight * fScaleY);
end;

procedure TogsScaledRect.SetWidth(const AValue: Double);
begin
 inherited SetWidth(AValue);
 if RecalcLocked then Exit;
 BeginRecalcLock;
 try
  UpdateScalesFromSize;
 finally
  EndRecalcLock;
 end;
end;

procedure TogsScaledRect.SetHeight(const AValue: Double);
begin
 inherited SetHeight(AValue);
 if RecalcLocked then Exit;
 BeginRecalcLock;
 try
  UpdateScalesFromSize;
 finally
  EndRecalcLock;
 end;
end;

end.
