unit CreateDefaultJSON;

{$H+}
{$WARNINGS OFF}

interface

uses Classes, SysUtils, fpjson, jsonparser;

procedure CreateDefaultDatabaseFile;

implementation

procedure CreateDefaultDatabaseFile;
var
  JSONObj: TJSONObject;
  ThemesArray, TasksArray, SubTasksArray: TJSONArray;
  ThemeObj: TJSONObject;
begin
  try
    // Создаем основной JSON объект
    JSONObj := TJSONObject.Create;
    
    // Создаем пустые массивы
    ThemesArray := TJSONArray.Create;
    TasksArray := TJSONArray.Create;
    SubTasksArray := TJSONArray.Create;
    
    // Добавляем пустые массивы в JSON
    JSONObj.Add('themes', ThemesArray);
    JSONObj.Add('tasks', TasksArray);
    JSONObj.Add('subTasks', SubTasksArray);
    
    // Сохраняем в файл
    with TStringList.Create do begin
      Text := JSONObj.FormatJSON();
      SaveToFile('c:/!theGrapher/GlobalMonitor/default.json');
      Free;
    end;
    
    JSONObj.Free;
    WriteLn('Default JSON file created successfully');
    WriteLn('Path: c:/!theGrapher/GlobalMonitor/default.json');
    
  except
    on E: Exception do begin
      WriteLn('Error creating JSON file: ' + E.Message);
    end;
  end;
end;

end.
