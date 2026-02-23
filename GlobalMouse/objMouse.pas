{%RunFlags BUILD-}
unit objMouse;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, Graphics, LCLType,
     ogcBasic, ogcMapObject;

type
 { TogsMouse - глобальный менеджер ввода мыши и клавиатуры }
 TogsMouse = class;

 // Тип для набора байтов (используется для клавиатуры)
 TSetOfByte = set of Byte;
  
 // Типы кнопок мыши
 TMouseButton = (mbLeft, mbRight, mbMiddle, mbX1, mbX2);
 TMouseButtons = set of TMouseButton;

 // Типы событий мыши
 TMouseEventType = (meDown, meUp, meMove, meWheel, meDoubleClick);

 // Типизированные процедурные переменные для событий мыши
 TMouseEvent = procedure(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 TMouseMoveEvent = procedure(Sender: TObject; Shift: TShiftState; X, Y: Integer);
 TMouseWheelEvent = procedure(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; X, Y: Integer);
 TPaintEvent = procedure(Sender: TObject; Drawer: TogsDrawer; const PaintRect: TogsRect);

 // Типизированные процедурные переменные для событий клавиатуры
 TKeyEvent = procedure(Sender: TObject; var Key: Word; Shift: TShiftState);
 TKeyPressEvent = procedure(Sender: TObject; var Key: Char);

 { Состояние клавиатуры }
 TKeyState = record
  Keys: TSetOfByte;
  LastKey: Word;
  LastChar: Char;
  Shift: TShiftState;
 end;

 { Состояние мыши }
 TMouseState = record
  X: Integer;
  Y: Integer;
  Buttons: TMouseButtons;
  WheelDelta: Integer;
  Shift: TShiftState;
 end;

  { TogsMouse - глобальный менеджер ввода мыши и клавиатуры }
 TogsMouse = class
 private
  fState: TMouseState;
  fOldState: TMouseState;
  fKeyState: TKeyState;
  fDrawer: TogsDrawer;
  fActive: Boolean;
  fMapObject: TogsMapObject;
  
  procedure UpdateState(X, Y: Integer; Buttons: TMouseButtons; WheelDelta: Integer; Shift: TShiftState);
  procedure UpdateKeyState(Key: Word; Shift: TShiftState; IsDown: Boolean);
  function GetButton(Button: TMouseButton): Boolean;
  function GetLeftButton: Boolean;
  function GetRightButton: Boolean;
  function GetMiddleButton: Boolean;
  function GetKey(Key: Word): Boolean;
  function GetCtrlPressed: Boolean;
  function GetShiftPressed: Boolean;
  function GetAltPressed: Boolean;
  procedure TriggerPaint;
 public
 // События (типизированные процедурные переменные)
  OnMouseDown: TMouseEvent;
  OnMouseUp: TMouseEvent;
  OnMouseMove: TMouseMoveEvent;
  OnMouseWheel: TMouseWheelEvent;
  OnDoubleClick: TMouseEvent;
  OnPaint: TPaintEvent;
    
 // События клавиатуры
  OnKeyDown: TKeyEvent;
  OnKeyUp: TKeyEvent;
  OnKeyPress: TKeyPressEvent;
 //
  constructor Create(MapObject: TogsMapObject = nil);
  destructor Destroy; override;
    
 // Текущее состояние мыши
  property State: TMouseState read fState;
  property X: Integer read fState.X;
  property Y: Integer read fState.Y;
  property Buttons: TMouseButtons read fState.Buttons;
  property WheelDelta: Integer read fState.WheelDelta;
  property Shift: TShiftState read fState.Shift;
    
 // Текущее состояние клавиатуры
  property KeyState: TKeyState read fKeyState;
  property Keys: TSetOfByte read fKeyState.Keys;
  property LastKey: Word read fKeyState.LastKey;
  property LastChar: Char read fKeyState.LastChar;
  property KeyShift: TShiftState read fKeyState.Shift;
    
 // Графический вывод
  property Drawer: TogsDrawer read fDrawer write fDrawer;
  property Active: Boolean read fActive write fActive;
    
 // Работа с объектами карты !!! временно
  property MapObject: TogsMapObject read fMapObject write fMapObject;
    
 // Проверка состояния кнопок мыши
  property LeftButton: Boolean read GetLeftButton;
  property RightButton: Boolean read GetRightButton;
  property MiddleButton: Boolean read GetMiddleButton;
    
 // Проверка состояния клавиш
  property CtrlPressed: Boolean read GetCtrlPressed;
  property ShiftPressed: Boolean read GetShiftPressed;
  property AltPressed: Boolean read GetAltPressed;

 // Методы управления
  procedure SetPosition(X, Y: Integer);
  procedure PressButton(Button: TMouseButton; Shift: TShiftState = []);
  procedure ReleaseButton(Button: TMouseButton; Shift: TShiftState = []);
  procedure Move(X, Y: Integer; Shift: TShiftState = []);
  procedure Scroll(WheelDelta: Integer; X, Y: Integer; Shift: TShiftState = []);
  procedure Reset;
    
 // Перехват сообщений (вызываются из оконных процедур)
  procedure HandleMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure HandleMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure HandleMouseMove(Shift: TShiftState; X, Y: Integer);
  procedure HandleMouseWheel(Shift: TShiftState; WheelDelta: Integer; X, Y: Integer);
  procedure HandleDoubleClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure HandlePaint(Drawer: TogsDrawer; const PaintRect: TogsRect);
    
 // Перехват сообщений клавиатуры
  procedure HandleKeyDown(var Key: Word; Shift: TShiftState);
  procedure HandleKeyUp(var Key: Word; Shift: TShiftState);
  procedure HandleKeyPress(var Key: Char);
    
 // Утилиты
  function IsButtonDown(Button: TMouseButton): Boolean;
  function WasButtonPressed(Button: TMouseButton): Boolean;
  function WasButtonReleased(Button: TMouseButton): Boolean;
  function GetDistance: Integer;
  function GetDeltaX: Integer;
  function GetDeltaY: Integer;
    
 // Утилиты клавиатуры
  function IsKeyDown(Key: Word): Boolean;
  function WasKeyPressed(Key: Word): Boolean;
  function WasKeyReleased(Key: Word): Boolean;
  procedure ClearKeys;
    
 // Работа с областью рисования
  procedure SetDrawingArea(Drawer: TogsDrawer; const PaintRect: TogsRect);
  procedure Invalidate;
  function PointInArea(X, Y: Integer): Boolean;
    
 // Работа с объектами TogsBasic
  function GetObjectAt(X, Y: Integer): TogsGeometry;
  function SelectObjectAt(X, Y: Integer): Boolean;
  procedure ClearSelection;
  procedure SelectObjectsInRect(const Rect: TogsRect);
  procedure MoveSelectedObjects(DX, DY: Integer);
 end;

var
// Глобальный объект мыши
 Mouse: TogsMouse;

implementation

{ TogsMouse }

constructor TogsMouse.Create(MapObject: TogsMapObject);
begin
 inherited Create;
 fActive := False;
 fDrawer := nil;
 fMapObject := MapObject;
 Reset;
end;

destructor TogsMouse.Destroy;
begin
 inherited Destroy;
end;

procedure TogsMouse.Reset;
begin
// Сброс состояния мыши
 fState.X := 0;
 fState.Y := 0;
 fState.Buttons := [];
 fState.WheelDelta := 0;
 fState.Shift := [];
 fOldState := fState;
  
// Сброс состояния клавиатуры
 fKeyState.Keys := [];
 fKeyState.LastKey := 0;
 fKeyState.LastChar := #0;
 fKeyState.Shift := [];
end;

procedure TogsMouse.UpdateState(X, Y: Integer; Buttons: TMouseButtons; WheelDelta: Integer; Shift: TShiftState);
begin
 fOldState := fState;
 fState.X := X;
 fState.Y := Y;
 fState.Buttons := Buttons;
 fState.WheelDelta := WheelDelta;
 fState.Shift := Shift;
end;

function TogsMouse.GetButton(Button: TMouseButton): Boolean;
begin
 case Button of
  mbLeft: Result := mbLeft in fState.Buttons;
  mbRight: Result := mbRight in fState.Buttons;
  mbMiddle: Result := mbMiddle in fState.Buttons;
  mbX1: Result := mbX1 in fState.Buttons;
  mbX2: Result := mbX2 in fState.Buttons;
 else
  Result := False;
 end;
end;

function TogsMouse.GetLeftButton: Boolean;
begin
 Result := mbLeft in fState.Buttons;
end;

function TogsMouse.GetRightButton: Boolean;
begin
 Result := mbRight in fState.Buttons;
end;

function TogsMouse.GetMiddleButton: Boolean;
begin
 Result := mbMiddle in fState.Buttons;
end;

// Методы для работы с клавиатурой

procedure TogsMouse.UpdateKeyState(Key: Word; Shift: TShiftState; IsDown: Boolean);
begin
 fKeyState.LastKey := Key;
 fKeyState.Shift := Shift;
  
 if IsDown then
  Include(fKeyState.Keys, Key)
 else
  Exclude(fKeyState.Keys, Key);
end;

function TogsMouse.GetKey(Key: Word): Boolean;
begin
 Result := Key in fKeyState.Keys;
end;

function TogsMouse.GetCtrlPressed: Boolean;
begin
 Result := (ssCtrl in fKeyState.Shift) or (VK_CONTROL in fKeyState.Keys);
end;

function TogsMouse.GetShiftPressed: Boolean;
begin
 Result := (ssShift in fKeyState.Shift) or (VK_SHIFT in fKeyState.Keys);
end;

function TogsMouse.GetAltPressed: Boolean;
begin
 Result := (ssAlt in fKeyState.Shift) or (VK_MENU in fKeyState.Keys);
end;

procedure TogsMouse.SetPosition(X, Y: Integer);
begin
 UpdateState(X, Y, fState.Buttons, fState.WheelDelta, fState.Shift);
end;

procedure TogsMouse.PressButton(Button: TMouseButton; Shift: TShiftState);
var
 NewButtons: TMouseButtons;
begin
 NewButtons := fState.Buttons + [Button];
 UpdateState(fState.X, fState.Y, NewButtons, fState.WheelDelta, Shift);
  
 OnMouseDown(Self, Button, Shift, fState.X, fState.Y);
end;

procedure TogsMouse.ReleaseButton(Button: TMouseButton; Shift: TShiftState);
var
 NewButtons: TMouseButtons;
begin
 NewButtons := fState.Buttons - [Button];
 UpdateState(fState.X, fState.Y, NewButtons, fState.WheelDelta, Shift);
  
 OnMouseUp(Self, Button, Shift, fState.X, fState.Y);
end;

procedure TogsMouse.Move(X, Y: Integer; Shift: TShiftState);
begin
 UpdateState(X, Y, fState.Buttons, fState.WheelDelta, Shift);
  
 OnMouseMove(Self, Shift, X, Y);
end;

procedure TogsMouse.Scroll(WheelDelta: Integer; X, Y: Integer; Shift: TShiftState);
begin
 UpdateState(X, Y, fState.Buttons, WheelDelta, Shift);
  
 OnMouseWheel(Self, Shift, WheelDelta, X, Y);
end;

procedure TogsMouse.HandleMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if not fActive then Exit;
 if not PointInArea(X, Y) then Exit;
  
 PressButton(Button, Shift);
 Invalidate; // Перерисовать после события мыши
end;

procedure TogsMouse.HandleMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if not fActive then Exit;
 if not PointInArea(X, Y) then Exit;
  
 ReleaseButton(Button, Shift);
 Invalidate; // Перерисовать после события мыши
end;

procedure TogsMouse.HandleMouseMove(Shift: TShiftState; X, Y: Integer);
begin
 if not fActive then Exit;
 if not PointInArea(X, Y) then Exit;
  
 Move(X, Y, Shift);
 Invalidate; // Перерисовать при перемещении
end;

procedure TogsMouse.HandleMouseWheel(Shift: TShiftState; WheelDelta: Integer; X, Y: Integer);
begin
 if not fActive then Exit;
 if not PointInArea(X, Y) then Exit;
  
 Scroll(WheelDelta, X, Y, Shift);
 Invalidate; // Перерисовать после прокрутки
end;

procedure TogsMouse.HandleDoubleClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if not fActive then Exit;
 if not PointInArea(X, Y) then Exit;
  
 OnDoubleClick(Self, Button, Shift, X, Y);
 Invalidate; // Перерисовать после двойного клика
end;

procedure TogsMouse.HandlePaint(Drawer: TogsDrawer; const PaintRect: TogsRect);
begin
 if not fActive then Exit;
  
// Обновляем текущий Drawer
 fDrawer := Drawer;
  
// Обновляем область в ogsSelector
 fMapObject.ogsSelector.Assign(PaintRect);
  
// Вызываем обработчик OnPaint
 OnPaint(Self, Drawer, PaintRect);
end;

procedure TogsMouse.HandleKeyDown(var Key: Word; Shift: TShiftState);
begin
 if not fActive then Exit;
  
 UpdateKeyState(Key, Shift, True);
  
 OnKeyDown(Self, Key, Shift);
 Invalidate; // Перерисовать после нажатия клавиши
end;

procedure TogsMouse.HandleKeyUp(var Key: Word; Shift: TShiftState);
begin
 if not fActive then Exit;
  
 UpdateKeyState(Key, Shift, False);
  
 OnKeyUp(Self, Key, Shift);
 Invalidate; // Перерисовать после отпускания клавиши
end;

procedure TogsMouse.HandleKeyPress(var Key: Char);
begin
 if not fActive then Exit;
  
 fKeyState.LastChar := Key;
  
 OnKeyPress(Self, Key);
 Invalidate; // Перерисовать после ввода символа
end;

procedure TogsMouse.TriggerPaint;
var
 PaintRect: TogsRect;
begin
 if Assigned(fDrawer) and Assigned(OnPaint) then
 begin
  // PaintRect := fMapObject.ogsSelector;
  // OnPaint(Self, fDrawer, PaintRect);
 end;
end;

procedure TogsMouse.SetDrawingArea(Drawer: TogsDrawer; const PaintRect: TogsRect);
begin
 fDrawer := Drawer;
 fMapObject.ogsSelector.Assign(PaintRect);
 fActive := Assigned(Drawer);
end;

procedure TogsMouse.Invalidate;
begin
// Вызываем перерисовку через OnPaint
 TriggerPaint;
end;

function TogsMouse.PointInArea(X, Y: Integer): Boolean;
begin
 //Result := fMapObject.ogsSelector.PointIn(X, Y);
end;

function TogsMouse.IsButtonDown(Button: TMouseButton): Boolean;
begin
 Result := Button in fState.Buttons;
end;

function TogsMouse.WasButtonPressed(Button: TMouseButton): Boolean;
begin
 Result := (Button in fState.Buttons) and not (Button in fOldState.Buttons);
end;

function TogsMouse.WasButtonReleased(Button: TMouseButton): Boolean;
begin
 Result := not (Button in fState.Buttons) and (Button in fOldState.Buttons);
end;

function TogsMouse.GetDistance: Integer;
var
 dx, dy: Integer;
begin
 dx := fState.X - fOldState.X;
 dy := fState.Y - fOldState.Y;
 Result := Round(Sqrt(dx * dx + dy * dy));
end;

function TogsMouse.GetDeltaX: Integer;
begin
 Result := fState.X - fOldState.X;
end;

function TogsMouse.GetDeltaY: Integer;
begin
 Result := fState.Y - fOldState.Y;
end;

// Утилиты клавиатуры

function TogsMouse.IsKeyDown(Key: Word): Boolean;
begin
 Result := Key in fKeyState.Keys;
end;

function TogsMouse.WasKeyPressed(Key: Word): Boolean;
begin
 Result := (Key in fKeyState.Keys) and (Key = fKeyState.LastKey);
end;

function TogsMouse.WasKeyReleased(Key: Word): Boolean;
begin
 Result := not (Key in fKeyState.Keys) and (Key = fKeyState.LastKey);
end;

procedure TogsMouse.ClearKeys;
begin
 fKeyState.Keys := [];
 fKeyState.LastKey := 0;
 fKeyState.LastChar := #0;
 fKeyState.Shift := [];
end;

// Работа с объектами TogsBasic

function TogsMouse.GetObjectAt(X, Y: Integer): TogsGeometry;
var
 CaptureRec: TCaptureRec;
 i: Integer;
 Geom: TogsGeometry;
begin
 Result := nil;
  
// Ищем объект через перебор всех примитивов в карте
 for i := 0 to fMapObject.Count - 1 do begin
   Geom := fMapObject[i];
   CaptureRec := Default(TCaptureRec);
   if Geom.SelectByPoint(X, Y, CaptureRec) then begin
     Result := Geom;
     Break;
   end;
 end;
end;

function TogsMouse.SelectObjectAt(X, Y: Integer): Boolean;
var
 Obj: TogsGeometry;
begin
 Result := False;
 Obj := GetObjectAt(X, Y);
 Obj.Selected := True;
 Result := True;
end;

procedure TogsMouse.ClearSelection;
var
 i: Integer;
 Geom: TogsGeometry;
begin
// Очищаем выделение у всех объектов
 for i := 0 to fMapObject.Count - 1 do begin
   Geom := fMapObject[i];
   Geom.Selected := False;
 end;
end;

procedure TogsMouse.SelectObjectsInRect(const Rect: TogsRect);
var
 i: Integer;
 Geom: TogsGeometry;
begin
// Выделяем объекты, пересекающиеся с прямоугольником
 for i := 0 to fMapObject.Count - 1 do begin
   Geom := fMapObject[i];
   if Geom.ogsRect.VisibleIn(Rect) then
    Geom.Selected := True;
 end;
end;

procedure TogsMouse.MoveSelectedObjects(DX, DY: Integer);
var
 i: Integer;
 Geom: TogsGeometry;
begin
// Перемещаем только выделенные объекты
 for i := 0 to fMapObject.Count - 1 do begin
   Geom := fMapObject[i];
   if Geom.Selected then begin
    // Geom.Move(DX, DY);
   end;
 end;
end;

initialization
 Mouse := TogsMouse.Create;
//
finalization
 Mouse.Free;
end.
