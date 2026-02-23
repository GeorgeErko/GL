unit uDockRepack2D;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Types;

type
  TRepackOrientation = (roRows, roCols);

  TRepackItem = record
    Control: TControl;
    SpanMain: Integer;
    SpanCross: Integer;
  end;

  PRepackItem = ^TRepackItem;

procedure RepackContainer2D(AHost: TWinControl; AItems: TFPList;
  ANewItem: PRepackItem; const ADockPointInHost: TPoint;
  AOrientation: TRepackOrientation; AMainUnitPx, ACrossUnitPx: Integer);

implementation

function MaxI(A, B: Integer): Integer; inline;
begin
  if A > B then Result := A else Result := B;
end;

function ControlRectInHost(AHost: TWinControl; C: TControl): TRect;
begin
  Result := Rect(C.Left, C.Top, C.Left + C.Width, C.Top + C.Height);
end;

function GetMainIndex(AOrientation: TRepackOrientation; const R: TRect; AMainUnitPx: Integer): Integer;
begin
  if AMainUnitPx <= 0 then Exit(0);
  if AOrientation = roRows then
    Result := R.Top div AMainUnitPx
  else
    Result := R.Left div AMainUnitPx;
end;

function CompareByLeft(Item1, Item2: Pointer): Integer;
var
  C1, C2: TControl;
begin
  C1 := TControl(Item1);
  C2 := TControl(Item2);
  Result := C1.Left - C2.Left;
end;

function CompareByTop(Item1, Item2: Pointer): Integer;
var
  C1, C2: TControl;
begin
  C1 := TControl(Item1);
  C2 := TControl(Item2);
  Result := C1.Top - C2.Top;
end;

procedure StableRowPack(AHost: TWinControl; AList: TFPList; AOrientation: TRepackOrientation);
var
  I: Integer;
  PrevEnd: Integer;
  C: TControl;
begin
  PrevEnd := 0;
  for I := 0 to AList.Count - 1 do begin
    C := TControl(AList[I]);
    if AOrientation = roRows then begin
      C.Left := MaxI(C.Left, PrevEnd);
      PrevEnd := C.Left + C.Width;
    end else begin
      C.Top := MaxI(C.Top, PrevEnd);
      PrevEnd := C.Top + C.Height;
    end;
  end;
end;

procedure CollectControlsOnMainIndex(AHost: TWinControl; AItems: TFPList; AOrientation: TRepackOrientation;
  AMainUnitPx, ACrossUnitPx, AMainIndex: Integer; OutList: TFPList);
var
  I: Integer;
  Item: PRepackItem;
  C: TControl;
  R: TRect;
  BaseIndex, Span: Integer;
begin
  ACrossUnitPx := ACrossUnitPx;
  OutList.Clear;
  for I := 0 to AItems.Count - 1 do begin
    Item := PRepackItem(AItems[I]);
    if Item = nil then Continue;
    C := Item^.Control;
    if (C = nil) or (C.Parent <> AHost) then Continue;
    R := ControlRectInHost(AHost, C);
    BaseIndex := GetMainIndex(AOrientation, R, AMainUnitPx);
    Span := MaxI(1, Item^.SpanMain);
    if (AMainIndex >= BaseIndex) and (AMainIndex <= BaseIndex + Span - 1) then
      OutList.Add(C);
  end;
end;

procedure ForceControlToMainIndex(AHost: TWinControl; AOrientation: TRepackOrientation;
  AMainUnitPx, AMainIndex: Integer; C: TControl);
begin
  if (C = nil) or (AMainUnitPx <= 0) then Exit;
  if AOrientation = roRows then
    C.Top := AMainIndex * AMainUnitPx
  else
    C.Left := AMainIndex * AMainUnitPx;
end;

procedure RepackContainer2D(AHost: TWinControl; AItems: TFPList;
  ANewItem: PRepackItem; const ADockPointInHost: TPoint;
  AOrientation: TRepackOrientation; AMainUnitPx, ACrossUnitPx: Integer);
var
  NewR: TRect;
  NewMainIndex: Integer;
  I, Pass, MaxPasses: Integer;
  Row: Integer;
  Work: TFPList;
  Changed: Boolean;
  BeforePos: array of Integer;
  C: TControl;
  ListMainStart, ListMainEnd: Integer;
  Item: PRepackItem;
  R: TRect;
  BaseIndex, Span, MaxEnd: Integer;
begin
  if (AHost = nil) or (AItems = nil) or (ANewItem = nil) then Exit;
  if ANewItem^.Control = nil then Exit;
  if AMainUnitPx <= 0 then Exit;
  ACrossUnitPx := ACrossUnitPx;

  if ANewItem^.SpanMain < 1 then ANewItem^.SpanMain := 1;
  if ANewItem^.SpanCross < 1 then ANewItem^.SpanCross := 1;

  if ANewItem^.Control.Parent <> AHost then
    ANewItem^.Control.Parent := AHost;

  NewR := ControlRectInHost(AHost, ANewItem^.Control);
  NewMainIndex := 0;
  if AOrientation = roRows then
    NewMainIndex := ADockPointInHost.Y div AMainUnitPx
  else
    NewMainIndex := ADockPointInHost.X div AMainUnitPx;

  ForceControlToMainIndex(AHost, AOrientation, AMainUnitPx, NewMainIndex, ANewItem^.Control);
  if AOrientation = roRows then
    ANewItem^.Control.Left := ADockPointInHost.X
  else
    ANewItem^.Control.Top := ADockPointInHost.Y;

  NewR := ControlRectInHost(AHost, ANewItem^.Control);

  Work := TFPList.Create;
  try
    MaxPasses := 128;
    ListMainStart := 0;
    MaxEnd := 0;
    for I := 0 to AItems.Count - 1 do begin
      Item := PRepackItem(AItems[I]);
      if (Item = nil) or (Item^.Control = nil) then Continue;
      if Item^.Control.Parent <> AHost then Continue;
      R := ControlRectInHost(AHost, Item^.Control);
      BaseIndex := GetMainIndex(AOrientation, R, AMainUnitPx);
      Span := MaxI(1, Item^.SpanMain);
      if BaseIndex + Span - 1 > MaxEnd then
        MaxEnd := BaseIndex + Span - 1;
    end;
    ListMainEnd := MaxEnd;

    for Pass := 0 to MaxPasses - 1 do begin
      Changed := False;

      for Row := ListMainStart to ListMainEnd do begin
        CollectControlsOnMainIndex(AHost, AItems, AOrientation, AMainUnitPx, ACrossUnitPx, Row, Work);
        if AOrientation = roRows then
          Work.Sort(@CompareByLeft)
        else
          Work.Sort(@CompareByTop);

        SetLength(BeforePos, Work.Count);
        for I := 0 to Work.Count - 1 do begin
          C := TControl(Work[I]);
          if AOrientation = roRows then
            BeforePos[I] := C.Left
          else
            BeforePos[I] := C.Top;
        end;

        StableRowPack(AHost, Work, AOrientation);

        for I := 0 to Work.Count - 1 do begin
          C := TControl(Work[I]);
          if AOrientation = roRows then begin
            if C.Left <> BeforePos[I] then Changed := True;
          end else begin
            if C.Top <> BeforePos[I] then Changed := True;
          end;
        end;
      end;

      if not Changed then Break;
    end;
  finally
    Work.Free;
  end;
end;

end.
