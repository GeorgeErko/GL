unit MonitorDatabase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ogcProperties;

type
  // База данных мониторинга
  TMonitorDatabase = class
  private
    fProject: TogsPropObject;  // ← Единственное хранилище
    fFileName: string;
    
  public
    property Project: TogsPropObject read fProject;
    constructor Create(const FileName: string = '');
    destructor Destroy; override;
    
    // Только базовые операции:
    procedure LoadFromFile(FileName: string);
    procedure SaveToFile(FileName: string);
  end;

implementation

{ TMonitorDatabase }

constructor TMonitorDatabase.Create(const FileName: string);
begin
  inherited Create;
  fFileName := FileName;
  fProject := TogsPropObject.Create;  // ← Создаем хранилище
  
  if (FileName <> '') and FileExists(FileName) then
    LoadFromFile(FileName);
end;

destructor TMonitorDatabase.Destroy;
begin
  if (fFileName <> '') then
    SaveToFile(fFileName);
  fProject.Free;
  inherited Destroy;
end;

procedure TMonitorDatabase.LoadFromFile(FileName: string);
var
  JsonContent: string;
begin
  if FileExists(FileName) then begin
    with TStringList.Create do begin
      LoadFromFile(FileName);
      JsonContent := Text;
      Free;
    end;
    fProject.FromString(JsonContent);
  end else begin
    // Создаем пустую структуру
    fProject.AddItem(TogsProperty.Create('themes', TogsPropArray.Create));
    fProject.AddItem(TogsProperty.Create('tasks', TogsPropArray.Create));
    fProject.AddItem(TogsProperty.Create('subTasks', TogsPropArray.Create));
  end;
end;

procedure TMonitorDatabase.SaveToFile(FileName: string);
begin
  with TStringList.Create do begin
    Text := fProject.ToString;
    SaveToFile(FileName);
    Free;
  end;
end;

end.
