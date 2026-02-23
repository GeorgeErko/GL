library gmflib;

{$mode Delphi}{$H+}


uses Interfaces, Classes, SysUtils, Forms, ogcCallBackRec, ogcWriter,
    //
     newProcs, WptForm2, Collect, newSelector, EcLot, EcDot, WpTwigs, newBlock,
     Lib, Lines2, Lines3, ecDot2,  newFontScale, DWGText, TextManager,
     LazUTF8, ogccallbacktypes, MainForm, libProcs;

// Локальные ф-ции

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

// Интерфейсные ф-ции *********************************************************

function OpenGMF(AppHandle: THandle; FileName: String; CallbackRec_: PCallbackRec): Integer; stdcall;
label 2;
var TwgForm: TForm2; Stream: TBufStream;
    oldSelector: TSelector;
    Lot: TLot;
    I, J, K: Integer;
    B: Byte;
    PD: TPointDot;
    Sign: TPoint_Sign;
    DT: TDotText;
    propStr: String;
    hObject, hPoint, hBlock, Line, mLine, hText, Poly, mPoly, hLineType: hObj;
    GeoPoint, rootP:PGeoPoint;
Function CreatePointBlock(P: TGeoBlock): hObj;
var Geometry: TGeometryEvents;
    hBlock: hObj;
procedure CreateAttribs;
var I: Integer; hAttr: hObj;
begin
// атрибуты P.txtProperties -> TogsTextParams
 If P.txtProperties <> nil then
  For I := 0 to P.txtProperties.Count -1 do begin
  // поиск атрибута в блоке, если найден -> устанавливаем параметры
   hAttr := FindBlockAttrib(hBlock, P.txtProperties[I].PropName);
   If hAttr <> 0 then
    CreatePointAttrValue(hPoint, hAttr, P.txtProperties[I].PropValue.Value);
   // сбрасываем hAttr
    ResetObject(hAttr);
  end;
end;
begin
// поиск блока в библиотеке
 hBlock := FindBlock(hObject, P.Name);
 If hBlock <> 0 then CreateAttribs else begin
// создаем блок
// WriteStr(Fmt(['BlockName = ',P.Name,P.X, P.Y]));
  hBlock := CreateBlock(hObject, P.Name, P.X , P.Y , 0);
  If hBlock <> 0 then begin
   Geometry := TGeometryEvents.Create(hBlock, CallbackRec.PolyEvent, CallbackRec.TextEvent);
    P.DrawTo(Geometry);
   Geometry.Free;
   CreateAttribs;
 // WriteStr(Fmt(['BlockRect=',Result.ogsRect]));
  end;
 end;
 Result := hBlock;
// сбрасываем hBlock
// ResetObject(hBlock);
end;
Function CreatePointSign(P: TPoint_Sign; inLineType: Boolean): hObj;
var Geometry: TGeometryEvents;
    hBlock: hObj;
procedure CreateAttribs;
var I: Integer;
    dwgText: TDWG_Text;
    hAttr: hObj;
begin
// атрибуты PD.TTextManaeger -> TTextParam
 If (not inLineType) and (PD.TextManager <> nil) then
  For I := 0 to PD.TextManager.FValues.Count - 1 do
   With TTextParams(PD.TextManager.FValues[I]) do begin
    dwgText := PD.TextManager.FTexts[I];
   // поиск аттрибута в TGM9FBlock
    hAttr := FindBlockAttrib(hBlock, dwgText.fName);
    If hAttr <> 0 then begin
    // создаем KeepObject -> добавляяем его в Point.Attributes
     // WriteIn(['Attr=',dwgText.fName,'value=',fValue,'color=', dwgText.fColor,dwgText.fBgColor]);
     If ShiftX <> 0 then
      CreatePointAttrib(hPoint, hAttr, ShiftX, ShiftY, 0, fH, fUgol, fValue, dwgText.fColor) else
      CreatePointAttrib(hPoint, hAttr, fDx, fDy, 0, fH, fUgol, fValue, dwgText.fColor);
    end;
    ResetObject(hAttr);
   end;
end;
begin
 // поиск блока в библиотеке
 hBlock := FindBlock(hObject, P.MyNameIs);
 If hBlock <> 0 then CreateAttribs else begin
// создаем блок
// WriteIn(['SignNAme=',P.MyNameIs, P.MyInd, P.X, P.Y]);
  hBlock := CreateBlock(hObject, P.MyNameIs, P.X, P.Y, 0);
  If hBlock <> 0 then begin
   Geometry := TGeometryEvents.Create(hBlock, CallbackRec.PolyEvent, CallbackRec.TextEvent);
    P.DrawTo(Geometry);
   Geometry.Free;
   CreateAttribs;
  end;
 end;
 Result := hBlock;
// сбрасываем hBlock
// ResetObject(hBlock);
end;
// передаем тип линии
Function CreateLineType_(P: TGeoLine): hObj;
var LS: Lines3.TLineStruct;
    PLT: TPartOfLineType;
    PS: TPoint_Sign;
    I: Integer;
begin
 If P = nil then exit;
// ищем тип линии
//WriteIn(['beginproc']);
 Result := FindLineType(hObject, P.NameOf);
// WriteIn(['FindLT======', P.NameOf, Result]);
// создаем тип линии
 If Result = 0 then begin
  P.CreatePoints(oldSelector.GPointCol);
  Result := CreateLineType(hObject, P.NameOf);
   For I := 0 to P.Structura.Count-1 do begin
    LS := P.Structura.At(I);
  //  LS.Write();
    PLT.Create;
    // устанавливаем имя блока для части типа линии
     If LS.BitOf = AllBits(bt_Custom) then begin
    //  WriteIn(['FindBlock1']);
      PS := SearchPointSign(oldSelector.GPointCol, Round(LS.Param4));
       //     WriteIn(['FindBlock1']);
      If PS = nil then continue;
      LS.Param4S := PChar(PS.MyNameIs);
        //  WriteIn(['CreatePointSign1']);

      CreatePointSign(PS, True);
              //  WriteIn(['CreatePointSign2']);
     // WriteIn(['NamePZn', LS.Param4S]);
     end;
    LS.FillPartOfLineType(PLT);
   // добавляем часть типа линии
  //  WriteIn(['addLT1']);
    AddPartOfLineType(Result, PLT);
  //  WriteIn(['addLT2']);
    PLT.Free;
   end;
  P.Points.DeleteAll;
 end;
// WriteIn(['exitproc']);
end;
begin
// структура с процедурами обратного вызова из вызывающей программы
 CallbackRec := CallBackRec_;
// инициализация Application.Handle := AppHandle
 InitAppCallback;
//
 HObject := CallbackRec.HObject;
 WriteIn(['Prepare load...', AppHandle, HObject]);
//
 Stream := TBufStream.InitFileStream(FileName, fmOpenRead);
 oldSelector:=TSelector.Create;
 oldSelector.GNForm := TForm1.Create(AppCallback);
 oldSelector.GCanvas := TForm(oldSelector.GNForm).Canvas;
 ApplicationMainForm := TForm(oldSelector.GNForm);
 Stream.Selector:=oldSelector;
//
 WriteIn(['Loading > ',TimeToStr(Now)]);
 TwgForm:=TForm2(Stream.Get);
 Stream.Free;
 WriteIn(['Loaded > ',TimeToStr(Now)]);
// создаем объекты для отображения
 WriteIn(['LotsCount =',TwgForm.Twigs.LotsLarge.Count,
                          TwgForm.Twigs.TwigsLarge.Count, TwgForm.Twigs.AnyLarge.Count]);
// связывание
 TwgForm.ClassbuildII;
 WriteIn(['Built']);
// грузим площадные/линейные с ogsProperties
 For I := 0 to TwgForm.Twigs.LotsCount -1 do begin
  Lot := TwgForm.Twigs.LAtIndex(I);
  Lot.InsClipDotsParall(TwgForm.Twigs);
  If Lot.TypeLot = 1 then begin
  // в линейный передаем знак из библиотеки
//   Writein(['Coord.Count=',Lot.Coord.Count]);
   If Lot.Coord.Count > 1 then begin
    propStr := Fmt(['{"System": {"Type" : "MultiLine", "Color" :', Lot.LotLineColor,', "Sign" :',Lot.csLineZnak,'}}']);
    hLineType := 0;
    If Lot.CsLineZnak = -1 then
     hLineType := CreateLineType_(SearchLineType(oldSelector.GLineCol, Lot.csLineZnak));
    mLine := CreateMPolyLine(hObject, Lot.LotLineColor, 0, 0, Lot.CsKoef, True, PChar(propStr));
//    MLine.Sign := CreateLineType(SearchLineType(oldSelector.GLineCol, Lot.csLineZnak));
    if mLine = 0 then continue;
  // вписываем сегменты в мультилинию
     For J := 0 to Lot.Coord.Count - 1 do With Lot.GetTwig(TwgForm.Twigs, J) do begin
      New(GeoPoint); rootP := GeoPoint;
      For K := 0 to Coord.Count - 1 do With TDot(Coord[K]) do
       If K = 0 then GeoPoint.Create(XDot, YDot, 0) else begin
                     GeoPoint.AddPoint(XDot, YDot, 0);
                     GeoPoint := GeoPoint.Next;
                    end;
      rootP.Count := Coord.Count;
      AddPolyPoints(mLine, rootP);
      rootP.FreeAll;
      Dispose(rootP);
     end;
    AddPrimitive(hObject, mLine);
    ResetObject(mLine);
   end else begin
    propStr := Fmt(['{"System": {"Type" : "Polyline", "Color" :', Lot.LotLineColor,', "Sign" :',Lot.csLineZnak,'}}']);
   // создаем тип линии
    hLineType := 0;
    If Lot.CsLineZnak <> -1 then
     hLineType := CreateLineType_(SearchLineType(oldSelector.GLineCol, Lot.csLineZnak));
    New(GeoPoint); rootP := GeoPoint;
//    Writein(['PCount=',Lot.Points.Count]);
     For K := 0 to Lot.Points.Count - 1 do With TDot(Lot.Points[K]) do begin
      If K = 0 then GeoPoint.Create(XDot, YDot, 0) else begin
                    GeoPoint.AddPoint(XDot, YDot, 0);
                    GeoPoint := GeoPoint.Next;
                   end;
//      WriteIn(['XY=',XDot, YDot]);
      end;
    rootP.Count := Lot.Points.Count;
  //  WriteIn(['Koef===',Lot.CsKoef]);
    Line := CreatePolyLine(hObject, rootP, Lot.LotLineColor, 0, hLineType, Lot.CsKoef, True, PChar(propStr));
    rootP.FreeAll;
    Dispose(rootP);
    if Line = 0 then continue;
   //
   AddPrimitive(hObject, Line);
   ResetObject(Line);
    resetObject(hLineType);
   end;
 //  Writein(['LineEnd=',I]);
  end else begin // If Lot.TypeLot = 2 ...
   propStr := Fmt(['{"System": {"Type" : "Polygon", "Color" :', Lot.LotColor, '}}']);
   Poly := CreatePolygon(hObject, Lot.LotColor, {0 Sign = nil,} True, PChar(propStr));
   If Poly = 0 then continue;
   New(GeoPoint); rootP := GeoPoint;
    For K := 0 to Lot.Points.Count - 1 do With TDot(Lot.Points[K]) do
     If K = 0 then GeoPoint.Create(XDot, YDot, 0) else begin
                   GeoPoint.AddPoint(XDot, YDot, 0);
                   GeoPoint := GeoPoint.Next;
                  end;
   rootP.Count := Lot.Points.Count;
   AddPolyPoints(Poly, rootP);
   rootP.FreeAll;
   Dispose(rootP);
   AddPrimitive(hObject, Poly);
   ResetObject(Poly);
  end;
  Lot.Points.Free;
 end;
//
// загружаем точечные, передаем знак из библиотеки
// CallbackRecWriteIn(['Selector0=',Selector.ogsRect]);
//goto 2;
 For I := 0 to TwgForm.Twigs.AnyCount -1 do begin
  PD:= TwgForm.Twigs.AAt(I, B);
  If PD is TDotText then begin
   DT := PD as TDotText;
  // WriteIn(['=nil=',DT.Text.fontView.FontName, DT.XDot, DT.Text.AttrName,DT.Text.Text]);
   propStr := Fmt(['{"System": {"Color" :', DT.Text.Color,', "Text" :',DT.Text.Text,', "FontName" :',DT.Text.fontView.FontName,'}}']);
   hText := CreateText(hObject, DT.XDot, DT.YDot, 0, PChar(DT.Text.fontView.FontName), DT.Text.Height,
                         DT.Ugol, DT.XKoef, DT.Text.Color, DT.Text.Align,
                          False, False, False, PChar(DT.Text.Text), PChar(DT.Text.AttrName), PChar(propStr));
   If hText <> 0 then
    AddPrimitive(hObject, hText);
   continue;
  end;
 // создаем дескриптор точки
  hPoint := CreatePoint(hObject, PD.XDot, PD.YDot, PD.Z);
  If hPoint <> 0 then begin
 //
   If PD.userObj <> nil then begin
  // формируем json - строку для отображения системных свойств
    propStr := Fmt(['{"System": {"Color" :', PD.PointColor,',"Block" :',
                                      TGeoBlock(PD.userobj).Name,'}}']);
  // экспортируем блок по примитивам
    hBlock := CreatePointBlock(PD.userObj as TGeoBlock);
  // устанавливаем свойства точки
    If SetPointParams(hPoint, PD.PointColor, PD.Ugol, PD.XKoef, hBlock, PChar(propStr)) then begin
     AddPrimitive(hObject, hPoint);
    end;
   // ResetObject(hPoint);
   // ResetObject(hBlock);
   end else begin
  // без блока, предполагаем, что есть условный знак
    propStr := Fmt(['{"System": {"Color" :', PD.PointColor,', "Sign" :',PD.GetZnak,'}}']);
    Sign := SearchPointSign(oldSelector.GPointCol, PD.GetZnak);
    // устанавливаем свойства точки
     If Sign <> nil then begin
     // экспортируем знак по примитивам
      hBlock := CreatePointSign(Sign, False);
     end else
      hBlock := 0;
     If SetPointParams(hPoint, PD.PointColor, PD.Ugol, PD.Koef, hBlock, PChar(propStr)) then
      AddPrimitive(hObject, hPoint);
    // ResetObject(hPoint);
     //ResetObject(hBlock);
    end;
  end;
 // разбираем условный знак на примитивы
 // CallbackRec.WriteIn(['PointEnd =',I]);
 end;
 2:
 WriteIn(['UpdateObj']);
// пересчет координат объекта + очистка мусора
 CallbackRec.UpdateObject(hObject, True);
 WriteIn(['Translated > ', TimeToStr(Now)]);
 TwgForm.Free;
 oldSelector.GNForm.Free;
 oldSelector.Free;
 WriteIn(['FreeAndExit']);
end;

exports OpenGMF;

initialization
 Application.Initialize;
  Writeln('GMFLib.dll -> Started...');
finalization
 WriteIn(['GMFLib.dll -> Destroy...']);
 DoneAppCallback;
end.



