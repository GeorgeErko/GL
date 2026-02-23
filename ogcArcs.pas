unit ogcArcs;

{$mode Delphi}

interface

uses Classes, SysUtils, ogcBasic, ogcGeometry, ogcMathUtils;

{ TogsEdge }

type
 TogsEdge = class(TogsDot)
 private
  fogsSelector: TogsSelector;
  function GetA: TogsDot;
  function GetogsSelector: TogsSelector; override;
  procedure SetogsSelector(ogsSelector_: TogsSelector); override;
  function _Length: Double; override;
 public
  B: TogsDot;
  constructor Create(ogsSelector_: TogsSelector; X_, Y_, Z_, X1_, Y1_, Z1_: Double);
  constructor CreateAs(ogsObject: TogsBasic); override;
  destructor Destroy; override;
 //
  property A: TogsDot read GetA;
 // ф-ции TogsGeometry
  property Length: Double read _Length;
  function StartPoint (): TogsDot; override;
  function EndPoint (): TogsDot; override;
  // рисование
  procedure Draw(Drawer: TogsDrawer); override;
  // захват
  function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
 end;

 { TogsCircle }

 TogsCircle = class(TogsEdge)
  LineString: TogsLineString;
  constructor Create(ogsSelector_: TogsSelector; X_, Y_, Z_, X1_, Y1_, Z1_: Double);
  constructor CreateAs(ogsObject: TogsBasic); override;
  destructor Destroy; override;
 //
  procedure CreateVertexes;
  function Radius: Double;
 end;

 { TogsArc }

 TogsArc = class(TogsEdge)
 private
  function _Length: Double; override;
 public
  C, D: TogsDot;
  LineString: TogsLineString;
  constructor Create(ogsSelector_: TogsSelector; ArcParams: TArcRec);
  constructor CreateAs(ogsObject: TogsBasic); override;
  destructor Destroy; override;
 // ф-ции TogsGeometry
  property Length: Double read _Length;
 //
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

constructor TogsEdge.Create(ogsSelector_: TogsSelector; X_,Y_,Z_,X1_,Y1_,Z1_: Double);
begin
 fogsSelector := ogsSelector_;
 inherited Create(X_,Y_,Z_);
 B := TogsDot.Create(X1_,Y1_,Z1_);
end;

constructor TogsEdge.CreateAs(ogsObject: TogsBasic);
begin
 if not (ogsObject is TogsEdge) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject as TogsDot);
 B := TogsDot.CreateAs(TogsEdge(ogsObject).B);
 fOgsSelector := TogsEdge(ogsObject).ogsSelector;
end;

destructor TogsEdge.Destroy;
begin
 inherited Destroy;
 B.Free;
end;

function TogsEdge.GetogsSelector: TogsSelector;
begin
 Result := fogsSelector;
end;

procedure TogsEdge.SetogsSelector(ogsSelector_: TogsSelector);
begin
 fogsSelector := ogsSelector_;
end;

function TogsEdge.GetA: TogsDot;
begin
 Result := StartPoint;
end;

function TogsEdge._Length: Double;
begin
 Result := ogcMathUtils.Distance(fX, fY, B.fX, B.fY);
end;

function TogsEdge.StartPoint: TogsDot;
begin
 Result := TogsDot(Self);
end;

function TogsEdge.EndPoint: TogsDot;
begin
 Result := TogsDot(B);
end;

procedure TogsEdge.Draw(Drawer: TogsDrawer);
begin
 with ogsSelector, activeRect do
  Drawer.DrawLine(Self, B, not (pointVisible(X, Y) and pointVisible(B.X, B.Y)));
end;

function TogsEdge.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var PX, PY: Double; Dist: Integer;
begin
 Result:= False;
 If ckLine in Params.CaptureFor then begin
 //
   Dist := ogsSelector.pixDist(Dist_Point_Edge(X_,Y_, X, Y, B.X, B.Y, PX, PY));
   If Dist <= Params.CaptureParam then begin
    Params.resCapture := Dist;
    Params.resCaptureOf := ckLine;
    Params.resObject := Self;
    Result := Params.resCapture <= Params.CaptureParam;
    exit;
   end;
 end;
end;

{ TogsCircle }

constructor TogsCircle.Create(ogsSelector_: TogsSelector; X_,Y_,Z_,X1_,Y1_,Z1_: Double);
begin
 inherited Create(ogsSelector_,X_,Y_,Z_,X1_,Y1_,Z1_);
 LineString := TogsLineString.Create(ogsSelector_);
end;

constructor TogsCircle.CreateAs(ogsObject: TogsBasic);
begin
 inherited CreateAs(ogsObject);
end;

destructor TogsCircle.Destroy;
begin
 inherited Destroy;
end;

procedure TogsCircle.CreateVertexes;
const qCount = 52;
var Col: TogsCollection; I,Quants: Integer; D1: TDot;
begin
 LineString.Clear;
//
 Quants := qCount;
 Col := Circle2(A.fX, A.fY, B.fX, B.fY, Radius, Quants);
//
 For I := 0 to Col.Count-1 do
  LineString.AddPoint(TlDot(Col[I]).XDot, TlDot(Col[I]).YDot, 0);
 Col.Free;
end;

function TogsCircle.Radius: Double;
begin
 Result := Sqrt(Sqr(fX - B.fX ) + Sqr(fY - B.fY));
end;

{ TogsArc }

function TogsArc._Length: Double;
var A1, A2, A3:Double;
begin
 A1 := Direct_Angle(C.fX, C.fY, fX, fY);
 A2 := Direct_Angle(C.fX, C.fY, B.fX, B.fY);
 A3 := A1 - A2;
 If A3 < 0 then A3 := 2 * Pi + A3 else If A3 > 2 * Pi then A3 := A3 - 2 * Pi;
 Result:=A3 * Radius;
end;

constructor TogsArc.Create(ogsSelector_: TogsSelector; ArcParams: TArcRec);
begin
 With ArcParams do begin
  inherited Create(ogsSelector_, AX, AY, AZ, BX, BY, BZ);
  D := TogsDot.Create(DX, DY, DZ);
 // расчитываем центр дуги окружности
  C := TogsDot.Create(0, 0);
  solving_arc_circle(fX, fY, B.fX, B.fY, D.fX, D.fY, C.fX, C.fY);
 //
  LineString := TogsLineString.Create(ogsSelector_);
 end;
end;

constructor TogsArc.CreateAs(ogsObject: TogsBasic);
var Obj: TogsArc;
begin
 if not (ogsObject is TogsEdge) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Obj := TogsArc(ogsObject);
 C := TogsDot.CreateAs(Obj.C);
 D := TogsDot.CreateAs(Obj.D);
 CreateVertexes;
end;

destructor TogsArc.Destroy;
begin
 inherited Destroy;
 // B.Free;
 D.Free; C.Free;
 LineString.Free;
end;

procedure TogsArc.CreateVertexes;
const qCount = 26;
var I, Quants: Integer; Col: TogsCollection;
begin
 LineString.Clear;
//
 Quants := qCount;
 Col := arc_Circle3(C.X, C.Y, fX, fY, B.X, B.Y, Quants);
 For I := 0 to Col.Count - 1 do
  LineString.AddPoint(TlDot(Col[I]).XDot, TlDot(Col[I]).YDot, 0);
 Col.Free;
end;

function TogsArc.Radius: Double;
begin
 Result := Sqrt(Sqr(fX - C.fX ) + Sqr(fY - C.fY));
end;

function TogsArc.getogsRect: TogsRect;
begin
 Result := LineString.ogsRect;
end;

function TogsArc.Calculate(Action: TCalcActionSet): Integer;
begin
 Result := LineString.Calculate(Action);
end;

procedure TogsArc.Draw(Drawer: TogsDrawer);
var I: Integer;
begin
 LineString.Draw(Drawer);
 Drawer.DrawMarker(Self.X, Self.Y);
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
 Delta := LineString.ogsSelector.geoDist(5);
 If not LineString.ogsRect.PointIn(X_,Y_,Delta) then exit;
 Dist := ogsSelector.pixDist(dist_to_arc(C.fX, C.fY, fX, fY, B.fX, B.fY, X_, Y_, X1 , Y1));
 If (Dist >= 0 ) and (Dist <= Params.CaptureParam) then begin
  Params.resCapture := Dist;
  Params.resCaptureOf := ckLine;
  Params.resObject := Self;
  Result := True;
 end;
end;

end.

