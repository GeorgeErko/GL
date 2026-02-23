{%RunFlags BUILD-}
unit objTool;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, Graphics, LCLType, Controls,
     ogcBasic, ogcMapObject;

type
 // Тип для набора байтов (используется для клавиатуры)
 TSetOfByte = set of Byte;
 TMouseButtons = set of TMouseButton;

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

type
 { TogsTool - базовый класс для всех инструментов работы с мышью и клавиатурой }
 TogsTool = class
 private
  fState: TMouseState;
  fOldState: TMouseState;
  fKeyState: TKeyState;
  fMapObject: TogsMapObject;
  fDrawer: TogsDrawer;
  fActive: Boolean;
  
 protected
  // Состояние мыши/клавиатуры
  property State: TMouseState read fState;
  property OldState: TMouseState read fOldState;
  property KeyState: TKeyState read fKeyState;
  property MapObject: TogsMapObject read fMapObject;
  property Drawer: TogsDrawer read fDrawer;
  property Active: Boolean read fActive;
  
  // Виртуальные методы для перекрытия
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
  procedure MouseMove(Shift: TShiftState; X, Y: Integer); virtual;
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
  procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; X, Y: Integer); virtual;
  procedure DoubleClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
  procedure KeyDown(var Key: Word; Shift: TShiftState); virtual;
  procedure KeyUp(var Key: Word; Shift: TShiftState); virtual;
  procedure KeyPress(var Key: Char); virtual;
  procedure Paint(Drawer: TogsDrawer; const PaintRect: TogsRect); virtual;
  
  // Утилиты (вызываются из наследников)
  procedure UpdateState(X, Y: Integer; Buttons: TMouseButtons; WheelDelta: Integer; Shift: TShiftState);
  procedure UpdateKeyState(Key: Word; Shift: TShiftState; IsDown: Boolean);
  function GetObjectAt(X, Y: Integer): TogsGeometry;
  procedure Invalidate;
  
 public
  constructor Create(MapObject: TogsMapObject); virtual;
  destructor Destroy; override;
  procedure SetDrawingArea(Drawer: TogsDrawer; const PaintRect: TogsRect);
  procedure Reset;
 end;

implementation

{ TogsTool }

constructor TogsTool.Create(MapObject: TogsMapObject);
begin
 inherited Create;
 fActive := False;
 fDrawer := nil;
 fMapObject := MapObject;
 Reset;
end;

destructor TogsTool.Destroy;
begin
 inherited Destroy;
end;

procedure TogsTool.Reset;
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

procedure TogsTool.UpdateState(X, Y: Integer; Buttons: TMouseButtons; WheelDelta: Integer; Shift: TShiftState);
begin
 fOldState := fState;
 fState.X := X;
 fState.Y := Y;
 fState.Buttons := Buttons;
 fState.WheelDelta := WheelDelta;
 fState.Shift := Shift;
end;

procedure TogsTool.UpdateKeyState(Key: Word; Shift: TShiftState; IsDown: Boolean);
begin
 fKeyState.LastKey := Key;
 fKeyState.Shift := Shift;
  
 if IsDown then
  Include(fKeyState.Keys, Key)
 else
  Exclude(fKeyState.Keys, Key);
end;

function TogsTool.GetObjectAt(X, Y: Integer): TogsGeometry;
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

procedure TogsTool.Invalidate;
begin
// Вызываем перерисовку
 Paint(fDrawer, nil);
end;

procedure TogsTool.SetDrawingArea(Drawer: TogsDrawer; const PaintRect: TogsRect);
begin
 fDrawer := Drawer;
 fMapObject.ogsSelector.Assign(PaintRect);
 fActive := Assigned(Drawer);
end;

// Виртуальные методы с базовой реализацией

procedure TogsTool.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

procedure TogsTool.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

procedure TogsTool.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

procedure TogsTool.MouseWheel(Shift: TShiftState; WheelDelta: Integer; X, Y: Integer);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

procedure TogsTool.DoubleClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

procedure TogsTool.KeyDown(var Key: Word; Shift: TShiftState);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

procedure TogsTool.KeyUp(var Key: Word; Shift: TShiftState);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

procedure TogsTool.KeyPress(var Key: Char);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

procedure TogsTool.Paint(Drawer: TogsDrawer; const PaintRect: TogsRect);
begin
// Базовая реализация - можно перекрыть в наследниках
end;

end.
