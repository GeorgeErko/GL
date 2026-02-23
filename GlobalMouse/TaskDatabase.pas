unit TaskDatabase;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, JSON, fpjson, jsonparser;

type
  // Статусы задач
  TTaskStatus = (tsNotStarted, tsInProgress, tsCompleted, tsBlocked, tsOnHold);
  
  // Приоритеты
  TTaskPriority = (tpLow, tpNormal, tpHigh, tpCritical);
  
  // Тема (верхний уровень)
  TTheme = record
    ID: string;
    Title: string;
    Description: string;
    CreatedDate: TDateTime;
    GitHubRepo: string;
    Color: string; // Для визуализации в TTreeView
  end;
  
  // Задача (средний уровень)
  TTask = record
    ID: string;
    ThemeID: string;
    Title: string;
    Description: string;
    Status: TTaskStatus;
    Priority: TTaskPriority;
    Progress: Integer; // 0-100%
    CreatedDate: TDateTime;
    DueDate: TDateTime;
    AssignedTo: string; // Исполнитель или агент
    GitHubPath: string; // Путь к файлам в репозитории
    EstimatedHours: Double;
    ActualHours: Double;
  end;
  
  // Подзадача (нижний уровень)
  TSubTask = record
    ID: string;
    TaskID: string;
    Title: string;
    Description: string;
    Status: TTaskStatus;
    Progress: Integer; // 0-100%
    CreatedDate: TDateTime;
    CompletedDate: TDateTime;
    GitHubFile: string; // Конкретный файл в репозитории
  end;
  
  // База данных задач
  TTaskDatabase = class
  private
    fThemes: array of TTheme;
    fTasks: array of TTask;
    fSubTasks: array of TSubTask;
    fFileName: string;
    
    function GetStatusString(Status: TTaskStatus): string;
    function GetPriorityString(Priority: TTaskPriority): string;
    function FindThemeByID(const ID: string): Integer;
    function FindTaskByID(const ID: string): Integer;
    function FindSubTaskByID(const ID: string): Integer;
    
  public
    constructor Create(const FileName: string = '');
    destructor Destroy; override;
    
    // Работа с темами
    function AddTheme(const Theme: TTheme): Boolean;
    function UpdateTheme(const Theme: TTheme): Boolean;
    function DeleteTheme(const ThemeID: string): Boolean;
    function GetTheme(const ThemeID: string): TTheme;
    function GetAllThemes: TArray<TTheme>;
    
    // Работа с задачами
    function AddTask(const Task: TTask): Boolean;
    function UpdateTask(const Task: TTask): Boolean;
    function DeleteTask(const TaskID: string): Boolean;
    function GetTask(const TaskID: string): TTask;
    function GetTasksByTheme(const ThemeID: string): TArray<TTask>;
    
    // Работа с подзадачами
    function AddSubTask(const SubTask: TSubTask): Boolean;
    function UpdateSubTask(const SubTask: TSubTask): Boolean;
    function DeleteSubTask(const SubTaskID: string): Boolean;
    function GetSubTask(const SubTaskID: string): TSubTask;
    function GetSubTasksByTask(const TaskID: string): TArray<TSubTask>;
    
    // Прогресс и статистика
    function CalculateTaskProgress(const TaskID: string): Integer;
    function CalculateThemeProgress(const ThemeID: string): Integer;
    function GetOverallProgress: Integer;
    function GetTasksByStatus(Status: TTaskStatus): TArray<TTask>;
    
    // Работа с файлами
    function LoadFromFile(const FileName: string): Boolean;
    function SaveToFile(const FileName: string): Boolean;
    function ExportToJSON: string;
    function ImportFromJSON(const JSONData: string): Boolean;
    
    // GitHub интеграция
    function GetGitHubPath(const TaskID: string): string;
    function SetGitHubPath(const TaskID, Path: string): Boolean;
    function GetGitHubFile(const SubTaskID: string): string;
  end;

implementation

{ TTaskDatabase }

constructor TTaskDatabase.Create(const FileName: string);
begin
  inherited Create;
  fFileName := FileName;
  SetLength(fThemes, 0);
  SetLength(fTasks, 0);
  SetLength(fSubTasks, 0);
  
  if (FileName <> '') and FileExists(FileName) then
    LoadFromFile(FileName);
end;

destructor TTaskDatabase.Destroy;
begin
  if (fFileName <> '') then
    SaveToFile(fFileName);
  inherited Destroy;
end;

function TTaskDatabase.GetStatusString(Status: TTaskStatus): string;
begin
  case Status of
    tsNotStarted: Result := 'Not Started';
    tsInProgress: Result := 'In Progress';
    tsCompleted: Result := 'Completed';
    tsBlocked: Result := 'Blocked';
    tsOnHold: Result := 'On Hold';
  end;
end;

function TTaskDatabase.GetPriorityString(Priority: TTaskPriority): string;
begin
  case Priority of
    tpLow: Result := 'Low';
    tpNormal: Result := 'Normal';
    tpHigh: Result := 'High';
    tpCritical: Result := 'Critical';
  end;
end;

function TTaskDatabase.FindThemeByID(const ID: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(fThemes) do
    if fThemes[i].ID = ID then begin
      Result := i;
      Exit;
    end;
end;

function TTaskDatabase.FindTaskByID(const ID: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(fTasks) do
    if fTasks[i].ID = ID then begin
      Result := i;
      Exit;
    end;
end;

function TTaskDatabase.FindSubTaskByID(const ID: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(fSubTasks) do
    if fSubTasks[i].ID = ID then begin
      Result := i;
      Exit;
    end;
end;

function TTaskDatabase.AddTheme(const Theme: TTheme): Boolean;
var
  NewLength: Integer;
begin
  if FindThemeByID(Theme.ID) <> -1 then begin
    WriteLn('Error: Theme with ID ' + Theme.ID + ' already exists');
    Exit(False);
  end;
  
  NewLength := Length(fThemes) + 1;
  SetLength(fThemes, NewLength);
  fThemes[NewLength - 1] := Theme;
  
  WriteLn('Theme "' + Theme.Title + '" added');
  Result := True;
end;

function TTaskDatabase.UpdateTheme(const Theme: TTheme): Boolean;
var
  Index: Integer;
begin
  Index := FindThemeByID(Theme.ID);
  if Index = -1 then begin
    WriteLn('Error: Theme with ID ' + Theme.ID + ' not found');
    Exit(False);
  end;
  
  fThemes[Index] := Theme;
  WriteLn('Theme "' + Theme.Title + '" updated');
  Result := True;
end;

function TTaskDatabase.DeleteTheme(const ThemeID: string): Boolean;
var
  Index, i: Integer;
begin
  Index := FindThemeByID(ThemeID);
  if Index = -1 then begin
    WriteLn('Error: Theme with ID ' + ThemeID + ' not found');
    Exit(False);
  end;
  
  // Удаляем все задачи этой темы
  for i := Length(fTasks) - 1 downto 0 do
    if fTasks[i].ThemeID = ThemeID then
      DeleteTask(fTasks[i].ID);
  
  // Удаляем тему
  for i := Index to High(fThemes) - 1 do
    fThemes[i] := fThemes[i + 1];
    
  SetLength(fThemes, Length(fThemes) - 1);
  WriteLn('Theme with ID ' + ThemeID + ' deleted');
  Result := True;
end;

function TTaskDatabase.GetTheme(const ThemeID: string): TTheme;
var
  Index: Integer;
begin
  Index := FindThemeByID(ThemeID);
  if Index = -1 then begin
    Result.ID := '';
    Exit;
  end;
  
  Result := fThemes[Index];
end;

function TTaskDatabase.GetAllThemes: TArray<TTheme>;
begin
  Result := Copy(fThemes, 0, Length(fThemes));
end;

function TTaskDatabase.AddTask(const Task: TTask): Boolean;
var
  NewLength: Integer;
begin
  if FindTaskByID(Task.ID) <> -1 then begin
    WriteLn('Error: Task with ID ' + Task.ID + ' already exists');
    Exit(False);
  end;
  
  // Проверяем существование темы
  if FindThemeByID(Task.ThemeID) = -1 then begin
    WriteLn('Error: Theme with ID ' + Task.ThemeID + ' not found');
    Exit(False);
  end;
  
  NewLength := Length(fTasks) + 1;
  SetLength(fTasks, NewLength);
  fTasks[NewLength - 1] := Task;
  
  WriteLn('Task "' + Task.Title + '" added');
  Result := True;
end;

function TTaskDatabase.UpdateTask(const Task: TTask): Boolean;
var
  Index: Integer;
begin
  Index := FindTaskByID(Task.ID);
  if Index = -1 then begin
    WriteLn('Error: Task with ID ' + Task.ID + ' not found');
    Exit(False);
  end;
  
  fTasks[Index] := Task;
  WriteLn('Task "' + Task.Title + '" updated');
  Result := True;
end;

function TTaskDatabase.DeleteTask(const TaskID: string): Boolean;
var
  Index, i: Integer;
begin
  Index := FindTaskByID(TaskID);
  if Index = -1 then begin
    WriteLn('Error: Task with ID ' + TaskID + ' not found');
    Exit(False);
  end;
  
  // Удаляем все подзадачи
  for i := Length(fSubTasks) - 1 downto 0 do
    if fSubTasks[i].TaskID = TaskID then
      DeleteSubTask(fSubTasks[i].ID);
  
  // Удаляем задачу
  for i := Index to High(fTasks) - 1 do
    fTasks[i] := fTasks[i + 1];
    
  SetLength(fTasks, Length(fTasks) - 1);
  WriteLn('Task with ID ' + TaskID + ' deleted');
  Result := True;
end;

function TTaskDatabase.GetTask(const TaskID: string): TTask;
var
  Index: Integer;
begin
  Index := FindTaskByID(TaskID);
  if Index = -1 then begin
    Result.ID := '';
    Exit;
  end;
  
  Result := fTasks[Index];
end;

function TTaskDatabase.GetTasksByTheme(const ThemeID: string): TArray<TTask>;
var
  i, Count: Integer;
begin
  Count := 0;
  for i := 0 to High(fTasks) do
    if fTasks[i].ThemeID = ThemeID then
      Inc(Count);
      
  SetLength(Result, Count);
  Count := 0;
  for i := 0 to High(fTasks) do
    if fTasks[i].ThemeID = ThemeID then begin
      Result[Count] := fTasks[i];
      Inc(Count);
    end;
end;

function TTaskDatabase.AddSubTask(const SubTask: TSubTask): Boolean;
var
  NewLength: Integer;
begin
  if FindSubTaskByID(SubTask.ID) <> -1 then begin
    WriteLn('Error: SubTask with ID ' + SubTask.ID + ' already exists');
    Exit(False);
  end;
  
  // Проверяем существование задачи
  if FindTaskByID(SubTask.TaskID) = -1 then begin
    WriteLn('Error: Task with ID ' + SubTask.TaskID + ' not found');
    Exit(False);
  end;
  
  NewLength := Length(fSubTasks) + 1;
  SetLength(fSubTasks, NewLength);
  fSubTasks[NewLength - 1] := SubTask;
  
  WriteLn('SubTask "' + SubTask.Title + '" added');
  Result := True;
end;

function TTaskDatabase.UpdateSubTask(const SubTask: TSubTask): Boolean;
var
  Index: Integer;
begin
  Index := FindSubTaskByID(SubTask.ID);
  if Index = -1 then begin
    WriteLn('Error: SubTask with ID ' + SubTask.ID + ' not found');
    Exit(False);
  end;
  
  fSubTasks[Index] := SubTask;
  WriteLn('SubTask "' + SubTask.Title + '" updated');
  Result := True;
end;

function TTaskDatabase.DeleteSubTask(const SubTaskID: string): Boolean;
var
  Index, i: Integer;
begin
  Index := FindSubTaskByID(SubTaskID);
  if Index = -1 then begin
    WriteLn('Error: SubTask with ID ' + SubTaskID + ' not found');
    Exit(False);
  end;
  
  for i := Index to High(fSubTasks) - 1 do
    fSubTasks[i] := fSubTasks[i + 1];
    
  SetLength(fSubTasks, Length(fSubTasks) - 1);
  WriteLn('SubTask with ID ' + SubTaskID + ' deleted');
  Result := True;
end;

function TTaskDatabase.GetSubTask(const SubTaskID: string): TSubTask;
var
  Index: Integer;
begin
  Index := FindSubTaskByID(SubTaskID);
  if Index = -1 then begin
    Result.ID := '';
    Exit;
  end;
  
  Result := fSubTasks[Index];
end;

function TTaskDatabase.GetSubTasksByTask(const TaskID: string): TArray<TSubTask>;
var
  i, Count: Integer;
begin
  Count := 0;
  for i := 0 to High(fSubTasks) do
    if fSubTasks[i].TaskID = TaskID then
      Inc(Count);
      
  SetLength(Result, Count);
  Count := 0;
  for i := 0 to High(fSubTasks) do
    if fSubTasks[i].TaskID = TaskID then begin
      Result[Count] := fSubTasks[i];
      Inc(Count);
    end;
end;

function TTaskDatabase.CalculateTaskProgress(const TaskID: string): Integer;
var
  SubTasks: TArray<TSubTask>;
  i, TotalProgress: Integer;
begin
  SubTasks := GetSubTasksByTask(TaskID);
  
  if Length(SubTasks) = 0 then begin
    // Если нет подзадач, возвращаем прогресс самой задачи
    var Task := GetTask(TaskID);
    if Task.ID <> '' then
      Exit(Task.Progress)
    else
      Exit(0);
  end;
  
  TotalProgress := 0;
  for i := 0 to High(SubTasks) do
    TotalProgress := TotalProgress + SubTasks[i].Progress;
    
  Result := TotalProgress div Length(SubTasks);
end;

function TTaskDatabase.CalculateThemeProgress(const ThemeID: string): Integer;
var
  Tasks: TArray<TTask>;
  i, TotalProgress: Integer;
begin
  Tasks := GetTasksByTheme(ThemeID);
  
  if Length(Tasks) = 0 then Exit(0);
  
  TotalProgress := 0;
  for i := 0 to High(Tasks) do
    TotalProgress := TotalProgress + CalculateTaskProgress(Tasks[i].ID);
    
  Result := TotalProgress div Length(Tasks);
end;

function TTaskDatabase.GetOverallProgress: Integer;
var
  i, TotalProgress: Integer;
begin
  if Length(fThemes) = 0 then Exit(0);
  
  TotalProgress := 0;
  for i := 0 to High(fThemes) do
    TotalProgress := TotalProgress + CalculateThemeProgress(fThemes[i].ID);
    
  Result := TotalProgress div Length(fThemes);
end;

function TTaskDatabase.GetTasksByStatus(Status: TTaskStatus): TArray<TTask>;
var
  i, Count: Integer;
begin
  Count := 0;
  for i := 0 to High(fTasks) do
    if fTasks[i].Status = Status then
      Inc(Count);
      
  SetLength(Result, Count);
  Count := 0;
  for i := 0 to High(fTasks) do
    if fTasks[i].Status = Status then begin
      Result[Count] := fTasks[i];
      Inc(Count);
    end;
end;

function TTaskDatabase.LoadFromFile(const FileName: string): Boolean;
var
  JSONData: string;
  JSONObj: TJSONObject;
  ThemesArray, TasksArray, SubTasksArray: TJSONArray;
  i: Integer;
  Theme: TTheme;
  Task: TTask;
  SubTask: TSubTask;
begin
  if not FileExists(FileName) then begin
    WriteLn('File ' + FileName + ' not found, creating new database');
    Result := True;
    Exit;
  end;
  
  try
    with TStringList.Create do begin
      LoadFromFile(FileName);
      JSONData := Text;
      Free;
    end;
    
    JSONObj := TJSONObject.Parse(JSONData) as TJSONObject;
    
    // Загружаем темы
    SetLength(fThemes, 0);
    ThemesArray := JSONObj.Get('themes') as TJSONArray;
    for i := 0 to ThemesArray.Count - 1 do begin
      var ThemeObj := ThemesArray[i] as TJSONObject;
      Theme.ID := ThemeObj.Get('id');
      Theme.Title := ThemeObj.Get('title');
      Theme.Description := ThemeObj.Get('description');
      Theme.CreatedDate := StrToDateTimeDef(ThemeObj.Get('createdDate'), Now);
      Theme.GitHubRepo := ThemeObj.Get('gitHubRepo');
      Theme.Color := ThemeObj.Get('color', '#0078D4');
      AddTheme(Theme);
    end;
    
    // Загружаем задачи
    SetLength(fTasks, 0);
    TasksArray := JSONObj.Get('tasks') as TJSONArray;
    for i := 0 to TasksArray.Count - 1 do begin
      var TaskObj := TasksArray[i] as TJSONObject;
      Task.ID := TaskObj.Get('id');
      Task.ThemeID := TaskObj.Get('themeId');
      Task.Title := TaskObj.Get('title');
      Task.Description := TaskObj.Get('description');
      Task.Status := TTaskStatus(StrToIntDef(TaskObj.Get('status'), 0));
      Task.Priority := TTaskPriority(StrToIntDef(TaskObj.Get('priority'), 1));
      Task.Progress := StrToIntDef(TaskObj.Get('progress'), 0);
      Task.CreatedDate := StrToDateTimeDef(TaskObj.Get('createdDate'), Now);
      Task.DueDate := StrToDateTimeDef(TaskObj.Get('dueDate'), Now + 7);
      Task.AssignedTo := TaskObj.Get('assignedTo', 'Unassigned');
      Task.GitHubPath := TaskObj.Get('gitHubPath');
      Task.EstimatedHours := StrToFloatDef(TaskObj.Get('estimatedHours'), 0);
      Task.ActualHours := StrToFloatDef(TaskObj.Get('actualHours'), 0);
      AddTask(Task);
    end;
    
    // Загружаем подзадачи
    SetLength(fSubTasks, 0);
    SubTasksArray := JSONObj.Get('subTasks') as TJSONArray;
    for i := 0 to SubTasksArray.Count - 1 do begin
      var SubTaskObj := SubTasksArray[i] as TJSONObject;
      SubTask.ID := SubTaskObj.Get('id');
      SubTask.TaskID := SubTaskObj.Get('taskId');
      SubTask.Title := SubTaskObj.Get('title');
      SubTask.Description := SubTaskObj.Get('description');
      SubTask.Status := TTaskStatus(StrToIntDef(SubTaskObj.Get('status'), 0));
      SubTask.Progress := StrToIntDef(SubTaskObj.Get('progress'), 0);
      SubTask.CreatedDate := StrToDateTimeDef(SubTaskObj.Get('createdDate'), Now);
      SubTask.CompletedDate := StrToDateTimeDef(SubTaskObj.Get('completedDate'), 0);
      SubTask.GitHubFile := SubTaskObj.Get('gitHubFile');
      AddSubTask(SubTask);
    end;
    
    JSONObj.Free;
    WriteLn('Database loaded from ' + FileName);
    Result := True;
  except
    on E: Exception do begin
      WriteLn('Error loading database: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TTaskDatabase.SaveToFile(const FileName: string): Boolean;
var
  JSONObj: TJSONObject;
  ThemesArray, TasksArray, SubTasksArray: TJSONArray;
  i: Integer;
  ThemeObj, TaskObj, SubTaskObj: TJSONObject;
begin
  try
    JSONObj := TJSONObject.Create;
    
    // Сохраняем темы
    ThemesArray := TJSONArray.Create;
    for i := 0 to High(fThemes) do begin
      ThemeObj := TJSONObject.Create;
      ThemeObj.Add('id', fThemes[i].ID);
      ThemeObj.Add('title', fThemes[i].Title);
      ThemeObj.Add('description', fThemes[i].Description);
      ThemeObj.Add('createdDate', DateTimeToStr(fThemes[i].CreatedDate));
      ThemeObj.Add('gitHubRepo', fThemes[i].GitHubRepo);
      ThemeObj.Add('color', fThemes[i].Color);
      ThemesArray.Add(ThemeObj);
    end;
    JSONObj.Add('themes', ThemesArray);
    
    // Сохраняем задачи
    TasksArray := TJSONArray.Create;
    for i := 0 to High(fTasks) do begin
      TaskObj := TJSONObject.Create;
      TaskObj.Add('id', fTasks[i].ID);
      TaskObj.Add('themeId', fTasks[i].ThemeID);
      TaskObj.Add('title', fTasks[i].Title);
      TaskObj.Add('description', fTasks[i].Description);
      TaskObj.Add('status', Ord(fTasks[i].Status));
      TaskObj.Add('priority', Ord(fTasks[i].Priority));
      TaskObj.Add('progress', fTasks[i].Progress);
      TaskObj.Add('createdDate', DateTimeToStr(fTasks[i].CreatedDate));
      TaskObj.Add('dueDate', DateTimeToStr(fTasks[i].DueDate));
      TaskObj.Add('assignedTo', fTasks[i].AssignedTo);
      TaskObj.Add('gitHubPath', fTasks[i].GitHubPath);
      TaskObj.Add('estimatedHours', fTasks[i].EstimatedHours);
      TaskObj.Add('actualHours', fTasks[i].ActualHours);
      TasksArray.Add(TaskObj);
    end;
    JSONObj.Add('tasks', TasksArray);
    
    // Сохраняем подзадачи
    SubTasksArray := TJSONArray.Create;
    for i := 0 to High(fSubTasks) do begin
      SubTaskObj := TJSONObject.Create;
      SubTaskObj.Add('id', fSubTasks[i].ID);
      SubTaskObj.Add('taskId', fSubTasks[i].TaskID);
      SubTaskObj.Add('title', fSubTasks[i].Title);
      SubTaskObj.Add('description', fSubTasks[i].Description);
      SubTaskObj.Add('status', Ord(fSubTasks[i].Status));
      SubTaskObj.Add('progress', fSubTasks[i].Progress);
      SubTaskObj.Add('createdDate', DateTimeToStr(fSubTasks[i].CreatedDate));
      SubTaskObj.Add('completedDate', DateTimeToStr(fSubTasks[i].CompletedDate));
      SubTaskObj.Add('gitHubFile', fSubTasks[i].GitHubFile);
      SubTasksArray.Add(SubTaskObj);
    end;
    JSONObj.Add('subTasks', SubTasksArray);
    
    with TStringList.Create do begin
      Text := JSONObj.FormatJSON();
      SaveToFile(FileName);
      Free;
    end;
    
    JSONObj.Free;
    WriteLn('Database saved to ' + FileName);
    Result := True;
  except
    on E: Exception do begin
      WriteLn('Error saving database: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TTaskDatabase.ExportToJSON: string;
var
  JSONObj: TJSONObject;
begin
  // Создаем временный JSON объект
  JSONObj := TJSONObject.Create;
  try
    // Здесь можно добавить экспорт в нужном формате
    Result := JSONObj.AsJSON;
  finally
    JSONObj.Free;
  end;
end;

function TTaskDatabase.ImportFromJSON(const JSONData: string): Boolean;
begin
  // Импорт из JSON строки
  Result := True;
end;

function TTaskDatabase.GetGitHubPath(const TaskID: string): string;
var
  Task: TTask;
begin
  Task := GetTask(TaskID);
  if Task.ID <> '' then
    Result := Task.GitHubPath
  else
    Result := '';
end;

function TTaskDatabase.SetGitHubPath(const TaskID, Path: string): Boolean;
var
  Task: TTask;
begin
  Task := GetTask(TaskID);
  if Task.ID = '' then Exit(False);
  
  Task.GitHubPath := Path;
  Result := UpdateTask(Task);
end;

function TTaskDatabase.GetGitHubFile(const SubTaskID: string): string;
var
  SubTask: TSubTask;
begin
  SubTask := GetSubTask(SubTaskID);
  if SubTask.ID <> '' then
    Result := SubTask.GitHubFile
  else
    Result := '';
end;

end.
