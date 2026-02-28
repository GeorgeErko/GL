unit ogcIEProcs;

{$mode Delphi}

interface

uses Classes, SysUtils, Forms, ogcCallbackRec, ogcCallbackTypes;


{=============================================================================
  Процедуры передаваемые в качестве процедур обратного вызова в TCallbackrec
==============================================================================}

 procedure ieDisableForms(var FormList: Pointer);
 procedure ieEnableForms(var FormList: Pointer);

 // сброс/уничтожение
 function  ieResetObject(Obj: hObj): hObj; stdcall;// обнуление обекта
 function  ieDestroyObject(Obj: hObj): hObj; stdcall;// уничтожение объекта, если он не был использован
 // добавление примитива в Obj = TogsMapObjectect
 function  ieAddPrimitive(Obj, Prim: hObj): boolean; stdcall;
 // ф-ции импорта-экспорта
 function  ieCreatePoint(Obj: hObj; X, Y, Z: Double): hObj; stdcall;
 function  ieSetPointParams(Obj: hObj; Color: Integer; Angle, Scale: Double;
                             block: hObj; addParams: PChar): boolean; stdcall;
 function  ieFindBlock(Obj: hObj; blockName: PChar): hObj; stdcall;
 function  ieCreateBlock(Obj: hObj; blockName: PChar; X, Y, Z: Double): hObj; stdcall;
 procedure iePolyEvent(Obj: hObj; Poly: PGeoPoint; penColor, brushColor: Integer;
                      lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
 procedure ieTextEvent(Obj: hObj; X, Y: Double; FontName: PChar; txtHeight,
                      txtAngle, txtScale: Double; txtColor: Integer; Align: byte; Bl, It,
                       Un: Boolean; Text, AttrName: PChar); stdcall;
 function  ieFindAttrib(Obj: hObj; attrName: PChar): hObj; stdcall;
 function  ieCreateAttrib(Obj, blockText:hObj; X_, Y_, Z_, Height_, Angle_: Double; Value_: PChar; Color: Integer): hObj; stdcall;
 function ieCreateAttrValue(Obj, blockText: hObj; Value_: PChar): hObj; stdcall;
//
 procedure ieUpdateObject(Obj: hObj; FitView: boolean = False); stdcall;
//
 procedure ieWriteString(S: PChar); stdcall;
//
 function ieCreatePolyLine(Obj: hObj; Points: PGeoPoint; penColor : Integer;
                            lWidth: Double; lType: Integer; lScale: Double; useColor: boolean;
                             addParams: PChar): hObj; stdcall;
 function ieCreateMultiLine(Obj: hObj; Points: PGeoEdge; penColor : Integer;
                            lWidth: Double; lType: Integer; lScale: Double; useColor: boolean;
                             addParams: PChar): hObj; stdcall;
 function ieCreateMPolyLine (Obj: hObj; penColor : Integer; lWidth: Double;
                              lType: Integer; lScale: Double;
                               useColor: boolean; addParams: PChar): hObj; stdcall;
 function ieAddPolyPoints(Obj: hObj; Points: PGeoPoint): Integer; stdcall;
 function ieCreatePolygon(Obj: hObj; brushColor : Integer; useColor: boolean; addParams: PChar): hObj; stdcall;
 function ieCreateMPolygon(Obj: hObj; brushColor : Integer; useColor: boolean; addParams: PChar): hObj; stdcall;
//
 function ieFindLineType(Obj: hObj; LineTypeName: PChar): hObj; stdcall;
 function ieCreateLineType(Obj: hObj; LineTypeName: PChar): hObj; stdcall;
 function ieAddPartOfLineType(Obj: hObj; addPLT: TPartOfLinetype): hObj; stdcall;
//
 function ieCreateText(Obj: hObj; X, Y, Z: Double; FontName: PChar; txtHeight,
                              txtAngle, txtScale: Double; txtColor: Integer; Align: byte; Bl, It,
                               Un: Boolean; Text, AttrName, addParams: PChar): hObj; stdcall;

implementation uses ogcBasic, ogcIEObjects, ogcMapObject, gmfGeometry, ogcGeometry,
                    ttfGeometry, ogcWriter, ogcProcs, ogcLType, ogcGeometry2,
                    LCLIntf;

// для создания форм в dll

procedure ieDisableForms(var FormList: Pointer);
begin
 FormList := Screen.DisableForms(nil, TList(FormList));
end;

procedure ieEnableForms(var FormList: Pointer);
begin
 Screen.EnableForms(TList(FormList));
end;

// проверка совместимости вызова ф-ции объекта

function Check(Obj: hObj; objType: TogsBasicClass; ProcType: Boolean; ProcName:String; Mode: byte): boolean;
var S: String;
begin
// WriteIn(['Check=', Obj, TIEObject(Obj).ogsObject.ClassName, objType.ClassName]);
 S:= '';
 If Obj = 0 then S := Fmt(['Invalid object:',Obj]) else
 If not (TIEObject(Obj).ogsObject is objType) then
  S := 'Invalid object type: ' + TIEObject(Obj).ogsObject.ClassName +
        ' -> method: ' + ProcName;
// WriteIn(['ProcType=', ProcType, 'ProcNzame=', ProcName]);
 If (ProcType = False) and (ProcName <> '') then
    S := S + #13#10 + 'Invalid method handle: ' + ProcName +
                       ' -> object type: ' + TIEObject(Obj).ogsObject.ClassName;
 Result := S = '';
 If not Result then
  raise Exception.Create(S);
end;

// уничтожение объкта дескриптора TIEObject

function ieResetObject(Obj: hObj): hObj;
begin
 If Obj = 0 then exit;
 If TObject(Obj) is TIEObject then begin
 //  WriteIn(['ResetObj',TIEObject(Obj).ogsObject.ClassName]);
  TIEObject(Obj).Free;
  Result := 0;
 end else begin
  Result := Obj;
  raise Exception.Create('Попытка сброса/уничтожения объекта не унаследованного от TIEObject:'
                         + 'ieDestroyOjbect ->' + IntToStr(Obj));
 end;
end;

// уничтожение объкта дескриптора TIEObject вместе с объектом TogsBasic

function ieDestroyObject(Obj: hObj): hObj;
begin
 If TObject(Obj) is TIEObject then begin
  TIEObject(Obj).ogsObject.Free;
  TIEObject(Obj).Free;
  Result := Obj;
 end else begin
  Result := 0;
  raise Exception.Create('Попытка сброса/уничтожения объекта не унаследованного от TIEObject: ieDestroyOjbect');
 end;
end;

function ieCreatePoint(Obj: hObj; X, Y, Z: Double): hObj; stdcall;
begin
 Result := 0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.CreatePoint),
               'CreatePoint', $FF) then exit;
//
 Result := hObj(TIEPoint.Create(TIEObject(Obj),
                 TgmfPoint.Create(X, Y, Z, TogsMapObject(TIEObject(Obj).ogsObject).ogsSelector)));
end;

function ieSetPointParams(Obj: hObj; Color: Integer; Angle, Scale: Double;
                           block: hObj; addParams: PChar): boolean; stdcall;
var P: TgmfPoint;
begin
 Result := False;
 If not Check(Obj, TogsPoint, Assigned(TIEObject(Obj).cbRec.SetPointParams),
              'SetPointParams', $FF) then exit;
 P := TgmfPoint(TIEPoint(Obj).ogsObject);
 P.Color := Color;
 P.Angle := Angle;
 P.Scale := Scale;
 If block <> 0 then
  P.Sign  := TIEBlock(block).ogsObject else
   P.Sign := nil;
 P.CreateSysProperties(addParams);
 Result:= True;
end;

// добавление полилинии/полигона в блок

procedure iePolyEvent(Obj: hObj; Poly: PGeoPoint; penColor, brushColor: Integer;
                     lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
begin
 If not Check(Obj, TgmfBlock, Assigned(TIEObject(Obj).cbRec.PolyEvent),
               'PolyEvent', $FF) then exit;
//
 TgmfBlock(TIEBlock(Obj).ogsObject).PolyEvent(Poly, penColor, brushColor, lineWidth,
                                               useColor, isPolygon);
end;

// добавление текстовых значений и атрибутов (значений с текстовым ключом) в блок

procedure ieTextEvent(Obj: hObj; X, Y: Double; FontName: PChar; txtHeight,
                     txtAngle, txtScale: Double; txtColor: Integer; Align: byte; Bl, It,
                      Un: Boolean; Text, AttrName: PChar); stdcall;
begin
 If not Check(Obj, TgmfBlock, Assigned(TIEObject(Obj).cbRec.TextEvent),
               'TextEvent', $FF) then exit;
//
 TgmfBlock(TIEObject(Obj).ogsObject).TextEvent(X, Y, FontName, txtHeight, txtAngle,
                                                txtScale, txtColor,
                                                 Align, Bl, It, Un, Text, AttrName);
end;

function ieFindBlock(Obj: hObj; blockName: PChar): hObj; stdcall;
var P: TgmfBlock;
begin
 Result := 0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.FindBlock),
               'FindBlock', $FF) then exit;
 P := TogsMapObject(TIEObject(Obj).ogsObject).SearchPLib(blockName);
 If P = nil then exit;
 Result := hObj(TIEBlock.Create(TIEObject(Obj), P));
end;

function ieCreateBlock(Obj: hObj; blockName: PChar; X, Y, Z: Double): hObj; stdcall;
var P: TgmfBlock;
begin
// WriteIn(['AddBlock']);
 Result :=  0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.CreateBlock),
               'CreateBlock', $FF) then exit;
 P := TgmfBlock.Create(TIEObject(Obj).ogsObject.ogsSelector, blockName, -1, X, Y, Z);
 TogsMapObject(TIEObject(Obj).ogsObject).AddBlock(P);
 Result := hObj(TIEBlock.Create(TIEObject(Obj), P));
end;

function ieFindAttrib(Obj: hObj; attrName: PChar): hObj; stdcall;
var Text: Pointer;
begin
 Result := 0;
 If not Check(Obj, TgmfBlock, Assigned(TIEObject(Obj).cbRec.FindAttrib),
               'FindAttrib', $FF) then exit;
//
 If TogsBlock(TIEBlock(Obj).ogsObject).FindAttribute(attrName, Text) then
  Result := hObj(TIEAttrib.Create(TIEObject(Obj), Text));
end;

function ieCreateAttrib(Obj, blockText: hObj; X_, Y_, Z_, Height_,
 Angle_: Double; Value_: PChar; Color: Integer): hObj; stdcall;
var Point: TgmfPoint;
    Text : TogsTextParams;
    TextParams: TogsTextParams;
begin
 Result := 0;
 If not Check(Obj, TgmfPoint, Assigned(TIEObject(Obj).cbRec.CreateAttrib),
               'CreateAttrib', $FF) then exit;
//
 Point := TgmfPoint(TIEObject(Obj).ogsObject);
 Text := TogsTextParams(TIEObject(blockText).ogsObject);
 With Text do
  TextParams := TogsTextParams.Create(Text, ogsSelector, fFontCollect, X_, Y_, Z_,
                    Height_, Angle_, fScale, fAlign, Value_, fAttrName, Color, True);
 Point.AddAttribute(TextParams);
  Result := hObj(TIEAttrib.Create(TIEPoint(Obj), TextParams));
end;

function ieCreateAttrValue(Obj, blockText: hObj; Value_: PChar): hObj; stdcall;
var Point: TgmfPoint;
    Text : TogsTextString;
    TextParams: TogsTExtParams;
begin
 Result := 0;
 If not Check(Obj, TgmfPoint, Assigned(TIEObject(Obj).cbRec.CreateAttrValue),
               'SetAttrValue', $FF) then exit;
 //
 Point := TgmfPoint(TIEObject(Obj).ogsObject);
 Text := TogsTextParams(TIEObject(blockText).ogsObject);
 With Text do
  TextParams := TogsTextParams.Create(Text, ogsSelector, fFontCollect, X, Y, Z,
                    fHeight, fAngle, fScale, fAlign, Value_, fAttrName, Color, True);
 Point.AddAttribute(TextParams);
 Result := hObj(TIEAttrib.Create(TIEPoint(Obj), TextParams));
end;

function ieAddPrimitive(Obj, Prim: hObj): boolean; stdcall;
begin
 Result := False;
 If Obj = Prim then exit;
// WriteIn(['AddPrim1=', TIEObject(Obj).ClassName,  TIEObject(Obj).ogsObject.ClassName, TIEObject(Prim).ogsObject.ClassName, Assigned(TIEObject(Obj).cbRec.AddPrimitive)]);
 If not Check(Obj, TgmfBlock, Assigned(TIEObject(Obj).cbRec.AddPrimitive),
              'AddPrimitive', $FF) then exit;
// WriteIn(['==============',TIEObject(Prim).ogsObject.Classname]);
 Result := TogsMapObject(TIEObject(Obj).ogsObject).AddPrim(Pointer(TIEObject(Prim).ogsObject)) > 0;
// WriteIn(['AddPrim2=',TIEobject(Obj).ClassName]);
end;

procedure ieUpdateObject(Obj: hObj; FitView: boolean); stdcall;
begin
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.UpdateObject),
           'UpdateObject', $FF) then exit;
 TogsMapObject(TIEObject(Obj).ogsObject).UpdateObject(FitView);
// удаляем корневой объект и собираем мусор
// TIEObject(Obj).Free;
end;

procedure ieWriteString(S: PChar); stdcall;
begin
 WriteIn([S]);
end;

// примитивы для создания hPrim и добавления в hObject

function ieCreatePolyLine(Obj: hObj; Points: PGeoPoint; penColor : Integer;
                           lWidth: Double; lType: Integer;  lScale: Double;
                            useColor: boolean; addParams: PChar): hObj; stdcall;
var Line: TgmfLineString;
begin
 Result:= 0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.CreatePolyLine),
           'CreatePolyLine', $FF) then exit;
// создаем полилинию
 Line := TgmfLineString.Create(TIEObject(Obj).ogsObject.ogsSelector);
 Line.CreateSysProperties(addParams);
 Line.Color := penColor;
//  WriteIn(['Polyline.Color=', GetRValue(penColor), GetGValue(penColor), GetBValue(penColor)]);
// !!! тип лини (без проверки)
// WriteIn(['Ltype=', lType]);
 If lType <> 0 then begin
  Line.Sign := Pointer(TIEObject(lType).ogsObject);
  Line.Scale := lScale;
//  WriteIn(['Sign=', TgmfLineType(Line.Sign).Name]);
 // WriteIn(['lscale=', lscale]);
 end;
 Result := hObj(TIELinearObject.Create(TIEObject(Obj), Line));
 TIELinearObject(Result).AddPoints(Points);
end;

function ieCreateMPolyLine (Obj: hObj; penColor : Integer; lWidth: Double;
                             lType: Integer;  lScale: Double; useColor: boolean;
                              addParams: PChar): hObj; stdcall;
var mLine: TgmfMultiLineString;
begin
 Result := 0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.CreateMPolyLine),
           'CreatePolyLine', $FF) then exit;
// создаем полилинию
 mLine := TgmfMultiLineString.Create(TIEObject(Obj).ogsObject.ogsSelector);
 mLine.CreateSysProperties(addParams);
 mLine.Color := penColor;
 // !!! тип лини (без проверки)
 If lType <> 0 then begin
  mLine.Sign := Pointer(TIEObject(lType).ogsObject);
  mLine.Scale := lScale;
 end;
//
 Result := hObj(TIEMultiLinearObject.Create(TIEObject(Obj), mLine));
end;

function ieAddPolyPoints(Obj: hObj; Points: PGeoPoint): Integer; stdcall;
begin
// WriteIn(['ieAdd=', TObject(Obj).ClassName]);
 Result := TIELinearObject(Obj).AddPoints(Points);
end;

function ieCreateMultiLine(Obj: hObj; Points: PGeoEdge; penColor : Integer;
                            lWidth: Double; lType: Integer;  lScale: Double;
                             useColor: boolean; addParams: PChar): hObj; stdcall;
var Line: TgmfMultiLine;
begin
 Result := 0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.CreatePolyLine),
           'CreateMultiLine', $FF) then exit;
// создаем полилинию
 Line := TgmfMultiLine.Create(TIEObject(Obj).ogsObject.ogsSelector);
 Line.CreateSysProperties(addParams);
 Line.Color := penColor;
 // !!! тип лини (без проверки)
// WriteIn(['Ltype=', lType]);
 If lType <> 0 then begin
  Line.Sign := Pointer(TIEObject(lType).ogsObject);
  Line.Scale := lScale;
//  WriteIn(['Sign=', TgmfLineType(Line.Sign).Name]);
 // WriteIn(['lscale=', lscale]);
 end;
 Result := hObj(TIELinearObject.Create(TIEObject(Obj), Line));
 TIELinearObject(Result).AddEdges(Points);
end;


function ieCreatePolygon(Obj: hObj; brushColor : Integer; useColor: boolean;
                          addParams: PChar): hObj; stdcall;
var Poly: TgmfPolygon;
begin
 Result:= 0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.CreatePolygon),
              'CreatePolygon', $FF) then exit;
// создаем полилинию
 Poly := TgmfPolygon.Create(TIEObject(Obj).ogsObject.ogsSelector);
 Poly.CreateSysProperties(addParams);
 Poly.Color := brushColor;
// !!! тип лини (без проверки)
// Poly.Sign := Pointer(LineType);
 Result := hObj(TIEPolygon.Create(TIEObject(Obj), Poly));
end;

function ieCreateMPolygon(Obj: hObj; brushColor : Integer; useColor: boolean;
                          addParams: PChar): hObj; stdcall;
begin

end;

function ieFindLineType(Obj: hObj; LineTypeName: PChar): hObj; stdcall;
var LT: TgmfLineType;
begin
 Result:= 0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.FindLineType),
              'FindLineType', $FF) then exit;
 LT := TogsMapObject(TIEObject(Obj).ogsObject).SearchLLib(LineTypeName);
 If LT <> nil then
  Result := hObj(TIELineType.Create(TIEObject(Obj), LT));
end;

function ieCreateLineType(Obj: hObj; LineTypeName: PChar): hObj; stdcall;
var LT: TgmfLineType;
begin
 Result:= 0;
 If not Check(Obj, TogsMapObject, Assigned(TIEObject(Obj).cbRec.CreateLineType),
              'FindLineType', $FF) then exit;
 WriteIn(['LType=', LineTypeName]);
 LT := TgmfLineType.Create(TIEObject(Obj).ogsObject.ogsSelector, LineTypeName, nil);
 TogsMapObject(TIEObject(Obj).ogsObject).AddLineType(LT);
 Result := hObj(TIELineType.Create(TIEObject(Obj), LT));
end;

function ieAddPartOfLineType(Obj: hObj; addPLT: TPartOfLinetype): hObj; stdcall;
begin
 Result:= 0;
 If not Check(Obj, TgmfLineType, Assigned(TIEObject(Obj).cbRec.AddPartOfLineType),
              'AddPartOfLineType', $FF) then exit;
//addPLT.Write;
 TgmfLineType(TIEObject(Obj).ogsObject).AddPartOfLineType(addPLT);
end;

//

function ieCreateText(Obj: hObj; X, Y, Z: Double; FontName: PChar; txtHeight,
                       txtAngle, txtScale: Double; txtColor: Integer; Align: byte; Bl, It,
                        Un: Boolean; Text, AttrName, addParams: PChar): hObj; stdcall;
var FC: TFontCollect;
    txtString: TogsTextString;
    Index: Integer;
begin
 Result := 0;
 Index := ogsFontManager.FindBy(FontName, ItalicBold(Bl, It), FC);
 If (FC = nil) then begin
  WriteIn(['Не найден шрифт: ' + FontName]);
  exit;
 end;
// загружаем шрифт из файла
 FC.LoadModeComplete;
// WriteIn(['inBlock=',not (TObject(TIEObject(Obj).ogsObject) is TogsMapObject), TIEObject(Obj).ogsObject.ClassName]);
 txtString := TogsTextString.Create(TIEObject(Obj).ogsObject.ogsSelector, FC, X, Y, 0, txtHeight,
                                     txtAngle, txtScale, AlignText(Align), Text, AttrName,
                                      txtColor, not (TObject(TIEObject(Obj).ogsObject) is TogsMapObject));
 txtString.CreateSysProperties(addParams);
 Result := hObj(TIEText.Create(TIEObject(Obj), txtString));
end;


end.

