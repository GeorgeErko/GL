unit vfLineStyles;

{$mode Delphi}

interface

uses
  SysUtils, Math, Graphics, Types, ogcBasic;

type
  // Тип окончания и стыка линии
  TVFLineCapKind = (lckRound, lckButt);
  TVFLineJoinKind = (ljkRound, ljkBevel, ljkMiter);
{
  TVFLineCapKind
  lckRound – закруглённые окончания штрихов/линии (полукружие радиусом половины толщины).
  lckButt – «обрубленные» окончания: линия обрывается строго в конечной точке без выступов.
  lckPolygon – произвольная полигональная форма окончания (например, острый «клин» с заданным минимальным углом).
  TVFLineJoinKind
  ljkRound – соединение сегментов через дугу (скруглённый угол).
  ljkBevel – фаска: угол срезается по прямой, образуя скошенную грань.
  ljkMiter – острый «усик»: продолжения боковых рёбер пересекаются в одной точке (обычно ограничивается максимальной длиной, чтобы не было бесконечно длинных выступов)
}

const
  VF_DEFAULT_CAP_KIND = lckButt;
  VF_DEFAULT_JOIN_KIND = ljkBevel;

type

  { TVFLineDashPattern }
  // Объект хранит последовательность длин штрихов и промежутков
  TVFLineDashPattern = class(TogsBasic)
  private
    FSegments: array of Double;
    function GetCount: Integer;
    function GetSegment(Index: Integer): Double;
    procedure SetSegment(Index: Integer; const Value: Double);
  public
    constructor Create; virtual;
    procedure Clear;
    procedure AddSegment(const Length_: Double);
    function TotalLength: Double;
    function IsEmpty: Boolean;
    function Assign(ogsObject: TogsBasic): boolean; override;
    property Count: Integer read GetCount;
    property Segments[Index: Integer]: Double read GetSegment write SetSegment; default;
  end;

  { TVFLineLayer }
  // Базовый слой линии: общий цвет, толщина, смещение и отсечения
  TVFLineLayer = class(TogsBasic)
  private
    FName: string;
    FColor: TColor;
    FBaseThickness: Double;
    FOffset: Double;
    FTrimStart: Double;
    FTrimEnd: Double;
    FEnabled: Boolean;
    procedure SetBaseThickness(const Value: Double);
  public
    constructor Create; virtual;
    function Assign(ogsObject: TogsBasic): boolean; override;
    procedure SetTrimRange(const AStart, AEnd: Double);
    property Enabled: Boolean read FEnabled write FEnabled;
    property Name: string read FName write FName;
    property Color: TColor read FColor write FColor;
    property BaseThickness: Double read FBaseThickness write SetBaseThickness;
    property Offset: Double read FOffset write FOffset;
    property TrimStart: Double read FTrimStart;
    property TrimEnd: Double read FTrimEnd;
  end;

  { TVFLineSolidLayer }
  // Слой сплошной линии с параметрами окончаний и стыков
  TVFLineSolidLayer = class(TVFLineLayer)
  private
    FCapKind: TVFLineCapKind;
    FJoinKind: TVFLineJoinKind;
  public
    constructor Create; override;
    function Assign(ogsObject: TogsBasic): boolean; override;
    property CapKind: TVFLineCapKind read FCapKind write FCapKind;
    property JoinKind: TVFLineJoinKind read FJoinKind write FJoinKind;
  end;

  { TVFLinePatternLayer }
  // Слой с паттерном штрихов
  TVFLinePatternLayer = class(TVFLineSolidLayer)
  private
    FDashPattern: TVFLineDashPattern;
    FDashOffset: Double;
    function GetDashPattern: TVFLineDashPattern;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Assign(ogsObject: TogsBasic): boolean; override;
    property DashPattern: TVFLineDashPattern read GetDashPattern;
    property DashOffset: Double read FDashOffset write FDashOffset;
  end;

  { TVFLineCustomLayer }
  // Слой с пользовательскими параметрами
  TVFLineCustomLayer = class(TVFLineLayer)
  private
    FUserParams: string;
  public
    function Assign(ogsObject: TogsBasic): boolean; override;
    property UserParams: string read FUserParams write FUserParams;
  end;

  TVFLineLayerClass = class of TVFLineLayer;

  { TVFLineLayerList }
  // Коллекция слоёв линии
  TVFLineLayerList = class(TogsCollection)
  private
    function GetLayer(Index: Integer): TVFLineLayer;
    class function CheckLayerType(P: TogsBasic): Boolean; static;
  public
    constructor Create;
    function AddLayer(ALayerClass: TVFLineLayerClass): TVFLineLayer;
    property Items[Index: Integer]: TVFLineLayer read GetLayer; default;
  end;

  { TVFLineStyle }
  // Композитный стиль линии
  TVFLineStyle = class(TogsBasic)
  private
    FName: string;
    FLayers: TVFLineLayerList;
    FBaseThickness: Double;
    FDashOffset: Double;
    FTrimStart: Double;
    FTrimEnd: Double;
    FThinLine: Boolean;
    FThinThreshold: Double;
    function GetLayer(Index: Integer): TVFLineLayer;
    function GetLayerCount: Integer;
    procedure SetBaseThickness(const Value: Double);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Assign(ogsObject: TogsBasic): boolean; override;
    function AddLayer(ALayerClass: TVFLineLayerClass): TVFLineLayer;
    function AddSolidLayer: TVFLineSolidLayer;
    function AddPatternLayer: TVFLinePatternLayer;
    function AddCustomLayer: TVFLineCustomLayer;
    procedure ClearLayers;
    procedure SetTrimRange(const AStart, AEnd: Double);
    procedure UpdateThinFlag(const Scale: Double);
    property Name: string read FName write FName;
    property Layers: TVFLineLayerList read FLayers;
    property LayerCount: Integer read GetLayerCount;
    property Layer[Index: Integer]: TVFLineLayer read GetLayer;
    property BaseThickness: Double read FBaseThickness write SetBaseThickness;
    property DashOffset: Double read FDashOffset write FDashOffset;
    property TrimStart: Double read FTrimStart;
    property TrimEnd: Double read FTrimEnd;
    property ThinLine: Boolean read FThinLine write FThinLine;
    property ThinThreshold: Double read FThinThreshold write FThinThreshold;
  end;

  { TVFLineStyleList }
  // Сортированная коллекция типов линий (TVFLineStyle), сортировка по Name
  TVFLineStyleList = class(TogsSortedCollection)
  private
    function GetStyle(Index: Integer): TVFLineStyle;
    class function CheckStyleType(P: TogsBasic): Boolean; static;
    class function CompareStyles(Item1, Item2: Pointer): Integer; static;
  public
    constructor Create;
    function AddStyle: TVFLineStyle;
    property Items[Index: Integer]: TVFLineStyle read GetStyle; default;
  end;

  // Полигональная аппроксимация утолщённой линии
  TVFLinePolygon = array of TPointF;
  TVFLinePolygonArray = array of TVFLinePolygon;

function VFPointF(const AX, AY: Double): TPointF; inline;
// Геометрические процедуры
procedure BuildSolidButtPolygons(const Layer: TVFLineSolidLayer;
  const Points: array of TPointF; out Polygons: TVFLinePolygonArray);
procedure BuildSolidButtMiterPolygons(const Layer: TVFLineSolidLayer;
  const Points: TVFLinePolygon; out Polygons: TVFLinePolygonArray);
procedure BuildSolidButtMiterPolygons2(const Layer: TVFLineSolidLayer;
  const Points: TVFLinePolygon; out Polygons: TVFLinePolygonArray);
procedure BuildSolidPolygons(const Layer: TVFLineSolidLayer;
  const Points: TVFLinePolygon; out Polygons: TVFLinePolygonArray);
procedure BuildDashedPolylines(const Points: TVFLinePolygon;
  const Pattern: TVFLineDashPattern; const DashOffset: Double;
  out Strokes: TVFLinePolygonArray);
procedure BuildDashedPolygons(const Layer: TVFLinePatternLayer;
  const Points: TVFLinePolygon; out Polygons: TVFLinePolygonArray);

implementation uses ogcWriter;

const
  DEFAULT_THICKNESS = 1.0;
  DEFAULT_THIN_THRESHOLD = 1.0;
  MIN_SEGMENT_LENGTH = 1e-6;
  DEFAULT_MIN_ANGLE = 15 * Pi / 180;

{ TVFLineDashPattern }

constructor TVFLineDashPattern.Create;
begin
  inherited Create;
  SetLength(FSegments, 0);
end;

procedure TVFLineDashPattern.AddSegment(const Length_: Double);
var
  NewIndex: Integer;
begin
  if Length_ <= MIN_SEGMENT_LENGTH then
    Exit;
  NewIndex := Length(FSegments);
  SetLength(FSegments, NewIndex + 1);
  FSegments[NewIndex] := Length_;
end;

function TVFLineDashPattern.Assign(ogsObject: TogsBasic): boolean;
var
  Src: TVFLineDashPattern;
  I: Integer;
begin
  Result := ogsObject is TVFLineDashPattern;
  if not Result then
    Exit;
  Src := TVFLineDashPattern(ogsObject);
  Clear;
  for I := 0 to Src.Count - 1 do
    AddSegment(Src[I]);
end;

procedure TVFLineDashPattern.Clear;
begin
  SetLength(FSegments, 0);
end;

function TVFLineDashPattern.GetCount: Integer;
begin
  Result := Length(FSegments);
end;

function TVFLineDashPattern.GetSegment(Index: Integer): Double;
begin
  if (Index >= 0) and (Index < Length(FSegments)) then
    Result := FSegments[Index]
  else
    Result := 0;
end;

function TVFLineDashPattern.IsEmpty: Boolean;
begin
  Result := TotalLength <= MIN_SEGMENT_LENGTH;
end;

procedure TVFLineDashPattern.SetSegment(Index: Integer; const Value: Double);
begin
  if (Index < 0) or (Index >= Length(FSegments)) then
    Exit;
  if Value <= MIN_SEGMENT_LENGTH then
    FSegments[Index] := MIN_SEGMENT_LENGTH
  else
    FSegments[Index] := Value;
end;

function TVFLineDashPattern.TotalLength: Double;
var
  Segment: Double;
begin
  Result := 0;
  for Segment in FSegments do
    Result := Result + Segment;
end;

{ TVFLineLayer }

constructor TVFLineLayer.Create;
begin
  inherited Create;
  FName := '';
  FColor := clBlack;
  FBaseThickness := DEFAULT_THICKNESS;
  FOffset := 0;
  FTrimStart := 0;
  FTrimEnd := 0;
  FEnabled := True;
end;

function TVFLineLayer.Assign(ogsObject: TogsBasic): boolean;
var
  Src: TVFLineLayer;
begin
  Result := ogsObject is TVFLineLayer;
  if not Result then
    Exit;
  Src := TVFLineLayer(ogsObject);
  FName := Src.FName;
  FColor := Src.FColor;
  FBaseThickness := Src.FBaseThickness;
  FOffset := Src.FOffset;
  FTrimStart := Src.FTrimStart;
  FTrimEnd := Src.FTrimEnd;
  FEnabled := Src.FEnabled;
end;

procedure TVFLineLayer.SetBaseThickness(const Value: Double);
begin
  if Value <= MIN_SEGMENT_LENGTH then
    FBaseThickness := DEFAULT_THICKNESS
  else
    FBaseThickness := Value;
end;

procedure TVFLineLayer.SetTrimRange(const AStart, AEnd: Double);
var
  StartValue, EndValue: Double;
begin
  StartValue := Max(0, AStart);
  EndValue := Max(0, AEnd);
  if (EndValue > 0) and (EndValue < StartValue) then
    EndValue := StartValue;
  FTrimStart := StartValue;
  FTrimEnd := EndValue;
end;

{ TVFLineSolidLayer }

constructor TVFLineSolidLayer.Create;
begin
  inherited Create;
  FCapKind := VF_DEFAULT_CAP_KIND;
  FJoinKind := VF_DEFAULT_JOIN_KIND;
end;

function TVFLineSolidLayer.Assign(ogsObject: TogsBasic): boolean;
var
  Src: TVFLineSolidLayer;
begin
  Result := inherited Assign(ogsObject);
  if not Result then
    Exit;
  Src := TVFLineSolidLayer(ogsObject);
  FCapKind := Src.FCapKind;
  FJoinKind := Src.FJoinKind;
end;

{ TVFLinePatternLayer }

constructor TVFLinePatternLayer.Create;
begin
  inherited Create;
  FDashPattern := nil;
  FDashOffset := 0;
end;

destructor TVFLinePatternLayer.Destroy;
begin
  FreeAndNil(FDashPattern);
  inherited Destroy;
end;

function TVFLinePatternLayer.Assign(ogsObject: TogsBasic): boolean;
var
  Src: TVFLinePatternLayer;
begin
  Result := inherited Assign(ogsObject);
  if not Result then
    Exit;
  Src := TVFLinePatternLayer(ogsObject);
  FDashOffset := Src.FDashOffset;
  if Assigned(Src.FDashPattern) then
    GetDashPattern.Assign(Src.FDashPattern)
  else if Assigned(FDashPattern) then
    FDashPattern.Clear;
end;

function TVFLinePatternLayer.GetDashPattern: TVFLineDashPattern;
begin
  if not Assigned(FDashPattern) then
    FDashPattern := TVFLineDashPattern.Create;
  Result := FDashPattern;
end;

{ TVFLineCustomLayer }

function TVFLineCustomLayer.Assign(ogsObject: TogsBasic): boolean;
var
  Src: TVFLineCustomLayer;
begin
  Result := inherited Assign(ogsObject);
  if not Result then
    Exit;
  Src := TVFLineCustomLayer(ogsObject);
  FUserParams := Src.FUserParams;
end;

{ TVFLineLayerList }

constructor TVFLineLayerList.Create;
begin
  inherited Create(1);
  CheckTypeProc := @TVFLineLayerList.CheckLayerType;
end;

class function TVFLineLayerList.CheckLayerType(P: TogsBasic): Boolean;
begin
  Result := P is TVFLineLayer;
end;

function TVFLineLayerList.AddLayer(ALayerClass: TVFLineLayerClass): TVFLineLayer;
begin
  if ALayerClass = nil then
    raise Exception.Create('Не указан класс слоя линии.');
  Result := ALayerClass.Create;
  inherited Add(Result);
end;

function TVFLineLayerList.GetLayer(Index: Integer): TVFLineLayer;
begin
  Result := TVFLineLayer(inherited Items[Index]);
end;

{ TVFLineStyle }

constructor TVFLineStyle.Create;
begin
  inherited Create;
  FName := '';
  FLayers := TVFLineLayerList.Create;
  FBaseThickness := DEFAULT_THICKNESS;
  FDashOffset := 0;
  FTrimStart := 0;
  FTrimEnd := 0;
  FThinThreshold := DEFAULT_THIN_THRESHOLD;
  FThinLine := False;
end;

destructor TVFLineStyle.Destroy;
begin
  FLayers.Free;
  inherited Destroy;
end;

function TVFLineStyle.Assign(ogsObject: TogsBasic): boolean;
var
  Src: TVFLineStyle;
  I: Integer;
  NewLayer: TVFLineLayer;
begin
  Result := ogsObject is TVFLineStyle;
  if not Result then
    Exit;
  Src := TVFLineStyle(ogsObject);
  FName := Src.FName;
  FBaseThickness := Src.FBaseThickness;
  FDashOffset := Src.FDashOffset;
  FTrimStart := Src.FTrimStart;
  FTrimEnd := Src.FTrimEnd;
  FThinLine := Src.FThinLine;
  FThinThreshold := Src.FThinThreshold;
  ClearLayers;
  for I := 0 to Src.LayerCount - 1 do
  begin
    NewLayer := AddLayer(TVFLineLayerClass(Src.Layer[I].ClassType));
    NewLayer.Assign(Src.Layer[I]);
  end;
end;

function TVFLineStyle.AddLayer(ALayerClass: TVFLineLayerClass): TVFLineLayer;
begin
  Result := FLayers.AddLayer(ALayerClass);
end;

function TVFLineStyle.AddSolidLayer: TVFLineSolidLayer;
begin
  Result := TVFLineSolidLayer(AddLayer(TVFLineSolidLayer));
end;

function TVFLineStyle.AddPatternLayer: TVFLinePatternLayer;
begin
  Result := TVFLinePatternLayer(AddLayer(TVFLinePatternLayer));
end;

function TVFLineStyle.AddCustomLayer: TVFLineCustomLayer;
begin
  Result := TVFLineCustomLayer(AddLayer(TVFLineCustomLayer));
end;

procedure TVFLineStyle.ClearLayers;
begin
  FLayers.FreeAll;
end;

procedure TVFLineStyle.SetBaseThickness(const Value: Double);
begin
  if Value <= MIN_SEGMENT_LENGTH then
    FBaseThickness := DEFAULT_THICKNESS
  else
    FBaseThickness := Value;
end;

procedure TVFLineStyle.SetTrimRange(const AStart, AEnd: Double);
var
  StartValue, EndValue: Double;
begin
  StartValue := Max(0, AStart);
  EndValue := Max(0, AEnd);
  if (EndValue > 0) and (EndValue < StartValue) then
    EndValue := StartValue;
  FTrimStart := StartValue;
  FTrimEnd := EndValue;
end;

procedure TVFLineStyle.UpdateThinFlag(const Scale: Double);
var
  ScreenWidth: Double;
begin
  ScreenWidth := FBaseThickness * Scale;
  FThinLine := ScreenWidth <= Max(MIN_SEGMENT_LENGTH, FThinThreshold);
end;

function TVFLineStyle.GetLayer(Index: Integer): TVFLineLayer;
begin
  Result := FLayers[Index];
end;

function TVFLineStyle.GetLayerCount: Integer;
begin
  Result := FLayers.Count;
end;

{ TVFLineStyleList }

constructor TVFLineStyleList.Create;
begin
  inherited Create(@TVFLineStyleList.CompareStyles, False, 1);
  CheckTypeProc := @TVFLineStyleList.CheckStyleType;
end;

class function TVFLineStyleList.CheckStyleType(P: TogsBasic): Boolean;
begin
  Result := P is TVFLineStyle;
end;

class function TVFLineStyleList.CompareStyles(Item1, Item2: Pointer): Integer;
var
  A, B: TVFLineStyle;
begin
  A := TVFLineStyle(Item1);
  B := TVFLineStyle(Item2);
  if (A = nil) and (B = nil) then
    Exit(0);
  if A = nil then
    Exit(-1);
  if B = nil then
    Exit(1);
  Result := CompareText(A.Name, B.Name);
end;

function TVFLineStyleList.AddStyle: TVFLineStyle;
begin
  Result := TVFLineStyle.Create;
  inherited Add(Result);
end;

function TVFLineStyleList.GetStyle(Index: Integer): TVFLineStyle;
begin
  Result := TVFLineStyle(inherited Items[Index]);
end;

function VFPointF(const AX, AY: Double): TPointF; inline;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function VFAdd(const A, B: TPointF): TPointF; inline;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

function VFSub(const A, B: TPointF): TPointF; inline;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

function VFScale(const A: TPointF; const S: Double): TPointF; inline;
begin
  Result.X := A.X * S;
  Result.Y := A.Y * S;
end;

function VFDot(const A, B: TPointF): Double; inline;
begin
  Result := A.X * B.X + A.Y * B.Y;
end;

function VFCross(const A, B: TPointF): Double; inline;
begin
  Result := A.X * B.Y - A.Y * B.X;
end;

function IsZeroVec(const V: TPointF): Boolean; inline;
begin
  Result := (Abs(V.X) <= MIN_SEGMENT_LENGTH) and (Abs(V.Y) <= MIN_SEGMENT_LENGTH);
end;

function NormalizeVector(const V: TPointF; out R: TPointF): Boolean; inline;
var
  L: Double;
begin
  L := Hypot(V.X, V.Y);
  Result := L > MIN_SEGMENT_LENGTH;
  if Result then
  begin
    R.X := V.X / L;
    R.Y := V.Y / L;
  end
  else
    R := VFPointF(0, 0);
end;

function LeftNormal(const Dir: TPointF): TPointF; inline;
begin
  Result := VFPointF(-Dir.Y, Dir.X);
end;

function LinesIntersection(const P1, D1, P2, D2: TPointF; out X: TPointF): Boolean;
var
  Denom, TVal: Double;
begin
  Denom := VFCross(D1, D2);
  if SameValue(Denom, 0.0, MIN_SEGMENT_LENGTH) then
    Exit(False);
  TVal := VFCross(VFSub(P2, P1), D2) / Denom;
  X := VFAdd(P1, VFScale(D1, TVal));
  Result := True;
end;

procedure BuildDashedPolylines(const Points: TVFLinePolygon;
  const Pattern: TVFLineDashPattern; const DashOffset: Double;
  out Strokes: TVFLinePolygonArray);
var
  TotalLen, OffsetPos: Double;
  PatternIndex: Integer;
  InSegmentOffset: Double;
  RemainingInPattern: Double;
  IsOn: Boolean;
  SegmentIndex: Integer;
  P0, P1, D, CutPoint: TPointF;
  SegLen, StepLen, T: Double;
  Current: TVFLinePolygon;

  function SamePoint(const A, B: TPointF): Boolean; inline;
  begin
    Result := SameValue(A.X, B.X, 1e-9) and SameValue(A.Y, B.Y, 1e-9);
  end;

  procedure FlushCurrent;
  var
    Idx: Integer;
  begin
    if Length(Current) < 2 then
    begin
      SetLength(Current, 0);
      Exit;
    end;
    Idx := Length(Strokes);
    SetLength(Strokes, Idx + 1);
    Strokes[Idx] := Current;
    SetLength(Current, 0);
  end;

  procedure EnsureAddPoint(const P: TPointF);
  var
    N: Integer;
  begin
    N := Length(Current);
    if (N = 0) or (not SamePoint(Current[N - 1], P)) then
    begin
      SetLength(Current, N + 1);
      Current[N] := P;
    end;
  end;

  procedure AdvancePattern(const Delta: Double);
  var
    Left: Double;
  begin
    Left := Delta;
    while Left > MIN_SEGMENT_LENGTH do
    begin
      if Left < RemainingInPattern - MIN_SEGMENT_LENGTH then
      begin
        RemainingInPattern := RemainingInPattern - Left;
        Exit;
      end;
      Left := Left - RemainingInPattern;
      Inc(PatternIndex);
      if PatternIndex >= Pattern.Count then
        PatternIndex := 0;
      RemainingInPattern := Max(MIN_SEGMENT_LENGTH, Pattern[PatternIndex]);
      IsOn := (PatternIndex mod 2) = 0;
      if not IsOn then
        FlushCurrent;
    end;
  end;

begin
  Strokes := nil;
  Current := nil;

  if Length(Points) < 2 then
    Exit;
  if (Pattern = nil) or (Pattern.Count = 0) then
  begin
    SetLength(Strokes, 1);
    Strokes[0] := Copy(Points, 0, Length(Points));
    Exit;
  end;

  TotalLen := Pattern.TotalLength;
  if TotalLen <= MIN_SEGMENT_LENGTH then
  begin
    SetLength(Strokes, 1);
    Strokes[0] := Copy(Points, 0, Length(Points));
    Exit;
  end;

  OffsetPos := DashOffset;
  OffsetPos := OffsetPos - Floor(OffsetPos / TotalLen) * TotalLen;
  if OffsetPos < 0 then
    OffsetPos := OffsetPos + TotalLen;

  PatternIndex := 0;
  InSegmentOffset := 0;
  while (PatternIndex < Pattern.Count) and (OffsetPos > MIN_SEGMENT_LENGTH) do
  begin
    if OffsetPos < Pattern[PatternIndex] - MIN_SEGMENT_LENGTH then
    begin
      InSegmentOffset := OffsetPos;
      OffsetPos := 0;
      Break;
    end;
    OffsetPos := OffsetPos - Pattern[PatternIndex];
    Inc(PatternIndex);
    if PatternIndex >= Pattern.Count then
      PatternIndex := 0;
  end;

  IsOn := (PatternIndex mod 2) = 0;
  RemainingInPattern := Max(MIN_SEGMENT_LENGTH, Pattern[PatternIndex] - InSegmentOffset);
  if not IsOn then
    FlushCurrent;

  for SegmentIndex := 0 to High(Points) - 1 do
  begin
    P0 := Points[SegmentIndex];
    P1 := Points[SegmentIndex + 1];
    D := VFSub(P1, P0);
    SegLen := Hypot(D.X, D.Y);
    if SegLen <= MIN_SEGMENT_LENGTH then
      Continue;

    while SegLen > MIN_SEGMENT_LENGTH do
    begin
      StepLen := RemainingInPattern;
      if StepLen > SegLen then
        StepLen := SegLen;

      T := StepLen / SegLen;
      CutPoint := VFAdd(P0, VFScale(D, T));

      if IsOn then
      begin
        EnsureAddPoint(P0);
        EnsureAddPoint(CutPoint);
      end;

      AdvancePattern(StepLen);

      P0 := CutPoint;
      D := VFSub(P1, P0);
      SegLen := Hypot(D.X, D.Y);
    end;
  end;

  FlushCurrent;
end;

procedure BuildDashedPolygons(const Layer: TVFLinePatternLayer;
  const Points: TVFLinePolygon; out Polygons: TVFLinePolygonArray);
const
  EPS = 1e-6;
var
  Trimmed: TVFLinePolygon;
  Strokes: TVFLinePolygonArray;
  Stroke: TVFLinePolygon;
  StrokePolys: TVFLinePolygonArray;
  I, J, K, N: Integer;

  function GetTrimmedPoints(const Src: TVFLinePolygon; const TrimStart,
    TrimEnd: Double): TVFLinePolygon;
  var
    Idx: Integer;
    Total, CutS, CutE: Double;
    Acc, SegLen: Double;
    P0, P1: TPointF;
    DX, DY: Double;
    T0, T1: Double;
    A, B: TPointF;
    L: Integer;

    procedure AddPoint(const P: TPointF);
    begin
      L := Length(Result);
      if (L = 0) or (Abs(Result[L - 1].X - P.X) > 1e-9) or (Abs(Result[L - 1].Y - P.Y) > 1e-9) then
      begin
        SetLength(Result, L + 1);
        Result[L] := P;
      end;
    end;

  begin
    Result := nil;
    if Length(Src) < 2 then
      Exit;

    Total := 0;
    for Idx := 0 to High(Src) - 1 do
      Total := Total + Hypot(Src[Idx + 1].X - Src[Idx].X, Src[Idx + 1].Y - Src[Idx].Y);
    if Total <= EPS then
      Exit;

    CutS := Max(0, TrimStart);
    CutE := Max(0, TrimEnd);
    if CutS + CutE >= Total - EPS then
      Exit;

    Acc := 0;
    for Idx := 0 to High(Src) - 1 do
    begin
      P0 := Src[Idx];
      P1 := Src[Idx + 1];
      DX := P1.X - P0.X;
      DY := P1.Y - P0.Y;
      SegLen := Hypot(DX, DY);
      if SegLen <= EPS then
        Continue;

      T0 := 0;
      T1 := 1;
      if CutS > Acc + EPS then
        T0 := (CutS - Acc) / SegLen;
      if (Total - CutE) < (Acc + SegLen - EPS) then
        T1 := (Total - CutE - Acc) / SegLen;

      if T1 <= 0 then
        Break;
      if T0 >= 1 then
      begin
        Acc := Acc + SegLen;
        Continue;
      end;

      T0 := EnsureRange(T0, 0, 1);
      T1 := EnsureRange(T1, 0, 1);
      if T1 <= T0 + 1e-12 then
      begin
        Acc := Acc + SegLen;
        Continue;
      end;

      A.X := P0.X + DX * T0;
      A.Y := P0.Y + DY * T0;
      B.X := P0.X + DX * T1;
      B.Y := P0.Y + DY * T1;
      AddPoint(A);
      AddPoint(B);

      Acc := Acc + SegLen;
      if T1 < 1 - 1e-12 then
        Break;
    end;
  end;

begin
  Polygons := nil;
  if (Layer = nil) or (Length(Points) < 2) then
    Exit;

  Trimmed := GetTrimmedPoints(Points, Layer.TrimStart, Layer.TrimEnd);
  if Length(Trimmed) < 2 then
    Exit;

  if (Layer.DashPattern = nil) or (Layer.DashPattern.Count = 0) or Layer.DashPattern.IsEmpty then
  begin
    BuildSolidPolygons(Layer, Trimmed, Polygons);
    Exit;
  end;

  BuildDashedPolylines(Trimmed, Layer.DashPattern, Layer.DashOffset, Strokes);

  N := 0;
  for Stroke in Strokes do
  begin
    StrokePolys := nil;
    if Length(Stroke) < 2 then
      Continue;
    if Layer.JoinKind = ljkMiter then
      BuildSolidButtMiterPolygons(Layer, Stroke, StrokePolys)
    else
      BuildSolidButtPolygons(Layer, Stroke, StrokePolys);
    N := N + Length(StrokePolys);
  end;

  SetLength(Polygons, N);
  K := 0;
  for I := 0 to High(Strokes) do
  begin
    Stroke := Strokes[I];
    StrokePolys := nil;
    if Length(Stroke) < 2 then
      Continue;
    if Layer.JoinKind = ljkMiter then
      BuildSolidButtMiterPolygons(Layer, Stroke, StrokePolys)
    else
      BuildSolidButtPolygons(Layer, Stroke, StrokePolys);
    for J := 0 to High(StrokePolys) do
    begin
      Polygons[K] := StrokePolys[J];
      Inc(K);
    end;
  end;
  SetLength(Polygons, K);
end;

procedure BuildBaseOutlines(const Points: TVFLinePolygon; const Normals: TVFLinePolygon;
 const HalfWidth: Double; out LeftOutline, RightOutline: TVFLinePolygon);
var
 I: Integer;
 Offset: TPointF;
begin
 SetLength(LeftOutline, Length(Points));
 SetLength(RightOutline, Length(Points));
 for I := 0 to High(Points) do
 begin
 Offset := VFScale(Normals[I], HalfWidth);
 LeftOutline[I] := VFAdd(Points[I], Offset);
 RightOutline[I] := VFSub(Points[I], Offset);
 end;
end;

procedure BuildSolidButtPolygons(const Layer: TVFLineSolidLayer;
  const Points: array of TPointF; out Polygons: TVFLinePolygonArray);
var
  SegmentIndex, PolyIndex: Integer;
  P0, P1, Normal, OffsetVec, ShiftVec: TPointF;
  DX, DY, SegmentLength, HalfWidth: Double;
begin
  Polygons := nil;
  if (Layer = nil) or (Length(Points) < 2) then
    Exit;

 // if Layer.CapKind <> lckButt then
  //  Exit;
 // if Layer.JoinKind <> ljkBevel then
  //  Exit;

  HalfWidth := Max(MIN_SEGMENT_LENGTH, Layer.BaseThickness) * 0.5;
  if HalfWidth <= MIN_SEGMENT_LENGTH then
    Exit;

  SetLength(Polygons, Length(Points) - 1);
  PolyIndex := 0;

  for SegmentIndex := 0 to Length(Points) - 2 do
  begin
    P0 := Points[SegmentIndex];
    P1 := Points[SegmentIndex + 1];

    DX := P1.X - P0.X;
    DY := P1.Y - P0.Y;
    SegmentLength := Hypot(DX, DY);
    if SegmentLength <= MIN_SEGMENT_LENGTH then
      Continue;

    Normal := VFPointF(-DY / SegmentLength, DX / SegmentLength);
    OffsetVec := VFPointF(Normal.X * HalfWidth, Normal.Y * HalfWidth);

    if not SameValue(Layer.Offset, 0.0, MIN_SEGMENT_LENGTH) then
    begin
      ShiftVec := VFPointF(Normal.X * Layer.Offset, Normal.Y * Layer.Offset);
      P0 := VFPointF(P0.X + ShiftVec.X, P0.Y + ShiftVec.Y);
      P1 := VFPointF(P1.X + ShiftVec.X, P1.Y + ShiftVec.Y);
    end;

    SetLength(Polygons[PolyIndex], 4);
    Polygons[PolyIndex][0] := VFPointF(P0.X - OffsetVec.X, P0.Y - OffsetVec.Y);
    Polygons[PolyIndex][1] := VFPointF(P0.X + OffsetVec.X, P0.Y + OffsetVec.Y);
    Polygons[PolyIndex][2] := VFPointF(P1.X + OffsetVec.X, P1.Y + OffsetVec.Y);
    Polygons[PolyIndex][3] := VFPointF(P1.X - OffsetVec.X, P1.Y - OffsetVec.Y);
    Inc(PolyIndex);
  end;

  SetLength(Polygons, PolyIndex);
end;

procedure BuildSolidButtMiterPolygons(const Layer: TVFLineSolidLayer;
  const Points: TVFLinePolygon; out Polygons: TVFLinePolygonArray);
var
  BasePolys, Extra: TVFLinePolygonArray;
  SegmentCount, I, BaseCount: Integer;
  DirPrevIn, DirNextOut, PrevOut: TPointF;
  AngleRad, HalfWidth, TurnSign: Double;
  PrevOffsetPt, NextOffsetPt, Apex: TPointF;

  procedure AddExtra(const Poly: TVFLinePolygon);
  var
    Idx: Integer;
  begin
    Idx := Length(Extra);
    SetLength(Extra, Idx + 1);
    Extra[Idx] := Poly;
  end;

  procedure AppendMiterQuad(const A, B, C, Vtx: TPointF; const Turn: Double);
  var
    Poly: TVFLinePolygon;
  begin
    SetLength(Poly, 4);
    if Turn > 0 then
    begin
      Poly[0] := A;
      Poly[1] := B;
      Poly[2] := C;
      Poly[3] := Vtx;
    end
    else
    begin
      Poly[0] := C;
      Poly[1] := B;
      Poly[2] := A;
      Poly[3] := Vtx;
    end;
    AddExtra(Poly);
  end;

begin
  Polygons := nil;
  if (Layer = nil) or (Length(Points) < 2) then
    Exit;
  if Layer.CapKind <> lckButt then
    Exit;

  BuildSolidButtPolygons(Layer, Points, BasePolys);
  Polygons := BasePolys;

  HalfWidth := Max(MIN_SEGMENT_LENGTH, Layer.BaseThickness) * 0.5;
  if HalfWidth <= MIN_SEGMENT_LENGTH then
    Exit;

  SegmentCount := Length(Points) - 1;
  for I := 1 to SegmentCount - 1 do
  begin
    if not NormalizeVector(VFSub(Points[I], Points[I - 1]), DirPrevIn) then
      Continue;
    if not NormalizeVector(VFSub(Points[I + 1], Points[I]), DirNextOut) then
      Continue;

    PrevOut := VFScale(DirPrevIn, -1);
    AngleRad := Abs(ArcTan2(VFCross(PrevOut, DirNextOut), VFDot(PrevOut, DirNextOut)));
    if AngleRad < DEFAULT_MIN_ANGLE then
      Continue;

    TurnSign := VFCross(DirPrevIn, DirNextOut);
    if SameValue(TurnSign, 0.0, MIN_SEGMENT_LENGTH) then
      Continue;

    PrevOffsetPt := VFAdd(Points[I], VFScale(LeftNormal(DirPrevIn), HalfWidth));
    NextOffsetPt := VFAdd(Points[I], VFScale(LeftNormal(DirNextOut), HalfWidth));
    if LinesIntersection(PrevOffsetPt, DirPrevIn, NextOffsetPt, DirNextOut, Apex) then
      AppendMiterQuad(PrevOffsetPt, Apex, NextOffsetPt, Points[I], TurnSign);

    PrevOffsetPt := VFSub(Points[I], VFScale(LeftNormal(DirPrevIn), HalfWidth));
    NextOffsetPt := VFSub(Points[I], VFScale(LeftNormal(DirNextOut), HalfWidth));
    if LinesIntersection(PrevOffsetPt, DirPrevIn, NextOffsetPt, DirNextOut, Apex) then
      AppendMiterQuad(PrevOffsetPt, Apex, NextOffsetPt, Points[I], TurnSign);
  end;

  if Length(Extra) > 0 then
  begin
    BaseCount := Length(Polygons);
    SetLength(Polygons, BaseCount + Length(Extra));
    for I := 0 to High(Extra) do
      Polygons[BaseCount + I] := Extra[I];
  end;
end;

procedure BuildSolidButtMiterPolygons2(const Layer: TVFLineSolidLayer;
  const Points: TVFLinePolygon; out Polygons: TVFLinePolygonArray);
var
  HalfWidth: Double;
  I, N: Integer;
  DirPrevIn, DirNextOut, PrevOut: TPointF;
  AngleRad, TurnSign: Double;
  OffPrev, OffNext: TPointF;
  Apex: TPointF;
  LeftOutline, RightOutline: TVFLinePolygon;
  Poly: TVFLinePolygon;
  ForceBevel: Boolean;

  function OffsetPoint(const P, Dir: TPointF; const Sign: Double): TPointF; inline;
  begin
    Result := VFAdd(P, VFScale(LeftNormal(Dir), Sign * HalfWidth));
  end;

  function TryMiterPoint(const P: TPointF; const DirIn, DirOut: TPointF;
    const Sign: Double; out X: TPointF): Boolean;
  var
    A, C: TPointF;
  begin
    A := OffsetPoint(P, DirIn, Sign);
    C := OffsetPoint(P, DirOut, Sign);
    Result := LinesIntersection(A, DirIn, C, DirOut, X);
  end;

  procedure AddOutlinePoint(var Outline: TVFLinePolygon; const P: TPointF);
  var
    L: Integer;
  begin
    L := Length(Outline);
    if (L = 0) or (Abs(Outline[L - 1].X - P.X) > 1e-9) or (Abs(Outline[L - 1].Y - P.Y) > 1e-9) then
    begin
      SetLength(Outline, L + 1);
      Outline[L] := P;
    end;
  end;

begin
  Polygons := nil;
  if (Layer = nil) or (Length(Points) < 2) then
    Exit;
  if Layer.CapKind <> lckButt then
    Exit;

  HalfWidth := Max(MIN_SEGMENT_LENGTH, Layer.BaseThickness) * 0.5;
  if HalfWidth <= MIN_SEGMENT_LENGTH then
    Exit;

  ForceBevel := Layer.JoinKind <> ljkMiter;

  N := Length(Points);
  LeftOutline := nil;
  RightOutline := nil;

  // Start cap: use first segment direction
  if not NormalizeVector(VFSub(Points[1], Points[0]), DirNextOut) then
    Exit;
  AddOutlinePoint(LeftOutline, OffsetPoint(Points[0], DirNextOut, +1));
  AddOutlinePoint(RightOutline, OffsetPoint(Points[0], DirNextOut, -1));

  // Interior vertices
  for I := 1 to N - 2 do
  begin
    if not NormalizeVector(VFSub(Points[I], Points[I - 1]), DirPrevIn) then
      Continue;
    if not NormalizeVector(VFSub(Points[I + 1], Points[I]), DirNextOut) then
    begin
      AddOutlinePoint(LeftOutline, OffsetPoint(Points[I], DirPrevIn, +1));
      AddOutlinePoint(RightOutline, OffsetPoint(Points[I], DirPrevIn, -1));
      Continue;
    end;

    PrevOut := VFScale(DirPrevIn, -1);
    AngleRad := Abs(ArcTan2(VFCross(PrevOut, DirNextOut), VFDot(PrevOut, DirNextOut)));
    TurnSign := VFCross(DirPrevIn, DirNextOut);

    // Bevel-like corner for sharp/degenerate turns OR when JoinKind <> ljkMiter.
    // IMPORTANT: do not average offsets here (can collapse on near-180° turns).
    if ForceBevel or (AngleRad < DEFAULT_MIN_ANGLE) or SameValue(TurnSign, 0.0, MIN_SEGMENT_LENGTH) then
    begin
      AddOutlinePoint(LeftOutline, OffsetPoint(Points[I], DirPrevIn, +1));
      AddOutlinePoint(LeftOutline, OffsetPoint(Points[I], DirNextOut, +1));
      AddOutlinePoint(RightOutline, OffsetPoint(Points[I], DirPrevIn, -1));
      AddOutlinePoint(RightOutline, OffsetPoint(Points[I], DirNextOut, -1));
      Continue;
    end;

    // Miter corner
    if TryMiterPoint(Points[I], DirPrevIn, DirNextOut, +1, Apex) then
      AddOutlinePoint(LeftOutline, Apex)
    else
      AddOutlinePoint(LeftOutline, OffsetPoint(Points[I], DirPrevIn, +1));

    if TryMiterPoint(Points[I], DirPrevIn, DirNextOut, -1, Apex) then
      AddOutlinePoint(RightOutline, Apex)
    else
      AddOutlinePoint(RightOutline, OffsetPoint(Points[I], DirPrevIn, -1));
  end;

  // End cap: use last segment direction
  if not NormalizeVector(VFSub(Points[N - 1], Points[N - 2]), DirPrevIn) then
    Exit;
  AddOutlinePoint(LeftOutline, OffsetPoint(Points[N - 1], DirPrevIn, +1));
  AddOutlinePoint(RightOutline, OffsetPoint(Points[N - 1], DirPrevIn, -1));

  // Compose single polygon: left outline forward + right outline backward
  if (Length(LeftOutline) < 2) or (Length(RightOutline) < 2) then
    Exit;
  SetLength(Poly, Length(LeftOutline) + Length(RightOutline));
  for I := 0 to High(LeftOutline) do
    Poly[I] := LeftOutline[I];
  for I := 0 to High(RightOutline) do
    Poly[Length(LeftOutline) + I] := RightOutline[High(RightOutline) - I];

  SetLength(Polygons, 1);
  Polygons[0] := Poly;
end;

procedure BuildSolidPolygons(const Layer: TVFLineSolidLayer;
  const Points: TVFLinePolygon; out Polygons: TVFLinePolygonArray);
begin
  Polygons := nil;
  if Layer = nil then
    Exit;

  case Layer.CapKind of
    lckButt:
      case Layer.JoinKind of
        ljkBevel:
           BuildSolidButtPolygons(Layer, Points, Polygons);
        ljkMiter:
           BuildSolidButtMiterPolygons(Layer, Points, Polygons);
      else
        BuildSolidButtPolygons(Layer, Points, Polygons);
      end;
  else
    BuildSolidButtPolygons(Layer, Points, Polygons);
  end;
end;

end.
