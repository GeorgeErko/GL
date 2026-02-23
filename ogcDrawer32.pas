unit ogcDrawer32;

{$mode Delphi}{$H+}

interface uses GR32, GR32_Image,
               GR32_Blend, VGR32_Lines, GR32_Polygons,
               Classes, SysUtils, Graphics, ogcBasic,  ExtCtrls;

type

 { TogsDrawer32 }

 TogsDrawer32 = class(TogsSpacer)
 private
  FOnUpdateImage: TNotifyEvent;
  fPenColor32: TColor32;
  fBrushColor32: TColor32;
  fPC: TPixelCombineEvent;
  fLine: TArrayOfFixedPoint;//TArrayOfFloatPoint;
  Line32: TLine32;
  Polygon32: TPolygon32;
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
  Image: TImage32;
  constructor Create(ogsSelector_: TogsSelector; Image_: TImage32; OnPaint_: TNotifyEvent);
  destructor Destroy; override;
  procedure Clear(AColor: Integer); override;
 //
  procedure UpdateImage;
  property OnUpdateImage: TNotifyEvent read FOnUpdateImage write SetOnUpdateImage;
 //
  procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); override;
  procedure DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean = True); override;
  procedure DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean = True); override;
  procedure DrawSect(Sect: TSect); override;
  procedure DrawCircle(XA, YA, Radius: Double); override;
  procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); override;
  procedure DrawBitmap(Bitmap: TogsGeometry; bmRect: TogsRect); override;
 // рисовагние в системе координат Canvas
  procedure MoveTo(X, Y: Integer); override;
  procedure LineTo(X, Y: Integer); override;
 //
  function geoWidth: Double; override;
  function geoHeight: Double; override;
 //
  procedure BeginPaint; override;
  procedure EndPaint; override;
  procedure DrawTo(Image_: TCanvas; Rect: TRect); override;
 //
  property penColor32  : TColor32 read fPenColor32 write fPenColor32;
  property brushColor32: TColor32 read fBrushColor32 write fBrushColor32;
  procedure mergeColor(F: TColor32; var B: TColor32; M: TColor32);
 end;

implementation uses ogcWriter, ogcMathUtils;

{ TogsDrawer32 }

constructor TogsDrawer32.Create(ogsSelector_: TogsSelector; Image_: TImage32; OnPaint_: TNotifyEvent);
begin
 inherited Create(ogsSelector_, OnPaint_);
 Image := Image_;
 Image.Bitmap.Width := Image.Width + 10;
 Image.Bitmap.Height := Image.Height + 10;
// Image.Bitmap.DrawMode := dmCustom;
// Image.Bitmap.CombineMode := cmBlend;
// Image.Bitmap.OnPixelCombine := mergeColor;
 SetLength(fLine, 2);
 Line32 := TLine32.Create;
 Polygon32 := TPolygon32.Create;
end;

destructor TogsDrawer32.Destroy;
begin
 inherited Destroy;
 Line32.Free;
 Polygon32.Free;
// !!!! не предусмотрено обнуление
// Pen.Free; Brush.Free;
end;

procedure TogsDrawer32.SetOnUpdateImage(AValue: TNotifyEvent);
begin
 FOnUpdateImage := AValue;
end;

function TogsDrawer32.GetHeight: Integer;
begin
 Result := Image.Height;
end;

function TogsDrawer32.GetWidth: Integer;
begin
 Result := Image.Width;
end;

procedure TogsDrawer32.SetHeight(AValue: Integer);
begin
 Image.Height := AValue;
 Image.Bitmap.Height := AValue + 10;
end;

procedure TogsDrawer32.SetWidth(AValue: Integer);
begin
 Image.Width := AValue;
 Image.Bitmap.Width := AValue + 10;
end;

procedure TogsDrawer32.SetPen(AValue: TogsPen);
begin
 inherited SetPen(AValue);
 Image.Bitmap.PenColor := Color32(AValue.penColor);
 fPenColor32 := Color32(AValue.penColor);
end;

procedure TogsDrawer32.SetBrush(AValue: TogsBrush);
begin
 inherited SetBrush(AValue);
 fBrushColor32 := Color32(AValue.brColor);
// WriteIn(['SetBr=', AValue.brColor]);
end;

function TogsDrawer32.GetCanvas: TCanvas;
begin
 Result := Image.Bitmap.Canvas;
end;

procedure TogsDrawer32.Clear(AColor: Integer);
begin
 Image.Bitmap.Clear(Color32(AColor));
end;

procedure TogsDrawer32.UpdateImage;
begin
 If Assigned(OnUpdateImage) then OnUpdateImage(Self);
 Image.Changed;
end;

procedure TogsDrawer32.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
const C = 0;
var X_,Y_,X1_,Y1_:Double;
    tmpLine: TArrayOfFloatPoint;
    I: Integer;
    Dashes: TArrayOfFloat;
    Poly: TArrayOfFloatPoint;
Procedure DrawL(Width: Single);
var I: Integer; X, Y: Double;
begin
// WriteIn(['St=',ogsSelector.memFreeStart]);
 If Disable then exit;
 With Line32 do begin //try
  EndStyle := esRounded;
  JoinStyle := jsRounded;
  LineWidth := Width;
  SetPoints(fLine);
 // Image.Bitmap.penColor := clBlue32;
 // WriteIn(['BegpenColor',Pen.penColor, Color32(Pen.PenColor),Color32(clLime)]);
 // WriteIn(['Draw']);
  Draw(Image.Bitmap, Width, Dashes, Color32(Pen.PenColor));
 // WriteIn(['EndpenColor',Pen.penColor]);
// except
  end;
// WriteIn(['Fin=',ogsSelector.memFreeFinish]);
end;
begin
// DisableIn;
// !!! не отображать линии < Delta
 If (abs(X1 - X) <= ogsSelector.PixelSize) and
     (abs(Y1 - Y) <= ogsSelector.PixelSize) then With ogsSelector do begin
      //fLine[0] := FixedPoint(XPix(X), YPix(Y));
      Image.Bitmap.PixelXS[XPix(X), YPix(Y)] := Color32(Pen.penColor);
     // WriteIn([XPix(X), YPix(Y), X, Y]);
      exit;
     end;
 If not cutRequest then With ogsSelector do begin
  fLine[0] := FixedPoint(XPix(X), YPix(Y));
  fLine[1] := FixedPoint(XPix(X1), YPix(Y1));
  DrawL(1);
  //Image.Bitmap.Line(XPix(X), YPix(Y), XPix(X1), YPix(Y1), fpenColor32);
  exit;
 end;
// With ogsSelector.activeRect do WriteIn(['Min-Max',XMin+C, YMin+C, XMax-C, YMax-C]);
 X_:=X; Y_:=Y; X1_:=X1; Y1_:=Y1;
 with ogsSelector, activeRect do
  If pointVisible(X, Y) and pointVisible(X1, Y1) then begin
    fLine[0] := FixedPoint(XPix(X), YPix(Y));
    fLine[1] := FixedPoint(XPix(X1), YPix(Y1));
   // Image.Bitmap.Line(XPix(X_), YPix(Y_),XPix(X1_),YPix(Y1_), fPenColor32);
  // WriteIn(['noCut',XPix(X_), YPix(Y_),XPix(X1_),YPix(Y1_)]);
   DrawL(1);
  // WriteIn(['end']);
  end else
 // If lineVisible(X, Y, X1, Y1) then
   If cutLine(XMin+C, YMin+C, XMax-C, YMax-C, X_,Y_,X1_,Y1_) then begin
   // SetLength(Poly,2);
   // Poly[0].X := XPix(X);Poly[1].X := XPix(X1);Poly[0].Y := YPix(Y);Poly[1].Y := YPix(Y1);
   // PolyLineFS(Image.Bitmap, Poly, fPenColor32, False, 1);
   // SetLength(Poly,0);
   // exit;
    fLine[0] := FixedPoint(XPix(X_), YPix(Y_));
    fLine[1] := FixedPoint(XPix(X1_), YPix(Y1_));
  //  Image.Bitmap.Line(XPix(X_), YPix(Y_),XPix(X1_),YPix(Y1_), fPenColor32);
  // WriteIn(['Cut=',XPix(X_), YPix(Y_),XPix(X1_),YPix(Y1_)]);
   DrawL(1);
  // WriteIn(['end']);
  end;
//  EnableIn;
end;

procedure TogsDrawer32.DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean);
var
 I: Integer;
 P0, P1: TogsDot;
begin
// WriteIn(['============================']);
 if Disable then Exit;
 if (Points = nil) or (Points.Count < 2) then Exit;
 for I := 0 to Points.Count - 2 do begin
  P0 := TogsDot(Points.Items[I]);
  P1 := TogsDot(Points.Items[I + 1]);
 // WriteIn(['DrawLine=',P0.fX, P0.fY, P1.fX, P1.fY, cutRequest, ogsSelector.fScale]);
  DrawLine(P0.fX, P0.fY, P1.fX, P1.fY, cutRequest);
 // P0.DrawPoint(Self);
 // P1.DrawPoint(Self);
 end;
end;

procedure TogsDrawer32.DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean);
var
 I: Integer;
 Part: TogsPolyCollection;
begin
 if Disable then Exit;
 if (Parts = nil) or (Parts.Count = 0) then Exit;
 for I := 0 to Parts.Count - 1 do begin
  Part := TogsPolyCollection(Parts[I]);
  DrawPolyline(Part, cutRequest);
 end;
end;

procedure TogsDrawer32.DrawSect(Sect: TSect);
begin
 If Disable then exit;
 With Sect do begin
  DrawLine(XMin, YMin, XMin, YMax);
  DrawLine(XMin, YMax, XMax, YMax);
  DrawLine(XMax, YMax, XMax, YMin);
  DrawLine(XMax, YMin, XMin, YMin);
 end;
end;

procedure TogsDrawer32.DrawCircle(XA, YA, Radius: Double);
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

procedure TogsDrawer32.DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect);
var I, J: Integer;
    Poly: TogsCollection;
    FillColor: TColor32;
Procedure DrawP;
begin
 If Disable then exit;
 With Polygon32 do begin
//  try
   FillMode:=pfAlternate;
   Closed:=True;
   FillColor := SetAlpha(Color32(Brush.brColor), $FF);
   DrawFill(Image.Bitmap, FillColor);
//  finally
   Clear;
 end;
//  end;
end;
begin
 // заполняем Polygon
// Polygon32.Clear;
 With ogsSelector do
 If ((polyRect.XMax - polyRect.XMin) <= PixelSize) and
     ((polyRect.YMax - polyRect.YMin) <= PixelSize) then begin
      //fLine[0] := FixedPoint(XPix(polyRect.XMin), YPix(polyRect.YMin));
      Image.Bitmap.PixelXS[XPix(polyRect.XMin), YPix(polyRect.YMin)] := Color32(Brush.Color);
      exit;
     end;
 With ogsSelector do
  For I := 0 to Polygons.Count - 1 do With TogsPolyCollection(Polygons[I]).Items do begin
   // WriteIn([I, TogsCollection(Polygons[I]).Count]);
   For J := 0 to Count - 1 do With TDot(List[J]) do begin
    Polygon32.Add(FixedPoint(XPix(X), YPix(Y)));
 //   Inc(PointCount);
   end;
   Polygon32.NewLine;
  end;
 DrawP;
end;

procedure TogsDrawer32.DrawBitmap(Bitmap: TogsGeometry; bmRect: TogsRect);
var R: TogsRect;
    Rect: TSect;
begin
 if (Bitmap = nil) then Exit;
 if bmRect = nil then begin
  Bitmap.Draw(Self);
  Exit;
 end;
// R := TogsRect.CreateAs(Bitmap.ogsSelector.ActiveRect);
// Bitmap.ogsSelector.ActiveRect := bmRect;
 Rect := Bitmap.ogsSelector.ActiveRect.GetSect;
// WriteIn(['bmRect=', bmRect]);
 Bitmap.ogsSelector.ActiveRect.SetSect(bmRect.GetSect);
 try
  Bitmap.Draw(Self);
 finally
  Bitmap.ogsSelector.ActiveRect.SetSect(Rect);
 // R.Free;
 end;
end;

procedure TogsDrawer32.MoveTo(X, Y: Integer);
begin
 Image.Bitmap.MoveTo(X, Y);
end;

procedure TogsDrawer32.LineTo(X, Y: Integer);
begin
 Image.Bitmap.PenColor := clRed32;
 Image.Bitmap.LineToS(X, Y);
end;

function TogsDrawer32.geoWidth: Double;
begin
 Result := ogsSelector.activeRect.XMax - ogsSelector.activeRect.XMin;
end;

function TogsDrawer32.geoHeight: Double;
begin
 Result := ogsSelector.activeRect.YMax - ogsSelector.activeRect.YMin;
end;

procedure TogsDrawer32.BeginPaint;
begin
 ogsSelector.BeginPaint;
// WriteIn(['pixelSize=',ogsSelector.PixelSize]);
 Image.Bitmap.BeginUpdate;
end;

procedure TogsDrawer32.EndPaint;
begin
 Image.Update;
 Image.Invalidate;
 Image.Bitmap.EndUpdate;
end;

procedure TogsDrawer32.DrawTo(Image_: TCanvas; Rect: TRect);
begin
 Image_.Clear;
 Image.Bitmap.DrawTo(Image_.Handle, Rect, Rect);
 Image_.Refresh;
end;

procedure TogsDrawer32.mergeColor(F: TColor32; var B: TColor32; M: TColor32);
begin
 // XOR cancels out on polygon fills because the rasterizer may touch a pixel multiple times.
 // Use normal alpha blending instead.
 B := BlendReg(F, B);
end;

end.

