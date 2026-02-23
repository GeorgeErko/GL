unit TestRootForm;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Math,
  RootGrapherForm, objMouse, ogcBasic, ogcMapObject, ogcDrawer32;

type
  // Пример формы, наследующей TRootGrapherForm
  TTestRootForm = class(TRootGrapherForm)
  private
    FTestMap: TogsMapObject;
    FTestDrawer: TogsDrawer32;
    
    procedure SetupTestObjects;
    
  protected
    // Переопределяем виртуальные методы для демонстрации
    procedure DoCustomPaint(Drawer: TogsDrawer; const PaintRect: TogsRect); override;
    procedure DoCustomMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoCustomMouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure DoCustomKeyPress(var Key: Char); override;
    
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  TestRootForm: TTestRootForm;

implementation

{ TTestRootForm }

constructor TTestRootForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  // Создаем тестовые объекты
  FTestDrawer := TogsDrawer32.Create;
  FTestMap := TogsMapObject.Create(FTestDrawer);
  
  // Настраиваем систему ввода
  SetupTestObjects;
  SetupInputSystem(Mouse, FTestDrawer, ogcRect(0, 0, ClientWidth, ClientHeight));
  
  // Настраиваем обработчики мыши
  Mouse.OnMouseDown := @TestMouseDownHandler;
  Mouse.OnMouseMove := @TestMouseMoveHandler;
  Mouse.OnKeyPress := @TestKeyPressHandler;
  Mouse.OnPaint := @TestPaintHandler;
end;

destructor TTestRootForm.Destroy;
begin
  Mouse.OnMouseDown := nil;
  Mouse.OnMouseMove := nil;
  Mouse.OnKeyPress := nil;
  Mouse.OnPaint := nil;
  
  FreeAndNil(FTestMap);
  FreeAndNil(FTestDrawer);
  inherited Destroy;
end;

procedure TTestRootForm.SetupTestObjects;
begin
  // Здесь можно создать тестовые объекты на карте
  // Например: точки, линии, полигоны и т.д.
  
  Caption := 'Test Root Grapher Form - Mouse: ' + 
    IfThen(Assigned(Mouse), 'Connected', 'Disconnected');
end;

procedure TTestRootForm.DoCustomPaint(Drawer: TogsDrawer; const PaintRect: TogsRect);
begin
  inherited DoCustomPaint(Drawer, PaintRect);
  
  // Рисуем тестовую информацию
  if Assigned(Drawer) then
  begin
    // Рисуем координаты мыши
    Drawer.DrawText(Format('Mouse: (%d, %d)', [Mouse.X, Mouse.Y]), 10, 10);
    
    // Рисуем состояние кнопок
    if Mouse.LeftButton then
      Drawer.DrawText('Left Button: PRESSED', 10, 30);
    
    if Mouse.CtrlPressed then
      Drawer.DrawText('CTRL: PRESSED', 10, 50);
    
    // Рисуем последний символ
    if Mouse.LastChar <> #0 then
      Drawer.DrawText(Format('Last Key: %s', [Mouse.LastChar]), 10, 70);
  end;
end;

procedure TTestRootForm.DoCustomMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited DoCustomMouseDown(Button, Shift, X, Y);
  
  // Пытаемся выбрать объект под курсором
  if Button = mbLeft then
  begin
    if Mouse.SelectObjectAt(X, Y) then
      Caption := 'Object selected at (' + IntToStr(X) + ', ' + IntToStr(Y) + ')'
    else
      Caption := 'No object at (' + IntToStr(X) + ', ' + IntToStr(Y) + ')';
  end;
end;

procedure TTestRootForm.DoCustomMouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited DoCustomMouseMove(Shift, X, Y);
  
  // Перемещаем выделенные объекты
  if Mouse.LeftButton and (Mouse.GetDeltaX <> 0) or (Mouse.GetDeltaY <> 0) then
  begin
    Mouse.MoveSelectedObjects(Mouse.GetDeltaX, Mouse.GetDeltaY);
    Caption := Format('Moving selected objects: dx=%d, dy=%d', [Mouse.GetDeltaX, Mouse.GetDeltaY]);
  end;
end;

procedure TTestRootForm.DoCustomKeyPress(var Key: Char);
begin
  inherited DoCustomKeyPress(Key);
  
  case Key of
    'c', 'C': 
      begin
        Mouse.ClearSelection;
        Caption := 'Selection cleared';
      end;
    'r', 'R':
      begin
        Invalidate;
        Caption := 'Refresh';
      end;
    #27: // ESC
      begin
        Mouse.ClearSelection;
        Caption := 'ESC - Selection cleared';
      end;
  end;
end;

// Обработчики событий TogsMouse
procedure TTestRootForm.TestMouseDownHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Дополнительная обработка через TogsMouse
  if Button = mbRight then
  begin
    // Правый клик - показываем контекстное меню или что-то еще
    ShowMessage(Format('Right click at (%d, %d)', [X, Y]));
  end;
end;

procedure TTestRootForm.TestMouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  // Можно добавить дополнительную логику для перемещения мыши
end;

procedure TTestRootForm.TestKeyPressHandler(Sender: TObject; var Key: Char);
begin
  // Дополнительная обработка клавиатуры
  case Key of
    '+':
      Caption := 'Zoom in';
    '-':
      Caption := 'Zoom out';
  end;
end;

procedure TTestRootForm.TestPaintHandler(Sender: TObject; Drawer: TogsDrawer; const PaintRect: TogsRect);
begin
  // Дополнительная отрисовка через TogsMouse
  if Assigned(Drawer) then
  begin
    // Рисуем курсор в виде крестика
    Drawer.DrawLine(Mouse.X - 5, Mouse.Y, Mouse.X + 5, Mouse.Y);
    Drawer.DrawLine(Mouse.X, Mouse.Y - 5, Mouse.X, Mouse.Y + 5);
  end;
end;

end.
