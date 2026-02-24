unit uMap2DRenderForm;

{$mode objfpc}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, OpenGLPanel,
 StdCtrls,
 Types, LCLIntf,
 ComCtrls,
 Menus, ValEdit,
 fgl,
 ogcBasic, ogcDrawerOGL, ogcMapObject, uGLSceneIndexer, ogcProperties,
 ogcGeometry,
 ogcInspector;

type

 TSelectedIdMap = specialize TFPGMap <TGLObjectId, Byte>;
 TIdToGeomMap = specialize TFPGMap <TGLObjectId, TogsGeometry>;
 TIdToOrderMap = specialize TFPGMap <TGLObjectId, Integer>;

 { TMap2DRenderForm }

 TMap2DRenderForm = class(TForm)
  CBTiles: TCheckBox;
  ImgList: TImageList;
  MainMenu1: TMainMenu;
  MenuFile: TMenuItem;
  MenuFileOpen: TMenuItem;
  OpenGLPanel1: TOpenGLPanel;
  ODGmf: TOpenDialog;
  PanelTop: TPanel;
  PBScene: TProgressBar;
  StatusBar1: TStatusBar;
  VLE: TValueListEditor;
  procedure CBTilesClick(Sender: TObject);
  procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  procedure FormCreate(Sender: TObject);
  procedure FormDestroy(Sender: TObject);
  procedure MenuFileOpenClick(Sender: TObject);
  procedure OpenGLPanel1Paint(Sender: TObject);
  procedure OpenGLPanel1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure OpenGLPanel1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  procedure OpenGLPanel1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure OpenGLPanel1MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
 private
  FDrawer: TDrawerOGL;
  FMapObject: TogsMapObject;
  FGLInited: Boolean;
  FPainting: Boolean;
  FSceneDirty: Boolean;
  FTessPrepared: Boolean;
  FClosing: Boolean;
  FMouseDragging: Boolean;
  FLastMousePos: TPoint;
  FFpsFrameCount: Integer;
  FFpsLastTick: QWord;
  FBaseCaption: String;
  FInspector: TPropInspector;
  FSelectedIDs: TSelectedIdMap;
  FIdToGeom: TIdToGeomMap;
  FIdToOrder: TIdToOrderMap;
  FLastPickedId: TGLObjectId;
  procedure BuildScene;
  procedure Render;
  procedure RenderSelectionOverlay;
  procedure ClearSelection;
  procedure ToggleSelection(AId: TGLObjectId);
  procedure AddSelection(AId: TGLObjectId);
  procedure SelectSingle(AId: TGLObjectId);
  function IsSelected(AId: TGLObjectId): Boolean;
  function PickObjectIdAt(XPix, YPix: Integer; out PickedId: TGLObjectId): Boolean;
  procedure UpdateInspectorForSelection;
 public
 end;

var
 Map2DRenderForm: TMap2DRenderForm;

implementation uses GMFGeometry, dglOpenGL, ogcWriter, Math;

{$R *.frm}

procedure TMap2DRenderForm.FormCreate(Sender: TObject);
begin
 FDrawer := TDrawerOGL.Create(nil, OpenGLPanel1, @OpenGLPanel1Paint);
 FMapObject := TogsMapObject.Create(FDrawer);
 FDrawer.ogsSelector := FMapObject.ogsSelector;
 if (FMapObject.Indexer <> nil) then FMapObject.Indexer.TestSplit4 := True;
 if CBTiles <> nil then CBTiles.Checked := FDrawer.ShowTiles;
 FGLInited := False;
 FPainting := False;
 FSceneDirty := True;
 FTessPrepared := False;
 FClosing := False;
 FMouseDragging := False;
 FLastMousePos := Point(0, 0);
 FSelectedIDs := TSelectedIdMap.Create;
 FSelectedIDs.Sorted := True;
 FIdToGeom := TIdToGeomMap.Create;
 FIdToGeom.Sorted := True;
 FIdToOrder := TIdToOrderMap.Create;
 FIdToOrder.Sorted := True;
 FLastPickedId := 0;
 FBaseCaption := Caption;
 FFpsFrameCount := 0;
 FFpsLastTick := GetTickCount64;
 if not InitOpenGL then raise Exception.Create('noInitGL');
 OpenGLPanel1.Color := clBtnFace;
//
 FInspector := TPropInspector.Create(VLE, nil, ImgList);
 OnClose := @FormClose;
end;

procedure TMap2DRenderForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 FClosing := True;
 if FDrawer <> nil then FDrawer.Disable := True;
 FSceneDirty := False;
 if OpenGLPanel1 <> nil then
 begin
  OpenGLPanel1.OnPaint := nil;
  OpenGLPanel1.OnMouseDown := nil;
  OpenGLPanel1.OnMouseMove := nil;
  OpenGLPanel1.OnMouseUp := nil;
  OpenGLPanel1.OnMouseWheel := nil;
 end;
end;

procedure TMap2DRenderForm.CBTilesClick(Sender: TObject);
begin
 if (FDrawer <> nil) and (CBTiles <> nil) then FDrawer.ShowTiles := CBTiles.Checked;
 if OpenGLPanel1 <> nil then OpenGLPanel1.Invalidate;
end;

procedure TMap2DRenderForm.FormDestroy(Sender: TObject);
begin
 WriteIn([1]);
 if (FDrawer <> nil) and (OpenGLPanel1 <> nil) then
  try
   if (not (csDestroying in OpenGLPanel1.ComponentState)) and OpenGLPanel1.HandleAllocated and OpenGLPanel1.MakeCurrent then
    FDrawer.ReleaseGL;
  except
  end;
  WriteIn([2]);
 FreeAndNil(FSelectedIDs);
 FreeAndNil(FIdToGeom);
 FreeAndNil(FIdToOrder);
 FreeAndNil(FMapObject);
 FreeAndNil(FDrawer);
   WriteIn([3]);
end;

procedure TMap2DRenderForm.MenuFileOpenClick(Sender: TObject);
var oldStatus: String;
begin
 if ODGmf = nil then Exit;
 if not ODGmf.Execute then Exit;
 if (FMapObject = nil) then Exit;
 oldStatus := '';
 if StatusBar1 <> nil then
 begin
  oldStatus := StatusBar1.SimpleText;
  StatusBar1.SimpleText := 'Загрузка графики...';
  StatusBar1.Repaint;
 end;
 try
  FMapObject.Clear;
  FMapObject.OpenFile(ODGmf.FileName);
  FSceneDirty := True;
  FTessPrepared := False;
  OpenGLPanel1.Invalidate;
//
 finally
  FInspector.Clear;
  FDrawer.ClearDebugLabels;
  ClearSelection;
  if StatusBar1 <> nil then
  begin
   StatusBar1.SimpleText := oldStatus;
   StatusBar1.Repaint;
  end;
 end;
end;

procedure TMap2DRenderForm.ClearSelection;
begin
 if FSelectedIDs <> nil then FSelectedIDs.Clear;
 FLastPickedId := 0;
 UpdateInspectorForSelection;
end;

function TMap2DRenderForm.IsSelected(AId: TGLObjectId): Boolean;
begin
 if (FSelectedIDs = nil) then Exit(False);
 Result := FSelectedIDs.IndexOf(AId) >= 0;
end;

procedure TMap2DRenderForm.AddSelection(AId: TGLObjectId);
begin
 if (AId = 0) then Exit;
 if (FSelectedIDs = nil) then Exit;
 if FSelectedIDs.IndexOf(AId) >= 0 then Exit;
 FSelectedIDs.Add(AId, 1);
 FLastPickedId := AId;
 UpdateInspectorForSelection;
end;

procedure TMap2DRenderForm.ToggleSelection(AId: TGLObjectId);
var idx: Integer;
begin
 if (AId = 0) then Exit;
 if (FSelectedIDs = nil) then Exit;
 idx := FSelectedIDs.IndexOf(AId);
 if idx >= 0 then
 begin
  FSelectedIDs.Delete(idx);
  if FLastPickedId = AId then FLastPickedId := 0;
 end else
 begin
  FSelectedIDs.Add(AId, 1);
  FLastPickedId := AId;
 end;
 UpdateInspectorForSelection;
end;

procedure TMap2DRenderForm.SelectSingle(AId: TGLObjectId);
begin
 if (FSelectedIDs <> nil) then FSelectedIDs.Clear;
 if AId <> 0 then
 begin
  if (FSelectedIDs <> nil) then FSelectedIDs.Add(AId, 1);
  FLastPickedId := AId;
 end else
  FLastPickedId := 0;
 UpdateInspectorForSelection;
end;

procedure TMap2DRenderForm.UpdateInspectorForSelection;
var geom: TogsGeometry;
begin
 if FInspector = nil then Exit;
 if (FIdToGeom = nil) then Exit;
 if (FLastPickedId = 0) then
 begin
  FInspector.Clear;
  Exit;
 end;
 if FIdToGeom.IndexOf(FLastPickedId) < 0 then
 begin
  FInspector.Clear;
  Exit;
 end;
 geom := FIdToGeom.Data[FIdToGeom.IndexOf(FLastPickedId)];
 if (geom = nil) or (geom.ogsProperties = nil) then
 begin
  FInspector.Clear;
  Exit;
 end;
 FInspector.ogsProperties := geom.ogsProperties;
end;

function TMap2DRenderForm.PickObjectIdAt(XPix, YPix: Integer; out PickedId: TGLObjectId): Boolean;
var
 gx, gy: Double;
 idx: TGLSceneIndexer;
 candidates: TGLObjectIdArray;
 i, bestOrder, ordIdx: Integer;
 id: TGLObjectId;
 geom: TogsGeometry;
 cap: TCaptureRec;
 viewRect: TogsRect;
 x0, y0, x1, y1: Double;
 vx0, vy0, vx1, vy1: Double;
begin
 Result := False;
 PickedId := 0;
 if (FMapObject = nil) or (FMapObject.ogsSelector = nil) then Exit;
 idx := FMapObject.Indexer;
 if (idx = nil) then Exit;
 viewRect := FMapObject.ogsSelector.ActiveRect;
 gx := FMapObject.ogsSelector.XGeo(XPix);
 gy := FMapObject.ogsSelector.YGeo(YPix);
 idx.QueryObjectsAtPoint(gx, gy, candidates);
 if Length(candidates) = 0 then Exit;
 bestOrder := -MaxInt;
 for i := 0 to Length(candidates) - 1 do
 begin
  id := candidates[i];
  if (FIdToGeom = nil) or (FIdToGeom.IndexOf(id) < 0) then Continue;
  geom := FIdToGeom.Data[FIdToGeom.IndexOf(id)];
  if geom = nil then Continue;
  if (viewRect <> nil) and (geom.ogsRect <> nil) then
  begin
   x0 := Min(geom.ogsRect.XMin, geom.ogsRect.XMax);
   x1 := Max(geom.ogsRect.XMin, geom.ogsRect.XMax);
   y0 := Min(geom.ogsRect.YMin, geom.ogsRect.YMax);
   y1 := Max(geom.ogsRect.YMin, geom.ogsRect.YMax);
   vx0 := Min(viewRect.XMin, viewRect.XMax);
   vx1 := Max(viewRect.XMin, viewRect.XMax);
   vy0 := Min(viewRect.YMin, viewRect.YMax);
   vy1 := Max(viewRect.YMin, viewRect.YMax);
   if (x1 < vx0) or (x0 > vx1) or (y1 < vy0) or (y0 > vy1) then Continue;
  end;
  cap := CRClearParams;
  if not geom.SelectByPoint(gx, gy, cap) then Continue;
  ordIdx := -1;
  if (FIdToOrder <> nil) then ordIdx := FIdToOrder.IndexOf(id);
  if ordIdx >= 0 then
  begin
   if FIdToOrder.Data[ordIdx] >= bestOrder then
   begin
    bestOrder := FIdToOrder.Data[ordIdx];
    PickedId := id;
    Result := True;
   end;
  end else
  begin
   if bestOrder < 0 then
   begin
    bestOrder := 0;
    PickedId := id;
    Result := True;
   end;
  end;
 end;
end;

procedure TMap2DRenderForm.BuildScene;
var i: Integer;
    id: TGLObjectId;
    geom: TogsGeometry;
    idx: TGLSceneIndexer;
    tiles: TGLTileIdArray;
    j, tx, ty: Integer;
    jsonStr: AnsiString;
    fs: TFormatSettings;
    xm, ym: Double;
    gRect: TogsRect;
    gx0, gy0, gx1, gy1: Double;
    tXMin, tYMin, tXMax, tYMax: array[0..1] of Double;
    ix, iy: Integer;
    first: Boolean;
    DoJson: Boolean;
    total: Integer;
    lastUiTick: QWord;
    nowUiTick: QWord;
    oldStatus: String;
    statusText: String;
begin
 if FDrawer = nil then Exit;
 if FMapObject = nil then Exit;
 if (not FTessPrepared) and (FMapObject.Geometry <> nil) then
 begin
  for i := 0 to FMapObject.PLib.Count - 1 do
   FMapObject.PLibItem[i].Calculate([calcTess]);
  for i := 0 to FMapObject.Geometry.Count - 1 do
  begin
   geom := FMapObject.Geometry.Item[i];
   if geom = nil then Continue;
   if (geom is TogsPolygon) or (geom is TogsMultiPolygon) then
    geom.Calculate([calcTess]);
  end;
  FTessPrepared := True;
 end;
 DoJson := False;
 fs := DefaultFormatSettings;
 fs.DecimalSeparator := '.';
 idx := FMapObject.Indexer;
 if (idx <> nil) and (FMapObject.ogsSelector <> nil) and (FMapObject.ogsSelector.GlobalRect <> nil) then
 begin
  gRect := FMapObject.ogsSelector.GlobalRect;
  xm := gRect.XMax - gRect.XMin;
  ym := gRect.YMax - gRect.YMin;
  if (xm > 0) or (ym > 0) then
  begin
   idx.TestSplit4 := False;
   idx.TileSize := 500.0;
  end;
 end;
 if idx <> nil then idx.Clear;
 if FIdToGeom <> nil then FIdToGeom.Clear;
 if FIdToOrder <> nil then FIdToOrder.Clear;
 FDrawer.Indexer := idx;
 FDrawer.BeginScene;
 oldStatus := '';
 if StatusBar1 <> nil then oldStatus := StatusBar1.SimpleText;
 total := 0;
 if (FMapObject.Geometry <> nil) then total := FMapObject.Geometry.Count;
 if PBScene <> nil then
 begin
  PBScene.Min := 0;
  PBScene.Max := total;
  PBScene.Position := 0;
  PBScene.Visible := True;
 end;
 lastUiTick := GetTickCount64;
 if (FMapObject.Geometry <> nil) then
  for i := 0 to FMapObject.Geometry.Count - 1 do
  begin
   geom := FMapObject.Geometry.Item[i];
  // WriteIn([i, geom.ClassName]);
   if geom <> nil then
   begin
    geom.RenderOrder := i;
    id := geom.ogsID;
    if id = 0 then
    begin
     id := i + 1;
     geom.ogsID := id;
    end;
   end else
    id := 0;

   if (StatusBar1 <> nil) then
   begin
    nowUiTick := GetTickCount64;
    if (nowUiTick - lastUiTick) >= 100 then
    begin
     if total > 0 then statusText := Format('BuildScene %d/%d (%.1f%%)', [i + 1, total, (i + 1) * 100.0 / total])
     else statusText := Format('BuildScene %d', [i + 1]);
     StatusBar1.SimpleText := statusText;
     StatusBar1.Repaint;
     if (PBScene <> nil) and (PBScene.Visible) then PBScene.Position := i + 1;
     lastUiTick := nowUiTick;
    end;
   end;

   if geom.ogsRect <> nil then
   begin
    if idx.TestSplit4 then
    begin
     gRect := nil;
     if (FMapObject <> nil) and (FMapObject.ogsSelector <> nil) then gRect := FMapObject.ogsSelector.GlobalRect;
     if gRect <> nil then
     begin
      gx0 := gRect.XMin;
      gy0 := gRect.YMin;
      gx1 := gRect.XMax;
      gy1 := gRect.YMax;
     end else
     begin
      gx0 := geom.ogsRect.XMin;
      gy0 := geom.ogsRect.YMin;
      gx1 := geom.ogsRect.XMax;
      gy1 := geom.ogsRect.YMax;
     end;
     xm := (gx0 + gx1) * 0.5;
     ym := (gy0 + gy1) * 0.5;
     tXMin[0] := gx0; tXMax[0] := xm;
     tXMin[1] := xm;  tXMax[1] := gx1;
     tYMin[0] := gy0; tYMax[0] := ym;
     tYMin[1] := ym;  tYMax[1] := gy1;
     if DoJson then
     begin
      jsonStr := '{"id":'+IntToStr(id)+',"bbox":['+
       FloatToStr(geom.ogsRect.XMin, fs)+','+FloatToStr(geom.ogsRect.YMin, fs)+','+FloatToStr(geom.ogsRect.XMax, fs)+','+FloatToStr(geom.ogsRect.YMax, fs)+'],"globalRect":['+
       FloatToStr(gx0, fs)+','+FloatToStr(gy0, fs)+','+FloatToStr(gx1, fs)+','+FloatToStr(gy1, fs)+'],"tiles":[';
      first := True;
      for iy := 0 to 1 do
       for ix := 0 to 1 do
        if not ((geom.ogsRect.XMax <= tXMin[ix]) or (geom.ogsRect.XMin >= tXMax[ix]) or
                (geom.ogsRect.YMax <= tYMin[iy]) or (geom.ogsRect.YMin >= tYMax[iy])) then
        begin
         if not first then jsonStr := jsonStr + ',' else first := False;
         jsonStr := jsonStr + '{"ij":['+IntToStr(ix)+','+IntToStr(iy)+'],"rect":['+
          FloatToStr(tXMin[ix], fs)+','+FloatToStr(tYMin[iy], fs)+','+FloatToStr(tXMax[ix], fs)+','+FloatToStr(tYMax[iy], fs)+']}';
        end;
      jsonStr := jsonStr + ']}' ;
      if geom.ogsProperties = nil then geom.ogsProperties := TogsPropObject.CreateFrom('{}');
      TogsPropValue(geom.ogsProperties).FromString(jsonStr);
     end;
    end else
    if idx.TryGetObjectTiles(id, tiles) then
    begin
     if DoJson then
     begin
      jsonStr := '{"id":'+IntToStr(id)+',"bbox":['+
       FloatToStr(geom.ogsRect.XMin, fs)+','+FloatToStr(geom.ogsRect.YMin, fs)+','+FloatToStr(geom.ogsRect.XMax, fs)+','+FloatToStr(geom.ogsRect.YMax, fs)+'],"tiles":[';
      for j := 0 to Length(tiles) - 1 do
      begin
       tx := LongInt(tiles[j] shr 32);
       ty := LongInt(tiles[j] and $FFFFFFFF);
       jsonStr := jsonStr + '['+IntToStr(tx)+','+IntToStr(ty)+']';
       if j < Length(tiles) - 1 then jsonStr := jsonStr + ',';
      end;
      jsonStr := jsonStr + ']}' ;
      if geom.ogsProperties = nil then geom.ogsProperties := TogsPropObject.CreateFrom('{}');
      TogsPropValue(geom.ogsProperties).FromString(jsonStr);
     end;
    end;
   end;

   if (idx <> nil) and (geom <> nil) then
  begin
   geom.Calculate([calcbBox]);
   idx.AddObject(id, geom.ogsRect);
   if (FIdToGeom <> nil) and (FIdToGeom.IndexOf(id) < 0) then FIdToGeom.Add(id, geom);
   if (FIdToOrder <> nil) and (FIdToOrder.IndexOf(id) < 0) then FIdToOrder.Add(id, i);
  end;

   if geom <> nil then
   begin
    FDrawer.BeginObject(id);
    geom.Draw(FDrawer);
    FDrawer.EndObject;
   end;
  end;
 FDrawer.EndScene;
 FSceneDirty := False;
 if StatusBar1 <> nil then
 begin
  StatusBar1.SimpleText := oldStatus;
  StatusBar1.Repaint;
 end;
 if PBScene <> nil then PBScene.Visible := False;
end;

procedure TMap2DRenderForm.Render;
begin
 if FDrawer = nil then Exit;
 FDrawer.Clear(clWhite);
 FDrawer.RenderScene;
end;

procedure TMap2DRenderForm.RenderSelectionOverlay;
var
 i: Integer;
 id: TGLObjectId;
 geom: TogsGeometry;
 oldForce: Boolean;
 oldColor: TColor;
 oldPen: TogsPen;
 oldOverlayThick: Boolean;
 oldOverlayWidth: Integer;
procedure DrawSelected;
var i: Integer;
begin
  for i := 0 to FSelectedIDs.Count - 1 do begin
   id := FSelectedIDs.Keys[i];
   if FIdToGeom.IndexOf(id) < 0 then Continue;
   geom := FIdToGeom.Data[FIdToGeom.IndexOf(id)];
   if geom = nil then Continue;
   FDrawer.BeginObject(id);
   geom.Draw(FDrawer);
   FDrawer.EndObject;
  end;
end;
begin
 if (FDrawer = nil) then Exit;
 if (FSelectedIDs = nil) or (FSelectedIDs.Count = 0) then Exit;
 if (FIdToGeom = nil) then Exit;
 oldForce := FDrawer.ForceColor;
 oldColor := FDrawer.ForcedColor;
 oldOverlayThick := FDrawer.OverlayThick;
 oldOverlayWidth := FDrawer.OverlayWidthPx;
 FDrawer.ForceColor := True;
 FDrawer.OverlayThick := True;
 oldPen := FDrawer.SelectPen(TogsPen.Create(clRed, 0, nil));
 try
  FDrawer.ForcedColor := clYellow;
  FDrawer.OverlayWidthPx := 7;
  DrawSelected;
  FDrawer.FlushOverlay;
 //
  FDrawer.ForcedColor := clRed;
  FDrawer.OverlayWidthPx := 3;
  DrawSelected;
  FDrawer.FlushOverlay;
 finally
  FDrawer.DeletePen(FDrawer.SelectPen(oldPen));
  FDrawer.ForceColor := oldForce;
  FDrawer.ForcedColor := oldColor;
  FDrawer.OverlayThick := oldOverlayThick;
  FDrawer.OverlayWidthPx := oldOverlayWidth;
 end;
end;

procedure TMap2DRenderForm.OpenGLPanel1Paint(Sender: TObject);
var
 nowTick: QWord;
 dt: QWord;
 fps: Double;
begin
 if FClosing then Exit;
 if (csDestroying in ComponentState) then Exit;
 if FPainting then Exit;
 FPainting := True;
 try
  if not OpenGLPanel1.MakeCurrent then Exit;
  if not FGLInited then
  begin
   ReadExtensions;
   ReadImplementationProperties;
   if Assigned(wglSwapIntervalEXT) then wglSwapIntervalEXT(0);
   FGLInited := True;
  end;
  if FDrawer <> nil then FDrawer.BeginPaint;
  if FSceneDirty then BuildScene;
  Render;
  RenderSelectionOverlay;
  if FDrawer <> nil then FDrawer.EndPaint;
  if (FDrawer <> nil) then FDrawer.RenderDebugLabels;

  Inc(FFpsFrameCount);
  nowTick := GetTickCount64;
  dt := nowTick - FFpsLastTick;
  if dt >= 1000 then
  begin
   fps := FFpsFrameCount * 1000.0 / dt;
   Caption := FBaseCaption + Format('  FPS: %.1f', [fps]);
   FFpsFrameCount := 0;
   FFpsLastTick := nowTick;
  end;
 finally
  FPainting := False;
 end;
end;

procedure TMap2DRenderForm.OpenGLPanel1MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var p: TPoint;
begin
 if (FDrawer = nil) then Exit;
 p := MousePos;
 FDrawer.MouseWheel(Sender, Shift, WheelDelta, p, Handled);
 Handled := True;
end;

procedure TMap2DRenderForm.OpenGLPanel1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var id: TGLObjectId;
begin
 SetCapture(OpenGLPanel1.Handle);
 if Button = mbLeft then
 begin
  if PickObjectIdAt(X, Y, id) then
  begin
   if (ssCtrl in Shift) then ToggleSelection(id) else
    if (ssShift in Shift) then AddSelection(id) else
     SelectSingle(id);
  end else
  begin
   if not ((ssCtrl in Shift) or (ssShift in Shift)) then ClearSelection;
  end;
  if OpenGLPanel1 <> nil then OpenGLPanel1.Invalidate;
  Exit;
 end;
 if (Button = mbMiddle) and (ssDouble in Shift) then
 begin
  ReleaseCapture;
  if (FMapObject <> nil) and (FMapObject.ogsSelector <> nil) then
   FMapObject.ogsSelector.UpdateRects(True);
  if OpenGLPanel1 <> nil then OpenGLPanel1.Invalidate;
  Exit;
 end;
 if Button <> mbMiddle then Exit;
 if OpenGLPanel1 = nil then Exit;
 FMouseDragging := True;
 FLastMousePos := Point(X, Y);
// SetCaptureControl(OpenGLPanel1);
end;

procedure TMap2DRenderForm.OpenGLPanel1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var gx, gy: Double;
begin
 if (StatusBar1 <> nil) and (FMapObject <> nil) and (FMapObject.ogsSelector <> nil) then
 begin
  gx := FMapObject.ogsSelector.XGeo(X);
  gy := FMapObject.ogsSelector.YGeo(Y);
  StatusBar1.SimpleText := Format('X=%.3f  Y=%.3f', [gx, gy]);
 end;
 if not FMouseDragging then Exit;
 if (FMapObject = nil) or (FMapObject.ogsSelector = nil) then Exit;
 with FMapObject.ogsSelector do
 begin
  Move(geoDist(-X + FLastMousePos.X), geoDist(-Y + FLastMousePos.Y));
  FLastMousePos := Point(X, Y);
 end;
 OpenGLPanel1.Invalidate;
end;

procedure TMap2DRenderForm.OpenGLPanel1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if Button <> mbMiddle then Exit;
 FMouseDragging := False;
 ReleaseCapture;
end;

end.
