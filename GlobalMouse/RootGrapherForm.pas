unit RootGrapherForm;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
 LCLType, LMessages, LCLIntf,
 ogcBasic, ogcMapObject, objTool;

type
 // Базовая форма для всех графических форм Grapher
 // Перехватывает события мыши и клавиатуры
 TRootGrapherForm = class(TForm)
 private
  FTool: TogsTool;
  procedure SetTool(AValue: TogsTool);
 protected
  procedure PaintWindow(DC: HDC); override;
  procedure Resize; override;
 public
  constructor Create(AOwner: TComponent); override;
  destructor Destroy; override;
  // Основное свойство - текущий инструмент
  property Tool: TogsTool read FTool write SetTool;
 end;

implementation

{$R *.frm}

{ TRootGrapherForm }

constructor TRootGrapherForm.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 FTool := nil;
end;

destructor TRootGrapherForm.Destroy;
begin
 FTool := nil;
 inherited Destroy;
end;

procedure TRootGrapherForm.SetTool(AValue: TogsTool);
begin
 if FTool = AValue then Exit;
 FTool := AValue;
end;

procedure TRootGrapherForm.PaintWindow(DC: HDC);
begin
 inherited PaintWindow(DC);
end;

procedure TRootGrapherForm.Resize;
begin
 inherited Resize;
end;

// События формы для мыши и клавиатуры

procedure TRootGrapherForm.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 inherited MouseDown(Button, Shift, X, Y);
 FTool.MouseDown(Button, Shift, X, Y);
end;

procedure TRootGrapherForm.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 inherited MouseUp(Button, Shift, X, Y);
 FTool.MouseUp(Button, Shift, X, Y);
end;

procedure TRootGrapherForm.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
 inherited MouseMove(Shift, X, Y);
 FTool.MouseMove(Shift, X, Y);
end;

procedure TRootGrapherForm.MouseWheel(Shift: TShiftState; WheelDelta: Integer; X, Y: Integer);
begin
 inherited MouseWheel(Shift, WheelDelta, X, Y);
 FTool.MouseWheel(Shift, WheelDelta, X, Y);
end;

procedure TRootGrapherForm.DblClick;
begin
 inherited DblClick;
 FTool.DoubleClick(mbLeft, [], Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TRootGrapherForm.KeyPress(var Key: Char);
begin
 inherited KeyPress(Key);
 FTool.KeyPress(Key);
end;

procedure TRootGrapherForm.KeyDown(var Key: Word; Shift: TShiftState);
begin
 inherited KeyDown(Key, Shift);
 FTool.KeyDown(Key, Shift);
end;

procedure TRootGrapherForm.KeyUp(var Key: Word; Shift: TShiftState);
begin
 inherited KeyUp(Key, Shift);
 FTool.KeyUp(Key, Shift);
end;

end.
