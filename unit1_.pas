unit Unit1;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
     ogcIEObjects, ogcBasic;

type

 { TForm1 - GMF-обработчик}

 TForm1 = class(TDemoForm)
  Button5: TButton;
  Button6: TButton;
  Button7: TButton;
  Button8: TButton;
  Button9: TButton;
  Edit2: TEdit;
  MainMenu1: TMainMenu;
  MenuItem1: TMenuItem;
  MIMemFinish: TMenuItem;
  MImemStart: TMenuItem;
  OD: TOpenDialog;
  procedure btnLoadGMFClick(Sender: TObject);
  procedure Button1Click(Sender: TObject);
  procedure Button3Click(Sender: TObject);
  procedure Button5Click(Sender: TObject);
  procedure Button6Click(Sender: TObject);
  procedure Button7Click(Sender: TObject);
  procedure Button8Click(Sender: TObject);
  procedure Button9Click(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure FormDestroy(Sender: TObject);
  procedure FormPaint(Sender: TObject);
 private
 public
  PLib: TogsCollection;
  LLib: TogsCollection;
  memStart: Integer;
  procedure OnPaint(Sender: TObject); override;
 end;

var
 Form1: TForm1;

implementation uses WptForm2, Collect, newSelector, EcLot, EcDot, WpTwigs,
                    newBlock, Lib, Lines2, Lines3, ecDot2,
                    ogcGeometry, gmfGeometry, ogcWriter, TTFGeometry,
                    feFontEngineObjects, newFontScale,
                    DWGText, TextManager, LazUTF8, ogcPlayer,
                    ogcProperties;

{$R *.frm}

function SearchPointSign(PC: TSortedCollection; Num: Integer): Pointer;
var Index: Integer;
begin
 Index := SearchThis(PC, Num);
 If Index = -1 then Result := nil else Result := PC[Index];
end;

function SearchLineType(PC: TSortedCollection; Num: Integer): Pointer;
var Index: Integer;
begin
 Index := SearchLine(PC, Num);
 If Index = -1 then Result := nil else Result := PC[Index];
end;

function SearchPLib(PLib: TogsCollection; Name: AnsiString): TgmfBlock;
var I: Integer;
begin
 Result := nil;
 For I := 0 to PLib.Count - 1 do
  If TgmfBlock(PLib[I]).Name = Name then begin
   Result := PLib[I];
   exit;
  end;
end;

function SearchLLib(LLib: TogsCollection; Name: AnsiString): TgmfLineType;
var I: Integer;
begin
 Result := nil;
 For I := 0 to LLib.Count - 1 do
  If TgmfLineType(LLib[I]).Name = Name then begin
   Result := LLib[I];
   exit;
  end;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
 inherited;
 PLib := TogsCollection.Create;
 LLib := TogsCollection.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 inherited;
 PLib.Free;
 LLib.Free;
end;

procedure TForm1.FormPaint(Sender: TObject);
begin

end;

procedure TForm1.btnLoadGMFClick(Sender: TObject);
var TwgForm: TForm2; Stream: TBufStream;
    oldSelector: TSelector;
    Lot: TLot;
    I, J, K: Integer;
    B: Byte;
    PD: TPointDot;
    Point: TgmfPoint;
    Line : TogsLineString;
    MLine: TgmfMultiLineString;
    Poly : TPoly_Single;
    Polygon: TgmfPolygon;
    Sign: TPoint_Sign;
    StrZ: String;
    DT: TDotText;
    txtString: TogsTextString;
    FC: TFontCollect;
Function CreatePointSign(P: TPoint_Sign; inLineType: Boolean): TgmfBlock;
var I: Integer;
    Geometry: TGeometryEvents;
procedure CreateAttribs;
var I: Integer;
    dwgText: TDWG_Text;
    Text: TogsTextString;
    TextParams: TogsTextParams;
begin
 If (not inLineType) and (PD.TextManager <> nil) then
  For I := 0 to PD.TextManager.FValues.Count - 1 do
   With TTextParams(PD.TextManager.FValues[I]) do begin
    dwgText := PD.TextManager.FTexts[I];
   // поиск аттрибута в TGM9FBlock
    If Result.FindAttribute(dwgText.fName, Pointer(Text)) then begin
    // создаем KeepObject -> добавляяем его в Point.Attributes
     If ShiftX <> 0 then
      TextParams := TogsTextParams.Create(Text, Text.ogsSelector, Text.fFontCollect, ShiftX, ShiftY, 0,
                     fH, fUgol, Text.fScale, Text.fAlign, fValue,
                     dwgText.fName, True) else
      TextParams := TogsTextParams.Create(Text, Text.ogsSelector, Text.fFontCollect, fDx, fDy, 0,
                     fH, fUgol, Text.fScale, Text.fAlign, fValue,
                     dwgText.fName, True);
     Point.AddAttribute(TextParams);
   end;
 end;
end;
begin
 Result := SearchPLib(PLib, P.MyNameIs);
// создаем атрибуты TTextParam из PD.TTextManaeger
// If PD.TextManager <> nil then PD.TextManager.UpdateText(0);
 If Result <> nil then begin
  CreateAttribs;
  exit;
 end;
// создаем блок
//outDisabled := false;
// WriteIn(['SignNAme=',P.MyNameIs, P.MyInd, P.X, P.Y]);
 Result := TgmfBlock.Create(Selector, P.MyNameIs, P.MyInd, P.X, P.Y, 0);
 Geometry := TGeometryEvents.Create(nil, nil);//Result.PolyEvent, Result.TextEvent);
 P.DrawTo(Geometry);
 Geometry.Free;
// создаем атрибуты
 CreateAttribs;
// If PD.TextManager <> nil then PD.TextManager.Restore;
// вставляем
 PLib.Add(Result);
// WriteIn(['End']);
// outDisabled := True;
end;
Function CreatePointBlock(P: TGeoBlock): TgmfBlock;
var Geometry: TGeometryEvents;
    I: Integer;
    PD: TPointDot; DT: TDotText; B: Byte;
procedure CreateAttribs;
var I: Integer;
    Text: TogsTextString;
    TextParams: TogsTextParams;
begin
// создаем атрибуты TTextParams из P.txtProperties
 If P.txtProperties <> nil then
  For I := 0 to P.txtProperties.Count -1 do
  // поиск атрибута в TGMFBlock
   If Result.FindAttribute(P.txtProperties[I].PropName, Pointer(Text)) then
    With Text do begin
   // создаем KeepObject -> добавляяем его в Point.Attributes
     TextParams := TogsTextParams.Create(Text, ogsSelector, fFontCollect, X, Y, Z,
                    fHeight, fAngle, fScale, fAlign, P.txtProperties[I].PropValue.Value,
                    fAttrName, True);
     Point.AddAttribute(TextParams);
    end;
end;
begin
 Result := SearchPLib(PLib, P.Name);
 If Result <> nil then begin
  CreateAttribs;
  exit;
 end;
// создаем блок
// outDisabled := False;
// WriteIn(['BlockName = ',P.Name,P.X, P.Y]);
 Result := TgmfBlock.Create(Selector, P.Name, -1, P.X, P.Y, 0);
 Geometry := TGeometryEvents.Create(nil, nil);//Result.PolyEvent, Result.TextEvent);
  P.DrawTo(Geometry);
 Geometry.Free;
// создаем атрибуты
 CreateAttribs;
// вставляем в список блоков
 PLib.Add(Result);
 Result.Calculate([calcbBox, calcSquare, calcRelation, calcSortBy]);
// WriteIn(['BlockRect=',Result.ogsRect]);
end;
Function CreateLineType(P: TGeoLine): TgmfLineType;
var PS: TLineStruct;
    I: Integer;
    Point: TPoint_Sign;
procedure CreatePointView(P: TGeoLine);
var I, Index:Integer;
    PS: TLineStruct;
    Block: TgmfBlock;
    Point: TPoint_Sign;
begin
P.Points.DeleteAll;
For I := 0 to P.Structura.Count-1 do begin
  PS := P.Structura.At(I);
  if PS.BitOf = bt_Custom then begin
   Point := SearchPointSign(oldSelector.GPointCol, Round(PS.Param4));
   If Point <> nil then begin
     Block := CreatePointSign(Point, True);
     If Block <> nil then
      P.Points.Insert(Block)
     else P.Points.Insert(@ZnakNil);
    end else P.Points.Insert(@ZnakNil);
   end else P.Points.Insert(@ZnakNil);
 end;
end;
begin
 Result := nil; If P = nil then exit;
// создаем тип линии, содержащий ссылку на TGeoLine
 Result := SearchLLib(LLib, P.NameOf);
 If Result <> nil then exit;
 Result := TgmfLineType.Create(Selector, P);
// связываем тип линии с точечными блоками для рисовки блока в линии
 CreatePointView(Result.Sign);
// вставляем в список типов линий
 LLib.Add(Result);
end;
begin
 Result := nil; If P = nil then exit;
// создаем тип линии, содержащий ссылку на TGeoLine
 Result := SearchLLib(LLib, P.NameOf);
 If Result <> nil then exit;
 Result := TgmfLineType.Create(Selector, P);
// связываем тип линии с точечными блоками для рисовки блока в линии
 CreatePointView(Result.Sign);
// вставляем в список типов линий
 LLib.Add(Result);
end;
function AlignText(B: Byte): TFEAlignments;
begin
 Case B of
  0 : Result:= [ftaLeft, ftaBottom];
  1 : Result:= [ftaLeft, ftaBaseLine];
  2 : Result:= [ftaLeft, ftaVerticalCenter];
  3 : Result:= [ftaLeft, ftaTop];
  4 : Result:= [ftaCenter, ftaBottom];
  5 : Result:= [ftaCenter, ftaBaseLine];
  6 : Result:= [ftaCenter, ftaVerticalCenter];
  7 : Result:= [ftaCenter, ftaTop];
  8 : Result:= [ftaRight, ftaBottom];
  9: Result := [ftaRight, ftaBaseLine];
  10: Result:= [ftaRight, ftaVerticalCenter];
  11: Result:= [ftaRight, ftaTop];
 end;
{ Add('влево-основание');
 Add('влево-низ');
 Add('влево-центр');
 Add('влево-верх');
 Add('центр-основание');
 Add('центр-низ');
 Add('центр-центр');
 Add('центр-верх');
 Add('вправо-основание');
 Add('вправо-низ');
 Add('вправо-центр');
 Add('вправо-верх');
}
end;
function ItalicBold(FView: TFontViewEx): TFEStyles;
begin
 Result := [];
 If FView.it = 1 then Result:= Result + [ftsItalic];
 If FView.bl = 1 then Result:= Result + [ftsBold];
end;
begin
 WriteIn(['Prepare load...']);
 Prims.FreeAll;
 If Sender = nil then
 Stream := TBufStream.InitFileStream(OD.FileName, fmOpenRead) else
 // Stream:=TBufStream.InitFileStream('C:\D\!GEOMASTER3\Typhon\Objecst\6357 Polini Osipenko ul. 14 k.1.gmf',fmOpenRead);
 // Stream:=TBufStream.InitFileStream('C:\D\!GeoTyphon\21465_Tulskaya M. ul. 8 uz.gmf',fmOpenRead);
  Stream := TBufStream.InitFileStream('C:\D\!GeoTyphon\21465_Tulskaya M. ul. 8 dzm.gmf', fmOpenRead);
 oldSelector:=TSelector.Create;
 oldSelector.GNForm:=Self;
 oldSelector.GCanvas:=Self.Canvas;
 Stream.Selector:=oldSelector;
 WriteIn(['Loading > ',TimeToStr(Now)]);
 TwgForm:=TForm2(Stream.Get);
 Stream.Free;
 WriteIn(['Loaded > ',TimeToStr(Now)]);
// создаем объекты для отображения
 WriteIn(['LotsCount =',TwgForm.Twigs.LotsLarge.Count, TwgForm.Twigs.TwigsLarge.Count, TwgForm.Twigs.AnyLarge.Count]);
// связывание
 TwgForm.ClassbuildII;
 WriteIn(['Built']);
// грузим площадные/линейные с ogsProperties
 For I := 0 to TwgForm.Twigs.LotsCount -1 do begin
  Lot := TwgForm.Twigs.LAt(I);
  Lot.InsClipDotsParall(TwgForm.Twigs);
  If Lot. TypeLot = 1 then begin
  // в линейный передаем знак из библиотеки
  // Writein(['Line=',I]);
   If Lot.Coord.Count > 1 then begin
    MLine := TgmfMultiLineString.Create(Selector);
    MLine.CreateSysProperties(Fmt(['{"System": {"Color" :', Lot.LotLineColor,', "Sign" :',Lot.csLineZnak,'}}']));
    MLine.Color := Lot.LotLineColor;
    MLine.Sign := CreateLineType(SearchLineType(oldSelector.GLineCol, Lot.csLineZnak));
  // вписываем сегменты в мультилинию
    For J := 0 to Lot.Coord.Count - 1 do With Lot.GetTwig(TwgForm.Twigs, J) do begin
     Line := TogsLineString.Create(Self.Selector);
     Line.Color := MLine.Color;
     Line.Sign := MLine.Sign;
     For K := 0 to Coord.Count - 1 do With TDot(Coord[K]) do begin
      Line.AddPoint(XDot, YDot, 0);
      Self.Selector.AddCoord(XDot, YDot);
     end;
     MLine.AddLine(Line);
    end;
    Prims.Add(MLine);
    MLine.Calculate([calcLength, calcbBox]);
   end else begin
    Line := TgmfLineString.Create(Self.Selector);
    Line.CreateSysProperties(Fmt(['{"System": {"Color" :', Lot.LotLineColor,', "Sign" :',Lot.csLineZnak,'}}']));
    Line.Color := Lot.LotLineColor;
    Line.Sign := CreateLineType(SearchLineType(oldSelector.GLineCol, Lot.csLineZnak));
     For J := 0 to Lot.Points.Count - 1 do With TDot(Lot.Points[J]) do begin
      Self.Selector.AddCoord(XDot, YDot);
      Line.AddPoint(XDot, YDot, 0);
     end;
    Prims.Add(Line);
   end;
 //  Writein(['LineEnd=',I]);
  end else begin
 // Writein(['poly=',I]);
   Poly := TPoly_Single.Create(Selector);
  //
   Polygon := TgmfPolygon.Create(Selector);
   Polygon.AddPolygon(Poly as TPoly_Single);
   Polygon.CreateSysProperties(Fmt(['{"System": {"Color" :', Lot.LotColor,'}}']));
  //
   Prims.Add(Polygon);
   Polygon.Color := Lot.LotColor;
   Polygon.LineColor := Lot.LotLineColor;
   For J := 0 to Lot.Points.Count - 1 do With TDot(Lot.Points[J]) do begin
    Self.Selector.AddCoord(XDot, YDot);
    Poly.AddPoint(XDot, YDot, 0);
   end;
   Polygon.Calculate([calcRelation, calcSquare, calcbBox]);
   // With POlygon.ogsRect do WriteIn(['Rect=',XMin, YMin, XMax, YMax, Polygon.Count]);
 //  Writein(['polyEnd=',I]);
  end;
  Lot.Points.Free;
 end;
// загружаем точечные, передаем знак из библиотеки
 ogsFontManager.FreeAll;
 ogsFontManager.LoadFontList(Selector);
// WriteIn(['Selector0=',Selector.ogsRect]);
 For I := 0 to TwgForm.Twigs.AnyCount -1 do begin
  PD:= TwgForm.Twigs.AAt(I, B);
//  WriteIn(['Point =',I]);
  If PD is TDotText then begin
   DT := PD as TDotText;
  // ищем шрифт
   FC := ogsFontManager.FindBy(DT.Text.fontView.FontName, ItalicBold(DT.Text.fontView));
   If (FC = nil) then begin
    WriteIn(['Не найден шрифт: '+DT.Text.fontView.FontName]);
    continue;
   end;
  // загружаем шрифт из файла
   FC.LoadModeComplete;
   txtString := TogsTextString.Create(Selector, FC, DT.XDot, DT.YDot, 0, DT.Text.Height,
                                      DT.Ugol, DT.XKoef, AlignText(DT.Text.Align), DT.Text.Text, DT.Text.AttrName, False);
   txtString.CreateSysProperties(Fmt(['{"System": {"Color" :', DT.Text.Color,', "Text" :',DT.Text.Text,', "FontName" :',DT.Text.fontView.FontName,'}}']));
   txtString.Calculate([calcbBox]);
   Selector.AddPrim(txtString);
   Prims.Add(txtString);
   continue;
  end;
  Point := TgmfPoint.Create(PD.XDot, PD.YDot, PD.Z, Selector);
  If PD.userObj <> nil then begin
   Point.CreateSysProperties(Fmt(['{"System": {"Color" :', PD.PointColor,',"Block" :',
                                  TGeoBlock(PD.userobj).Name,'}}']));
 // разбираем блок на примитивы
   TGeoBlock(PD.userObj).txtProperties := PD.Properties;
   Point.Sign := CreatePointBlock(PD.userObj as TGeoBlock);
   Point.Angle := PD.Ugol;
   Point.Scale := PD.XKoef;
   Point.Calculate([calcbBox, calcRelation, calcSquare]);
//   With Point.ogsRect do WriteIn(['PointBlock.Rect=',XMin, YMin, XMax, YMax]);
  end else begin
 // без блока, предполагаем, что есть условный знак
   Point.CreateSysProperties(Fmt(['{"System": {"Color" :', PD.PointColor,', "Sign" :',PD.GetZnak,'}}']));
   Sign := SearchPointSign(oldSelector.GPointCol, PD.GetZnak);
   If Sign <> nil then begin
    Point.Sign := CreatePointSign(Sign, False);
    Point.Angle := PD.Ugol;
    Point.Scale := PD.Koef;
   end;
   Point.Calculate([calcbBox, calcRelation, calcSquare]);
//   With Point.ogsRect do WriteIn(['PointZnak.Rect=',XMin, YMin, XMax, YMax]);
  end;
 //
  Selector.AddPrim(Point);
  Prims.Add(Point);
  Point.Color := PD.PointColor;
 // разбираем условный знак на примитивы
// WriteIn(['PointEnd =',I]);
 end;
 outDisabled := False;
 WriteIn(['Translated > ', TimeToStr(Now)]);
 TwgForm.Free;
 Selector.UpdateRects(True);
 WriteIn([Selector.ogsRect]);
 Button2Click(Sender);
end;

procedure TForm1.Button1Click(Sender: TObject);
var memMgr: TMemoryManager;
    Status: THeapStatus;
    T, T1, T2: Integer;
    I: Integer;
begin
 inherited;
 Selector.DevScale;
 GetMemoryManager(memMgr);
 Status:=memMgr.GetHeapStatus; T1:=Status.TotalFree;
 WriteIn(['memoryStart=',Status.TotalFree]);
 DisableIn;
 For I := 1 to 100000 do begin
  OnPaint(nil);
  If I mod 10000 = 0 then begin
   Status := memMgr.GetHeapStatus; T2 := Status.TotalFree;
   EnableIn;
   WriteIn([T2-T1]);
   DisableIn;
  end;
//  T := Status.TotalFree;
 // Status:=memMgr.GetHeapStatus;
 // WriteIn(['memoryFinish=',Status.TotalFree,' ',T-T1]);
//  If T - T1 >0 then WriteIn(['+']);
 end;
 EnableIn;
 Status := memMgr.GetHeapStatus; T2 := Status.TotalFree;
 WriteIn(['memoryFinish=',Status.TotalFree,' ',T2-T1]);
end;

procedure TForm1.Button3Click(Sender: TObject);
var S:UnicodeString; I: Integer;
    C:UnicodeChar;
begin
// S := Edit2.Text;
 WriteIn(['Len=',Length(S),UTF8Length('Тест UTF8')]);
 SetLength(S,UTF8Length('Тест UTF8'));
 UTF8ToUnicode(PUniCodeChar(S),'Тест UTF8',UTF8Length('Тест UTF8'));
 For I := 1 to Length(S) do begin
  C := S[I];
  WriteIn(['Chr=',S[I],'I=',I,C]);
 end;
 SetLength(S,0);
// inherited;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
 If OD.Execute then btnLoadGMFClick(nil);
end;

procedure TForm1.OnPaint(Sender: TObject);
var timeStart: TDateTime;
begin
 If Drawer = nil then exit;
 EnableIn;
 If MImemStart.Caption = 'memStart' then begin
  memStart := Selector.memFreeStart;
  MImemStart.Caption := Fmt(['memStart =',Selector.memFreeStart]);
 end;
 WriteIn(['memoryStart=', Selector.memFreeStart]);
 If Drawer.cmdPlayer.Count <> 0 then begin
//  WriteIn(['beginPlay']);
  timeStart := GetTickCount;
  Drawer.BeginPaint;
  Drawer.Clear(clWhite);
  Drawer.Play(Drawer);
  Drawer.EndPaint;
//  WriteIn(['endPlay : ',GetTickCount - timeStart]);
 end else inherited OnPaint(Sender);
 WriteIn(['memoryFinish=', Selector.memFreeFinish, SizeOf(TMemoryManager)]);
  MImemFinish.Caption := Fmt(['memDiff =',Selector.memFree  - memStart]);
end;

procedure TForm1.Button6Click(Sender: TObject);
var Counter: TgmfPlayer;
    currentDrawer: TogsDrawer;
begin
 Counter := TgmfPlayer.Create(Selector);
 currentDrawer := Drawer;
 Drawer := Counter;
 try
  Selector.ActiveRect.Inflate(-1,-1);
  Button2Click(Self);
  Selector.ActiveRect.Inflate(1,1);
 finally
  Drawer := currentDrawer;
  WriteIn(['Drawer.Count=',Drawer.cmdPlayer.Count]);
 end;
 Counter.SaveToFile(ExtractFilePath(ParamStr(0))+'tstPalyer.gr');
 Counter.cmdPlayer := TogsCollection.Create;
 Counter.Free;
end;

procedure TForm1.Button7Click(Sender: TObject);
var Counter: TgmfPlayer;
begin
 Counter := TgmfPlayer.Create(Selector);
 Counter.LoadFromFile(ExtractFilePath(ParamStr(0))+'tstPalyer.gr');
 Drawer.cmdPlayer := Counter.cmdPlayer;
 Counter.cmdPlayer := TogsCollection.Create;
 Counter.Free;
//
 Selector.UpdateRects(True);
 WriteIn([Selector.GlobalRect]);
 WriteIn([Selector.ActiveRect]);
 Button2Click(Self);
end;

procedure TForm1.Button8Click(Sender: TObject);
var I: Integer;
begin
 For I := 0 to Prims.Count - 1 do
  If Prims[I] is TogsPoint then
   WriteIn([Prims[I].ToString]);
end;

procedure TForm1.Button9Click(Sender: TObject);
var I: Integer;
begin
 WriteIn([TimeToStr(Time)]);
 For I := 0 to 2000 do
  TypeOfString(Edit2.Text);
 WriteIn([TimeToStr(Time), TypeOfString(Edit2.Text)]);
end;

end.

