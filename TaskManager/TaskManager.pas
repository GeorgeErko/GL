unit TaskManager;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, DateUtils, Variants;

type
  // Статусы задач
  TTaskStatus = (tsNotStarted, tsInProgress, tsCompleted, tsBlocked, tsOnHold);
  
  // Приоритеты
  TTaskPriority = (tpLow, tpNormal, tpHigh, tpCritical);
  
  // Подзадача
  TSubTask = record
    ID: string;
    Title: string;
    Description: string;
    Progress: Integer; // 0-100%
    Status: TTaskStatus;
    AssignedTo: string;
    DueDate: TDateTime;
    CreatedDate: TDateTime;
    EstimatedHours: Double;
    ActualHours: Double;
  end;
  
  // Основная задача
  TTask = record
    ID: string;
    Title: string;
    Description: string;
    Progress: Integer; // 0-100%
    Status: TTaskStatus;
    Priority: TTaskPriority;
    SubTasks: array of TSubTask;
    CreatedDate: TDateTime;
    DueDate: TDateTime;
    AssignedTo: string;
    Project: string;
    Tags: string;
  end;
  
  // Менеджер задач с Excel интеграцией
  TTaskManager = class
  private
    fTasks: array of TTask;
    fFileName: string;
    
    function GetStatusString(Status: TTaskStatus): string;
    function GetPriorityString(Priority: TTaskPriority): string;
    function CalculateTaskProgress(const Task: TTask): Integer;
    function FindTaskByID(const ID: string): Integer;
    function FindSubTaskByID(const TaskID, SubTaskID: string): Integer;
    function EscapeCSV(const Value: string): string;
    
  public
    constructor Create(const FileName: string = '');
    destructor Destroy; override;
    
    // Управление задачами
    function AddTask(const Task: TTask): Boolean;
    function UpdateTask(const Task: TTask): Boolean;
    function DeleteTask(const TaskID: string): Boolean;
    function GetTask(const TaskID: string): TTask;
    
    // Управление подзадачами
    function AddSubTask(const TaskID: string; const SubTask: TSubTask): Boolean;
    function UpdateSubTask(const TaskID: string; const SubTask: TSubTask): Boolean;
    function DeleteSubTask(const TaskID, SubTaskID: string): Boolean;
    
    // Обновление прогресса
    function UpdateSubTaskProgress(const TaskID, SubTaskID: string; Progress: Integer): Boolean;
    function UpdateTaskProgress(const TaskID: string; Progress: Integer): Boolean;
    function GetTaskProgress(const TaskID: string): Integer;
    
    // Excel операции
    function LoadFromExcel(const FileName: string): Boolean;
    function SaveToExcel(const FileName: string): Boolean;
    function ExportProgressReport(const FileName: string): Boolean;
    function ImportFromCSV(const FileName: string): Boolean;
    
    // Аналитика
    function GetCompletedTasksCount: Integer;
    function GetInProgressTasksCount: Integer;
    function GetOverdueTasksCount: Integer;
    function GetTotalProgress: Integer;
    
    // Отображение
    procedure DisplayAllTasks;
    procedure DisplayTaskDetails(const TaskID: string);
    procedure DisplayProgressReport;
  end;

implementation

{ TTaskManager }

constructor TTaskManager.Create(const FileName: string);
begin
  inherited Create;
  fFileName := FileName;
  SetLength(fTasks, 0);
  
  if (FileName <> '') and FileExists(FileName) then
    LoadFromExcel(FileName);
end;

destructor TTaskManager.Destroy;
begin
  if (fFileName <> '') then
    SaveToExcel(fFileName);
  inherited Destroy;
end;

function TTaskManager.GetStatusString(Status: TTaskStatus): string;
begin
  case Status of
    tsNotStarted: Result := 'Not Started';
    tsInProgress: Result := 'In Progress';
    tsCompleted: Result := 'Completed';
    tsBlocked: Result := 'Blocked';
    tsOnHold: Result := 'On Hold';
  end;
end;

function TTaskManager.GetPriorityString(Priority: TTaskPriority): string;
begin
  case Priority of
    tpLow: Result := 'Low';
    tpNormal: Result := 'Normal';
    tpHigh: Result := 'High';
    tpCritical: Result := 'Critical';
  end;
end;

function TTaskManager.CalculateTaskProgress(const Task: TTask): Integer;
var
  i, TotalProgress: Integer;
begin
  if Length(Task.SubTasks) = 0 then
    Exit(Task.Progress);
    
  TotalProgress := 0;
  for i := 0 to High(Task.SubTasks) do
    TotalProgress := TotalProgress + Task.SubTasks[i].Progress;
    
  Result := TotalProgress div Length(Task.SubTasks);
end;

function TTaskManager.FindTaskByID(const ID: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(fTasks) do begin
    if fTasks[i].ID = ID then begin
      Result := i;
      Exit;
    end;
  end;
end;

function TTaskManager.FindSubTaskByID(const TaskID, SubTaskID: string): Integer;
var
  TaskIndex, i: Integer;
begin
  Result := -1;
  TaskIndex := FindTaskByID(TaskID);
  if TaskIndex = -1 then Exit;
  
  for i := 0 to High(fTasks[TaskIndex].SubTasks) do begin
    if fTasks[TaskIndex].SubTasks[i].ID = SubTaskID then begin
      Result := i;
      Exit;
    end;
  end;
end;

function TTaskManager.EscapeCSV(const Value: string): string;
begin
  Result := StringReplace(Value, '"', '""', [rfReplaceAll]);
  if (Pos(';', Result) > 0) or (Pos('"', Result) > 0) or (Pos(#10, Result) > 0) then
    Result := '"' + Result + '"';
end;

function TTaskManager.AddTask(const Task: TTask): Boolean;
var
  NewLength: Integer;
begin
  if FindTaskByID(Task.ID) <> -1 then begin
    WriteLn('Error: Task with ID ' + Task.ID + ' already exists');
    Exit(False);
  end;
  
  NewLength := Length(fTasks) + 1;
  SetLength(fTasks, NewLength);
  fTasks[NewLength - 1] := Task;
  
  WriteLn('Task "' + Task.Title + '" added');
  Result := True;
end;

function TTaskManager.UpdateTask(const Task: TTask): Boolean;
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

function TTaskManager.DeleteTask(const TaskID: string): Boolean;
var
  Index, i: Integer;
begin
  Index := FindTaskByID(TaskID);
  if Index = -1 then begin
    WriteLn('Error: Task with ID ' + TaskID + ' not found');
    Exit(False);
  end;
  
  for i := Index to High(fTasks) - 1 do
    fTasks[i] := fTasks[i + 1];
    
  SetLength(fTasks, Length(fTasks) - 1);
  WriteLn('Task with ID ' + TaskID + ' deleted');
  Result := True;
end;

function TTaskManager.GetTask(const TaskID: string): TTask;
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

function TTaskManager.AddSubTask(const TaskID: string; const SubTask: TSubTask): Boolean;
var
  TaskIndex, NewLength: Integer;
begin
  TaskIndex := FindTaskByID(TaskID);
  if TaskIndex = -1 then begin
    WriteLn('Error: Task with ID ' + TaskID + ' not found');
    Exit(False);
  end;
  
  NewLength := Length(fTasks[TaskIndex].SubTasks) + 1;
  SetLength(fTasks[TaskIndex].SubTasks, NewLength);
  fTasks[TaskIndex].SubTasks[NewLength - 1] := SubTask;
  
  WriteLn('Subtask "' + SubTask.Title + '" added to task ' + TaskID);
  Result := True;
end;

function TTaskManager.UpdateSubTask(const TaskID: string; const SubTask: TSubTask): Boolean;
var
  TaskIndex, SubIndex: Integer;
begin
  TaskIndex := FindTaskByID(TaskID);
  if TaskIndex = -1 then begin
    WriteLn('Error: Task with ID ' + TaskID + ' not found');
    Exit(False);
  end;
  
  SubIndex := FindSubTaskByID(TaskID, SubTask.ID);
  if SubIndex = -1 then begin
    WriteLn('Error: Subtask with ID ' + SubTask.ID + ' not found');
    Exit(False);
  end;
  
  fTasks[TaskIndex].SubTasks[SubIndex] := SubTask;
  WriteLn('Subtask "' + SubTask.Title + '" updated');
  Result := True;
end;

function TTaskManager.DeleteSubTask(const TaskID, SubTaskID: string): Boolean;
var
  TaskIndex, SubIndex, i: Integer;
begin
  TaskIndex := FindTaskByID(TaskID);
  if TaskIndex = -1 then begin
    WriteLn('Error: Task with ID ' + TaskID + ' not found');
    Exit(False);
  end;
  
  SubIndex := FindSubTaskByID(TaskID, SubTaskID);
  if SubIndex = -1 then begin
    WriteLn('Error: Subtask with ID ' + SubTaskID + ' not found');
    Exit(False);
  end;
  
  for i := SubIndex to High(fTasks[TaskIndex].SubTasks) - 1 do
    fTasks[TaskIndex].SubTasks[i] := fTasks[TaskIndex].SubTasks[i + 1];
    
  SetLength(fTasks[TaskIndex].SubTasks, Length(fTasks[TaskIndex].SubTasks) - 1);
  WriteLn('Subtask with ID ' + SubTaskID + ' deleted');
  Result := True;
end;

function TTaskManager.UpdateSubTaskProgress(const TaskID, SubTaskID: string; Progress: Integer): Boolean;
var
  TaskIndex, SubIndex: Integer;
  OldProgress: Integer;
begin
  if (Progress < 0) or (Progress > 100) then begin
    WriteLn('Error: Progress must be in range 0-100');
    Exit(False);
  end;
  
  TaskIndex := FindTaskByID(TaskID);
  if TaskIndex = -1 then Exit(False);
  
  SubIndex := FindSubTaskByID(TaskID, SubTaskID);
  if SubIndex = -1 then Exit(False);
  
  OldProgress := fTasks[TaskIndex].SubTasks[SubIndex].Progress;
  fTasks[TaskIndex].SubTasks[SubIndex].Progress := Progress;
  
  // Update status based on progress
  if Progress = 0 then
    fTasks[TaskIndex].SubTasks[SubIndex].Status := tsNotStarted
  else if Progress = 100 then
    fTasks[TaskIndex].SubTasks[SubIndex].Status := tsCompleted
  else
    fTasks[TaskIndex].SubTasks[SubIndex].Status := tsInProgress;
  
  // Recalculate main task progress
  fTasks[TaskIndex].Progress := CalculateTaskProgress(fTasks[TaskIndex]);
  
  WriteLn('Subtask ' + SubTaskID + ' progress changed from ' + 
          IntToStr(OldProgress) + '% to ' + IntToStr(Progress) + '%');
  WriteLn('Total task ' + TaskID + ' progress: ' + IntToStr(fTasks[TaskIndex].Progress) + '%');
  
  Result := True;
end;

function TTaskManager.UpdateTaskProgress(const TaskID: string; Progress: Integer): Boolean;
var
  Index: Integer;
begin
  if (Progress < 0) or (Progress > 100) then begin
    WriteLn('Error: Progress must be in range 0-100');
    Exit(False);
  end;
  
  Index := FindTaskByID(TaskID);
  if Index = -1 then Exit(False);
  
  fTasks[Index].Progress := Progress;
  
  // Update status
  if Progress = 0 then
    fTasks[Index].Status := tsNotStarted
  else if Progress = 100 then
    fTasks[Index].Status := tsCompleted
  else
    fTasks[Index].Status := tsInProgress;
  
  WriteLn('Task ' + TaskID + ' progress set to ' + IntToStr(Progress) + '%');
  Result := True;
end;

function TTaskManager.GetTaskProgress(const TaskID: string): Integer;
var
  Index: Integer;
begin
  Index := FindTaskByID(TaskID);
  if Index = -1 then Exit(0);
  
  Result := CalculateTaskProgress(fTasks[Index]);
end;

function TTaskManager.LoadFromExcel(const FileName: string): Boolean;
var
  CSV: TStringList;
  Line, Cell: string;
  Cells: TStringArray;
  i: Integer;
  Task: TTask;
  SubTask: TSubTask;
begin
  if not FileExists(FileName) then begin
    WriteLn('Error: File ' + FileName + ' not found');
    Exit(False);
  end;
  
  CSV := TStringList.Create;
  try
    CSV.LoadFromFile(FileName);
    
    SetLength(fTasks, 0);
    i := 1; // Skip header
    
    while i < CSV.Count do begin
      Line := CSV[i];
      Cells := Line.Split([';']);
      
      if Length(Cells) >= 10 then begin
        Task.ID := Cells[0];
        Task.Title := Cells[1];
        Task.Description := Cells[2];
        Task.Progress := StrToIntDef(Cells[3], 0);
        Task.Status := TTaskStatus(StrToIntDef(Cells[4], 0));
        Task.Priority := TTaskPriority(StrToIntDef(Cells[5], 1));
        Task.CreatedDate := StrToDateTimeDef(Cells[6], Now);
        Task.DueDate := StrToDateTimeDef(Cells[7], Now + 7);
        Task.AssignedTo := Cells[8];
        Task.Project := Cells[9];
        
        AddTask(Task);
      end;
      
      Inc(i);
    end;
    
    WriteLn('Loaded ' + IntToStr(Length(fTasks)) + ' tasks from file ' + FileName);
    Result := True;
  except
    on E: Exception do begin
      WriteLn('Load error: ' + E.Message);
      Result := False;
    end;
  end;
  CSV.Free;
end;

function TTaskManager.SaveToExcel(const FileName: string): Boolean;
var
  CSV: TStringList;
  Task: TTask;
  i: Integer;
begin
  CSV := TStringList.Create;
  try
    // Headers
    CSV.Add('ID;Title;Description;Progress;Status;Priority;CreatedDate;DueDate;AssignedTo;Project');
    
    // Data
    for i := 0 to High(fTasks) do begin
      Task := fTasks[i];
      CSV.Add(
        EscapeCSV(Task.ID) + ';' +
        EscapeCSV(Task.Title) + ';' +
        EscapeCSV(Task.Description) + ';' +
        IntToStr(Task.Progress) + ';' +
        IntToStr(Ord(Task.Status)) + ';' +
        IntToStr(Ord(Task.Priority)) + ';' +
        DateTimeToStr(Task.CreatedDate) + ';' +
        DateTimeToStr(Task.DueDate) + ';' +
        EscapeCSV(Task.AssignedTo) + ';' +
        EscapeCSV(Task.Project)
      );
    end;
    
    CSV.SaveToFile(FileName);
    WriteLn('Saved ' + IntToStr(Length(fTasks)) + ' tasks to file ' + FileName);
    Result := True;
  except
    on E: Exception do begin
      WriteLn('Save error: ' + E.Message);
      Result := False;
    end;
  end;
  CSV.Free;
end;

function TTaskManager.ExportProgressReport(const FileName: string): Boolean;
var
  CSV: TStringList;
  Task: TTask;
  SubTask: TSubTask;
  i, j: Integer;
begin
  CSV := TStringList.Create;
  try
    // Заголовки детального отчета
    CSV.Add('TaskID;TaskTitle;TaskProgress;SubTaskID;SubTaskTitle;SubTaskProgress;Status;AssignedTo;DueDate;CreatedDate');
    
    // Данные по всем подзадачам
    for i := 0 to High(fTasks) do begin
      Task := fTasks[i];
      
      if Length(Task.SubTasks) = 0 then begin
        // Задача без подзадач
        CSV.Add(
          EscapeCSV(Task.ID) + ';' +
          EscapeCSV(Task.Title) + ';' +
          IntToStr(Task.Progress) + ';' +
          ';;' +
          GetStatusString(Task.Status) + ';' +
          EscapeCSV(Task.AssignedTo) + ';' +
          DateTimeToStr(Task.DueDate) + ';' +
          DateTimeToStr(Task.CreatedDate)
        );
      end else begin
        // Задача с подзадачами
        for j := 0 to High(Task.SubTasks) do begin
          SubTask := Task.SubTasks[j];
          CSV.Add(
            EscapeCSV(Task.ID) + ';' +
            EscapeCSV(Task.Title) + ';' +
            IntToStr(CalculateTaskProgress(Task)) + ';' +
            EscapeCSV(SubTask.ID) + ';' +
            EscapeCSV(SubTask.Title) + ';' +
            IntToStr(SubTask.Progress) + ';' +
            GetStatusString(SubTask.Status) + ';' +
            EscapeCSV(SubTask.AssignedTo) + ';' +
            DateTimeToStr(SubTask.DueDate) + ';' +
            DateTimeToStr(SubTask.CreatedDate)
          );
        end;
      end;
    end;
    
    CSV.SaveToFile(FileName);
    WriteLn('Отчет о прогрессе сохранен в ' + FileName);
    Result := True;
  except
    on E: Exception do begin
      WriteLn('Ошибка экспорта отчета: ' + E.Message);
      Result := False;
    end;
  end;
  CSV.Free;
end;

function TTaskManager.ImportFromCSV(const FileName: string): Boolean;
begin
  Result := LoadFromExcel(FileName);
end;

function TTaskManager.GetCompletedTasksCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(fTasks) do
    if fTasks[i].Status = tsCompleted then
      Inc(Result);
end;

function TTaskManager.GetInProgressTasksCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(fTasks) do
    if fTasks[i].Status = tsInProgress then
      Inc(Result);
end;

function TTaskManager.GetOverdueTasksCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(fTasks) do
    if (fTasks[i].DueDate < Now) and (fTasks[i].Status <> tsCompleted) then
      Inc(Result);
end;

function TTaskManager.GetTotalProgress: Integer;
var
  i, TotalProgress: Integer;
begin
  if Length(fTasks) = 0 then Exit(0);
  
  TotalProgress := 0;
  for i := 0 to High(fTasks) do
    TotalProgress := TotalProgress + fTasks[i].Progress;
    
  Result := TotalProgress div Length(fTasks);
end;

procedure TTaskManager.DisplayAllTasks;
var
  Task: TTask;
  i: Integer;
  ProgressBar: string;
begin
  WriteLn('=== ALL TASKS ===');
  WriteLn;
  
  for i := 0 to High(fTasks) do begin
    Task := fTasks[i];
    WriteLn('ID: ' + Task.ID);
    WriteLn('Title: ' + Task.Title);
    WriteLn('Status: ' + GetStatusString(Task.Status));
    WriteLn('Priority: ' + GetPriorityString(Task.Priority));
    WriteLn('Progress: ' + IntToStr(Task.Progress) + '%');
    
    // Visual progress bar
    ProgressBar := StringOfChar('|', Task.Progress div 5) +
                  StringOfChar('0', 20 - (Task.Progress div 5));
    WriteLn('[' + ProgressBar + ']');
    
    WriteLn('Assigned to: ' + Task.AssignedTo);
    WriteLn('Project: ' + Task.Project);
    WriteLn('Due date: ' + DateTimeToStr(Task.DueDate));
    WriteLn('Subtasks: ' + IntToStr(Length(Task.SubTasks)));
    WriteLn(StringOfChar('-', 50));
  end;
end;

procedure TTaskManager.DisplayTaskDetails(const TaskID: string);
var
  Task: TTask;
  SubTask: TSubTask;
  i: Integer;
  ProgressBar: string;
begin
  Task := GetTask(TaskID);
  if Task.ID = '' then begin
    WriteLn('Task with ID ' + TaskID + ' not found');
    Exit;
  end;
  
  WriteLn('=== TASK DETAILS ===');
  WriteLn('ID: ' + Task.ID);
  WriteLn('Title: ' + Task.Title);
  WriteLn('Description: ' + Task.Description);
  WriteLn('Status: ' + GetStatusString(Task.Status));
  WriteLn('Priority: ' + GetPriorityString(Task.Priority));
  WriteLn('Progress: ' + IntToStr(Task.Progress) + '%');
  
  ProgressBar := StringOfChar('1', Task.Progress div 5) +
                StringOfChar('0', 20 - (Task.Progress div 5));
  WriteLn('[' + ProgressBar + ']');
  
  WriteLn('Assigned to: ' + Task.AssignedTo);
  WriteLn('Project: ' + Task.Project);
  WriteLn('Created: ' + DateTimeToStr(Task.CreatedDate));
  WriteLn('Due date: ' + DateTimeToStr(Task.DueDate));
  WriteLn;
  
  if Length(Task.SubTasks) > 0 then begin
    WriteLn('=== SUBTASKS ===');
    for i := 0 to High(Task.SubTasks) do begin
      SubTask := Task.SubTasks[i];
      WriteLn('ID: ' + SubTask.ID);
      WriteLn('Title: ' + SubTask.Title);
      WriteLn('Description: ' + SubTask.Description);
      WriteLn('Status: ' + GetStatusString(SubTask.Status));
      WriteLn('Progress: ' + IntToStr(SubTask.Progress) + '%');
      
      ProgressBar := StringOfChar('1', SubTask.Progress div 5) +
                    StringOfChar('0', 20 - (SubTask.Progress div 5));
      WriteLn('[' + ProgressBar + ']');
      
      WriteLn('Assigned to: ' + SubTask.AssignedTo);
      WriteLn('Due date: ' + DateTimeToStr(SubTask.DueDate));
      WriteLn('Estimated hours: ' + FloatToStr(SubTask.EstimatedHours) + 'h');
      WriteLn('Actual hours: ' + FloatToStr(SubTask.ActualHours) + 'h');
      WriteLn(StringOfChar('-', 30));
    end;
  end;
end;

procedure TTaskManager.DisplayProgressReport;
var
  Completed, InProgress, Overdue, Total: Integer;
begin
  WriteLn('=== PROGRESS REPORT ===');
  WriteLn;
  
  Completed := GetCompletedTasksCount;
  InProgress := GetInProgressTasksCount;
  Overdue := GetOverdueTasksCount;
  Total := Length(fTasks);
  
  WriteLn('Total tasks: ' + IntToStr(Total));
  WriteLn('Completed: ' + IntToStr(Completed) + ' (' + 
          IntToStr(Round(Completed * 100 / Total)) + '%)');
  WriteLn('In progress: ' + IntToStr(InProgress) + ' (' + 
          IntToStr(Round(InProgress * 100 / Total)) + '%)');
  WriteLn('Overdue: ' + IntToStr(Overdue) + ' (' + 
          IntToStr(Round(Overdue * 100 / Total)) + '%)');
  WriteLn('Overall progress: ' + IntToStr(GetTotalProgress) + '%');
  WriteLn;
  
  if Overdue > 0 then
    WriteLn('WARNING: ' + IntToStr(Overdue) + ' tasks are overdue!');
end;

end.
