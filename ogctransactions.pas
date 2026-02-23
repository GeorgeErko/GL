unit ogctransactions;

{$mode Delphi}

interface

uses Classes, SysUtils, ogcBasic;

type

 { TUpdater - абстрактный класс для проверки возможности внесения изменений
              в объект во время транзакции. Применяется при удаленных соединениях
              и соединенни с БД
 }

 TUpdater = class(TogsBasic)
  function Insert(Prim:TObject): boolean; virtual;
  function Uodate(Prim:TObject): boolean; virtual;
  function Delete(Prim:TObject): boolean; virtual;
 end;

 { TogsBasicTransaction }

 TogsBasicTransaction = class(TogsBasic)
 private
  fogsSelector: TogsSelector;
  function GetogsSelector: TogsSelector; override;
  procedure SetogsSelector(AValue: TogsSelector); override;
 public
  constructor Create(ogsSelector_: TogsSelector);
 end;

 TTransactionMode = (tmInsert, tmUpdate, tmDelete);

 { TogsSingleTransaction }

 TogsSingleTransaction = class(TogsBasicTransaction)
  Mode: TTransactionMode;
 // идентификатор транзакции
  ID: Integer;
 // ID элемента единичной транзакции
  GUID: TGUID;
 // оригинальный и дубликат объект с ID-транзакции
  objOriginal,
  objDuplicate: TogsBasic;
  constructor Create(ID_: Integer; Mode_: TTransactionMode; ogsObject: TogsBasic; copyPerform: Boolean);
  destructor Destroy; override;
 end;

 { TogsTransactionItem }

 TogsTransactionItem = class(TogsBasicTransaction)
 private
  function GetTransactionItem(Index: Integer): TogsTransactionItem;
 public
 // неуникальное имя транзакции
  Name: String;
 // идентификатор для группы примитивов объекта ogsSelector.ogsParent
 // ID сохраняется в примитиве ogsObject.TransactionID
  ID: Integer;
 // список примитивов с одним TransactionID
  Items: TogsCollection;
 //
  Commited: Boolean;
  constructor Create(ogsSelector_: TogsSelector; Name_: String; ID_: Integer);
  destructor Destroy; override;
 //
  property Item[Index: Integer]: TogsTransactionItem read GetTransactionItem;
  procedure Insert (ogsObject: TogsBasic);
  procedure Update (ogsObject: TogsBasic);
  procedure Delete (ogsObject: TogsBasic);
 end;

 { TogsTransactionList }

 TogsTransactionList = class(TogsBasicTransaction)
 private
  fUpdater: TUpdater;
  IDCounter: Integer;
  CurrentTransaction: TogsTransactionItem;
  Items: TogsCollection;
  function GetTransactionItem(Index: Integer): TogsTransactionItem;
 public
  constructor Create(Selector_: TogsSelector; Updater_: TUpdater);
  destructor Destroy; override;
 //
  property Item[Index: Integer]: TogsTransactionItem read GetTransactionItem;
  function Count: Integer;
 //
  property Updater: TUpdater read fUpdater write fUpdater;
 //
  function StartTransaction(Name: String): TogsTransactionItem;
  procedure CommitTransaction;
  procedure RollbackTransaction;
 end;

implementation

{ TUpdater }

function TUpdater.Insert(Prim: TObject): boolean;
begin
 Result := True;
end;

function TUpdater.Uodate(Prim: TObject): boolean;
begin
 Result := True;
end;

function TUpdater.Delete(Prim: TObject): boolean;
begin
 Result := True;
end;

{ TogsBasicTransaction }

function TogsBasicTransaction.GetogsSelector: TogsSelector;
begin
 Result := fogsSelector;
end;

procedure TogsBasicTransaction.SetogsSelector(AValue: TogsSelector);
begin
 fogsSelector := AValue;
end;

constructor TogsBasicTransaction.Create(ogsSelector_: TogsSelector);
begin
 fogsSelector := ogsSelector;
end;


{ TogsSingleTransaction }

constructor TogsSingleTransaction.Create(ID_: Integer; Mode_: TTransactionMode;
                                          ogsObject: TogsBasic; copyPerform: Boolean);
begin
 ID := ID_;
// GIUD := ogsObject.GUID;
 ogsObject.TransactionID := ID;
 objOriginal := ogsObject;
 If copyPerform then
  objDuplicate := TogsBasicClass(ogsObject.ClassType).CreateAs(objOriginal);
end;

destructor TogsSingleTransaction.Destroy;
begin
 inherited Destroy;
 If objDuplicate <> nil then objDuplicate.Free;
end;

{ TogsTransactionItem }

function TogsTransactionItem.GetTransactionItem(Index: Integer): TogsTransactionItem;
begin
 Result := Items[Index];
end;

constructor TogsTransactionItem.Create(ogsSelector_: TogsSelector; Name_: String; ID_: Integer);
begin
 inherited Create(ogsSelector_);
 Name := Name_;
 ID := ID_;
 Items := TogsCollection.Create;
end;

destructor TogsTransactionItem.Destroy;
begin
 inherited Destroy;
 Items.Free;
end;

procedure TogsTransactionItem.Insert(ogsObject: TogsBasic);
begin
// добавление
 Items.Add(TogsSingleTransaction.Create(ID, tmInsert, ogsObject, False));
end;

procedure TogsTransactionItem.Update(ogsObject: TogsBasic);
begin
// обновление
 Items.Add(TogsSingleTransaction.Create(ID, tmUpdate, ogsObject, True));
end;

procedure TogsTransactionItem.Delete(ogsObject: TogsBasic);
begin
// удаление
 Items.Add(TogsSingleTransaction.Create(ID, tmDelete, ogsObject, True));
end;

{ TogsTransactionList }

constructor TogsTransactionList.Create(Selector_: TogsSelector; Updater_: TUpdater);
begin
// возможно присваивать userID * 100 ???
 IDCounter := 0;
 Items := TogsCollection.Create;
 fUpdater := Updater;
end;

destructor TogsTransactionList.Destroy;
begin
 Items.Free;
end;

function TogsTransactionList.GetTransactionItem(Index: Integer): TogsTransactionItem;
begin
 Result := Items[Index];
end;

function TogsTransactionList.Count: Integer;
begin
 Result := Items.Count;
end;

function TogsTransactionList.StartTransaction(Name: String): TogsTransactionItem;
begin
 If CurrentTransaction <> nil then begin
 // запрет на вложенность транзакций
  raise Exception.Create(ClassName + '.ActiveTransaction = "' + CurrentTransaction.Name+ '" raised exception for Name = ' + Name);
 end;
 Inc(IDCounter);
 CurrentTransaction := TogsTransactionItem.Create(fogsSelector, Name, IDCounter);
 Result := CurrentTransaction;
end;

procedure TogsTransactionList.CommitTransaction;
begin
 If CurrentTransaction <> nil then begin
 // транзакция остается в списке Items для выполнения отката
  CurrentTransaction.Commited := True;
  CurrentTransaction := nil;
 end else
 raise Exception.Create(ClassName + ' commited null transaction');
end;

procedure TogsTransactionList.RollbackTransaction;
begin
 // откат транзакции - удаление из списка

end;

end.

