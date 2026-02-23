program TestJSON;

{$mode Delphi}{$H+}

uses
  Classes, SysUtils, ogcProperties;

var
  Project: TogsPropObject;
  JsonContent: string;
  Themes, Tasks, SubTasks: TogsPropArray;
  i: Integer;
  Theme, Task: TogsPropObject;
begin
  // Читаем JSON файл
  with TStringList.Create do begin
    LoadFromFile('default.json');
    JsonContent := Text;
    Free;
  end;

  // Создаем объект и загружаем JSON
  Project := TogsPropObject.CreateFrom(JsonContent);
  try
    WriteLn('=== JSON успешно загружен ===');
    WriteLn;
    
    // Получаем массивы
    Themes := Project.ItemByName['themes'] as TogsPropArray;
    Tasks := Project.ItemByName['tasks'] as TogsPropArray;
    SubTasks := Project.ItemByName['subTasks'] as TogsPropArray;
    
    WriteLn('Темы: ', Themes.Count);
    WriteLn('Задачи: ', Tasks.Count);
    WriteLn('Подзадачи: ', SubTasks.Count);
    WriteLn;
    
    // Выводим темы
    for i := 0 to Themes.Count - 1 do begin
      Theme := Themes.Item[i] as TogsPropObject;
      WriteLn('Тема ', i+1, ': ', Theme.ItemByName['title'].AsString);
      WriteLn('  ID: ', Theme.ItemByName['id'].AsString);
      WriteLn('  Описание: ', Theme.ItemByName['description'].AsString);
      WriteLn('  Активна: ', Theme.ItemByName['isActive'].AsString);
      WriteLn;
    end;
    
    // Выводим задачи
    for i := 0 to Tasks.Count - 1 do begin
      Task := Tasks.Item[i] as TogsPropObject;
      WriteLn('Задача ', i+1, ': ', Task.ItemByName['title'].AsString);
      WriteLn('  ID: ', Task.ItemByName['id'].AsString);
      WriteLn('  ThemeID: ', Task.ItemByName['themeId'].AsString);
      WriteLn('  Прогресс: ', Task.ItemByName['progress'].AsInt, '%');
      WriteLn('  Статус: ', Task.ItemByName['status'].AsInt);
      WriteLn;
    end;
    
    // Проверяем сохранение обратно в JSON
    WriteLn('=== Обратное преобразование в JSON ===');
    WriteLn(Project.ToString);
    
  finally
    Project.Free;
  end;
  
  WriteLn('Нажмите Enter для выхода...');
  ReadLn;
end.
