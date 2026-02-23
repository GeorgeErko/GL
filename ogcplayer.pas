unit ogcPlayer;

{$mode Delphi}

interface

uses Classes, SysUtils, Graphics, ogcBasic;

const
  ID_CreatePen   : byte = 1;
  ID_CreateBrush : byte = 2;
  ID_DrawLine    : byte = 3;
  ID_DrawPolygon : byte = 4;
  ID_DrawPolyline: byte = 5;
  ID_DrawBitmap  : byte = 6;

type
// разобраться, нужен ли отдельный класс для pen-brush

  { TgrCreatePen }

  TgrCreatePen = class(TogsPen)
   class function ObjectID: Integer; override;
   constructor Create(Pen: TogsPen);
   procedure Play(Drawer: TogsDrawer; playRect: TogsRect = nil); override;
   procedure Store(Stream: TogsStream); override;
   constructor Load(Stream: TogsStream); override;
  end;

  { TgrCreateBrush }

  TgrCreateBrush = class(TogsBrush)
   class function ObjectID: Integer; override;
   constructor Create(Brush: TogsBrush);
   procedure Play(Drawer: TogsDrawer; playRect: TogsRect = nil); override;
   procedure Store(Stream: TogsStream); override;
   constructor Load(Stream: TogsStream); override;
  end;

  { TgrPoint }

  TgrPoint = record
   X, Y: Single;
  end;

  { TgrLine }

  TgrLine = class(TogsBasic)
   Color  : TColor;
   lSect  : TSect; // прямоугольник для линии
   fpIndex: Byte;  // индекс вершины lSect[fpIndex] = {X,Y}
   class function ObjectID: Integer; override;
   constructor Create(X, Y, X1, Y1: Double);
   procedure CreateLine(var X, Y, X1, Y1: Double);
   procedure Play(Drawer: TogsDrawer; playRect: TogsRect = nil); override;
   procedure Store(Stream: TogsStream); override;
   constructor Load(Stream: TogsStream); override;
  end;

  { TgrPolygons }

  TgrPolygons = class(TogsBasic)
   Color: TColor;
   pSect: TSect;
   Polygons: TogsCollection;
   Pen: TgrCreateBrush;
   class function ObjectID: Integer; override;
   constructor Create(Polygons_: TogsCollection);
   destructor Destroy; override;
   procedure Play(Drawer: TogsDrawer; playRect: TogsRect = nil); override;
   procedure Store(Stream: TogsStream); override;
   constructor Load(Stream: TogsStream); override;
  end;

  { TgrPolyline }

  TgrPolyline = class(TogsBasic)
   Color: TColor;
   pSect: TSect;
   Parts: TogsCollection;
   class function ObjectID: Integer; override;
   constructor Create(Parts_: TogsCollection);
   destructor Destroy; override;
   procedure Play(Drawer: TogsDrawer; playRect: TogsRect = nil); override;
   procedure Store(Stream: TogsStream); override;
   constructor Load(Stream: TogsStream); override;
  end;

  { TgrBitmap }

  TgrBitmap = class(TogsBasic)
   bSect: TSect;
   Bitmap: TogsGeometry;
   class function ObjectID: Integer; override;
   constructor Create(Bitmap_: TogsGeometry);
   procedure Play(Drawer: TogsDrawer; playRect: TogsRect = nil); override;
   procedure Store(Stream: TogsStream); override;
   constructor Load(Stream: TogsStream); override;
  end;

  { TgmfPlayer }

  TgmfPlayer = class(TogsSpacer)
  protected
  // TDrawer, используемый для рисования
  // при создании объекта сохраняется из ogsSelector
  // при угичтожении восстанавливается
   ogsDrawer: TogsDrawer;
   Commands: TogsCollection;
   Loaded: Boolean;
   function GetCanvas: TCanvas; override;
   function GetHeight: Integer; override;
   function GetWidth: Integer; override;
  public
   LineCount, RectCount, CircleCount, PolyCount: Integer;
   constructor Create(ogsSelector_: TogsSelector; ogsDrawer_: TogsDrawer;
    cmdPlayer_: TogsCollection);
   destructor Destroy; override;
   procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); override;
   procedure DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean = True); override;
   procedure DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean = True); override;
   procedure DrawSect(Sect: TSect); override;
   procedure DrawCircle(XA, YA, Radius: Double); override;
   procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); override;
   procedure DrawBitmap(Bmp: TogsGeometry; bmRect: TogsRect=nil); override;
   function SelectPen(Pen: TogsPen): TogsPen; override;
   function SelectBrush(Brush: TogsBrush): TogsBrush; override;
  // вызов OnPaint
   procedure DrawTo(Image_: TCanvas; Rect: TRect); override;
  // сохранение метафайла
   procedure SaveToFile(fName: String);
   function LoadFromFile(fName: String): Integer;
  //
   function WriteObj(Params: Array of Const): String; override;
  end;

implementation uses ogcWriter, ogcMathUtils;

{ TgrCreatePen }

class function TgrCreatePen.ObjectID: Integer;
begin
 Result := ID_CreatePen;
end;

constructor TgrCreatePen.Create(Pen: TogsPen);
begin
 If Pen <> nil then CreateAs(Pen)
  else begin
   penColor := clBlack;
   penWidth := 0;
  end;
end;

procedure TgrCreatePen.Play(Drawer: TogsDrawer; playRect: TogsRect);
begin
 Drawer.SelectPen(Self);
end;

procedure TgrCreatePen.Store(Stream: TogsStream);
begin
 Stream.Write(ID_CreatePen, SizeOf(Byte)); // sizeof(byte) = 4; value = 0
 Stream.Write(penColor, SizeOf(penColor)); // sizeof(int) = 4
 Stream.Write(penWidth, SizeOf(penWidth)); // sizeof(int) = 4
end;

constructor TgrCreatePen.Load(Stream: TogsStream);
begin
 Stream.Read(penColor, SizeOf(penColor)); // sizeof(int) = 4
 Stream.Read(penWidth, SizeOf(penWidth)); // sizeof(int) = 4
end;

{ TgrCreateBrush }

class function TgrCreateBrush.ObjectID: Integer;
begin
 Result := ID_CreateBrush;
end;

constructor TgrCreateBrush.Create(Brush: TogsBrush);
begin
 If Brush <> nil then CreateAs(Brush)
  else begin
   brColor := clBlack;
  end;
end;

procedure TgrCreateBrush.Play(Drawer: TogsDrawer; playRect: TogsRect);
begin
 Drawer.SelectBrush(Self);
end;

procedure TgrCreateBrush.Store(Stream: TogsStream);
begin
 Stream.Write(ID_CreateBrush,SizeOf(Byte)); // sizeof(byte) = 1; value = 1
 Stream.Write(brColor, SizeOf(brColor)); // sizeof(int) = 4
end;

constructor TgrCreateBrush.Load(Stream: TogsStream);
begin
 Stream.Read(brColor, SizeOf(brColor)); // sizeof(int) = 4
end;

{ TgrLine }

class function TgrLine.ObjectID: Integer;
begin
 Result := ID_DrawLine;
end;

constructor TgrLine.Create(X, Y, X1, Y1: Double);
var Rect: TogsRect;
begin
 Color := clLime;
 Rect := TogsRect.Create;
 Rect.Insert(X, Y); Rect.Insert(X1, Y1);
 lSect := Rect.Sect;
// определяем точку первой вершины
 If (X = lSect.XMin) and (Y = lSect.YMin) then fpIndex := 0 else
 If (X = lSect.XMin) and (Y = lSect.YMax) then fpIndex := 1 else
 If (X = lSect.XMax) and (Y = lSect.YMax) then fpIndex := 2 else
                                               fpIndex := 3;
 Rect.Free;
end;

procedure TgrLine.CreateLine(var X, Y, X1, Y1: Double);
begin
 If fpIndex = 0 then begin X := lSect.XMin; Y := lSect.YMin; X1 := lSect.XMax; Y1 := lSect.YMax; end else
 If fpIndex = 1 then begin X := lSect.XMin; Y := lSect.YMax; X1 := lSect.XMax; Y1 := lSect.YMin; end else
 If fpIndex = 2 then begin X := lSect.XMax; Y := lSect.YMax; X1 := lSect.XMin; Y1 := lSect.YMin; end else
                     begin X := lSect.XMax; Y := lSect.YMin; X1 := lSect.XMin; Y1 := lSect.YMax; end;
end;

procedure TgrLine.Play(Drawer: TogsDrawer; playRect: TogsRect);
var fullVis: boolean;
    oldPen: TogsPen;
begin
 If not lSect.VisibleIn(Drawer.ogsSelector.ActiveRect) then exit;
// fullVis := lSect.VisibleAllIn(Drawer.ogsSelector.ActiveRect);
 oldPen := Drawer.SelectPen(TogsPen.Create(Color, 0, nil));
 try
  If fpIndex = 0 then Drawer.DrawLine(lSect.XMin, lSect.YMin, lSect.XMax, lSect.YMax, true) else
  If fpIndex = 1 then Drawer.DrawLine(lSect.XMin, lSect.YMax, lSect.XMax, lSect.YMin, true) else
  If fpIndex = 2 then Drawer.DrawLine(lSect.XMax, lSect.YMax, lSect.XMin, lSect.YMin, true) else
                      Drawer.DrawLine(lSect.XMax, lSect.YMin, lSect.XMin, lSect.YMax, true);
 finally
  Drawer.DeletePen(Drawer.SelectPen(oldPen));
 end;
end;

procedure TgrLine.Store(Stream: TogsStream);
var X, Y, X1, Y1: Double;
begin
 Stream.Write(ID_DrawLine,SizeOf(Byte)); // sizeof(int) = 4; value = 3
 Stream.Write(Color, SizeOf(Color));
 CreateLine(X, Y, X1, Y1);
// Stream.Write(lSect, SizeOf(lSect)); // sizeof(double) * 4 = 8 * 4 = 32
 Stream.Write(X, SizeOf(X)); Stream.Write(Y, SizeOf(X));
 Stream.Write(X1, SizeOf(X)); Stream.Write(Y1, SizeOf(X));
 Stream.Write(fpIndex, SizeOf(Byte)); // sizeof(byte)  = 1
end;

constructor TgrLine.Load(Stream: TogsStream);
var R: TogsRect;
    X, Y, X1, Y1: Double;
begin
// Stream.Read(lSect, SizeOf(lSect)); // sizeof(double) * 4 = 8 * 4 = 32
 R := TogsRect.Create;
 Stream.Read(Color, SizeOf(Color));
  Stream.Read(X, SizeOf(X)); Stream.Read(Y, SizeOf(X));
  Stream.Read(X1, SizeOf(X)); Stream.Read(Y1, SizeOf(X));
 R.Insert(X, Y); R.Insert(X1, Y1);
  Stream.Read(fpIndex, SizeOf(Byte)); // sizeof(byte)  = 1
  Stream.ogsSelector.AddCoord(X, Y);
  Stream.ogsSelector.AddCoord(X1, Y1);
 lSect := R.Sect;
 R.Free;
end;

{ TgrPolygons }

class function TgrPolygons.ObjectID: Integer;
begin
 Result := ID_DrawPolygon;
end;

constructor TgrPolygons.Create(Polygons_: TogsCollection);
var I, J: Integer; R: TogsRect;
    Points: TogsPolyCollection;
begin
 Color := clLime;
 Polygons := TogsCollection.Create;
 R := TogsRect.Create;
  For I := 0 to Polygons_.Count - 1 do begin
   Points := TogsPolyCollection.Create(TogsPolyCollection(Polygons_[I]).Count);
   With TogsPolyCollection(Polygons_[I]) do
    For J := 0 to Count - 1 do With TDot(List[J]) do begin
     Points.Add(TogsDot.Create(X, Y, Z));
     R.Insert(X, Y);
    end;
   if Points <> nil then begin
     Polygons.Add(Points);
     Points := nil;
   end;
  end;
 pSect := R.Sect;
 R.Free;
end;

destructor TgrPolygons.Destroy;
begin
 Polygons.Free;
 inherited Destroy;
end;

procedure TgrPolygons.Play(Drawer: TogsDrawer; playRect: TogsRect);
var
 oldPen: TogsPen;
 oldBrush: TogsBrush;
begin
 If not pSect.VisibleIn(Drawer.ogsSelector.ActiveRect) then exit;
 oldPen := Drawer.SelectPen(TogsPen.Create(Color, 0, nil));
 oldBrush := Drawer.SelectBrush(TogsBrush.Create(Color, nil));
 try
  Drawer.DrawPolyPolygon(Polygons, TogsRect(@pSect));
 finally
  Drawer.DeleteBrush(Drawer.SelectBrush(oldBrush));
  Drawer.DeletePen(Drawer.SelectPen(oldPen));
 end;
// Drawer.DrawSect(pSect);
end;

procedure TgrPolygons.Store(Stream: TogsStream);
var I, J: Integer;
begin
 Stream.Write(ID_DrawPolygon,SizeOf(Byte)); // sizeof(int) = 4; value = 4
 Stream.Write(Color, SizeOf(Color));
 Stream.Write(Polygons.Count, SizeOf(Integer)); // sizeof(int) = 4
 For I := 0 to Polygons.Count - 1 do
  With TogsCollection(Polygons[I]) do begin
   Stream.Write(Count, Sizeof(Count)); // sizeof(int) = 4
    For J := 0 to Count - 1 do With TDot(List[J]) do begin
     Stream.Write(X, SizeOf(X)); // sizeof(double) = 8
     Stream.Write(Y, SizeOf(Y));
     Stream.Write(Z, SizeOf(Z));
    end;
  end;
end;

constructor TgrPolygons.Load(Stream: TogsStream);
var I, J, Count, ptCount: Integer;
    X, Y, Z: Double;
    Points: TogsCollection;
    R: TogsRect;
begin
 Polygons := TogsCollection.Create;
 Stream.Read(Color, SizeOf(Color));
 Stream.Read(Count, SizeOf(Integer)); // sizeof(int) = 4
 R := TogsRect.Create;
 For I := 0 to Count - 1 do begin
  Stream.Read(ptCount, Sizeof(ptCount)); // sizeof(int) = 4
  Points := TogsCollection.Create;
   For J := 0 to ptCount - 1 do begin
    Stream.Read(X, SizeOf(X)); // sizeof(double) = 8
    Stream.Read(Y, SizeOf(Y));
    Stream.Read(Z, SizeOf(Z));
    R.Insert(X, Y);
    Stream.ogsSelector.AddCoord(X, Y);
    Points.Add(TogsDot.Create(X, Y, Z));
   end;
  Polygons.Add(Points);
 end;
 pSect := R.Sect;
 R.Free;
end;

{ TgrPolyline }

class function TgrPolyline.ObjectID: Integer;
begin
 Result := ID_DrawPolyline;
end;

constructor TgrPolyline.Create(Parts_: TogsCollection);
var
 I, J: Integer;
 R: TogsRect;
 Src: TogsPolyCollection;
 Dst: TogsPolyCollection;
begin
 Color := clLime;
 Parts := TogsCollection.Create;
 R := TogsRect.Create;
 For I := 0 to Parts_.Count - 1 do begin
  Src := TogsPolyCollection(Parts_[I]);
  Dst := TogsPolyCollection.Create(Src.Count);
  For J := 0 to Src.Count - 1 do With TDot(Src.List[J]) do begin
   Dst.Add(TogsDot.Create(X, Y, Z));
   R.Insert(X, Y);
  end;
  Parts.Add(Dst);
 end;
 pSect := R.Sect;
 R.Free;
end;

destructor TgrPolyline.Destroy;
begin
 Parts.Free;
 inherited Destroy;
end;

procedure TgrPolyline.Play(Drawer: TogsDrawer; playRect: TogsRect);
var
 oldPen: TogsPen;
begin
 If not pSect.VisibleIn(Drawer.ogsSelector.ActiveRect) then exit;
 oldPen := Drawer.SelectPen(TogsPen.Create(Color, 0, nil));
 try
  Drawer.DrawPolyPolyLine(Parts, True);
 finally
  Drawer.DeletePen(Drawer.SelectPen(oldPen));
 end;
end;

procedure TgrPolyline.Store(Stream: TogsStream);
var I, J: Integer;
begin
 Stream.Write(ID_DrawPolyline, SizeOf(Byte));
 Stream.Write(Color, SizeOf(Color));
 Stream.Write(Parts.Count, SizeOf(Integer));
 For I := 0 to Parts.Count - 1 do
  With TogsPolyCollection(Parts[I]) do begin
   Stream.Write(Count, SizeOf(Count));
   For J := 0 to Count - 1 do With TDot(List[J]) do begin
    Stream.Write(X, SizeOf(X));
    Stream.Write(Y, SizeOf(Y));
    Stream.Write(Z, SizeOf(Z));
   end;
  end;
end;

constructor TgrPolyline.Load(Stream: TogsStream);
var
 I, J, Count, ptCount: Integer;
 X, Y, Z: Double;
 Part: TogsPolyCollection;
 R: TogsRect;
begin
 Stream.Read(Color, SizeOf(Color));
 Parts := TogsCollection.Create;
 Stream.Read(Count, SizeOf(Integer));
 R := TogsRect.Create;
 For I := 0 to Count - 1 do begin
  Stream.Read(ptCount, SizeOf(ptCount));
  Part := TogsPolyCollection.Create(ptCount);
  For J := 0 to ptCount - 1 do begin
   Stream.Read(X, SizeOf(X));
   Stream.Read(Y, SizeOf(Y));
   Stream.Read(Z, SizeOf(Z));
   R.Insert(X, Y);
   Stream.ogsSelector.AddCoord(X, Y);
   Part.Add(TogsDot.Create(X, Y, Z));
  end;
  Parts.Add(Part);
 end;
 pSect := R.Sect;
 R.Free;
end;

{ TgrBitmap }

class function TgrBitmap.ObjectID: Integer;
begin
 Result := ID_DrawBitmap;
end;

constructor TgrBitmap.Create(Bitmap_: TogsGeometry);
begin
 Bitmap := Bitmap_;
 if (Bitmap <> nil) and (Bitmap.ogsRect <> nil) then
  bSect := Bitmap.ogsRect.Sect
 else
 begin
  bSect.XMin := 0; bSect.YMin := 0; bSect.XMax := 0; bSect.YMax := 0;
 end;
end;

procedure TgrBitmap.Play(Drawer: TogsDrawer; playRect: TogsRect);
var
 R: TogsRect;
begin
 if Bitmap = nil then Exit;
 if not bSect.VisibleIn(Drawer.ogsSelector.ActiveRect) then Exit;
 R := playRect;
 if R = nil then R := Drawer.ogsSelector.ogsRect;
 Drawer.DrawBitmap(Bitmap, R);
end;

procedure TgrBitmap.Store(Stream: TogsStream);
begin
 Stream.Write(ID_DrawBitmap, SizeOf(Byte));
 // runtime-only reference, not stored
end;

constructor TgrBitmap.Load(Stream: TogsStream);
begin
 Bitmap := nil;
 bSect.XMin := 0; bSect.YMin := 0; bSect.XMax := 0; bSect.YMax := 0;
end;

{ TgmfPlayer }

constructor TgmfPlayer.Create(ogsSelector_: TogsSelector; ogsDrawer_: TogsDrawer; cmdPlayer_: TogsCollection);
begin
 ogsSelector := ogsSelector_;
 inherited Create(ogsSelector_, nil);
 ogsDrawer := ogsDrawer_;
 cmdPlayer := cmdPlayer_;
end;

destructor TgmfPlayer.Destroy;
begin
// WriteIn(['destroy=', integer(ogsdrawer)]);
// ogsSelector.ogsDrawer := ogsDrawer;
 inherited Destroy;
end;

function TgmfPlayer.GetCanvas: TCanvas;
begin
 Result := ogsDrawer.Canvas;
end;

function TgmfPlayer.GetHeight: Integer;
begin
 {
 If ogsDrawer <> nil then
  Result := ogsDrawer.Width else
  Result := 0;
  }
end;

function TgmfPlayer.GetWidth: Integer;
begin
 {
 If ogsDrawer <> nil then
  Result := ogsDrawer.Height else
  Result := 0;
  }
end;

procedure TgmfPlayer.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
var
 L: TgrLine;
begin
 Inc(LineCount);
// отсечение линии, если есть пересечения
 If not cutRequest then begin
  L := TgrLine.Create(X, Y, X1, Y1);
  if Pen <> nil then L.Color := Pen.penColor;
  cmdPlayer.Add(L);
 end else begin
//
  with ogsSelector, activeRect do
  If pointVisible(X, Y) and pointVisible(X1, Y1) then
   begin
    L := TgrLine.Create(X, Y, X1, Y1);
    if Pen <> nil then L.Color := Pen.penColor;
    cmdPlayer.Add(L);
   end else
  If lineVisible(X, Y, X1, Y1) then
   If cutLine(XMin, YMin, XMax, YMax, X, Y, X1, Y1) then
   begin
    L := TgrLine.Create(X, Y, X1, Y1);
    if Pen <> nil then L.Color := Pen.penColor;
    cmdPlayer.Add(L);
   end;
 end;
end;

procedure TgmfPlayer.DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean);
var
 Parts: TogsCollection;
 Part: TogsPolyCollection;
 I: Integer;
 P: TgrPolyline;
begin
 if cmdPlayer = nil then exit;
 if (Points = nil) or (Points.Count < 2) then exit;
 Parts := TogsCollection.Create;
 Part := TogsPolyCollection.Create(Points.Count);
 For I := 0 to Points.Count - 1 do With TDot(Points.List[I]) do
  Part.Add(TogsDot.Create(X, Y, Z));
 Parts.Add(Part);
 P := TgrPolyline.Create(Parts);
 if Pen <> nil then P.Color := Pen.penColor;
 cmdPlayer.Add(P);
 Parts.Free;
end;

procedure TgmfPlayer.DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean);
var
 P: TgrPolyline;
begin
 if cmdPlayer = nil then exit;
 if (Parts = nil) or (Parts.Count = 0) then exit;
 P := TgrPolyline.Create(Parts);
 if Pen <> nil then P.Color := Pen.penColor;
 cmdPlayer.Add(P);
end;

procedure TgmfPlayer.DrawSect(Sect: TSect);
begin
 Inc(RectCount);
end;

procedure TgmfPlayer.DrawCircle(XA, YA, Radius: Double);
begin
 Inc(CircleCount);
end;

procedure TgmfPlayer.DrawPolyPolygon(Polygons: TogsCollection;
 polyRect: TogsRect);
var
 P: TgrPolygons;
begin
 If Polygons.Count > 0 then begin
  P := TgrPolygons.Create(Polygons);
  if Brush <> nil then P.Color := Brush.brColor
  else if Pen <> nil then P.Color := Pen.penColor;
  cmdPlayer.Add(P);
  Inc(PolyCount);
 end;
// после выходя из процедуры в TogsPolygon.Draw -> Polygons.Free
// поэтому присваиваем Polygons ноую коллекцию (для этого и var-параметр)
end;

procedure TgmfPlayer.DrawBitmap(Bmp: TogsGeometry; bmRect: TogsRect = nil);
begin
 if cmdPlayer = nil then Exit;
 if Bmp = nil then Exit;
 cmdPlayer.Add(TgrBitmap.Create(Bmp));
end;

function TgmfPlayer.SelectPen(Pen: TogsPen): TogsPen;
begin
 Result := inherited SelectPen(Pen);
end;

function TgmfPlayer.SelectBrush(Brush: TogsBrush): TogsBrush;
begin
 Result := inherited SelectBrush(Brush);
end;

procedure TgmfPlayer.DrawTo(Image_: TCanvas; Rect: TRect);
begin
 WriteIn([Self]);
end;

procedure TgmfPlayer.SaveToFile(fName: String);
var I: Integer;
    Stream: TogsStream;
begin
 Stream := TogsStream.CreateFileStream(fName, fmCreate, ogsSelector);
 Stream.Write(cmdPlayer.Count, SizeOf(cmdPlayer.Count)); // sizeof(int) = 4
 For I := 0 to cmdPlayer.Count - 1 do begin
  cmdPlayerItem[I].Store(Stream);
 end;
 Stream.Free;
end;

function TgmfPlayer.LoadFromFile(fName: String): Integer;
var I, Count: Integer;
    Stream: TogsStream;
    Command: Byte;
begin
 Stream := TogsStream.CreateFileStream(fName, fmOpenRead, ogsSelector);
 Stream.ogsSelector := ogsSelector;
 cmdPlayer := TogsCollection.Create;
 Loaded := False;
 try
  Stream.Read(Count, SizeOf(Count)); // sizeof(int) = 4
  For I := 0 to Count - 1 do begin
   Stream.Read(Command, SizeOf(Byte)); // sizeof(byte) = 1
   If (Command > 5) or (Command = 0) then WriteIn(['cmd=',Command, I]);
   Case Command of
    1 : cmdPlayer.Add(TgrCreatePen.Load(Stream));
    // Stream.Read(penColor, SizeOf(penColor)); // sizeof(int) = 4
    // Stream.Read(penWidth, SizeOf(penWidth)); // sizeof(int) = 4
    2: cmdPlayer.Add(TgrCreateBrush.Load(Stream));
    // Stream.Read(brColor, SizeOf(brColor)); // sizeof(int) = 4
    3 : cmdPlayer.Add(TgrLine.Load(Stream));
    // Stream.Read(X, SizeOf(X)); Stream.Read(Y, SizeOf(X));
    // Stream.Read(X1, SizeOf(X)); Stream.Read(Y1, SizeOf(X));
    // Stream.Read(fpIndex, SizeOf(Byte)); // sizeof(byte)  = 1
    4 : cmdPlayer.Add(TgrPolygons.Load(Stream));
    5 : cmdPlayer.Add(TgrPolyline.Load(Stream));
    6 : cmdPlayer.Add(TgrBitmap.Load(Stream));
    // считываем PolyPolygon
    // Stream.Read(Count, SizeOf(Integer)); // sizeof(int) = 4
    // For I := 0 to Count - 1 do begin
    // Stream.Read(ptCount, Sizeof(ptCount)); // sizeof(int) = 4
    //  For J := 0 to ptCount - 1 do begin
    //   Stream.Read(X, SizeOf(X)); // sizeof(double) = 8
    //   Stream.Read(Y, SizeOf(Y));
    //   Stream.Read(Z, SizeOf(Z));
    //  end;
   end;
  end;
  Loaded := True;
 finally
  Stream.Free;
 end;
end;

function TgmfPlayer.WriteObj(Params: array of const): String;
begin
 WriteIn([ClassName,':',Fmt(Params)]);
 Result := Fmt(['lines, rects, circles, polygs :',LineCount, RectCount, CircleCount, PolyCount]);
end;

end.

