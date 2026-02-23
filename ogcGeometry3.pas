unit ogcGeometry3;

{$mode Delphi}

interface

uses Classes, SysUtils, ogcBasic, ogcMathUtils, ogcGeometry;

{ TogsEdge }
type
 TogsEdge = class(TogsLineString)
 private
  function GetA: TogsDot;
  function GetB: TogsDot;
 public
  constructor Create(ogsSelector_: TogsSelector; ArcParams: TArcRec);
  destructor Destroy; override;
 //
  property A: TogsDot read GetA;
  property B: TogsDot read GetB;
 end;

{ TogsArc }

 TogsArc = class(TogsEdge)
 private
  function _Length: Double; override;
 public
  Bulge: Double;
  C, D: TogsDot;
  constructor Create(ogsSelector_: TogsSelector; ArcParams: TArcRec);
  constructor CreateAs(ogsObject: TogsBasic); override;
  destructor Destroy; override;
 // временно в public
  function ArcParams: TArcRec;
  procedure CreateVertexes;
  function Radius: Double;
  function getogsRect: TogsRect; override;
 //
  function Calculate(Action: TCalcActionSet): Integer; override;
 // рисование
  procedure Draw(Drawer: TogsDrawer); override;
 // захват
  function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
 end;

implementation

{ TogsEdge }

constructor TogsEdge.Create(ogsSelector_: TogsSelector; ArcParams: TArcRec);
begin
 inherited Create(ogsSelector_);
 With ArcParams do
  If Bulge = 0 then begin
   AddPoint(AX, AY, AZ);
   AddPoint(BX, BY, BZ);
  end;
end;

destructor TogsEdge.Destroy;
begin
 inherited Destroy;
end;

function TogsEdge.GetA: TogsDot;
begin
 Result := Point[0];
end;

function TogsEdge.GetB: TogsDot;
begin
 Result := Point[Count - 1];
end;

{ TogsArc }

function TogsArc._Length: Double;
var A1, A2, A3:Double;
begin
 A1 := Direct_Angle(C.fX, C.fY, A.X, A.Y);
 A2 := Direct_Angle(C.fX, C.fY, B.fX, B.fY);
 A3 := A1 - A2;
 If A3 < 0 then A3 := 2 * Pi + A3 else If A3 > 2 * Pi then A3 := A3 - 2 * Pi;
 Result:=A3 * Radius;
end;

constructor TogsArc.Create(ogsSelector_: TogsSelector; ArcParams: TArcRec);
begin
 inherited Create(ogsSelector_, ArcParams);
 With ArcParams do begin
  Self.Bulge := Bulge;
 // расчет точки D
 // D := TogsDot.Create(DX, DY, DZ);
 // расчитываем центр дуги окружности
 // C := TogsDot.Create(0, 0);
 // solving_arc_circle(fX, fY, B.fX, B.fY, D.fX, D.fY, C.fX, C.fY);
 // расчет точек
  AddPoint(AX, AY, AZ);
  // CreateVertexes;
  AddPoint(BX, BY, BZ);
 end;
end;

constructor TogsArc.CreateAs(ogsObject: TogsBasic);
begin
 if not (ogsObject is TogsArc) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 Create(ogsObject.ogsSelector, TogsArc(ogsObject).ArcParams);
// CreateVertexes;
end;

destructor TogsArc.Destroy;
begin
 inherited Destroy;
end;

function TogsArc.ArcParams: TArcRec;
var A, B: TogsDot;
begin
 With Result do begin
  AX := A.X; AY := A.Y; AZ := A.Z; BX := B.X; BY := B.Y; BZ := B.Z;
  Bulge := Self.Bulge;
 end;
end;

procedure TogsArc.CreateVertexes;
const qCount = 26;
var I, Quants: Integer; Col: TogsCollection;
begin
 Clear;
//
 Quants := qCount;
 Col := arc_Circle3(C.X, C.Y, A.X, A.Y, B.X, B.Y, Quants);
 For I := 0 to Col.Count - 1 do
  AddPoint(TlDot(Col[I]).XDot, TlDot(Col[I]).YDot, 0);
 Col.Free;
end;

function TogsArc.Radius: Double;
begin
 Result := Sqrt(Sqr(A.X - C.fX ) + Sqr(A.Y - C.fY));
end;

function TogsArc.getogsRect: TogsRect;
begin
 Result := ogsRect;
end;

function TogsArc.Calculate(Action: TCalcActionSet): Integer;
begin
 Result := inherited Calculate(Action);
end;

procedure TogsArc.Draw(Drawer: TogsDrawer);
var I: Integer;
begin
 Draw(Drawer);
 Drawer.DrawMarker(A.X, A.Y);
 Drawer.DrawMarker(B.X, B.Y);
 Drawer.DrawMarker(C.X, C.Y);
 Drawer.DrawMarker(D.X, D.Y);
end;

function TogsArc.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var X1, Y1, Delta: Double; Dist: Integer;
begin
// захват по траектории дуги
 Result := False;
 If not (ckLine in Params.CaptureFor) then exit;
 Delta := ogsSelector.geoDist(5);
 If not ogsRect.PointIn(X_,Y_,Delta) then exit;
 Dist := ogsSelector.pixDist(dist_to_arc(C.fX, C.fY, A.fX, A.fY, B.fX, B.fY, X_, Y_, X1 , Y1));
 If (Dist >= 0 ) and (Dist <= Params.CaptureParam) then begin
  Params.resCapture := Dist;
  Params.resCaptureOf := ckLine;
  Params.resObject := Self;
  Result := True;
 end;
end;

end.

