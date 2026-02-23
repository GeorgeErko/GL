unit JSONExample;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type
  TJSONHelper = class
  public
    class function CreateJSON(const Data: string): TJSONObject;
    class procedure SaveToFile(const JSON: TJSONObject; const FileName: string);
    class function LoadFromFile(const FileName: string): TJSONObject;
    class function TaskToJSON(const Task: TTask): TJSONObject;
    class function JSONToTask(const JSON: TJSONObject): TTask;
  end;

implementation

class function TJSONHelper.CreateJSON(const Data: string): TJSONObject;
var
  Parser: TJSONParser;
begin
  try
    Parser := TJSONParser.Create(Data);
    try
      Result := Parser.Parse as TJSONObject;
    finally
      Parser.Free;
    end;
  except
    Result := TJSONObject.Create;
  end;
end;

class procedure TJSONHelper.SaveToFile(const JSON: TJSONObject; const FileName: string);
var
  StringList: TStringList;
begin
  StringList := TStringList.Create;
  try
    StringList.Text := JSON.FormatJSON();
    StringList.SaveToFile(FileName);
  finally
    StringList.Free;
  end;
end;

class function TJSONHelper.LoadFromFile(const FileName: string): TJSONObject;
var
  StringList: TStringList;
  Parser: TJSONParser;
begin
  StringList := TStringList.Create;
  try
    StringList.LoadFromFile(FileName);
    Parser := TJSONParser.Create(StringList.Text);
    try
      Result := Parser.Parse as TJSONObject;
    finally
      Parser.Free;
    end;
  finally
    StringList.Free;
  end;
end;

class function TJSONHelper.TaskToJSON(const Task: TTask): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.Add('id', Task.ID);
    Result.Add('themeId', Task.ThemeID);
    Result.Add('title', Task.Title);
    Result.Add('description', Task.Description);
    Result.Add('status', Ord(Task.Status));
    Result.Add('priority', Ord(Task.Priority));
    Result.Add('progress', Task.Progress);
    Result.Add('createdDate', DateTimeToStr(Task.CreatedDate));
    Result.Add('dueDate', DateTimeToStr(Task.DueDate));
    Result.Add('assignedTo', Task.AssignedTo);
    Result.Add('gitHubPath', Task.GitHubPath);
    Result.Add('estimatedHours', Task.EstimatedHours);
    Result.Add('actualHours', Task.ActualHours);
    Result.Add('lastModified', DateTimeToStr(Task.LastModified));
  except
    Result.Free;
    raise;
  end;
end;

class function TJSONHelper.JSONToTask(const JSON: TJSONObject): TTask;
begin
  Result.ID := JSON.Get('id');
  Result.ThemeID := JSON.Get('themeId');
  Result.Title := JSON.Get('title');
  Result.Description := JSON.Get('description');
  Result.Status := TTaskStatus(StrToIntDef(JSON.Get('status'), 0));
  Result.Priority := TTaskPriority(StrToIntDef(JSON.Get('priority'), 1));
  Result.Progress := StrToIntDef(JSON.Get('progress'), 0);
  Result.CreatedDate := StrToDateTimeDef(JSON.Get('createdDate'), Now);
  Result.DueDate := StrToDateTimeDef(JSON.Get('dueDate'), Now + 7);
  Result.AssignedTo := JSON.Get('assignedTo', 'Unassigned');
  Result.GitHubPath := JSON.Get('gitHubPath');
  Result.EstimatedHours := StrToFloatDef(JSON.Get('estimatedHours'), 0);
  Result.ActualHours := StrToFloatDef(JSON.Get('actualHours'), 0);
  Result.LastModified := StrToDateTimeDef(JSON.Get('lastModified'), Now);
end;

end.
