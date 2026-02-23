program TaskManagerDemo;

{$mode Delphi}{$H+}

uses SysUtils, TaskManager;

procedure CreateSampleTasks(Manager: TTaskManager);
var
  Task: TTask;
  SubTask: TSubTask;
begin
  WriteLn('Creating sample tasks...');
  
  // Task 1: Graphics Editor Development
  Task.ID := 'TASK001';
  Task.Title := 'Graphics Editor Development';
  Task.Description := 'Create full-featured graphics editor with drawing tools';
  Task.Progress := 0;
  Task.Status := tsInProgress;
  Task.Priority := tpHigh;
  Task.CreatedDate := Now - 10;
  Task.DueDate := Now + 20;
  Task.AssignedTo := 'Ivan Petrov';
  Task.Project := 'Grapher v2.0';
  Task.Tags := 'development,graphics,tools';
  SetLength(Task.SubTasks, 0);
  
  Manager.AddTask(Task);
  
  // Subtasks for task 1
  SubTask.ID := 'SUB001';
  SubTask.Title := 'Create TogsTool base class';
  SubTask.Description := 'Develop base class for all tools';
  SubTask.Progress := 100;
  SubTask.Status := tsCompleted;
  SubTask.AssignedTo := 'Ivan Petrov';
  SubTask.DueDate := Now - 5;
  SubTask.CreatedDate := Now - 10;
  SubTask.EstimatedHours := 8;
  SubTask.ActualHours := 6;
  Manager.AddSubTask('TASK001', SubTask);
  
  SubTask.ID := 'SUB002';
  SubTask.Title := 'Implement selection tools';
  SubTask.Description := 'Create object selection tools';
  SubTask.Progress := 75;
  SubTask.Status := tsInProgress;
  SubTask.AssignedTo := 'Maria Ivanova';
  SubTask.DueDate := Now + 5;
  SubTask.CreatedDate := Now - 8;
  SubTask.EstimatedHours := 12;
  SubTask.ActualHours := 9;
  Manager.AddSubTask('TASK001', SubTask);
  
  SubTask.ID := 'SUB003';
  SubTask.Title := 'Implement drawing tools';
  SubTask.Description := 'Create pencil, lines, rectangles';
  SubTask.Progress := 30;
  SubTask.Status := tsInProgress;
  SubTask.AssignedTo := 'Ivan Petrov';
  SubTask.DueDate := Now + 10;
  SubTask.CreatedDate := Now - 5;
  SubTask.EstimatedHours := 16;
  SubTask.ActualHours := 5;
  Manager.AddSubTask('TASK001', SubTask);
  
  WriteLn('Sample tasks created!');
end;

procedure DemonstrateProgressUpdates(Manager: TTaskManager);
begin
  WriteLn;
  WriteLn('=== PROGRESS UPDATE DEMONSTRATION ===');
  WriteLn;
  
  WriteLn('Updating SUB002 progress to 90%...');
  Manager.UpdateSubTaskProgress('TASK001', 'SUB002', 90);
  
  WriteLn('Updating SUB003 progress to 60%...');
  Manager.UpdateSubTaskProgress('TASK001', 'SUB003', 60);
  
  WriteLn;
  WriteLn('=== PROGRESS AFTER UPDATES ===');
  Manager.DisplayProgressReport;
end;

procedure DemonstrateExcelOperations(Manager: TTaskManager);
begin
  WriteLn;
  WriteLn('=== EXCEL OPERATIONS DEMONSTRATION ===');
  WriteLn;
  
  if Manager.SaveToExcel('tasks.csv') then
    WriteLn('Tasks saved to tasks.csv');
  
  if Manager.ExportProgressReport('progress_report.csv') then
    WriteLn('Progress report saved to progress_report.csv');
  
  WriteLn;
  WriteLn('Files created in current directory:');
  WriteLn('- tasks.csv - main tasks');
  WriteLn('- progress_report.csv - detailed subtask report');
end;

// Main program
var
  Manager: TTaskManager;
begin
  WriteLn('=== TASK MANAGEMENT SYSTEM WITH EXCEL INTEGRATION ===');
  WriteLn;
  
  Manager := TTaskManager.Create('');
  
  CreateSampleTasks(Manager);
  Manager.DisplayAllTasks;
  Manager.DisplayProgressReport;
  
  DemonstrateProgressUpdates(Manager);
  DemonstrateExcelOperations(Manager);
  
  Manager.Free;
  
  WriteLn;
  WriteLn('Program completed. Thank you!');
  Readln;
end.
