unit ogcGeometry2;

{$mode Delphi}

interface

uses Classes, SysUtils, Graphics,
      ogcBasic, ogcGeometry, ogcMathUtils, gmfGeometry,
       ogcArcs;

type

 TgmfEdge = class(TogsEdge)
 end;

 { TgmfMultiLine }

 TgmfMultiLine = class(TogsLineString)
 private
  fLength: Double;
  fSign: TgmfLineType;
  fScale,
  fWidth: Single;
  function GetLine(Index: Integer): TogsEdge;
  function _Length (): Double; override;
  function GetSign: Pointer; override;
  procedure SetSign(AValue: Pointer); override;
  procedure SetLineType(AValue: TgmfLineType);
 public
  class function GeometryType: String; override;
  constructor Create(ogsSelector_: TogsSelector);
  constructor Load(Stream: TogsStream); override;
  procedure Store(Stream: TogsStream); override;
 //
  property LineType: TgmfLineType read fSign write SetLineType;
  property Scale: Single read fScale write fScale;
  property Width: Single read fWidth write fWidth;
 //
  procedure AddPoint(P: TogsDot); overload;
 //
  property Length: Double read _Length;
  function StartPoint (): TogsDot; override;
  function EndPoint (): TogsDot; override;
  function IsClosed (): Integer; override;
  function IsRing (): Integer; override;
 //
  property Line[Index: Integer]: TogsEdge read GetLine; default;
 //
  function Calculate(Action: TCalcActionSet): Integer; override;
 // отрисовка
  procedure Draw(Drawer: TogsDrawer); override;
 // захват
  function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
 //
//   function UpdateSpatialProperties(out spatialProps: TogsProp): Integer; override;
 end;

implementation uses ogcWriter;

{ TgmfMultiLine }

function TgmfMultiLine._Length: Double;
var I: Integer;
begin
 Result := 0;
 For I := 0 to List.Count - 1 do
  Result := Result + Point[I]._Length;
end;

function TgmfMultiLine.GetLine(Index: Integer): TogsEdge;
begin
 Result := List.Items[Index];
end;

function TgmfMultiLine.GetSign: Pointer;
begin
 Result := Sign;
end;

procedure TgmfMultiLine.SetSign(AValue: Pointer);
 var I: Integer;
begin
 fSign := AValue;
 For I := 0 to Count - 1 do Line[I].Sign := AValue;
end;

procedure TgmfMultiLine.SetLineType(AValue: TgmfLineType);
begin
 SetSign(AValue);
end;

class function TgmfMultiLine.GeometryType: String;
begin
 Result := 'MultiLine';
end;

function CheckogsEdgeType(P: TogsBasic): Boolean;
begin
 Result := (P is TogsEdge) or (P is TogsArc);
end;

constructor TgmfMultiLine.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 Items.checkTypeProc := @CheckogsEdgeType;
end;

constructor TgmfMultiLine.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
end;

procedure TgmfMultiLine.Store(Stream: TogsStream);
begin
 inherited Store(Stream);
end;

procedure TgmfMultiLine.AddPoint(P: TogsDot);
begin
 inherited AddPoint(P);
 ogsRect.Insert(P.StartPoint.fX, P.StartPoint.fY);
 ogsRect.Insert(P.EndPoint.fX, P.EndPoint.fY);
end;

function TgmfMultiLine.StartPoint: TogsDot;
begin
 Result := Point[0];
end;

function TgmfMultiLine.EndPoint: TogsDot;
begin
 Result := Point[Count - 1].EndPoint;
end;

function TgmfMultiLine.IsClosed: Integer;
begin
 Result := inherited IsClosed;
end;

function TgmfMultiLine.IsRing: Integer;
begin
// !!! проверить
 Result := inherited IsRing;
end;

function TgmfMultiLine.Calculate(Action: TCalcActionSet): Integer;
var I: Integer; P1, P2: TogsDot;
begin
 Result := 0 ;
 If calcLength in Action then begin
  fLength := 0;
  For I := 0 to List.Count - 1 do fLength := fLength + Point[I]._Length;
  Result := 1;
 end;
 If calcbBox in Action then begin
  ogsRect.Clear;
  For I := 0 to List.Count - 1 do
  If Point[I] is TogsArc then begin
   Point[I].Calculate(Action);
   ogsRect.InsertRect(TogsArc(Point[I]).ogsRect)
  end else begin
   ogsRect.Insert(Point[I].X, Point[I].Y);
   ogsRect.Insert(Point[I].EndPoint.X, Point[I].EndPoint.Y);
  end;
 end;
end;

procedure TgmfMultiLine.Draw(Drawer: TogsDrawer);
var I: Integer;
    Pen: TogsPen;
begin
 If Selected then
  Pen := Drawer.SelectPen(TogsPen.Create(clLime, 0, nil)) else
  Pen := Drawer.SelectPen(TogsPen.Create(Color, 0, nil));
 try
  For I := 0 to List.Count - 1 do
   Point[I].Draw(Drawer);
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
 end;
end;

function TgmfMultiLine.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
begin
 For I := 0 to List.Count - 1 do
  If Point[I].SelectByPoint(X_, Y_, Params) then begin
   WriteIn(['I=', Point[I].ClassName]);
   Result := True;
   exit;
  end;
 Result := False;
end;

end.

