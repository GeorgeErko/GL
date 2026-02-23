program MonitorConsole;

{$mode Delphi}{$H+}

uses
  SysUtils, Classes, MonitorDatabase;

var
  Database: TMonitorDatabase;

procedure ProcessCommand(const Cmd: string);
var
  Parts, ParamParts: TArray<string>;
  Action, Entity, Params: string;
  Theme: TTheme;
  Task: TTask;
  SubTask: TSubTask;
  i: Integer;
begin
  Parts := Cmd.Split(['//']);
  if Length(Parts) < 2 then begin
    WriteLn('Invalid command format');
    Exit;
  end;
  
  Action := Parts[0];
  Entity := Parts[1];
  
  // --- ADD COMMANDS ---
  if Action = 'Add' then begin
    if Entity.StartsWith('Theme=') then begin
      var ThemeTitle := Entity.Substring(6);
      Theme.ID := 'THEME' + FormatDateTime('yymmddhhnnss', Now);
      Theme.Title := ThemeTitle;
      Theme.Description := 'Created from console';
      Theme.CreatedDate := Now;
      Theme.GitHubRepo := 'https://github.com/user/repo';
      Theme.Color := '#0078D4';
      Theme.IsActive := True;
      Database.AddTheme(Theme);
      WriteLn('Theme added: ' + Theme.ID + ' - ' + Theme.Title);
    end else if Entity.StartsWith('Task=') then begin
      ParamParts := Entity.Substring(5).Split(['|']);
      if Length(ParamParts) >= 2 then begin
        var ThemeID := ParamParts[0].Split(['='])[1];
        var TaskTitle := ParamParts[1].Split(['='])[1];
        
        Task.ID := 'TASK' + FormatDateTime('yymmddhhnnss', Now);
        Task.ThemeID := ThemeID;
        Task.Title := TaskTitle;
        Task.Description := 'Created from console';
        Task.Status := tsNotStarted;
        Task.Priority := tpNormal;
        Task.Progress := 0;
        Task.CreatedDate := Now;
        Task.DueDate := Now + 30;
        Task.AssignedTo := 'Console User';
        Task.GitHubPath := '/src/' + TaskTitle.ToLower.Replace(' ', '_');
        Task.EstimatedHours := 40;
        Task.ActualHours := 0;
        Task.LastModified := Now;
        
        if Database.AddTask(Task) then
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
        SubTask.Description := 'Created from console';
        SubTask.Status := tsNotStarted;
        SubTask.Progress := 0;
        SubTask.CreatedDate := Now;
        SubTask.CompletedDate := 0;
        SubTask.GitHubFile := '/src/' + SubTaskTitle.ToLower.Replace(' ', '_') + '.pas';
        SubTask.LastModified := Now;
        
        if Database.AddSubTask(SubTask) then
          WriteLn('SubTask added: ' + SubTask.ID + ' - ' + SubTask.Title)
        else
          WriteLn('Failed to add subtask - Task not found');
      end;
    end;
  end
  
  // --- UPDATE COMMANDS ---
  else if Action = 'Update' then begin
    if Entity.StartsWith('Theme=') then begin
      ParamParts := Entity.Substring(6).Split(['|']);
      if Length(ParamParts) >= 2 then begin
        var ThemeID := ParamParts[0].Split(['='])[1];
        var NewTitle := ParamParts[1].Split(['='])[1];
        
        Theme := Database.GetTheme(ThemeID);
        if Theme.ID <> '' then begin
          Theme.Title := NewTitle;
          Database.UpdateTheme(Theme);
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
        
        Task := Database.GetTask(TaskID);
        if Task.ID <> '' then begin
          if ParamName = 'progress' then
            Task.Progress := StrToIntDef(ParamValue, 0)
          else if ParamName = 'status' then
            Task.Status := TTaskStatus(StrToIntDef(ParamValue, 0))
          else if ParamName = 'title' then
            Task.Title := ParamValue;
            
          Task.LastModified := Now;
          Database.UpdateTask(Task);
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
        
        SubTask := Database.GetSubTask(SubTaskID);
        if SubTask.ID <> '' then begin
          if ParamName = 'progress' then
            SubTask.Progress := StrToIntDef(ParamValue, 0)
          else if ParamName = 'status' then
            SubTask.Status := TTaskStatus(StrToIntDef(ParamValue, 0))
          else if ParamName = 'title' then
            SubTask.Title := ParamValue;
            
          SubTask.LastModified := Now;
          Database.UpdateSubTask(SubTask);
          WriteLn('SubTask updated: ' + SubTask.ID);
        end else
          WriteLn('SubTask not found');
      end;
    end;
  end
  
  // --- DELETE COMMANDS ---
  else if Action = 'Delete' then begin
    if Entity.StartsWith('Theme=') then begin
      var ThemeID := Entity.Substring(6);
      if Database.DeleteTheme(ThemeID) then
        WriteLn('Theme deleted: ' + ThemeID)
      else
        WriteLn('Failed to delete theme');
    end else if Entity.StartsWith('Task=') then begin
      var TaskID := Entity.Substring(5);
      if Database.DeleteTask(TaskID) then
        WriteLn('Task deleted: ' + TaskID)
      else
        WriteLn('Failed to delete task');
    end else if Entity.StartsWith('SubTask=') then begin
      var SubTaskID := Entity.Substring(8);
      if Database.DeleteSubTask(SubTaskID) then
        WriteLn('SubTask deleted: ' + SubTaskID)
      else
        WriteLn('Failed to delete subtask');
    end;
  end
  
  // --- LIST COMMANDS ---
  else if Action = 'List' then begin
    if Entity = 'Themes' then begin
      var Themes := Database.GetAllThemes;
      WriteLn('=== THEMES ===');
      for i := 0 to High(Themes) do begin
        WriteLn(Themes[i].ID + ' - ' + Themes[i].Title + ' [' + 
                IntToStr(Database.CalculateThemeProgress(Themes[i].ID)) + '%]');
      end;
    end else if Entity.StartsWith('Tasks=') then begin
      var ThemeID := Entity.Substring(6);
      var Tasks := Database.GetTasksByTheme(ThemeID);
      WriteLn('=== TASKS FOR THEME ' + ThemeID + ' ===');
      for i := 0 to High(Tasks) do begin
        WriteLn(Tasks[i].ID + ' - ' + Tasks[i].Title + ' [' + 
                IntToStr(Database.CalculateTaskProgress(Tasks[i].ID)) + '%]');
      end;
    end else if Entity.StartsWith('SubTasks=') then begin
      var TaskID := Entity.Substring(9);
      var SubTasks := Database.GetSubTasksByTask(TaskID);
      WriteLn('=== SUBTASKS FOR TASK ' + TaskID + ' ===');
      for i := 0 to High(SubTasks) do begin
        WriteLn(SubTasks[i].ID + ' - ' + SubTasks[i].Title + ' [' + 
                IntToStr(SubTasks[i].Progress) + '%]');
      end;
    end;
  end
  
  // --- STATUS COMMANDS ---
  else if Action = 'Status' then begin
    WriteLn('=== MONITOR STATUS ===');
    WriteLn('Overall Progress: ' + IntToStr(Database.GetOverallProgress) + '%');
    WriteLn('Themes: ' + IntToStr(Length(Database.GetAllThemes)));
    WriteLn('Tasks in Progress: ' + IntToStr(Length(Database.GetTasksByStatus(tsInProgress))));
    WriteLn('Completed Tasks: ' + IntToStr(Length(Database.GetTasksByStatus(tsCompleted))));
    WriteLn('Overdue Tasks: ' + IntToStr(Length(Database.GetOverdueTasks)));
  end
  
  // --- PROGRESS COMMAND ---
  else if Action = 'Progress' then begin
    WriteLn('=== PROGRESS REPORT ===');
    var Themes := Database.GetAllThemes;
    for i := 0 to High(Themes) do begin
      WriteLn(Themes[i].Title + ': ' + IntToStr(Database.CalculateThemeProgress(Themes[i].ID)) + '%');
    end;
    WriteLn('Overall: ' + IntToStr(Database.GetOverallProgress) + '%');
  end
  
  // --- EXPORT COMMAND ---
  else if Action = 'Export' then begin
    if Database.SaveToFile('export.json') then
      WriteLn('Data exported to export.json')
    else
      WriteLn('Export failed');
  end
  
  else begin
    WriteLn('Unknown command: ' + Action);
  end;
end;

begin
  Database := TMonitorDatabase.Create('default.json');
  
  if ParamCount > 0 then begin
    ProcessCommand(ParamStr(1));
  end else begin
    WriteLn('Monitor Console - Work Complex Management');
    WriteLn('');
    WriteLn('Usage:');
    WriteLn('  Add//Theme=theme title');
    WriteLn('  Add//Task=theme_id|title=task title');
    WriteLn('  Add//SubTask=task_id|title=subtask title');
    WriteLn('');
    WriteLn('  Update//Theme=theme_id|title=new title');
    WriteLn('  Update//Task=task_id|progress=50');
    WriteLn('  Update//SubTask=subtask_id|progress=75');
    WriteLn('');
    WriteLn('  Delete//Theme=theme_id');
    WriteLn('  Delete//Task=task_id');
    WriteLn('  Delete//SubTask=subtask_id');
    WriteLn('');
    WriteLn('  List//Themes');
    WriteLn('  List//Tasks=theme_id');
    WriteLn('  List//SubTasks=task_id');
    WriteLn('');
    WriteLn('  Status');
    WriteLn('  Progress');
    WriteLn('  Export');
  end;
  
  Database.Free;
end.
