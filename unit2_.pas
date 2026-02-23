unit Unit2;

{$mode Delphi}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 ComCtrls, ValEdit, DebuggerForm, GR32_Image, ogcBasic, ogcDrawer32, GLCanvas,
 GR32_Layers, Types, GR32, OpenGLCanvas, ogcGeometry, SynEdit, vte_json,
 vte_stringlist, vte_propertytree, VirtualTrees, Grids, ActnList, ogcInspector,
 MainForm1, Interfaces, LCLProc, LazLoggerBase, LazTracer;

type

 { TDemoForm }

 TDemoForm = class(TForm)
  btnCanvas: TButton;
  Button1: TButton;
  Button2: TButton;
  btnImage32: TButton;
  btnLoadGMF: TButton;
  bJSON: TButton;
  Button3: TButton;
  Button4: TButton;
  CheckBox1: TCheckBox;
  CheckBox2: TCheckBox;
  Edit1: TEdit;
  ImageList1: TImageList;
  Label1: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  OGLC: TOpenGLCanvas;
  Image1: TPaintBox;
  Store: TButton;
  GLCanvas: TButton;
  plus: TButton;
  minus: TButton;
  Load: TButton;
  up: TButton;
  right: TButton;
  left: TButton;
  down: TButton;
  JSONView: TVirtualJSONInspector;
  VLE: TValueListEditor;
  VirtualNumberedMemo1: TVirtualNumberedMemo;
  procedure bJSONClick(Sender: TObject);
  procedure btnImage32Click(Sender: TObject);
  procedure btnCanvasClick(Sender: TObject);
  procedure btnLoadGMFClick(Sender: TObject);
  procedure Button2Click(Sender: TObject);
  procedure Button3Click(Sender: TObject);
  procedure Button4Click(Sender: TObject);
  procedure CheckBox1Click(Sender: TObject);
  procedure CheckBox2Change(Sender: TObject);
  procedure CheckBox2Click(Sender: TObject);
  procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  procedure FormCreate(Sender: TObject);
  procedure FormPaint(Sender: TObject);
  procedure FormResize(Sender: TObject);
  procedure GLCanvasClick(Sender: TObject);
  procedure Image1DblClick(Sender: TObject);
  procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer);
  procedure Image1MouseLeave(Sender: TObject);
  procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer);
  procedure Image1MouseWheel(Sender: TObject; Shift: TShiftState;
   WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  procedure Image1MouseWheelDown(Sender: TObject; Shift: TShiftState;
   MousePos: TPoint; var Handled: Boolean);
  procedure Image1MouseWheelUp(Sender: TObject; Shift: TShiftState;
   MousePos: TPoint; var Handled: Boolean);
  procedure Image1Paint(Sender: TObject);
  procedure Image1Resize(Sender: TObject);
  procedure Image32Resize(Sender: TObject);
   procedure LoadClick(Sender: TObject);
  procedure minusClick(Sender: TObject);
  procedure OGLCMouseWheel(Sender: TObject; Shift: TShiftState;
   WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  procedure StoreClick(Sender: TObject);
  procedure upClick(Sender: TObject);
 public
  Image: TImage;
  Image32: TImage32;
  OGLCanvas: TOpenGLCanvas;
  Selector: TogsSelector;
  Drawer: TogsDrawer;
  Prims: TogsGeometryCollection;
  oldMPos: TPoint;
  mwDowned: Boolean;
  Inspector: TPropInspector;
  procedure OnPaint(Sender: TObject); virtual;
 end;

var
 DemoForm: TDemoForm;

implementation uses ogcWriter, ogcRects, ogcDrawerCanvas,
                    ogcDrawerGLCanvas,
                   // старые модули для загрузки
                    WPTForm2, CreateTWG, newSelector, Collect, EcLot, EcDot,
                    ogcJSON, fpjson, jsonparser, strutils, ogcProperties;

{$R *.frm}

{ TDemoForm }

procedure TDemoForm.FormCreate(Sender: TObject);
var I: Integer;
begin
 if Debugger = nil then Debugger := TDebugger.Create(nil);
 Debugger.Show;
 For I:=0 to ogsRegisteredClasses.Count-1 do
 With TogsRegisteredClass(ogsRegisteredClasses[I]) do
  WriteIn([objClassType.ClassName,ClassNum, ClassRank]);
// создаем Selector
 Selector := TogsSelector.Create(Drawer);
 Prims := TogsGeometryCollection.Create(Selector);
 Edit1.Text := '{ "type": "FeatureCollection", "features": [ "geometry": {"coordinates": [ sys_SpatialData ], "type": sys_GeometryType, "properties": { "sys_Properties" } } ]';
 Inspector := TPropInspector.Create(VLE, nil, ImageList1);
 btnImage32Click(nil);
end;

procedure TDemoForm.FormPaint(Sender: TObject);
begin
 OnPaint(Self);
end;

procedure TDemoForm.btnImage32Click(Sender: TObject);
begin
 OGLC.Visible := False;
 Image32 := TImage32.Create(Self); Image32.Visible:=False;
 Image32.RepaintMode := rmFull;
 Image32.Color := clYellow; Image32.Update(Image32.ClientRect);
 Image32.Width := Image1.Width; Image32.Height := Image1.Height;
// Image32.Align := alClient;
 Drawer := TogsDrawer32.Create(Selector, Image32, OnPaint);
 Label1.Caption := 'Graphics32';
end;

procedure TDemoForm.btnCanvasClick(Sender: TObject);
begin
 OGLC.Visible := False;
 Image := TImage.Create(Self); Image.Visible := False;
 Image.Width := Image1.Width; Image.Height := Image1.Height;
 Drawer := TogsDrawerCanvas.Create(Selector, Image, OnPaint);
 Label1.Caption := 'Native';
 Button2Click(Sender);
end;

procedure TDemoForm.GLCanvasClick(Sender: TObject);
begin
 OGLCanvas := OGLC;//TOpenGLCanvas.Create(Self);
 OGLCanvas.Visible := True; Image1.Visible := False;
 OGLCanvas.Left := Image1.Left; OGLCanvas.Top := Image1.Top;
 OGLCanvas.Width := Image1.Width; OGLCanvas.Height := Image1.Height;
 OGLCanvas.OnPaint := Button2Click;
 Drawer := TogsDrawerGL.Create(Selector, OGLCanvas, OnPaint);
 Label1.Caption := 'OpenGL';
end;

procedure TDemoForm.Image1DblClick(Sender: TObject);
begin
 Selector.UpdateRects(True);
 Button2Click(Sender);
end;

procedure TDemoForm.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
 If mwDowned then With Selector do begin
  Move(geoDist(- X + oldMPos.X), geoDist(- Y + oldMPos.Y));
  oldMPos.X := X; oldMPos.Y := Y;
  Button2Click(Sender);
 end;
 Label3.Caption := Fmt(['X=',Selector.XGeo(X),' Y=',Selector.YGeo(Y)]);
end;

procedure TDemoForm.Image1MouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 mwDowned := False;
end;

procedure TDemoForm.Image1MouseWheel(Sender: TObject; Shift: TShiftState;
 WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
 Drawer.MouseWheel(Sender, Shift, WheelDelta, MousePos, Handled);
 Drawer.DrawTo(Image1.Canvas, Image1.ClientRect);
end;

procedure TDemoForm.Image1MouseWheelDown(Sender: TObject; Shift: TShiftState;
 MousePos: TPoint; var Handled: Boolean);
begin
end;

procedure TDemoForm.Image1MouseWheelUp(Sender: TObject; Shift: TShiftState;
 MousePos: TPoint; var Handled: Boolean);
begin
end;

procedure TDemoForm.Image1Paint(Sender: TObject);
begin
 If Drawer <> nil then
  Drawer.DrawTo(Image1.Canvas, Image1.ClientRect);
end;

procedure TDemoForm.Image1Resize(Sender: TObject);
begin
 //
end;

procedure TDemoForm.OGLCMouseWheel(Sender: TObject; Shift: TShiftState;
 WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
 Drawer.MouseWheel(Sender, Shift, WheelDelta, MousePos, Handled);
 TOgsDrawerGL(Drawer).Image.DoOnPaint(Sender);
// Drawer.DrawTo(Image1, Image1.ClientRect);
end;

procedure TDemoForm.Button2Click(Sender: TObject);
var I, J: Integer; Line: TogsLineString;
     ARect: TRect;
begin
//WriteIn(['---------------------', Prims.Count, Drawer.Width, Drawer.Height]);
 If Drawer is TOgsDrawerGL then TOgsDrawerGL(Drawer).Image.DoOnPaint(Sender) else
 Drawer.DoOnPaint(Sender);
 Drawer.DrawTo(Image1.Canvas, Image1.ClientRect);
//WriteIn(['---------------------']);

// WriteIn(['Height=', Drawer.Image.Bitmap.Height,Image1.Height]);
end;

procedure TDemoForm.CheckBox1Click(Sender: TObject);
begin
 outDisabled := CheckBox1.Checked;
end;

procedure TDemoForm.CheckBox2Change(Sender: TObject);
begin

end;

procedure TDemoForm.CheckBox2Click(Sender: TObject);
begin
 Drawer.Disable := CheckBox2.Checked;
 Button2Click(nil);
end;

procedure TDemoForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 If Debugger <> nil then Debugger.Free;
end;

procedure TDemoForm.FormResize(Sender: TObject);
begin
 If Drawer = nil then exit;
 Drawer.Width := Image1.Width; Drawer.Height := Image1.Height;
 Selector.UpdateRects(False);
 Button2Click(Sender);
 WriteIn(['Width=', Image1.Width, Drawer.Width]);
end;

procedure TDemoForm.Image32Resize(Sender: TObject);
var Rect: TMRect;
begin
// необходимо поменять параметры Selector.activeRect
end;

procedure TDemoForm.minusClick(Sender: TObject);
begin
 With Selector, activeRect do
  If Sender = plus then Selector.Scale((XMax+XMin)/2, (YMax+YMin)/2, -2) else
  If Sender = minus then Selector.Scale((XMax+XMin)/2, (YMax+YMin)/2, 2);
 Button2Click(Sender);
end;

procedure TDemoForm.upClick(Sender: TObject);
begin
 If Sender = up then Selector.Move(0, -Drawer.geoHeight/10);
 If Sender = down then Selector.Move(0, Drawer.geoHeight/10);
 If Sender = left then Selector.Move(-Drawer.geoWidth/10,0);
 If Sender = right then Selector.Move(Drawer.geoWidth/10,0);
 Button2Click(Sender);
end;

procedure TDemoForm.btnLoadGMFClick(Sender: TObject);
begin
 WriteIn([]);
end;

procedure TDemoForm.StoreClick(Sender: TObject);
var Stream: TogsStream;
begin
// сохранение Prims
 Stream := TogsStream.CreateFileStream('C:\D\!!!DZ\testOGC.ogs',fmCreate);
  Stream.Put(Prims);
 Stream.Free;
end;

procedure TDemoForm.LoadClick(Sender: TObject);
var Stream: TogsStream;
    Line: TogsLineString;
    I, J: Integer;
begin
// сохранение Prims
 WriteIn(['sel.rect.iter=',Selector.ogsRect.Iter]);
 Stream := TogsStream.CreateFileStream('C:\D\!!!DZ\testOGC.ogs',fmOpenRead, Selector);
  Prims := TogsGeometryCollection(Stream.Get);
  WriteIn(['Count=',Prims.Count]);
 Stream.Free;
//
  For I:=0 to Prims.Count - 1 do Selector.AddPrim(Prims[I]);
//  WriteIn(['Next1=',Prims.Count]);
 Selector.UpdateRects(True);
 WriteIn(['Next2=',Prims.Count]);
 Button2Click(Sender);
end;

procedure TDemoForm.bJSONClick(Sender: TObject);
var Buf, Stream: TJSONStream;
    S: AnsiString;
    I: Integer;
    Time: Int64;
    Schema: TogsPropObject;
    JSONObject, Prop, Geometry, Properties: TogsPropValue;
    geomTtype: String;
 //
    Data: TJSONData;
    Parser: TJSONParser;
 //
    Point: TogsPoint;
    LineS: TogsLineString;
    Poly : TogsPolygon;
    PolyM: TogsMultiPolygon;
begin
{  For I:=0 to 10000  do begin
   LineS := TogsLineString.Create(Selector);
   LineS.AddPoint(Random(1000), Random(1000), 0);
   Selector.AddCoord(LineS.Point[0].X, LineS.Point[0].Y);
   LineS.AddPoint(Random(1000), Random(1000), 0);
   Selector.AddCoord(LineS.Point[1].X, LineS.Point[1].Y);
   Prims.Add(LineS);
  end;
  Selector.UpdateRects(True);
  Button2Click(Sender);
  exit;
}
 Edit1.Text := '{ "type": "FeatureCollection", "features": [ "geometry": {"coordinates":' +
               '[ sys_SpatialData ], "type": sys_GeometryType, "properties": { "sys_Properties": "" } } ]';
// грузим схему для разбора геоданных
 Stream := TJSONStream.CreateStringStream(Edit1.Text);
//  Schema := Stream.LoadDefaultObject(nil);
 Stream.Free;
// WriteIn([Schema.ToString]);
//
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\dogcat.txt', fmOpenRead, Selector);
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\phoneArray+Object.txt', fmOpenRead, Selector);
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\locations.txt', fmOpenRead, Selector);
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\embeddedarrays.txt', fmOpenRead, Selector);
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\Test111.geojson', fmOpenRead, Selector);
 Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\27048-2_poly.geojson', fmOpenRead, Selector);
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\30756625.geojson', fmOpenRead, Selector);
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\!Native1.txt', fmOpenRead, Selector);
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\mockturtle.json', fmOpenRead, Selector);
// Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\JSON-МАФ\tstgab.geojson', fmOpenRead, Selector);
//  Buf := TJSONStream.CreateTextStream('C:\!!!GIS_VAO\Паспорта 2023\Schema_msk50WGS.geojson', fmOpenRead, Selector);
// Buf := TJSONStream.CreateStringStream('{ "Pets": [["Dog","cat", {"Name": 10000.34, "Name2": 2222}, "end array", "ERzKO"], "2ARAAY","2ARRAY" ], "objType" : "2ARRAY", "object" : {"obj1": [1, 2, 3.03]}}}', Selector);
//
 Time := GetTickCount;
 WriteIn(['Start=',Time]);
 try
  JSONObject := Buf.LoadDefaultObject(nil); Buf.Position := 0;
// Parser := TJSONParser.Create(Buf.Stream);
//  Data := Parser.Parse;
//  WriteIn(['TreeJSON',Data.AsJSON]);
 // JSONView.RootData := Data;
 finally
//  Parser.Free;
  Buf.Free;
 end;
 WriteIn(['Stop=', GetTickCount - Time]);
// ищем переменные их схемы в json
// Prop := JSONObject.FindBySchema(Schema);
 outDisabled := True;
 If JSONObject.FindByNames(['Features','Geometry','Coordinates'], S) <> nilObject then begin
  Prims.FreeAll;
  Prop := JSONObject['Features'];
  If Prop is TogsPropArray then
   For I := 0 to Prop.Count - 1 do begin
    Geometry := Prop.Item[I]['Geometry'];
    Properties := Prop.Item[I]['Properties'];
//    If Properties['Root_id'].ToString = '920767734' then
    If Geometry['Type'] <> nilObject then
     // собираем геометрию в соответствии с типом "Geometry" -> "Type"
    // WriteIn(['geotype=',Geometry['Type'].ToString]);
     Case geometryType(Geometry['Type'].AsString) of
      gtPoint:begin
               Point := TogsPoint.CreateJSON(Geometry['Coordinates'], Properties, Selector);
               Prims.Add(Point);
              end;
      gtLineString:begin
                   // WriteIn(['GEOM=',Geometry['Type'].ToString]);
                    LineS := TogsLineString.CreateJSON(Geometry['Coordinates'], Properties, Selector);
                    Prims.Add(LineS);
                   // WriteIn(['EndGEOM=',Geometry['Type'].ToString]);
                   end;
      gtPolygon:begin
                 Poly := TogsPolygon.CreateJSON(Geometry['Coordinates'], Properties, Selector);
                 Prims.Add(Poly);
                end;
      gtMultiPolygon:begin
                      PolyM := TogsMultiPolygon.CreateJSON(Geometry['Coordinates'], Properties, Selector);
                      Prims.Add(PolyM);
                     end;
     end;
   end;
  Prims.SortByProc(SortBySquareProc, True);
  Selector.UpdateRects(True);
  WriteIn(['Next2=',Prims.Count]);
  Button2Click(Sender);
 end;
end;

procedure TDemoForm.OnPaint(Sender: TObject);
var I, J, K: Integer; Line: TogsLineString;
    timeStart: TDateTime;
    R: TogsRect;
 begin
 WriteIn(['beginPaint']);
 If Drawer = nil then Exit;
 timeStart := GetTickCount;
 Drawer.BeginPaint;
 Drawer.Clear(clWhite);
 Selector.UpdateRects(False);
// For j := 0 to 1000 do
  For I := 0 to Prims.Count - 1 do
   If Prims[I].Visible(Selector.ActiveRect) then begin
   { If Prims[I] is TogsLineString then Drawer.Pen.penColor := clBlue else
    If Prims[I] is TogsPolygon then Drawer.Pen.penColor := clGray else
    If Prims[I] is TogsMultiPolygon then Drawer.Pen.penColor := clMaroon else Drawer.Pen.penColor := clYellow;
    If Prims[I].Selected then Drawer.Pen.penColor := clLime;  }
//    WriteIn(['Paint.Ind=',I,Prims[I].ClassName]);
    Prims[I].Draw(Drawer);
//    WriteIn(['Paint.End',I]);
   // Prims[I].DrawPoint(Drawer);
   end;// else WriteIn(['notVisible=',Prims[I].ClassName,Prims[I].ogsRect.XMin,Prims[I].ogsRect.YMin,
              // Prims[I].ogsRect.XMax,Prims[I].ogsRect.YMax]);
  For I := 0 to Prims.Count - 1 do
   If Prims[I].Selected and Prims[I].Visible(Selector.ActiveRect) then begin
    Drawer.Pen.penColor := clLime;
    Prims[I].Draw(Drawer);
   // Prims[I].DrawPoint(Drawer);
   end;
 R := TogsRect.CreateAs(Selector.ActiveRect);
 R.Inflate(-1,-1);
 Drawer.DrawSect(R.Sect);
 R.Free;
 Drawer.EndPaint;
 WriteIn(['Elapsed=',GetTickCount - timeStart,' PrimsCount = ',Prims.Count]);
// outDisabled := True;
end;

procedure TDemoForm.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var I, J:Integer;
    cParams: TCaptureRec;
//  intParams: TInterRec;
    List: TList;
    Selected: Boolean;
    Intersects: TogsGeometryCollection;
    P1, P2: TogsGeometry;
    Buf: TogsStream;
    Data: TJSONData;
    Parser: TJSONParser;
    T: TDateTime;
begin
 If Button = mbMiddle then begin
  mwDowned := True;
  oldMPos.X := X; oldMPos.Y := Y;
 end else
 If Button = mbLeft then begin
  outDisabled := False;
  // выбор контура для проверки Properties
  cParams.ClearParams;
  outDisabled := False;
  Selected := False;
  T := GetTickCount;
  WriteIn(['Begin ', Prims.Count, T]);
  For I := Prims.Count - 1 downto 0 do begin
   TogsGeometry(Prims[I]).Selected := False;
   If cParams.resObject = nil then
    If Prims[I].Visible(Selector.ActiveRect) then
     If Prims[I].SelectByPoint(Selector.XGeo(X),Selector.YGeo(Y), cParams) then begin
      TogsGeometry(Prims[I]).Selected := True;
      Selected := True;
      If TogsGeometry(Prims[I]).ogsProperties <> nil then begin
        Inspector.ogsProperties := Prims[I].ogsProperties;
        WriteIn([Prims[I].ToString]);
        Buf := TogsStream.CreateStringStream(Prims[I].ogsProperties.ToString);
        Parser := TJSONParser.Create(Buf.Stream);
        try
        // Data := Parser.Parse;
        // If JSONView.RootData <> nil then JSONView.RootData.Free;
        // JSONView.RootData := Data;
        finally
         Parser.Free;
         Buf.Free;
        end;
      // WriteIn([TogsGeometry(Prims[I]).ogsProperties.ToString]);
      end;
     end;
  end;
  If not Selected then Inspector.ogsProperties := nil;
  WriteIn(['End', GetTickCount - T]);
  outDisabled := True;
  Drawer.DoOnPaint(Sender);
  Drawer.DrawTo(Image1.Canvas, Image1.ClientRect);
 end;
end;

procedure TDemoForm.Image1MouseLeave(Sender: TObject);
begin
 mwDowned := False;
end;

procedure TDemoForm.Button3Click(Sender: TObject);
var I, J: Integer;
    F, F1: TextFile;
    LS: TogsLineString;
    PP: TogsPoint;
    propValue, propTree, propBush, Tree, Bush: TogsPropValue;
    Buf: TogsStream;
    St: TStringList;
Procedure ToTrees(prop: TogsPropValue; SectionName: String);
var I, J: Integer;
    S: String;
begin
 St.Add(SectionName);
 For I := 0 to prop.Count - 1 do begin
   Tree := prop.Item[I]['Children'];
    For J := 0 to Tree.Count - 1 do begin
     S :=  Tree.Item[J]['Text'].ToString;
     Delete(S,1,1); Delete(S, Length(S),1);
     St.Add(S);
    end;
  end;
end;
begin
 Buf := TJSONStream.CreateTextStream('C:\!!!ГЗ\Борт\message.txt', fmOpenRead, Selector);
 propValue := Buf.LoadDefaultObject(nil);
 propTree := propValue['Trees'];
 propBush := propValue['Bushes'];
 St:=TStringList.Create;
  ToTrees(propTree, '[Порода дерево]');
   St.Add('');
  ToTrees(propBush, '[Порода куст]');
 St.SaveToFile('C:\!!!ГЗ\Борт\Trees.txt');
 Buf.Free;
exit;
 AssignFile(F, 'C:\!!!GIS_VAO\Паспорта 2023\output.txt');
 Rewrite(F);
 AssignFile(F1, 'C:\!!!GIS_VAO\Паспорта 2023\outtext.txt');
 Rewrite(F1);
 For I := 0 to Prims.Count - 1 do
 If Prims[I] is TogsLineString then begin
  LS := TogsLineString(Prims[I]);
  Writeln(F, LS.Count);
  For J := 0 to LS.Count-1 do Writeln(F, LS.Point[J].X, #13#10, LS.Point[J].Y);
 end else
 If Prims[I] is TogsPoint then begin
  PP := TogsPoint(Prims[I]);
  propValue := PP.ogsProperties as TogsPropValue;
  propValue := propValue['Text'];
  If propValue <> nilObject then
   Writeln(F1, propValue.ToString) else Writeln(F1, 'null');
  Writeln(F1, PP.X, #13#10, PP.Y);
 end;
 CloseFile(F);
 CloseFile(F1);
end;

procedure TDemoForm.Button4Click(Sender: TObject);
begin
 Image32.Color := clRed;
end;

begin
 Application.Scaled:=True;
end.

