unit TestCommand;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, MonitorDatabase;

var
  Database: TMonitorDatabase;
  Theme: TTheme;

begin
  Database := TMonitorDatabase.Create('default.json');
  
  try
    // Создаем тему
    Theme.ID := 'THEME' + FormatDateTime('yymmddhhnnss', Now);
    Theme.Title := 'Grapher Development';
    Theme.Description := 'Created from chat';
    Theme.CreatedDate := Now;
    Theme.GitHubRepo := 'https://github.com/user/grapher';
    Theme.Color := '#0078D4';
    Theme.IsActive := True;
    
    if Database.AddTheme(Theme) then begin
      WriteLn('Theme added: ' + Theme.ID + ' - ' + Theme.Title);
      Database.SaveToFile('default.json');
      WriteLn('Database saved to default.json');
    end else
      WriteLn('Failed to add theme');
      
  finally
    Database.Free;
  end;
end.
