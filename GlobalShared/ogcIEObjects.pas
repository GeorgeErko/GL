unit ogcIEObjects;

{$mode Delphi}

interface

uses Classes, SysUtils, ogcCallbackRec, ogcCallbackTypes,
      ogcBasic, ogcMapObject, ogcGeometry,
       ogcArcs, gmfGeometry, TTFGeometry;

// объекты импорта/экспорта
// каждый объект устанавливает только те callback-процедуры
// которые использует инкапсулируемый объект TogsBasic
// остальные - загрушки, либо вызывают исключения

type

 TIEObject = class;
 TIEGarbageItems = class;

 TDestroyIEEvent = procedure(IEObject: TIEObject) of object;

 { TIEObject }

 TIEObject = class(TObject)
 public
  Parent: TIEObject;
  ogsObject: TogsBasic;
  cbRec    : PCallbackRec;
 //
  IEGarbageItem: TIEGarbageItems;
 // базовый объект TogsBasig
  constructor Create(Parent_: TIEObject; ogsObject_: TogsBasic); virtual;
  destructor Destroy; override;
 end;

 { TIEPoint }

 TIEPoint = class(TIEObject)
  constructor Create(Parent_: TIEObject; ogsObject_: TogsBasic); override;
 end;

 { TIEBlock }

 TIEBlock = class(TIEObject)
  constructor Create(Parent_: TIEObject; ogsObject_: TogsBasic); override;
 end;

 { TIEAttrib }

 TIEAttrib = class(TIEObject)
  constructor Create(Parent_: TIEObject; ogsObject_: TogsBasic); override;
 end;


 { TIELinearObject }

 TIELinearObject = class(TIEObject)
  constructor Create(Parent_: TIEObject; ogsObject_: TogsBasic); override;
  function AddPoints(P: PGeoPoint): Integer; virtual;
  function AddEdges(P: PGeoEdge): Integer; virtual;
 end;

 { TIEMultiLinearObject }

 TIEMultiLinearObject = class(TIELinearObject)
  function AddPoints(P: PGeoPoint): Integer; override;
 end;

 { TIEPolygon }

 TIEPolygon = class(TIELinearObject)
  function AddPoints(P: PGeoPoint): Integer; override;
 end;

 { TIEPolygon }

 TIEText = class(TIEObject)
 end;

 { TIELineType }

 TIELineType = class (TIEObject)
  constructor Create(Parent_: TIEObject; ogsObject_: TogsBasic); override;
 end;

 { TIEGarbageItems - список IE-объектов GarbageList}

 TIEGarbageItems = class(TogsBasic)
  Name: String;
  IEObject: TIEObject;
  Prev, Next, First, Last: TIEGarbageItems;
  Count: Integer;
  LockItems: boolean;
  constructor Create(IEObject_: TIEObject);
  destructor Destroy; override;
  procedure AddItem(IEObject_: TIEObject);
  procedure DeleteItem;
  procedure FreeAll;
 end;

// создание/сброс корневого объетка TogsMapObjectect
 function  ieCreateRootObject(ogsMapObject: TogsMapObject): TIEObject;
 procedure ieResetRootObject(IEObject: TIEObject);

var CallbackRec: PCallbackRec;

implementation uses ogcIEProcs, ogcWriter, ogcGeometry2;

function ieCreateRootObject(ogsMapObject: TogsMapObject): TIEObject;
begin
 Result := TIEObject.Create(nil, ogsMapObject);
 CallbackRec.HObject := Integer(Result);
end;

procedure ieResetRootObject(IEObject: TIEObject);
begin
 IEObject.Free;
end;

{ TIEGarbageItems }

constructor TIEGarbageItems.Create(IEObject_: TIEObject);
begin
 IEObject := IEObject_;
 IEObject.IEGarbageItem := Self;
 If IEObject.Parent = nil then
  First := Self;
 Prev := nil; Next := nil;
 Last := Self;
 Count := 0;
end;

destructor TIEGarbageItems.Destroy;
begin
 If Prev = nil then
  FreeAll
 else
  DeleteItem
end;

procedure TIEGarbageItems.AddItem(IEObject_: TIEObject);
var Item: TIEGarbageItems;
begin
// WriteIn(['Garbage.Name=', Name, First.Count]);
 Item := TIEGarbageItems.Create(IEObject_);
 Item.First := First;
 Item.Name := 'next' + Fmt([First.Count]);
 Item.Prev := First.Last; First.Last.Next := Item;
 First.Last := Item;
 Inc(First.Count);
end;

procedure TIEGarbageItems.DeleteItem;
begin
// WriteIn(['Delete.Count=', First.Count]);
 If LockItems then exit;
 If Prev <> nil then Prev.Next := Next;
 If Next <> nil then Next.Prev := Prev;
 If First.Last = Self then
  First.Last := Prev;
 Dec(First.Count);
// WriteIn(['Delete.Count=', First.Count]);
end;

procedure TIEGarbageItems.FreeAll;
var Item, Item1: TIEGarbageItems;
begin
 LockItems := True;
 try
  Item := First.Last;
  While Item.Prev <> nil do begin
   Item1 := Item.Prev;
   Item.IEObject.Free;// Item.Free;
   Item := Item1;
  end;
 finally
  LockItems := False;
 end;
end;

{ TIEObject }

constructor TIEObject.Create(Parent_: TIEObject; ogsObject_: TogsBasic);
begin
 Parent := Parent_;
//
 cbRec := GetMem(SizeOf(TCallbackRec)); // резервируем память для процедур обратного вызова
 FillChar(cbRec^, SizeOf(TCallbackRec), 0);
 ogsObject := ogsObject_;
 If Parent = nil then begin // корневой объект заполняет все процедуры cbRec
 // для корневого объекта создаем garbage-коллекцию
  IEGarbageItem := TIEGarbageItems.Create(Self);
  IEGarbageItem.Name := 'root';
 //
  cbRec.hObject := Integer(Self);
 //
  cbRec.CreatePoint := ieCreatePoint;
  cbRec.FindBlock := ieFindBlock;
  cbRec.CreateBlock := ieCreateBlock;
  cbRec.AddPrimitive := ieAddPrimitive;
  cbRec.UpdateObject := ieUpdateObject;
  cbRec.WriteString := ieWriteString;
 //
  cbRec.CreatePolyLine := ieCreatePolyline;
  cbRec.CreateMPolyLine := ieCreateMPolyline;
  cbRec.CreatePolygon := ieCreatePolygon;
  cbRec.CreateMPolygon := ieCreateMPolygon;
  cbRec.CreateMultiline := ieCreateMultiLine;
  cbRec.CreateText := ieCreateText;
  cbRec.FindLineType    := ieFindLineType;
  cbRec.CreateLineType  := ieCreateLineType;
 end else begin
  Parent.IEGarbageItem.AddItem(Self);
 //
  cbRec.hObject := Integer(ogsObject);
  cbRec.WriteString := ieWriteString;
 end;
end;

destructor TIEObject.Destroy;
begin
 IEGarbageItem.Free;
 FreeMem(cbRec);
end;

{ TIEPoint }

constructor TIEPoint.Create(Parent_: TIEObject; ogsObject_: TogsBasic);
begin
 inherited;
// ф-ции для точечных объектов
 cbRec.SetPointParams := ieSetPointParams;
 cbRec.CreateBlock := ieCreateBlock;
 cbRec.WriteString := ieWriteString;
 cbRec.CreateAttrib := ieCreateAttrib;
// cbRec.SetAttrValue := ieSetAttrValue;
end;


{ TIEBlock }

constructor TIEBlock.Create(Parent_: TIEObject; ogsObject_: TogsBasic);
begin
 inherited;
// ф-ции для точечных объектов
 cbRec.PolyEvent := iePolyEvent;
 cbRec.TextEvent := ieTextEvent;
 cbRec.FindAttrib := ieFindAttrib;
 cbRec.AddPrimitive := ieAddPrimitive;
//
 cbRec.WriteString := ieWriteString;
end;

{ TIEAttrib }

constructor TIEAttrib.Create(Parent_: TIEObject; ogsObject_: TogsBasic);
begin
 inherited;
 // ф-ции для точечных объектов
 cbRec.CreateAttrValue := ieCreateAttrValue;
end;

{ TIELinearObject }

constructor TIELinearObject.Create(Parent_: TIEObject; ogsObject_: TogsBasic);
begin
 inherited Create(Parent_, ogsObject_);
 // ф-ции для линейных-полигональных объектов
 cbRec.AddPolyPoints := ieAddPolyPoints;
end;

function TIELinearObject.AddPoints(P: PGeoPoint): Integer;
var I: Integer;
begin
// WriteIn(['addPoints=',P.Count]);
 Result := 0;
 For I := 0 to P.Count - 1 do
  With TogsLineString(ogsObject) do begin
//   WriteIn(['apXY=', P.X, P.Y]);
   AddPoint(P.X, P.Y, P.Z);
   P := P.Next;
   Inc(Result);
  end;
// WriteIn(['====end']);
end;

function TIELinearObject.AddEdges(P: PGeoEdge): Integer;
var I: Integer;
begin
// WriteIn(['addPoints=',P.Count]);
 Result := 0;
 For I := 0 to P.Count - 1 do
  With TgmfMultiLine(ogsObject) do begin
//   WriteIn(['apXY=', P.X, P.Y]);
   If P.Bulge = 0 then
    AddPoint(TogsEdge.Create(ogsSelector, P.XA, P.YA, P.ZA, P.XB, P.YB, P.ZB)) else
    AddPoint(TogsArc.Create(ogsSelector, P.GetArcRec));
   P := P.Next;
   Inc(Result);
  end;
// WriteIn(['====end']);
end;

{ TIEMultiLinearObject }

function TIEMultiLinearObject.AddPoints(P: PGeoPoint): Integer;
var Line: TogsLineString;
    oldObj: pointer;
begin
// WriteIn(['MultiLine.Add']);
 Line := TogsLineString.Create(ogsObject.ogsSelector);
 oldObj := ogsObject;
 ogsObject := Line;
 try
  Result := inherited AddPoints(P);
 finally
  ogsObject := oldObj;
 end;
 TgmfMultiLineString(ogsObject).AddLine(Line);
end;

{ TIEPolygon }

function TIEPolygon.AddPoints(P: PGeoPoint): Integer;
var Poly: TPoly_Single;
    oldObj: pointer;
begin
// WriteIn(['MultiLine.Add']);
 Poly := TPoly_Single.Create(ogsObject.ogsSelector);
 oldObj := ogsObject;
 ogsObject := Poly;
 try
  Result := inherited AddPoints(P);
 finally
  ogsObject := oldObj;
 end;
 TogsPolygon(ogsObject).AddPolygon(Poly);
end;

{ TIELineType }

constructor TIELineType.Create(Parent_: TIEObject; ogsObject_: TogsBasic);
begin
 inherited Create(Parent_, ogsObject_);
 cbRec.AddPartOfLineType := ieAddPartOfLineType;
end;

initialization
 New(CallbackRec);
 With CallbackRec^ do begin
  EnableForms     := ieEnableForms;
  DisableForms    := ieDisableForms;
 //
  DestroyObject   := ieDestroyObject;
  ResetObject     := ieResetObject;
 //
  CreatePoint     := ieCreatePoint;
  SetPointParams  := ieSetPointParams;
  FindBlock       := ieFindBlock;
  CreateBlock     := ieCreateBlock;
  PolyEvent       := iePolyEvent;
  TextEvent       := ieTextEvent;
  FindAttrib      := ieFindAttrib;
  CreateAttrib    := ieCreateAttrib;
  CreateAttrValue := ieCreateAttrValue;
 //
  UpdateObject    := ieUpdateObject;
 //
  AddPrimitive    := ieAddPrimitive;
 //
  WriteString     := ieWriteString;
 // создание примитивов hPrim для hObject
  CreatePolyLine  := ieCreatePolyLine;
  CreateMPolyLine := ieCreateMPolyLine;
  CreatePolygon   := ieCreatePolygon;
  CreateMPolygon  := ieCreateMPolygon;
  AddPolyPoints   := ieAddPolyPoints;
 // типы линий
  FindLineType    := ieFindLineType;
  CreateLineType  := ieCreateLineType;
  AddPartOfLineType := ieAddPartOfLineType;
 //
  CreateText      := ieCreateText;
end;
finalization
 Dispose(CallbackRec);
end.

