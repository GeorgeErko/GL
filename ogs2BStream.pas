unit ogs2BStream;

{$mode Delphi}

interface

uses Classes, SysUtils, ogcBasic, ogcMemStream;

type

  { TogsObjIntf }

  // объект с информацией об объекте (версия + размер)
  // objData - либо успешно загруженный объект,
  // либо TogsContainer - объект с буфффером для хранения в потоке
  // TogsObjIntf + TogsContainer позволяет сохранять содержимое объекта
  // с его размером и считывать даже:
  //                * если это предыдущая версия открывающей программы
  //                * если объект внутри его буфера сохранен некорректно
  // позволет сохранить скорость запись/чтение в поток на максимально
  // приближенном а TStream.Get/TStream.Put
  TogsObjIntf = class(TogsBasic)
   objVersion: Byte;
   objSize: Integer;
   objData: TogsBasic;
   constructor Create(Version: Byte; Data: TogsBasic);
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  end;

  { TogsCantainer }

  TogsContainer = class(TogsBasic)
   objData: TogsBasic;
   Buffer: Pointer;
   constructor  Create(objData_: TogsBasic);
   constructor Load(Stream: TogsStream);
   procedure Store(Stream: TogsStream);
   destructor Destroy; override;
  end;

  { Togs2BStream }

  Togs2BStream = class(TogsStream)
   function  Pop: TogsBasic;
   procedure Push (ogsObject: TogsBasic);
  end;


implementation uses ogcWriter;

{ TogsObjIntf }

constructor TogsObjIntf.Create(Version: Byte; Data: TogsBasic);
begin
 objVersion := Version;
 objData := Data;
end;

constructor TogsObjIntf.Load(Stream: TogsStream);
var ogsContainer: TogsContainer;
begin
 Stream.Read(objVersion, SizeOf(objVersion));
 Stream.Version := objVersion;
 ogsContainer := TogsContainer(Stream.Get);
 objData := ogsContainer.objData;
// считали контейнер -> если в objData он вернул объект -> уничтожаем
 If ogsContainer <> ogsContainer.objData
  then
   ogsContainer.Free;
end;

procedure TogsObjIntf.Store(Stream: TogsStream);
var ogsContainer: TogsContainer;
begin
 Stream.Write(objVersion, SizeOf(objVersion));
 Stream.Version := objVersion;
 ogsContainer := TogsContainer.Create(objData);
 Stream.Put(ogsContainer);
 ogsContainer.Free;
end;

{ TogsContainer }

constructor TogsContainer.Create(objData_: TogsBasic);
begin
 objData := objData_;
end;

constructor TogsContainer.Load(Stream: TogsStream);
var objSize: Integer;
    ogsStream: TogsStream; // временный TMemStream для корректного считывания
    objType: SmallInt;
    ogsBasicClass: TogsBasicClass;
begin
 Stream.Read(objSize, SizeOf(objSize));
 ogsStream := TogsStream.CreateMemoryStream(-1); // указатель Memory не будет уничтожен в TMemStream.Destroy
 TMemStream(ogsStream.Stream).Size := objSize;
 Stream.Read(TMemStream(ogsStream.Stream).Memory^, objSize);
// читаем объект objData из буфера Buffer, аналогично TogsStream.Get
 ogsStream.Read(objType, SizeOf(objType));
// ищем в ogsRegisteredObjects класс для загрузки объекта
 ogsBasicClass := LinearSearchGet(objType);
 if ogsBasicClass = nil then begin
 // не нашли -> поместили в буфер
  Buffer := TMemStream(ogsStream.Stream).Memory;
  objData := Self;
 end else begin
 // Buffer := nil;
  ogsStream.Version := Stream.Version;
  objData := ogsBasicClass.Load(ogsStream);
 //
  TMemStream(ogsStream.Stream).doFreeMemory := True;
  ogsStream.Free;
 end;
end;

procedure TogsContainer.Store(Stream: TogsStream);
var ogsStream: TogsStream;
begin
// сохрвняем объект objData в буфер поток
 ogsStream := TogsStream.CreateMemoryStream(0); // указатель Memory будет уничтожена в TMemStream.Destroy
 ogsStream.Version := Stream.Version;
 ogsStream.Put(objData);
 Stream.Write(ogsStream.Size, SizeOf(ogsStream.Size));
 Stream.Write(TMemStream(ogsStream.Stream).Memory^, ogsStream.Size);
 ogsStream.Free;
end;

destructor TogsContainer.Destroy;
var memStream: TMEmStream;
begin
 If Buffer <> nil then begin
  memStream := TMemStream.Create(True);
  memStream.Memory := Buffer;
  memStream.Free;
 end;
end;

{ Togs2BStream }

function Togs2BStream.Pop: TogsBasic;
var objType: SmallInt;
    ogsBasicClass: TogsBasicClass;
begin
 Stream.Read(objType, SizeOf(objType));
 If objType = 0 then begin Result := nil; exit;end;
 // ищем в ogsRegisteredObjects класс для загрузки объекта
 ogsBasicClass:= fOnSearchGetProc(objType);
 if ogsBasicClass = nil then raise Exception.Create(Fmt(['Не найден регистрационный код (Stream.Get): ',objType]));
 Result := ogsBasicClass.Load(Self);
 If Result is TogsObjIntf then
  Result := Result.Load(Self);
end;

procedure Togs2BStream.Push(ogsObject: TogsBasic);
var objType: SmallInt;
    ogsBasicClass: TogsBasicClass;
begin
 If ogsObject = nil then begin
  objType := 0; Stream.Write(objType, SizeOf(ObjType));
  exit;
 end;
 // ищем в ogsRegisteredObjects класс для сохранения объекта
 objType := fOnSearchPutProc(TogsBasicClass(ogsObject.ClassType));
 if objType = -1 then raise Exception.Create(Fmt(['Не зарегистрирован класс (Stream.Put): ',ogsObject.ClassName]));
 Self.Write(objType, SizeOf(objType));
 ogsObject.Store(Self);
end;

end.

