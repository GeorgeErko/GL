unit ogcDrawerCanvas;

{$mode Delphi}{$H+}

interface

uses
 Classes, SysUtils, Graphics, ExtCtrls, ogcBasic, GR32;

type

 { TogsDrawerCanvas }

 TogsDrawerCanvas = class(TogsSpacer)
 private
  FOnUpdateImage: TNotifyEvent;
  procedure SetOnUpdateImage(AValue: TNotifyEvent);
 //
  function GetHeight: Integer; override;
  function GetWidth: Integer; override;
  procedure SetHeight(AValue: Integer); override;
  procedure SetWidth(AValue: Integer); override;
 protected
  procedure SetPen(AValue: TogsPen); override;
  procedure SetBrush(AValue: TogsBrush); override;
  function GetCanvas: TCanvas; override;
 public
  Image: TImage;
  constructor Create(ogsSelector_: TogsSelector; Image_: TImage; OnPaint_:TNotifyEvent);
  procedure Clear(AColor: Integer); override;
 //
  procedure UpdateImage;
  property OnUpdateImage: TNotifyEvent read FOnUpdateImage write SetOnUpdateImage;
 //
  procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); override;
  procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); override;
  procedure DrawCircle(XA, YA, Radius: Double); override;
 // рисовагние в системе координат Canvas
  procedure MoveTo(X, Y: Integer); override;
  procedure LineTo(X, Y: Integer); override;
 //
  property Width: Integer read GetWidth write SetWidth;
  property Height: Integer read GetHeight write SetHeight;
  function geoWidth: Double; override;
  function geoHeight: Double; override;
 //
  procedure BeginPaint; override;
  procedure EndPaint; override;
  procedure DrawTo(Image_: TCanvas; Rect: TRect); override;
 //
 end;

implementation uses ogcWriter, ogcMathUtils;

{ TogsDrawerCanvas }

procedure TogsDrawerCanvas.SetOnUpdateImage(AValue: TNotifyEvent);
begin
 FOnUpdateImage := AValue;
end;

function TogsDrawerCanvas.GetHeight: Integer;
begin
 Result := Image.Height;
end;

function TogsDrawerCanvas.GetWidth: Integer;
begin
 Result := Image.Width;
end;

procedure TogsDrawerCanvas.SetHeight(AValue: Integer);
begin
 Image.Height := AValue;
end;

procedure TogsDrawerCanvas.SetWidth(AValue: Integer);
begin
 Image.Width := AValue;
end;

function TogsDrawerCanvas.GetCanvas: TCanvas;
begin
 Result := Image.Canvas;
end;

procedure TogsDrawerCanvas.SetPen(AValue: TogsPen);
begin
 inherited SetPen(AValue);
 Image.Canvas.Pen.Color := AValue.penColor;
end;

procedure TogsDrawerCanvas.SetBrush(AValue: TogsBrush);
begin
 inherited SetBrush(AValue);
 Image.Canvas.Brush.Color := AValue.brColor;
end;

constructor TogsDrawerCanvas.Create(ogsSelector_: TogsSelector; Image_: TImage; OnPaint_: TNotifyEvent);
begin
 inherited Create(ogsSelector_, OnPaint_);
 Image := Image_;
 Image.Width := Image_.Width;
 Image.Height := Image_.Height;
end;

procedure TogsDrawerCanvas.Clear(AColor: Integer);
begin
 Image.Width := Image.Width;
 Image.Height := Image.Height;
 Image.Picture:=nil;
 Image.Canvas.Brush.Color := Color32(AColor);
 Image.Canvas.Rectangle(-2,-2,Image.Width+5,Image.Height+5);
end;

procedure TogsDrawerCanvas.UpdateImage;
begin
 If Assigned(OnUpdateImage) then OnUpdateImage(Self);
end;

procedure TogsDrawerCanvas.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
const C = 0;
var X_,Y_,X1_,Y1_:Double;
begin
//
 If Disable then exit;
 If not cutRequest then With ogsSelector do begin
  Image.Canvas.Pen.Color := Pen.penColor;
  Image.Canvas.MoveTo(XPix(X), YPix(Y));
  Image.Canvas.LineTo(XPix(X1), YPix(Y1));
  exit;
 end;
//
 X_:=X; Y_:=Y; X1_:=X1; Y1_:=Y1;
 with ogsSelector, activeRect do
  If pointVisible(X, Y) and pointVisible(X1, Y1) then begin
//   WriteIn(['allVis=',XPix(X_), YPix(Y_), XPix(X1_), YPix(Y1_), Image.Width, Image.Height]);
//   If (XPix(X_) > Self.Width) or (XPix(X1_) > Self.Width) or (YPix(Y_) > Self.Height) or (YPix(Y1_) > Self.Height) then exit;
//   If (XPix(X_)< 0) or (XPix(Y_)< 0) or (XPix(X1_)< 0) or (XPix(Y1_)< 0) then exit;

   Image.Canvas.Pen.Color := Pen.penColor;
   Image.Canvas.MoveTo(XPix(X_), YPix(Y_));
   Image.Canvas.LineTo(XPix(X1_), YPix(Y1_))
//   WriteIn(['end']);
  end else
  If lineVisible(X, Y, X1, Y1) then
   If cutLine(XMin+C, YMin+C, XMax-C, YMax-C, X_,Y_,X1_,Y1_) then begin
//    WriteIn(['Rect=', XMin, YMin, XMax, YMax, 'Coord=', XPix(X_), YPix(Y_), XPix(X1_), YPix(Y1_)]);
//    WriteIn(['cut=', XPix(X_), YPix(Y_), XPix(X1_), YPix(Y1_), Image.Width, Image.Height]);
    If (XPix(X_) > Self.Width) or (XPix(X1_) > Self.Width) or (YPix(Y_) > Self.Height) or (YPix(Y1_) > Self.Height) then exit;
    Image.Canvas.Pen.Color := Pen.penColor;
    Image.Canvas.MoveTo(XPix(X_), YPix(Y_));
    Image.Canvas.LineTo(XPix(X1_), YPix(Y1_))
//    WriteIn(['end']);
   end;
end;

procedure TogsDrawerCanvas.DrawPolyPolygon(Polygons: TogsCollection;
 polyRect: TogsRect);
var AllLin:Array[0..20000] of TPoint; AllPoly:Array[0..1000] of Integer;
    I, J: Integer;
    Poly: TogsCollection;
    PointCount, PolyCount: Integer;
begin
 If Disable then exit;
// заполняем Polygon
 PointCount := 0;
 With ogsSelector do
  For I := 0 to Polygons.Count - 1 do With TogsCollection(Polygons[I]) do begin
   AllPoly[I] := Count;
   For J := 0 to Count - 1 do With TogsDot(List[J]) do begin
    AllLin[PointCount].X := XPix(X);
    AllLin[PointCount].Y := YPix(Y);
    Inc(PointCount);
   end;
  end;
 Image.Canvas.Brush.Color := Brush.brColor;
 Image.Canvas.Polygon(AllLin, PointCount);
end;

procedure TogsDrawerCanvas.DrawCircle(XA, YA, Radius: Double);
var N: Integer = 25;
    I: Integer;
    Col: TogsCollection;
    D1, D2: TlDot;
begin
 If Disable then exit;
 Col := circle( XA, YA, Radius, N);
 For I := 0 to Col.Count - 2 do begin
  D1 := Col[I]; D2 := Col[I + 1];
  DrawLine(D1.XDot, D1.YDot, D2.XDot, D2.YDot);
 end;
 Col.Free;
end;

procedure TogsDrawerCanvas.MoveTo(X, Y: Integer);
begin
 Image.Canvas.MoveTo(X, Y);
end;

procedure TogsDrawerCanvas.LineTo(X, Y: Integer);
begin
 Image.Canvas.LineTo(X, Y);
end;

function TogsDrawerCanvas.geoWidth: Double;
begin
 Result := ogsSelector.activeRect.XMax - ogsSelector.activeRect.XMin;
end;

function TogsDrawerCanvas.geoHeight: Double;
begin
 Result := ogsSelector.activeRect.YMax - ogsSelector.activeRect.YMin;
end;

procedure TogsDrawerCanvas.BeginPaint;
begin
// not used
end;

procedure TogsDrawerCanvas.EndPaint;
begin
// not used
end;

procedure TogsDrawerCanvas.DrawTo(Image_: TCanvas; Rect: TRect);
begin
 Image_.CopyRect(Rect, Image.Canvas, Rect);
 Image_.Refresh;
end;

end.

