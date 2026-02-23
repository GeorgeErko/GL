unit ogcMapObject;

{$mode Delphi}

interface uses Classes, SysUtils, Forms, gmfGeometry, ogcBasic, Graphics,
               ogcTypedCollect, uGLSceneIndexer;

type
 { TogsMapObjectect - базовый объект -> загрузчик библиотек блоков, тпов линий, заливок }
  TogsMapObject = class(TgmfBlock)
  private
   fOnPaint: TNotifyEvent;
   FIndexer: TGLSceneIndexer;
   FNextOgsID: Int64;
   procedure AssignOgsIDs;
   function GetPLibItem(Index: Integer): TgmfBlock;
  protected
   procedure SetogsSelector(Data: TogsSelector); override;
  public
   PLib: TStrTypedCollection; // блоки
   LLib: TStrTypedCollection; // типы линий
   SLib: TStrTypedCollection; // штриховки
   Drawer: TogsDrawer;
   constructor Create(Drawer_: TogsDrawer);
   destructor Destroy; override;
  //
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  // constructor jsLoad(Stream: TogsStream); override;
  // procedure jsStore(Stream: TogsStream); override;
  //
   procedure Clear; override;
   function OpenFile(FileName_: String): Integer; virtual;
   procedure UpdateObject(FitView: boolean = False);
  // доступ
   Property PLibItem[Index: Integer]: TgmfBlock read GetPLibItem;
  // поиск в библиотеках
   function SearchPLib(ItemName_: AnsiString): TgmfBlock;
   function SearchLLib(ItemName_: AnsiString): TgmfLineType;
   function SearchSLib(ItemName_: AnsiString): TgmfHatchStyle;
  // таблица блоков, типов линий,
   procedure AddBlock(Block: TgmfBlock);
   procedure AddLineType(LT: TgmfLinetype);
  // вставка в Geometry, возвращает индекс элемента
   function AddPrim(Prim: TogsGeometry): Integer; override;
  //
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // рисовка
   procedure Draw(Drawer: TogsDrawer); override;
   property OnPaint: TNotifyEvent read fOnPaint write fOnPaint;
   property Indexer: TGLSceneIndexer read FIndexer;
  end;

implementation uses TTFGeometry, ogcGMFReader, ogcWriter, ogcGeometry;

{ TogsMapObject }

procedure TogsMapObject.SetogsSelector(Data: TogsSelector);
var I: Integer;
begin
 inherited SetogsSelector(Data);
 For I := 0 to PLib.Count - 1 do
  TgmfBlock(PLib[I].Data).SetogsSelector(Data);
end;

constructor TogsMapObject.Create(Drawer_: TogsDrawer);
begin
//
 PLib := TStrTypedCollection.CreateTyped;
 LLib := TStrTypedCollection.CreateTyped;
 SLib := TStrTypedCollection.CreateTyped;
 FNextOgsID := 1;
//
 Drawer := Drawer_;
 ogsSelector := TogsSelector.Create(Drawer_);
 ogsSelector.Parent := Self;
 ogsSelector.sName := 'BasicObject';
//
 FIndexer := TGLSceneIndexer.Create(1.0);
//!!! временно очищаем глобальную коллекцию шрифтов
  ogsFontManager.FreeAll;
  ogsFontManager.LoadFontList(ogsSelector); // загрузка шрифтов из каталога ../FONTS
// вызов
 inherited Create(ogsSelector, '',-2, 0, 0, 0);
 Clear;
 ogsSelector.GlobalRect.Assign(ogsRect);
 ogsSelector.UpdateRects(True);
end;

destructor TogsMapObject.Destroy;
begin
 inherited Destroy;
 FreeAndNil(FIndexer);
 PLib.Free;
 LLib.Free;
 SLib.Free;
 ogsSelector.Free;
end;

constructor TogsMapObject.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
end;

procedure TogsMapObject.Store(Stream: TogsStream);
begin
 inherited Store(Stream);
end;

procedure TogsMapObject.Clear;
begin
 inherited Clear;
 ogsRect.CreateRect(0, 0, 10, 10);
 PLib.FreeAll; LLib.FreeAll; SLib.FreeAll;
 if FIndexer <> nil then FIndexer.Clear;
 FNextOgsID := 1;
// ogsSelector.AddCoord(0, 0); ogsSelector.AddCoord(10, 10);
// ogsSelector.Clear;
end;

procedure TogsMapObject.AssignOgsIDs;
var I: Integer;
    G: TogsGeometry;
begin
 if Geometry = nil then Exit;
 for I := 0 to Geometry.Count - 1 do
 begin
  G := Geometry.Item[I];
  if (G <> nil) and (G.ogsID = 0) then
  begin
   G.ogsID := FNextOgsID;
   Inc(FNextOgsID);
  end;
 end;
end;

function TogsMapObject.GetPLibItem(Index: Integer): TgmfBlock;
begin
 Result := TgmfBlock(PLib[Index].Data);
end;

function TogsMapObject.OpenFile(FileName_: String): Integer;
begin
 ogcGMFReader.OpenGMF(Self, FileName_);
 AssignOgsIDs;
end;

procedure TogsMapObject.UpdateObject(FitView: boolean);
var I: Integer;
begin
// получение ссылок на блоки из типов линий
 WriteIn(['Updatebegin']);
 For I := 0 to LLib.Count - 1 do
  TgmfLineType(LLib[I].Data).UpdateBlockTableItems(PLib);
 WriteIn(['Updatebegin2']);
 Geometry.Calculate([calcbBox]);
 WriteIn(['Updatebegin3']);
 ogsSelector.UpdateRects(FitView);
 WriteIn(['Updatebegin4']);
 Drawer.DoOnPaint(Self);
 WriteIn(['Updatebegin5']);
end;

procedure TogsMapObject.AddBlock(Block: TgmfBlock);
begin
 PLib.Add(Block.Name, Block);
end;

procedure TogsMapObject.AddLineType(LT: TgmfLinetype);
begin
 LLib.Add(LT.Name, LT);
end;

function TogsMapObject.AddPrim(Prim: TogsGeometry): Integer;
begin
// WriteIN(['BasicObj.AddPrim1=', Prim.ClassName, Prim.ogsRect]);
  If Prim is TogsPoint then Prim.Calculate([calcbBox, calcRelation, calcSquare, calcSortBy]) else
   If Prim is TogsMultiPoint then Prim.Calculate([calcLength, calcbBox]) else
                                  Prim.Calculate([calcRelation, calcSquare, calcbBox]);
  If Geometry.Count = 0 then ogsSelector.Clear;
  ogsSelector.AddPrim(Prim);
 // WriteIN(['BasicObj.AddPrim1=', Prim.ClassName, Prim.ogsRect]);
  Result := Geometry.Add(Prim);
//  WriteIN(['Selector.Rect=', ogsSelector.ActiveRect]);
end;

function TogsMapObject.SearchPLib(ItemName_: AnsiString): TgmfBlock;
var P: Pointer; I: Integer;
begin
{ Result := nil;
 For I := 0 to PLib.Count - 1 do
  If ItemName_ = TgmfBlock(PLib.Item[I].Data).Name then begin
   Result := PLib.List[I];
   WriteIn(['FoundP=',I]);
   exit;
  end;
 exit;
}
//
 Result := nil;
 P := PLib.SearchBy(ItemName_);
 If P <> nil then begin
  Result := TgmfBlock(P);
 end;
end;

function TogsMapObject.SearchLLib(ItemName_: AnsiString): TgmfLineType;
var P: Pointer; I: Integer;
begin
{
 Result := nil;
 For I := 0 to LLib.Count - 1 do
  If ItemName_ = TgmfLineType(LLib.Item[I].Data).Name then begin
   Result := LLib.List[I];
   WriteIn(['FoundL=',I]);
   exit;
  end;
 exit;
}
//
 Result := nil;
 P := LLib.SearchBy(ItemName_);
 If P <> nil then begin
 // WriteIn(['<>nil']);
  Result := TgmfLineType(P);
 // WriteIn(['LTFound=', Result.Name, ItemName_]);
 end else
 // WriteIn(['LTNOTFound=', ItemName_]);
end;

function TogsMapObject.SearchSLib(ItemName_: AnsiString): TgmfHatchStyle;
begin
 Result := SLib.SearchBy(ItemName_) as TgmfHatchStyle;
end;

function TogsMapObject.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
begin
 Result := False;
 Selected := False;
 WriteIn(['BasicObj.Geometry.Count=', Geometry.Count]);
 For I := Geometry.Count -1 downto 0 do begin
//  WriteIn(['Geomatry ', I, Geometry[I].ClassName,' ..Geometry.Count=', TgmfPoint(Geometry[I]).gmfBlock.Geometry.Count]);
  Result := Geometry[I].SelectByPoint(X_, Y_, Params);
  // Geometry[I].Selected := True;
  If Result then begin
   Params.resObject := Geometry.Item[I];
   exit;
  end;
 end;
end;

procedure TogsMapObject.Draw(Drawer: TogsDrawer);
var Pen:TogsPen; Brush: TogsBrush;
begin
// рисуем
 Pen := Drawer.SelectPen(TogsPen.Create(0, 0, nil));
 Brush := Drawer.SelectBrush(TogsBrush.Create(0, nil));
 try
  inherited Draw(Drawer);
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
  Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
 end;
end;

end.

