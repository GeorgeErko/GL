unit TaskTrackerGUI;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Menus, TaskDatabase;

type

  { TTaskTrackerForm }
  
  TTaskTrackerForm = class(TForm)
    MainMenu1: TMainMenu;
    FileMenu: TMenuItem;
    NewThemeMenu: TMenuItem;
    NewTaskMenu: TMenuItem;
    NewSubTaskMenu: TMenuItem;
    SaveMenu: TMenuItem;
    LoadMenu: TMenuItem;
    ExitMenu: TMenuItem;
    EditMenu: TMenuItem;
    DeleteMenu: TMenuItem;
    ViewMenu: TMenuItem;
    RefreshMenu: TMenuItem;
    ExpandAllMenu: TMenuItem;
    CollapseAllMenu: TMenuItem;
    ToolsMenu: TMenuItem;
    GitHubLinkMenu: TMenuItem;
    ProgressMenu: TMenuItem;
    HelpMenu: TMenuItem;
    AboutMenu: TMenuItem;
    
    TaskTreeView: TTreeView;
    DetailsPanel: TPanel;
    TitleLabel: TLabel;
    TypeLabel: TLabel;
    StatusLabel: TLabel;
    ProgressLabel: TLabel;
    AssignedLabel: TLabel;
    GitHubLabel: TLabel;
    DetailsMemo: TMemo;
    ProgressBar: TProgressBar;
    ButtonPanel: TPanel;
    AddButton: TButton;
    EditButton: TButton;
    DeleteButton: TButton;
    ProgressButton: TButton;
    GitHubButton: TButton;
    StatusPanel: TPanel;
    StatusLabel2: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TaskTreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure TaskTreeViewAdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
      var PaintImages, DefaultDraw: Boolean);
    procedure AddButtonClick(Sender: TObject);
    procedure EditButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure ProgressButtonClick(Sender: TObject);
    procedure GitHubButtonClick(Sender: TObject);
    procedure NewThemeMenuClick(Sender: TObject);
    procedure NewTaskMenuClick(Sender: TObject);
    procedure NewSubTaskMenuClick(Sender: TObject);
    procedure SaveMenuClick(Sender: TObject);
    procedure LoadMenuClick(Sender: TObject);
    procedure DeleteMenuClick(Sender: TObject);
    procedure RefreshMenuClick(Sender: TObject);
    procedure ExpandAllMenuClick(Sender: TObject);
    procedure CollapseAllMenuClick(Sender: TObject);
    procedure GitHubLinkMenuClick(Sender: TObject);
    procedure AboutMenuClick(Sender: TObject);
    procedure ExitMenuClick(Sender: TObject);
    
  private
    fDatabase: TTaskDatabase;
    fCurrentNodeType: string;
    fCurrentNodeID: string;
    
    procedure RefreshTreeView;
    procedure UpdateDetails;
    procedure UpdateStatusBar;
    procedure AddThemeToTreeView(const Theme: TTheme);
    procedure AddTaskToTreeView(const Task: TTask; ParentNode: TTreeNode);
    procedure AddSubTaskToTreeView(const SubTask: TSubTask; ParentNode: TTreeNode);
    function GetNodeData(Node: TTreeNode): string;
    procedure SetNodeProgress(Node: TTreeNode; Progress: Integer);
    
  public
    procedure CreateSampleData;
  end;

var
  TaskTrackerForm: TTaskTrackerForm;

implementation

{$R *.lfm}

{ TTaskTrackerForm }

procedure TTaskTrackerForm.FormCreate(Sender: TObject);
begin
  Caption := 'Task Tracker - Work Complex Management';
  Width := 1200;
  Height := 800;
  
  fDatabase := TTaskDatabase.Create('tasks.json');
  fCurrentNodeType := '';
  fCurrentNodeID := '';
  
  // Если база пуста, создаем демонстрационные данные
  if Length(fDatabase.GetAllThemes) = 0 then
    CreateSampleData;
    
  RefreshTreeView;
  UpdateStatusBar;
end;

procedure TTaskTrackerForm.FormDestroy(Sender: TObject);
begin
  fDatabase.Free;
end;

procedure TTaskTrackerForm.RefreshTreeView;
var
  Themes: TArray<TTheme>;
  Tasks: TArray<TTask>;
  SubTasks: TArray<TSubTask>;
  i: Integer;
  ThemeNode, TaskNode: TTreeNode;
begin
  TaskTreeView.Items.Clear;
  
  // Добавляем темы
  Themes := fDatabase.GetAllThemes;
  for i := 0 to High(Themes) do begin
    AddThemeToTreeView(Themes[i]);
  end;
  
  // Разворачиваем все узлы
  TaskTreeView.FullExpand;
end;

procedure TTaskTrackerForm.AddThemeToTreeView(const Theme: TTheme);
var
  ThemeNode: TTreeNode;
  Tasks: TArray<TTask>;
  i: Integer;
begin
  ThemeNode := TaskTreeView.Items.Add(nil, Theme.Title);
  ThemeNode.ImageIndex := 0;
  ThemeNode.SelectedIndex := 0;
  ThemeNode.Data := Pointer('THEME:' + Theme.ID);
  
  // Устанавливаем цвет темы
  ThemeNode.Text := Theme.Title + ' [' + IntToStr(fDatabase.CalculateThemeProgress(Theme.ID)) + '%]';
  
  // Добавляем задачи темы
  Tasks := fDatabase.GetTasksByTheme(Theme.ID);
  for i := 0 to High(Tasks) do
    AddTaskToTreeView(Tasks[i], ThemeNode);
end;

procedure TTaskTrackerForm.AddTaskToTreeView(const Task: TTask; ParentNode: TTreeNode);
var
  TaskNode: TTreeNode;
  SubTasks: TArray<TSubTask>;
  i: Integer;
begin
  TaskNode := TaskTreeView.Items.AddChild(ParentNode, Task.Title);
  TaskNode.ImageIndex := 1;
  TaskNode.SelectedIndex := 1;
  TaskNode.Data := Pointer('TASK:' + Task.ID);
  
  // Показываем прогресс и статус
  TaskNode.Text := Task.Title + ' [' + IntToStr(fDatabase.CalculateTaskProgress(Task.ID)) + '%] - ' + 
                 fDatabase.GetStatusString(Task.Status);
  
  // Добавляем подзадачи
  SubTasks := fDatabase.GetSubTasksByTask(Task.ID);
  for i := 0 to High(SubTasks) do
    AddSubTaskToTreeView(SubTasks[i], TaskNode);
end;

procedure TTaskTrackerForm.AddSubTaskToTreeView(const SubTask: TSubTask; ParentNode: TTreeNode);
var
  SubTaskNode: TTreeNode;
begin
  SubTaskNode := TaskTreeView.Items.AddChild(ParentNode, SubTask.Title);
  SubTaskNode.ImageIndex := 2;
  SubTaskNode.SelectedIndex := 2;
  SubTaskNode.Data := Pointer('SUBTASK:' + SubTask.ID);
  
  // Показываем прогресс и статус
  SubTaskNode.Text := SubTask.Title + ' [' + IntToStr(SubTask.Progress) + '%] - ' + 
                    fDatabase.GetStatusString(SubTask.Status);
end;

procedure TTaskTrackerForm.TaskTreeViewChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) and Assigned(Node.Data) then begin
    var NodeData := GetNodeData(Node);
    var Parts := NodeData.Split([':']);
    
    if Length(Parts) = 2 then begin
      fCurrentNodeType := Parts[0];
      fCurrentNodeID := Parts[1];
      UpdateDetails;
    end;
  end else begin
    fCurrentNodeType := '';
    fCurrentNodeID := '';
    UpdateDetails;
  end;
end;

procedure TTaskTrackerForm.TaskTreeViewAdvancedCustomDrawItem(
  Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawStage;
  var PaintImages, DefaultDraw: Boolean);
var
  NodeText: string;
  Progress: Integer;
  Rect: TRect;
begin
  if (Stage = cdPostPaint) and Assigned(Node) and Assigned(Node.Data) then begin
    var NodeData := GetNodeData(Node);
    var Parts := NodeData.Split([':']);
    
    if Length(Parts) = 2 then begin
      var NodeType := Parts[0];
      var NodeID := Parts[1];
      
      // Рисуем прогресс-бар для задач и подзадач
      if (NodeType = 'TASK') or (NodeType = 'SUBTASK') then begin
        if NodeType = 'TASK' then
          Progress := fDatabase.CalculateTaskProgress(NodeID)
        else
          Progress := fDatabase.GetSubTask(NodeID).Progress;
          
        if Progress > 0 then begin
          Rect := Node.DisplayRect(True);
          Rect.Left := Rect.Right - 100;
          Rect.Right := Rect.Right - 5;
          Rect.Top := Rect.Top + 2;
          Rect.Bottom := Rect.Top + 4;
          
          Sender.Canvas.Brush.Color := clGreen;
          Sender.Canvas.FillRect(Rect);
          
          Rect.Right := Rect.Left + (Rect.Right - Rect.Left) * Progress div 100;
          Sender.Canvas.Brush.Color := clLime;
          Sender.Canvas.FillRect(Rect);
        end;
      end;
    end;
  end;
end;

function TTaskTrackerForm.GetNodeData(Node: TTreeNode): string;
begin
  if Assigned(Node.Data) then
    Result := string(Node.Data)
  else
    Result := '';
end;

procedure TTaskTrackerForm.UpdateDetails;
var
  Theme: TTheme;
  Task: TTask;
  SubTask: TSubTask;
  Details: string;
begin
  if fCurrentNodeID = '' then begin
    TitleLabel.Caption := 'No item selected';
    TypeLabel.Caption := '';
    StatusLabel.Caption := '';
    ProgressLabel.Caption := '';
    AssignedLabel.Caption := '';
    GitHubLabel.Caption := '';
    ProgressBar.Position := 0;
    DetailsMemo.Lines.Clear;
    Exit;
  end;
  
  if fCurrentNodeType = 'THEME' then begin
    Theme := fDatabase.GetTheme(fCurrentNodeID);
    TitleLabel.Caption := Theme.Title;
    TypeLabel.Caption := 'Theme';
    StatusLabel.Caption := 'Active';
    ProgressLabel.Caption := 'Progress: ' + IntToStr(fDatabase.CalculateThemeProgress(Theme.ID)) + '%';
    ProgressBar.Position := fDatabase.CalculateThemeProgress(Theme.ID);
    AssignedLabel.Caption := 'GitHub: ' + Theme.GitHubRepo;
    GitHubLabel.Caption := 'Color: ' + Theme.Color;
    
    Details := 'ID: ' + Theme.ID + #13#10;
    Details := Details + 'Description: ' + Theme.Description + #13#10;
    Details := Details + 'Created: ' + FormatDateTime('dd/mm/yyyy hh:nn', Theme.CreatedDate) + #13#10;
    Details := Details + 'GitHub Repository: ' + Theme.GitHubRepo + #13#10;
    Details := Details + 'Color: ' + Theme.Color;
    
    DetailsMemo.Lines.Text := Details;
  end else if fCurrentNodeType = 'TASK' then begin
    Task := fDatabase.GetTask(fCurrentNodeID);
    TitleLabel.Caption := Task.Title;
    TypeLabel.Caption := 'Task';
    StatusLabel.Caption := 'Status: ' + fDatabase.GetStatusString(Task.Status);
    ProgressLabel.Caption := 'Progress: ' + IntToStr(fDatabase.CalculateTaskProgress(Task.ID)) + '%';
    ProgressBar.Position := fDatabase.CalculateTaskProgress(Task.ID);
    AssignedLabel.Caption := 'Assigned to: ' + Task.AssignedTo;
    GitHubLabel.Caption := 'GitHub: ' + Task.GitHubPath;
    
    Details := 'ID: ' + Task.ID + #13#10;
    Details := Details + 'Description: ' + Task.Description + #13#10;
    Details := Details + 'Status: ' + fDatabase.GetStatusString(Task.Status) + #13#10;
    Details := Details + 'Priority: ' + fDatabase.GetPriorityString(Task.Priority) + #13#10;
    Details := Details + 'Progress: ' + IntToStr(Task.Progress) + '% (Calculated: ' + 
               IntToStr(fDatabase.CalculateTaskProgress(Task.ID)) + '%)' + #13#10;
    Details := Details + 'Assigned to: ' + Task.AssignedTo + #13#10;
    Details := Details + 'Created: ' + FormatDateTime('dd/mm/yyyy hh:nn', Task.CreatedDate) + #13#10;
    Details := Details + 'Due date: ' + FormatDateTime('dd/mm/yyyy hh:nn', Task.DueDate) + #13#10;
    Details := Details + 'Estimated hours: ' + FloatToStr(Task.EstimatedHours) + #13#10;
    Details := Details + 'Actual hours: ' + FloatToStr(Task.ActualHours) + #13#10;
    Details := Details + 'GitHub Path: ' + Task.GitHubPath;
    
    DetailsMemo.Lines.Text := Details;
  end else if fCurrentNodeType = 'SUBTASK' then begin
    SubTask := fDatabase.GetSubTask(fCurrentNodeID);
    TitleLabel.Caption := SubTask.Title;
    TypeLabel.Caption := 'SubTask';
    StatusLabel.Caption := 'Status: ' + fDatabase.GetStatusString(SubTask.Status);
    ProgressLabel.Caption := 'Progress: ' + IntToStr(SubTask.Progress) + '%';
    ProgressBar.Position := SubTask.Progress;
    AssignedLabel.Caption := 'Completed: ' + FormatDateTime('dd/mm/yyyy hh:nn', SubTask.CompletedDate);
    GitHubLabel.Caption := 'GitHub: ' + SubTask.GitHubFile;
    
    Details := 'ID: ' + SubTask.ID + #13#10;
    Details := Details + 'Description: ' + SubTask.Description + #13#10;
    Details := Details + 'Status: ' + fDatabase.GetStatusString(SubTask.Status) + #13#10;
    Details := Details + 'Progress: ' + IntToStr(SubTask.Progress) + '%' + #13#10;
    Details := Details + 'Created: ' + FormatDateTime('dd/mm/yyyy hh:nn', SubTask.CreatedDate) + #13#10;
    Details := Details + 'Completed: ' + FormatDateTime('dd/mm/yyyy hh:nn', SubTask.CompletedDate) + #13#10;
    Details := Details + 'GitHub File: ' + SubTask.GitHubFile;
    
    DetailsMemo.Lines.Text := Details;
  end;
end;

procedure TTaskTrackerForm.UpdateStatusBar;
var
  Themes: TArray<TTheme>;
  Tasks: TArray<TTask>;
  SubTasks: TArray<TSubTask>;
begin
  Themes := fDatabase.GetAllThemes;
  Tasks := fDatabase.GetTasksByStatus(tsInProgress);
  SubTasks := fDatabase.GetSubTasksByTask('');
  
  StatusLabel2.Caption := Format('Themes: %d | Tasks in Progress: %d | Overall Progress: %d%%',
    [Length(Themes), Length(Tasks), fDatabase.GetOverallProgress]);
end;

procedure TTaskTrackerForm.AddButtonClick(Sender: TObject);
begin
  if fCurrentNodeType = '' then
    NewThemeMenuClick(Sender)
  else if fCurrentNodeType = 'THEME' then
    NewTaskMenuClick(Sender)
  else if fCurrentNodeType = 'TASK' then
    NewSubTaskMenuClick(Sender)
  else
    ShowMessage('Select a parent item first');
end;

procedure TTaskTrackerForm.EditButtonClick(Sender: TObject);
begin
  ShowMessage('Edit functionality - to be implemented');
end;

procedure TTaskTrackerForm.DeleteButtonClick(Sender: TObject);
begin
  if fCurrentNodeID = '' then begin
    ShowMessage('Please select an item to delete');
    Exit;
  end;
  
  if MessageDlg('Delete selected item?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
    if fCurrentNodeType = 'THEME' then
      fDatabase.DeleteTheme(fCurrentNodeID)
    else if fCurrentNodeType = 'TASK' then
      fDatabase.DeleteTask(fCurrentNodeID)
    else if fCurrentNodeType = 'SUBTASK' then
      fDatabase.DeleteSubTask(fCurrentNodeID);
      
    RefreshTreeView;
    UpdateDetails;
    UpdateStatusBar;
    ShowMessage('Item deleted successfully');
  end;
end;

procedure TTaskTrackerForm.ProgressButtonClick(Sender: TObject);
var
  ProgressForm: TForm;
  ProgressEdit: TEdit;
  OkButton, CancelButton: TButton;
  Progress: Integer;
begin
  if fCurrentNodeID = '' then begin
    ShowMessage('Please select a task or subtask');
    Exit;
  end;
  
  ProgressForm := TForm.Create(nil);
  try
    ProgressForm.Caption := 'Update Progress';
    ProgressForm.Width := 300;
    ProgressForm.Height := 150;
    ProgressForm.Position := poScreenCenter;
    
    TLabel.Create(ProgressForm).Parent := ProgressForm;
    TLabel(ProgressForm.Components[ProgressForm.ComponentCount-1]).Caption := 'Progress (0-100):';
    TLabel(ProgressForm.Components[ProgressForm.ComponentCount-1]).Left := 20;
    TLabel(ProgressForm.Components[ProgressForm.ComponentCount-1]).Top := 20;
    
    ProgressEdit := TEdit.Create(ProgressForm);
    ProgressEdit.Parent := ProgressForm;
    ProgressEdit.Left := 20;
    ProgressEdit.Top := 50;
    ProgressEdit.Width := 100;
    
    if fCurrentNodeType = 'TASK' then
      ProgressEdit.Text := IntToStr(fDatabase.GetTask(fCurrentNodeID).Progress)
    else if fCurrentNodeType = 'SUBTASK' then
      ProgressEdit.Text := IntToStr(fDatabase.GetSubTask(fCurrentNodeID).Progress);
    
    OkButton := TButton.Create(ProgressForm);
    OkButton.Parent := ProgressForm;
    OkButton.Caption := 'OK';
    OkButton.Left := 20;
    OkButton.Top := 80;
    OkButton.ModalResult := mrOk;
    
    CancelButton := TButton.Create(ProgressForm);
    CancelButton.Parent := ProgressForm;
    CancelButton.Caption := 'Cancel';
    CancelButton.Left := 100;
    CancelButton.Top := 80;
    CancelButton.ModalResult := mrCancel;
    
    if ProgressForm.ShowModal = mrOk then begin
      try
        Progress := StrToInt(ProgressEdit.Text);
        if (Progress >= 0) and (Progress <= 100) then begin
          if fCurrentNodeType = 'TASK' then begin
            var Task := fDatabase.GetTask(fCurrentNodeID);
            Task.Progress := Progress;
            fDatabase.UpdateTask(Task);
          end else if fCurrentNodeType = 'SUBTASK' then begin
            var SubTask := fDatabase.GetSubTask(fCurrentNodeID);
            SubTask.Progress := Progress;
            fDatabase.UpdateSubTask(SubTask);
          end;
          
          RefreshTreeView;
          UpdateDetails;
          UpdateStatusBar;
          ShowMessage('Progress updated successfully');
        end else
          ShowMessage('Progress must be between 0 and 100');
      except
        ShowMessage('Invalid progress value');
      end;
    end;
  finally
    ProgressForm.Free;
  end;
end;

procedure TTaskTrackerForm.GitHubButtonClick(Sender: TObject);
begin
  if fCurrentNodeID = '' then begin
    ShowMessage('Please select an item');
    Exit;
  end;
  
  ShowMessage('GitHub integration - to be implemented');
end;

procedure TTaskTrackerForm.NewThemeMenuClick(Sender: TObject);
var
  Theme: TTheme;
  InputForm: TForm;
  TitleEdit, DescEdit, GitHubEdit, ColorEdit: TEdit;
  OkButton, CancelButton: TButton;
begin
  InputForm := TForm.Create(nil);
  try
    InputForm.Caption := 'New Theme';
    InputForm.Width := 400;
    InputForm.Height := 250;
    InputForm.Position := poScreenCenter;
    
    // Создаем поля ввода
    // ID
    TLabel.Create(InputForm).Parent := InputForm;
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Caption := 'ID:';
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Left := 20;
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Top := 20;
    
    TitleEdit := TEdit.Create(InputForm);
    TitleEdit.Parent := InputForm;
    TitleEdit.Left := 100;
    TitleEdit.Top := 15;
    TitleEdit.Width := 200;
    TitleEdit.Text := 'THEME' + FormatDateTime('yymmddhhnnss', Now);
    
    // Title
    TLabel.Create(InputForm).Parent := InputForm;
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Caption := 'Title:';
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Left := 20;
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Top := 50;
    
    DescEdit := TEdit.Create(InputForm);
    DescEdit.Parent := InputForm;
    DescEdit.Left := 100;
    DescEdit.Top := 45;
    DescEdit.Width := 200;
    DescEdit.Text := 'New Theme';
    
    // GitHub
    TLabel.Create(InputForm).Parent := InputForm;
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Caption := 'GitHub Repo:';
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Left := 20;
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Top := 80;
    
    GitHubEdit := TEdit.Create(InputForm);
    GitHubEdit.Parent := InputForm;
    GitHubEdit.Left := 100;
    GitHubEdit.Top := 75;
    GitHubEdit.Width := 200;
    GitHubEdit.Text := 'https://github.com/user/repo';
    
    // Color
    TLabel.Create(InputForm).Parent := InputForm;
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Caption := 'Color:';
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Left := 20;
    TLabel(InputForm.Components[InputForm.ComponentCount-1]).Top := 110;
    
    ColorEdit := TEdit.Create(InputForm);
    ColorEdit.Parent := InputForm;
    ColorEdit.Left := 100;
    ColorEdit.Top := 105;
    ColorEdit.Width := 200;
    ColorEdit.Text := '#0078D4';
    
    OkButton := TButton.Create(InputForm);
    OkButton.Parent := InputForm;
    OkButton.Caption := 'OK';
    OkButton.Left := 100;
    OkButton.Top := 150;
    OkButton.ModalResult := mrOk;
    
    CancelButton := TButton.Create(InputForm);
    CancelButton.Parent := InputForm;
    CancelButton.Caption := 'Cancel';
    CancelButton.Left := 200;
    CancelButton.Top := 150;
    CancelButton.ModalResult := mrCancel;
    
    if InputForm.ShowModal = mrOk then begin
      Theme.ID := TitleEdit.Text;
      Theme.Title := DescEdit.Text;
      Theme.Description := DescEdit.Text;
      Theme.CreatedDate := Now;
      Theme.GitHubRepo := GitHubEdit.Text;
      Theme.Color := ColorEdit.Text;
      
      if fDatabase.AddTheme(Theme) then begin
        RefreshTreeView;
        UpdateStatusBar;
        ShowMessage('Theme added successfully');
      end;
    end;
  finally
    InputForm.Free;
  end;
end;

procedure TTaskTrackerForm.NewTaskMenuClick(Sender: TObject);
begin
  ShowMessage('New Task - to be implemented');
end;

procedure TTaskTrackerForm.NewSubTaskMenuClick(Sender: TObject);
begin
  ShowMessage('New SubTask - to be implemented');
end;

procedure TTaskTrackerForm.SaveMenuClick(Sender: TObject);
begin
  if fDatabase.SaveToFile('tasks.json') then
    ShowMessage('Database saved successfully')
  else
    ShowMessage('Failed to save database');
end;

procedure TTaskTrackerForm.LoadMenuClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog := TOpenDialog.Create(nil);
  try
    OpenDialog.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    
    if OpenDialog.Execute then begin
      if fDatabase.LoadFromFile(OpenDialog.FileName) then begin
        RefreshTreeView;
        UpdateDetails;
        UpdateStatusBar;
        ShowMessage('Database loaded successfully');
      end else
        ShowMessage('Failed to load database');
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TTaskTrackerForm.DeleteMenuClick(Sender: TObject);
begin
  DeleteButtonClick(Sender);
end;

procedure TTaskTrackerForm.RefreshMenuClick(Sender: TObject);
begin
  RefreshTreeView;
  UpdateDetails;
  UpdateStatusBar;
end;

procedure TTaskTrackerForm.ExpandAllMenuClick(Sender: TObject);
begin
  TaskTreeView.FullExpand;
end;

procedure TTaskTrackerForm.CollapseAllMenuClick(Sender: TObject);
begin
  TaskTreeView.FullCollapse;
end;

procedure TTaskTrackerForm.GitHubLinkMenuClick(Sender: TObject);
begin
  ShowMessage('GitHub linking - to be implemented');
end;

procedure TTaskTrackerForm.AboutMenuClick(Sender: TObject);
begin
  ShowMessage('Task Tracker v1.0'#13#10'Work Complex Management System'#13#10'with GitHub integration');
end;

procedure TTaskTrackerForm.ExitMenuClick(Sender: TObject);
begin
  Close;
end;

procedure TTaskTrackerForm.CreateSampleData;
var
  Theme: TTheme;
  Task: TTask;
  SubTask: TSubTask;
begin
  // Создаем тему "Grapher Development"
  Theme.ID := 'THEME001';
  Theme.Title := 'Grapher Development';
  Theme.Description := 'Development of graphics editor';
  Theme.CreatedDate := Now;
  Theme.GitHubRepo := 'https://github.com/user/grapher';
  Theme.Color := '#0078D4';
  fDatabase.AddTheme(Theme);
  
  // Создаем задачу "Core Framework"
  Task.ID := 'TASK001';
  Task.ThemeID := 'THEME001';
  Task.Title := 'Core Framework';
  Task.Description := 'Develop core framework components';
  Task.Status := tsInProgress;
  Task.Priority := tpHigh;
  Task.Progress := 60;
  Task.CreatedDate := Now - 10;
  Task.DueDate := Now + 20;
  Task.AssignedTo := 'Lead Developer';
  Task.GitHubPath := '/src/core';
  Task.EstimatedHours := 40;
  Task.ActualHours := 24;
  fDatabase.AddTask(Task);
  
  // Создаем подзадачи
  SubTask.ID := 'SUB001';
  SubTask.TaskID := 'TASK001';
  SubTask.Title := 'Base Classes';
  SubTask.Description := 'Create base classes for tools';
  SubTask.Status := tsCompleted;
  SubTask.Progress := 100;
  SubTask.CreatedDate := Now - 10;
  SubTask.CompletedDate := Now - 5;
  SubTask.GitHubFile := '/src/core/basetools.pas';
  fDatabase.AddSubTask(SubTask);
  
  SubTask.ID := 'SUB002';
  SubTask.TaskID := 'TASK001';
  SubTask.Title := 'Event System';
  SubTask.Description := 'Implement event handling system';
  SubTask.Status := tsInProgress;
  SubTask.Progress := 50;
  SubTask.CreatedDate := Now - 8;
  SubTask.CompletedDate := 0;
  SubTask.GitHubFile := '/src/core/events.pas';
  fDatabase.AddSubTask(SubTask);
  
  SubTask.ID := 'SUB003';
  SubTask.TaskID := 'TASK001';
  SubTask.Title := 'Memory Management';
  SubTask.Description := 'Optimize memory usage';
  SubTask.Status := tsNotStarted;
  SubTask.Progress := 0;
  SubTask.CreatedDate := Now - 5;
  SubTask.CompletedDate := 0;
  SubTask.GitHubFile := '/src/core/memory.pas';
  fDatabase.AddSubTask(SubTask);
  
  // Создаем вторую задачу
  Task.ID := 'TASK002';
  Task.ThemeID := 'THEME001';
  Task.Title := 'User Interface';
  Task.Description := 'Develop GUI components';
  Task.Status := tsNotStarted;
  Task.Priority := tpNormal;
  Task.Progress := 0;
  Task.CreatedDate := Now - 3;
  Task.DueDate := Now + 30;
  Task.AssignedTo := 'UI Developer';
  Task.GitHubPath := '/src/ui';
  Task.EstimatedHours := 60;
  Task.ActualHours := 0;
  fDatabase.AddTask(Task);
  
  // Создаем вторую тему
  Theme.ID := 'THEME002';
  Theme.Title := 'Testing & QA';
  Theme.Description := 'Quality assurance and testing';
  Theme.CreatedDate := Now - 2;
  Theme.GitHubRepo := 'https://github.com/user/grapher-tests';
  Theme.Color := '#107C10';
  fDatabase.AddTheme(Theme);
end;

end.
