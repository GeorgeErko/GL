unit vfLineTypesForm;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, Types, Math, ImgList, Buttons, vfLineStyles;

type
  TfrmVFLineTypes = class(TForm)
    ilButtons: TImageList;
    btnAddLineType: TBitBtn;
    btnDeleteLineType: TBitBtn;
    btnApplyLayerParams: TBitBtn;
    cbEnabled: TCheckBox;
    cbCapKind: TComboBox;
    cbJoinKind: TComboBox;
    edtBaseThickness: TEdit;
    edtColor: TEdit;
    edtDash: TEdit;
    edtDashOffset: TEdit;
    edtGap: TEdit;
    edtLayerName: TEdit;
    edtOffset: TEdit;
    edtTrimEnd: TEdit;
    edtTrimStart: TEdit;
    edtUserParams: TEdit;
    lblBaseThickness: TLabel;
    lblCapKind: TLabel;
    lblColor: TLabel;
    lblDash: TLabel;
    lblDashOffset: TLabel;
    lblGap: TLabel;
    lblJoinKind: TLabel;
    lblLayerName: TLabel;
    lblOffset: TLabel;
    lblTrimEnd: TLabel;
    lblTrimStart: TLabel;
    lblUserParams: TLabel;
    miAddCustomLayer: TMenuItem;
    miAddPatternLayer: TMenuItem;
    miAddSolidLayer: TMenuItem;
    pmTree: TPopupMenu;
    pbPreview: TPaintBox;
    pnlLeftBottom: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    pnlParamsBottom: TPanel;
    pnlParams: TPanel;
    pcLayerParams: TPageControl;
    splMain: TSplitter;
    tsCommon: TTabSheet;
    tsSolid: TTabSheet;
    tsPattern: TTabSheet;
    tsCustom: TTabSheet;
    tvLineTypes: TTreeView;
    procedure btnAddLineTypeClick(Sender: TObject);
    procedure btnApplyLayerParamsClick(Sender: TObject);
    procedure btnDeleteLineTypeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure miAddCustomLayerClick(Sender: TObject);
    procedure miAddPatternLayerClick(Sender: TObject);
    procedure miAddSolidLayerClick(Sender: TObject);
    procedure pbPreviewPaint(Sender: TObject);
    procedure tvLineTypesEditing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure tvLineTypesEdited(Sender: TObject; Node: TTreeNode; var S: string);
    procedure tvLineTypesCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure tvLineTypesSelectionChanged(Sender: TObject);
  private
    FLineTypes: TVFLineStyleList;
    FCurrentLineType: TVFLineStyle;
    FCurrentLayer: TVFLineLayer;
    function GetLineTypeName(const Style: TVFLineStyle): string;
    function GetLayerName(const Layer: TVFLineLayer): string;
    function GetSelectedStyle: TVFLineStyle;
    function GetSelectedStyleNode: TTreeNode;
    function GetSelectedLayer: TVFLineLayer;
    function FindStyleIndexByPtr(const Style: TVFLineStyle): Integer;
    function HasStyleNameConflict(const AName: string; const ExceptStyle: TVFLineStyle): Boolean;
    procedure ResortLineTypes;
    procedure RebuildList;
    procedure SetCurrentLineType(AStyle: TVFLineStyle);
    procedure SetCurrentLayer(ALayer: TVFLineLayer);
    procedure SetActiveLayerInStyle(const Style: TVFLineStyle; const ActiveLayer: TVFLineLayer);
    procedure BuildDemoPolyline(out Points: TVFLinePolygon);
    function CreateUniqueStyleName(const BaseName: string): string;
    procedure EnsureDefaultSolidLayer(const Style: TVFLineStyle);
    procedure AddLayerToSelectedStyle(ALayerClass: TVFLineLayerClass);
    procedure DeleteSelectedStyle;
    procedure UpdateParamsUI;
    procedure SaveParamsToLayer;
    procedure ApplyNodeNameFromTree;
  public
    property LineTypes: TVFLineStyleList read FLineTypes;
    property CurrentLineType: TVFLineStyle read FCurrentLineType write SetCurrentLineType;
    property CurrentLayer: TVFLineLayer read FCurrentLayer write SetCurrentLayer;
  end;

var
  frmVFLineTypes: TfrmVFLineTypes;

implementation

{$R *.frm}

procedure TfrmVFLineTypes.FormCreate(Sender: TObject);
var
  Bmp: TBitmap;
  X0, Y0: Integer;
begin
  FLineTypes := TVFLineStyleList.Create;
  FCurrentLineType := nil;
  FCurrentLayer := nil;

  RebuildList;
  SetCurrentLineType(nil);
  SetCurrentLayer(nil);

  cbCapKind.Items.Clear;
  cbCapKind.Items.Add('Round');
  cbCapKind.Items.Add('Butt');

  cbJoinKind.Items.Clear;
  cbJoinKind.Items.Add('Round');
  cbJoinKind.Items.Add('Bevel');
  cbJoinKind.Items.Add('Miter');

  if ilButtons <> nil then
  begin
    ilButtons.Clear;
    ilButtons.Width := 16;
    ilButtons.Height := 16;

    Bmp := TBitmap.Create;
    try
      Bmp.SetSize(16, 16);
      Bmp.Transparent := True;
      Bmp.TransparentColor := clFuchsia;

      // Add
      Bmp.Canvas.Brush.Color := clFuchsia;
      Bmp.Canvas.FillRect(Rect(0, 0, 16, 16));
      Bmp.Canvas.Pen.Color := clGreen;
      Bmp.Canvas.Pen.Width := 2;
      X0 := 8;
      Y0 := 8;
      Bmp.Canvas.Line(X0 - 5, Y0, X0 + 5, Y0);
      Bmp.Canvas.Line(X0, Y0 - 5, X0, Y0 + 5);
      ilButtons.AddMasked(Bmp, clFuchsia);

      // Delete
      Bmp.Canvas.Brush.Color := clFuchsia;
      Bmp.Canvas.FillRect(Rect(0, 0, 16, 16));
      Bmp.Canvas.Pen.Color := clMaroon;
      Bmp.Canvas.Pen.Width := 2;
      Bmp.Canvas.Line(3, 8, 13, 8);
      ilButtons.AddMasked(Bmp, clFuchsia);

      // Apply
      Bmp.Canvas.Brush.Color := clFuchsia;
      Bmp.Canvas.FillRect(Rect(0, 0, 16, 16));
      Bmp.Canvas.Pen.Color := clNavy;
      Bmp.Canvas.Pen.Width := 2;
      Bmp.Canvas.Line(3, 9, 7, 13);
      Bmp.Canvas.Line(7, 13, 13, 3);
      ilButtons.AddMasked(Bmp, clFuchsia);
    finally
      Bmp.Free;
    end;

    ilButtons.GetBitmap(0, btnAddLineType.Glyph);
    btnAddLineType.NumGlyphs := 1;
    ilButtons.GetBitmap(1, btnDeleteLineType.Glyph);
    btnDeleteLineType.NumGlyphs := 1;
    ilButtons.GetBitmap(2, btnApplyLayerParams.Glyph);
    btnApplyLayerParams.NumGlyphs := 1;
  end;
end;

procedure TfrmVFLineTypes.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLineTypes);
  FCurrentLineType := nil;
  FCurrentLayer := nil;
end;

function TfrmVFLineTypes.FindStyleIndexByPtr(const Style: TVFLineStyle): Integer;
var
  I: Integer;
begin
  Result := -1;
  if (Style = nil) or (FLineTypes = nil) then
    Exit;
  for I := 0 to FLineTypes.Count - 1 do
    if FLineTypes[I] = Style then
      Exit(I);
end;

function TfrmVFLineTypes.HasStyleNameConflict(const AName: string;
  const ExceptStyle: TVFLineStyle): Boolean;
var
  I: Integer;
  S: TVFLineStyle;
begin
  Result := False;
  if (FLineTypes = nil) or (Trim(AName) = '') then
    Exit;
  for I := 0 to FLineTypes.Count - 1 do
  begin
    S := FLineTypes[I];
    if (S <> nil) and (S <> ExceptStyle) and SameText(S.Name, AName) then
      Exit(True);
  end;
end;

procedure TfrmVFLineTypes.ResortLineTypes;
var
  Temp: TVFLineStyleList;
  I: Integer;
begin
  if FLineTypes = nil then
    Exit;

  Temp := TVFLineStyleList.Create;
  try
    for I := 0 to FLineTypes.Count - 1 do
      Temp.Add(FLineTypes[I]);

    FLineTypes.DeleteAll;

    for I := 0 to Temp.Count - 1 do
      FLineTypes.Add(Temp[I]);

    Temp.DeleteAll;
  finally
    Temp.Free;
  end;
end;

procedure TfrmVFLineTypes.RebuildList;
var
  StyleIndex, LayerIndex: Integer;
  S: TVFLineStyle;
  StyleNode: TTreeNode;
  Layer: TVFLineLayer;
begin
  tvLineTypes.Items.BeginUpdate;
  try
    tvLineTypes.Items.Clear;
    for StyleIndex := 0 to FLineTypes.Count - 1 do
    begin
      S := FLineTypes[StyleIndex];
      StyleNode := tvLineTypes.Items.AddObject(nil, GetLineTypeName(S), S);
      for LayerIndex := 0 to S.LayerCount - 1 do
      begin
        Layer := S.Layer[LayerIndex];
        tvLineTypes.Items.AddChildObject(StyleNode, GetLayerName(Layer), Layer);
      end;
      StyleNode.Expand(True);
    end;
  finally
    tvLineTypes.Items.EndUpdate;
  end;
end;

function TfrmVFLineTypes.GetLineTypeName(const Style: TVFLineStyle): string;
begin
  if Style = nil then
    Result := ''
  else if Style.Name <> '' then
    Result := Style.Name
  else
    Result := Style.ClassName;
end;

function TfrmVFLineTypes.GetLayerName(const Layer: TVFLineLayer): string;
begin
  if Layer = nil then
    Result := '(nil)'
  else if Layer.Name <> '' then
    Result := Layer.Name
  else
    Result := Layer.ClassName;
end;

function TfrmVFLineTypes.GetSelectedStyleNode: TTreeNode;
begin
  Result := nil;
  if not Assigned(tvLineTypes) then
    Exit;
  if not Assigned(tvLineTypes.Selected) then
    Exit;
  if tvLineTypes.Selected.Level = 0 then
    Result := tvLineTypes.Selected
  else
    Result := tvLineTypes.Selected.Parent;
end;

function TfrmVFLineTypes.GetSelectedStyle: TVFLineStyle;
var
  N: TTreeNode;
begin
  Result := nil;
  N := GetSelectedStyleNode;
  if (N <> nil) and (TObject(N.Data) is TVFLineStyle) then
    Result := TVFLineStyle(N.Data);
end;

function TfrmVFLineTypes.GetSelectedLayer: TVFLineLayer;
begin
  Result := nil;
  if not Assigned(tvLineTypes) then
    Exit;
  if not Assigned(tvLineTypes.Selected) then
    Exit;
  if (tvLineTypes.Selected.Level = 1) and (TObject(tvLineTypes.Selected.Data) is TVFLineLayer) then
    Result := TVFLineLayer(tvLineTypes.Selected.Data);
end;

procedure TfrmVFLineTypes.SetCurrentLineType(AStyle: TVFLineStyle);
begin
  if FCurrentLineType = AStyle then
    Exit;
  FCurrentLineType := AStyle;
  pbPreview.Invalidate;
end;

procedure TfrmVFLineTypes.SetCurrentLayer(ALayer: TVFLineLayer);
begin
  if FCurrentLayer = ALayer then
    Exit;
  FCurrentLayer := ALayer;
  if (FCurrentLineType <> nil) then
    SetActiveLayerInStyle(FCurrentLineType, FCurrentLayer);
  UpdateParamsUI;
  if Assigned(tvLineTypes) then
    tvLineTypes.Invalidate;
  if Assigned(pbPreview) then
    pbPreview.Invalidate;
end;

procedure TfrmVFLineTypes.tvLineTypesSelectionChanged(Sender: TObject);
begin
  SetCurrentLineType(GetSelectedStyle);
  SetCurrentLayer(GetSelectedLayer);
end;

procedure TfrmVFLineTypes.tvLineTypesEditing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
begin
  AllowEdit := False;
  if Node = nil then
    Exit;
  if (Node.Level = 0) and (TObject(Node.Data) is TVFLineStyle) then
    AllowEdit := True
  else if (Node.Level = 1) and (TObject(Node.Data) is TVFLineLayer) then
    AllowEdit := True;
end;

procedure TfrmVFLineTypes.tvLineTypesEdited(Sender: TObject; Node: TTreeNode;
  var S: string);
var
  NewText: string;
  St: TVFLineStyle;
  Ly: TVFLineLayer;
  OldName: string;
  I: Integer;
begin
  if Node = nil then
    Exit;

  NewText := Trim(S);
  if NewText = '' then
  begin
    S := Node.Text;
    Exit;
  end;

  if (Node.Level = 0) and (TObject(Node.Data) is TVFLineStyle) then
  begin
    St := TVFLineStyle(Node.Data);
    if SameText(St.Name, NewText) then
      Exit;

    if HasStyleNameConflict(NewText, St) then
    begin
      OldName := St.Name;
      MessageDlg('Имя типа линии должно быть уникальным.' + LineEnding +
        'Имя "' + NewText + '" уже используется.', mtWarning, [mbOK], 0);
      S := OldName;
      Exit;
    end;

    St.Name := NewText;

    ResortLineTypes;

    for I := 0 to FLineTypes.Count - 1 do
      WriteLn(FLineTypes[I].Name);

    RebuildList;
    tvLineTypes.Selected := tvLineTypes.Items.FindNodeWithData(St);
    Exit;
  end;

  if (Node.Level = 1) and (TObject(Node.Data) is TVFLineLayer) then
  begin
    Ly := TVFLineLayer(Node.Data);
    if SameText(Ly.Name, NewText) then
      Exit;
    Ly.Name := NewText;
    if Ly = FCurrentLayer then
      edtLayerName.Text := Ly.Name;
    RebuildList;
    tvLineTypes.Selected := tvLineTypes.Items.FindNodeWithData(Ly);
    Exit;
  end;
end;

procedure TfrmVFLineTypes.SetActiveLayerInStyle(const Style: TVFLineStyle;
  const ActiveLayer: TVFLineLayer);
var
  I: Integer;
  L: TVFLineLayer;
begin
  if Style = nil then
    Exit;
  for I := 0 to Style.LayerCount - 1 do
  begin
    L := Style.Layer[I];
    if L <> nil then
      L.Active := (L = ActiveLayer);
  end;
end;

procedure TfrmVFLineTypes.tvLineTypesCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if (Node <> nil) and (Node.Level = 1) and (TObject(Node.Data) is TVFLineLayer) and
    TVFLineLayer(Node.Data).Active then
    Sender.Canvas.Font.Color := clRed;
  DefaultDraw := True;
end;

procedure TfrmVFLineTypes.UpdateParamsUI;
var
  Solid: TVFLineSolidLayer;
  Pattern: TVFLinePatternLayer;
  Custom: TVFLineCustomLayer;
begin
  if FCurrentLayer = nil then
  begin
    pcLayerParams.Enabled := False;
    btnApplyLayerParams.Enabled := False;
    Exit;
  end;

  pcLayerParams.Enabled := True;
  btnApplyLayerParams.Enabled := True;

  edtLayerName.Text := FCurrentLayer.Name;
  cbEnabled.Checked := FCurrentLayer.Enabled;
  edtColor.Text := IntToStr(FCurrentLayer.Color);
  edtBaseThickness.Text := FloatToStr(FCurrentLayer.BaseThickness);
  edtOffset.Text := FloatToStr(FCurrentLayer.Offset);
  edtTrimStart.Text := FloatToStr(FCurrentLayer.TrimStart);
  edtTrimEnd.Text := FloatToStr(FCurrentLayer.TrimEnd);

  tsSolid.TabVisible := FCurrentLayer is TVFLineSolidLayer;
  tsPattern.TabVisible := FCurrentLayer is TVFLinePatternLayer;
  tsCustom.TabVisible := FCurrentLayer is TVFLineCustomLayer;

  if FCurrentLayer is TVFLineSolidLayer then
  begin
    Solid := TVFLineSolidLayer(FCurrentLayer);
    cbCapKind.ItemIndex := Ord(Solid.CapKind);
    cbJoinKind.ItemIndex := Ord(Solid.JoinKind);
  end;

  if FCurrentLayer is TVFLinePatternLayer then
  begin
    Pattern := TVFLinePatternLayer(FCurrentLayer);
    edtDashOffset.Text := FloatToStr(Pattern.DashOffset);
    if Pattern.DashPattern.Count > 0 then
      edtDash.Text := FloatToStr(Pattern.DashPattern[0])
    else
      edtDash.Text := '0';
    if Pattern.DashPattern.Count > 1 then
      edtGap.Text := FloatToStr(Pattern.DashPattern[1])
    else
      edtGap.Text := '0';
  end;

  if FCurrentLayer is TVFLineCustomLayer then
  begin
    Custom := TVFLineCustomLayer(FCurrentLayer);
    edtUserParams.Text := Custom.UserParams;
  end;

  pcLayerParams.ActivePage := tsCommon;
end;

procedure TfrmVFLineTypes.SaveParamsToLayer;
var
  V: Double;
  Solid: TVFLineSolidLayer;
  Pattern: TVFLinePatternLayer;
  Custom: TVFLineCustomLayer;
  C: Integer;
begin
  if FCurrentLayer = nil then
    Exit;

  FCurrentLayer.Name := edtLayerName.Text;
  FCurrentLayer.Enabled := cbEnabled.Checked;
  C := StrToIntDef(Trim(edtColor.Text), Integer(clNavy));
  FCurrentLayer.Color := TColor(C);

  if TryStrToFloat(edtBaseThickness.Text, V) then
    FCurrentLayer.BaseThickness := V;
  if TryStrToFloat(edtOffset.Text, V) then
    FCurrentLayer.Offset := V;
  if TryStrToFloat(edtTrimStart.Text, V) then
    FCurrentLayer.SetTrimRange(V, FCurrentLayer.TrimEnd);
  if TryStrToFloat(edtTrimEnd.Text, V) then
    FCurrentLayer.SetTrimRange(FCurrentLayer.TrimStart, V);

  if FCurrentLayer is TVFLineSolidLayer then
  begin
    Solid := TVFLineSolidLayer(FCurrentLayer);
    if cbCapKind.ItemIndex >= 0 then
      Solid.CapKind := TVFLineCapKind(cbCapKind.ItemIndex);
    if cbJoinKind.ItemIndex >= 0 then
      Solid.JoinKind := TVFLineJoinKind(cbJoinKind.ItemIndex);
  end;

  if FCurrentLayer is TVFLinePatternLayer then
  begin
    Pattern := TVFLinePatternLayer(FCurrentLayer);
    if TryStrToFloat(edtDashOffset.Text, V) then
      Pattern.DashOffset := V;
    Pattern.DashPattern.Clear;
    if TryStrToFloat(edtDash.Text, V) then
      Pattern.DashPattern.AddSegment(Abs(V));
    if TryStrToFloat(edtGap.Text, V) then
      Pattern.DashPattern.AddSegment(Abs(V));
  end;

  if FCurrentLayer is TVFLineCustomLayer then
  begin
    Custom := TVFLineCustomLayer(FCurrentLayer);
    Custom.UserParams := edtUserParams.Text;
  end;
end;

procedure TfrmVFLineTypes.btnApplyLayerParamsClick(Sender: TObject);
var
  S: TVFLineStyle;
  L: TVFLineLayer;
begin
  S := GetSelectedStyle;
  L := GetSelectedLayer;
  if S <> nil then
    SetCurrentLineType(S);
  if L <> nil then
    SetCurrentLayer(L);

  SaveParamsToLayer;
  ApplyNodeNameFromTree;
 // RebuildList;
  pbPreview.Invalidate;
end;

procedure TfrmVFLineTypes.ApplyNodeNameFromTree;
var
  Node: TTreeNode;
  S: TVFLineStyle;
  L: TVFLineLayer;
  NewName: string;
  I: Integer;
begin
  if not Assigned(tvLineTypes) then
    Exit;
  Node := tvLineTypes.Selected;
  if Node = nil then
    Exit;

  NewName := Trim(Node.Text);
  if NewName = '' then
    Exit;

  if (Node.Level = 0) and (TObject(Node.Data) is TVFLineStyle) then
  begin
    S := TVFLineStyle(Node.Data);
    if SameText(S.Name, NewName) then
      Exit;

    if HasStyleNameConflict(NewName, S) then
    begin
      MessageDlg('Имя типа линии должно быть уникальным.' + LineEnding +
        'Имя "' + NewName + '" уже используется.', mtWarning, [mbOK], 0);
      Node.Text := S.Name;
      Exit;
    end;

    S.Name := NewName;

    ResortLineTypes;

    for I := 0 to FLineTypes.Count - 1 do
      WriteLn(FLineTypes[I].Name);

    RebuildList;
    tvLineTypes.Selected := tvLineTypes.Items.FindNodeWithData(S);
    Exit;
  end;

  if (Node.Level = 1) and (TObject(Node.Data) is TVFLineLayer) then
  begin
    L := TVFLineLayer(Node.Data);
    if SameText(L.Name, NewName) then
      Exit;
    L.Name := NewName;
    if L = FCurrentLayer then
      edtLayerName.Text := L.Name;
    RebuildList;
    tvLineTypes.Selected := tvLineTypes.Items.FindNodeWithData(L);
    Exit;
  end;
end;

function TfrmVFLineTypes.CreateUniqueStyleName(const BaseName: string): string;
var
  I, N: Integer;
  Candidate: string;
  S: TVFLineStyle;
  Exists: Boolean;
begin
  N := 1;
  repeat
    if N = 1 then
      Candidate := BaseName
    else
      Candidate := BaseName + ' ' + IntToStr(N);

    Exists := False;
    for I := 0 to FLineTypes.Count - 1 do
    begin
      S := FLineTypes[I];
      if SameText(S.Name, Candidate) then
      begin
        Exists := True;
        Break;
      end;
    end;
    Inc(N);
  until not Exists;
  Result := Candidate;
end;

procedure TfrmVFLineTypes.EnsureDefaultSolidLayer(const Style: TVFLineStyle);
var
  L: TVFLineSolidLayer;
begin
  if (Style = nil) or (Style.LayerCount > 0) then
    Exit;
  L := Style.AddSolidLayer;
  L.Color := clNavy;
  L.BaseThickness := 14;
  L.CapKind := lckButt;
  L.JoinKind := ljkBevel;
end;

procedure TfrmVFLineTypes.btnAddLineTypeClick(Sender: TObject);
var
  S: TVFLineStyle;
  StyleNode: TTreeNode;
  I: Integer;
begin
  S := FLineTypes.AddStyle;
  S.Name := CreateUniqueStyleName('LineType');

  ResortLineTypes;

  for I := 0 to FLineTypes.Count - 1 do
    WriteLn(FLineTypes[I].Name);

  RebuildList;
  StyleNode := tvLineTypes.Items.FindNodeWithData(S);
  if StyleNode <> nil then
    tvLineTypes.Selected := StyleNode;
end;

procedure TfrmVFLineTypes.DeleteSelectedStyle;
var
  S: TVFLineStyle;
  Idx: Integer;
begin
  S := GetSelectedStyle;
  if S = nil then
    Exit;
  if MessageDlg('Удалить тип линии "' + GetLineTypeName(S) + '"?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Idx := FLineTypes.IndexOf(S);
  if Idx >= 0 then
    FLineTypes.AtFree(Idx);
  SetCurrentLineType(nil);
  RebuildList;
end;

procedure TfrmVFLineTypes.btnDeleteLineTypeClick(Sender: TObject);
begin
  DeleteSelectedStyle;
end;

procedure TfrmVFLineTypes.AddLayerToSelectedStyle(ALayerClass: TVFLineLayerClass);
var
  S: TVFLineStyle;
  L: TVFLineLayer;
  StyleNode: TTreeNode;
begin
  S := GetSelectedStyle;
  if S = nil then
    Exit;
  L := S.AddLayer(ALayerClass);
  L.Color := clNavy;
  L.BaseThickness := 14;
//  L.CapKind := lckButt;
//  L.JoinKind := ljkBevel;
  RebuildList;
  StyleNode := tvLineTypes.Items.FindNodeWithData(S);
  if StyleNode <> nil then
    tvLineTypes.Selected := StyleNode;
  pbPreview.Invalidate;
end;

procedure TfrmVFLineTypes.miAddSolidLayerClick(Sender: TObject);
begin
  AddLayerToSelectedStyle(TVFLineSolidLayer);
end;

procedure TfrmVFLineTypes.miAddPatternLayerClick(Sender: TObject);
var
  S: TVFLineStyle;
  L: TVFLinePatternLayer;
begin
  S := GetSelectedStyle;
  if S = nil then
    Exit;
  L := TVFLinePatternLayer(S.AddLayer(TVFLinePatternLayer));
  L.Color := clNavy;
  L.BaseThickness := 14;
  L.CapKind := lckButt;
  L.JoinKind := ljkMiter;
  L.DashOffset := 0;
  L.DashPattern.Clear;
  L.DashPattern.AddSegment(30);
  L.DashPattern.AddSegment(12);
  RebuildList;
  pbPreview.Invalidate;
end;

procedure TfrmVFLineTypes.miAddCustomLayerClick(Sender: TObject);
begin
  AddLayerToSelectedStyle(TVFLineCustomLayer);
end;

procedure TfrmVFLineTypes.BuildDemoPolyline(out Points: TVFLinePolygon);
var
  W, H: Integer;
begin
  W := pbPreview.ClientWidth;
  H := pbPreview.ClientHeight;
  SetLength(Points, 5);
  Points[0] := VFPointF(Max(10, W div 10),            Max(10, H div 2));
  Points[1] := VFPointF(Max(10, W div 3),             Max(10, H div 3));
  Points[2] := VFPointF(Max(10, (W * 5) div 10),       Max(10, (H * 6) div 10));
  Points[3] := VFPointF(Max(10, (W * 7) div 10),       Max(10, H div 4));
  Points[4] := VFPointF(Max(10, (W * 9) div 10),       Max(10, (H * 6) div 10));
end;

procedure TfrmVFLineTypes.pbPreviewPaint(Sender: TObject);
var
  Points: TVFLinePolygon;
  Polygons: TVFLinePolygonArray;
  Poly: TVFLinePolygon;
  Outline: array of TPoint;
  LayerIndex, PolyIndex, PtIndex: Integer;
  Layer: TVFLineLayer;
begin
  pbPreview.Canvas.Brush.Color := clWhite;
  pbPreview.Canvas.FillRect(pbPreview.ClientRect);

  if (FCurrentLineType = nil) or (FCurrentLineType.LayerCount = 0) then
    Exit;

  BuildDemoPolyline(Points);
  if Length(Points) < 2 then
    Exit;

  for LayerIndex := 0 to FCurrentLineType.LayerCount - 1 do
  begin
    Layer := FCurrentLineType.Layer[LayerIndex];
    if (Layer = nil) or (not Layer.Enabled) then
      Continue;

    if Layer is TVFLinePatternLayer then
    begin
      BuildDashedPolygons(TVFLinePatternLayer(Layer), Points, Polygons);
    end
    else if Layer is TVFLineSolidLayer then
    begin
      BuildSolidPolygons(TVFLineSolidLayer(Layer), Points, Polygons);
    end
    else
      Continue;

    pbPreview.Canvas.Brush.Style := bsSolid;
    pbPreview.Canvas.Pen.Style := psSolid;
    if Layer.Active then
    begin
      pbPreview.Canvas.Brush.Color := clRed;
      pbPreview.Canvas.Pen.Color := clRed;
    end
    else
    begin
      pbPreview.Canvas.Brush.Color := Layer.Color;
      pbPreview.Canvas.Pen.Color := Layer.Color;
    end;

    for PolyIndex := 0 to High(Polygons) do
    begin
      Poly := Polygons[PolyIndex];
      SetLength(Outline, Length(Poly));
      for PtIndex := 0 to High(Poly) do
      begin
        Outline[PtIndex].X := Round(Poly[PtIndex].X);
        Outline[PtIndex].Y := Round(Poly[PtIndex].Y);
      end;
      pbPreview.Canvas.Polygon(Outline);
    end;
  end;
end;

end.
