unit ogcDrawerGLCanvas;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils, ogcBasic, Graphics, ExtCtrls, GR32, OpenGLCanvas, OpenGLPanel;

type

 { TogsDrawerCanvas }

 { TogsDrawerGL }

 TogsDrawerGL = class(TogsDrawer)
 private
  fOnUpdateImage: TNotifyEvent;
  procedure SetOnUpdateImage(AValue: TNotifyEvent);
 //
  function GetHeight: Integer; override;
  function GetWidth: Integer; override;
  procedure SetHeight(AValue: Integer); override;
  procedure SetWidth(AValue: Integer); override;
  procedure SetPen(AValue: TogsPen); override;
  function GetCanvas: TCanvas; override;
 public
  Image: TOpenGLCanvas;
  constructor Create(ogsSelector_: TogsSelector; Image_: TOpenGLCanvas; OnPaint_: TNotifyEvent);
  procedure Clear(AColor: Integer); override;
 //
  procedure UpdateImage;
  property OnUpdateImage: TNotifyEvent read FOnUpdateImage write SetOnUpdateImage;
 //
  procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); override;
 // рисование в системе координат Canvas
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
  procedure DrawTo(Image_: TCanvas; Rect: TRect); override; overload;
  procedure DoOnPaint(Sender: TObject); override;
 //
 end;

implementation uses ogcWriter;

{ TogsDrawerCanvas }

procedure TogsDrawerGL.SetOnUpdateImage(AValue: TNotifyEvent);
begin
 if FOnUpdateImage=AValue then Exit;
 FOnUpdateImage:=AValue;
end;

function TogsDrawerGL.GetHeight: Integer;
begin
 Result := Image.Height;
end;

function TogsDrawerGL.GetWidth: Integer;
begin
 Result := Image.Width;
end;

procedure TogsDrawerGL.SetHeight(AValue: Integer);
begin
 Image.Height := AValue;
end;

procedure TogsDrawerGL.SetWidth(AValue: Integer);
begin
 Image.Width := AValue;
end;

procedure TogsDrawerGL.SetPen(AValue: TogsPen);
begin
 inherited SetPen(AValue);
 Image.Canvas.Pen.Color := AValue.penColor;
end;

function TogsDrawerGL.GetCanvas: TCanvas;
begin
 Result := Image.Canvas;
end;

constructor TogsDrawerGL.Create(ogsSelector_: TogsSelector; Image_: TOpenGLCanvas; OnPaint_:TNotifyEvent);
begin
 inherited Create(ogsSelector_, OnPaint_);
 Image := Image_;
 Image.Width := Image_.Width;
 Image.Height := Image_.Height;
 Image.OnPaint := OnPaint_;;
end;

procedure TogsDrawerGL.Clear(AColor: Integer);
begin
// oglcClearOrtho2D(Image.ClientRect, ColorToRGB(AColor));
// exit;
 Image.Width := Image.Width;
 Image.Height := Image.Height;
 Image.Canvas.Brush.Color := Color32(AColor);
 Image.Canvas.Rectangle(-2,-2,Image.Width+5,Image.Height+5);
end;

procedure TogsDrawerGL.UpdateImage;
begin
 If Assigned(OnUpdateImage) then OnUpdateImage(Self);
end;

procedure TogsDrawerGL.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
const C = 0;
var X_,Y_,X1_,Y1_:Double;
begin
//
 If not cutRequest then With ogsSelector do begin
 // Image.Canvas.Pen.Color := clBlue;
  Image.Canvas.MoveTo(XPix(X), YPix(Y));
  Image.Canvas.LineTo(XPix(X1), YPix(Y1));
  exit;
 end;
//
 X_:=X; Y_:=Y; X1_:=X1; Y1_:=Y1;
 with ogsSelector, activeRect do
  If pointVisible(X, Y) and pointVisible(X1, Y1) then begin
   Image.Canvas.MoveTo(XPix(X_), YPix(Y_));
   Image.Canvas.LineTo(XPix(X1_), YPix(Y1_));
  // WriteIn(['endr']);
  end else
  If lineVisible(X, Y, X1, Y1) then
   If cutLine(XMin+C, YMin+C, XMax-C, YMax-C, X_,Y_,X1_,Y1_) then begin
//    If (XPix(X_) > Self.Width) or (XPix(X1_) > Self.Width) or (YPix(Y_) > Self.Height) or (YPix(Y1_) > Self.Height) then exit;
    Image.Canvas.MoveTo(XPix(X_), YPix(Y_));
    Image.Canvas.LineTo(XPix(X1_), YPix(Y1_));
   end;
end;

procedure TogsDrawerGL.MoveTo(X, Y: Integer);
begin
 Image.Canvas.MoveTo(X, Y);
end;

procedure TogsDrawerGL.LineTo(X, Y: Integer);
begin
 Image.Canvas.LineTo(X, Y);
end;

function TogsDrawerGL.geoWidth: Double;
begin
 Result := ogsSelector.activeRect.XMax - ogsSelector.activeRect.XMin;
end;

function TogsDrawerGL.geoHeight: Double;
begin
 Result := ogsSelector.activeRect.YMax - ogsSelector.activeRect.YMin;
end;

procedure TogsDrawerGL.BeginPaint;
begin
// oglcClearOrtho2D(Image.FControl.ClientRect, 0);
end;

procedure TogsDrawerGL.EndPaint;
begin
// TOpenGLPanel(Image.FControl).SwapBuffers;
end;

procedure TogsDrawerGL.DrawTo(Image_: TCanvas; Rect: TRect);
begin
// Image.FControl.DrawTo(0, 0, Image_.Picture);
end;

procedure TogsDrawerGL.DoOnPaint(Sender: TObject);
begin
 inherited DoOnPaint(Sender);
end;

end.

