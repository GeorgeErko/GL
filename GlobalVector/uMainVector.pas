unit uMainVector;

{$mode objfpc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Menus,
  ogcRegistry, ogcBasic,
  uLas3Drenderform,
  uMap2DRenderForm;

type

  { TMainVector }

  TMainVector = class(TForm)
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    miOpenProj: TMenuItem;
    miSaveProj: TMenuItem;
    miSaveAsProj: TMenuItem;
    ODProj: TOpenDialog;
    SDProj: TSaveDialog;
    PanelLeft: TPanel;
    PanelRight: TPanel;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure miOpenProjClick(Sender: TObject);
    procedure miSaveAsProjClick(Sender: TObject);
    procedure miSaveProjClick(Sender: TObject);
    procedure Splitter1Moved(Sender: TObject);
  private
    F3D: TLas3DRenderForm;
    F2D: TMap2DRenderForm;
    FLeftRatio: Double;
    FInResize: Boolean;
    FProjectFileName: String;
    procedure UpdateLeftRatio;
    function LoadRegStr(const Key: AnsiString): String;
    procedure SaveRegStr(const Key: AnsiString; const Value: String);
    procedure OpenProjectFile(const FileName: String);
    procedure SaveProjectFile(const FileName: String);
  public
  end;

var
  MainVector: TMainVector;

implementation

{$R *.frm}

const
  REG_FILE_NAME = 'theGrapher.reg';
  REG_PFX_MAINVECTOR = 'MainVector\';
  REG_KEY_LAST_DIR_PROJECT = 'Dialogs\MainVector\LastDirProject';

  PROJ_KEY_LAS = 'Project\LasFile';
  PROJ_KEY_GMF = 'Project\GmfFile';

function RegistryFileName: String;
begin
  Result := ExtractFilePath(Application.ExeName) + REG_FILE_NAME;
end;

procedure LoadRegistry(Reg: TogsVarRegistry);
var
  st: TogsStream;
  fn: String;
begin
  if Reg = nil then Exit;
  fn := RegistryFileName;
  if not FileExists(fn) then Exit;
  st := TogsStream.CreateFileStream(fn, fmOpenRead or fmShareDenyWrite, nil);
  try
    if st.Size > 0 then
      Reg.LoadFromStream(st);
  finally
    st.Free;
  end;
end;

procedure SaveRegistry(Reg: TogsVarRegistry);
var
  st: TogsStream;
  fn: String;
begin
  if Reg = nil then Exit;
  fn := RegistryFileName;
  st := TogsStream.CreateFileStream(fn, fmCreate or fmShareDenyWrite, nil);
  try
    Reg.SaveToStream(st);
  finally
    st.Free;
  end;
end;

function TMainVector.LoadRegStr(const Key: AnsiString): String;
var
  reg: TogsVarRegistry;
begin
  Result := '';
  reg := TogsVarRegistry.Create;
  try
    LoadRegistry(reg);
    Result := String(reg.GetStr(Key, ''));
  finally
    reg.Free;
  end;
end;

procedure TMainVector.SaveRegStr(const Key: AnsiString; const Value: String);
var
  reg: TogsVarRegistry;
begin
  if Value = '' then Exit;
  reg := TogsVarRegistry.Create;
  try
    LoadRegistry(reg);
    reg.SetStr(Key, AnsiString(Value));
    SaveRegistry(reg);
  finally
    reg.Free;
  end;
end;

procedure TMainVector.OpenProjectFile(const FileName: String);
var
  reg: TogsVarRegistry;
  st: TogsStream;
  lasFn: String;
  gmfFn: String;
begin
  if (FileName = '') or (not FileExists(FileName)) then Exit;

  reg := TogsVarRegistry.Create;
  try
    st := TogsStream.CreateFileStream(FileName, fmOpenRead or fmShareDenyWrite, nil);
    try
      if st.Size > 0 then
        reg.LoadFromStream(st);
    finally
      st.Free;
    end;

    lasFn := String(reg.GetStr(PROJ_KEY_LAS, ''));
    gmfFn := String(reg.GetStr(PROJ_KEY_GMF, ''));
  finally
    reg.Free;
  end;

  FProjectFileName := FileName;

  if (F3D <> nil) and (lasFn <> '') and FileExists(lasFn) then
    F3D.OpenLasFile(lasFn);
  if (F2D <> nil) and (gmfFn <> '') and FileExists(gmfFn) then
    F2D.OpenGmfFile(gmfFn);
end;

procedure TMainVector.SaveProjectFile(const FileName: String);
var
  reg: TogsVarRegistry;
  st: TogsStream;
  lasFn: String;
  gmfFn: String;
begin
  if FileName = '' then Exit;

  lasFn := '';
  gmfFn := '';
  if F3D <> nil then
    lasFn := F3D.CurrentLasFile;
  if F2D <> nil then
    gmfFn := F2D.CurrentGmfFile;

  reg := TogsVarRegistry.Create;
  try
    reg.SetStr(PROJ_KEY_LAS, AnsiString(lasFn));
    reg.SetStr(PROJ_KEY_GMF, AnsiString(gmfFn));

    st := TogsStream.CreateFileStream(FileName, fmCreate or fmShareDenyWrite, nil);
    try
      reg.SaveToStream(st);
    finally
      st.Free;
    end;
  finally
    reg.Free;
  end;

  FProjectFileName := FileName;
end;

procedure TMainVector.UpdateLeftRatio;
var
  avail: Integer;
begin
  avail := ClientWidth - Splitter1.Width;
  if avail <= 0 then Exit;
  FLeftRatio := PanelLeft.Width / avail;
end;

procedure TMainVector.FormCreate(Sender: TObject);
var
  reg: TogsVarRegistry;
  w, h, l, t: Integer;
  leftW: Integer;
  ws: Integer;
begin
  FProjectFileName := '';

  reg := TogsVarRegistry.Create;
  try
    LoadRegistry(reg);
    l := reg.GetInt(REG_PFX_MAINVECTOR + 'Left', Left);
    t := reg.GetInt(REG_PFX_MAINVECTOR + 'Top', Top);
    w := reg.GetInt(REG_PFX_MAINVECTOR + 'Width', Width);
    h := reg.GetInt(REG_PFX_MAINVECTOR + 'Height', Height);
    ws := reg.GetInt(REG_PFX_MAINVECTOR + 'WindowState', Ord(wsNormal));
    SetBounds(l, t, w, h);
  finally
    reg.Free;
  end;

  F3D := TLas3DRenderForm.Create(Self);
  F3D.OwnerForm := Self;
  F3D.BorderStyle := bsNone;
  F3D.Caption := '';
  F3D.Parent := PanelLeft;
  F3D.Align := alClient;
  F3D.Visible := True;

  if PanelLeft <> nil then
    PanelLeft.Constraints.MinWidth := 0;
  if PanelRight <> nil then
    PanelRight.Constraints.MinWidth := 0;
  if Splitter1 <> nil then
    Splitter1.MinSize := 0;

  F2D := TMap2DRenderForm.Create(Self);
  F2D.OwnerForm := Self;
  F2D.BorderStyle := bsNone;
  F2D.Caption := '';
  F2D.Parent := PanelRight;
  F2D.Align := alClient;
  F2D.Visible := True;

  reg := TogsVarRegistry.Create;
  try
    LoadRegistry(reg);
    leftW := reg.GetInt(REG_PFX_MAINVECTOR + 'PanelLeftWidth', PanelLeft.Width);
    if leftW > 0 then
      PanelLeft.Width := leftW;
  finally
    reg.Free;
  end;

  UpdateLeftRatio;

  if ws = Ord(wsMaximized) then
    WindowState := wsMaximized
  else
    WindowState := wsNormal;
end;

procedure TMainVector.FormDestroy(Sender: TObject);
var
  reg: TogsVarRegistry;
begin
  reg := TogsVarRegistry.Create;
  try
    LoadRegistry(reg);
    reg.SetInt(REG_PFX_MAINVECTOR + 'WindowState', Ord(WindowState));
    if WindowState = wsNormal then
    begin
      reg.SetInt(REG_PFX_MAINVECTOR + 'Left', Left);
      reg.SetInt(REG_PFX_MAINVECTOR + 'Top', Top);
      reg.SetInt(REG_PFX_MAINVECTOR + 'Width', Width);
      reg.SetInt(REG_PFX_MAINVECTOR + 'Height', Height);
    end;
    reg.SetInt(REG_PFX_MAINVECTOR + 'PanelLeftWidth', PanelLeft.Width);
    SaveRegistry(reg);
  finally
    reg.Free;
  end;

  FreeAndNil(F2D);
  FreeAndNil(F3D);
end;

procedure TMainVector.FormResize(Sender: TObject);
var
  avail: Integer;
  newLeft: Integer;
begin
  if FInResize then Exit;
  FInResize := True;
  try
    avail := ClientWidth - Splitter1.Width;
    if avail <= 0 then Exit;

    if FLeftRatio <= 0 then
      UpdateLeftRatio;

    newLeft := Round(avail * FLeftRatio);
    if newLeft < 0 then newLeft := 0;
    if newLeft > avail then newLeft := avail;

    PanelLeft.Width := newLeft;
  finally
    FInResize := False;
  end;
end;

procedure TMainVector.miOpenProjClick(Sender: TObject);
var
  fn: String;
  lastDir: String;
begin
  if ODProj = nil then Exit;
  lastDir := LoadRegStr(REG_KEY_LAST_DIR_PROJECT);
  if (lastDir <> '') and DirectoryExists(lastDir) then
    ODProj.InitialDir := lastDir;

  if not ODProj.Execute then Exit;
  fn := ODProj.FileName;
  if fn = '' then Exit;

  SaveRegStr(REG_KEY_LAST_DIR_PROJECT, ExtractFileDir(fn));
  OpenProjectFile(fn);
end;

procedure TMainVector.miSaveAsProjClick(Sender: TObject);
var
  fn: String;
  lastDir: String;
begin
  if SDProj = nil then Exit;
  lastDir := LoadRegStr(REG_KEY_LAST_DIR_PROJECT);
  if (lastDir <> '') and DirectoryExists(lastDir) then
    SDProj.InitialDir := lastDir;

  if FProjectFileName <> '' then
    SDProj.FileName := FProjectFileName;

  if not SDProj.Execute then Exit;
  fn := SDProj.FileName;
  if fn = '' then Exit;

  SaveRegStr(REG_KEY_LAST_DIR_PROJECT, ExtractFileDir(fn));
  SaveProjectFile(fn);
end;

procedure TMainVector.miSaveProjClick(Sender: TObject);
begin
  if FProjectFileName = '' then
  begin
    miSaveAsProjClick(Sender);
    Exit;
  end;
  SaveProjectFile(FProjectFileName);
end;

procedure TMainVector.Splitter1Moved(Sender: TObject);
begin
  UpdateLeftRatio;
end;

end.
