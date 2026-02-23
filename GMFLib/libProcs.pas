unit libProcs;

{$mode Delphi}

interface

uses Classes, SysUtils, Forms,
      ogcCallbackRec, ogcCallbackTypes;

type
 TApplicationCallback = class(TComponent)
 private
  DisableFormsCallBack: TEnableDisableFormsEvent;
  EnableFormsCallback: TEnableDisableFormsEvent;
  FormList: Pointer;
 public
  constructor Create(aOwner: TComponent); override;
  destructor Destroy; override;
  procedure DisableForms(Sender: TObject);
  procedure EnableForms(Sender: TObject);
 end;

var
  CallbackRec: PCallbackRec;
  AppCallBack: TApplicationCallback;

// служебные
procedure ClearRec;
procedure InitAppCallback;
procedure DoneAppCallback;

// создание точек, блоков и атрибутов
function CreatePoint(Obj: hObj; X, Y, Z: Double): hObj;
function SetPointParams(Obj: hObj; Color: Integer; Angle, Scale: Double;
                         Block: hObj; addParams: String): boolean;
function FindBlock(Obj: hObj; blockName: String): hObj;
function CreateBlock(Obj: hObj; blockName: String; X, Y, Z: Double): hObj;
function FindBlockAttrib(Obj: hObj; attrName: String): hObj;
function CreatePointAttrib(Obj, blockText: hObj; X, Y, Z, Height, Angle: Double; Value: String; Color: Integer): hObj;
function CreatePointAttrValue(Obj, blockText: hObj; Value: String): hObj;
function AddPrimitive(Obj: hObj; Prim: Integer): boolean;
function ResetObject(var Obj: hObj): hObj;
function DestroyObject(Obj: hObj): hObj;
procedure WriteStr(Params: Array of Const);

// примитивы для создания hPrim и добавления в hObject, hBlock
function CreatePolyLine(Obj: hObj; Points: PGeoPoint; penColor : Integer; lWidth: Double;
                              lType: Integer; lScale: Double; useColor: boolean;
                               addParams: PChar): hObj; stdcall;
function CreateMPolyLine(Obj: hObj; penColor : Integer; lWidth: Double; lType: Integer;
                         lScale: Double; useColor: boolean; addParams: PChar): hObj ; stdcall;
function AddPolyPoints(Obj: hObj; Points: PGeoPoint): Integer;
function CreatePolygon(Obj: hObj; brushColor : Integer; useColor: boolean; addParams: PChar): hObj; stdcall;
function CreateMPolygon(Obj: hObj; brushColor : Integer; useColor: boolean;addParams: PChar): hObj; stdcall;
function CreateMultiLine(Obj: hObj; Points: PGeoEdge; penColor : Integer;
                          lWidth: Double; lType: Integer; lScale: Double; useColor: boolean;
                           addParams: PChar): hObj; stdcall;

// типы линий
function FindLineType(Obj: hObj; LineTypeName: PChar): hObj; stdcall;
function CreateLineType(Obj: hObj; LineTypeName: PChar): hObj; stdcall;
function AddPartOfLineType(Obj: hObj; addPart: TPartOfLinetype): hObj; stdcall;

// текст
function CreateText(Obj: hObj; X, Y, Z: Double; FontName: PChar; txtHeight, txtAngle,
                     txtScale: Double; txtColor: Integer; Align: byte;
                      Bl, It, Un: boolean; Text, AttrName, addParams: PChar): hObj; stdcall;

implementation uses ogcWriter;

{ TApplicationCallback }

constructor TApplicationCallback.Create(aOwner: TComponent);
begin
 inherited Create(aOwner);
 Application.AddOnModalEndHandler(EnableForms);
 Application.AddOnModalBeginHandler(DisableForms);
end;

destructor TApplicationCallback.Destroy;
begin
 If Assigned(CallbackRec^.EnableForms) then
  Application.RemoveOnModalEndHandler(EnableForms);
 If Assigned(CallbackRec^.DisableForms) then
  Application.RemoveOnModalBeginHandler(DisableForms);
 inherited Destroy;
end;

procedure TApplicationCallback.DisableForms(Sender: TObject);
begin
 If Assigned(DisableFormsCallBack) then
  DisableFormsCallBack(FormList);
end;

// служебные

procedure TApplicationCallback.EnableForms(Sender: TObject);
begin
 If Assigned(EnableFormsCallBack) then
  EnableFormsCallback(FormList);
end;
procedure ClearRec;
begin
 FillChar(CallBackRec^, SizeOf(TCallBackRec), 0);
end;

procedure InitAppCallback;
begin
 AppCallback := TApplicationCallback.Create(nil);
 If Assigned(CallbackRec^.EnableForms) then
  With CallbackRec^ do begin
   AppCallback.DisableFormsCallBack := DisableForms;
   AppCallback.EnableFormsCallback := EnableForms;
 end;
end;

procedure DoneAppCallback;
begin
 If AppCallback <> nil then AppCallback.Free;
end;

// Ф-ции экспорта *************************************************************

function CreatePoint(Obj: hObj; X, Y, Z: Double): hObj;
begin
 Result := 0;
 With CallbackRec^ do
  If Assigned(CreatePoint) then Result := CreatePoint(Obj, X, Y, Z);
end;

function SetPointParams(Obj: hObj; Color: Integer; Angle, Scale: Double;
                         Block: hObj; addParams: String): boolean;
begin
 Result := False;
 With CallBackRec^ do
  If Assigned(SetPointParams) then
   Result := SetPointParams(Obj, Color, Angle, Scale, Block, PChar(addParams));
end;

function FindBlock(Obj: hObj; blockName: String): hObj;
begin
 Result := 0;
 With CallBackRec^ do
  If Assigned(FindBlock) then Result := FindBlock(Obj, PChar(blockName));
end;

function CreateBlock(Obj: hObj; blockName: String; X, Y, Z: Double): hObj;
begin
 Result := 0;
 With CallBackRec^ do
  If Assigned(CreateBlock) then Result := CreateBlock(Obj, PChar(blockName), X, Y, Z);
end;

function FindBlockAttrib(Obj: hObj; attrName: String): hObj;
begin
 Result := 0;
 With CallBackRec^ do
  If Assigned(FindAttrib) then Result := FindAttrib(Obj, PChar(attrName));
end;

function CreatePointAttrib(Obj, blockText: hObj; X, Y, Z, Height, Angle: Double; Value: String; Color: Integer): hObj;
begin
 Result := 0;
 With CallBackRec^ do
  If Assigned(CreateAttrib) then
   Result := CreateAttrib(Obj, blockText, X, Y, Z, Height, Angle, PChar(Value), Color);
end;

function CreatePointAttrValue(Obj, blockText: hObj; Value: String): hObj;
begin
 Result := 0;
 With CallBackRec^ do
  If Assigned(CreateAttrValue) then
   Result := CreateAttrValue(Obj, blockText, PChar(Value));
end;

function AddPrimitive(Obj: hObj; Prim: Integer): boolean;
begin
 Result := False;
 If Prim = 0 then exit;
 With CallBackRec^ do
  If Assigned(AddPrimitive) then Result := AddPrimitive(Obj, Prim);
end;

function ResetObject(var Obj: hObj): hObj;
begin
 Result := Obj;
 With CallBackRec^ do
  If Assigned(DestroyObject) then Result := ResetObject(Obj);
end;

function DestroyObject(Obj: hObj): hObj;
begin
 Result := Obj;
 With CallBackRec^ do
  If Assigned(DestroyObject) then Result := DestroyObject(Obj);
end;

procedure WriteStr(Params: Array of Const);
begin
 With CallBackRec^ do
  if Assigned(WriteString) then WriteString(PChar(Fmt(Params)));
end;

// примитивы для создания hPrim и добавления в hObject

function CreatePolyLine(Obj: hObj; Points: PGeoPoint; penColor : Integer; lWidth: Double;
                              lType: Integer; lScale: Double; useColor: boolean; addParams: PChar): hObj; stdcall;
begin
 With CallBackRec^ do
  if Assigned(CreatePolyLine) then
   Result := CreatePolyLine(Obj, Points, penColor, lWidth, lType, lScale, useColor, addParams);
end;

function CreateMPolyLine(Obj: hObj; penColor : Integer; lWidth: Double; lType: Integer; lScale: Double;
                              useColor: boolean; addParams: PChar): hObj ; stdcall;
begin
 With CallBackRec^ do
  if Assigned(CreateMPolyLine) then
   Result := CreateMPolyLine(Obj, penColor, lWidth, lType, lScale, useColor, addParams);
end;

function AddPolyPoints(Obj: hObj; Points: PGeoPoint): Integer;
begin
 Result := 0;
 With CallBackRec^ do
  if Assigned(AddPolyPoints) then
   Result := AddPolyPoints(Obj, Points);
end;

function CreatePolygon(Obj: hObj; brushColor : Integer; useColor: boolean; addParams: PChar): hObj; stdcall;
begin
 With CallBackRec^ do begin
  if Assigned(CreatePolygon) then
   Result := CreatePolygon(Obj, brushColor, useColor, addParams);
 end;
end;

function CreateMPolygon(Obj: hObj; brushColor : Integer; useColor: boolean;addParams: PChar): hObj; stdcall;
begin
 With CallBackRec^ do
  if Assigned(CreateMPolygon) then
   Result := CreateMPolygon(Obj, brushColor, useColor, addParams);
end;

function CreateMultiLine(Obj: hObj; Points: PGeoEdge; penColor: Integer;
                          lWidth: Double; lType: Integer; lScale: Double; useColor: boolean;
                           addParams: PChar): hObj; stdcall;
begin
 With CallBackRec^ do
  if Assigned(CreateMultiLine) then
   Result := CreateMultiLine(Obj, Points, penColor, lWidth, lType, lScale, useColor, addParams);
end;

function FindLineType(Obj: hObj; LineTypeName: PChar): hObj; stdcall;
begin
 With CallBackRec^ do
  if Assigned(FindLineType) then
   Result := FindLineType(Obj, LineTypeName);
end;

function CreateLineType(Obj: hObj; LineTypeName: PChar): hObj; stdcall;
begin
 With CallBackRec^ do
  if Assigned(CreateLineType) then
   Result := CreateLineType(Obj, LineTypeName);
end;

function AddPartOfLineType(Obj: hObj; addPart: TPartOfLinetype): hObj; stdcall;
begin
 With CallBackRec^ do
  if Assigned(AddPartOfLineType) then begin
   Result := AddPartOfLineType(Obj, addPart);
  end;
end;

function CreateText(Obj: hObj; X, Y, Z: Double; FontName: PChar; txtHeight, txtAngle,
                     txtScale: Double; txtColor: Integer; Align: byte;
                      Bl, It, Un: boolean; Text, AttrName, addParams: PChar): hObj; stdcall;
begin
 With CallBackRec^ do
  if Assigned(CreateText) then begin
   Result := CreateText(Obj, X, Y, Z, FontName, txtHeight, txtAngle,
                         txtScale, txtColor, Align, Bl, It, Un,
                          Text, AttrName, addParams);
  end;
end;

end.

