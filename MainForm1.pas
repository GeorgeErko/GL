{%RunFlags BUILD-}
unit MainForm1;

{$mode Delphi}

interface

uses LCLIntf, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ValEdit,
 Menus, ActnList, StdCtrls, Spin, Interfaces, GR32_Image, SpkToolbar, spkt_Tab,
 spkt_Pane, spkt_Buttons, ogcGMFReader, ogcMathUtils, ogcBasic, ogcDrawer32,
 GMFLTDrawer, ogcMapObject, GR32_Layers, Types, GR32, ogcInspector, IdHTTP,
 gd_dockingbase, DCPblowfish, cyButton, cyResizer, ExButtons, LvlGraphCtrl,
 bgraExButton, bgraExRotImage, BCButton, BGRASpeedButton, BGRATheme,
 BGRAThemeButton, BGRAColorTheme, BGRASVGTheme, BCDefaultThemeManager,
 BCMaterialDesignButton, ogcCallbackRec,
 vswebsocket, ogcInterServer, ogcTileLayer,
 uLas3DViewerForm, OpenGLPanel;

type

 { TMainFrm }

 { TbtnTicker }

 TbtnTicker = class
  btnTick: Byte;
  btnTime: array[0..2] of TDateTime;
  function QueryDblClick(msgText: String): boolean;
 end;

 TMainFrm = class(TForm)
  actnOpenDWG: TAction;
  actnFitView: TAction;
  btnTestTiles: TButton;
  btnTestTiles1: TButton;
  Button1: TButton;
  ButtonMap2D: TButton;
  ButtonMap2D1: TButton;
  FloatSpinEdit1: TFloatSpinEdit;
  GroupBox1: TGroupBox;
  Image32: TImage32;
  ImgList: TImageList;
  Label1: TLabel;
  LabelXY: TLabel;
  actnOpenGMF: TAction;
  ActionList1: TActionList;
  mainPanel: TPanel;
  btmPanel: TPanel;
  MenuItem1: TMenuItem;
  MenuItem2: TMenuItem;
  ODGmf: TOpenDialog;
  ODDwg: TOpenDialog;
  ODLas: TOpenDialog;
  PopupMenu1: TPopupMenu;
  SpkLargeButton1: TSpkLargeButton;
  SpkLargeButton2: TSpkLargeButton;
  SpkLargeButton4: TSpkLargeButton;
  sbAutorise: TSpkLargeButton;
  SpkCreateSession: TSpkLargeButton;
  spConnect: TSpkLargeButton;
  SpkPane3: TSpkPane;
  spkSort: TSpkLargeButton;
  SpkLargeButton3: TSpkLargeButton;
  SpkPane1: TSpkPane;
  btnOpenGMF: TSpkSmallButton;
  SpkPane2: TSpkPane;
  btnFitView: TSpkSmallButton;
  SpkSmallButton1: TSpkSmallButton;
  SpkTab1: TSpkTab;
  SpkTab2: TSpkTab;
  SpkToolbar1: TSpkToolbar;
  Splitter1: TSplitter;
  Splitter2: TSplitter;
  ToggleBox1: TToggleBox;
  VLE: TValueListEditor;
  procedure actnFitViewExecute(Sender: TObject);
  procedure actnOpenDWGExecute(Sender: TObject);
  procedure btnTestTilesClick(Sender: TObject);
  procedure Button1Click(Sender: TObject);
  procedure ButtonMap2D1Click(Sender: TObject);
  procedure ButtonMap2DClick(Sender: TObject);
  procedure FloatSpinEdit1Change(Sender: TObject);
  procedure FormChangeBounds(Sender: TObject);
  procedure GroupBox1Click(Sender: TObject);
  procedure Image32MouseDown(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
  procedure Image32MouseMove(Sender: TObject; Shift: TShiftState; X,
   Y: Integer; Layer: TCustomLayer);
  procedure Image32MouseUp(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
  procedure Image32MouseWheel(Sender: TObject; Shift: TShiftState;
   WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  procedure Image32Resize(Sender: TObject);
  procedure MenuItem1Click(Sender: TObject);
  procedure actnOpenGMFExecute(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure FormDestroy(Sender: TObject);
  procedure MenuItem2Click(Sender: TObject);
  procedure ODGmfShow(Sender: TObject);
  procedure SpkLargeButton2Click(Sender: TObject);
  procedure SpkLargeButton3Click(Sender: TObject);
  procedure SpkLargeButton4Click(Sender: TObject);
  procedure sbAutoriseClick(Sender: TObject);
  procedure SpkCreateSessionClick(Sender: TObject);
  procedure spkSortClick(Sender: TObject);
  procedure SpkSmallButton1Click(Sender: TObject);
  procedure spConnectClick(Sender: TObject);
  procedure ToggleBox1Change(Sender: TObject);
  procedure VLEClick(Sender: TObject);
 private
  oldMPos: TPoint;
  mwDowned: Boolean;
  btnTicker: TbtnTicker;
  procedure OnPaint(Sender: TObject);
  procedure CaptureGeometry(X, Y: Double);
 // Сокеты
//  procedure ConnectionSocketL(Sender: TObject; Reason: THookSocketReason; const Value: String);
 public
  Drawer: TogsDrawer;
  ogsObject: TogsMapObject;
  CaptureRec: TCaptureRec;
  Inspector: TPropInspector;
  TileLayer: TogsTileLayer;
 end;

var
 MainFrm: TMainFrm;

implementation uses DebuggerForm, ogcWriter, GMFGeometry, ogcIEObjects,
                    ogcGeometry, ogcGeometry3, ogcCallbackTypes, TTFGeometry,
                    feFontEngineObjects, ogcProcs, ogcPlayer,
                    ogcGeometry2,
                    ogcProperties,
                    IdMultipartFormData, IdGlobal,
                    StrUtils, synachar, synautil, Math, TypInfo,
                    ogcRects, ogcBitmap, ogcLas, GR32_Polygons,
                    uBitHash,
                    uLasViewRenderer, uLas3DRenderform, uMap2D2RenderForm,
                    uMainVector;

{$R *.frm}

{ TbtnTicker }

function TbtnTicker.QueryDblClick(msgText: string): boolean;
begin
 Result := False;
 If btnTick = 0 then If msgText = 'up' then exit;
 Inc(btnTick);
 If btnTick > 2 then begin
  btnTime[btnTick - 1] := GetTickCount;
  Result := (btnTime[2] - btnTime[0]) <= 300;
  btnTick := 0;
  If not Result then begin
    btnTime[btnTick] := GetTickCount;
    Inc(btnTick);
  end;
 end else
  btnTime[btnTick - 1] := GetTickCount;
end;

{ TMainFrm }
var Las: TogsLas;

procedure TMainFrm.FormCreate(Sender: TObject);
var I, J: Integer; Rect: TogsRectLineString;
    Bmp: TogsBitmap;
    W, H : Double;
    Props: TogsPropObject;
begin
 outMode := omConsole;
//
 LoadBitHashCollectFromRegFile;
//
 Drawer := TogsDrawer32.Create(nil, Image32, Self.OnPaint);
 ogsObject := TogsMapObject.Create(Drawer);
 btnTicker := TbtnTicker.Create;
 Inspector := TPropInspector.Create(VLE, nil, ImgList);

 ogsObject.Clear;

// ODGmf.FileName := 'C:\!!!ГЗ\ДПиООС\fill.gmf';
//  ODGmf.FileName := 'C:\!!!ГЗ\ДПиООС\отлет3.gmf';
 // ODGmf.FileName := 'C:\!!!ГЗ\2025\Борт\tstBlock.gmf';
// ODGmf.FileName := 'C:\!!!ГЗ\ДПиООС\21465_Tulskaya M. ul. 8_blocks_pack.gmf';
//
// ogsObject.OpenFile(ODGmf.FileName);

// ogsObject.ogsSelector.UpdateRects(True);
{
Rect := TogsRectLineString.Create(ogsObject.ogsSelector);
Rect.SetRectLocal(400, 200, 200, 300);
Rect.RotatePoints(45 * Pi/180, 0);
Rect.Calculate([calcbBox]);
ogsObject.AddPrim(Rect);
}
//
{
 W := 0; H := 0;
 For I := 0 to 3 do begin
  For J := 0 to 3 do begin
   Bmp := TogsBitmap.Create(ogsObject.ogsSelector);
   Bmp.OpenRasterFile('C:\!GEOMASTER2\PAVEL\tst\' + 'Testmap.bmp', I * W, J * H);
   W := Bmp.Width;
   H := Bmp.Height;
   WriteIn(['WH+',W, H]);
   Bmp.SetImageParams(0,0,0,0,0,24 * Pi/180);
  // Bmp.Width := Bmp.Width / 1.5;
  // Bmp.Height := Bmp.Width / 1.2;
   Bmp.Calculate([calcbBox]);
   ogsObject.AddPrim(Bmp);
  end;
 end;
 WriteIn(['BMP=',Bmp.ogsRect]);
}
//
{
 Las := TogsLas.Create(ogsObject.ogsSelector);
 Las.Scale := 1;
 Las.ZBase := 0;
 Las.ZStep := 0;
 Las.ZLayerIndex := 0;
 Las.FlipY := True;
 Las.Mode := lrmRGB;
 Las.MaxPoints := 0;
 If ODLas.Execute then begin
  Las.OpenLasFile(ODLas.FileName, 0, 0);
  Las.Calculate([calcbBox]);
  WriteIn(['LAS.Rect',Las.ogsRect]);
  ogsObject.AddPrim(Las);
 //
  ogsObject.ogsSelector.UpdateRects(True);
  ogsObject.ogsSelector.ActiveRect.Inflate(25, 25);
 end;
}
//
exit;
 With TStringList.Create do begin
  LoadFromFile('C:\!theGrapher\GlobalMonitor\default.json');
  Props := TogsPropObject.CreateFrom(Text);
  Free;
  Inspector.ogsProperties := Props;
  FloatSpinEdit1.Value := 40;
  FloatSpinEdit1Change(nil);
 end;
end;

procedure TMainFrm.ButtonMap2DClick(Sender: TObject);
var Form2D: TMap2D2RenderForm;
begin
 Form2D := TMap2D2RenderForm.Create(Self);
 try
  Form2D.ShowModal;
 finally
  Form2D.Free;
 end;
end;

procedure TMainFrm.ButtonMap2D1Click(Sender: TObject);
var MainVector: TMainVector;
begin
 MainVector := TMainVector.Create(Self);
 try
  MainVector.ShowModal;
 finally
  MainVector.Free;
 end;
end;

procedure TMainFrm.FloatSpinEdit1Change(Sender: TObject);
var ZCut: Double;
begin
 Las.AutoZLayers(100);
 Las.ZFilterMode := zfmMinToLayer;
 Las.ZBase := Las.Source.Header.MinZ;
 Las.ZLayerIndex := Round(FloatSpinEdit1.Value);
 If Las.ZLayerIndex = 0 then Las.ZStep := 0 else Las.ZStep := 1;
 Las.Renderer.Mode := lrmDensity;
 Las.BlendEnabled := True;
 Las.BlendAlpha := 16;  // 16..64 обычно ок; больше = быстрее “забивается”
 OnPaint(nil);
end;

procedure TMainFrm.FormDestroy(Sender: TObject);
begin
 Drawer.Free;
 Inspector.Free;
 ogsObject.Free;
 btnTicker.Free;
end;

procedure TMainFrm.Button1Click(Sender: TObject);
var Form3D: TLas3DViewerForm;
begin
 Las3DRenderForm := TLas3DRenderForm.Create(Self);
 Las3DRenderForm.ShowModal;
 Las3DRenderForm.Free;
 exit;
//
 Form3D := TLas3DViewerForm.Create(Self);
 try
//  Form3D.SetLas(Las);
  Form3D.ShowModal;
 finally
  Form3D.Free;
 end;
end;

type
 TCallbackFunc = function (Param: Integer): hObj; stdcall;
 TCallnCheck = function (fAddr: TCallbackFunc): hObj; stdcall;


function CallbackFunc(Param: integer): hObj; stdcall;
begin
 WriteIn([100000000000]);
end;

procedure TMainFrm.MenuItem2Click(Sender: TObject);
var hLib: THandle;
    openFunc: TCallnCheck;
    IEObject: TIEObject;
begin
 try
 { загрузка DLL }
 WriteIn(['Load']);
  hLib := SafeLoadLibrary(ExtractFilePath(ParamStr(0))+ 'test.dll');
  WriteIn(['hLib=', hlib]);
  If hLib <> 0 then begin
   openFunc := GetProcAddress(hLib, 'CallnCheck');
   If Assigned(openFunc) then
    openFunc(CallbackFunc);
   FreeLibrary(hLib);
  end;
 finally
 end;
end;

procedure TMainFrm.ODGmfShow(Sender: TObject);
begin

end;

procedure TMainFrm.OnPaint(Sender: TObject);
var I, J, K: Integer;
    timeStart: TDateTime;
    Dist: Double;
begin
// WriteIn(['beginPaint.scale',ogsObject.ogsSelector.fScale,ogsObject.ogsSelector.ActiveRect]);
 timeStart := GetTickCount;
 Drawer.BeginPaint;
 Drawer.Clear(clWhite);
 ogsObject.ogsSelector.UpdateRects(False);
 Dist := ogsObject.ogsSelector.geoDist(50);
// ogsObject.ogsSelector.ActiveRect.Inflate(-Dist, -Dist);
 If TileLayer <> nil then begin
   Drawer.Clear(clWhite);
   TileLayer.Draw(Drawer);
 end else
  ogsObject.Draw(Drawer);
//
  If CaptureRec.resObject <> nil then
   TogsGeometry(CaptureRec.resObject).Draw(Drawer);
 Drawer.EndPaint;
// Drawer.DrawSect(ogsObject.ogsSelector.ActiveRect.GetSect);
 //ogsObject.ogsSelector.ActiveRect.Inflate(Dist, Dist);
 // WriteIn(['Elapsed=',GetTickCount - timeStart,' PrimsCount = ',ogsObject.Geometry.Count]);
end;

procedure TMainFrm.CaptureGeometry(X, Y: Double);
var I: Integer;
begin
 CaptureRec.ClearParams;
 If ogsObject.SelectByPoint(X, Y, CaptureRec) then begin
  Inspector.ogsProperties := TogsGeometry(CaptureRec.resObject).ogsProperties;
 // WriteIn(['Class=',TogsGeometry(CaptureRec.resObject).ClassName]);
 TogsGeometry(CaptureRec.resObject).Selected := True;
 WriteIn([TogsGeometry(CaptureRec.resObject).ogsRect]);
  // If Inspector.ogsProperties = nil then exit;
 end else Inspector.ogsProperties := nil;
 OnPaint(Self);
end;

procedure TMainFrm.actnOpenGMFExecute(Sender: TObject);
begin
 If ODGmf.Execute then begin
  ogsObject.Clear;
  ogsObject.OpenFile(ODGmf.FileName);
 // ogsObject.UpdateObject(True);
//  Drawer.DoOnPaint(Sender);
 end;
end;

procedure TMainFrm.Image32MouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
 If Button = mbMiddle then begin
  mwDowned := True;
  SetCapture(Image32.Handle);
  oldMPos.X := X; oldMPos.Y := Y;
  If btnTicker.QueryDblClick('down') then begin
   ogsObject.ogsSelector.UpdateRects(True);
   OnPaint(Sender);
  end;
 end else
 If Button = mbLeft then CaptureGeometry(ogsObject.ogsSelector.XGeo(X), ogsObject.ogsSelector.YGeo(Y));
end;

procedure TMainFrm.actnFitViewExecute(Sender: TObject);
begin
 ogsObject.ogsSelector.UpdateRects(True);
 OnPaint(Sender);
end;

procedure TMainFrm.Image32MouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
 If Button = mbMiddle then begin
  btnTicker.QueryDblClick('up');
  mwDowned := False;
  ReleaseCapture;
 end;
end;

procedure TMainFrm.Image32MouseMove(Sender: TObject; Shift: TShiftState; X,
 Y: Integer; Layer: TCustomLayer);
begin
 If mwDowned then With ogsObject.ogsSelector do begin
  Move(geoDist(- X + oldMPos.X), geoDist(- Y + oldMPos.Y));
  oldMPos.X := X; oldMPos.Y := Y;
  OnPaint(Sender);
 end;
 LabelXY.Caption := Fmt(['X=',ogsObject.ogsSelector.XGeo(X),' Y=',ogsObject.ogsSelector.YGeo(Y)]);
end;

procedure TMainFrm.Image32MouseWheel(Sender: TObject; Shift: TShiftState;
 WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
 Drawer.MouseWheel(Sender, Shift, WheelDelta, MousePos, Handled);
 OnPaint(Sender);
end;

procedure TMainFrm.Image32Resize(Sender: TObject);
begin
 Drawer.Width := Image32.Width; Drawer.Height := Image32.Height;
 ogsObject.ogsSelector.UpdateRects(False);
 OnPaint(Sender);
end;

procedure TMainFrm.MenuItem1Click(Sender: TObject);
begin
 ogsObject.Clear;
 Inspector.ogsProperties := nil;
 OnPaint(Sender);
end;

procedure TMainFrm.actnOpenDWGExecute(Sender: TObject);
begin
 If ODDwg.Execute then begin
  ogsObject.Clear;
  If ogcGMFReader.OpenDWG(ogsObject, ODDwg.FileName) <> 0 then begin
   ogsObject.ogsSelector.UpdateRects(True);
   Drawer.DoOnPaint(Sender);
  end;
 end;
end;

procedure TMainFrm.FormChangeBounds(Sender: TObject);
begin

end;

procedure TMainFrm.GroupBox1Click(Sender: TObject);
begin

end;

procedure TMainFrm.SpkSmallButton1Click(Sender: TObject);
var IEObject, rootIE, P: TIEObject;
    rootGr: TIEGarbageItems;
    I: Integer;
    List:TList;
begin
 List := TList.Create;
 WriteIn(['memFree1=',ogsObject.ogsSelector.memFree]);
 IEObject := TIEObject.Create(nil, ogsObject);
 rootIE := IEObject; rootGr := IEObject.IEGarbageItem;
 For I := 0 to 5 do begin
  IEObject := TIEObject.Create(IEObject, ogsObject);
  List.Add(IEObject);
//  WriteIn(['Create.Count=',rootGr.Count, rootGr.Name, rootGr.Last.Name]);
 end;
 WriteIn(['memFree2=',ogsObject.ogsSelector.memFree]);
// rootGr.FreeAll;
 WriteIn(['memFree3=',ogsObject.ogsSelector.memFree]);
// WriteIn(['beforeFree.Count=',rootGr.Count, rootGr.Name, rootGr.Last.Name]);
// rootGr.Free;
 For I := 1 to 3 do begin
  P := List[I];
  WriteIn(['beforeFree.Count=',rootGr.Count, rootGr.Name, rootGr.Last.Name]);
  P.Free;
  WriteIn(['afterFree.Count=',rootGr.Count, rootGr.Name, rootGr.Last.Name]);
 end;
 rootGr.FreeAll;
  WriteIn(['beforeFree.Count=',rootGr.Count, rootGr.Name, rootGr.Last.Name]);
end;

procedure TMainFrm.ToggleBox1Change(Sender: TObject);
var Counter: TgmfPlayer;
    currentDrawer: TogsDrawer;
begin
 Counter := TgmfPlayer.Create(ogsObject.ogsSelector, Drawer, TogsCollection.Create);
 currentDrawer := Drawer;
 Drawer := Counter;
 try
  ogsObject.ogsSelector.ActiveRect.Inflate(-1,-1);
  Drawer.OnPaint(Self);
  WriteIn(['Drawer.Count=',Drawer.cmdPlayer.Count]);
  ogsObject.ogsSelector.ActiveRect.Inflate(1,1);
 finally
  Drawer := currentDrawer;
 end;
 Counter.SaveToFile(ExtractFilePath(ParamStr(0))+'tstPlayer100x100.gr');
 Counter.Free;
end;

procedure TMainFrm.VLEClick(Sender: TObject);
begin

end;

function SortBy1(Item1, Item2: Pointer): Integer;
begin
 If TogsGeometry(Item1).Square < TogsGeometry(Item2).Square then Result := -1 else
 If TogsGeometry(Item1).Square = TogsGeometry(Item2).Square then begin
   If (TObject(Item1) is TogsPoint) and (TObject(Item2) is TogsPoint) then
     Result := -1 else
                     Result := 0
 end else
 If TogsGeometry(Item1).Square > TogsGeometry(Item2).Square then Result := 1;
end;

function SortBy2(Item1, Item2: Pointer): Integer;
begin
 If TogsGeometry(Item1).Square < TogsGeometry(Item2).Square then Result := 1 else
 If TogsGeometry(Item1).Square = TogsGeometry(Item2).Square then begin
   If (TObject(Item1) is TogsPoint) and (TObject(Item2) is TogsPoint) then
     Result := -1 else
                     Result := 0
 end else
 If TogsGeometry(Item1).Square > TogsGeometry(Item2).Square then Result := -1;
end;

var B: Boolean = True;

procedure TMainFrm.spkSortClick(Sender: TObject);
var I: Integer;
    Geometry: TogsGeometryCollection;
begin
 Geometry := ogsObject.Geometry;
 WriteIn(['before=========',B]);
 For I := 0 to Geometry.Count - 1 do
  WriteIn(['I=', Geometry[I].Square]);
 If B then Geometry.SortByProc(SortBy1, True) else
           Geometry.SortByProc(SortBy2, True);
 B := not(B);
 WriteIn(['after=========',B]);
 For I := 0 to Geometry.Count - 1 do
  WriteIn(['I=', Geometry[I].Square]);
 Drawer.DoOnPaint(nil);
end;


var MLine: TgmfMultiLine;

procedure TMainFrm.SpkLargeButton3Click(Sender: TObject);
var Arc: TogsArc; Rec: TArcRec;
begin
 (*
 Arc := TogsArc.Create(ogsObject.ogsSelector, Rec.Create(10,20, 0, 10, 10, 0, 14, 5, 0));
 Arc.CreateVertexes;
 MLine := TgmfMultiLine.Create(ogsObject.ogsSelector);
 MLine.AddPoint(Arc);
 MLine.AddPoint(TogsEdge.Create(ogsObject.ogsSelector, 10, 20, 0, 20, 20, 0));
 MLine.AddPoint(TogsEdge.Create(ogsObject.ogsSelector, 20, 20, 0, 30, 30, 0));
 MLine.Calculate([calcbBox]);
// WriteIn(['1=',MLin e.ogsRect]);
// ogsObject.AddPrim(MLine);
// WriteIn(['2=',ogsObject.ogsRect]);
 ogsObject.UpdateObject(True);
 *)
end;

procedure TMainFrm.SpkLargeButton2Click(Sender: TObject);
var I: Integer;
    MLine2: TgmfMultiLine;
    Line: TogsEdge;
    Edge, First: PGeoEdge;
    Arc: TogsArc;
begin
 (*
// заполнение PGeoEdge - аналог PGeoPoint с координатами отрезка или дуги
// MLine заполняется при нажатии на кнопку Arc
 New(Edge); First := Edge;
 For I := 0 to MLine.Count - 1 do begin
  Line := MLine[I];
  If not (Line is TogsArc) then begin
   If I = 0 then Edge.Create(Line.A.X, Line.A.Y, 0, Line.B.X, Line.B.Y, 0) else begin
                 Edge.AddCoord(Line.A.X, Line.A.Y, 0, Line.B.X, Line.B.Y, 0);
                 Edge := Edge.Next;
   end;
  end else
  With TogsArc(Line) do begin
   If I = 0 then Edge.Create(Line.A.X, Line.A.Y, 0, Line.B.X, Line.B.Y, 0) else begin
                 Edge.AddCoord(Line.A.X, Line.A.Y, 0, Line.B.X, Line.B.Y, 0);
                 Edge := Edge.Next;
   end;
   Edge.XD := D.X; Edge.YD := D.Y; Edge.Bulge := 1;
  end;
  Inc(First.Count);
  WriteIn([First.Count]);
  WriteIn(['apXY=', Edge.Count, Edge.XA, Edge.YA, Edge.XB, Edge.YB, Edge.XD, Edge.YD]);
 end;
// чтение данных из PGeoEdge
 MLine2 := TgmfMultiLine.Create(ogsObject.ogsSelector);
 Edge := First;
 For I := 0 to First.Count - 1 do begin
   WriteIn(['apXY=', Edge.Count, Edge.XA, Edge.YA, Edge.XB, Edge.YB, Edge.XD, Edge.YD]);
   If Edge.Bulge = 0 then
    MLine2.AddPoint(TogsEdge.Create(ogsObject.ogsSelector, Edge.XA, Edge.YA, Edge.ZA, Edge.XB, Edge.YB, Edge.ZB)) else
   begin
    Arc := TogsArc.Create(ogsObject.ogsSelector, Edge.GetArcRec);
    Arc.CreateVertexes;
    MLine2.AddPoint(Arc);
   end;
   Edge := Edge.Next;
 end;
 MLine2.Calculate([calcbBox]);
 WriteIn(['1=',MLine2.ogsRect]);
 ogsObject.AddPrim(MLine2);
 WriteIn(['2=',ogsObject.ogsRect]);
 ogsObject.UpdateObject(True);
*)
end;

procedure TMainFrm.SpkLargeButton4Click(Sender: TObject);
var P: TogsCollection;
    mFree, mFree1, mFree2: Integer;
    I, J, K, M: Integer;
    FC: TFontCollect;
    Poly:TgmfPolygon;
    PS: Tpoly_Single;
begin
 mFree := ogsObject.ogsSelector.memFree;
// ogsFontManager.FindBy('Arial', ItalicBold(False, False), FC);
// FC.LoadModeComplete;
 mFree := ogsObject.ogsSelector.memFree;
 WriteIn(['Mem1=', ogsObject.ogsSelector.memFree]);
  For J := 0 to 1 do begin
  P := TogsCollection.Create(1);
  For I := 0 to 800 do begin
  // P.Add(TogsTextString.Create(ogsObject.ogsSelector, FC, 100, 100,
  //                                             0, 10, 0, 2, [ftaLeft], '123456789', '', 2));
   Poly := TgmfPolygon.Create(ogsObject.ogsSelector);
   For K := 0 to 100 do begin
    PS := TPoly_Single.Create(ogsObject.ogsSelector);
     For M := 0 to 10 do
      PS.Add(TogsPoint.Create(0,0,0, ogsObject.ogsSelector));
    Poly.Add(PS);
   end;
   P.Add(Poly);
  end;
  P.Free;
  end;
//  FC.FreeAll; FC.fLoadMode := lmIncomplete;
 WriteIn(['Mem2=', ogsObject.ogsSelector.memFree - mFree]);
// mFree1 := ogsObject.ogsSelector.memFree;
//  P.Free;
 WriteIn(['Mem3=', ogsObject.ogsSelector.memFree - mFree1, ogsObject.ogsSelector.memFree - mFree]);
 WriteIn(['===']);
end;

// Server ===================================================================

var WSClient: TBaseWebSocketClient = nil;

procedure TMainFrm.sbAutoriseClick(Sender: TObject);
var  Login, Password: String;
begin
 Login :='test'; Password := 'Sy8GBs5qkRYd';
 if not Assigned(WSClient) then begin
  WSClient := TBaseWebSocketClient.Create(Self, '5.129.252.72', '4000');
  WriteIn(['Client.Start']);
  WSClient.GetToken(Login, Password);
 end else
  WriteIn(['AlreadyStarted']);
// sClient.Socket.OnSyncStatus := ConnectionSocketL;
end;

procedure TMainFrm.spConnectClick(Sender: TObject);
begin
WriteIn(['wsClient.Connect', DateTimeToStr(Now)]);
 WSClient.Connect;
end;

procedure TMainFrm.SpkCreateSessionClick(Sender: TObject);
begin
 If WSClient.Connected then begin
  WriteIn(['wsClient.GetSession', DateTimeToStr(Now)]);
  WSClient.SendMsg(MSGID_CreateSession, 'test text');
 end;
end;

// тайлер

procedure TMainFrm.btnTestTilesClick(Sender: TObject);
var I: Integer;
begin
 if Sender = btnTestTiles1 then begin
   TileLayer.Free; TileLayer := nil;
   Drawer.DoOnPaint(nil);
   exit;
 end;
 WriteIn(['Drawer1=', ogsObject.ogsSelector.ogsDrawer.ClassName]);
 TileLayer := TogsTileLayer.Create(ogsObject);
 TileLayer.CompileMapLayer;
//
WriteIn(['Drawer2=', ogsObject.ogsSelector.ogsDrawer.ClassName]);
 Drawer.DoOnPaint(nil);
 WriteIn(['Drawer3=', ogsObject.ogsSelector.ogsDrawer.ClassName]);
end;

initialization
 WSClient := nil;
end.

