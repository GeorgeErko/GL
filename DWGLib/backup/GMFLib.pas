unit GMFLib;

{$mode Delphi}

interface

uses Classes, SysUtils, Forms, ogsCallBackRec;

var
  CallbackRec: PCallbackRec;

 procedure Clear;
 function CreatePointHandle(X, Y, Z: Double): boolean;
 function SetPointParams(Color: Integer; Angle, Scale: Double; addParams: String): boolean;
 function FindBlockHandle(blockName: String): boolean;
 function CreateBlockHandle(blockName: String; X, Y, Z: Double): boolean;
 function FindBlockAttrib(attrName: String): boolean;
 function CreateBlockAttrib(X, Y, Z, Height, Angle: Double; Value: String): boolean;
 function CreateBlockAttrValue(Value: String): boolean;
 function AddPrim(Prim: Integer): boolean;
 procedure WriteIn(S: String);

 function OpenGMF(FileName: String; CallbackRec_: PCallbackRec): Integer;

//implementation uses WptForm2, Collect, newSelector, EcLot, EcDot, WpTwigs,
//                    newBlock, Lib, Lines2, Lines3, ecDot2,
//                    ogcWriter, newFontScale, DWGText, TextManager, LazUTF8;

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

{ TCallBackRec }

procedure Clear;
begin
 FillChar(CallBackRec^, SizeOf(TCallBackRec), 0);
end;

function CreatePointHandle(X, Y, Z: Double): boolean;
begin
 Result := False;
 With CallbackRec^ do
  If Assigned(OnCreatePoint) then Result := OnCreatePoint(X, Y, Z);
end;

function SetPointParams(Color: Integer; Angle, Scale: Double;
 addParams: String): boolean;
begin
 Result := False;
 With CallBackRec^ do begin
  If (hPoint = 0) or (not Assigned(OnSetPointParams)) then exit;
  Result := OnSetPointParams(Color, Angle, Scale, addParams);
 end;
end;

function FindBlockHandle(blockName: String): boolean;
begin
 Result := False;
 With CallBackRec^ do
  If Assigned(OnFindBlock) then Result := OnFindBlock(blockName);
end;

function CreateBlockHandle(blockName: String; X, Y, Z: Double): boolean;
begin
 Result := False;
 With CallBackRec^ do
  If Assigned(OnCreateBlock) then Result := OnCreateBlock(blockName, X, Y, Z);
end;

function FindBlockAttrib(attrName: String): boolean;
begin
 Result := False;
 With CallBackRec^ do
  If Assigned(OnFindAttrib) then Result := OnFindAttrib(attrName);
end;

function CreateBlockAttrib(X, Y, Z, Height, Angle: Double; Value: String): boolean;
begin
 Result := False;
 With CallBackRec^ do
  If Assigned(OnCreateAttrib) then
   Result := OnCreateAttrib(X, Y, Z, Height, Angle, Value);
end;

function CreateBlockAttrValue(Value: String): boolean;
begin
 Result := False;
 With CallBackRec^ do
  If Assigned(OnCreateAttrValue) then
   Result := OnCreateAttrValue(Value);
end;

function AddPrim(Prim: Integer): boolean;
begin
 Result := False;
 If Prim = 0 then exit;
 With CallBackRec^ do
  If Assigned(OnAddPrim) then Result := OnAddPrim(Prim);
end;

procedure WriteIn(S: String);
begin
 With CallBackRec^ do
  if Assigned(OnWriteString) then OnWriteString(S);
end;

function OpenGMF(FileName: String; CallbackRec_: PCallbackRec): Integer;
var TwgForm: TForm2; Stream: TBufStream;
    oldSelector: TSelector;
    Lot: TLot;
    I, J, K: Integer;
    B: Byte;
    PD: TPointDot;
    Sign: TPoint_Sign;
    DT: TDotText;
    propStr: String;
Procedure CreatePointBlock(P: TGeoBlock);
var Geometry: TGeometryEvents;
procedure CreateAttribs;
var I: Integer;
begin
// атрибуты P.txtProperties -> TTextParams
 If P.txtProperties <> nil then
  For I := 0 to P.txtProperties.Count -1 do
  // поиск атрибута в блоке, если найден -> устанавливаем параметры
   If FindBlockAttrib(P.txtProperties[I].PropName)
    then
     CreateBlockAttrValue(P.txtProperties[I].PropValue.Value);
end;
begin
// поиск блока в библиотеке
 If FindBlockHandle(P.Name) then CreateAttribs else
// создаем блок
// CallbackRec.WriteStr(Fmt(['BlockName = ',P.Name,P.X, P.Y]));
 If CreateBlockHandle(P.Name, P.X, P.Y, 0) then begin
  Geometry := TGeometryEvents.Create(CallbackRec.OnPolyEvent, CallbackRec.OnTextEvent);
   P.DrawTo(Geometry);
  Geometry.Free;
  CreateAttribs;
// CallbackRec.WriteStr(Fmt(['BlockRect=',Result.ogsRect]));
 end;
end;
Procedure CreatePointSign(P: TPoint_Sign; inLineType: Boolean);
var Geometry: TGeometryEvents;
procedure CreateAttribs;
var I: Integer;
    dwgText: TDWG_Text;
begin
// атрибуты PD.TTextManaeger -> TTextParam
 If (not inLineType) and (PD.TextManager <> nil) then
  For I := 0 to PD.TextManager.FValues.Count - 1 do
   With TTextParams(PD.TextManager.FValues[I]) do begin
    dwgText := PD.TextManager.FTexts[I];
   // поиск аттрибута в TGM9FBlock
    If FindBlockAttrib(dwgText.fName) then begin
    // создаем KeepObject -> добавляяем его в Point.Attributes
     If ShiftX <> 0 then
      CreateBlockAttrib(ShiftX, ShiftY, 0, fH, fUgol, fValue) else
      CreateBlockAttrib(fDx, fDy, 0, fH, fUgol, fValue);
    end;
   end;
end;
begin
 // поиск блока в библиотеке
 If FindBlockHandle(P.MyNameIs) then CreateAttribs else
// создаем блок
// WriteIn(['SignNAme=',P.MyNameIs, P.MyInd, P.X, P.Y]);
 If CreateBlockHandle(P.MyNameIs, P.X, P.Y, 0) then begin
  Geometry := TGeometryEvents.Create(CallbackRec.OnPolyEvent, CallbackRec.OnTextEvent);
   P.DrawTo(Geometry);
  Geometry.Free;
  CreateAttribs;
 end;
end;
begin
 CallbackRec := CallBackRec_;
 WriteIn('Prepare load...');
 Stream := TBufStream.InitFileStream(FileName, fmOpenRead);
 oldSelector:=TSelector.Create;
 oldSelector.GNForm := Application.MainForm;
 oldSelector.GCanvas := Application.MainForm.Canvas;
 Stream.Selector:=oldSelector;
 WriteIn(Fmt(['Loading > ',TimeToStr(Now)]));
 TwgForm:=TForm2(Stream.Get);
 Stream.Free;
 WriteIn(Fmt(['Loaded > ',TimeToStr(Now)]));
// создаем объекты для отображения
 WriteIn(Fmt(['LotsCount =',TwgForm.Twigs.LotsLarge.Count,
                          TwgForm.Twigs.TwigsLarge.Count, TwgForm.Twigs.AnyLarge.Count]));
// связывание
 TwgForm.ClassbuildII;
 WriteIn('Built');
// грузим площадные/линейные с ogsProperties
//
// загружаем точечные, передаем знак из библиотеки
// CallbackRecWriteIn(['Selector0=',Selector.ogsRect]);
 For I := 0 to TwgForm.Twigs.AnyCount -1 do begin
  PD:= TwgForm.Twigs.AAt(I, B);
//  CallbackRecWriteIn(['Point =',I]);
  If PD is TDotText then begin
     DT := PD as TDotText;
   (*txtString := TogsTextString.Create(Selector, FC, DT.XDot, DT.YDot, 0, DT.Text.Height,
                                      DT.Ugol, DT.XKoef, AlignText(DT.Text.Align), DT.Text.Text, DT.Text.AttrName, False);
   txtString.CreateSysProperties(Fmt(['{"System": {"Color" :', DT.Text.Color,', "Text" :',DT.Text.Text,', "FontName" :',DT.Text.fontView.FontName,'}}']));
   txtString.Calculate([calcbBox]);
   Selector.AddPrim(txtString);
   Prims.Add(txtString);*)
   continue;
  end;
//  Point := TgmfPoint.Create(PD.XDot, PD.YDot, PD.Z, Selector);
  If CreatePointHandle(PD.XDot, PD.YDot, PD.Z) then begin
 //
   If PD.userObj <> nil then begin
  // формируем json - строку для отображения системных свойств
    propStr := Fmt(['{"System": {"Color" :', PD.PointColor,',"Block" :',
                                      TGeoBlock(PD.userobj).Name,'}}']);
  // устанавливаем свойства точки
    If CallbackRec.OnSetPointParams(PD.PointColor, PD.Ugol, PD.XKoef, propStr) then
     begin
  // экспортируем блое по примитивам
      CreatePointBlock(PD.userObj as TGeoBlock);
      AddPrim(CallBackRec.hPoint);
     end;
   end else begin
  // без блока, предполагаем, что есть условный знак
    propStr := Fmt(['{"System": {"Color" :', PD.PointColor,', "Sign" :',PD.GetZnak,'}}']);
    Sign := SearchPointSign(oldSelector.GPointCol, PD.GetZnak);
    // устанавливаем свойства точки
    If CallbackRec.OnSetPointParams(PD.PointColor, PD.Ugol, PD.Koef, propStr) then
     If Sign <> nil then begin
     // экспортируем знак по примитивам
      CreatePointSign(Sign, False);
      AddPrim(CallBackRec.hPoint);
     end;
   end;
  //
  end;
 // разбираем условный знак на примитивы
// CallbackRecWriteIn(['PointEnd =',I]);
 end;
 CallbackRec.OnUpdateObject(True);
 WriteIn(Fmt(['Translated > ', TimeToStr(Now)]));
 TwgForm.Free;
end;

end.

