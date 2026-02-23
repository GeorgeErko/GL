unit MonitorGUI;

{$H+}
{$WARNINGS OFF}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, Menus, MonitorDatabase, fpjson, jsonparser, ogcProperties,
  VirtualTrees, ImgList, ValEdit, Types, ogcInspector, TAGraph, TASeries,
  TAChartUtils, TAChartAxis;

type

 { TMonitorForm }
  
  TMonitorForm = class(TForm)
   ProgressChart: TChart;
   ImageList1: TImageList;
   ImgList: TImageList;
    MainMenu1: TMainMenu;
    FileMenu: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    NewThemeMenu: TMenuItem;
    NewTaskMenu: TMenuItem;
    NewSubTaskMenu: TMenuItem;
    PC: TPageControl;
    SaveMenu: TMenuItem;
    LoadMenu: TMenuItem;
    BackupMenu: TMenuItem;
    ExitMenu: TMenuItem;
    EditMenu: TMenuItem;
    DeleteMenu: TMenuItem;
    Splitter1: TSplitter;
    TS1: TTabSheet;
    TS2: TTabSheet;
    VLE: TValueListEditor;
    ViewMenu: TMenuItem;
    RefreshMenu: TMenuItem;
    ExpandAllMenu: TMenuItem;
    CollapseAllMenu: TMenuItem;
    FilterMenu: TMenuItem;
    ToolsMenu: TMenuItem;
    GitHubValidateMenu: TMenuItem;
    ProgressUpdateMenu: TMenuItem;
    ActivityLogMenu: TMenuItem;
    ReportsMenu: TMenuItem;
    HelpMenu: TMenuItem;
    AboutMenu: TMenuItem;

    DetailsPanel: TPanel;
    DetailsMemo: TMemo;
    ButtonPanel: TPanel;
    AddButton: TButton;
    EditButton: TButton;
    DeleteButton: TButton;
    ProgressButton: TButton;
    GitHubButton: TButton;
    ActivityButton: TButton;
    StatusPanel: TPanel;
    StatusLabel2: TLabel;
    FilterPanel: TPanel;
    FilterCombo: TComboBox;
    FilterEdit: TEdit;
    FilterClearButton: TButton;
    MonitorTreeView: TVirtualStringTree;
    
    procedure AddButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure EditButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MonitorTreeViewAfterCellPaint(Sender: TBaseVirtualTree;
     TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
     const CellRect: TRect);
    procedure MonitorTreeViewAfterItemPaint(Sender: TBaseVirtualTree;
     TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect);
    procedure MonitorTreeViewBeforeItemPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  const CellRect: TRect; var PaintInfo: TVTPaintInfo);
    procedure MonitorTreeViewAdvancedHeaderDraw(Sender: TVTHeader;
     var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements);
    procedure MonitorTreeViewBeforeItemPaint(Sender: TBaseVirtualTree;
     TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect;
     var CustomDraw: boolean);
    procedure MonitorTreeViewBeforePaint(Sender: TBaseVirtualTree;
     TargetCanvas: TCanvas);
    procedure MonitorTreeViewChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure MonitorTreeViewCollapsed(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure MonitorTreeViewCollapsing(Sender: TBaseVirtualTree; Node: PVirtualNode;
     var AllowCollapse: Boolean);
    procedure MonitorTreeViewColumnResize(Sender: TVTHeader;
     Column: TColumnIndex);
    procedure MonitorTreeViewEditing(Sender: TBaseVirtualTree; Node: PVirtualNode;
     Column: TColumnIndex; var AllowEdit: Boolean);
    procedure MonitorTreeViewExpanded(Sender: TBaseVirtualTree;
     Node: PVirtualNode);
    procedure MonitorTreeViewExpanding(Sender: TBaseVirtualTree; Node: PVirtualNode;
     var AllowExpansion: Boolean);
    procedure MonitorTreeViewGetImageIndex(Sender: TBaseVirtualTree;
     Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
     var Ghosted: boolean; var ImageIndex: integer);
    procedure MonitorTreeViewGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
     Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure MonitorTreeViewGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
     Kind: TVTImageKind; Column: TColumnIndex; var ImageIndex: Integer;
     var ImageList: TCustomImageList);
    procedure ProgressButtonClick(Sender: TObject);
    procedure GitHubButtonClick(Sender: TObject);
    procedure ActivityButtonClick(Sender: TObject);
    procedure FilterComboChange(Sender: TObject);
    procedure FilterEditChange(Sender: TObject);
    procedure FilterClearButtonClick(Sender: TObject);
    procedure NewThemeMenuClick(Sender: TObject);
    procedure NewTaskMenuClick(Sender: TObject);
    procedure NewSubTaskMenuClick(Sender: TObject);
    procedure SaveMenuClick(Sender: TObject);
    procedure LoadMenuClick(Sender: TObject);
    procedure BackupMenuClick(Sender: TObject);
    procedure DeleteMenuClick(Sender: TObject);
    procedure RefreshMenuClick(Sender: TObject);
    procedure ExpandAllMenuClick(Sender: TObject);
    procedure CollapseAllMenuClick(Sender: TObject);
    procedure GitHubValidateMenuClick(Sender: TObject);
    procedure ActivityLogMenuClick(Sender: TObject);
    procedure AboutMenuClick(Sender: TObject);
    procedure ExitMenuClick(Sender: TObject);
    procedure Splitter1CanOffset(Sender: TObject; var NewOffset: Integer;
     var Accept: Boolean);
    procedure Splitter1ChangeBounds(Sender: TObject);
    
  private
    fDatabase: TMonitorDatabase;
    fProject: TogsPropObject;
    fCurrentNode: TogsPropValue;
    fCurrentNodeID: string;
    fCurrentFileName: string;
    
    function CalculateProgress(ArrayObj: TogsPropArray): Double;
    procedure CreateDefaultDatabaseFile;
    function GetNodeData(Tree: TBaseVirtualTree; Node: PVirtualNode): TogsPropObject;
    procedure LoadProject;
    procedure SaveProject;
    procedure RefreshTreeView;
    procedure UpdateDetails;
    procedure UpdateParentProgress(Node: PVirtualNode);
    procedure UpdateStatusBar;
    procedure SaveAsMenuClick(Sender: TObject);
   // Методы редактирования узлов
    procedure AddNewTheme;
    procedure AddNewTask(ParentNode: PVirtualNode);
    procedure AddNewSubTask(ParentNode: PVirtualNode);
    procedure DeleteSelectedNode;
    procedure SetNodeProgress(Node: PVirtualNode; Progress: Double);
    procedure UpdateNodeTitle(Node: PVirtualNode; NewTitle: string);
    procedure UpdateProgressChart;  // ← Обновление графика прогресса
  public
    Inspector: TPropInspector;
  end;

var
  MonitorForm: TMonitorForm;

// Функция сравнения для сортировки тем по startproc
function CompareThemesByStartProc(Item1, Item2: Pointer): Integer;

implementation uses ogcWriter;

{$R *.frm}

// Функция сравнения для сортировки тем по startproc
function CompareThemesByStartProc(Item1, Item2: Pointer): Integer;
var
  Theme1, Theme2: TogsPropObject;
  Start1, Start2: TDateTime;
begin
  Theme1 := TogsPropObject(Item1);
  Theme2 := TogsPropObject(Item2);
  
  if AssignedProps(Theme1.ItemByName['startproc']) then
    Start1 := StrToDateTimeDef(Theme1.ItemByName['startproc'].AsString, Now)
  else
    Start1 := Now;
    
  if AssignedProps(Theme2.ItemByName['startproc']) then
    Start2 := StrToDateTimeDef(Theme2.ItemByName['startproc'].AsString, Now)
  else
    Start2 := Now;
  
  if Start1 < Start2 then
    Result := -1
  else if Start1 > Start2 then
    Result := 1
  else
    Result := 0;
end;

{ TMonitorForm }

procedure TMonitorForm.UpdateProgressChart;
var
  ThemesList: TList;
  Node: PVirtualNode;
  NodeObj: TogsPropObject;
  i: Integer;
  StartDateTime: TDateTime;
  Progress: Double;
  BarSeries: TBarSeries;
begin
  if not Assigned(ProgressChart) then Exit;
  
  // Очищаем график
  ProgressChart.ClearSeries;
  
  // Создаем список тем
  ThemesList := TList.Create;
  try
    // Собираем все темы (Level = 1)
    Node := MonitorTreeView.GetFirst;
    while Assigned(Node) do begin
      NodeObj := GetNodeData(MonitorTreeView, Node);
      if Assigned(NodeObj) and (NodeObj.Level = 1) then
        ThemesList.Add(NodeObj);
      Node := MonitorTreeView.GetNext(Node);
    end;
    
    // Сортируем по startproc
    ThemesList.Sort(@CompareThemesByStartProc);
    
    // Создаем серию для графика
    BarSeries := TBarSeries.Create(ProgressChart);
    BarSeries.Title := 'Прогресс тем';
    
    // Настройка отображения названий тем
    BarSeries.Marks.Visible := True;           // ← Включаем метки
    BarSeries.Marks.Style := smsLabelPercent;  // ← Показываем проценты
   // BarSeries.Marks.Format := '%s: %.0f%%';  // ← Формат: Тема: Процент%
    
    ProgressChart.AddSeries(BarSeries);
    
    // Добавляем данные на график
    for i := 0 to ThemesList.Count - 1 do begin
      NodeObj := TogsPropObject(ThemesList[i]);
      
      // Получаем startproc
      if AssignedProps(NodeObj.ItemByName['startproc']) then
        StartDateTime := StrToDateTimeDef(NodeObj.ItemByName['startproc'].AsString, Now)
      else
        StartDateTime := Now;
      
      // Получаем прогресс
      if AssignedProps(NodeObj.ItemByName['progress']) then
        Progress := NodeObj.ItemByName['progress'].AsFloat * 100
      else
        Progress := 0;
      
      // Добавляем точку на график с названием темы
      BarSeries.AddXY(i, Progress, NodeObj.ItemByName['title'].AsString);
    end;
    
    // Настройка осей для лучшего отображения
    try
     // ProgressChart.BottomAxis.LabelFont.Orientation := 450;  // ← Поворот меток (45° = 450 десятых)
    except
      // Альтернативный вариант если Angle не поддерживается
     // ProgressChart.BottomAxis.LabelRotation := 45;  // ← Поворот меток
    end;
    ProgressChart.LeftAxis.Title.Caption := 'Прогресс, %';  // ← Заголовок оси Y
    ProgressChart.BottomAxis.Title.Caption := 'Темы проекта';  // ← Заголовок оси X
   // ProgressChart.Title.Text.Caption := 'Прогресс выполнения тем';  // ← Заголовок графика
    
  finally
    ThemesList.Free;
  end;
end;

procedure TMonitorForm.CreateDefaultDatabaseFile;
begin
  // Используем метод базы данных для создания иерархической структуры
  fDatabase.CreateDefaultHierarchicalStructure;
  WriteLn('Default hierarchical JSON file created successfully');
end;

procedure TMonitorForm.FormCreate(Sender: TObject);
begin
  Caption := 'Global Monitor - Work Complex Management';

  // Создаем базу данных через адаптер
  fDatabase := TMonitorDatabase.Create('');
  fProject := fDatabase.Project;
  fCurrentNode := nil;
  fCurrentNodeID := '';
  fCurrentFileName := 'default.json';
  
  // Настройка VirtualStringTree для двухстрочного отображения
  MonitorTreeView.TreeOptions.AutoOptions := [
    toAutoExpand]; // Авто-развертывание
   MonitorTreeView.TreeOptions.PaintOptions := [toShowButtons,          // Кнопки +/-
    toShowRoot,             // Корневой узел
    toShowTreeLines       // Линии дерева
   // toAlwaysShowSelection   // Всегда показывать выделение
  ];
  
  // Настраиваем высоту узлов для двух строк
  MonitorTreeView.DefaultNodeHeight := MonitorTreeView.DefaultNodeHeight * 2;  // Увеличиваем в 2 раза
  MonitorTreeView.Header.AutoSizeIndex := 0;
  MonitorTreeView.Header.MainColumn := 0;

  // Назначаем обработчики событий
 // MonitorTreeView.OnMouseDown := @MonitorTreeViewMouseDown;
 // MonitorTreeView.OnBeforeItemPaint := @MonitorTreeViewBeforeItemPaint;
 // Создаем файл по умолчанию, если он не существует
  if not FileExists('default.json') then begin
   // CreateDefaultDatabaseFile;
   // SaveProject;
  end;

  RefreshTreeView;
  UpdateStatusBar;
  
  MonitorTreeView.FullExpand;
//
  Inspector := TPropInspector.Create(VLE, nil, ImgList);
end;

procedure TMonitorForm.FormDestroy(Sender: TObject);
begin
  fDatabase.Free;  // ← Адаптер сам сохранит данные при уничтожении
  Inspector.Free;
end;

procedure TMonitorForm.MonitorTreeViewAfterCellPaint(Sender: TBaseVirtualTree;
 TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
 const CellRect: TRect);
begin
//  WriteIn(['CELLRect=', CellRect.Left, CellRect.Top, CellRect.Right, CellRect.Bottom]);
end;

procedure TMonitorForm.MonitorTreeViewAfterItemPaint(Sender: TBaseVirtualTree;
 TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect);
var PI: TVTPaintInfo;
begin
 // WriteIn(['ItemRect=', ItemRect.Left, ItemRect.Top, ItemRect.Right, ItemRect.Bottom]);
  MonitorTreeViewBeforeItemPaint(Sender, TargetCanvas, Node, 0, ItemRect, PI);
end;

procedure TMonitorForm.MonitorTreeViewBeforeItemPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  const CellRect: TRect; var PaintInfo: TVTPaintInfo);
var
  DefHeight: Integer; // Базовая высота строки для расчетов
  NodeObj: TogsPropObject;
  Title: string;
  Progress: Double;
  ProgressText: string;
  ProgressRect: TRect;
  TextRect: TRect;
  ProgressWidth: Integer;
  Indent: Integer;
  IconRect: TRect;
  ImageIndex: Integer;
  IsSelected: Boolean;
  SelectionRect: TRect;
begin
  DefHeight := MonitorTreeView.DefaultNodeHeight div 2;
  NodeObj := GetNodeData(MonitorTreeView, Node);
  if not Assigned(NodeObj) then Exit;
  
  // Проверяем, выбран ли узел
  IsSelected := (Node = MonitorTreeView.FocusedNode) or (vsSelected in Node^.States);
  
  // Рассчитываем отступ для иерархии
  Indent := (NodeObj.Level - 1) * DefHeight + Round(DefHeight * 1.3);  // Используем константу DefHeight
  if Indent < 0 then Indent := 0;
  
  // Рисуем фон выделения если узел выбран
  SelectionRect := CellRect;
  SelectionRect.Left := CellRect.Left + Indent;  // Начинаем выделение с учетом отступа
  if IsSelected then begin
    // Рассчитываем прямоугольник выделения с учетом отступов
    TargetCanvas.Brush.Color := MonitorTreeView.Colors.FocusedSelectionColor;  // Системный цвет выделения
    TargetCanvas.FillRect(SelectionRect);
  end else begin
    TargetCanvas.Brush.Color := MonitorTreeView.Colors.UnfocusedColor;  // Системный фон
    TargetCanvas.FillRect(SelectionRect);
  end;
  
  // Получаем заголовок
  if AssignedProps(NodeObj.ItemByName['title']) then
    Title := NodeObj.ItemByName['title'].AsString
  else
    Title := 'Untitled';

  WriteIn(['=============Title=', Title, NodeObj.Level, isSelected]);
  With PaintInfo.ContentRect do
  WriteIn(['==CellRect=', Left, Top, Right, Bottom]);

  // Получаем прогресс
  if AssignedProps(NodeObj.ItemByName['progress']) then begin
    Progress := NodeObj.ItemByName['progress'].AsFloat;
    ProgressText := Format('%.0f%%', [Progress * 100]);
  end else begin
    Progress := 0;
    ProgressText := '0%';
  end;
  
  WriteIn(['==2']);
  // Рисуем иконку по уровню NodeObj.Level
  if Assigned(ImageList1) and (ImageList1.Count > 0) then begin
    IconRect := CellRect;
    IconRect.Left := CellRect.Left + Indent + 2;
    IconRect.Top := CellRect.Top + (CellRect.Height - 16) div 2;  // Центрируем по вертикали
    IconRect.Right := IconRect.Left + 16;
    IconRect.Bottom := IconRect.Top + 16;
    
    // Выбираем иконку по уровню
    case NodeObj.Level of
      1: ImageIndex := 0;  // Иконка темы
      2: ImageIndex := 1;  // Иконка задачи
      3: ImageIndex := 2;  // Иконка подзадачи
    else
      ImageIndex := 0;  // По умолчанию
    end;
    
    // Рисуем иконку
    ImageList1.Draw(TargetCanvas, IconRect.Left, IconRect.Top, ImageIndex);
    
    // Смещаем текст вправо от иконки
    Indent := Indent + 20;  // Добавляем место для иконки
  end;
  
  // Устанавливаем цвет текста в зависимости от выделения
  if IsSelected then
    TargetCanvas.Font.Color := MonitorTreeView.Colors.SelectionTextColor  // Системный цвет текста выделения
  else
    TargetCanvas.Font.Color := MonitorTreeView.Colors.TreeLineColor; // Системный цвет текста
  
  // Рисуем первую строку - заголовок с учетом отступа
  TextRect := CellRect;
  TextRect.Left := TextRect.Left + Indent + 2;  // Добавляем отступ
  TextRect.Top := TextRect.Top + 2;
  TextRect.Bottom := TextRect.Top + 14;  // Высота первой строки
  
  TargetCanvas.Font.Name := 'Tahoma';
  TargetCanvas.Font.Size := 9;
  TargetCanvas.TextRect(TextRect, TextRect.Left, TextRect.Top, Title);

  // Рисуем вторую строку - прогрессбар и текст с учетом отступа
  // Определяем размеры прогрессбара (используем константу DefHeight)
  ProgressRect := CellRect;
  ProgressRect.Top := CellRect.Top + DefHeight + 2;  // Начало второй строки
  ProgressRect.Bottom := CellRect.Top + DefHeight + Round((DefHeight) / 1.5);  // Уменьшенная высота на основе DefHeight
  ProgressRect.Left := CellRect.Left + Indent + 2;  // Добавляем отступ
  ProgressRect.Right := CellRect.Right - 50;  // Оставляем место для текста
  
  ProgressWidth := Round(ProgressRect.Width * Progress);
  
  // Рисуем фон прогрессбара
  if IsSelected then
    TargetCanvas.Brush.Color := MonitorTreeView.Colors.UnfocusedSelectionColor  // Системный фон прогрессбара
  else
    TargetCanvas.Brush.Color := MonitorTreeView.Colors.UnfocusedColor; // Системный фон
  
  TargetCanvas.FillRect(ProgressRect);
  
  // Рисуем заполненную часть прогрессбара
  if ProgressWidth > 0 then begin
    if IsSelected then
      TargetCanvas.Brush.Color := RGBToColor(210, 130, 70)  // Кирпичный RGB для выделенного
    else
      TargetCanvas.Brush.Color := RGBToColor(210, 130, 70);  // Кирпичный RGB прогресса
    
    ProgressRect.Right := ProgressRect.Left + ProgressWidth;
    TargetCanvas.FillRect(ProgressRect);
  end;
  
  // Рисуем рамку прогрессбара
  ProgressRect.Right := CellRect.Right - 50;
  TargetCanvas.Brush.Style := bsClear;
  TargetCanvas.Pen.Color := MonitorTreeView.Colors.TreeLineColor;  // Системный цвет рамки
  TargetCanvas.Rectangle(ProgressRect);
  
  // Рисуем текст прогресса
  TextRect := CellRect;
  TextRect.Top := CellRect.Top + DefHeight;  // Используем константу DefHeight
  TextRect.Bottom := CellRect.Top + DefHeight + Round((DefHeight) / 1.5);  // Высота прогрессбара
  TextRect.Left := CellRect.Right - 45;
  TextRect.Right := CellRect.Right - 2;
  
  TargetCanvas.TextRect(TextRect, TextRect.Left, TextRect.Top, ProgressText);
end;

procedure TMonitorForm.MonitorTreeViewAdvancedHeaderDraw(Sender: TVTHeader;
 var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements);
begin
end;

procedure TMonitorForm.MonitorTreeViewBeforeItemPaint(Sender: TBaseVirtualTree;
 TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect;
 var CustomDraw: boolean);
begin

end;

procedure TMonitorForm.MonitorTreeViewBeforePaint(Sender: TBaseVirtualTree;
 TargetCanvas: TCanvas);
begin
end;

function TMonitorForm.GetNodeData(Tree: TBaseVirtualTree; Node: PVirtualNode): TogsPropObject;
begin
  if Assigned(Node) and (MonitorTreeView.NodeDataSize > 0) then
    Result := TogsPropObject(Tree.GetNodeData(Node)^)
  else
    Result := nil;
end;

procedure TMonitorForm.MonitorTreeViewGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  NodeObj: TogsPropObject;
  Title: string;
  Progress: Double;
  ProgressText: string;
begin
  NodeObj := GetNodeData(MonitorTreeView, Node);
  if not Assigned(NodeObj) then Exit;
  
  // Получаем заголовок
  if AssignedProps(NodeObj.ItemByName['title']) then
    Title := NodeObj.ItemByName['title'].AsString
  else
    Title := 'Untitled';
  
  // Проверяем наличие поля progress и создаем если нужно
  if not AssignedProps(NodeObj.ItemByName['progress']) then begin
    // Определяем тип узла и создаем поле progress
    if AssignedProps(NodeObj.ItemByName['tasks']) then begin
      // Это тема - создаем progress
      NodeObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
      Progress := 0;
    end else if AssignedProps(NodeObj.ItemByName['subTasks']) then begin
      // Это задача - создаем progress
      NodeObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
      Progress := 0;
    end else begin
      // Это подзадача или другой тип - без progress
      CellText := Title + '| |0';  // Формат: Заголовок|ПрогрессТекст|Значение
      Exit;
    end;
  end else
    Progress := NodeObj.ItemByName['progress'].AsFloat;
  
  // Формируем двухстрочный формат: Заголовок|ПрогрессТекст|Значение
  ProgressText := Format('%.0f%%', [Progress * 100]);
  CellText := Format('%s|%s|%.2f', [Title, ProgressText, Progress]);
end;

procedure TMonitorForm.MonitorTreeViewGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Kind: TVTImageKind; Column: TColumnIndex; var ImageIndex: Integer;
  var ImageList: TCustomImageList);
var
  PropObj: TogsPropObject;
begin
 PropObj := GetNodeData(Sender, Node);
  // Определяем иконку по типу узла
  if Assigned(PropObj) then begin
    if AssignedProps(PropObj.ItemByName['tasks']) then
      ImageIndex := 0  // Иконка темы
    else
    if AssignedProps(PropObj.ItemByNAme['subTasks']) then
      ImageIndex := 1  // Иконка задачи
    else
      ImageIndex := 2; // Иконка подзадачи
  end else
    ImageIndex := -1;  // Нет иконки
end;

procedure TMonitorForm.MonitorTreeViewChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
var PropObj: TogsPropObject;
begin
//  WriteIn(['nodenil=',Node = nil]);
  PropObj := GetNodeData(Sender, Node);
  // Получаем выбранный узел
  if Assigned(PropObj) then begin
    fCurrentNode := PropObj;
    fCurrentNodeID := fCurrentNode.ItemByName['id'].AsString;
    UpdateDetails;
    Inspector.ogsProperties := fCurrentNode;
  end else begin
    fCurrentNode := nil;
    fCurrentNodeID := '';
  end;
end;

procedure TMonitorForm.MonitorTreeViewCollapsed(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  // Дерево уже построено, ничего не делаем
end;

procedure TMonitorForm.MonitorTreeViewCollapsing(Sender: TBaseVirtualTree; Node: PVirtualNode;
  var AllowCollapse: Boolean);
begin
  AllowCollapse := False;
end;

procedure TMonitorForm.MonitorTreeViewColumnResize(Sender: TVTHeader;
 Column: TColumnIndex);
begin

end;

procedure TMonitorForm.MonitorTreeViewEditing(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; var AllowEdit: Boolean);
begin
  // Запрещаем редактирование
  AllowEdit := False;
end;

procedure TMonitorForm.MonitorTreeViewExpanded(Sender: TBaseVirtualTree;
 Node: PVirtualNode);
begin

end;

procedure TMonitorForm.MonitorTreeViewExpanding(Sender: TBaseVirtualTree; Node: PVirtualNode;
  var AllowExpansion: Boolean);
begin
 AllowExpansion := False;
end;

procedure TMonitorForm.MonitorTreeViewGetImageIndex(Sender: TBaseVirtualTree;
 Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
 var Ghosted: boolean; var ImageIndex: integer);
begin

end;

procedure TMonitorForm.LoadProject;
begin
  fDatabase.LoadFromFile(fCurrentFileName);
  fProject := fDatabase.Project;  // ← Получаем TogsPropObject из адаптера
end;

procedure TMonitorForm.SaveProject;
begin
  fDatabase.SaveToFile(fCurrentFileName);  // ← Используем адаптер для сохранения
end;

procedure TMonitorForm.RefreshTreeView;
begin
  LoadProject;
  fDatabase.FillTreeViewData(MonitorTreeView);
  UpdateProgressChart;  // ← Обновляем график после загрузки данных
end;

procedure TMonitorForm.UpdateDetails;
var
  PropValue: TogsPropValue;
begin
  PropValue := fCurrentNode;
  WriteIn([fCurrentNode = nil]);
    // Показываем информацию о выбранном объекте
  ss32 := '';
  DetailsMemo.Lines.Text := PropValue.ToString;
end;

procedure TMonitorForm.UpdateStatusBar;
var
  ProjectObj: TogsPropObject;
  ThemesArray, TasksArray, SubTasksArray: TogsPropArray;
  TotalThemes, TotalTasks, TotalSubTasks: Integer;
  i, j, k: Integer;
  ThemeObj, TaskObj: TogsPropObject;
begin
  TotalThemes := 0;
  TotalTasks := 0;
  TotalSubTasks := 0;
  
  // Получаем корневой объект проекта
  if AssignedProps(fProject.ItemByName['project']) then begin
    ProjectObj := fProject.ItemByName['project'] as TogsPropObject;
    
    // Считаем темы
    if AssignedProps(ProjectObj.ItemByName['themes']) then begin
      ThemesArray := ProjectObj.ItemByName['themes'] as TogsPropArray;
      TotalThemes := ThemesArray.Count;
      
      // Считаем задачи
      for i := 0 to ThemesArray.Count - 1 do begin
        ThemeObj := ThemesArray.Item[i] as TogsPropObject;
        if AssignedProps(ThemeObj.ItemByName['tasks']) then begin
          TasksArray := ThemeObj.ItemByName['tasks'] as TogsPropArray;
          TotalTasks := TotalTasks + TasksArray.Count;
          
          // Считаем подзадачи
          for j := 0 to TasksArray.Count - 1 do begin
            TaskObj := TasksArray.Item[j] as TogsPropObject;
            if AssignedProps(TaskObj.ItemByName['subTasks']) then begin
              SubTasksArray := TaskObj.ItemByName['subTasks'] as TogsPropArray;
              TotalSubTasks := TotalSubTasks + SubTasksArray.Count;
            end;
          end;
        end;
      end;
    end;
  end;
  
  StatusLabel2.Caption := Format('Themes: %d | Tasks: %d | SubTasks: %d',
    [TotalThemes, TotalTasks, TotalSubTasks]);
end;

// ---------- Методы редактирования узлов ----------

// Вспомогательная функция для расчета среднего прогресса
function TMonitorForm.CalculateProgress(ArrayObj: TogsPropArray): Double;
var
  i: Integer;
  ItemObj: TogsPropObject;
  TotalProgress: Double;
  Count: Integer;
begin
  Result := 0;
  TotalProgress := 0;
  Count := 0;
  
  if not Assigned(ArrayObj) then Exit;
  
  for i := 0 to ArrayObj.Count - 1 do begin
    ItemObj := ArrayObj.Item[i] as TogsPropObject;
    if AssignedProps(ItemObj.ItemByName['progress']) then begin
      TotalProgress := TotalProgress + ItemObj.ItemByName['progress'].AsFloat;
      Inc(Count);
    end;
  end;
  
  if Count > 0 then
    Result := TotalProgress / Count
  else
    Result := 0;
end;

// Обновление прогресса для родительских элементов
procedure TMonitorForm.UpdateParentProgress(Node: PVirtualNode);
var
  ParentNode: PVirtualNode;
  ParentObj, ChildObj: TogsPropObject;
  TasksArray, SubTasksArray: TogsPropArray;
  NewProgress: Double;
begin
  if not Assigned(Node) then Exit;
  
  ParentNode := Node^.Parent;
  if not Assigned(ParentNode) then Exit;
  
  ParentObj := GetNodeData(MonitorTreeView, ParentNode);
  if not Assigned(ParentObj) then Exit;
  
  // Если родитель - задача, обновляем ее прогресс на основе подзадач
  if AssignedProps(ParentObj.ItemByName['subTasks']) then begin
    SubTasksArray := ParentObj.ItemByName['subTasks'] as TogsPropArray;
    NewProgress := CalculateProgress(SubTasksArray);
    
    // Создаем поле progress если его нет
    if not AssignedProps(ParentObj.ItemByName['progress']) then
      ParentObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
    
    // Обновляем прогресс задачи
    ParentObj.ItemByName['progress'].AsFloat := NewProgress;
    ParentObj.ItemByName['lastModified'].AsString := FormatDateTime('dd.mm.yyyy hh:nn:ss', Now);
    
    // Обновляем отображение
    MonitorTreeView.InvalidateNode(ParentNode);
    
    // Рекурсивно обновляем прогресс темы
    UpdateParentProgress(ParentNode);
  end
  // Если родитель - тема, обновляем ее прогресс на основе задач
  else if AssignedProps(ParentObj.ItemByName['tasks']) then begin
    TasksArray := ParentObj.ItemByName['tasks'] as TogsPropArray;
    NewProgress := CalculateProgress(TasksArray);
    
    // Создаем поле progress если его нет
    if not AssignedProps(ParentObj.ItemByName['progress']) then
      ParentObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
    
    // Обновляем прогресс темы
    ParentObj.ItemByName['progress'].AsFloat := NewProgress;
    ParentObj.ItemByName['lastModified'].AsString := FormatDateTime('dd.mm.yyyy hh:nn:ss', Now);
    
    // Обновляем отображение
    MonitorTreeView.InvalidateNode(ParentNode);
  end;
end;

procedure TMonitorForm.AddNewTheme;
var
  ProjectObj: TogsPropObject;
  ThemesArray: TogsPropArray;
  NewThemeObj: TogsPropObject;
  NewNode: PVirtualNode;
  ThemeID: string;
begin
  // Получаем проект
  if not AssignedProps(fProject.ItemByName['project']) then begin
   ProjectObj := TogsPropObject.Create;
   fProject.AddItem(TogsProperty.Create('project', ProjectObj));
  end else
   ProjectObj := fProject.ItemByName['project'] as TogsPropObject;
  
  // Получаем массив тем
  if not AssignedProps(ProjectObj.ItemByName['themes']) then begin
   ThemesArray := TogsPropArray.Create;
   ProjectObj.AddItem(TogsProperty.Create('themes', ThemesArray));
  end else
   ThemesArray := ProjectObj.ItemByName['themes'] as TogsPropArray;
  
  // Создаем новую тему
  NewThemeObj := TogsPropObject.Create;
  ThemeID := Format('THEME%.3d', [ThemesArray.Count + 1]);
  
  NewThemeObj.AddItem(TogsProperty.Create('id', TogsPropString.Create(ThemeID)));
  NewThemeObj.AddItem(TogsProperty.Create('title', TogsPropString.Create('New Theme')));
  NewThemeObj.AddItem(TogsProperty.Create('description', TogsPropString.Create('')));
  NewThemeObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
  NewThemeObj.AddItem(TogsProperty.Create('createdDate', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  NewThemeObj.AddItem(TogsProperty.Create('gitHubRepo', TogsPropString.Create('')));
  NewThemeObj.AddItem(TogsProperty.Create('color', TogsPropString.Create('#0078D4')));
  NewThemeObj.AddItem(TogsProperty.Create('isActive', TogsPropString.Create('True')));
  
  // Создаем пустой массив задач
  NewThemeObj.AddItem(TogsProperty.Create('tasks', TogsPropArray.Create));
  
  // Добавляем тему в массив
  ThemesArray.AddItem(NewThemeObj);
  
  // Обновляем прогресс проекта (если нужно)
  // UpdateParentProgress(NewNode); // У темы нет родителя с прогрессом
  
  // Добавляем узел в дерево
  MonitorTreeView.BeginUpdate;
  try
    NewNode := MonitorTreeView.AddChild(nil, NewThemeObj);
  //  NewNode.Data := NewThemeObj;
    MonitorTreeView.Selected[NewNode] := True;
    MonitorTreeView.FullExpand(NewNode);
  finally
    MonitorTreeView.EndUpdate;
  end;
  
  // Сохраняем изменения
 // SaveProject;
  UpdateStatusBar;
end;

procedure TMonitorForm.AddNewTask(ParentNode: PVirtualNode);
var
  ParentObj, NewTaskObj: TogsPropObject;
  TasksArray: TogsPropArray;
  NewNode: PVirtualNode;
  TaskID: string;
begin
  if not Assigned(ParentNode) then Exit;

  ParentObj := GetNodeData(MonitorTreeView, ParentNode);
  if not Assigned(ParentObj) then Exit;
  
  // Проверяем что родитель - тема
  if not AssignedProps(ParentObj.ItemByName['tasks']) then Exit;
  WriteIn([ParentObj.ItemByName['tasks'].PropValue.AsString]);
  TasksArray := ParentObj.ItemByName['tasks'] as TogsPropArray;
  
  // Создаем новую задачу
  NewTaskObj := TogsPropObject.Create;
  TaskID := Format('TASK%.3d', [TasksArray.Count + 1]);
  
  NewTaskObj.AddItem(TogsProperty.Create('id', TogsPropString.Create(TaskID)));
  NewTaskObj.AddItem(TogsProperty.Create('title', TogsPropString.Create('New Task')));
  NewTaskObj.AddItem(TogsProperty.Create('description', TogsPropString.Create('')));
  NewTaskObj.AddItem(TogsProperty.Create('status', TogsPropFloat.Create(0)));
  NewTaskObj.AddItem(TogsProperty.Create('priority', TogsPropFloat.Create(1)));
  NewTaskObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
  NewTaskObj.AddItem(TogsProperty.Create('createdDate', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  NewTaskObj.AddItem(TogsProperty.Create('dueDate', TogsPropString.Create('')));
  NewTaskObj.AddItem(TogsProperty.Create('assignedTo', TogsPropString.Create('')));
  NewTaskObj.AddItem(TogsProperty.Create('gitHubPath', TogsPropString.Create('')));
  NewTaskObj.AddItem(TogsProperty.Create('estimatedHours', TogsPropFloat.Create(0)));
  NewTaskObj.AddItem(TogsProperty.Create('actualHours', TogsPropFloat.Create(0)));
  NewTaskObj.AddItem(TogsProperty.Create('lastModified', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  
  // Создаем пустой массив подзадач
  NewTaskObj.AddItem(TogsProperty.Create('subTasks', TogsPropArray.Create));
  
  // Добавляем задачу в массив
  TasksArray.AddItem(NewTaskObj);
  
  // Добавляем узел в дерево
  MonitorTreeView.BeginUpdate;
  try
    NewNode := MonitorTreeView.AddChild(ParentNode, NewTaskObj);
  //  NewNode.Data := NewTaskObj;
    MonitorTreeView.Selected[NewNode] := True;
    MonitorTreeView.FullExpand(ParentNode);
  finally
    MonitorTreeView.EndUpdate;
  end;
  
  // Обновляем прогресс темы (родительской)
  UpdateParentProgress(NewNode);
  
  // Сохраняем изменения
 SaveProject;
  UpdateStatusBar;
end;

procedure TMonitorForm.AddNewSubTask(ParentNode: PVirtualNode);
var
  ParentObj, NewSubTaskObj: TogsPropObject;
  SubTasksArray: TogsPropArray;
  NewNode: PVirtualNode;
  SubTaskID: string;
begin
  if not Assigned(ParentNode) then Exit;
  
  ParentObj := GetNodeData(MonitorTreeView, ParentNode);
  if not Assigned(ParentObj) then Exit;
  
  // Проверяем что родитель - задача
  if not AssignedProps(ParentObj.ItemByName['subTasks']) then begin
    // Создаем массив подзадач если его нет
    ParentObj.AddItem(TogsProperty.Create('subTasks', TogsPropArray.Create));
  end;
  
  SubTasksArray := ParentObj.ItemByName['subTasks'] as TogsPropArray;
  
  // Создаем новую подзадачу
  NewSubTaskObj := TogsPropObject.Create;
  SubTaskID := Format('SUBTASK%.3d', [SubTasksArray.Count + 1]);
  
  NewSubTaskObj.AddItem(TogsProperty.Create('id', TogsPropString.Create(SubTaskID)));
  NewSubTaskObj.AddItem(TogsProperty.Create('title', TogsPropString.Create('New SubTask')));
  NewSubTaskObj.AddItem(TogsProperty.Create('description', TogsPropString.Create('')));
  NewSubTaskObj.AddItem(TogsProperty.Create('status', TogsPropFloat.Create(0)));
  NewSubTaskObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
  NewSubTaskObj.AddItem(TogsProperty.Create('createdDate', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  NewSubTaskObj.AddItem(TogsProperty.Create('completedDate', TogsPropString.Create('')));
  NewSubTaskObj.AddItem(TogsProperty.Create('gitHubFile', TogsPropString.Create('')));
  NewSubTaskObj.AddItem(TogsProperty.Create('lastModified', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  
  // Добавляем подзадачу в массив
  SubTasksArray.AddItem(NewSubTaskObj);
  
  // Добавляем узел в дерево
  MonitorTreeView.BeginUpdate;
  try
    NewNode := MonitorTreeView.AddChild(ParentNode, NewSubTaskObj);
  //  NewNode.Data := NewSubTaskObj;
    MonitorTreeView.Selected[NewNode] := True;
    MonitorTreeView.FullExpand(ParentNode);
  finally
    MonitorTreeView.EndUpdate;
  end;
  
  // Обновляем прогресс задачи и темы (родительских)
  UpdateParentProgress(NewNode);
  
  // Сохраняем изменения
 SaveProject;
  UpdateStatusBar;
end;

procedure TMonitorForm.DeleteSelectedNode;
var
  SelectedNode: PVirtualNode;
  NodeObj, ParentObj: TogsPropObject;
  ParentArray: TogsPropArray;
  i: Integer;
  NodeID: string;
begin
  SelectedNode := MonitorTreeView.GetFirstSelected;
  if not Assigned(SelectedNode) then begin
    ShowMessage('Please select a node to delete');
    Exit;
  end;
  
  NodeObj := GetNodeData(MonitorTreeView, SelectedNode);
  if not Assigned(NodeObj) then Exit;
  
  // Получаем ID узла для поиска в массиве
  if not AssignedProps(NodeObj.ItemByName['id']) then Exit;
  NodeID := NodeObj.ItemByName['id'].AsString;
  
  // Определяем тип узла и находим родительский массив
  if AssignedProps(NodeObj.ItemByName['tasks']) then begin
    // Это тема - удаляем из массива тем
    ParentObj := fProject.ItemByName['project'] as TogsPropObject;
    ParentArray := ParentObj.ItemByName['themes'] as TogsPropArray;
  end else if AssignedProps(NodeObj.ItemByName['subTasks']) then begin
    // Это задача - удаляем из массива задач родительской темы
    ParentObj := GetNodeData(MonitorTreeView, SelectedNode^.Parent);
    if not Assigned(ParentObj) then Exit;
    ParentArray := ParentObj.ItemByName['tasks'] as TogsPropArray;
  end else begin
    // Это подзадача - удаляем из массива подзадач родительской задачи
    ParentObj := GetNodeData(MonitorTreeView, SelectedNode^.Parent);
    if not Assigned(ParentObj) then Exit;
    ParentArray := ParentObj.ItemByName['subTasks'] as TogsPropArray;
  end;
  
  // Находим и удаляем элемент из массива
  for i := 0 to ParentArray.Count - 1 do begin
    NodeObj := ParentArray.Item[i] as TogsPropObject;
    if AssignedProps(NodeObj.ItemByName['id']) and 
       (NodeObj.ItemByName['id'].AsString = NodeID) then begin
      ParentArray.DeleteItem(i);
      Break;
    end;
  end;
  
  // Удаляем узел из дерева
  MonitorTreeView.BeginUpdate;
  try
    MonitorTreeView.DeleteNode(SelectedNode);
  finally
    MonitorTreeView.EndUpdate;
  end;
  
  // Обновляем прогресс родительских элементов после удаления
  UpdateParentProgress(SelectedNode);
  
  // Сохраняем изменения
  SaveProject;
  UpdateStatusBar;
  UpdateDetails;
end;

procedure TMonitorForm.SetNodeProgress(Node: PVirtualNode; Progress: Double);
var
  NodeObj: TogsPropObject;
begin
  if not Assigned(Node) then Exit;
  
  NodeObj := GetNodeData(MonitorTreeView, Node);
  if not Assigned(NodeObj) then Exit;
  
  // Устанавливаем прогресс для задач и подзадач
  if AssignedProps(NodeObj.ItemByName['progress']) then begin
    NodeObj.ItemByName['progress'].AsFloat := Progress;
    NodeObj.ItemByName['lastModified'].AsString := FormatDateTime('dd.mm.yyyy hh:nn:ss', Now);
    
    // Обновляем отображение
    MonitorTreeView.InvalidateNode(Node);
    
    // Автоматически обновляем прогресс родительских элементов
    UpdateParentProgress(Node);
    
    // Сохраняем изменения
    SaveProject;
    UpdateDetails;
  end;
end;

procedure TMonitorForm.UpdateNodeTitle(Node: PVirtualNode; NewTitle: string);
var
  NodeObj: TogsPropObject;
begin
  if not Assigned(Node) then Exit;
  
  NodeObj := GetNodeData(MonitorTreeView, Node);
  if not Assigned(NodeObj) then Exit;
  
  // Обновляем заголовок
  if AssignedProps(NodeObj.ItemByName['title']) then begin
    NodeObj.ItemByName['title'].AsString := NewTitle;
    NodeObj.ItemByName['lastModified'].AsString := FormatDateTime('dd.mm.yyyy hh:nn:ss', Now);
    
    // Обновляем отображение
    MonitorTreeView.InvalidateNode(Node);
    
    // Сохраняем изменения
    SaveProject;
    UpdateDetails;
  end;
end;

procedure TMonitorForm.AddButtonClick(Sender: TObject);
var
  SelectedNode: PVirtualNode;
  NodeObj: TogsPropObject;
begin
  SelectedNode := MonitorTreeView.GetFirstSelected;
  
  if not Assigned(SelectedNode) then begin
    // Нет выделенного узла - добавляем новую тему
    AddNewTheme;
  end else begin
    NodeObj := GetNodeData(MonitorTreeView, SelectedNode);
    if Assigned(NodeObj) then begin
      if AssignedProps(NodeObj.ItemByName['tasks']) then
        // Выделена тема - добавляем задачу
        AddNewTask(SelectedNode)
      else if AssignedProps(NodeObj.ItemByName['subTasks']) then
        // Выделена задача - добавляем подзадачу
        AddNewSubTask(SelectedNode)
      else
        // Выделена подзадача - добавляем новую тему
        AddNewTheme;
    end;
  end;
  // Сохраняем изменения
  SaveProject;
end;

procedure TMonitorForm.EditButtonClick(Sender: TObject);
var
  SelectedNode: PVirtualNode;
  NodeObj: TogsPropObject;
  NewTitle: string;
begin
  SelectedNode := MonitorTreeView.GetFirstSelected;
  if not Assigned(SelectedNode) then begin
    ShowMessage('Please select a node to edit');
    Exit;
  end;
  
  NodeObj := GetNodeData(MonitorTreeView, SelectedNode);
  if not Assigned(NodeObj) then Exit;
  
  // Получаем текущий заголовок
  if AssignedProps(NodeObj.ItemByName['title']) then
    NewTitle := NodeObj.ItemByName['title'].AsString
  else
    NewTitle := '';
  
  // Здесь можно добавить диалог редактирования
  if InputQuery('Edit Title', 'Enter new title:', NewTitle) then begin
    UpdateNodeTitle(SelectedNode, NewTitle);
  end;
  // Сохраняем изменения
  SaveProject;
end;

procedure TMonitorForm.DeleteButtonClick(Sender: TObject);
begin
  DeleteSelectedNode;
end;

procedure TMonitorForm.ProgressButtonClick(Sender: TObject);
var
  SelectedNode: PVirtualNode;
  NodeObj: TogsPropObject;
  CurrentProgress: Double;
  ProgressStr: string;
  NodeType: string;
begin
  SelectedNode := MonitorTreeView.GetFirstSelected;
  if not Assigned(SelectedNode) then begin
    ShowMessage('Please select a subtask to update progress');
    Exit;
  end;
  
  NodeObj := GetNodeData(MonitorTreeView, SelectedNode);
  if not Assigned(NodeObj) then Exit;
  
  // Определяем тип узла
  if AssignedProps(NodeObj.ItemByName['tasks']) then
    NodeType := 'theme'
  else if AssignedProps(NodeObj.ItemByName['subTasks']) then
    NodeType := 'task'
  else
    NodeType := 'subtask';
  
  // Прогресс можно устанавливать только для подзадач
  if NodeType <> 'subtask' then begin
    if AssignedProps(NodeObj.ItemByName['progress']) then
      ShowMessage(Format('Progress for %s is calculated automatically from subtasks (Current: %.1f%%)', 
        [NodeType, NodeObj.ItemByName['progress'].AsFloat * 100]))
    else
      ShowMessage('Progress can only be set for subtasks');
    Exit;
  end;
  
  // Получаем текущий прогресс подзадачи
  CurrentProgress := NodeObj.ItemByName['progress'].AsFloat;
  ProgressStr := Format('%.1f', [CurrentProgress * 100]);
  
  // Запрашиваем новый прогресс
  if InputQuery('Update SubTask Progress', 'Enter progress percentage (0-100):', ProgressStr) then begin
    try
      CurrentProgress := StrToFloat(ProgressStr) / 100;
      if (CurrentProgress >= 0) and (CurrentProgress <= 1) then begin
        SetNodeProgress(SelectedNode, CurrentProgress);
        ShowMessage('SubTask progress updated successfully');
      end else
        ShowMessage('Progress must be between 0 and 100');
    except
      ShowMessage('Invalid progress value');
    end;
  end;
 // Сохраняем изменения
  SaveProject;
end;

procedure TMonitorForm.GitHubButtonClick(Sender: TObject);
var
  NodeData: string;
  Parts: TStringArray;
  GitHubPath: string;
  CurrentObj: TogsPropObject;
begin
  if fCurrentNodeID = '' then begin
    ShowMessage('Please select an item');
    Exit;
  end;
  
  GitHubPath := '';
  
  // Получаем данные узла
{
  if Assigned(MonitorTreeView.Selected) and Assigned(MonitorTreeView.Selected.Data) then begin
    NodeData := string(MonitorTreeView.Selected.Data);
    Parts := NodeData.Split([':']);
    
    if Length(Parts) = 2 then begin
      // Получаем объект напрямую из Node.Data
      CurrentObj := TogsPropValue(MonitorTreeView.Selected.Data) as TogsPropObject;
      
      if Parts[0] = 'tasks' then begin
        // Получаем GitHubPath из задачи
        if AssignedProps(CurrentObj.ItemByName['gitHubPath']) then
          GitHubPath := CurrentObj.ItemByName['gitHubPath'].AsString;
      end else if Parts[0] = 'subTasks' then begin
        // Получаем GitHubFile из подзадачи
        if AssignedProps(CurrentObj.ItemByName['gitHubFile']) then
          GitHubPath := CurrentObj.ItemByName['gitHubFile'].AsString;
      end;
    end;
  end;
  
  if GitHubPath <> '' then
    ShowMessage('GitHub link: ' + GitHubPath)
  else
    ShowMessage('No GitHub link configured');
 }
end;

procedure TMonitorForm.ActivityButtonClick(Sender: TObject);
begin
  ActivityLogMenuClick(Sender);
end;

procedure TMonitorForm.FilterComboChange(Sender: TObject);
begin
  // Фильтрация отключена - ничего не делаем
end;

procedure TMonitorForm.FilterEditChange(Sender: TObject);
begin
  // Фильтрация отключена - ничего не делаем
end;

procedure TMonitorForm.FilterClearButtonClick(Sender: TObject);
begin
  FilterEdit.Text := '';
  FilterCombo.ItemIndex := 0;
  // Ничего не обновляем - дерево уже построено
end;

procedure TMonitorForm.NewThemeMenuClick(Sender: TObject);
begin
  AddNewTheme;
end;

procedure TMonitorForm.NewTaskMenuClick(Sender: TObject);
var
  SelectedNode: PVirtualNode;
  NodeObj: TogsPropObject;
begin
  SelectedNode := MonitorTreeView.GetFirstSelected;
  if not Assigned(SelectedNode) then begin
    ShowMessage('Please select a theme to add a task');
    Exit;
  end;
  
  NodeObj := GetNodeData(MonitorTreeView, SelectedNode);
  if Assigned(NodeObj) and AssignedProps(NodeObj.ItemByName['tasks']) then
    AddNewTask(SelectedNode)
  else
    ShowMessage('Please select a theme to add a task');
end;

procedure TMonitorForm.NewSubTaskMenuClick(Sender: TObject);
var
  SelectedNode: PVirtualNode;
  NodeObj: TogsPropObject;
begin
  SelectedNode := MonitorTreeView.GetFirstSelected;
  if not Assigned(SelectedNode) then begin
    ShowMessage('Please select a task to add a subtask');
    Exit;
  end;
  
  NodeObj := GetNodeData(MonitorTreeView, SelectedNode);
  if Assigned(NodeObj) and AssignedProps(NodeObj.ItemByName['subTasks']) then
    AddNewSubTask(SelectedNode)
  else
    ShowMessage('Please select a task to add a subtask');
end;

procedure TMonitorForm.SaveMenuClick(Sender: TObject);
begin
  SaveProject();
  ShowMessage('Project saved successfully: ' + ExtractFileName(fCurrentFileName));
end;

procedure TMonitorForm.SaveAsMenuClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    SaveDialog.FileName := fCurrentFileName;
    
    if SaveDialog.Execute then begin
      fCurrentFileName := SaveDialog.FileName;  // ← Сохраняем новое имя файла
      SaveProject();
      ShowMessage('Project saved successfully: ' + ExtractFileName(fCurrentFileName));
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TMonitorForm.LoadMenuClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog := TOpenDialog.Create(nil);
  try
    OpenDialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    
    if OpenDialog.Execute then begin
      fCurrentFileName := OpenDialog.FileName;  
      fDatabase.LoadFromFile(fCurrentFileName);
      fProject := fDatabase.Project;
      
      RefreshTreeView;
      UpdateDetails;
      UpdateStatusBar;
      ShowMessage('Project loaded successfully: ' + ExtractFileName(fCurrentFileName));
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TMonitorForm.BackupMenuClick(Sender: TObject);
begin
  SaveProject;
  ShowMessage('Backup created successfully');
end;

procedure TMonitorForm.DeleteMenuClick(Sender: TObject);
begin
  DeleteSelectedNode;
end;

procedure TMonitorForm.RefreshMenuClick(Sender: TObject);
begin
  RefreshTreeView;
end;

procedure TMonitorForm.ExpandAllMenuClick(Sender: TObject);
begin
  MonitorTreeView.FullExpand;
end;

procedure TMonitorForm.CollapseAllMenuClick(Sender: TObject);
begin
  MonitorTreeView.FullCollapse;
end;

procedure TMonitorForm.GitHubValidateMenuClick(Sender: TObject);
begin
  ShowMessage('GitHub validation functionality - to be implemented');
end;

procedure TMonitorForm.ActivityLogMenuClick(Sender: TObject);
begin
  ShowMessage('Activity log functionality - to be implemented');
end;

procedure TMonitorForm.AboutMenuClick(Sender: TObject);
begin
  ShowMessage('Global Monitor v1.0'#13#10'Work Complex Management System'#13#10'with GitHub integration and activity monitoring');
end;

procedure TMonitorForm.ExitMenuClick(Sender: TObject);
begin
  Close;
end;

procedure TMonitorForm.Splitter1CanOffset(Sender: TObject;
 var NewOffset: Integer; var Accept: Boolean);
begin
 //
end;

procedure TMonitorForm.Splitter1ChangeBounds(Sender: TObject);
begin
//
end;

end.
