unit uDockContainers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Types, uBitHash;

const
  fmBtnSize  = 24;
  fmBorderIndent = 4;
  fmLeftIndent = 6;

type
  TFlyControlKind = (fckSpeedButton, fckPanel);

  TflyControl = class
  public
    Name: string;
    Caption: string;
    Hint: string;
    Control: TControl;
    Kind: TFlyControlKind;
    BitHashItem: TBitHashItem;
    GlyphData: AnsiString;
    GlyphHash: string;
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
    BtnWidth: Integer;
    BtnHeight: Integer;
    function PxWidth(fmBtnSize, fmLeftIndent, fmBorderIndent: Integer): Integer;
    function PxHeight(fmBtnSize, fmBorderIndent: Integer): Integer;
  end;

  TflySection = class
  private
    FflyControls: TFPList;
    FBtnWidth: Integer;
    FBtnHeight: Integer;
  public
    Name: string;
    Control: TWinControl;
    RowKey: Integer;
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
    constructor Create; virtual;
    destructor Destroy; override;
    function AddControl(AControl: TflyControl): Integer;
    procedure ClearControls(FreeItems: Boolean);
    function FindControlByName(const AName: string): TflyControl;
    function PxWidth(fmBtnSize, fmLeftIndent, fmBorderIndent: Integer): Integer;
    function PxHeight(fmBtnSize, fmBorderIndent: Integer): Integer;
    property BtnWidth: Integer read FBtnWidth write FBtnWidth;
    property BtnHeight: Integer read FBtnHeight write FBtnHeight;
    property flyControls: TFPList read FflyControls;
  end;

  { TDockContainerBase }

  TDockContainerBase = class
  private
    FHost: TWinControl;
    FCaptureName: string;
    FCaptureBtnWidth: Integer;
    FCaptureBtnHeight: Integer;
    FCaptureControl: TWinControl;
    FRefCount: Integer;
  public
    constructor Create(AHost: TWinControl); virtual;
    function GetCapture(MouseX, MouseY: Integer; var R: TRect): Boolean; virtual;
    procedure SetCaptureTool(const AName: string; ABtnWidth, ABtnHeight: Integer; AControl: TWinControl); virtual;
    procedure AddRef;
    procedure Release;
    procedure NotifyControlDestroyed(AControl: TWinControl); virtual;
    property Host: TWinControl read FHost;
    property CaptureName: string read FCaptureName;
    property CaptureBtnWidth: Integer read FCaptureBtnWidth;
    property CaptureBtnHeight: Integer read FCaptureBtnHeight;
    property CaptureControl: TWinControl read FCaptureControl;
  end;

  THContainer = class(TDockContainerBase)
  private
    FflySections: TFPList;
    function FindSectionByControl(AControl: TWinControl; out Index: Integer): TflySection;
    function SectionPxHeight(Sec: TflySection): Integer;
    function ToolPxWidth: Integer;
    function ToolPxHeight: Integer;
  public
    constructor Create(AHost: TWinControl); override;
    destructor Destroy; override;
    function AddSection(ASection: TflySection): Integer;
    procedure ClearSections(FreeItems: Boolean);
    function GetCapture(MouseX, MouseY: Integer; var R: TRect): Boolean; override;
    procedure RecalcSections;
    procedure RecalcSections(AIgnore: TWinControl);
    procedure ApplyDock(MouseX, MouseY: Integer);
    procedure NotifyControlDestroyed(AControl: TWinControl); override;
    function GetDockedRectByName(const AName: string; out R: TRect): Boolean;
    property flySections: TFPList read FflySections;
  end;

  TVContainer = class(TDockContainerBase)
  private
    FflySections: TFPList;
    function FindSectionByControl(AControl: TWinControl; out Index: Integer): TflySection;
    function SectionPxWidth(Sec: TflySection): Integer;
    function ToolPxWidth: Integer;
    function ToolPxHeight: Integer;
  public
    constructor Create(AHost: TWinControl); override;
    destructor Destroy; override;
    function AddSection(ASection: TflySection): Integer;
    procedure ClearSections(FreeItems: Boolean);
    function GetCapture(MouseX, MouseY: Integer; var R: TRect): Boolean; override;
    procedure RecalcSections;
    procedure RecalcSections(AIgnore: TWinControl);
    procedure ApplyDock(MouseX, MouseY: Integer);
    procedure NotifyControlDestroyed(AControl: TWinControl); override;
    function GetDockedRectByName(const AName: string; out R: TRect): Boolean;
    property flySections: TFPList read FflySections;
  end;

function AcquireDockContainer(AHost: TWinControl): TDockContainerBase;

implementation uses ogcWriter;

var
  GSharedContainers: TFPList;

function MaxI(A, B: Integer): Integer; inline;
begin
  if A > B then Result := A else Result := B;
end;

{ TflyControl }

function TflyControl.PxWidth(fmBtnSize, fmLeftIndent, fmBorderIndent: Integer): Integer;
begin
  Result := fmLeftIndent + fmBtnSize * BtnWidth + fmBorderIndent;
end;

function TflyControl.PxHeight(fmBtnSize, fmBorderIndent: Integer): Integer;
begin
  Result := fmBtnSize * BtnHeight + fmBorderIndent * 2;
end;

{ TflySection }

constructor TflySection.Create;
begin
  inherited Create;
  FflyControls := TFPList.Create;
  Control := nil;
  RowKey := 0;
end;

destructor TflySection.Destroy;
begin
  ClearControls(True);
  FreeAndNil(FflyControls);
  inherited Destroy;
end;

function TflySection.AddControl(AControl: TflyControl): Integer;
begin
  if FflyControls = nil then
    FflyControls := TFPList.Create;
  Result := FflyControls.Add(AControl);
end;

procedure TflySection.ClearControls(FreeItems: Boolean);
var
  I: Integer;
begin
  if FflyControls = nil then Exit;
  if FreeItems then
    for I := 0 to FflyControls.Count - 1 do
      TObject(FflyControls[I]).Free;
  FflyControls.Clear;
end;

function TflySection.FindControlByName(const AName: string): TflyControl;
var
  I: Integer;
  C: TflyControl;
begin
  Result := nil;
  if (FflyControls = nil) or (AName = '') then Exit;
  for I := 0 to FflyControls.Count - 1 do begin
    C := TflyControl(FflyControls[I]);
    if (C <> nil) and SameText(C.Name, AName) then
      Exit(C);
  end;
end;

function TflySection.PxWidth(fmBtnSize, fmLeftIndent, fmBorderIndent: Integer): Integer;
begin
  Result := fmLeftIndent + fmBtnSize * FBtnWidth + fmBorderIndent;
end;

function TflySection.PxHeight(fmBtnSize, fmBorderIndent: Integer): Integer;
begin
  Result := fmBtnSize * FBtnHeight + fmBorderIndent * 2;
end;

constructor TDockContainerBase.Create(AHost: TWinControl);
begin
  inherited Create;
  FHost := AHost;
  FCaptureBtnWidth := 0;
  FCaptureBtnHeight := 0;
  FCaptureControl := nil;
  FRefCount := 0;
end;

procedure TDockContainerBase.SetCaptureTool(const AName: string; ABtnWidth,
  ABtnHeight: Integer; AControl: TWinControl);
begin
  FCaptureName := AName;
  FCaptureBtnWidth := ABtnWidth;
  FCaptureBtnHeight := ABtnHeight;
  FCaptureControl := AControl;
end;

procedure TDockContainerBase.AddRef;
begin
  Inc(FRefCount);
end;

procedure TDockContainerBase.Release;
var
  I: Integer;
begin
  Dec(FRefCount);
  if FRefCount > 0 then Exit;

  if GSharedContainers <> nil then begin
    I := GSharedContainers.IndexOf(Self);
    if I >= 0 then
      GSharedContainers.Delete(I);
  end;
  Free;
end;

procedure TDockContainerBase.NotifyControlDestroyed(AControl: TWinControl);
begin
  AControl := AControl;
end;

function AcquireDockContainer(AHost: TWinControl): TDockContainerBase;
var
  I: Integer;
  C: TDockContainerBase;
begin
  Result := nil;
  if AHost = nil then Exit;

  if GSharedContainers = nil then
    GSharedContainers := TFPList.Create;

  for I := 0 to GSharedContainers.Count - 1 do begin
    C := TDockContainerBase(GSharedContainers[I]);
    if (C <> nil) and (C.Host = AHost) then begin
      C.AddRef;
      Exit(C);
    end;
  end;

  if (AHost.Align = alTop) or (AHost.Align = alBottom) then
    Result := THContainer.Create(AHost)
  else
    Result := TVContainer.Create(AHost);

  Result.AddRef;
  GSharedContainers.Add(Result);
end;

function TDockContainerBase.GetCapture(MouseX, MouseY: Integer; var R: TRect
 ): Boolean;
const
  CAPTURE_DIST = 16;
var
  P0: TPoint;
  RH, RNear: TRect;
  W0, H0: Integer;
  IsZeroSized: Boolean;
begin
  Result := False;
  R := Rect(0, 0, 0, 0);
  if FHost = nil then Exit;

  P0 := FHost.ClientToScreen(Point(0, 0));
  RH := Rect(P0.X, P0.Y, P0.X + FHost.Width, P0.Y + FHost.Height);

  W0 := RH.Right - RH.Left;
  H0 := RH.Bottom - RH.Top;
  IsZeroSized := FHost.AutoSize and ((W0 = 0) or (H0 = 0));

  if not IsZeroSized then begin
    Result := (MouseX >= RH.Left) and (MouseX < RH.Right) and
              (MouseY >= RH.Top) and (MouseY < RH.Bottom);
    if Result then
      R := RH;
    Exit;
  end;

  RNear := RH;
  if W0 = 0 then begin
    RNear.Left := RH.Left - CAPTURE_DIST;
    RNear.Right := RH.Right + CAPTURE_DIST;
  end;
  if H0 = 0 then begin
    RNear.Top := RH.Top - CAPTURE_DIST;
    RNear.Bottom := RH.Bottom + CAPTURE_DIST;
  end;

  Result := (MouseX >= RNear.Left) and (MouseX < RNear.Right) and
            (MouseY >= RNear.Top) and (MouseY < RNear.Bottom);
  if not Result then Exit;

  R := RH;
  if W0 = 0 then begin
    R.Left := RH.Left;
    R.Right := RH.Left + 1;
  end;
  if H0 = 0 then begin
    R.Top := RH.Top;
    R.Bottom := RH.Top + 1;
  end;
end;

{ THContainer }

constructor THContainer.Create(AHost: TWinControl);
begin
  inherited Create(AHost);
  FflySections := TFPList.Create;
end;

destructor THContainer.Destroy;
begin
  ClearSections(True);
  FreeAndNil(FflySections);
  inherited Destroy;
end;

function THContainer.SectionPxHeight(Sec: TflySection): Integer;
begin
  if Sec = nil then Exit(0);
  Result := Sec.PxHeight(fmBtnSize, fmBorderIndent);
end;

function THContainer.FindSectionByControl(AControl: TWinControl; out Index: Integer): TflySection;
var
  I: Integer;
  Sec: TflySection;
begin
  Result := nil;
  Index := -1;
  if (AControl = nil) or (FflySections = nil) then Exit;
  for I := 0 to FflySections.Count - 1 do begin
    Sec := TflySection(FflySections[I]);
    if (Sec <> nil) and (Sec.Control = AControl) then begin
      Index := I;
      Exit(Sec);
    end;
  end;
end;

function THContainer.ToolPxWidth: Integer;
begin
  Result := fmLeftIndent + fmBtnSize * MaxI(1, CaptureBtnWidth) + fmBorderIndent;
end;

function THContainer.ToolPxHeight: Integer;
begin
  Result := fmBtnSize * MaxI(1, CaptureBtnHeight) + fmBorderIndent * 2;
end;

function THContainer.AddSection(ASection: TflySection): Integer;
begin
  if FflySections = nil then
    FflySections := TFPList.Create;
  Result := FflySections.Add(ASection);
end;

procedure THContainer.ClearSections(FreeItems: Boolean);
var
  I: Integer;
begin
  if FflySections = nil then Exit;
  if FreeItems then
    for I := 0 to FflySections.Count - 1 do
      TObject(FflySections[I]).Free;
  FflySections.Clear;
end;

procedure THContainer.RecalcSections;
begin
  RecalcSections(nil);
end;

procedure THContainer.RecalcSections(AIgnore: TWinControl);
var
  S: Integer;
  Sec: TflySection;
  RowH: Integer;
  SecW, SecH: Integer;
  RowCount: Integer;
  I, J: Integer;
  Keys: array of Integer;
  Key: Integer;
  YPos: Integer;
  XPos: Integer;
  Found: Boolean;
begin
  if FflySections = nil then Exit;
  if Host = nil then Exit;

  RowCount := 0;
  SetLength(Keys, 0);
  for S := 0 to FflySections.Count - 1 do begin
    Sec := TflySection(FflySections[S]);
    if Sec = nil then Continue;
    if (AIgnore <> nil) and (Sec.Control = AIgnore) then Continue;
    Key := Sec.RowKey;
    Found := False;
    for I := 0 to RowCount - 1 do
      if Keys[I] = Key then begin
        Found := True;
        Break;
      end;
    if not Found then begin
      SetLength(Keys, RowCount + 1);
      Keys[RowCount] := Key;
      Inc(RowCount);
    end;
  end;

  for I := 0 to RowCount - 2 do
    for J := I + 1 to RowCount - 1 do
      if Keys[J] < Keys[I] then begin
        Key := Keys[I];
        Keys[I] := Keys[J];
        Keys[J] := Key;
      end;

  YPos := 0;
  for I := 0 to RowCount - 1 do begin
    Key := Keys[I];
    RowH := 0;
    XPos := 0;

    for S := 0 to FflySections.Count - 1 do begin
      Sec := TflySection(FflySections[S]);
      if Sec = nil then Continue;
      if (AIgnore <> nil) and (Sec.Control = AIgnore) then Continue;
      if Sec.RowKey <> Key then Continue;
      SecH := Sec.PxHeight(fmBtnSize, fmBorderIndent);
      if SecH > RowH then
        RowH := SecH;
    end;
    if RowH < 1 then
      RowH := ToolPxHeight;

    for S := 0 to FflySections.Count - 1 do begin
      Sec := TflySection(FflySections[S]);
      if Sec = nil then Continue;
      if (AIgnore <> nil) and (Sec.Control = AIgnore) then Continue;
      if Sec.RowKey <> Key then Continue;

      SecW := Sec.PxWidth(fmBtnSize, fmLeftIndent, fmBorderIndent);
      SecH := Sec.PxHeight(fmBtnSize, fmBorderIndent);

      Sec.X := XPos;
      Sec.Y := YPos;
      Sec.Width := SecW;
      Sec.Height := SecH;
      Sec.RowKey := Sec.Y;

      Inc(XPos, SecW);
    end;

    Inc(YPos, RowH);
  end;
end;

function THContainer.GetCapture(MouseX, MouseY: Integer; var R: TRect): Boolean;
var
  HostR: TRect;
  P0: TPoint;
  RowTop: Integer;
  RowH: Integer;
  ToolW, ToolH: Integer;
  InsertX: Integer;
  S: Integer;
  Sec: TflySection;
  IsRowFound: Boolean;
begin
  Result := inherited GetCapture(MouseX, MouseY, HostR);
  if not Result then begin
    R := Rect(0, 0, 0, 0);
    Exit;
  end;
  if (Host = nil) or (FflySections = nil) then begin
    R := Rect(0, 0, 0, 0);
    Exit;
  end;

  ToolW := ToolPxWidth;
  ToolH := ToolPxHeight;

  if FflySections.Count > 0 then
    RecalcSections(CaptureControl);

  if FflySections.Count = 0 then begin
    P0 := Host.ClientToScreen(Point(0, 0));
    R := Rect(P0.X, P0.Y, P0.X + ToolW, P0.Y + ToolH);
    Exit(True);
  end;

  P0 := Host.ClientToScreen(Point(0, 0));

  IsRowFound := False;
  RowTop := 0;
  RowH := ToolH;
  for S := 0 to FflySections.Count - 1 do begin
    Sec := TflySection(FflySections[S]);
    if (Sec = nil) then Continue;
    if (CaptureControl <> nil) and (Sec.Control = CaptureControl) then Continue;
    if (MouseY >= P0.Y + Sec.Y) and (MouseY < P0.Y + Sec.Y + Sec.Height) then begin
      RowTop := Sec.Y;
      RowH := Sec.Height;
      IsRowFound := True;
      Break;
    end;
  end;

  if not IsRowFound then begin
    RowTop := 0;
    RowH := ToolH;
    for S := 0 to FflySections.Count - 1 do begin
      Sec := TflySection(FflySections[S]);
      if (Sec = nil) then Continue;
      if (CaptureControl <> nil) and (Sec.Control = CaptureControl) then Continue;
      if (Sec.Y + Sec.Height > RowTop) then begin
        RowTop := Sec.Y + Sec.Height;
        RowH := ToolH;
      end;
    end;
  end;

  if (MouseY - (P0.Y + RowTop)) > (RowH div 2) then begin
    RowTop := RowTop + RowH;
    RowH := ToolH;
    InsertX := 0;
    R := Rect(P0.X + InsertX, P0.Y + RowTop, P0.X + InsertX + ToolW, P0.Y + RowTop + RowH);
    Exit(True);
  end;

  InsertX := 0;
  IsRowFound := False;
  for S := 0 to FflySections.Count - 1 do begin
    Sec := TflySection(FflySections[S]);
    if (Sec = nil) then Continue;
    if (CaptureControl <> nil) and (Sec.Control = CaptureControl) then Continue;
    if Sec.Y <> RowTop then Continue;
    IsRowFound := True;
    if MouseX < (P0.X + Sec.X + Sec.Width div 2) then begin
      InsertX := Sec.X;
      Break;
    end;
    InsertX := Sec.X + Sec.Width;
  end;

  if not IsRowFound then
    InsertX := 0;

  R := Rect(P0.X + InsertX, P0.Y + RowTop, P0.X + InsertX + ToolW, P0.Y + RowTop + RowH);
end;

procedure THContainer.ApplyDock(MouseX, MouseY: Integer);
var
  P0: TPoint;
  Sec: TflySection;
  OldIndex: Integer;
  InsertIndex: Integer;
  ToolW, ToolH: Integer;
  R: TRect;
  S: Integer;
  TargetKey: Integer;
begin
  if FflySections = nil then
    FflySections := TFPList.Create;

  if Host = nil then Exit;

  ToolW := ToolPxWidth;
  ToolH := ToolPxHeight;

  Sec := FindSectionByControl(CaptureControl, OldIndex);
  if Sec <> nil then begin
    FflySections.Delete(OldIndex);
  end else begin
    Sec := TflySection.Create;
    Sec.Control := CaptureControl;
    Sec.Name := CaptureName;
  end;

  Sec.BtnWidth := MaxI(1, CaptureBtnWidth);
  Sec.BtnHeight := MaxI(1, CaptureBtnHeight);
  Sec.Width := fmLeftIndent + fmBtnSize * Sec.BtnWidth + fmBorderIndent;
  Sec.Height := fmBtnSize * Sec.BtnHeight + fmBorderIndent * 2;

  if FflySections.Count > 0 then
    RecalcSections(nil);

  P0 := Host.ClientToScreen(Point(0, 0));
  InsertIndex := FflySections.Count;
  R := Rect(P0.X, P0.Y, P0.X + ToolW, P0.Y + ToolH);
  GetCapture(MouseX, MouseY, R);

  TargetKey := R.Top - P0.Y;
  Sec.RowKey := TargetKey;

  for S := 0 to FflySections.Count - 1 do begin
    if TflySection(FflySections[S]) = nil then Continue;
    if TargetKey < TflySection(FflySections[S]).RowKey then begin
      InsertIndex := S;
      Break;
    end;
    if (TargetKey = TflySection(FflySections[S]).RowKey) and
       (R.Left - P0.X < TflySection(FflySections[S]).X) then begin
      InsertIndex := S;
      Break;
    end;
  end;

  if InsertIndex >= FflySections.Count then
    FflySections.Add(Sec)
  else
    FflySections.Insert(InsertIndex, Sec);

  RecalcSections(nil);

  if Sec.Control <> nil then
    Sec.Control.BringToFront;

  MouseX := MouseX;
  MouseY := MouseY;
end;

procedure THContainer.NotifyControlDestroyed(AControl: TWinControl);
var
  S: Integer;
  Sec: TflySection;
begin
  inherited NotifyControlDestroyed(AControl);
  if (AControl = nil) or (FflySections = nil) then Exit;

  S := 0;
  while S < FflySections.Count do begin
    Sec := TflySection(FflySections[S]);
    if (Sec <> nil) and (Sec.Control = AControl) then begin
      FflySections.Delete(S);
      Sec.Free;
      Continue;
    end;
    Inc(S);
  end;

  RecalcSections;
end;

function THContainer.GetDockedRectByName(const AName: string; out R: TRect): Boolean;
var
  S: Integer;
  Sec: TflySection;
begin
  Result := False;
  R := Rect(0, 0, 0, 0);
  if (FflySections = nil) or (AName = '') then Exit;

  for S := 0 to FflySections.Count - 1 do begin
    Sec := TflySection(FflySections[S]);
    if Sec = nil then Continue;
    if SameText(Sec.Name, AName) or ((Sec.Control <> nil) and SameText(Sec.Control.Name, AName)) then begin
      R := Rect(Sec.X, Sec.Y, Sec.X + Sec.Width, Sec.Y + Sec.Height);
      Exit(True);
    end;
  end;
end;

{ TVContainer }

constructor TVContainer.Create(AHost: TWinControl);
begin
 inherited Create(AHost);
 FflySections := TFPList.Create;
end;

destructor TVContainer.Destroy;
begin
 ClearSections(True);
 FreeAndNil(FflySections);
 inherited Destroy;
end;

function TVContainer.FindSectionByControl(AControl: TWinControl; out Index: Integer): TflySection;
var
 I: Integer;
 Sec: TflySection;
begin
 Result := nil;
 Index := -1;
 if (AControl = nil) or (FflySections = nil) then Exit;
 for I := 0 to FflySections.Count - 1 do begin
  Sec := TflySection(FflySections[I]);
  if (Sec <> nil) and (Sec.Control = AControl) then begin
   Index := I;
   Exit(Sec);
  end;
 end;
end;

function TVContainer.SectionPxWidth(Sec: TflySection): Integer;
begin
 if Sec = nil then Exit(0);
 Result := Sec.PxWidth(fmBtnSize, fmLeftIndent, fmBorderIndent);
end;

function TVContainer.ToolPxWidth: Integer;
begin
 Result := fmLeftIndent + fmBtnSize * MaxI(1, CaptureBtnWidth) + fmBorderIndent;
end;

function TVContainer.ToolPxHeight: Integer;
begin
 Result := fmBtnSize * MaxI(1, CaptureBtnHeight) + fmBorderIndent * 2;
end;

function TVContainer.AddSection(ASection: TflySection): Integer;
begin
 if FflySections = nil then
  FflySections := TFPList.Create;
 Result := FflySections.Add(ASection);
end;

procedure TVContainer.ClearSections(FreeItems: Boolean);
var
 I: Integer;
begin
 if FflySections = nil then Exit;
 if FreeItems then
  for I := 0 to FflySections.Count - 1 do
   TObject(FflySections[I]).Free;
 FflySections.Clear;
end;

procedure TVContainer.RecalcSections;
begin
 RecalcSections(nil);
end;

procedure TVContainer.RecalcSections(AIgnore: TWinControl);
var
 S: Integer;
 Sec: TflySection;
 ColW: Integer;
 SecW, SecH: Integer;
 ColCount: Integer;
 I, J: Integer;
 Keys: array of Integer;
 Key: Integer;
 XPos: Integer;
 YPos: Integer;
 Found: Boolean;
begin
 if FflySections = nil then Exit;
 if Host = nil then Exit;

 ColCount := 0;
 SetLength(Keys, 0);
 for S := 0 to FflySections.Count - 1 do begin
  Sec := TflySection(FflySections[S]);
  if Sec = nil then Continue;
  if (AIgnore <> nil) and (Sec.Control = AIgnore) then Continue;
  Key := Sec.RowKey;
  Found := False;
  for I := 0 to ColCount - 1 do
   if Keys[I] = Key then begin
    Found := True;
    Break;
   end;
  if not Found then begin
   SetLength(Keys, ColCount + 1);
   Keys[ColCount] := Key;
   Inc(ColCount);
  end;
 end;

 for I := 0 to ColCount - 2 do
  for J := I + 1 to ColCount - 1 do
   if Keys[J] < Keys[I] then begin
    Key := Keys[I];
    Keys[I] := Keys[J];
    Keys[J] := Key;
   end;

 XPos := 0;
 for I := 0 to ColCount - 1 do begin
  Key := Keys[I];
  ColW := 0;
  YPos := 0;

  for S := 0 to FflySections.Count - 1 do begin
   Sec := TflySection(FflySections[S]);
   if Sec = nil then Continue;
   if (AIgnore <> nil) and (Sec.Control = AIgnore) then Continue;
   if Sec.RowKey <> Key then Continue;
   SecW := SectionPxWidth(Sec);
   if SecW > ColW then
    ColW := SecW;
  end;
  if ColW < 1 then
   ColW := ToolPxWidth;

  for S := 0 to FflySections.Count - 1 do begin
   Sec := TflySection(FflySections[S]);
   if Sec = nil then Continue;
   if (AIgnore <> nil) and (Sec.Control = AIgnore) then Continue;
   if Sec.RowKey <> Key then Continue;

   SecW := Sec.PxWidth(fmBtnSize, fmLeftIndent, fmBorderIndent);
   SecH := Sec.PxHeight(fmBtnSize, fmBorderIndent);

   Sec.X := XPos;
   Sec.Y := YPos;
   Sec.Width := SecW;
   Sec.Height := SecH;
   Sec.RowKey := Sec.X;

   Inc(YPos, SecH);
  end;

  Inc(XPos, ColW);
 end;
end;

function TVContainer.GetCapture(MouseX, MouseY: Integer; var R: TRect): Boolean;
var
 HostR: TRect;
 P0: TPoint;
 ColLeft: Integer;
 ColW: Integer;
 ToolW, ToolH: Integer;
 InsertY: Integer;
 S: Integer;
 Sec: TflySection;
 IsColFound: Boolean;
begin
 Result := inherited GetCapture(MouseX, MouseY, HostR);
 if not Result then begin
  R := Rect(0, 0, 0, 0);
  Exit;
 end;
 if (Host = nil) or (FflySections = nil) then begin
  R := Rect(0, 0, 0, 0);
  Exit;
 end;

 ToolW := ToolPxWidth;
 ToolH := ToolPxHeight;

 if FflySections.Count > 0 then
  RecalcSections(CaptureControl);

 if FflySections.Count = 0 then begin
  P0 := Host.ClientToScreen(Point(0, 0));
  R := Rect(P0.X, P0.Y, P0.X + ToolW, P0.Y + ToolH);
  Exit(True);
 end;

 P0 := Host.ClientToScreen(Point(0, 0));

 IsColFound := False;
 ColLeft := 0;
 ColW := ToolW;
 for S := 0 to FflySections.Count - 1 do begin
  Sec := TflySection(FflySections[S]);
  if (Sec = nil) then Continue;
  if (CaptureControl <> nil) and (Sec.Control = CaptureControl) then Continue;
  if (MouseX >= P0.X + Sec.X) and (MouseX < P0.X + Sec.X + Sec.Width) then begin
   ColLeft := Sec.X;
   ColW := Sec.Width;
   IsColFound := True;
   Break;
  end;
 end;

 if not IsColFound then begin
  ColLeft := 0;
  ColW := ToolW;
  for S := 0 to FflySections.Count - 1 do begin
   Sec := TflySection(FflySections[S]);
   if (Sec = nil) then Continue;
   if (CaptureControl <> nil) and (Sec.Control = CaptureControl) then Continue;
   if (Sec.X + Sec.Width > ColLeft) then begin
    ColLeft := Sec.X + Sec.Width;
    ColW := ToolW;
   end;
  end;
 end;

 if (MouseX - (P0.X + ColLeft)) > (ColW div 2) then begin
  ColLeft := ColLeft + ColW;
  ColW := ToolW;
  InsertY := 0;
  R := Rect(P0.X + ColLeft, P0.Y + InsertY, P0.X + ColLeft + ColW, P0.Y + InsertY + ToolH);
  Exit(True);
 end;

 InsertY := 0;
 IsColFound := False;
 for S := 0 to FflySections.Count - 1 do begin
  Sec := TflySection(FflySections[S]);
  if (Sec = nil) then Continue;
  if (CaptureControl <> nil) and (Sec.Control = CaptureControl) then Continue;
  if Sec.X <> ColLeft then Continue;
  IsColFound := True;
  if MouseY < (P0.Y + Sec.Y + Sec.Height div 2) then begin
   InsertY := Sec.Y;
   Break;
  end;
  InsertY := Sec.Y + Sec.Height;
 end;

 if not IsColFound then
  InsertY := 0;

 R := Rect(P0.X + ColLeft, P0.Y + InsertY, P0.X + ColLeft + ColW, P0.Y + InsertY + ToolH);
end;

procedure TVContainer.ApplyDock(MouseX, MouseY: Integer);
var
 P0: TPoint;
 Sec: TflySection;
 OldIndex: Integer;
 InsertIndex: Integer;
 ToolW, ToolH: Integer;
 R: TRect;
 S: Integer;
 TargetKey: Integer;
begin
 if FflySections = nil then
  FflySections := TFPList.Create;
 if Host = nil then Exit;

 ToolW := ToolPxWidth;
 ToolH := ToolPxHeight;

 Sec := FindSectionByControl(CaptureControl, OldIndex);
 if Sec <> nil then
  FflySections.Delete(OldIndex)
 else begin
  Sec := TflySection.Create;
  Sec.Control := CaptureControl;
  Sec.Name := CaptureName;
 end;

 Sec.BtnWidth := MaxI(1, CaptureBtnWidth);
 Sec.BtnHeight := MaxI(1, CaptureBtnHeight);
 Sec.Width := fmLeftIndent + fmBtnSize * Sec.BtnWidth + fmBorderIndent;
 Sec.Height := fmBtnSize * Sec.BtnHeight + fmBorderIndent * 2;

 if FflySections.Count > 0 then
  RecalcSections(nil);

 P0 := Host.ClientToScreen(Point(0, 0));
 InsertIndex := FflySections.Count;
 R := Rect(P0.X, P0.Y, P0.X + ToolW, P0.Y + ToolH);
 GetCapture(MouseX, MouseY, R);

 TargetKey := R.Left - P0.X;
 Sec.RowKey := TargetKey;

 for S := 0 to FflySections.Count - 1 do begin
  if TflySection(FflySections[S]) = nil then Continue;
  if TargetKey < TflySection(FflySections[S]).RowKey then begin
   InsertIndex := S;
   Break;
  end;
  if (TargetKey = TflySection(FflySections[S]).RowKey) and
     (R.Top - P0.Y < TflySection(FflySections[S]).Y) then begin
   InsertIndex := S;
   Break;
  end;
 end;

 if InsertIndex >= FflySections.Count then
  FflySections.Add(Sec)
 else
  FflySections.Insert(InsertIndex, Sec);

 RecalcSections(nil);
 if Sec.Control <> nil then
  Sec.Control.BringToFront;

 MouseX := MouseX;
 MouseY := MouseY;
end;

procedure TVContainer.NotifyControlDestroyed(AControl: TWinControl);
var
 S: Integer;
 Sec: TflySection;
begin
 inherited NotifyControlDestroyed(AControl);
 if (AControl = nil) or (FflySections = nil) then Exit;

 S := 0;
 while S < FflySections.Count do begin
  Sec := TflySection(FflySections[S]);
  if (Sec <> nil) and (Sec.Control = AControl) then begin
   FflySections.Delete(S);
   Sec.Free;
   Continue;
  end;
  Inc(S);
 end;

 RecalcSections;
end;

function TVContainer.GetDockedRectByName(const AName: string; out R: TRect): Boolean;
var
 S: Integer;
 Sec: TflySection;
begin
 Result := False;
 R := Rect(0, 0, 0, 0);
 if (FflySections = nil) or (AName = '') then Exit;

 for S := 0 to FflySections.Count - 1 do begin
  Sec := TflySection(FflySections[S]);
  if Sec = nil then Continue;
  if SameText(Sec.Name, AName) or ((Sec.Control <> nil) and SameText(Sec.Control.Name, AName)) then begin
   R := Rect(Sec.X, Sec.Y, Sec.X + Sec.Width, Sec.Y + Sec.Height);
   Exit(True);
  end;
 end;
end;

end.
