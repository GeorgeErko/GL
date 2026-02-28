unit TTFGeometry;

{$mode Delphi}

interface

uses Classes, SysUtils, LCLType, Graphics, ogcBasic, ogcGeometry,
     feFontEngine, feFontEngineObjects, feGlyphVector3D,
     StrUtils, ogcTess;

type

  TogsTextString = class;

  { TFontSymbol }

  TFontSymbol = class(TogsMultiPolygon)
   fSymbol: UnicodeChar;
   fFont : TFEFont;
   fIndex: Integer;
   fGlyph: TFEGlyph;
   fBounds: TRect;
   fRect: TRect;
  //
   Metrics: FE_Glyph_Metrics;
   advLine: TRect;
  //
   nullSymbol: TFontSymbol;
   constructor Create(Selector_: TogsSelector; Font_: TFEFont; Glyph_: TFEGlyph;
                      Index_: Integer; nullSymbol_: TFontSymbol);
   destructor Destroy; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   property Bounds: TRect read fBounds;
   property Rect: TRect read fRect;
  //
   function Calculate(Action: TCalcActionSet): Integer; override;
  end;

  { TFontCollect }

  TLoadMode = (lmIncomplete, lmComplete);

  TFontCollect = class(TogsGeometryCollection)
  private
  // режим загрузки шрифта:
  //  lmIncomplete - загружены заголовки шрифта
  //  lmComplete   - загружены все символы шрифта
//   fLoadMode: TLoadMode;
  //
   fFileName: String;
   fFontName: String;
   fFont: TFEFont;
   fHeight: Integer; // высота символа
   fbtmHeight: Integer; // высота символа fHeight + (ABC.yBase - ABC.yBottom)
   function GetSymbol(Index: Integer): TFontSymbol;
  public
   fLoadMode: TLoadMode;
   constructor Create(Selector_: TogsSelector; FileName_: AnsiString; Mode: TLoadMode);
   procedure LoadModeComplete;
   destructor Destroy; override;
  //
   property Symbol[Index: Integer]: TFontSymbol read GetSymbol; default;
  // Поиск символа по индексу Unicode
   function CharIndex(CharCode: Integer): Integer;
   function SymbolByIndex(CharCode: Integer): TFontSymbol;
  //
   property FEFont: TFEFont read fFont;
  // коэффициент для вывода текста
   function ScaleOf(Height: Double): Double;
  end;

  { TogsSymbol }

  TogsSymbol = class(TogsPoint)
   fChar: PChar;
   fSymbol: TFontSymbol;
   fSymbolTess: TogsTess;
   constructor Create(Selector: TogsSelector; X_, Y_, Z_: Double; Char_: PChar; Symbol_: TFontSymbol);
   destructor Destroy; override;
  // расчет
   function Calculate(Action: TCalcActionSet): Integer; override;
  // рисование
   procedure Draw(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  end;

  { TogsTextString }

  TogsTextString = class(TogsPoint)
  private
   fColorBy: TColorBy;
   fColor: TColor;
   function GetSymbol(Index: Integer): TogsSymbol;
   function GetAttribute: String; override;
   procedure SetAttribute(AttrName_: String); override;
   procedure SetColorBy(AValue: TColorBy); override;
   function GetColorBy: TColorBy; override;
   function GetColor: TColor; override;
   procedure SetColor(AValue: TColor); override;
  public
   fFontCollect: TFontCollect;
   fText: String;
   fSymbols: TogsGeometryCollection;
   ABC: ArrayOfCharPosition;
  // параметры вывода
   fHeight : Double;
   fAngle  : Double;
   fScale  : Double;
   fAlign  : TFEAlignments;
  //
   fAttrName: String; // имя атрибута в блоке
   fBlock: boolean;
  // временно в виде переменных, !!! необходимо реализовать в виде свойств
   constructor Create(Selector: TogsSelector; FontCollect_: TFontCollect; X_, Y_,
    Z_: Double; Height_, Angle_, Scale_: Double; Align_: TFEAlignments; Text_,
    AttrName_: String; TextColor: Integer; InBlock: Boolean=False);
   constructor CreateAs(ogsObject: TogsBasic); override;
   destructor Destroy; override;
   function Assign(ogsObject: TogsBasic): Boolean; override;
  // расчет расстановки текста
   procedure CalculateText;
   procedure AddSymbol(X_,Y_: Double; Char_: PChar; Symbol: TFontSymbol);
  //
   function Count: Integer;
   property Symbol[Index: Integer]: TogsSymbol read GetSymbol; default;
  // расчет
   function Calculate(Action: TCalcActionSet): Integer; override;
  // рисование
   procedure Draw(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  end;

  { TogsTextParams }

  { TogsKeeper }
 // !!! объект предназначен для управления копиями объектов
 // при использовании Undo и управлением свойствами объектов
{  TogsKeeper = class(TogsStream)
   KeepObject: TogsBasic;
   constructor Create(KeepObject_: TogsBasic); virtual;
   procedure Keep; virtual;
   procedure Release; virtual;
  end;
}

  TogsTextParams = class(TogsTextString)
   fKeepObject: Boolean; // признак объекта - копии
  // KeepObject - объект для временного хранения полей TextString
  // которые замещаются атрибутами Self в блоке для:
  //                                    отрисовки, захвата, вычисления шабаритов
   KeepString : TogsTextParams;
   TextString : TogsTextString;
  // данный конструктор используется для создания объекта -> копии TogsTExtString
  // для временного сохранения полей оригинального объекта
   constructor CreateEmpty; override;
   constructor Create(TextString_: TogsTextString;
               Selector: TogsSelector; FontCollect_: TFontCollect; X_, Y_,
               Z_: Double; Height_, Angle_, Scale_: Double; Align_: TFEAlignments; Text_,
               AttrName_: String; TextColor: Integer; InBlock: Boolean=False);
   destructor Destroy; override;
  // функция не создает копии полей -> объектов-указателей
  // применяется для копирования полей объекта, для
  // временного хранения их в KeepString
   function Assign(ogsObject:TogsBasic): boolean; override;
   procedure KeepObject;
   procedure ReleaseObject;
  //
   function isKeepObject: Boolean; override;
  end;

  { TTextAttribs }

  TTextAttribs = class(TogsCollection)
  private
   function GetAttr(Index: Integer): TogsTextParams;
  public
   constructor Create;
 //  procedure AddAtrib(AttrName_, Text_: String; TextString_: TogsTextString);
   function FindAttr(AttrName: String; CI: boolean): TogsTextParams;
   property Attr[Index: Integer]: TogsTextParams read GetAttr; default;
   procedure KeepObject;
   procedure ReleaseObject;
  end;

  { TogsFontManager - класс для загрузки шоифтов из папки Fonts }

  { TFontItem }

  TFontItem = class(TogsBasic)
   fileName: String;
   fontName: String;
   fontStyle: TFEStyles;
   fontStyles: String;
   fontCollect: TFontCollect;
   Constructor Create(Selector: TogsSelector; fileName_: String);
   destructor Destroy; override;
  end;

  TogsFontManager = class(TogsSortedCollection)
  private
   // незагруженные ttf - файлы
   ErrorList: TStrings;
   function GetItem(Index: Integer): TFontItem;
  public
   constructor Create;
   destructor Destroy; override;
   function LoadFontList(Selector: TogsSelector): Integer;
   property Item[Index: Integer]: TFontItem read GetItem;
  //
   function FindBy(fontName: String; fontStyle: TFEStyles; var FC: TFontCollect): Integer;
  end;

  var ogsFontManager: TogsFontManager;

  function CompareFontItemProc(Item1, Item2: Pointer): Integer;

implementation uses ogcWriter, lazUTF8, FileUtil;

function CompareFontItemProc(Item1, Item2: Pointer): Integer;
begin
 If TFontItem(Item1).fontName < TFontItem(Item2).fontName then Result:= -1 else
 If TFontItem(Item1).fontName > TFontItem(Item2).fontName then Result:= 1
  else
 If TFontItem(Item1).fontStyles < TFontItem(Item2).fontStyles then Result := -1 else
 If TFontItem(Item1).fontStyles > TFontItem(Item2).fontStyles then Result := 1
  else
 If TFontItem(Item1).fileName < TFontItem(Item2).fileName then Result := -1 else
 If TFontItem(Item1).fileName > TFontItem(Item2).fileName then Result := 1
  else
   Result := 0;
end;

{ TFontItem }

constructor TFontItem.Create(Selector: TogsSelector; fileName_: String);
begin
 fileName := fileName_;
 if fileName <> '' then begin
  fontCollect := TFontCollect.Create(Selector, fileName, lmIncomplete);
  fontName := fontCollect.fFontName;
  fontStyle:= fontCollect.FEFont.Style;
  fontStyles := fontCollect.FEFont.StyleAsString;
 end;
end;

destructor TFontItem.Destroy;
begin
 fontCollect.Free;
end;

{ TogsFontManager }

constructor TogsFontManager.Create;
begin
 inherited Create(CompareFontItemProc, True);
 ErrorList := TStringList.Create;
end;

destructor TogsFontManager.Destroy;
begin
 inherited Destroy;
 ErrorList.Free;
end;

function TogsFontManager.GetItem(Index: Integer): TFontItem;
begin
 Result := List[Index];
end;

function TogsFontManager.LoadFontList(Selector: TogsSelector): Integer;
var I: Integer;
    FileList : TStrings;
begin
 FileList := TStringList.Create;
 ErrorList:= TStringList.Create;
 try
  FindAllFiles(FileList, ExtractFilePath(ParamStr(0))+'Fonts', '*.ttf', False);
  WriteIn(['Fonts.Count=',FileList.Count ]);
  For I := 0 to FileList.Count - 1 do begin
  // загружаем файлы
   try
    Add(TFontItem.Create(Selector, FileList[I]));
   except
    ErrorList.Add(FileList[I]);
   end;
  end;
 finally
  Result := FileList.Count;
  FileList.Free;
 end;
 WriteIn(['Errors=',ErrorList.Count]);
 For I := 0 to Count - 1 do WriteIn([Item[I].fileName, Item[I].fontName, Item[I].fontStyles, Item[I].FontCollect.Count]);
end;

function TogsFontManager.FindBy(fontName: String; fontStyle: TFEStyles; var FC: TFontCollect): Integer;
var I: Integer;
begin
 Result := -1;
 If Count = 0 then raise Exception.Create('Нет загруженных шрифтов');
 FC := Item[0].FontCollect;
 For I := 0 to Count - 1 do begin
  If Result = -1 then
   If ansiLowerCase(Item[I].fontName) = ansiLowerCase(fontName) then FC := Item[I].fontCollect;
  If (ansiLowerCase(Item[I].fontName) = ansiLowerCase(fontName))  and (Item[I].fontStyle = fontStyle) then begin
   FC := Item[I].FontCollect;
   Result := I;
   exit;
  end;
 end;
end;

{ TFontSymbol }
(*
constructor TFontSymbol.Create(Selector_: TogsSelector; Font_: TFEFont; Glyph_: TFEGlyph;
                               Index_: Integer; nullSymbol_: TFontSymbol);
var X, Y, X1, Y1: Double;
    glyphPolygon: TVFGlyphPolygon;
    I, J: Integer;
    Poly_S: TPoly_Single;
    Poly: TogsPolygon;
    VFPoly: TVFGlyphPolygon;
    Pt: TVFPolygonPoint;
    Glyph3D: TVFGlyph3D;
begin
 inherited Create(Selector_);
 //
  fIndex := Index_;
  fFont  := Font_;
  fGlyph := Glyph_;
  fBounds := fGlyph.Bounds;
 // параметры геометии и основные метрики глифа
  If FE_Get_Glyph_Metrics(fGlyph.Data, Metrics) <> FE_Err_Ok then begin
 // пустой глиф
   nullSymbol := nullSymbol_;
   exit;
  end;
 // проверяем на наличие геометрии
  If (Bounds.Top = 0) and (Bounds.Bottom = 0) and (Bounds.Left = 0) and (Bounds.Right = 0) then begin
 // пустой глиф
   nullSymbol := nullSymbol_;
  // WriteIn(['null symbol...........']);
   exit;
  end;
 // WriteIn(['glyphIndex=',fGlyph.Index]);
  fGeometry := TVFGlyph3D.Create(fGlyph, 10, 4);
 // вычисляем точку привязки глифа (лево-низ), используя метрики bearingX, bearingY
  advLine.Left := Metrics.bBox.XMin - Metrics.bearingX;
  advLine.Top := Metrics.bbox.YMax - (Metrics.bbox.YMax - Metrics.bearingY);
  advLine.Right := advLine.Left + fGeometry.fGlyph.Metrics.horiAdvance;
  advLine.Bottom := advLine.Top;
 // переворачиваем Rect
  fRect.Left := Metrics.bbox.XMin;
  fRect.Top := Metrics.bbox.YMax - Metrics.bbox.YMin;
  fRect.Right := Metrics.bbox.XMax;
  fRect.Bottom := Metrics.bbox.YMax - Metrics.bbox.YMax;
 // заполняем геометрию
  Poly := TogsPolygon.Create(ogsSelector);
  With Metrics, fGeometry do
  Glyph3D := TVFGlyph3D.Create(Glyph_, 10, 0); // только полигоны
   for i := 0 to Glyph3D.FPolygonsFine.Count - 1 do
   begin
     VFPoly := TVFGlyphPolygon(Glyph3D.FPolygonsFine[i]);
     if VFPoly.FPointsList.Count = 0 then Continue;
    // создаем одиночный полигон
     Poly_S := TPoly_Single.Create(ogsSelector);

     Pt := TVFPolygonPoint(VFPoly.FPointsList[0]);
    // Path.MoveTo(Pt.x / 64.0, -Pt.y / 64.0);
     Poly_S.AddPoint(Pt.x, -Pt.y, 0);

     for j := 1 to VFPoly.FPointsList.Count - 1 do
     begin
       Pt := TVFPolygonPoint(VFPoly.FPointsList[j]);
      // Path.LineTo(Pt.x / 64.0, -Pt.y / 64.0);
      Poly_S.AddPoint(Pt.x, -Pt.y, 0);
     end;
     // замыкание

     Pt := TVFPolygonPoint(VFPoly.FPointsList[0]);
    // Path.LineTo(Pt.x / 64.0, -Pt.y / 64.0);
     Poly_S.AddPoint(Pt.x, -Pt.y, 0);
    // добавляем в основной полигон
     Poly_S.Calculate([calcbBox, calcSquare]);
     Poly.AddPolygon(Poly_S);
   end;
  Glyph3D.Free;
 If Poly.Count <> 0 then Poly.Calculate([calcSquare, calcbBox, calcRelation]);
// If fIndex = 8 then WriteIn(['Multi = ',fIndex, Poly.isMultiPolygon, Poly.Count]);
 // если полигон состоит из нескольких независимых ->
 // формируем мультиполигон из нескольких полигонов,
 // иначе просто добавляем полигон
  If not Poly.isMultiPolygon then begin
   AddPolygon(Poly);
  // WriteIn(['PolyCount =', Count]);
  end else begin
   AddMultiPoly(Poly);
 // еси вставили как мультиполигон -> удаляем Poly
//   WriteIn(['MultiCount =', Count]);
   Poly.Free;
  end;
  Calculate([calcbBox, calcSquare, calcRelation]);
end;
*)

constructor TFontSymbol.Create(Selector_: TogsSelector; Font_: TFEFont; Glyph_: TFEGlyph;
                               Index_: Integer; nullSymbol_: TFontSymbol);
var X, Y, X1, Y1: Double;
    glyphPolygon: TVFGlyphPolygon;
    I, J: Integer;
    Poly_S: TPoly_Single;
    Poly: TogsPolygon;
    fGeometry: TVFGlyph3D;
begin
 inherited Create(Selector_);
 //
  fIndex := Index_;
  fFont  := Font_;
  fGlyph := Glyph_;
  fBounds := fGlyph.Bounds;
 // параметры геометии и основные метрики глифа
  If FE_Get_Glyph_Metrics(fGlyph.Data, Metrics) <> FE_Err_Ok then begin
 // пустой глиф
   nullSymbol := nullSymbol_;
   exit;
  end;
 // проверяем на наличие геометрии
  If (Bounds.Top = 0) and (Bounds.Bottom = 0) and (Bounds.Left = 0) and (Bounds.Right = 0) then begin
 // пустой глиф
   nullSymbol := nullSymbol_;
  // WriteIn(['null symbol...........']);
   exit;
  end;
 // WriteIn(['glyphIndex=',fGlyph.Index]);
  fGeometry := TVFGlyph3D.Create(fGlyph, 10, 4);
 // вычисляем точку привязки глифа (лево-низ), используя метрики bearingX, bearingY
  advLine.Left := Metrics.bBox.XMin - Metrics.bearingX;
  advLine.Top := Metrics.bbox.YMax - (Metrics.bbox.YMax - Metrics.bearingY);
  advLine.Right := advLine.Left + fGeometry.fGlyph.Metrics.horiAdvance;
  advLine.Bottom := advLine.Top;
 // переворачиваем Rect
  fRect.Left := Metrics.bbox.XMin;
  fRect.Top := Metrics.bbox.YMax - Metrics.bbox.YMin;
  fRect.Right := Metrics.bbox.XMax;
  fRect.Bottom := Metrics.bbox.YMax - Metrics.bbox.YMax;
 // заполняем геометрию
  Poly := TogsPolygon.Create(ogsSelector);
  With Metrics, fGeometry do
   // заполняем коллекцию координатами полигонов глифа
   For J := 0 to FPolygonsFine.Count-1 do begin
    glyphPolygon := FPolygonsFine[J];
     For I := 0 to glyphPolygon.FPointsList.Count-1 do begin
      X1 := TVFPolygonPoint(glyphPolygon.FPointsList[I]).X;
      Y1 :=  (Metrics.bearingY) - TVFPolygonPoint(glyphPolygon.FPointsList[I]).Y;
     // фиксируем первую точку
      If I = 0 then begin
       X := X1; Y := Y1;
       Poly_S := Tpoly_Single.Create(ogsSelector);
       Poly_S.AddPoint(X1, Y1, 0);
      end else
       Poly_S.AddPoint(X1, Y1, 0);
     // замыкаем полигон, вставляем в коллекцию
      If I = glyphPolygon.FPointsList.Count - 1 then begin
      // Poly_S.AddPoint(X, Y, 0);
       Poly_S.Calculate([calcbBox, calcSquare]);
       Poly.AddPolygon(Poly_S);
      end;
     end;
   end;
  fGeometry.Free;
 If Poly.Count <> 0 then Poly.Calculate([calcSquare, calcbBox, calcRelation]);
// If fIndex = 8 then WriteIn(['Multi = ',fIndex, Poly.isMultiPolygon, Poly.Count]);
 // если полигон состоит из нескольких независимых ->
 // формируем мультиполигон из нескольких полигонов,
 // иначе просто добавляем полигон
  If not Poly.isMultiPolygon then begin
   AddPolygon(Poly);
  // WriteIn(['PolyCount =', Count]);
  end else begin
   AddMultiPoly(Poly);
 // еси вставили как мультиполигон -> удаляем Poly
//   WriteIn(['MultiCount =', Count]);
   Poly.Free;
  end;
  Calculate([calcbBox, calcSquare, calcRelation]);
end;

destructor TFontSymbol.Destroy;
begin
 inherited Destroy;
// !!! в старой версии
// fGeometry.Free;
end;

constructor TFontSymbol.Load(Stream: TogsStream);
begin
 Stream.Read(fSymbol, SizeOf(fSymbol));
 Stream.Read(fIndex, SizeOf(fIndex));
 Stream.Read(fBounds, SizeOf(fBounds));
 Stream.Read(fRect, SizeOf(fRect));
 Stream.Read(advLine, SizeOf(advLine));
 Stream.Read(Metrics, SizeOf(Metrics));
 inherited Load(Stream);
end;

procedure TFontSymbol.Store(Stream: TogsStream);
begin
 Stream.Write(fSymbol, SizeOf(fSymbol));
 Stream.Write(fIndex, SizeOf(fIndex));
 Stream.Write(fBounds, SizeOf(fBounds));
 Stream.Write(fRect, SizeOf(fRect));
 Stream.Write(advLine, SizeOf(advLine));
 Stream.Write(Metrics, SizeOf(Metrics));
 inherited Store(Stream);
end;

function TFontSymbol.Calculate(Action: TCalcActionSet): Integer;
begin
 If calcTess in Action then  begin
 // WriteIn(['oпыTess=nil', ogsTess = nil, fSymbol]);
  Result := inherited Calculate(Action);
 end else
  Result := inherited Calculate(Action);
end;

{ TFontCollect }

constructor TFontCollect.Create(Selector_: TogsSelector; FileName_: AnsiString; Mode: TLoadMode);
var I: Integer;
begin
 inherited Create(Selector_);
  fFileName := FileName_;
  fFileName := fFileName;
  fFontName:= VarFontCollection.AddFile(fFileName).Family.FamilyName;
 //
  With VarFontCollection.AddFile(fFileName).Family do

 //
  fFont := TFEFont.Create;
  fFont.Name := fFontName;
  fFont.Style := [ftsItalic];
  fFont.DPI := 96;
  fFont.SizeInPoints := 72;
 // создаем и заполняем коллекцию символов
//  WriteIn(['I=',I,'Char=',fFont.CharIndex[I]]);
  fLoadMode := Mode;
  If Mode = lmIncomplete then exit;
  LoadModeComplete;
end;

procedure TFontCollect.LoadModeComplete;
var I: Integer;
    Symbol, nullSymbol: TFontSymbol;
    ABC: ArrayOfCharPosition;
begin
 If fLoadMode = lmComplete then exit;
 nullSymbol := nil;
 fLoadMode := lmComplete;
 try
  For I := 0 to fFont.GlyphCount - 1 do begin
   Symbol := TFontSymbol.Create(ogsSelector, fFont, fFont.Glyph[I], I, nullSymbol);
   If I = 0 then nullSymbol := Symbol;
   Items.Add(Symbol);
  end;
  ABC := FEFont.CharsPosition('A');
 // определяем высоту символа
  fHeight := Round(Abs(ABC[1].yTop - ABC[1].yBottom) * 64);
  fbtmHeight := fHeight - Round(Abs(ABC[1].yBase - ABC[1].yBottom) * 64);
  SetLength(ABC, 0);
 except
  fLoadMode := lmIncomplete;
 end;
end;

function TFontCollect.GetSymbol(Index: Integer): TFontSymbol;
begin
 If fLoadMode = lmIncomplete then Exception.Create('LoadMode = Incomplete. FontName: ' + ffontName);
 Result := Items[Index];
end;

destructor TFontCollect.Destroy;
begin
 inherited Destroy;
 fFont.Free;
end;

function TFontCollect.CharIndex(CharCode: Integer): Integer;
begin
 Result := fFont.CharIndex[CharCode]
end;

function TFontCollect.SymbolByIndex(CharCode: Integer): TFontSymbol;
var Index: Integer;
begin
 Index := CharIndex(CharCode);
 If Index = - 1 then raise Exception.Create(Fmt(['Неверный код символа ',Index]));
 Result := Items[Index];
end;

function TFontCollect.ScaleOf(Height: Double): Double;
begin
 If fLoadMode = lmIncomplete then Exception.Create('LoadMode = Incomplete. FontName: ' + ffontName);
 Result := Height/fHeight;
end;

{ TogsSymbol }

constructor TogsSymbol.Create(Selector: TogsSelector; X_, Y_, Z_: Double;
 Char_: PChar; Symbol_: TFontSymbol);
begin
 inherited Create(X_,Y_,Z_,Selector);
 fChar := Char_;
 fSymbol := Symbol_;
 fSymbolTess := nil;
 ogsRect.Clear;
 ogsRect.InsertRect(fSymbol.ogsRect);
 ogsRect.Move(X_, Y_);
end;

destructor TogsSymbol.Destroy;
begin
 FreeAndNil(fSymbolTess);
 inherited Destroy;
end;

function TogsSymbol.Calculate(Action: TCalcActionSet): Integer;
var oldSect: TSect;
    Matrix: TogsMatrix;
begin
 If calcbBox in Action then begin
 // перевычисление габаритов символа
 oldSect := fSymbol.ogsRect.Sect;
 Matrix := SelectMatrix(TogsMatrix.Create({ogsMatrix.X +} X, {ogsMatrix.Y +} Y, ogsMatrix.Angle, ogsMatrix.Scale));
  try
   fSymbol.Calculate([calcbBox]);
   ogsRect.Assign(fSymbol.ogsRect);
  finally
   DeleteMatrix(SelectMatrix(Matrix));
   fSymbol.ogsRect.Sect := oldSect;
  end;
 end;
 If calcTess in Action then
 begin
  FreeAndNil(fSymbolTess);
 // WriteIn(['Tessnil', fSymbol.ogsTess = nil]);
  if fSymbol.ogsTess = nil then begin
  // WriteIn(['Calc', fChar]);
   fSymbol.Calculate([calcTess]);
  end;
 end;
end;

procedure TogsSymbol.Draw(Drawer: TogsDrawer);
var oldSect: TSect;
    P1, P2: TogsPoint;
    Matrix: TogsMatrix;
    oldTess: TogsTess;
begin
 If not Visible(ogsSelector.ActiveRect) then
  If fSymbol.ogsTess = nil then exit;
// With ogsRect do WriteIn(['Self.Rect=',XMin, YMin, XMax, YMax]);
// Drawer.DrawSect(ogsRect.Sect);
// exit;
 With fSymbol.advLine do begin
  P1 := TogsPoint.Create(Left, Top, 0);
  P2 := TogsPoint.Create(Right, Bottom, 0);
 end;
// WriteIn(['Symb=', X, Y,fX,fY]);
 Matrix := SelectMatrix(TogsMatrix.Create( X,   Y , ogsMatrix.Angle, ogsMatrix.Scale));
 try
//  With fSymbol.ogsRect do WriteIn(['prev "',fChar,'"',XMin, YMin, XMax, YMax]);
  oldSect:= fSymbol.ogsRect.Sect;
  fSymbol.Calculate([calcbBox]);
//  With fSymbol.ogsRect do WriteIn(['next "',fChar,'"',XMin, YMin, XMax, YMax]);
  if fSymbol.ogsTess = nil then fSymbol.Calculate([calcTess]);
  oldTess := fSymbol.ogsTess;
  if fSymbolTess <> nil then fSymbol.ogsTess := fSymbolTess;
  fSymbol.Draw(Drawer);
  fSymbol.ogsTess := oldTess;
//  Drawer.DrawLine(P1.X, P1.Y, P2.X, P2.Y);
 finally
  DeleteMatrix(SelectMatrix(Matrix));
  P1.Free; P2.Free;
  fSymbol.ogsRect.Sect := oldSect;
 end;
end;

function TogsSymbol.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var oldSect: TSect;
    Matrix: TogsMatrix;
begin
 Result := False;
 If not ogsRect.PointIn(X_,Y_) then exit;
 oldSect := fSymbol.ogsRect.Sect;
 Matrix := SelectMatrix(TogsMatrix.Create({ogsMatrix.X +} X, {ogsMatrix.Y +} Y, ogsMatrix.Angle, ogsMatrix.Scale));
 try
  fSymbol.Calculate([calcbBox]);
  Result := fSymbol.SelectByPoint(X_,Y_,Params);
 finally
  DeleteMatrix(SelectMatrix(Matrix));
  fSymbol.ogsRect.Sect := oldSect;
 end;
end;

{ TogsTextString }

constructor TogsTextString.Create(Selector: TogsSelector;
 FontCollect_: TFontCollect; X_, Y_, Z_: Double; Height_, Angle_,
 Scale_: Double; Align_: TFEAlignments; Text_, AttrName_: String;
 TextColor: Integer; InBlock: Boolean);
begin
 inherited Create(X_,Y_,Z_,Selector);
 fFontCollect := FontCollect_;
 fText := Text_;
// создание коллекции символов TogsSymbol
 fSymbols := TogsGeometryCollection.Create(Selector);
//
 fHeight:= Height_;
 fAngle := Angle_;
 fScale := Scale_;
 fAlign := Align_;
//
 fAttrName := AttrName_;
 Color := TextColor;
 fBlock := InBlock;
 CalculateText;
end;

constructor TogsTextString.CreateAs(ogsObject: TogsBasic);
begin
 Assign(ogsObject);
 inherited CreateAs(ogsObject);
end;

destructor TogsTextString.Destroy;
begin
 inherited Destroy;
// TogsTextString может быть копируемым объектом
 If not isKeepObject then begin
  fSymbols.Free;
  SetLength(ABC, 0);
 end;
end;

function TogsTextString.Assign(ogsObject: TogsBasic): Boolean;
var Obj: TogsTextString;
begin
 Result:= False;
 If not(ogsObject is TogsTextString) then
   raise Exception.Create(ClassName+'.Assign: попытка присвоить объект типа ' + ogsObject.ClassName);
 Obj := TogsTextString(ogsObject);
 fFontCollect := Obj.fFontCollect;
 fText := Obj.fText;
 fSymbols := Obj.fSymbols;
 ABC := Obj.ABC;
 fHeight := Obj.fHeight;
 fAngle  := Obj.fAngle;
 fScale  := Obj.fScale;
 fAlign  := Obj.fAlign;
 fAttrName := Obj.fAttrName;
 Color := Obj.Color;
end;

function TogsTextString.GetSymbol(Index: Integer): TogsSymbol;
begin
 Result := fSymbols.List[Index];
end;

function TogsTextString.GetAttribute: String;
begin
 Result := fAttrName;
end;

procedure TogsTextString.SetAttribute(AttrName_: String);
begin
 fAttrName := AttrName_;
end;

procedure TogsTextString.SetColorBy(AValue: TColorBy); begin fColorBy := AValue; end;

function TogsTextString.GetColorBy: TColorBy; begin Result := fColorBy; end;

function TogsTextString.GetColor: TColor; begin Result := fColor; end;

procedure TogsTextString.SetColor(AValue: TColor); begin fColor := AValue; end;

procedure TogsTextString.CalculateText;
var pStr: PChar;
    Left, Index: Integer;
    charCode, charLen, glyphIndex: Integer;
    fontSymbol: TFontSymbol;
    lineTop: Integer;
    xLeft, Delta, ABCIndex: Integer;
    XF, YF: Double;
    uStr: TUTF8Char;
begin
// выстраиваем последовательность символов
 Index := 1;
 pStr := @fText[Index];
 Left := length(fText);
 xLeft := 0;
 ABCIndex := 0;
 ABC := fFontCollect.FEFont.CharsPosition(pStr, fAlign);
 While Left > 0 do begin
  charCode := UTF8CodePointToUnicode(pStr, charLen);
  Dec(Left, charLen);
  glyphIndex := fFontCollect.CharIndex(charCode);
  fontSymbol := fFontCollect[glyphIndex];
// на первом символе вычисляем смещение по Y
   If Index = 1 then lineTop := fontSymbol.advLine.Top;
   YF := - fontSymbol.advLine.Top + Round(ABC[ABCIndex].yBase * 64);
   XF := Round(ABC[ABCIndex].x * 64);
   uStr:=pStr;
   AddSymbol(XF, YF, pStr, fontSymbol);
   Inc(Index, charLen);
   Inc(ABCIndex);
   pStr := @fText[Index];
  end;
end;

procedure TogsTextString.AddSymbol(X_, Y_: Double; Char_: PChar;
 Symbol: TFontSymbol);
begin
 fSymbols.Add(TogsSymbol.Create(ogsSelector, X_,Y_,Z, Char_, Symbol));
end;

function TogsTextString.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
    Matrix: TogsMatrix;
    Symb: TogsSymbol;
    txScale: Double;
    mxAngle: Double;
    mxScale: Double;
begin
 If calcTess in Action then begin
  try
   txScale := fFontCollect.ScaleOf(fHeight);
  // txScale := ;
   If ogsMatrix <> nil then mxAngle := ogsMatrix.Angle else mxAngle := 0;
   If ogsMatrix <> nil then mxScale := ogsMatrix.Scale else mxScale := 1;
   If fBlock then
    Matrix := SelectMatrix(TogsMatrix.Create(X, Y, mxAngle + fAngle, txScale * mxScale)) else
    Matrix := SelectMatrix(TogsMatrix.Create(fX, fY, fAngle, txScale * fScale));
   For I := 0 to fSymbols.Count - 1 do
    Symbol[I].Calculate([calcTess]);
  finally
   DeleteMatrix(SelectMatrix(Matrix));
  end;
 end;
 If not(calcbBox in Action) then exit;
// вычисляем габариты строки текста и каждого символа внутри строки
 txScale := fFontCollect.ScaleOf(fHeight);
// txScale := ;
 If ogsMatrix <> nil then mxAngle := ogsMatrix.Angle else mxAngle := 0;
 If ogsMatrix <> nil then mxScale := ogsMatrix.Scale else mxScale := 1;
 If fBlock then
  Matrix := SelectMatrix(TogsMatrix.Create(X, Y, mxAngle + fAngle, txScale * mxScale)) else
  Matrix := SelectMatrix(TogsMatrix.Create(fX, fY, fAngle, txScale * fScale));
 ogsRect.Clear;
 try
  For I := 0 to fSymbols.Count - 1 do begin
   Symb := Symbol[I];
  // вычисляем статические габариты символа
   Symb.Calculate([calcbBox]);
 //  WriteIn(['Symbol=',I, Symb.Count, Symb.ogsRect]);
   ogsRect.InsertRect(Symb.ogsRect);
  end;
 finally
  DeleteMatrix(SelectMatrix(Matrix));
 end;
end;

procedure TogsTextString.Draw(Drawer: TogsDrawer);
var I: Integer;
    Matrix: TogsMatrix;
    txScale: Double;
    mxAngle: Double;
    mxScale: Double;
    Pen: TogsPen;
    Brush: TogsBrush;
begin
// exit;
 If not Visible(ogsSelector.ActiveRect) then exit;
 If Selected then
  Pen := Drawer.SelectPen(TogsPen.Create(clLime, 0, nil)) else
  Pen := Drawer.SelectPen(TogsPen.Create(Color, 0, nil));
  Brush := Drawer.SelectBrush(TogsBrush.Create(Color, nil));
 txScale := fFontCollect.ScaleOf(fHeight);
// txScale := 1;
 ogsRect.Draw(Drawer);
// WriteIn(['Matrix=',ogsMatrix.X, ogsMatrix.Y]);
 If ogsMatrix <> nil then mxAngle := ogsMatrix.Angle else mxAngle := 0;
 If ogsMatrix <> nil then mxScale := ogsMatrix.Scale else mxScale := 1;
 If fBlock then
  Matrix := SelectMatrix(TogsMatrix.Create(X, Y, mxAngle + fAngle, txScale * mxScale)) else
  Matrix := SelectMatrix(TogsMatrix.Create(fX, fY, fAngle, txScale * fScale));
 try
  For I := 0 to Count - 1 do
   Symbol[I].Draw(Drawer);
  If fBlock then Drawer.DrawMarker(X, Y) else
                  Drawer.DrawMarker(fX, fY);
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
  Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
  DeleteMatrix(SelectMatrix(Matrix));
 end;
end;

function TogsTextString.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
    Matrix: TogsMatrix;
    txScale: Double;
    mxAngle: Double;
    mxScale: Double;
begin
 If not(ogsRect.PointIn(X_,Y_)) then exit;
 txScale := fFontCollect.ScaleOf(fHeight);
// txScale := 1;
 If ogsMatrix <> nil then mxAngle := ogsMatrix.Angle else mxAngle := 0;
 If ogsMatrix <> nil then mxScale := ogsMatrix.Scale else mxScale := 1;
 If fBlock then
  Matrix := SelectMatrix(TogsMatrix.Create(X, Y, mxAngle + fAngle, txScale * mxScale)) else
  Matrix := SelectMatrix(TogsMatrix.Create(fX, fY, fAngle, txScale * fScale));
 try
  For I := 0 to Count - 1 do begin
   Result := Symbol[I].SelectByPoint(X_,Y_,Params);
   If Result then begin
    Params.resObject := Self;
    exit;
   end;
  end;
 finally
  DeleteMatrix(SelectMatrix(Matrix));
 end;
end;

function TogsTextString.Count: Integer;
begin
 Result := fSymbols.Count;
end;

{ TogsTextParams }

constructor TogsTextParams.CreateEmpty;
begin
 inherited CreateEmpty;
 fKeepObject := True;
end;

constructor TogsTextParams.Create(TextString_: TogsTextString;
 Selector: TogsSelector; FontCollect_: TFontCollect; X_, Y_, Z_: Double;
 Height_, Angle_, Scale_: Double; Align_: TFEAlignments; Text_,
 AttrName_: String; TextColor: Integer; InBlock: Boolean);
begin
 inherited Create(Selector, FontCollect_, X_,Y_,Z_,
                  Height_,Angle_,Scale_,Align_,Text_,AttrName_, TextColor, InBlock);
 TextString := TextString_;
end;

destructor TogsTextParams.Destroy;
var P: TClass;
begin
// вызов Destroy дедушки -> TogsPoint
{ P := PClass(Self)^;
 PClass(Self)^ := TogsPoint;
 TogsPoint(Self).Destroy;
 PClass(Self)^ := P;
}
// если объект не был создан как KeepObject
 inherited Destroy;
end;

function TogsTextParams.Assign(ogsObject: TogsBasic): boolean;
begin
 inherited Assign(ogsObject);
 KeepString := TogsTextParams(ogsObject);
end;

procedure TogsTextParams.KeepObject;
begin
// если KeepObject уже создан -> выход
 If KeepString <> nil then exit;
//   raise Exception.Create('TogsTextParams.ReleaseObject: KeepString = nil, отсутствует симметричный вызов KeepObject');
// создаем пустой объект
 KeepString := TogsTextParams.CreateEmpty;
// присваивем указатели
 KeepString.Assign(TextString);
 TextString.Assign(Self);
// WriteIn(['KeepStr=',KeepString.fText, TextString.fText]);
end;

procedure TogsTextParams.ReleaseObject;
begin
// если KeepObject уничтожен -> возможно был вложенный вызов ReleaseObject -> выход
 If KeepString = nil then exit;
//   raise Exception.Create('TogsTextParams.ReleaseObject: KeepString = nil, отсутствует симметричный вызов KeepObject');
 TextString.Assign(KeepString);
 KeepString.Free;
 KeepString := nil;
end;

function TogsTextParams.isKeepObject: Boolean;
begin
 Result := fKeepObject;
end;

{ TTextAttribs }

function CheckAttrProc (P: TogsBasic): Boolean;
begin
 Result := P is TogsTextParams;
end;

constructor TTextAttribs.Create;
begin
 inherited Create;
 CheckTypeProc := CheckAttrProc;
end;

function TTextAttribs.FindAttr(AttrName: String; CI: boolean): TogsTextParams;
var I: Integer;
begin
 Result := nil;
 For I := 0 to Count - 1 do
  If AnsiCompareText(AttrName, Attr[I].fAttrName) = 0 then begin
   Result := Attr[I];
   exit;
  end;
end;

function TTextAttribs.GetAttr(Index: Integer): TogsTextParams;
begin
 Result := Items[Index];
end;

procedure TTextAttribs.KeepObject;
var I: Integer;
begin
 For I := 0 to Count - 1 do Attr[I].KeepObject;
end;

procedure TTextAttribs.ReleaseObject;
var I: Integer;
begin
 For I := 0 to Count - 1 do Attr[I].ReleaseObject;
end;

initialization
 ogsFontManager := TogsFontManager.Create;
finalization
 ogsFontManager.Free;
end.


