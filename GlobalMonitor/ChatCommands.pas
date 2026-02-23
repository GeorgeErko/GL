unit ChatCommands;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, MonitorDatabase;

type
  TChatCommandProcessor = class
  private
    fDatabase: TMonitorDatabase;
    fFileName: string;
    
    procedure ProcessAddCommand(const Entity: string);
    procedure ProcessUpdateCommand(const Entity: string);
    procedure ProcessDeleteCommand(const Entity: string);
    procedure ProcessListCommand(const Entity: string);
    procedure ProcessStatusCommand;
    procedure ProcessProgressCommand;
    procedure ProcessExportCommand;
    
  public
    constructor Create(const FileName: string = 'default.json');
    destructor Destroy; override;
    
    function ExecuteCommand(const Command: string): string;
    procedure LoadDatabase;
    procedure SaveDatabase;
  end;

implementation

{ TChatCommandProcessor }

constructor TChatCommandProcessor.Create(const FileName: string);
begin
  inherited Create;
  fFileName := FileName;
  fDatabase := TMonitorDatabase.Create(FileName);
  LoadDatabase;
end;

destructor TChatCommandProcessor.Destroy;
begin
  SaveDatabase;
  fDatabase.Free;
  inherited Destroy;
end;

procedure TChatCommandProcessor.LoadDatabase;
begin
  fDatabase.LoadFromFile(fFileName);
end;

procedure TChatCommandProcessor.SaveDatabase;
begin
  fDatabase.SaveToFile(fFileName);
end;

procedure TChatCommandProcessor.ProcessAddCommand(const Entity: string);
var
  Parts, ParamParts: TArray<string>;
  Theme: TTheme;
  Task: TTask;
  SubTask: TSubTask;
begin
  if Entity.StartsWith('Theme=') then begin
    var ThemeTitle := Entity.Substring(6);
    Theme.ID := 'THEME' + FormatDateTime('yymmddhhnnss', Now);
    Theme.Title := ThemeTitle;
    Theme.Description := 'Created from chat';
    Theme.CreatedDate := Now;
    Theme.GitHubRepo := 'https://github.com/user/repo';
    Theme.Color := '#0078D4';
    Theme.IsActive := True;
    fDatabase.AddTheme(Theme);
    WriteLn('Theme added: ' + Theme.ID + ' - ' + Theme.Title);
  end else if Entity.StartsWith('Task=') then begin
    ParamParts := Entity.Substring(5).Split(['|']);
    if Length(ParamParts) >= 2 then begin
      var ThemeID := ParamParts[0].Split(['='])[1];
      var TaskTitle := ParamParts[1].Split(['='])[1];
      
      Task.ID := 'TASK' + FormatDateTime('yymmddhhnnss', Now);
      Task.ThemeID := ThemeID;
      Task.Title := TaskTitle;
      Task.Description := 'Created from chat';
      Task.Status := tsNotStarted;
      Task.Priority := tpNormal;
      Task.Progress := 0;
      Task.CreatedDate := Now;
      Task.DueDate := Now + 30;
      Task.AssignedTo := 'Chat User';
      Task.GitHubPath := '/src/' + TaskTitle.ToLower.Replace(' ', '_');
      Task.EstimatedHours := 40;
      Task.ActualHours := 0;
      Task.LastModified := Now;
      
      if fDatabase.AddTask(Task) then
        WriteLn('Task added: ' + Task.ID + ' - ' + Task.Title)
      else
        WriteLn('Failed to add task - Theme not found');
    end;
  end else if Entity.StartsWith('SubTask=') then begin
    ParamParts := Entity.Substring(8).Split(['|']);
    if Length(ParamParts) >= 2 then begin
      var TaskID := ParamParts[0].Split(['='])[1];
      var SubTaskTitle := ParamParts[1].Split(['='])[1];
      
      SubTask.ID := 'SUB' + FormatDateTime('yymmddhhnnss', Now);
      SubTask.TaskID := TaskID;
      SubTask.Title := SubTaskTitle;
      SubTask.Description := 'Created from chat';
      SubTask.Status := tsNotStarted;
      SubTask.Progress := 0;
      SubTask.CreatedDate := Now;
      SubTask.CompletedDate := 0;
      SubTask.GitHubFile := '/src/' + SubTaskTitle.ToLower.Replace(' ', '_') + '.pas';
      SubTask.LastModified := Now;
      
      if fDatabase.AddSubTask(SubTask) then
        WriteLn('SubTask added: ' + SubTask.ID + ' - ' + SubTask.Title)
      else
        WriteLn('Failed to add subtask - Task not found');
    end;
  end;
end;

procedure TChatCommandProcessor.ProcessUpdateCommand(const Entity: string);
var
  ParamParts: TArray<string>;
  Theme: TTheme;
  Task: TTask;
  SubTask: TSubTask;
begin
  if Entity.StartsWith('Theme=') then begin
    ParamParts := Entity.Substring(6).Split(['|']);
    if Length(ParamParts) >= 2 then begin
      var ThemeID := ParamParts[0].Split(['='])[1];
      var NewTitle := ParamParts[1].Split(['='])[1];
      
      Theme := fDatabase.GetTheme(ThemeID);
      if Theme.ID <> '' then begin
        Theme.Title := NewTitle;
        fDatabase.UpdateTheme(Theme);
        WriteLn('Theme updated: ' + Theme.ID + ' - ' + Theme.Title);
      end else
        WriteLn('Theme not found');
    end;
  end else if Entity.StartsWith('Task=') then begin
    ParamParts := Entity.Substring(5).Split(['|']);
    if Length(ParamParts) >= 2 then begin
      var TaskID := ParamParts[0].Split(['='])[1];
      var ParamName := ParamParts[1].Split(['='])[0];
      var ParamValue := ParamParts[1].Split(['='])[1];
      
      Task := fDatabase.GetTask(TaskID);
      if Task.ID <> '' then begin
        if ParamName = 'progress' then
          Task.Progress := StrToIntDef(ParamValue, 0)
        else if ParamName = 'status' then
          Task.Status := TTaskStatus(StrToIntDef(ParamValue, 0))
        else if ParamName = 'title' then
          Task.Title := ParamValue;
          
        Task.LastModified := Now;
        fDatabase.UpdateTask(Task);
        WriteLn('Task updated: ' + Task.ID);
      end else
        WriteLn('Task not found');
    end;
  end else if Entity.StartsWith('SubTask=') then begin
    ParamParts := Entity.Substring(8).Split(['|']);
    if Length(ParamParts) >= 2 then begin
      var SubTaskID := ParamParts[0].Split(['='])[1];
      var ParamName := ParamParts[1].Split(['='])[0];
      var ParamValue := ParamParts[1].Split(['='])[1];
      
      SubTask := fDatabase.GetSubTask(SubTaskID);
      if SubTask.ID <> '' then begin
        if ParamName = 'progress' then
          SubTask.Progress := StrToIntDef(ParamValue, 0)
        else if ParamName = 'status' then
          SubTask.Status := TTaskStatus(StrToIntDef(ParamValue, 0))
        else if ParamName = 'title' then
          SubTask.Title := ParamValue;
          
        SubTask.LastModified := Now;
        fDatabase.UpdateSubTask(SubTask);
        WriteLn('SubTask updated: ' + SubTask.ID);
      end else
        WriteLn('SubTask not found');
    end;
  end;
end;

procedure TChatCommandProcessor.ProcessDeleteCommand(const Entity: string);
begin
  if Entity.StartsWith('Theme=') then begin
    var ThemeID := Entity.Substring(6);
    if fDatabase.DeleteTheme(ThemeID) then
      WriteLn('Theme deleted: ' + ThemeID)
    else
      WriteLn('Failed to delete theme');
  end else if Entity.StartsWith('Task=') then begin
    var TaskID := Entity.Substring(5);
    if fDatabase.DeleteTask(TaskID) then
      WriteLn('Task deleted: ' + TaskID)
    else
      WriteLn('Failed to delete task');
  end else if Entity.StartsWith('SubTask=') then begin
    var SubTaskID := Entity.Substring(8);
    if fDatabase.DeleteSubTask(SubTaskID) then
      WriteLn('SubTask deleted: ' + SubTaskID)
    else
      WriteLn('Failed to delete subtask');
  end;
end;

procedure TChatCommandProcessor.ProcessListCommand(const Entity: string);
var
  i: Integer;
  Themes: TArray<TTheme>;
  Tasks: TArray<TTask>;
  SubTasks: TArray<TSubTask>;
begin
  if Entity = 'Themes' then begin
    Themes := fDatabase.GetAllThemes;
    WriteLn('=== THEMES ===');
    for i := 0 to High(Themes) do begin
      WriteLn(Themes[i].ID + ' - ' + Themes[i].Title + ' [' + 
              IntToStr(fDatabase.CalculateThemeProgress(Themes[i].ID)) + '%]');
    end;
  end else if Entity.StartsWith('Tasks=') then begin
    var ThemeID := Entity.Substring(6);
    Tasks := fDatabase.GetTasksByTheme(ThemeID);
    WriteLn('=== TASKS FOR THEME ' + ThemeID + ' ===');
    for i := 0 to High(Tasks) do begin
      WriteLn(Tasks[i].ID + ' - ' + Tasks[i].Title + ' [' + 
              IntToStr(fDatabase.CalculateTaskProgress(Tasks[i].ID)) + '%]');
    end;
  end else if Entity.StartsWith('SubTasks=') then begin
    var TaskID := Entity.Substring(9);
    SubTasks := fDatabase.GetSubTasksByTask(TaskID);
    WriteLn('=== SUBTASKS FOR TASK ' + TaskID + ' ===');
    for i := 0 to High(SubTasks) do begin
      WriteLn(SubTasks[i].ID + ' - ' + SubTasks[i].Title + ' [' + 
              IntToStr(SubTasks[i].Progress) + '%]');
    end;
  end;
end;

procedure TChatCommandProcessor.ProcessStatusCommand;
begin
  WriteLn('=== MONITOR STATUS ===');
  WriteLn('Overall Progress: ' + IntToStr(fDatabase.GetOverallProgress) + '%');
  WriteLn('Themes: ' + IntToStr(Length(fDatabase.GetAllThemes)));
  WriteLn('Tasks in Progress: ' + IntToStr(Length(fDatabase.GetTasksByStatus(tsInProgress))));
  WriteLn('Completed Tasks: ' + IntToStr(Length(fDatabase.GetTasksByStatus(tsCompleted))));
  WriteLn('Overdue Tasks: ' + IntToStr(Length(fDatabase.GetOverdueTasks)));
end;

procedure TChatCommandProcessor.ProcessProgressCommand;
var
  i: Integer;
  Themes: TArray<TTheme>;
begin
  WriteLn('=== PROGRESS REPORT ===');
  Themes := fDatabase.GetAllThemes;
  for i := 0 to High(Themes) do begin
    WriteLn(Themes[i].Title + ': ' + IntToStr(fDatabase.CalculateThemeProgress(Themes[i].ID)) + '%');
  end;
  WriteLn('Overall: ' + IntToStr(fDatabase.GetOverallProgress) + '%');
end;

procedure TChatCommandProcessor.ProcessExportCommand;
begin
  if fDatabase.SaveToFile('export.json') then
    WriteLn('Data exported to export.json')
  else
    WriteLn('Export failed');
end;

function TChatCommandProcessor.ExecuteCommand(const Command: string): string;
var
  Parts: TArray<string>;
  Action, Entity: string;
  Result: string;
begin
  Parts := Command.Split(['//']);
  if Length(Parts) < 2 then begin
    Result := 'Invalid command format';
    Exit;
  end;
  
  Action := Parts[0];
  Entity := Parts[1];
  
  if Action = 'Add' then begin
    ProcessAddCommand(Entity);
    Result := 'Add command executed';
  end else if Action = 'Update' then begin
    ProcessUpdateCommand(Entity);
    Result := 'Update command executed';
  end else if Action = 'Delete' then begin
    ProcessDeleteCommand(Entity);
    Result := 'Delete command executed';
  end else if Action = 'List' then begin
    ProcessListCommand(Entity);
    Result := 'List command executed';
  end else if Action = 'Status' then begin
    ProcessStatusCommand;
    Result := 'Status command executed';
  end else if Action = 'Progress' then begin
    ProcessProgressCommand;
    Result := 'Progress command executed';
  end else if Action = 'Export' then begin
    ProcessExportCommand;
    Result := 'Export command executed';
  end else begin
    Result := 'Unknown command: ' + Action;
  end;
  
  // Автосохранение после каждой команды
  SaveDatabase;
  
  ExecuteCommand := Result;
end;

end.
