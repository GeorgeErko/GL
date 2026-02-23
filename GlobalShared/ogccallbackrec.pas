unit ogccallbackrec;

{$mode Delphi}

interface

uses Classes, SysUtils, ogccallbacktypes;

type
  hObj = Longint; //дескериптор объекта

// массив геоточек
 PGeoPointArray = ^TGeoPointArray;
 TGeoPointArray = array of PGeoPoint;

type
 // служебные
  TEnableDisableFormsEvent = procedure (var FormList: Pointer);
 // создание/сброс/удаленее графического объекта
  TCreateGraphicsEvent = function (): hObj; stdcall;
  TResetObjectEvent = function (Obj: hObj): hObj; stdcall;
  TDestroyObjectEvent = function (Obj: hObj): hObj; stdcall;
 // создает точку и возвращает дескриптор блока
  TCreatePointEvent = function (Obj: hObj; X, Y, Z: Double): hObj; stdcall;
  TSetPointParamsEvent = function (Obj: hObj; Color: Integer; Angle, Scale: Double;
                                    blockHandle: hObj;
                                    addParams: PChar): boolean; stdcall;
 // создает блок и возвращяет дескритор блока
  TFindBlockEvent = function (Obj: hObj; blockName: PChar): hObj; stdcall;
  TCreateBlockEvent = function (Obj: hObj; blockName: PChar;
                                 X, Y, Z: Double): hObj; stdcall;
 // возвращает адрес ф-ции для создания примитивов в блоке
  TPolyEvent = procedure (Obj: hObj; Poly: PGeoPoint; penColor,
                           brushColor: Integer; lineWidth: Double; useColor: boolean;
                            isPolygon: boolean); stdcall;
  TTextEvent = procedure (Obj: hObj; X, Y: Double; FontName: PChar; txtHeight, txtAngle,
                           txtScale: Double; txtColor: Integer; Align: byte;
                            Bl, It, Un: boolean; Text, AttrName: PChar); stdcall;
 // ищет атрибут в блоке Block с именем attrName
  TFindAttribEvent = function (Obj: hObj; attrName: PChar): hObj; stdcall;
 // создание атрибута
  TCreateAttribEvent = function (Obj, blockText: hObj; X, Y, Z, Height, Angle:
                                  Double; Value: PChar; Color: Integer): hObj; stdcall;
  TCreateAttrValueEvent = function (Obj, blockText: hObj; Value : PChar): hObj; stdcall;
 // после создания примитива можно добавить его в текущую GeometryCollection
  TAddPrimitiveEvent = function (Obj, Prim: hObj): boolean; stdcall;
  TUpdateObjectEvent = procedure (Obj: hObj; FitView: boolean = False); stdcall;
 // передает строку во внешний модуль для вывода
  TWriteStringEvent = procedure (S: PChar); stdcall;
 // примитивы для создания hPrim и добавления в hObject
  TCreatePolyLineEvent = function (Obj: hObj; Points: PGeoPoint; penColor : Integer;
                                    lWidth: Double; lType: Integer; lScale: Double;
                                     useColor: boolean; addParams: PChar): hObj; stdcall;
  TCreateMPolyLineEvent = function (Obj: hObj; penColor : Integer; lWidth: Double;
                                     lType: Integer; lScale: Double;
                                      useColor: boolean; addParams: PChar): hObj; stdcall;
  TCreateMultilineEvent = function (Obj: hObj; Points: PGeoEdge; penColor : Integer;
                                     lWidth: Double; lType: Integer; lScale: Double;
                                      useColor: boolean; addParams: PChar): hObj; stdcall;
  TAddPolyPointsEvent = function (Obj: hObj; Points: PGeoPoint): hObj; stdcall;
  TCreatePolygonEvent = function (Obj: hObj; brushColor : Integer; useColor: boolean; addParams: PChar): hObj; stdcall;
  TCreateMPolygonEvent = function (Obj: hObj; brushColor : Integer; useColor: boolean;
                                    addParams: PChar): hObj; stdcall;
 // типы линий
  TFindLineTypeEvent = function (Obj: hObj; LineTypeName: PChar): hObj; stdcall;
  TCreateLineTypeEvent = function (Obj: hObj; LineTypeName: PChar): hObj; stdcall;
  TAddPartOfLineTypeEvent = function (Obj: hObj; addPart: TPartOfLineType): hObj; stdcall;
 //
  TCreateTextEvent = function (Obj: hObj; X, Y, Z: Double; FontName: PChar; txtHeight, txtAngle,
                                txtScale: Double; txtColor: Integer; Align: byte;
                                 Bl, It, Un: boolean; Text, AttrName, addParams: PChar): hObj; stdcall;


{ TCallBackRec }

 PCallBackRec = ^TCallBackRec;
 TCallbackRec = record
  hObject         : Longint;  // TogsGeometryCollection
                              // корневой объект TogcBasicObject
 //
  EnableForms     : TEnableDisableFormsEvent;
  DisableForms    : TEnableDisableFormsEvent;
 //
  CreateGraphics  : TCreateGraphicsEvent;
  DestroyObject   : TDestroyObjectEvent;
  ResetObject     : TResetObjectEvent;
 //
  CreatePoint     : TCreatePointEvent;
  SetPointParams  : TSetPointParamsEvent;
  FindBlock       : TFindBlockEvent;
  CreateBlock     : TCreateBlockEvent;
  PolyEvent       : TPolyEvent;
  TextEvent       : TTextEvent;
  FindAttrib      : TFindAttribEvent;
  CreateAttrib    : TCreateAttribEvent;
  CreateAttrValue : TCreateAttrValueEvent;
 //
  UpdateObject    : TUpdateObjectEvent;
 //
  AddPrimitive    : TAddPrimitiveEvent;
 //
  WriteString     : TWriteStringEvent;
 // создание примитивов hPrim для hObject
  CreatePolyLine  : TCreatePolyLineEvent;
  CreateMPolyLine : TCreateMPolyLineEvent;
  AddPolyPoints   : TAddPolyPointsEvent;
  CreateMultiLine : TCreateMultiLineEvent;
  CreatePolygon   : TCreatePolygonEvent;
  CreateMPolygon  : TCreateMPolygonEvent;
 // типы линий
  FindLineType    : TFindLineTypeEvent;
  CreateLineType  : TCreateLineTypeEvent;
  AddPartOfLineType : TAddPartOfLineTypeEvent;
 //
  CreateText      : TCreateTextEvent;
 end;

implementation

end.

