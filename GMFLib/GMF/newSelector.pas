unit newSelector;

interface uses {$IFDEF WIN64}Windows,{$ENDIF}Collect, newSettings, Controls, Graphics {$IFDEF UNIX},Types, tmpPainter{$ENDIF};

 var
    { точности }
     Const_Of_DecimalHeight:Byte; // знаков после запятой для высот пикетов
     Const_Of_DecimalLength:Byte; // знаков после запятой для длин линий
     Const_Of_SqwearMetric :Byte; // в каких единицах измерения выдавать площади
     Const_Of_DecimalSqwear:Byte; // знаков после запятой для площадей
     Const_Of_AngleMetric  :Byte; // измерение углов до минут,секунд и т.п
     Const_Of_DecimalAngle :Byte; // измерение углов до минут c остатком
     Const_Of_DecimalCoord :Byte; // точность измерения координат
     Const_Of_CalcDirect   :Byte; // способ отсчета направлений
   { соотв. множители }
     Const_Of_PrecHeight:Integer;
     Const_Of_PrecLength:Integer;
     Const_Of_PrecSqwear:Integer;
     Const_Of_PrecCoord :Integer;
Const
    _LD = 15;
     Const_Meter=0;
     Const_Ga=1;
     Const_Seconds=0;
     Const_DecMinutes=1;
     Const_Minutes=2;
     Const_Direct=0;
     Const_Rumb=1;

Type
 TSect=packed record
   Case boolean of
    False:(Left,Top,Right,Bottom:Extended);
    True:(XA,YA,XB,YB:Extended);
  end;

 TShortSect=record
   Case boolean of
    False:(Left,Top,Right,Bottom:Double);
    True:(XA,YA,XB,YB:Double);
  end;

 PSect=^TSect;

 TRumb=record
   Dir:String;
   Angle:Double;
  end;

Const
  XYMax = MaxInt;
  XYMin = MaxInt;

Type

 { TMRect }
 TMRect = class
  XMin, YMin, XMax, YMax: double;
  Iter:0..1;
  Constructor Create;
  Constructor CreateAs(MRect_: TMRect);
  Procedure Clear;
  procedure Insert(X_, Y_: Double);
  function Visible(Sect: TSect): boolean;
  Function Sect: TSect;
 end;

 TUpdateProc=Procedure(Check:boolean=False) of object;

 TSelector = class(TTwgObject)
  GTwgForm:Pointer;
  GMemMakeIndex:Integer;
  GMemMake:AnsiString;
 //
  GNForm:TWinControl;
  GRect,GRect1:TSect;
  GPRect:TRect;
  GXMin,GYMin,GDx,GDy:Double;
  GScale:Double;
  GMS:Double;
  HObject,WObject:Double;
  GGraphSet:TGraphSet;
  GlobalSettings:TGlobalSettings;
  GLineCol,GSqwearCol,GPointCol:TSortedCollection;
  GCanvas:TCanvas;
  GFontColEx:Pointer;
  STSDrawing:boolean;
// Создание
  Constructor Create;
  Destructor Destroy; override;
// Сравнение
  Function  EqualPoints(D1,D2:Pointer):Boolean;
  Function  EqualAnyPoints(X,Y,X2,Y2:Double):Boolean;
  Function  EqualCoord(P1,P2:Double):Boolean;
// Видимость
  Function  PointVis(X,Y:Double):Boolean;
  Function  PointVis1(X,Y:Double):Boolean;
  Function  LineVis(XX,YY,XX1,YY1:Double):Boolean;
  Function  PointInSect(X,Y:Double;Sect:TSect):Boolean;
// Преобразования
  Function  YPix(YCoord:Double):Int64;
  Function  XPix(XCoord:Double):Int64;
  Function  YGeo(YCoord:Double):Double;
  Function  XGeo(XCoord:Double):Double;
 {}
  Function  XRasst(XCoord:Double):LongInt;
  Function  YRasst(YCoord:Double):Longint;
 {}
  Function  YGeoRasst(YCoord:Double):Double;
  Function  XGeoRasst(XCoord:Double):Double;
  Function  RealDouble(V:Double):Double;
  Function  RealInt(V:Double):Int64;
 {}
// Рисование
  Procedure DrawLineSys(XX,YY,XX1,YY1:Double);overload;
  Procedure PMoveTo(X,Y:Double);
  Procedure PLineTo(X,Y:Double);
  Procedure PRectEx2(X,Y:Double;V:Byte);
  Procedure PSetPixel(X,Y:Double);
// Перевод
  Function  DirectToRumb(Angle:Double):TRumb;
  Function  AngleToStr(Angle:Double;UseCalc:Boolean;Razd:String):String;
// Параметры координатной системы
  Procedure UpdateImage(CheckRange:boolean = false);
  Procedure SetParams;
  Procedure SetSelector;
  Function  HObj:Extended; // высота объекта в метрах
  Function  WObj:Extended; // длина объекта в метрах
  Procedure Move(Dx,Dy:Double);
  Procedure Zoom(X,Y,K:Double);
 end;

implementation uses EcDot, Intervals, SysUtils, Math, WPTForm0, WPTForm1;

{ TMrect }

constructor TMRect.Create;
begin
 Clear;
end;

procedure TMRect.Clear;
begin
 Iter:=0;
 XMin:=0;XMax:=0;YMin:=0;YMax:=0;
end;

constructor TMRect.CreateAs(MRect_: TMRect);
begin
 XMax:=MRect_.XMax;YMax:=MRect_.YMax;XMin:=MRect_.YMin;YMax:=MRect_.YMax;
 Iter:=MRect_.Iter;
end;

procedure TMRect.Insert(X_, Y_: Double);
begin
 If Iter = 0 then begin
  XMin:=X_;YMin:=Y_;XMax:=X_;YMax:=Y_;
  Iter:=1;
 end else begin
  if X_<XMin then XMin:=X_;
  if Y_<YMin then YMin:=Y_;
  if X_>XMax then XMax:=X_;
  if Y_>YMax then YMax:=Y_;
 end;
end;

function TMRect.Visible(Sect: TSect): boolean;
begin
 Result := True;
 If XMax < Sect.Left   then begin Result := False; exit;end;
 If XMin > Sect.Right  then begin Result := False; exit;end;
 If YMin > Sect.Top    then begin Result := False; exit;end;
 If YMax < Sect.Bottom then begin Result := False; exit;end;
end;

function TMRect.Sect: TSect;
begin
  Result.Left:=XMin;
  Result.Top:=YMax;
  Result.Right:=XMax;
  Result.Bottom:=YMin;
end;

{ TSelector }

constructor TSelector.Create;
begin
 GlobalSettings:=TGlobalSettings.Create();
end;

destructor TSelector.Destroy;
begin
 GlobalSettings.Free;
end;

function TSelector.EqualAnyPoints(X, Y, X2, Y2: Double): Boolean;
begin
 Result:=(Abs(X-X2)<1/Const_Of_PrecCoord) and (Abs(Y-Y2)<1/Const_Of_PrecCoord);
end;

function TSelector.EqualCoord(P1, P2: Double): Boolean;
begin
 Result:=(Abs(P1-P2)<1/Const_Of_PrecCoord);
end;

function TSelector.EqualPoints(D1, D2: Pointer): Boolean;
begin
 Result:=(Abs(TDot(D1).XDot-TDot(D2).XDot)<1/Const_Of_PrecCoord) and (Abs(TDot(D1).YDot-TDot(D2).YDot)<1/Const_Of_PrecCoord);
end;

Function TSelector.XRasst;
 begin
  XRasst:=Round(XCoord*GMs);
 end;

Function TSelector.YRasst;
 begin
  YRasst:=Round(YCoord*GMs);
 end;

function TSelector.XGeo(XCoord: Double): Double;
begin
 If Gms=0 then begin Result:=0;Exit;end;
 XGeo:=GXmin+GDx+XCoord/GMs;
end;

Function TSelector.XGeoRasst;
 begin
  If Gms=0 then begin Result:=0;Exit;end;
   XGeoRasst:=XCoord/GMs;
 end;

function TSelector.XPix(XCoord: Double): Int64;
begin
 XPix:=Round((XCoord-GXMin-GDx)*GMs);
end;

function TSelector.YGeo(YCoord: Double): Double;
begin
 If Gms=0 then begin Result:=0;Exit;end;
 YGeo:=({GPRect.Bottom-}YCoord)/GMs+GyMin+GDy;
end;

Function TSelector.YGeoRasst;
 begin
  If Gms=0 then begin Result:=0;Exit;end;
  YGeoRasst:=YCoord/GMs;
 end;

function TSelector.YPix(YCoord: Double): Int64;
begin
 YPix:={GPRect.Bottom-}Round(((YCoord-GyMin-GDy)*GMs));
end;

function TSelector.PointInSect(X, Y: Double; Sect: TSect): Boolean;
Const C=100;
begin
 With Sect do
  begin
   If (X>=Left) and (X<=Right) and
      (Y<=Bottom) and (Y>=Top) then PointInSect:=True else
                                    PointInSect:=False;
  end;
end;

Function TSelector.PointVis;
 begin
  With GRect do
   begin
    If (X>=Left) and (X<=Right) and
       (Y>=Bottom) and (Y<=Top) then PointVis:=True else
                                   PointVis:=False;
   end;
 end;

Function TSelector.PointVis1;
 begin
  With GRect1 do
   begin
    If (X>=Left) and (X<=Right) and
       (Y>=Bottom) and (Y<=Top) then PointVis1:=True else
                                     PointVis1:=False;
   end;
 end;

procedure TSelector.PRectEx2(X, Y: Double; V: Byte);
var XP,YP:LongInt;
begin
 XP:=XPix(X);
 YP:=YPix(Y);
  With GCanvas,GGraphSet do
   begin
    MoveTo(XP-V,YP-V);
    LineTo(XP+V,YP-V);
    LineTo(XP+V,YP+V);
    LineTo(XP-V,YP+V);
    LineTo(XP-V,YP-V);
  end;
end;

Procedure TSelector.PSetPixel;
 Procedure PRect1;
  var XP,YP:LongInt;RPoint:Integer;
      Br:THandle;R:TRect;
  begin
   XP:=XPix(X);
   YP:=YPix(Y);
   RPoint:=GlobalSettings.Settings.gsPointSize;
    If not GlobalSettings.Settings.gsFillPointCheck then With GCanvas do begin
     MoveTo(XP-RPoint,YP-RPoint);
     LineTo(XP+RPoint,YP-RPoint);
     LineTo(XP+RPoint,YP+RPoint);
     LineTo(XP-RPoint,YP+RPoint);
     LineTo(XP-RPoint,YP-RPoint);
    end else With GCanvas do begin
     Br:=SelectObject(Handle,CreateSolidBrush(GlobalSettings.Settings.gsFillPointColor));
      With R do begin Left:=XP-RPoint;Top:=YP-RPoint;Right:=XP+RPoint;Bottom:=YP+RPoint;
       Rectangle(Left,Top,Right+1,Bottom+1);
      end;
     DeleteObject(SelectObject(Handle,Br));
    end;
  end;
begin
 PRect1;
end;

function TSelector.RealDouble(V: Double): Double;
begin
 Result:=Round(V*Const_Of_PrecCoord)/Const_Of_PrecCoord;
end;

function TSelector.RealInt(V: Double): Int64;
begin
Result:=Round(V*Const_Of_PrecCoord);
end;

Function TSelector.LineVis(XX,YY,XX1,YY1:Double):Boolean;
var L,T,R,B:Double;
 begin
  LineVis:=True;
  If XX>XX1 then begin L:=XX1;R:=XX; end else begin L:=XX;R:=XX1;end;
  If YY>YY1 then begin T:=YY1;B:=YY; end else begin T:=YY;B:=YY1;end;
 With GRect do
  begin
   If R<Left then begin LineVis:=False;Exit;end;
   If L>Right then begin LineVis:=False;Exit;end;
   If T>Top then begin LineVis:=False;Exit;end;
   If B<Bottom then begin LineVis:=False;Exit;end;
  end;
 end;

function TSelector.AngleToStr(Angle: Double; UseCalc: Boolean;
  Razd: String): String;
var R:TRumb;
Function GrMin:String;
 var Gr,Min:String[10];Min1:Extended;
 begin
  Str(Trunc(Angle),Gr);
  Min1:=Abs((Angle-Trunc(Angle))*60);
  Str(Min1:3:0,Min);
    If Length(Min)=1 then Min:='0'+Min;
    Result:=Gr+Razd+Min;
   If Gr='0' then If Angle<0 then Result:='-'+Result;
 end;
Function GrMinSec:String;
 var Gr,Min:String[10];Min1:Extended;
 begin
  Str(Trunc(Angle),Gr);
  Min1:=Trunc((Angle-Trunc(Angle))*60);
  Str(Min1:-1:Const_Of_DecimalAngle,Min);
    Result:=Gr+Razd+Min;
   If Gr='0' then If Angle<0 then Result:='-'+Result;
 end;
Function GrMinsSec:String;
 var Gr,Min,Sec:String[10];Min1,SSec:Extended;
 begin
      Str(Trunc(Angle),Gr);
 Min1:=Abs(Trunc((Angle-Trunc(Angle))*60));
       SSec :=Abs(Trunc(Frac((Angle-Trunc(Angle))*60)*60));
 Str(Min1:-1:0,Min);
 Str(SSec:-1:0,Sec);
     If Length(Min)=1 then Min:='0'+Min;
     If Length(Sec)=1 then Sec:='0'+Sec;
   Result:=Gr+Razd+Min+Razd+Sec;
   If Gr='0' then If Angle<0 then Result:='-'+Result;
 end;
begin
 if UseCalc then
  begin
   R:=DirectToRumb(Angle);
   Angle:=R.Angle;
  end else
  begin
   R.Dir:='';
   R.Angle:=Angle;
  end;
  If Const_Of_AngleMetric=Const_Seconds then
   Result:=R.Dir+' '+GrMinSSec else
  If Const_Of_AngleMetric=Const_DecMinutes then
   Result:=R.Dir+' '+GrMinSec else
  If Const_Of_AngleMetric=Const_Minutes then
   Result:=R.Dir+' '+GrMin;
 Result:=Trim(Result);
end;

Function TSelector.DirectToRumb;
 begin
  if Const_Of_CalcDirect=Const_Rumb then
   begin
    if (Angle>90)and(Angle<180) then begin Angle:=-Angle+180;Result.Dir:='ЮВ';end else
    if (Angle>180)and(Angle<270) then begin Angle:=Angle-180;Result.Dir:='ЮЗ';end else
    if (Angle>270)and(Angle<360) then begin Angle:=-Angle+360;Result.Dir:='CЗ';end else
    if (Angle=0)or(Angle=360) then begin Angle:=0;Result.Dir:='C ' end else
    if (Angle=90) then begin Angle:=0;Result.Dir:='З ' end else
    if (Angle=180) then begin Angle:=0;Result.Dir:='Ю ' end else
    if (Angle=270) then begin Angle:=0;Result.Dir:='В ' end else Result.Dir:='CВ';
    Result.Angle:=Angle;
   end else
   begin
    Result.Dir:='';
    Result.Angle:=Angle;
   end;
 end;

Procedure TSelector.DrawLineSys(XX,YY,XX1,YY1:Double);
  Const C=100;
   var Vis1,Vis2:Boolean;
       XA,YA,XB,YB:Double;
       X,Y,X1,Y1:LongInt;
       jX,jY,jX1,jY1:int64;
   begin
{}
 If GCanvas = nil then exit;
// Inc(DrawLineCounter);
  If PointVis1(XX,YY) and PointVis1(XX1,YY1) then
  begin
      X:=XPix((XX));
      Y:=YPix((YY));
      X1:=XPix((XX1));
      Y1:=YPix((YY1));
      GCanvas.MoveTo(X,Y);GCanvas.LineTo(X1,Y1);
  end else
   With GRect do
  if Clip_Interval(Left-XGeoRasst(C),Bottom-YGeoRasst(C),Right+XGeoRasst(C),Top+YGeoRasst(C),XX,YY,XX1,YY1) then
     begin
{  If PointVis1(XX,YY) or PointVis1(XX1,YY1) then
  begin}
      X:=XPix((XX));
      Y:=YPix((YY));
      X1:=XPix((XX1));
      Y1:=YPix((YY1));
   //   Writeln(X,' ',Y,' ',X1,' ',Y1);
      GCanvas.MoveTo(X,Y);GCanvas.LineTo(X1,Y1);
     end;
end;

Procedure TSelector.PMoveTo;
 begin
  With GCanvas do
   MoveTo(XPix(X),YPix(Y));
 end;

Procedure TSelector.PLineTo;
 begin
//  Inc(DrawLineCounter);
  With GCanvas do
   LineTo(XPix(X),YPix(Y));
 end;

Procedure TSelector.SetParams;
var Kx,Ky,Mx,My:Double;
 begin
  TForm0(GTwgForm).hWndParent:=GNForm.Handle;
  GPRect:=GNForm.ClientRect;
  Kx:=(GPRect.Bottom/WObj);
  Ky:=(GPRect.Right/HObj);
  My:=(HObj/HObject);
  Mx:=(WObj/WObject);
  If Kx>Ky tHen GMs:=My else GMs:=Mx;
  If Kx>Ky tHen Kx:=Ky else Ky:=Kx;
    GMs:=GMs*Kx;
{ Промежуточная установка Selector }
  SetSelector;
  With GRect,TForm0(GTwgForm) do
   begin
	 Left  :=XXMin+GDX;
	 Bottom:=YYMin+GDY;
	 Right :=XGeo(GPRect.Right);
	 Top   :=YGeo(GPRect.Bottom);
   end;
{ Фиксируем параметры}
  SetSelector;
 end;

Procedure TSelector.SetSelector;
 Const C:Integer = 100;
 var B:Byte;TwgForm:TForm1;
 begin
  TwgForm:=GTwgForm;
  // UpdateImage:=UpdateImage;
  // UpdateCanvas:=UpdateCanvas;
  // SetActiveCursor:=SetActiveCursor;
  //  GetActiveCursor:=GetActiveCursor;
  //  SetOnPoint:=SetOnPoint;
  //  SetOnRect:=SetOnRect;
  //  GTwgForm:=TwgForm;
  { Построения }
   GMemMake:=TwgForm.MemMake;
   GMemMakeIndex:=TwgForm.MemMakeIndex;
   {}
   GGraphSet:=TwgForm.FGraphSet;
   {}
//    GDx:=GDx;GDy:=GDy;GMs:=GMs;
//    Writeln(Gdx:8:2,' ',Gdy:8:2,' ',Gms:8:2,' ',HObject:8:2,' ',WObject:8:2);
//    GRect:=FRect;
   GXMin:=TwgForm.XXMin;GYMin:=TwgForm.YYMin;
//    GRect:=FRect;
//    GPRect:=MRect;
   {}
   try
    GRect1.Left:=GRect.Left-XGeoRasst(C);
    GRect1.Bottom:=GRect.Bottom-YGeoRasst(C);
    GRect1.Right:=GRect.Right+XGeoRasst(C);
    GRect1.Top:=GRect.Top+YGeoRasst(C);
   Except
   end;
   {}
    GLineCol:=TwgForm.MkLib.LSLib;
    GSqwearCol:=TwgForm.MkLib.SSLib;
    GPointCol:=TwgForm.MkLib.PSLIb;
   {}
   //  GFontCollect:=TwgForm.Twigs.FontS;
   //  GFontSet    :=TwgForm.Twigs.FontSet;
   //  GPrn:= PrnRec;
   {}
   With TForm0(GTwgForm).About do
    begin
     Const_Of_DecimalCoord:=DecimalCoord;
     Const_Of_DecimalHeight:=DecimalHeight;
     Const_Of_DecimalLength:=DecimalLength;
     Const_Of_DecimalSqwear:=DecimalSqwear;
     Const_Of_SqwearMetric:=SqwearMetric;
     Const_Of_AngleMetric:=AngleMetric;
     Const_Of_DecimalAngle:=DecimalAngle;
     Const_Of_CalcDirect:=CalcDirect;
   {}
     Const_Of_PrecHeight:=Round(IntPower(10,DecimalHeight));
     Const_Of_PrecLength:=Round(IntPower(10,DecimalLength));
     Const_Of_PrecSqwear:=Round(IntPower(10,DecimalSqwear));
     Const_Of_PrecCoord :=Round(IntPower(10,DecimalCoord));
    {}
    end;
//  GScale:=Scale;
end;

procedure TSelector.UpdateImage(CheckRange: boolean);
begin
 //
end;

function TSelector.HObj: Extended;
begin
 With TForm0(GTwgForm) do
  Result:=abs(XXMax-XXMin);
 If Result=0 then Result:=0.01;
end;

function TSelector.WObj: Extended;
begin
 With TForm0(GTwgForm) do
  Result:=abs(YYMax-YYMin);
 If Result=0 then Result:=0.01;
end;

Procedure TSelector.Move(Dx,Dy:Double);
var W0,H0,WG,HG:Double;
begin
 GDx:=GDx+Dx;GDy:=GDy+Dy;
end;

Procedure TSelector.Zoom(X,Y,K:Double);
const UMax=0.01;
var CKU:Single;F:Byte;XX,YY,Dxx,Dyy,Dxx1,Dyy1:Double;
begin
 If GGraphSet.Ku=0 then Exit;
// LockImage:=False;
 F:=0;
  CKU:=K;
   Dxx:=XGeo(X)-GPRect.Left;Dyy:=YGeo(Y)-GPRect.Bottom;
   XX:=XGeo(X);YY:=YGeo(Y);
  {}
   If HObject/CKu<UMax then exit;
   If WObject/CKu<UMax then exit;
  // UndoSave
// if not MButtonDown then If TwgForm.Undo<>nil then TUndo(TwgForm.Undo).AddUndoItem(TUndoItem.Create(TwgForm));
  //
   HObject:=HObject/CKu;
   WObject:=WObject/CKu;
   GDx:=XX-WObject/2-TForm0(GTwgForm).XXMin;
   GDy:=YY-HObject/2-TForm0(GTwgForm).YYMin;
    SetParams;
   Dxx1:=XGeo(GNForm.Width/2)-GPRect.Left;Dyy1:=YGeo(GNForm.Height/2)-GPRect.Bottom;
   GDx:=GDX+(Dxx-Dxx1);GDy:=GDy+(Dyy-Dyy1);
    SetParams;
    GDx:=GDx+XGeoRasst(-X+XPix(XX));GDy:=GDy+YGeoRasst(-Y+YPix(YY));
//   Writeln(FDx,' ',FDy);
    SetParams;
//  UpdateImage(False);
end;

initialization
end.
