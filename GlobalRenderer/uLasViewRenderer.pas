unit uLasViewRenderer;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Math, Graphics, GR32,
 GR32_Blend,
 uLasMmapSource24, ogcDrawer32, ogcBasic;

type
 TLasRenderMode = (lrmHeight, lrmRGB, lrmDensity);

 TZFilterMode = (zfmSlice, zfmMinToLayer, zfmLayerToMax);

 TLasViewRenderer = class(TComponent)
 protected
  FSource: TLasMmapSource24;
  FMode: TLasRenderMode;
  FBaseX: Double;
  FBaseY: Double;
  FScale: Double;
  FFlipY: Boolean;
  FZBase: Double;
  FZStep: Double;
  FZLayerIndex: Integer;
  FZFilterMode: TZFilterMode;
  FBlendEnabled: Boolean;
  FBlendAlpha: Byte;
  FMaxPoints: Int64;
  procedure SetSource(const AValue: TLasMmapSource24);
 public
  constructor Create(AOwner: TComponent); override;
  procedure RenderToDrawer32(ADrawer: TogsDrawer32);
  property Source: TLasMmapSource24 read FSource write SetSource;
  property Mode: TLasRenderMode read FMode write FMode;
  property BaseX: Double read FBaseX write FBaseX;
  property BaseY: Double read FBaseY write FBaseY;
  property Scale: Double read FScale write FScale;
  property FlipY: Boolean read FFlipY write FFlipY;
  property ZBase: Double read FZBase write FZBase;
  property ZStep: Double read FZStep write FZStep;
  property ZLayerIndex: Integer read FZLayerIndex write FZLayerIndex;
  property ZFilterMode: TZFilterMode read FZFilterMode write FZFilterMode;
  property BlendEnabled: Boolean read FBlendEnabled write FBlendEnabled;
  property BlendAlpha: Byte read FBlendAlpha write FBlendAlpha;
  property MaxPoints: Int64 read FMaxPoints write FMaxPoints;
 end;

implementation

constructor TLasViewRenderer.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 FSource := nil;
 FMode := lrmHeight;
 FBaseX := 0;
 FBaseY := 0;
 FScale := 1;
 FFlipY := False;
 FZBase := 0;
 FZStep := 0;
 FZLayerIndex := 0;
 FZFilterMode := zfmSlice;
 FBlendEnabled := False;
 FBlendAlpha := 64;
 FMaxPoints := 0;
end;

procedure TLasViewRenderer.SetSource(const AValue: TLasMmapSource24);
begin
 if FSource = AValue then Exit;
 FSource := AValue;
end;

procedure TLasViewRenderer.RenderToDrawer32(ADrawer: TogsDrawer32);
var
 i: Int64;
 cnt: Int64;
 step: Int64;
 x, y, z: Double;
 r, g, b: Word;
 dx, dy: Double;
 z0, z1: Double;
 pixX, pixY: Integer;
 idx: Integer;
 w: Integer;
 bits: PColor32Array;
 col: Cardinal;
 dst: TColor32;
 act: TogsRect;
begin
 if (ADrawer = nil) or (ADrawer.Image = nil) then Exit;
 if (FSource = nil) or (not FSource.IsOpen) then Exit;
 if (ADrawer.ogsSelector = nil) then Exit;
 if (ADrawer.Image = nil) or (ADrawer.Image.Bitmap = nil) then Exit;

 if FScale = 0 then FScale := 1;

 act := ADrawer.ogsSelector.ActiveRect;
 if FZStep > 0 then
 begin
  case FZFilterMode of
   zfmMinToLayer:
    begin
     z0 := FZBase;
     z1 := FZBase + (Double(FZLayerIndex) + 1) * FZStep;
    end;
   zfmLayerToMax:
    begin
     z0 := FZBase + Double(FZLayerIndex) * FZStep;
     z1 := 1.0e300;
    end;
  else
    begin
     z0 := FZBase + Double(FZLayerIndex) * FZStep;
     z1 := z0 + FZStep;
    end;
  end;
 end
 else
 begin
  z0 := -1.0e300;
  z1 :=  1.0e300;
 end;

 cnt := FSource.PointCount;
 if cnt <= 0 then Exit;

 step := 1;
 if (FMaxPoints > 0) and (cnt > FMaxPoints) then
  step := Ceil(cnt / FMaxPoints);

 bits := ADrawer.Image.Bitmap.Bits;
 w := ADrawer.Image.Bitmap.Width;

 for i := 0 to cnt - 1 do
 begin
  if FMode = lrmRGB then
  begin
   if not FSource.GetPointXYZRGB(i, x, y, z, r, g, b) then
    Continue;
  end
  else
  begin
   if not FSource.GetPointXYZ(i, x, y, z) then
    Continue;
   r := 0;
   g := 0;
   b := 0;
  end;

  if (z < z0) or (z >= z1) then
   Continue;

  dx := FBaseX + (x - FSource.Header.MinX) * FScale;
  if FFlipY then
   dy := FBaseY + (FSource.Header.MaxY - y) * FScale
  else
   dy := FBaseY + (y - FSource.Header.MinY) * FScale;

  if act.isRect then
   if (dx < act.XMin) or (dx > act.XMax) or (dy < act.YMin) or (dy > act.YMax) then
    Continue;

  pixX := ADrawer.ogsSelector.XPix(dx);
  pixY := ADrawer.ogsSelector.YPix(dy);

  if (pixX < 0) or (pixX >= ADrawer.Width) or (pixY < 0) or (pixY >= ADrawer.Height) then
   Continue;

  idx := pixY * w + pixX;
  case FMode of
   lrmRGB:
    begin
     if (r >= $FF00) and (g >= $FF00) and (b >= $FF00) then
      col := Cardinal($FF000000)
     else
      col := Cardinal(b shr 8) or (Cardinal(g shr 8) shl 8) or (Cardinal(r shr 8) shl 16) or (Cardinal(255) shl 24);
     if FBlendEnabled then
     begin
      col := (col and $00FFFFFF) or (Cardinal(FBlendAlpha) shl 24);
      dst := bits^[idx];
      bits^[idx] := BlendReg(TColor32(col), dst);
     end
     else
      bits^[idx] := TColor32(col);
    end;
   lrmDensity:
    begin
     if FBlendEnabled then
     begin
      col := Cardinal($00000000) or (Cardinal(FBlendAlpha) shl 24);
      dst := bits^[idx];
      bits^[idx] := BlendReg(TColor32(col), dst);
     end
     else
      bits^[idx] := TColor32($FF000000);
    end;
  else
    begin
     if FBlendEnabled then
     begin
      col := Cardinal($00000000) or (Cardinal(FBlendAlpha) shl 24);
      dst := bits^[idx];
      bits^[idx] := BlendReg(TColor32(col), dst);
     end
     else
      bits^[idx] := TColor32($FF000000);
    end;
  end;

 end;

 ADrawer.UpdateImage;
end;

end.
