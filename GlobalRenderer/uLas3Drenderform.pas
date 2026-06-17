unit uLas3Drenderform;

{$mode Delphi}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, OpenGLPanel,
 Menus, ComCtrls, StdCtrls, Spin, Buttons, ComboEx, IniFiles, Math,
 uogslasrenderer, ogcLas, uLasPointCloudTiles, ogcBasic, ogcRegistry, plugTrees,
 uLasFileContext, uLasSceneController;

type

 { TLas3DRenderForm }

 TLas3DRenderForm = class(TForm)
  AlphaBar: TTrackBar;
  BlendCheck: TCheckBox;
  Button2D: TButton;
  Button3D: TButton;
  ButtonReset: TButton;
  cbTileSize: TComboBox;
  ColorModeCombo: TComboBox;
  cbClouds: TComboBox;
  DeltaZEdit: TFloatSpinEdit;
  kZoom: TCheckBox;
  Label2: TLabel;
  Label3: TLabel;
  Panel1: TPanel;
  r3sbAddLas1: TSpeedButton;
  r3sbAddLas2: TSpeedButton;
  r3sbOpen: TSpeedButton;
  r3sbOpen1: TSpeedButton;
  r3sbAddLas: TSpeedButton;
  sbRun1: TSpeedButton;
  sbRun2: TSpeedButton;
  ZoomKEdit: TFloatSpinEdit;
  Label1: TLabel;
  LabelCamera: TLabel;
  LabelZInfo: TLabel;
  MenuFileInfo: TMenuItem;
  ODLAS: TOpenDialog;
  OpenGLPanel1: TOpenGLPanel;
  r3pnlBottom: TPanel;
  r3MainMenu1: TMainMenu;
  MenuFile: TMenuItem;
  MenuFileOpen: TMenuItem;
  MenuFileOpenTrees: TMenuItem;
  PlaneCheck: TCheckBox;
  ProgressBar1: TProgressBar;
  r3pnlTop: TPanel;
  TilesCheck: TCheckBox;
  UpdateTimer: TTimer;
  UpDown1: TUpDown;
  procedure cbCloudsChange(Sender: TObject);
  procedure cbTileSizeChange(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure FormDestroy(Sender: TObject);
  procedure LabelCameraClick(Sender: TObject);
  procedure MenuFileOpenClick(Sender: TObject);
  procedure MenuFileInfoClick(Sender: TObject);
  procedure MenuFileOpenTreesClick(Sender: TObject);
  procedure OpenGLPanel1Click(Sender: TObject);
  procedure OpenGLPanel1Paint(Sender: TObject);
  procedure OpenGLPanel1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure OpenGLPanel1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  procedure OpenGLPanel1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure OpenGLPanel1MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  procedure sbRun1Click(Sender: TObject);
  procedure Button2DClick(Sender: TObject);
  procedure Button3DClick(Sender: TObject);
  procedure ButtonResetClick(Sender: TObject);
  procedure Panel1Click(Sender: TObject);
  procedure PointSizeSpinChange(Sender: TObject);
  procedure sbRun2Click(Sender: TObject);
  procedure UIChanged(Sender: TObject);
  procedure ColorModeComboChange(Sender: TObject);
  procedure UpdateTimerTimer(Sender: TObject);
  procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
  procedure r3sbAddLasClick(Sender: TObject);
 private
  FScene: TLasSceneController;
  FRenderer: TLasRenderer;
  FTreeList: TplugTreeList;
  FGLInited: Boolean;
  FUpdatingUI: Boolean;
  FPainting: Boolean;
  FMouseDragging: Boolean;
  FLastInteractTick: QWord;
  FTargetRenderFrac: Single;
  FLastPaintTick: QWord;
  FLxtFileName: String;
  FCurrentLasFile: String;
  FRun2SegIndex: Integer;
  FRun2SegS: Double;
  FRun2LastTick: QWord;
  FRun2Speed: Double;
  function ActiveContext: TLasFileContext;
  procedure RebuildCloudsCombo;
  function GetLas: TogsLas;
  function GetTiles: TLasPointCloudTiles;
  procedure OnTilesProgress(Sender: TObject; APos, AMax: Integer);
  procedure UpdateCameraLabel;
  procedure UpdateZInfoLabel;
  procedure SaveSettings;
  procedure LoadSettings;
  procedure PopulateColorModeCombo;
  procedure SyncColorModeComboFromTiles;
 public
  OwnerForm: TForm;
  function CurrentLasFile: String;
  procedure OpenLasFile(const FileName: String);
  property Las: TogsLas read GetLas;
  property Tiles: TLasPointCloudTiles read GetTiles;
 end;

var
 Las3DRenderForm: TLas3DRenderForm;

implementation uses dglOpenGL, ogcWriter, ClipBrd, uLasMmapSource24;

{$R *.frm}

const
  REG_FILE_NAME = 'theGrapher.reg';
  REG_KEY_LAST_DIR_LAS = 'Dialogs\Las3D\LastDirLas';
  REG_KEY_LAST_DIR_TREES = 'Dialogs\Las3D\LastDirTreesCsv';

function RegistryFileName: String;
begin
  Result := ExtractFilePath(Application.ExeName) + REG_FILE_NAME;
end;

function LoadRegStr(const Key: AnsiString): String;
var
  reg: TogsVarRegistry;
  st: TogsStream;
  fn: String;
begin
  Result := '';
  reg := TogsVarRegistry.Create;
  try
    fn := RegistryFileName;
    if FileExists(fn) then
    begin
      st := TogsStream.CreateFileStream(fn, fmOpenRead or fmShareDenyWrite, nil);
      try
        if st.Size > 0 then
          reg.LoadFromStream(st);
      finally
        st.Free;
      end;
    end;
    Result := String(reg.GetStr(Key, ''));
  finally
    reg.Free;
  end;
end;

procedure SaveRegStr(const Key: AnsiString; const Value: String);
var
  reg: TogsVarRegistry;
  st: TogsStream;
  fn: String;
begin
  if Value = '' then Exit;
  reg := TogsVarRegistry.Create;
  try
    fn := RegistryFileName;
    if FileExists(fn) then
    begin
      st := TogsStream.CreateFileStream(fn, fmOpenRead or fmShareDenyWrite, nil);
      try
        if st.Size > 0 then
          reg.LoadFromStream(st);
      finally
        st.Free;
      end;
    end;

    reg.SetStr(Key, AnsiString(Value));

    st := TogsStream.CreateFileStream(fn, fmCreate or fmShareDenyWrite, nil);
    try
      reg.SaveToStream(st);
    finally
      st.Free;
    end;
  finally
    reg.Free;
  end;
end;
//
procedure TLas3DRenderForm.FormCreate(Sender: TObject);
begin
// Menu := nil;
 FScene := TLasSceneController.Create(OpenGLPanel1);
 FRenderer := FScene;
 FTreeList := TplugTreeList.Create(OpenGLPanel1);
 FGLInited := False;
 FUpdatingUI := False;
 FLastInteractTick := 0;
 FLastPaintTick := 0;
 FPainting := False;
 FTargetRenderFrac := 1.0;
 FRun2SegIndex := 0;
 FRun2SegS := 0;
 FRun2LastTick := 0;
 FRun2Speed := 5.0;
 FRenderer.RenderFrac := 1.0;
 FRenderer.BlendEnabled := (BlendCheck <> nil) and BlendCheck.Checked;
 if AlphaBar <> nil then
  FRenderer.Alpha := AlphaBar.Position / 255.0
 else
  FRenderer.Alpha := 1.0;
 FLxtFileName := '';
 FCurrentLasFile := '';
 ProgressBar1.Visible := False;
 UpDown1.Position := 2;
 if cbTileSize <> nil then
  cbTileSize.OnChange := cbTileSizeChange;
 if cbClouds <> nil then
  cbClouds.OnChange := cbCloudsChange;
 if r3sbAddLas <> nil then
  r3sbAddLas.OnClick := r3sbAddLasClick;
 if sbRun1 <> nil then
  sbRun1.OnClick := sbRun1Click;
 //
 PopulateColorModeCombo;
 SyncColorModeComboFromTiles;
//
 OpenGLPanel1.Color := clBtnFace;
//
 If not InitOpenGL then
  raise Exception.Create('noInitGL');
end;

procedure TLas3DRenderForm.cbTileSizeChange(Sender: TObject);
var
 v: Double;
begin
 if FUpdatingUI then Exit;
 if (FRenderer = nil) or (cbTileSize = nil) then Exit;
 if TryStrToFloat(Trim(cbTileSize.Text), v) then
 begin
  FRenderer.DynaLodTileSize := v;
  OpenGLPanel1.Invalidate;
  SaveSettings;
 end;
end;

//
procedure TLas3DRenderForm.FormDestroy(Sender: TObject);
begin
 SaveSettings;
 FreeAndNil(FTreeList);
 FRenderer := nil;
 FreeAndNil(FScene);
end;

function TLas3DRenderForm.GetLas: TogsLas;
begin
 if ActiveContext <> nil then
  Result := ActiveContext.Las
 else
  Result := nil;
end;

function TLas3DRenderForm.GetTiles: TLasPointCloudTiles;
begin
 if ActiveContext <> nil then
  Result := ActiveContext.Tiles
 else
  Result := nil;
end;

function TLas3DRenderForm.ActiveContext: TLasFileContext;
begin
 Result := nil;
 if (cbClouds = nil) then Exit;
 if (cbClouds.ItemIndex < 0) or (cbClouds.ItemIndex >= cbClouds.Items.Count) then Exit;
 Result := TLasFileContext(cbClouds.Items.Objects[cbClouds.ItemIndex]);
end;

procedure TLas3DRenderForm.RebuildCloudsCombo;
var
 i: Integer;
 ctx: TLasFileContext;
 fn: String;
 activeIdx: Integer;
begin
 if (cbClouds = nil) or (FScene = nil) then Exit;
 FUpdatingUI := True;
 try
  activeIdx := cbClouds.ItemIndex;
  cbClouds.Items.BeginUpdate;
  try
   cbClouds.Items.Clear;
   for i := 0 to FScene.ContextCount - 1 do
   begin
    ctx := FScene.Contexts[i];
    if (ctx = nil) then Continue;
    fn := ExtractFileName(ctx.FileName);
    cbClouds.Items.AddObject(fn, ctx);
   end;
  finally
   cbClouds.Items.EndUpdate;
  end;
  if (activeIdx >= 0) and (activeIdx < cbClouds.Items.Count) then
   cbClouds.ItemIndex := activeIdx
  else if cbClouds.Items.Count > 0 then
   cbClouds.ItemIndex := 0;
 finally
  FUpdatingUI := False;
 end;
end;

procedure TLas3DRenderForm.cbCloudsChange(Sender: TObject);
begin
 if FUpdatingUI then Exit;
 SyncColorModeComboFromTiles;
 if (cbTileSize <> nil) and (FRenderer <> nil) then
 begin
  FUpdatingUI := True;
  try
   cbTileSize.Text := FloatToStr(FRenderer.DynaLodTileSize);
  finally
   FUpdatingUI := False;
  end;
 end;
 UpdateZInfoLabel;
 OpenGLPanel1.Invalidate;
end;

procedure TLas3DRenderForm.r3sbAddLasClick(Sender: TObject);
var
 dlg: TOpenDialog;
 fn: String;
 i: Integer;
 ctx: TLasFileContext;
 pdrf: Integer;
begin
 if FScene = nil then Exit;
 dlg := ODLAS;
 if dlg <> nil then
  dlg.Options := dlg.Options + [ofAllowMultiSelect];
 if (dlg = nil) or (not dlg.Execute) then Exit;
 if (dlg.Files <> nil) and (dlg.Files.Count > 0) then
  fn := dlg.Files[0]
 else
  fn := dlg.FileName;
 if (fn = '') or (not FileExists(fn)) then Exit;

 ProgressBar1.Visible := True;
 ProgressBar1.Position := 0;
 Application.ProcessMessages;
 Screen.Cursor := crHourglass;
 try
  if (dlg.Files <> nil) and (dlg.Files.Count > 0) then
  begin
   for i := 0 to dlg.Files.Count - 1 do
   begin
    fn := dlg.Files[i];
    if (fn = '') or (not FileExists(fn)) then
     Continue;

    ctx := FScene.AddContext;
    if ctx.Tiles <> nil then
     ctx.Tiles.OnProgress := OnTilesProgress;
    if not ctx.Open(fn) then
    begin
     ShowMessage('Не удалось открыть LAS файл');
     Continue;
    end;

    if FScene <> nil then
     FScene.LoadPoslOnceFromDir(ExtractFileDir(fn));

    if FScene <> nil then
     FScene.MarkBBoxDirty;

    FCurrentLasFile := fn;
    FLxtFileName := ChangeFileExt(fn, '.lxt');
    FRenderer.StateFileName := FLxtFileName;

    if (ctx.Tiles <> nil) and (ctx.Las <> nil) and (ctx.Las.Source <> nil) and (ctx.Las.Source.IsOpen) then
    begin
     pdrf := ctx.Las.Source.Header.PointDataRecordFormat;
     case pdrf of
      2, 3, 5, 7, 8, 10: ctx.Tiles.ColorMode := lpcmRGB;
     else
      ctx.Tiles.ColorMode := lpcmIntensity;
     end;
    end;

   LoadSettings;

    if (ctx.Tiles <> nil) and OpenGLPanel1.MakeCurrent then
    begin
     if not FGLInited then
     begin
      ReadExtensions;
      ReadImplementationProperties;
      if Assigned(wglSwapIntervalEXT) then
       wglSwapIntervalEXT(0);
      FGLInited := True;
     end;
     ctx.Tiles.InitGL;
    end;

    if (ctx.Tiles <> nil) and (ctx.Las <> nil) and (ctx.Las.Source <> nil) and (ctx.Las.Source.IsOpen) then
     ctx.Tiles.BuildFromLas(ctx.Las, 0);
   end;
  end
  else
  begin
   fn := dlg.FileName;
   if (fn <> '') and FileExists(fn) then
   begin
    ctx := FScene.AddContext;
    if ctx.Tiles <> nil then
     ctx.Tiles.OnProgress := OnTilesProgress;
    if not ctx.Open(fn) then
    begin
     ShowMessage('Не удалось открыть LAS файл');
    end
    else
    begin
     if FScene <> nil then
      FScene.LoadPoslOnceFromDir(ExtractFileDir(fn));

     if FScene <> nil then
      FScene.MarkBBoxDirty;

     FCurrentLasFile := fn;
     FLxtFileName := ChangeFileExt(fn, '.lxt');
     FRenderer.StateFileName := FLxtFileName;

     if (ctx.Tiles <> nil) and (ctx.Las <> nil) and (ctx.Las.Source <> nil) and (ctx.Las.Source.IsOpen) then
     begin
      pdrf := ctx.Las.Source.Header.PointDataRecordFormat;
      case pdrf of
       2, 3, 5, 7, 8, 10: ctx.Tiles.ColorMode := lpcmRGB;
      else
       ctx.Tiles.ColorMode := lpcmIntensity;
      end;
     end;

     LoadSettings;

     if (ctx.Tiles <> nil) and OpenGLPanel1.MakeCurrent then
     begin
      if not FGLInited then
      begin
       ReadExtensions;
       ReadImplementationProperties;
       if Assigned(wglSwapIntervalEXT) then
        wglSwapIntervalEXT(0);
       FGLInited := True;
      end;
      ctx.Tiles.InitGL;
     end;

     if (ctx.Tiles <> nil) and (ctx.Las <> nil) and (ctx.Las.Source <> nil) and (ctx.Las.Source.IsOpen) then
      ctx.Tiles.BuildFromLas(ctx.Las, 0);
    end;
   end;
  end;

  RebuildCloudsCombo;
  if (cbClouds <> nil) and (cbClouds.Items.Count > 0) then
   cbClouds.ItemIndex := cbClouds.Items.Count - 1;
  FRenderer.ResetView;
  SyncColorModeComboFromTiles;
  UpdateZInfoLabel;
  OpenGLPanel1.Invalidate;
 finally
  Screen.Cursor := crDefault;
  ProgressBar1.Visible := False;
 end;
end;

procedure TLas3DRenderForm.LabelCameraClick(Sender: TObject);
begin
 ClipBoard.AsText := LabelCamera.Caption;
end;

//
procedure TLas3DRenderForm.MenuFileOpenClick(Sender: TObject);
var
  dlg: TOpenDialog;
  fn: String;
  lastDir: String;
  i: Integer;
begin
 dlg := ODLAS;

 if dlg <> nil then
  dlg.Options := dlg.Options + [ofAllowMultiSelect];

 if dlg <> nil then
 begin
   lastDir := LoadRegStr(REG_KEY_LAST_DIR_LAS);
   if (lastDir <> '') and DirectoryExists(lastDir) then
     dlg.InitialDir := lastDir;
 end;

 if (dlg = nil) or (not dlg.Execute) then Exit;
 if (dlg.Files <> nil) and (dlg.Files.Count > 0) then
  fn := dlg.Files[0]
 else
  fn := dlg.FileName;

 if fn <> '' then
   SaveRegStr(REG_KEY_LAST_DIR_LAS, ExtractFileDir(fn));

 if (dlg.Files <> nil) and (dlg.Files.Count > 0) then
 begin
  for i := 0 to dlg.Files.Count - 1 do
   OpenLasFile(dlg.Files[i]);
 end
 else
  OpenLasFile(fn);
end;

function TLas3DRenderForm.CurrentLasFile: String;
begin
 Result := FCurrentLasFile;
end;

procedure TLas3DRenderForm.OpenLasFile(const FileName: String);
var
 fn: String;
 pdrf: Integer;
 dx, dy: Double;
 tileDiag: Double;
 ctx: TLasFileContext;
begin
 fn := FileName;
 if (fn = '') or (not FileExists(fn)) then Exit;

 if not FileExists(fn) then Exit;
 ProgressBar1.Visible := True;
 ProgressBar1.Position := 0;
 Application.ProcessMessages;
 Screen.Cursor := crHourglass;
 try
  if FScene = nil then Exit;
  ctx := FScene.AddContext;
  if ctx.Tiles <> nil then
   ctx.Tiles.OnProgress := OnTilesProgress;
  if not ctx.Open(fn) then
  begin
   ShowMessage('Не удалось открыть LAS файл');
   ProgressBar1.Visible := False;
   Exit;
  end;

  if FScene <> nil then
   FScene.LoadPoslOnceFromDir(ExtractFileDir(fn));

  if FScene <> nil then
   FScene.MarkBBoxDirty;
  FCurrentLasFile := fn;
  FLxtFileName := ChangeFileExt(fn, '.lxt');
  FRenderer.StateFileName := FLxtFileName;

  if (ctx.Tiles <> nil) and (ctx.Las <> nil) and (ctx.Las.Source <> nil) and (ctx.Las.Source.IsOpen) then
  begin
   pdrf := ctx.Las.Source.Header.PointDataRecordFormat;
   case pdrf of
    2, 3, 5, 7, 8, 10: ctx.Tiles.ColorMode := lpcmRGB;
   else
    ctx.Tiles.ColorMode := lpcmIntensity;
   end;
  end;

  LoadSettings;

  if (ctx.Tiles <> nil) and OpenGLPanel1.MakeCurrent then
  begin
   if not FGLInited then
   begin
    ReadExtensions;
    ReadImplementationProperties;
    if Assigned(wglSwapIntervalEXT) then
     wglSwapIntervalEXT(0);
    FGLInited := True;
   end;
   ctx.Tiles.InitGL;
  end;

  if (ctx.Tiles <> nil) and (ctx.Las <> nil) and (ctx.Las.Source <> nil) and (ctx.Las.Source.IsOpen) then
   ctx.Tiles.BuildFromLas(ctx.Las, 0);

  if (ctx.Tiles <> nil) and (cbTileSize <> nil) then
  begin
   ctx.Tiles.GetGridTileStep(dx, dy);
   tileDiag := Hypot(dx, dy);
   if tileDiag > 0 then
   begin
    FUpdatingUI := True;
    try
     cbTileSize.Text := FloatToStr(Round(tileDiag));
    finally
     FUpdatingUI := False;
    end;
    cbTileSizeChange(nil);
   end;
  end;

  FRenderer.ResetView;
  SyncColorModeComboFromTiles;
  UpdateZInfoLabel;
  FRenderer.RenderFrac := 1.0;
  FTargetRenderFrac := 1.0;
  ProgressBar1.Visible := False;
  RebuildCloudsCombo;
  if cbClouds <> nil then
   cbClouds.ItemIndex := cbClouds.Items.IndexOfObject(ctx);
  OpenGLPanel1.Invalidate;
 finally
  Screen.Cursor := crDefault;
 end;
end;

procedure TLas3DRenderForm.MenuFileOpenTreesClick(Sender: TObject);
var
  dlg: TOpenDialog;
  fn: String;
  cnt: Integer;
  removed: Integer;
  lastDir: String;
begin
 dlg := TOpenDialog.Create(Self);
 try
  dlg.Filter := 'CSV files (*.csv)|*.csv|All files (*.*)|*.*';

  lastDir := LoadRegStr(REG_KEY_LAST_DIR_TREES);
  if (lastDir <> '') and DirectoryExists(lastDir) then
    dlg.InitialDir := lastDir;

  if not dlg.Execute then Exit;
  fn := dlg.FileName;
 finally
  dlg.Free;
 end;

 if fn <> '' then
   SaveRegStr(REG_KEY_LAST_DIR_TREES, ExtractFileDir(fn));

 if FTreeList = nil then
  FTreeList := TplugTreeList.Create(OpenGLPanel1);
 cnt := FTreeList.LoadFromCsv(fn);
 removed := 0;
 if (Las <> nil) and (Las.Source <> nil) and (Las.Source.IsOpen) then
  removed := FTreeList.FilterByBBoxXY(Las.Source.Header.MinX, Las.Source.Header.MaxX,
                                      Las.Source.Header.MinY, Las.Source.Header.MaxY);
 if removed > 0 then
  ShowMessage('Загружено деревьев: ' + IntToStr(cnt) + '  Удалено вне bbox(XY): ' + IntToStr(removed))
 else
  ShowMessage('Загружено деревьев: ' + IntToStr(cnt));
end;

procedure TLas3DRenderForm.OpenGLPanel1Click(Sender: TObject);
begin

end;

procedure TLas3DRenderForm.MenuFileInfoClick(Sender: TObject);
var
 h: TLASHeader;
 s, sysId, genSw, fileName: String;
 sizeX, sizeY, sizeZ: Double;
 cX, cY, cZ: Double;
 hasRGB: Boolean;
 hasGpsTime: Boolean;
 byRet: String;
 i: Integer;

 function AnsiArrayToString(const A: array of AnsiChar): String;
 var
  i, n: Integer;
 begin
  n := Length(A);
  i := 0;
  while (i < n) and (A[i] <> #0) do Inc(i);
  SetString(Result, PAnsiChar(@A[0]), i);
  Result := Trim(Result);
 end;

begin
 if (Las = nil) or (Las.Source = nil) or (not Las.Source.IsOpen) then
 begin
  ShowMessage('Файл не загружен');
  Exit;
 end;

 h := Las.Source.Header;
 fileName := Las.FileName;
 sysId := AnsiArrayToString(h.SystemIdentifier);
 genSw := AnsiArrayToString(h.GeneratingSoftware);
 hasRGB := (h.PointDataRecordFormat = 2) or (h.PointDataRecordFormat = 3) or
           (h.PointDataRecordFormat = 5) or (h.PointDataRecordFormat = 7) or
           (h.PointDataRecordFormat = 8) or (h.PointDataRecordFormat = 10);
 hasGpsTime := (h.PointDataRecordFormat = 1) or (h.PointDataRecordFormat = 3);
 sizeX := h.MaxX - h.MinX;
 sizeY := h.MaxY - h.MinY;
 sizeZ := h.MaxZ - h.MinZ;
 cX := (h.MinX + h.MaxX) * 0.5;
 cY := (h.MinY + h.MaxY) * 0.5;
 cZ := (h.MinZ + h.MaxZ) * 0.5;

 s := '';
 s := s + 'Файл: ' + fileName + LineEnding;
 s := s + 'Точек: ' + IntToStr(Las.Source.PointCount) + LineEnding;
 s := s + Format('LAS: %d.%d  HeaderSize: %d  OffsetToPointData: %d  VLR: %d', [h.VersionMajor, h.VersionMinor, h.HeaderSize, h.OffsetToPointData, h.NumberOfVLR]) + LineEnding;
 s := s + Format('FileSourceID: %d  GlobalEncoding: %d', [h.FileSourceID, h.GlobalEncoding]) + LineEnding;
 s := s + Format('PointFormat: %d  RecLen: %d  RGB: %d  GPSTime: %d', [h.PointDataRecordFormat, h.PointDataRecordLength, Ord(hasRGB), Ord(hasGpsTime)]) + LineEnding;
 if (h.FileCreationYear <> 0) or (h.FileCreationDayOfYear <> 0) then
  s := s + Format('Created: %d day %d', [h.FileCreationYear, h.FileCreationDayOfYear]) + LineEnding;
 if sysId <> '' then
  s := s + 'SystemIdentifier: ' + sysId + LineEnding;
 if genSw <> '' then
  s := s + 'GeneratingSoftware: ' + genSw + LineEnding;
 byRet := '';
 for i := 0 to High(h.LegacyNumberOfPointsByReturn) do
 begin
  if byRet <> '' then byRet := byRet + ' ';
  byRet := byRet + IntToStr(h.LegacyNumberOfPointsByReturn[i]);
 end;
 if byRet <> '' then
  s := s + 'ByReturn: ' + byRet + LineEnding;
 s := s + Format('Scale: %.12g %.12g %.12g', [h.ScaleX, h.ScaleY, h.ScaleZ]) + LineEnding;
 s := s + Format('Offset: %.12g %.12g %.12g', [h.OffsetX, h.OffsetY, h.OffsetZ]) + LineEnding;
 s := s + Format('BBox Min: %.12g %.12g %.12g', [h.MinX, h.MinY, h.MinZ]) + LineEnding;
 s := s + Format('BBox Max: %.12g %.12g %.12g', [h.MaxX, h.MaxY, h.MaxZ]) + LineEnding;
 s := s + Format('Size: %.12g %.12g %.12g', [sizeX, sizeY, sizeZ]) + LineEnding;
 s := s + Format('Center: %.12g %.12g %.12g', [cX, cY, cZ]) + LineEnding;
 if FRenderer <> nil then
  s := s + Format('Camera: Yaw %.3g  Pitch %.3g  FOV %.3g  Dist %.6g  Pan %.6g %.6g %.6g',
   [FRenderer.Yaw, FRenderer.Pitch, FRenderer.FovDeg, FRenderer.Distance, FRenderer.PanX, FRenderer.PanY, FRenderer.PanZ]) + LineEnding;
 ClipBoard.AsText := S;
 ShowMessage(s);
end;
//
procedure TLas3DRenderForm.OpenGLPanel1Paint(Sender: TObject);
var
 minX, minY, minZ: Double;
 maxX, maxY, maxZ: Double;
 originX, originY, originZ: Double;
 haveOrigin: Boolean;
begin
 if FRenderer = nil then Exit;
 if FPainting then Exit;
 FPainting := True;
 try
  if not OpenGLPanel1.MakeCurrent then Exit;
  if not FGLInited then
  begin
   ReadExtensions;
   ReadImplementationProperties;
   if Assigned(wglSwapIntervalEXT) then
    wglSwapIntervalEXT(0);
   FGLInited := True;
   if FScene <> nil then
    FScene.InitGL;
  end;
  haveOrigin := False;
  if (FScene <> nil) and FScene.GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ) then
  begin
   originX := (minX + maxX) * 0.5;
   originY := (minY + maxY) * 0.5;
   originZ := (minZ + maxZ) * 0.5;
   haveOrigin := True;
  end;
  FRenderer.Render;
  if haveOrigin and (FTreeList <> nil) then
   FTreeList.RenderTrees(originX, originY, originZ);
  OpenGLPanel1.SwapBuffers;
 finally
  FPainting := False;
 end;
end;
//
procedure TLas3DRenderForm.OpenGLPanel1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if ((sbRun1 <> nil) and sbRun1.Down) or ((sbRun2 <> nil) and sbRun2.Down) then Exit;
 if FRenderer <> nil then
 begin
  FRenderer.UseDyna := True;
  FRenderer.MouseDown(Button, Shift, X, Y);
  FMouseDragging := True;
 end;
end;
//
procedure TLas3DRenderForm.OpenGLPanel1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var tick: QWord;
begin
 if ((sbRun1 <> nil) and sbRun1.Down) or ((sbRun2 <> nil) and sbRun2.Down) then Exit;
 if FRenderer <> nil then
 begin
  if not FMouseDragging then
  begin
   FRenderer.UseDyna := False;
   Exit;
  end;
  FRenderer.UseDyna := True;
  FRenderer.MouseMove(Shift, X, Y);
  UpdateCameraLabel;
  tick := GetTickCount64;
  FLastInteractTick := tick;
  FRenderer.RenderFrac := 1.0;
  FTargetRenderFrac := 1.0;
  if (tick - FLastPaintTick) >= 33 then
  begin
   FLastPaintTick := tick;
   OpenGLPanel1.Invalidate;
  end;
 end;
end;
//
procedure TLas3DRenderForm.OpenGLPanel1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if ((sbRun1 <> nil) and sbRun1.Down) or ((sbRun2 <> nil) and sbRun2.Down) then
 begin
  FMouseDragging := False;
  Exit;
 end;
 if FRenderer <> nil then
 begin
  FRenderer.MouseUp(Button, Shift, X, Y);
  FRenderer.UseDyna := False;
  FMouseDragging := False;
  FLastInteractTick := GetTickCount64;
  FRenderer.RenderFrac := 1.0;
  FTargetRenderFrac := 1.0;
  OpenGLPanel1.Invalidate;
 end;
end;
//
procedure TLas3DRenderForm.OpenGLPanel1MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var p: TPoint;
begin
 if ((sbRun1 <> nil) and sbRun1.Down) or ((sbRun2 <> nil) and sbRun2.Down) then
 begin
  Handled := True;
  Exit;
 end;
 if FRenderer <> nil then
 begin
  FRenderer.UseDyna := True;
  p := OpenGLPanel1.ScreenToClient(MousePos);
  FRenderer.MouseWheel(Shift, WheelDelta, p);
  UpdateCameraLabel;
  FLastInteractTick := GetTickCount64;
  UpdateTimer.Enabled := True;
  FRenderer.RenderFrac := 1.0;
  FTargetRenderFrac := 1.0;
  OpenGLPanel1.Invalidate;
  Handled := True;
 end;
end;
//
procedure TLas3DRenderForm.Button2DClick(Sender: TObject);
begin
 if FRenderer <> nil then
 begin
  FRenderer.Mode := rmOrtho2D;
  OpenGLPanel1.Invalidate;
 end;
end;
//
procedure TLas3DRenderForm.Button3DClick(Sender: TObject);
begin
 if FRenderer <> nil then
 begin
  FRenderer.Mode := rm3D;
  OpenGLPanel1.Invalidate;
 end;
end;
//
procedure TLas3DRenderForm.ButtonResetClick(Sender: TObject);
begin
 if FRenderer <> nil then
 begin
  FRenderer.ResetView;
  OpenGLPanel1.Invalidate;
 end;
end;

procedure TLas3DRenderForm.Panel1Click(Sender: TObject);
begin

end;

procedure TLas3DRenderForm.PointSizeSpinChange(Sender: TObject);
begin

end;

procedure TLas3DRenderForm.sbRun2Click(Sender: TObject);
begin
 if (sbRun2 = nil) then Exit;
 if not sbRun2.Down then
 begin
  if FRenderer <> nil then
   FRenderer.UseDyna := False;
  UpdateTimer.Enabled := True;
  Exit;
 end;

 FRun2SegIndex := 0;
 FRun2SegS := 0;
 FRun2LastTick := GetTickCount64;
 if FRenderer <> nil then
 begin
  FRenderer.Mode := rm3D;
  FRenderer.AutoDistance := False;
  FRenderer.Pitch := -90;
  FRenderer.Distance := 10;
  FRenderer.UseDyna := False;
 end;
 UpdateTimer.Enabled := True;
end;

procedure TLas3DRenderForm.UIChanged(Sender: TObject);
begin
 if FUpdatingUI then Exit;
 if FRenderer = nil then Exit;
 FRenderer.BlendEnabled := (BlendCheck <> nil) and BlendCheck.Checked;
 if AlphaBar <> nil then
  FRenderer.Alpha := AlphaBar.Position / 255.0
 else
  FRenderer.Alpha := 1.0;
 FRenderer.ShowTileBBoxes := (TilesCheck <> nil) and TilesCheck.Checked;
 FRenderer.PlaneEnabled := (PlaneCheck <> nil) and PlaneCheck.Checked;
 if DeltaZEdit <> nil then
  FRenderer.PlaneDeltaZ := DeltaZEdit.Value
 else
  FRenderer.PlaneDeltaZ := 0;
 FRenderer.ZoomToPlaneEnabled := (kZoom <> nil) and kZoom.Checked;
 if ZoomKEdit <> nil then
  FRenderer.ZoomToPlaneK := ZoomKEdit.Value;
 OpenGLPanel1.Invalidate;
 SaveSettings;
 UpdateZInfoLabel;
end;

procedure TLas3DRenderForm.ColorModeComboChange(Sender: TObject);
var
 idx: Integer;
begin
 if FUpdatingUI then Exit;
 if (Tiles = nil) then Exit;
 if ColorModeCombo = nil then Exit;
 idx := ColorModeCombo.ItemIndex;
 if idx < 0 then Exit;
 Tiles.ColorMode := TLasPointColorMode(idx);
 SaveSettings;
 Screen.Cursor := crHourglass;
 try
  if (Las <> nil) and (Las.Source <> nil) and (Las.Source.IsOpen) then
   Tiles.BuildFromLas(Las, 0);
  OpenGLPanel1.Invalidate;
 finally
  Screen.Cursor := crDefault;
 end;
end;

procedure TLas3DRenderForm.UpdateZInfoLabel;
var
 minZ, maxZ: Double;
 dz: Double;
 minX, minY, maxX, maxY: Double;
begin
 if LabelZInfo = nil then Exit;
 if (FScene = nil) or (not FScene.GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ)) then
 begin
  LabelZInfo.Caption := '';
  Exit;
 end;
 if DeltaZEdit <> nil then
  dz := DeltaZEdit.Value
 else
  dz := 0;
 LabelZInfo.Caption := Format('MinZ: %.3f   MaxZ: %.3f   DeltaZ: %.3f   Zlevel: %.3f', [minZ, maxZ, dz, minZ + dz]);
end;

//
procedure TLas3DRenderForm.OnTilesProgress(Sender: TObject; APos, AMax: Integer);
begin
 if AMax > 0 then
 begin
  ProgressBar1.Max := AMax;
  ProgressBar1.Position := APos;
  Application.ProcessMessages;
 end;
end;
//
//
procedure TLas3DRenderForm.UpdateTimerTimer(Sender: TObject);
var
 tick: QWord;
 dt: Double;
 minX, minY, minZ, maxX, maxY, maxZ: Double;
 originX, originY, originZ: Double;
 p0x, p0y, p0z: Double;
 p1x, p1y, p1z: Double;
 ax, ay, az: Double;
 bx, by, bz: Double;
 segDx, segDy, segDz: Double;
 segLen: Double;
 segT: Double;
 yawRad: Double;
 camX, camY, camZ: Double;
begin
 //UpdateTimer.Enabled := False;

 if (sbRun2 <> nil) and sbRun2.Down and (FScene <> nil) and (FRenderer <> nil) then
 begin
  tick := GetTickCount64;
  if FRun2LastTick = 0 then
   FRun2LastTick := tick;
  dt := (tick - FRun2LastTick) / 1000.0;
  if dt < 0 then dt := 0;
  if dt > 0.2 then dt := 0.2;
  FRun2LastTick := tick;

  if not FScene.GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ) then
  begin
   UpdateTimer.Enabled := True;
   Exit;
  end;
  originX := (minX + maxX) * 0.5;
  originY := (minY + maxY) * 0.5;
  originZ := (minZ + maxZ) * 0.5;

  if (FRun2SegIndex < 0) then FRun2SegIndex := 0;
  if (FRun2SegIndex >= FScene.PoslPointCount - 1) then
  begin
   sbRun2.Down := False;
   UpdateTimer.Enabled := True;
   Exit;
  end;

  if (not FScene.GetPoslPoint(FRun2SegIndex, p0x, p0y, p0z)) or
     (not FScene.GetPoslPoint(FRun2SegIndex + 1, p1x, p1y, p1z)) then
  begin
   sbRun2.Down := False;
   UpdateTimer.Enabled := True;
   Exit;
  end;

  ax := p0x - originX;
  ay := p0y - originY;
  az := p0z - originZ;
  bx := p1x - originX;
  by := p1y - originY;
  bz := p1z - originZ;

  segDx := bx - ax;
  segDy := by - ay;
  segDz := bz - az;
  segLen := Sqrt(segDx * segDx + segDy * segDy + segDz * segDz);
  if segLen < 1E-9 then
  begin
   Inc(FRun2SegIndex);
   FRun2SegS := 0;
   UpdateTimer.Enabled := True;
   Exit;
  end;

  FRun2SegS := FRun2SegS + dt * Max(0.1, FRun2Speed);
  while (FRun2SegS >= segLen) and (FRun2SegIndex < FScene.PoslPointCount - 2) do
  begin
   FRun2SegS := FRun2SegS - segLen;
   Inc(FRun2SegIndex);

   if (not FScene.GetPoslPoint(FRun2SegIndex, p0x, p0y, p0z)) or
      (not FScene.GetPoslPoint(FRun2SegIndex + 1, p1x, p1y, p1z)) then
    Break;
   ax := p0x - originX;
   ay := p0y - originY;
   az := p0z - originZ;
   bx := p1x - originX;
   by := p1y - originY;
   bz := p1z - originZ;
   segDx := bx - ax;
   segDy := by - ay;
   segDz := bz - az;
   segLen := Sqrt(segDx * segDx + segDy * segDy + segDz * segDz);
   if segLen < 1E-9 then segLen := 1E-9;
  end;

  segT := EnsureRange(FRun2SegS / segLen, 0.0, 1.0);
  camX := ax + segDx * segT;
  camY := ay + segDy * segT;
  camZ := az + segDz * segT + 2.0;

  yawRad := ArcTan2(segDx, segDy);
  FRenderer.Yaw := RadToDeg(yawRad);
  FRenderer.Pitch := -90;
  FRenderer.Distance := 10;
  FRenderer.PanX := -FRenderer.Distance * Sin(yawRad) - camX;
  FRenderer.PanY := -FRenderer.Distance * Cos(yawRad) - camY;
  FRenderer.PanZ := -camZ;

  FRenderer.UseDyna := False;
  UpdateTimer.Enabled := True;
  OpenGLPanel1.Invalidate;
  Exit;
 end;

 if FRenderer <> nil then
 begin
  tick := GetTickCount64;
  if (tick - FLastInteractTick) <= 250 then
  begin
   FRenderer.UseDyna := True;
   UpdateTimer.Enabled := True;
  end
  else
   FRenderer.UseDyna := False;
 end;
 UpdateCameraLabel;
 SaveSettings;
 OpenGLPanel1.Invalidate;
end;

procedure TLas3DRenderForm.UpDown1Click(Sender: TObject; Button: TUDBtnType);
begin
 FRenderer.PointSize := UpDown1.Position;
 OpenGLPanel1.Invalidate;
 SaveSettings;
end;

//
procedure TLas3DRenderForm.UpdateCameraLabel;
var s: String;
begin
 if FRenderer = nil then Exit;
 if FRenderer.Mode = rm3D then
  s := Format('Yaw: %.1f°  Pitch: %.1f°  FOV: %.1f°  Dist: %.6g  Pan: %.6g %.6g %.6g',
   [FRenderer.Yaw, FRenderer.Pitch, FRenderer.FovDeg, FRenderer.Distance,
    FRenderer.PanX, FRenderer.PanY, FRenderer.PanZ])
 else
  s := Format('2D  Scale: %.3f', [FRenderer.OrthoScale]);
 Caption := s;
end;
//
procedure TLas3DRenderForm.SaveSettings;
var
 ini: TIniFile;
begin
 exit;
 if (FRenderer = nil) then Exit;
 FRenderer.PointSize := UpDown1.Position;
 FRenderer.SaveState;

 if (FRenderer.StateFileName = '') or (not Assigned(Tiles)) then Exit;
 try
  ini := TIniFile.Create(FRenderer.StateFileName);
  try
   ini.WriteInteger('Render', 'ColorMode', Ord(Tiles.ColorMode));
  finally
   ini.Free;
  end;
 except
 end;
end;
//
procedure TLas3DRenderForm.LoadSettings;
var
 ini: TIniFile;
 cm: Integer;
begin
 if (FRenderer = nil) then Exit;
 FRenderer.LoadState;

 if (FRenderer.StateFileName <> '') and FileExists(FRenderer.StateFileName) and Assigned(Tiles) then
 begin
  try
   ini := TIniFile.Create(FRenderer.StateFileName);
   try
    cm := ini.ReadInteger('Render', 'ColorMode', Ord(Tiles.ColorMode));
    if (cm >= Ord(Low(TLasPointColorMode))) and (cm <= Ord(High(TLasPointColorMode))) then
     Tiles.ColorMode := TLasPointColorMode(cm);
   finally
    ini.Free;
   end;
  except
  end;
 end;

 FUpdatingUI := True;
 try
  UpDown1.Position := Round(FRenderer.PointSize);
  if BlendCheck <> nil then
   BlendCheck.Checked := FRenderer.BlendEnabled;
  if AlphaBar <> nil then
   AlphaBar.Position := Round(EnsureRange(FRenderer.Alpha, 0.0, 1.0) * 255.0);
  if TilesCheck <> nil then
   TilesCheck.Checked := FRenderer.ShowTileBBoxes;
  if PlaneCheck <> nil then
   PlaneCheck.Checked := FRenderer.PlaneEnabled;
  if DeltaZEdit <> nil then
   DeltaZEdit.Value := FRenderer.PlaneDeltaZ;
  if kZoom <> nil then
   kZoom.Checked := FRenderer.ZoomToPlaneEnabled;
  if ZoomKEdit <> nil then
   ZoomKEdit.Value := FRenderer.ZoomToPlaneK;
  SyncColorModeComboFromTiles;
 finally
  FUpdatingUI := False;
 end;
 UIChanged(nil);
 UpdateCameraLabel;
end;

procedure TLas3DRenderForm.PopulateColorModeCombo;
begin
 if ColorModeCombo = nil then Exit;
 if ColorModeCombo.Items.Count > 0 then Exit;
 ColorModeCombo.Items.Add('RGB');
 ColorModeCombo.Items.Add('Intensity');
 ColorModeCombo.Items.Add('Return');
 ColorModeCombo.Items.Add('Classification');
 ColorModeCombo.Items.Add('ScanAngle');
end;

procedure TLas3DRenderForm.SyncColorModeComboFromTiles;
begin
 if (ColorModeCombo = nil) or (Tiles = nil) then Exit;
 PopulateColorModeCombo;
 ColorModeCombo.ItemIndex := Ord(Tiles.ColorMode);
end;

procedure TLas3DRenderForm.sbRun1Click(Sender: TObject);
var
 minX, minY, minZ, maxX, maxY, maxZ: Double;
 originX, originY, originZ: Double;
 px0, py0, pz0: Double;
 px1, py1, pz1: Double;
 localX, localY, localZ: Double;
 segDx, segDy: Double;
 segLen: Double;
 yawRad: Double;
 distance: Double;
 camZ: Double;
begin
 if (sbRun1 = nil) or (not sbRun1.Down) then Exit;
 if (FScene = nil) or (FRenderer = nil) then Exit;
 if not FScene.GetCombinedBBoxVisible(minX, minY, minZ, maxX, maxY, maxZ) then Exit;
 if not FScene.GetPoslPoint(0, px0, py0, pz0) then Exit;

 originX := (minX + maxX) * 0.5;
 originY := (minY + maxY) * 0.5;
 originZ := (minZ + maxZ) * 0.5;

 localX := px0 - originX;
 localY := py0 - originY;
 localZ := pz0 - originZ;

 FRenderer.Mode := rm3D;
 FRenderer.AutoDistance := False;
 FRenderer.Pitch := -90;

 yawRad := 0;
 if FScene.GetPoslPoint(1, px1, py1, pz1) then
 begin
  segDx := (px1 - originX) - localX;
  segDy := (py1 - originY) - localY;
  segLen := Hypot(segDx, segDy);
  if segLen > 1E-12 then
   yawRad := ArcTan2(segDx, segDy);
 end;
 FRenderer.Yaw := RadToDeg(yawRad);

 distance := 10;
 FRenderer.Distance := distance;

 camZ := localZ + 2.0;
 FRenderer.PanX := -distance * Sin(yawRad) - localX;
 FRenderer.PanY := -distance * Cos(yawRad) - localY;
 FRenderer.PanZ := -camZ;

 FMouseDragging := False;
 UpdateCameraLabel;
 OpenGLPanel1.Invalidate;
end;

end.

