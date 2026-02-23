unit MonitorDatabase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ogcProperties, ComCtrls, VirtualTrees;

type
  // База данных мониторинга
  TMonitorDatabase = class
  private
    fProject: TogsPropObject;  // ← Единственное хранилище
    fFileName: string;
    
  public
    property Project: TogsPropObject read fProject;
    constructor Create(const FileName: string = '');
    destructor Destroy; override;
    
    // Только базовые операции:
    procedure LoadFromFile(FileName: string);
    procedure SaveToFile(FileName: string);
    
    // Работа с TreeView
    procedure FillTreeViewData(Tree: TVirtualStringTree);
    
    // Создание иерархической структуры
    procedure CreateDefaultHierarchicalStructure;
    
    // Установка времени окончания при прогрессе 100%
    procedure SetProgressEnd(NodeObj: TogsPropObject; Progress: Double);
  end;

implementation uses ogcWriter, Dialogs;

{ TMonitorDatabase }

constructor TMonitorDatabase.Create(const FileName: string);
begin
  inherited Create;
  fFileName := FileName;
  fProject := TogsPropObject.Create;  // ← Создаем хранилище
  
  if (FileName <> '') and FileExists(FileName) then
    LoadFromFile(FileName);
end;

destructor TMonitorDatabase.Destroy;
begin
  if (fFileName <> '') then
    SaveToFile(fFileName);
  fProject.Free;
  inherited Destroy;
end;

procedure TMonitorDatabase.LoadFromFile(FileName: string);
var
  JsonContent: string;
begin
  if FileExists(FileName) then begin
    with TStringList.Create do begin
      LoadFromFile(FileName);
      JsonContent := Text;
      Free;
    end;
    fProject.FromString(JsonContent);
  end else begin
    // Создаем иерархическую структуру
  //  CreateDefaultHierarchicalStructure;
  end;
//  WriteIn(['Load1=', Now] );
//  ShowMessage(JsonContent);
end;

procedure TMonitorDatabase.CreateDefaultHierarchicalStructure;
var
  ProjectObj, ThemeObj, TaskObj, SubTaskObj: TogsPropObject;
  ThemesArray, TasksArray, SubTasksArray: TogsPropArray;
begin
  exit;
  // Создаем корневой объект проекта
  ProjectObj := TogsPropObject.Create;
  ThemesArray := TogsPropArray.Create;
  ProjectObj.AddItem(TogsProperty.Create('themes', ThemesArray));
  fProject.AddItem(TogsProperty.Create('project', ProjectObj));
  
  // Создаем первую тему
  ThemeObj := TogsPropObject.Create;
  ThemeObj.AddItem(TogsProperty.Create('id', TogsPropString.Create('THEME001')));
  ThemeObj.AddItem(TogsProperty.Create('title', TogsPropString.Create('Grapher Development')));
  ThemeObj.AddItem(TogsProperty.Create('description', TogsPropString.Create('Development of graphics editor framework')));
  ThemeObj.AddItem(TogsProperty.Create('createdDate', TogsPropString.Create('15.12.2025 18:49:35')));
  ThemeObj.AddItem(TogsProperty.Create('startproc', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  ThemeObj.AddItem(TogsProperty.Create('endproc', TogsPropString.Create('')));
  ThemeObj.AddItem(TogsProperty.Create('gitHubRepo', TogsPropString.Create('https://github.com/user/grapher')));
  ThemeObj.AddItem(TogsProperty.Create('color', TogsPropString.Create('#0078D4')));
  ThemeObj.AddItem(TogsProperty.Create('isActive', TogsPropString.Create('True')));
  
  // Создаем задачи для темы
  TasksArray := TogsPropArray.Create;
  ThemeObj.AddItem(TogsProperty.Create('tasks', TasksArray));

  TaskObj := TogsPropObject.Create;
  TaskObj.AddItem(TogsProperty.Create('id', TogsPropString.Create('TASK001')));
  TaskObj.AddItem(TogsProperty.Create('title', TogsPropString.Create('GUI Components')));
  TaskObj.AddItem(TogsProperty.Create('description', TogsPropString.Create('Develop user interface components')));
  TaskObj.AddItem(TogsProperty.Create('status', TogsPropFloat.Create(0)));
  TaskObj.AddItem(TogsProperty.Create('priority', TogsPropFloat.Create(1)));
  TaskObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
  TaskObj.AddItem(TogsProperty.Create('createdDate', TogsPropString.Create('30.12.2025 18:49:35')));
  TaskObj.AddItem(TogsProperty.Create('startproc', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  TaskObj.AddItem(TogsProperty.Create('endproc', TogsPropString.Create('')));
  TaskObj.AddItem(TogsProperty.Create('dueDate', TogsPropString.Create('13.02.2026 18:49:35')));
  TaskObj.AddItem(TogsProperty.Create('assignedTo', TogsPropString.Create('UI Developer')));
  TaskObj.AddItem(TogsProperty.Create('gitHubPath', TogsPropString.Create('/src/gui')));
  TaskObj.AddItem(TogsProperty.Create('estimatedHours', TogsPropFloat.Create(120.0)));
  TaskObj.AddItem(TogsProperty.Create('actualHours', TogsPropFloat.Create(0.0)));
  TaskObj.AddItem(TogsProperty.Create('lastModified', TogsPropString.Create('30.12.2025 18:49:35')));
  
  // Создаем подзадачи для задачи
  SubTasksArray := TogsPropArray.Create;
  TaskObj.AddItem(TogsProperty.Create('subTasks', SubTasksArray));
  
  SubTaskObj := TogsPropObject.Create;
  SubTaskObj.AddItem(TogsProperty.Create('id', TogsPropString.Create('SUBTASK001')));
  SubTaskObj.AddItem(TogsProperty.Create('title', TogsPropString.Create('Create Form Class')));
  SubTaskObj.AddItem(TogsProperty.Create('description', TogsPropString.Create('Implement main form with basic layout')));
  SubTaskObj.AddItem(TogsProperty.Create('status', TogsPropFloat.Create(0)));
  SubTaskObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(0)));
  SubTaskObj.AddItem(TogsProperty.Create('createdDate', TogsPropString.Create('30.12.2025 18:49:35')));
  SubTaskObj.AddItem(TogsProperty.Create('startproc', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  SubTaskObj.AddItem(TogsProperty.Create('endproc', TogsPropString.Create('')));
  SubTaskObj.AddItem(TogsProperty.Create('completedDate', TogsPropString.Create('')));
  SubTaskObj.AddItem(TogsProperty.Create('gitHubFile', TogsPropString.Create('/src/gui/mainform.pas')));
  SubTaskObj.AddItem(TogsProperty.Create('lastModified', TogsPropString.Create('30.12.2025 18:49:35')));
  
  SubTasksArray.AddItem(SubTaskObj);
  TasksArray.AddItem(TaskObj);
  ThemesArray.AddItem(ThemeObj);
  
  // Создаем вторую тему
  ThemeObj := TogsPropObject.Create;
  ThemeObj.AddItem(TogsProperty.Create('id', TogsPropString.Create('THEME002')));
  ThemeObj.AddItem(TogsProperty.Create('title', TogsPropString.Create('Testing & QA')));
  ThemeObj.AddItem(TogsProperty.Create('description', TogsPropString.Create('Quality assurance and automated testing')));
  ThemeObj.AddItem(TogsProperty.Create('createdDate', TogsPropString.Create('25.12.2025 18:49:35')));
  ThemeObj.AddItem(TogsProperty.Create('gitHubRepo', TogsPropString.Create('https://github.com/user/grapher-tests')));
  ThemeObj.AddItem(TogsProperty.Create('color', TogsPropString.Create('#107C10')));
  ThemeObj.AddItem(TogsProperty.Create('isActive', TogsPropString.Create('True')));
  
  // Пустой массив задач для второй темы
  TasksArray := TogsPropArray.Create;
  ThemeObj.AddItem(TogsProperty.Create('tasks', TasksArray));
  
  ThemesArray.AddItem(ThemeObj);

end;

procedure TMonitorDatabase.SaveToFile(FileName: string);
var S: String;
begin
  with TStringList.Create do begin
    Text := fProject.ToString;
    S:= Text;
    SaveToFile(FileName);
    Free;
  end;
end;

procedure TMonitorDatabase.FillTreeViewData(Tree: TVirtualStringTree);
var
  ProjectObj, ThemeObj, TaskObj, SubTaskObj: TogsPropObject;
  ThemesArray, TasksArray, SubTasksArray: TogsPropArray;
  i, j, k: Integer;
  RootNode, ThemeNode, TaskNode: PVirtualNode;
begin
  WriteIn(['TreeViewDATA============', Now]);
  Tree.BeginUpdate;
  try
    Tree.Clear;
    
    // Получаем корневой объект проекта
    if not AssignedProps(fProject.ItemByName['project']) then
      Exit;
      
    ProjectObj := fProject.ItemByName['project'] as TogsPropObject;
    ProjectObj.Level := 1;
    
    // Получаем массив тем
    if not AssignedProps(ProjectObj.ItemByName['themes']) then
      Exit;
      
    ThemesArray := ProjectObj.ItemByName['themes'] as TogsPropArray;

    // Добавляем темы как корневые узлы
    for i := 0 to ThemesArray.Count - 1 do begin
      ThemeObj := ThemesArray.Item[i] as TogsPropObject;
      ThemeObj.Level := 1;
      
      // Добавляем startproc если отсутствует
      if not AssignedProps(ThemeObj.ItemByName['startproc']) then
        ThemeObj.AddItem(TogsProperty.Create('startproc', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
      
      // Добавляем endproc если отсутствует
      if not AssignedProps(ThemeObj.ItemByName['endproc']) then
        ThemeObj.AddItem(TogsProperty.Create('endproc', TogsPropString.Create('')));
        
      RootNode := Tree.AddChild(nil, ThemeObj);
      
      // Получаем задачи для этой темы
      if AssignedProps(ThemeObj.ItemByName['tasks']) then begin
        TasksArray := ThemeObj.ItemByName['tasks'] as TogsPropArray;

        // Добавляем дочерние узлы (задачи)
        for j := 0 to TasksArray.Count - 1 do begin
          TaskObj := TasksArray.Item[j] as TogsPropObject;
          TaskObj.Level := 2;
          
          // Добавляем startproc если отсутствует
          if not AssignedProps(TaskObj.ItemByName['startproc']) then
            TaskObj.AddItem(TogsProperty.Create('startproc', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
          
          // Добавляем endproc если отсутствует
          if not AssignedProps(TaskObj.ItemByName['endproc']) then
            TaskObj.AddItem(TogsProperty.Create('endproc', TogsPropString.Create('')));
            
          ThemeNode := Tree.AddChild(RootNode, TaskObj);

          // Получаем подзадачи для этой задачи
          if AssignedProps(TaskObj.ItemByName['subTasks']) then begin
            SubTasksArray := TaskObj.ItemByName['subTasks'] as TogsPropArray;
            
            // Добавляем дочерние узлы (подзадачи)
            for k := 0 to SubTasksArray.Count - 1 do begin
              SubTaskObj := SubTasksArray.Item[k] as TogsPropObject;
              SubTaskObj.Level := 3;
              
              // Добавляем startproc если отсутствует
              if not AssignedProps(SubTaskObj.ItemByName['startproc']) then
                SubTaskObj.AddItem(TogsProperty.Create('startproc', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
              
              // Добавляем endproc если отсутствует
              if not AssignedProps(SubTaskObj.ItemByName['endproc']) then
                SubTaskObj.AddItem(TogsProperty.Create('endproc', TogsPropString.Create('')));
                
              TaskNode := Tree.AddChild(ThemeNode, SubTaskObj);
            end;
          end;
        end;
      end;
    end;
  finally
    Tree.EndUpdate;
  end;
end;

procedure TMonitorDatabase.SetProgressEnd(NodeObj: TogsPropObject; Progress: Double);
begin
  // Устанавливаем прогресс
  if AssignedProps(NodeObj.ItemByName['progress']) then
    NodeObj.ItemByName['progress'].AsFloat := Progress
  else
    NodeObj.AddItem(TogsProperty.Create('progress', TogsPropFloat.Create(Progress)));
    
  // Если прогресс достиг 100%, устанавливаем время окончания
  if Progress >= 1.0 then begin
    if AssignedProps(NodeObj.ItemByName['endproc']) then
      NodeObj.ItemByName['endproc'].AsString := FormatDateTime('dd.mm.yyyy hh:nn:ss', Now)
    else
      NodeObj.AddItem(TogsProperty.Create('endproc', TogsPropString.Create(FormatDateTime('dd.mm.yyyy hh:nn:ss', Now))));
  end;
end;

end.
