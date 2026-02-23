unit ogcInspector;

{$mode Delphi}

interface

uses Classes, SysUtils, Controls, ogcBasic, ogcProperties, ValEdit, Grids;

type

 TOIItems = class;

 { TOIItem }

 TOIItem = class(TogsBasic)
 private
  fState: TpropState;
  function GetItem(Index: Integer): TOIItem;
  procedure SetState(AValue: TpropState);
 public
  Name, Value: String;
  Level: Integer;
  propValue: TogsPropValue;
  Items: TOIItems;
  constructor Create(Name_, Value_: String; propValue_: TogsPropValue; Level_: Integer);
  destructor Destroy; override;
  function Space: String;
  function isArray: boolean;
  function isSimple: boolean;
  function isExpanded: boolean;
  //
  property Item[Index: Integer]: TOIItem read GetItem; default;
  property State: TpropState read fState write SetState;
 end;

 { TOIItems }

 TOIItems = class(TogsCollection)
 private
  function GetItem(Index: Integer): TOIItem;
 public
  Level: Integer;
  constructor Create(Level_: Integer);
  function Add(Name, Value: String; propValue: TogsPropValue): TOIItem;
  procedure UpdateItems(OIItem: TOIItem; propValue: TogspropValue);
 //
  property Item[Index: Integer]: TOIItem read GetItem; default;
 end;

 { TPropInspector }

 TPropInspector = class(TogsBasic)
 private
  fProperties: TogsPropValue;
  ViewLocked: Boolean;
  View : TValueListEditor;
  Images: TImageList;
  MouseX, MouseY: Integer;
  activeCol, activeRow: Integer;
  activeRect: TRect;
  Items: TOIItems;
  function GetItem(Index: Integer): TOIItem;
  function GetogsProperties: TogsProperties; override;
  procedure SetogsProperties(AValue: TogsProperties); override;
  procedure DrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
  procedure SelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  procedure MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  procedure MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure DblClick(Sender: TObject);
  procedure SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
  procedure ValidateEntry(sender: TObject; aCol, aRow: Integer; const OldValue: string; var NewValue: String);
 public
  constructor Create(View_: TValueListEditor; propValue: TogsPropValue; Images_: TImageList);
  destructor Destroy; override;
  procedure ClearView;
  procedure UpdateView(Items: TOIItems; startRow: Integer);
  procedure UpdateState(Item: TOIItem);
 //
  function GetRect(X, Y: Integer): Boolean;
 //
  Property Item[Index: Integer]: TOIItem read GetItem;
 end;

const
  cellX = 4;

implementation uses Graphics, ogcWriter;

{ TOIItem }

function TOIItem.GetItem(Index: Integer): TOIItem;
begin
 Result := Items[Index];
end;

procedure TOIItem.SetState(AValue: TpropState);
begin
 if fState = AValue then Exit;
 fState := AValue;
 propValue.State := fState;
end;

constructor TOIItem.Create(Name_, Value_: String; propValue_: TogsPropValue; Level_: Integer);
begin
 Name := Name_;
 Value := Value_;
 Level := Level_ + 1;
 fState := propValue_.State;
 propValue:= propValue_;
//
 Items := TOIItems.Create(Level);
end;

destructor TOIItem.Destroy;
begin
 if propValue is TogsPropArrayItem then propValue.Free;
end;

function TOIItem.Space: String;
var I:Integer;
begin
 Result := '';
 For I := 1 to Level do Result := Result + #32#32;
end;

function TOIItem.isArray: boolean;
begin
 Result := Items.Count > 0;
end;

function TOIItem.isSimple: boolean;
begin
 Result := Items.Count = 0;
end;

function TOIItem.isExpanded: boolean;
begin
 Result := (isArray and (State = psExpanded)) or (isSimple);
end;

{ TOIItems }

function TOIItems.GetItem(Index: Integer): TOIItem;
begin
 Result := List[Index];
end;

constructor TOIItems.Create(Level_: Integer);
begin
 inherited Create;
 Level := Level_;
end;

function TOIItems.Add(Name, Value: String; propValue: TogsPropValue): TOIItem;
begin
 Result := TOIItem.Create(Name, Value, propValue, Level);
 inherited Add(Result);
end;

procedure TOIItems.UpdateItems(OIItem: TOIItem; propValue: TogspropValue);
var I: Integer;
begin
 outSpace := '';
// вместо проверки типа propValue, можно обращаться, используя propValue.TypeOf
 If (propValue is TogsPropString) or (propValue is TogsPropFloat) or
     (propValue is TogsPropBool) or (propValue is TogsPropNull)then begin
  If Count > 0 then
   Item[Count - 1].Value := propValue.AsString
  else
   Add(Fmt([propValue.propName]), propValue.AsString, propValue);
 end else
 If propValue is TogsProperty then begin
  OIItem := Add(Fmt([propValue.propName]), '', propValue.propValue);
  If (propValue.TypeOf = ptString) or (propValue.TypeOf = ptNumber)
    or (propValue.TypeOf = ptBool) or (propValue.TypeOf = ptNull) then
   UpdateItems(nil, propValue.propValue)
  else
   OIItem.Items.UpdateItems(OIITem, propValue.propValue);
 end else
 If propValue is TogsPropObject then begin
  For I := 0 to propValue.Count - 1 do begin
   UpdateItems(nil, propValue.Item[I]);
  end;
 end else
 If propValue is TogsPropArray then begin
  For I := 0 to propValue.Count - 1 do begin
   OIItem := Add(Fmt(['Item [', I, ']']), '', TogspropArrayItem.Create);
   OIItem.State := psCollapsed;
   OIItem.Items.UpdateItems(nil, propValue.Item[I]);
  end;
 end;
 outSpace := ' ';
end;

{ TPropInspector }

constructor TPropInspector.Create(View_: TValueListEditor; propValue: TogsPropValue; Images_: TImageList);
begin
//
 View := View_;
 View.OnDrawCell := DrawCell;
 View.OnSelectCell := SelectCell;
 View.OnMouseMove := MouseMove;
 View.OnDblClick := DblClick;
 View.OnMouseDown := MouseDown;
 View.OnSetEdittext := SetEditText;
 View.OnValidateEntry := ValidateEntry;
 View.ColWidths[0] := View.Width div 2;
//
 Images := Images_;
 Items := TOIItems.Create(-1);
 ogsProperties := propValue;
//
 If propValue <> nil then Items.UpdateItems(nil, propValue);
 ClearView;
 UpdateView(Items,-1);
end;

destructor TPropInspector.Destroy;
begin
 Items.Free;
 if fProperties <> nil then
   fProperties.Free;
end;

procedure TPropInspector.ClearView;
begin
 View.Clear;
 If Items <> nil then Items.FreeAll;
// View.RowCount := 1;
end;

function TPropInspector.GetogsProperties: TogsProperties;
begin
 Result := fProperties;
end;

function TPropInspector.GetItem(Index: Integer): TOIItem;
begin
 Result := Items[Index];
end;

procedure TPropInspector.SetogsProperties(AValue: TogsProperties);
begin
 if fProperties <> nil then fProperties.Free;
 If AValue <> nil then begin
  fProperties := TogsBasicClass(AValue.ClassType).CreateAs(AValue) as TogsPropValue;
  fProperties.Update(0);
  ClearView;
  Items.UpdateItems(nil, TogsPropValue(AValue));
  UpdateView(Items, -1);
 end else begin
  fProperties := nil;
  ClearView;
 end;
end;

procedure TPropInspector.DrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
var Delta: Integer;
    Prefix: String;
    Value: TOIItem;
begin
// WriteIn(['Draw.Row = ', aRow]);
 If (aRow = 0) or (Items.Count = 0) then exit;
 Value := TOIItem(View.Rows[aRow].Objects[0]);
 If Value = nil then exit;
 View.Font.Color := View.Font.Color;
 If ACol = 1 then With View.Canvas do
  If Value.propValue.TypeOf = ptString then Font.Color := clnavy else
  If Value.propValue.TypeOf = ptNumber then Font.Color := clMaroon else
  If Value.propValue.TypeOf = ptBool then begin
    Font.Color := clGreen;
  end else
 If Value.propValue.TypeOf = ptNull then Font.Color := clBlack;
 Delta := cellX + (Value.Level) * 8;
 With View.Canvas do
  If aCol = 0 then begin
   ClipRect := aRect;
   Clipping := True;
   FillRect(aRect);
   If Value.propValue is TogsPropArray then begin
    If Value.propValue.State = psCollapsed then Prefix := '+' else Prefix:='-';
   // Dec(Delta, 8);
    If Prefix = '-' then Font.Style := [fsItalic, fsBold] else Font.Style := [fsBold];
   end;
   // else WriteIn(['Class=',Value.propValue.ClassName]);
   TextRect(aRect, arect.Left + Delta, 0, Prefix + Value.Name);
  end else begin
   ClipRect := aRect;
   Clipping := True;
   FillRect(aRect);
   If Value.propValue is TogsPropArray then begin
    Font.Style := [fsBold]; Font.Color := clGreen;
   end;
   TextRect(aRect, arect.Left + cellX, 0, View.Cells[aCol, aRow]);
  end;
//  WriteIn(['EndDraw.Row = ', aRow]);
end;

procedure TPropInspector.SelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
var Value: TOIItem;
begin
// WriteIn(['Select.Row = ', aRow]);
 If ViewLocked or (aRow = 0) or (Items.Count = 0) then exit;
 Value := TOIItem(View.Rows[aRow].Objects[0]);
 If Value = nil then exit;
 If (aCol = 1) and (Value.propValue is TogsPropArray) then begin
  CanSelect := False;
  ViewLocked := True;
  View.Row := aRow; View.Col := 0;
  ViewLocked := False;
 end else
  CanSelect := True;
end;

procedure TPropInspector.MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
 MouseX := X;
 MouseY := Y;
end;

procedure TPropInspector.MouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
var Value: TOIItem;
    Delta: Integer;
begin
// устанавливаем элемент списка для установки Value.State
 If GetRect(MouseX, MouseY) then begin
  Value := TOIItem(View.Rows[activeRow].Objects[0]);
  If Value = nil then exit;
  Delta := cellX + (Value.Level) * 8;
  If Value.propValue is TogsPropArray then begin
   If (MouseX >= Delta) and (MouseX <= Delta + 8) then begin
   // раскрываем или закрываем массив/объект в списке в соответствии с Value.State
    View.Row := activeRow;
    UpdateState(Value);
   end;
  end;
 end;
end;

procedure TPropInspector.DblClick(Sender: TObject);
begin
// не используется
end;

procedure TPropInspector.SetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
// не используется
end;

procedure TPropInspector.ValidateEntry(sender: TObject; aCol, aRow: Integer; const OldValue: string; var NewValue: String);
var propValue: TogsPropValue;
begin
 If ViewLocked or (View.Rows[aRow].Objects[0] = nil) then exit;
 propValue := TOIItem(View.Rows[aRow].Objects[0]).propValue;
 If propValue.ValidateEntry(NewValue) then begin
  propValue.AsString := NewValue;
  ViewLocked := True;
//  WriteIn(['Value=',propValue.AsString]);
   View.Cells[aCol, aRow] := propValue.AsString;
   TOIItem(View.Rows[aRow].Objects[0]).Value := propValue.AsString;
  ViewLocked := False;
 end else
  Exception.Create('TPropInspector.Error = Введено недопустимое значение ' + newValue);
end;

function TPropInspector.GetRect(X, Y: Integer): Boolean;
var I, J: Integer;
    R: TRect;
begin
 Result := False;
 activeCol := -1; activeRow := -1;
 For I := 0 to 1 do
  For J := 1 to View.RowCount - 1 do begin
   R := View.CellRect(I, J);
   If (X > R.Left) and (X < R.Right) and (Y > R.Top) and (Y < R.Bottom) then begin
    Result := True;
    activeRect := R;
    activeCol := I; activeRow := J;
    exit;
   end;
  end;
end;

procedure TPropInspector.UpdateView(Items: TOIItems; startRow: Integer);
Procedure AddItems(Items: TOIItems);
var I: Integer;
Procedure InsertRow(Item: TOIItem);
begin
 If (startRow = -1) or (startRow = View.RowCount - 1) then begin
 // если первая строка не пустая
  If View.Cells[0, 1] = '' then
   View.InsertRowWithValues(0, [Item.Name, Item.Value]) else
   View.InsertRow(Item.Name, Item.Value, True);
  View.Rows[View.RowCount - 1].Objects[0] := Item;
 end else begin
  View.InsertRowWithValues(startRow, [Item.Name, Item.Value]);
 // увеличиваем счетчик для вставки следующей строки
  View.Rows[startRow].Objects[0] := Item;
  Inc(startRow);
 end;
end;
begin
 For I := 0 to Items.Count - 1 do begin
//  WriteIn(['lvl='+IntToStr(Items[I].Level),Items[I].Space,
//           Items[I].Name,Items[I].Value,Items[I].isSimple,Items[I].isExpanded,Items[I].Items.Count]);
//  If (Items[I].Level = 0) then begin//or (Items[I].isSimple) or (Items[I].isExpanded) then begin
   InsertRow(Items[I]);
   If Items[I].isSimple or Items[I].isExpanded then AddItems(Items[I].Items);
  end;
end;
begin
// Writein(['Cnt=',Items.Count]);
 AddItems(Items);
end;

procedure TPropInspector.UpdateState(Item: TOIItem);
var Index: Integer;
procedure AddItems(Items: TOIItems);
var I:Integer;
procedure InsertRow(Item:TOIItem);
begin
 WriteIn(['Insert=', Item.Name, Item.Value]);
 View.InsertRowWithValues(activeRow + Index, [Item.Name, Item.Value]);
 Inc(Index);
 View.Rows[activeRow + Index].Objects[0] := Item;
end;
begin
 For I := 0 to Items.Count -1 do begin
  WriteIn(['lvl='+IntToStr(Items[I].Level),Items[I].Space,Items[I].Name,Items[I].Value,Items[I].isArray]);
  InsertRow(Items[I]);
  If (Items[I].isSimple) or (Items[I].isExpanded) then
   AddItems(Items[I].Items);
 end;
end;
procedure DeleteItems(Items: TOIItems);
var I, J: Integer;
begin
 For I := View.RowCount - 1 downto 0 do
  If Items.IndexOf(View.Rows[I].Objects[0]) <> -1 then begin
   View.DeleteRow(I);
  end else
  For J := Items.Count - 1 downto 0 do
   DeleteItems(Items[J].Items);
end;
begin
 WriteIn(['StateChanged', Item.State, 'Count=',Item.Items.Count]);
 If Item.State = psCollapsed then begin
  Item.State := psExpanded;
  Index := 0;
 // AddItems(Item.Items);
  View.Clear;
  UpdateView(Items, -1);
  View.Row := activeRow + 1;
  View.Update;
 end else begin
  Item.State := psCollapsed;
  Index := 0;
 // DeleteItems(Item.Items);
  View.Clear;
  UpdateView(Items, -1);
  View.Row := activeRow;
  View.Update;
 end;
end;

end.

