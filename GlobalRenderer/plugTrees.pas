unit plugTrees;

{$mode Delphi}{$H+}

interface

uses
 Classes, SysUtils, OpenGLPanel;

type
 TplugTree = class
 public
  TreeID: Integer;
  TreePosY: Double;
  TreePosX: Double;
  TreePosZ: Double;
  TreeHeight: Double;
  DBH: Double;
 end;

 TplugTreeList = class(TList)
 private
  FOGL: TOpenGLPanel;
  FFontBase: Cardinal;
  FFontInited: Boolean;
  function DetectDelimiter(const S: String): Char;
  function ParseFloatDot(const S: String): Double;
  procedure FreeItems;
  procedure EnsureFont;
  procedure BuildGlyph(const ACh: AnsiChar; const ABits: array of Byte);
  procedure RenderText3D(const AX, AY, AZ: Double; const S: String);
  procedure RenderText2D(const AX, AY: Integer; const S: String);
 public
  constructor Create(AOGL: TOpenGLPanel);
  destructor Destroy; override;
  procedure Clear; override;
  function LoadFromCsv(const AFileName: String): Integer;
  function FilterByBBoxXY(const AMinX, AMaxX, AMinY, AMaxY: Double): Integer;
  procedure RenderTrees(const AOriginX, AOriginY, AOriginZ: Double);
  property OGL: TOpenGLPanel read FOGL;
 end;

implementation

uses
 dglOpenGL, GLU, Math;

constructor TplugTreeList.Create(AOGL: TOpenGLPanel);
begin
 inherited Create;
 FOGL := AOGL;
 FFontBase := 0;
 FFontInited := False;
end;

destructor TplugTreeList.Destroy;
begin
 FreeItems;
 inherited Destroy;
end;

procedure TplugTreeList.FreeItems;
var i: Integer;
begin
 for i := 0 to Count - 1 do
  TObject(Items[i]).Free;
 inherited Clear;
end;

procedure TplugTreeList.Clear;
begin
 FreeItems;
end;

procedure TplugTreeList.BuildGlyph(const ACh: AnsiChar; const ABits: array of Byte);
begin
 if FFontBase = 0 then Exit;
 glNewList(FFontBase + Ord(ACh), GL_COMPILE);
 glPushAttrib(GL_PIXEL_MODE_BIT);
 glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
 glPixelStorei(GL_UNPACK_LSB_FIRST, 1);
 glBitmap(8, 8, 0, 0, 8, 0, @ABits[0]);
 glPopAttrib;
 glEndList;
end;

procedure TplugTreeList.EnsureFont;
const
 g0: array[0..7] of Byte = ($00,$38,$44,$4C,$54,$44,$38,$00);
 g1: array[0..7] of Byte = ($00,$10,$30,$10,$10,$10,$38,$00);
 g2: array[0..7] of Byte = ($00,$38,$44,$04,$18,$20,$7C,$00);
 g3: array[0..7] of Byte = ($00,$38,$44,$08,$04,$44,$38,$00);
 g4: array[0..7] of Byte = ($00,$08,$18,$28,$48,$7C,$08,$00);
 g5: array[0..7] of Byte = ($00,$7C,$40,$78,$04,$44,$38,$00);
 g6: array[0..7] of Byte = ($00,$18,$20,$40,$78,$44,$38,$00);
 g7: array[0..7] of Byte = ($00,$7C,$44,$08,$10,$10,$10,$00);
 g8: array[0..7] of Byte = ($00,$38,$44,$38,$44,$44,$38,$00);
 g9: array[0..7] of Byte = ($00,$38,$44,$3C,$04,$08,$30,$00);
 gDot: array[0..7] of Byte = ($00,$00,$00,$00,$00,$00,$10,$00);
 gMinus: array[0..7] of Byte = ($00,$00,$00,$7C,$00,$00,$00,$00);
 gX: array[0..7] of Byte = ($00,$44,$28,$10,$28,$44,$00,$00);
 gY: array[0..7] of Byte = ($00,$44,$28,$10,$10,$10,$00,$00);
 gZ: array[0..7] of Byte = ($00,$7C,$08,$10,$20,$7C,$00,$00);
 gm: array[0..7] of Byte = ($00,$00,$68,$54,$54,$54,$00,$00);
 gSpace: array[0..7] of Byte = ($00,$00,$00,$00,$00,$00,$00,$00);
var
 i: Integer;
begin
 if FFontInited then Exit;
 if not Assigned(glGenLists) then Exit;
 FFontBase := glGenLists(256);
 if FFontBase = 0 then Exit;
 for i := 0 to 255 do
 begin
  glNewList(FFontBase + i, GL_COMPILE);
  glBitmap(8, 8, 0, 0, 8, 0, @gSpace[0]);
  glEndList;
 end;
 BuildGlyph('0', g0);
 BuildGlyph('1', g1);
 BuildGlyph('2', g2);
 BuildGlyph('3', g3);
 BuildGlyph('4', g4);
 BuildGlyph('5', g5);
 BuildGlyph('6', g6);
 BuildGlyph('7', g7);
 BuildGlyph('8', g8);
 BuildGlyph('9', g9);
 BuildGlyph('.', gDot);
 BuildGlyph('-', gMinus);
 BuildGlyph('X', gX);
 BuildGlyph('Y', gY);
 BuildGlyph('Z', gZ);
 BuildGlyph('m', gm);
 FFontInited := True;
end;

procedure TplugTreeList.RenderText3D(const AX, AY, AZ: Double; const S: String);
var p: PAnsiChar;
    n: Integer;
    s8: AnsiString;
const
 FontZoom = 1.3;
begin
 if S = '' then Exit;
 EnsureFont;
 if not FFontInited then Exit;
 s8 := AnsiString(S);
 if s8 = '' then Exit;
 glRasterPos3d(AX, AY, AZ);
 glListBase(FFontBase);
 p := PAnsiChar(s8);
 n := Length(s8);
 glPushAttrib(GL_PIXEL_MODE_BIT);
 glPixelZoom(FontZoom, FontZoom);
 glCallLists(n, GL_UNSIGNED_BYTE, p);
 glBitmap(0, 0, 0, 0, 1, 0, nil);
 glCallLists(n, GL_UNSIGNED_BYTE, p);
 glBitmap(0, 0, 0, 0, -1, 1, nil);
 glCallLists(n, GL_UNSIGNED_BYTE, p);
 glPopAttrib;
end;

procedure TplugTreeList.RenderText2D(const AX, AY: Integer; const S: String);
var p: PAnsiChar;
    n: Integer;
    s8: AnsiString;
const
 FontZoom = 3.0;
begin
 if S = '' then Exit;
 EnsureFont;
 if not FFontInited then Exit;
 s8 := AnsiString(S);
 if s8 = '' then Exit;
 glListBase(FFontBase);
 p := PAnsiChar(s8);
 n := Length(s8);
 glPushAttrib(GL_PIXEL_MODE_BIT);
 glPixelZoom(FontZoom, FontZoom);
 glRasterPos2i(AX, AY);
 glCallLists(n, GL_UNSIGNED_BYTE, p);
 glRasterPos2i(AX + 1, AY);
 glCallLists(n, GL_UNSIGNED_BYTE, p);
 glRasterPos2i(AX, AY + 1);
 glCallLists(n, GL_UNSIGNED_BYTE, p);
 glPopAttrib;
end;

function TplugTreeList.DetectDelimiter(const S: String): Char;
var cTab, cSem, cCom: Integer;
begin
 cTab := 0;
 cSem := 0;
 cCom := 0;
 if S <> '' then
 begin
  cTab := Length(S) - Length(StringReplace(S, #9, '', [rfReplaceAll]));
  cSem := Length(S) - Length(StringReplace(S, ';', '', [rfReplaceAll]));
  cCom := Length(S) - Length(StringReplace(S, ',', '', [rfReplaceAll]));
 end;
 Result := ',';
 if (cTab >= cSem) and (cTab >= cCom) and (cTab > 0) then Result := #9
 else if (cSem >= cTab) and (cSem >= cCom) and (cSem > 0) then Result := ';'
 else if (cCom > 0) then Result := ',';
end;

function TplugTreeList.ParseFloatDot(const S: String): Double;
var fs: TFormatSettings;
begin
 fs := DefaultFormatSettings;
 fs.DecimalSeparator := '.';
 Result := StrToFloat(Trim(S), fs);
end;

function TplugTreeList.LoadFromCsv(const AFileName: String): Integer;
var sl: TStringList;
    i: Integer;
    line: String;
    delim: Char;
    parts: TStringArray;
    t: TplugTree;
begin
 Clear;
 Result := 0;
 sl := TStringList.Create;
 try
  sl.LoadFromFile(AFileName);
  if sl.Count = 0 then Exit;
  delim := DetectDelimiter(sl[0]);
  for i := 0 to sl.Count - 1 do
  begin
   line := Trim(sl[i]);
   if line = '' then Continue;
   if (i = 0) and (Pos('TreeID', line) > 0) then Continue;
   parts := line.Split([delim]);
   if Length(parts) < 6 then Continue;
   t := TplugTree.Create;
   t.TreeID := StrToIntDef(Trim(parts[0]), 0);
   try
    t.TreePosY := ParseFloatDot(parts[1]);
    t.TreePosX := ParseFloatDot(parts[2]);
    t.TreePosZ := ParseFloatDot(parts[3]);
    t.TreeHeight := ParseFloatDot(parts[4]);
    t.DBH := ParseFloatDot(parts[5]);
   except
    t.Free;
    Continue;
   end;
   Add(t);
   Inc(Result);
  end;
 finally
  sl.Free;
 end;
end;

function TplugTreeList.FilterByBBoxXY(const AMinX, AMaxX, AMinY, AMaxY: Double): Integer;
var
 i: Integer;
 t: TplugTree;
begin
 Result := 0;
 for i := Count - 1 downto 0 do
 begin
  t := TplugTree(Items[i]);
  if t = nil then
  begin
   Delete(i);
   Inc(Result);
   Continue;
  end;
  if (t.TreePosX < AMinX) or (t.TreePosX > AMaxX) or (t.TreePosY < AMinY) or (t.TreePosY > AMaxY) then
  begin
   Delete(i);
   t.Free;
   Inc(Result);
  end;
 end;
end;

procedure TplugTreeList.RenderTrees(const AOriginX, AOriginY, AOriginZ: Double);
var
 i: Integer;
 t: TplugTree;
 x0, y0, z0: Double;
 x1, y1, z1: Double;
 hTree: Double;
 s: String;
 fs: TFormatSettings;
 mvm: array[0..15] of GLdouble;
 pm: array[0..15] of GLdouble;
 vp: array[0..3] of GLint;
 winX, winY, winZ: GLdouble;
 cx, cy: Integer;
 w, h: Integer;
begin
 if Count <= 0 then Exit;
 EnsureFont;
 glDisable(GL_TEXTURE_2D);
 glDisable(GL_LIGHTING);
 glColor3f(0.0, 1.0, 0.0);
 glLineWidth(2);
 glBegin(GL_LINES);
 for i := 0 to Count - 1 do
 begin
  t := TplugTree(Items[i]);
  if t = nil then Continue;
  x0 := t.TreePosX - AOriginX;
  y0 := t.TreePosY - AOriginY;
  z0 := t.TreePosZ - AOriginZ;
  x1 := x0;
  y1 := y0;
  hTree := t.TreeHeight - t.TreePosZ;
  if hTree < 0 then hTree := 0;
  z1 := (t.TreePosZ + hTree) - AOriginZ;
  glVertex3d(x0, y0, z0);
  glVertex3d(x1, y1, z1);
 end;
 glEnd;
 glLineWidth(1);
 fs := DefaultFormatSettings;
 fs.DecimalSeparator := '.';
 glGetDoublev(GL_MODELVIEW_MATRIX, @mvm[0]);
 glGetDoublev(GL_PROJECTION_MATRIX, @pm[0]);
 glGetIntegerv(GL_VIEWPORT, @vp[0]);
 w := vp[2];
 h := vp[3];
 glPushAttrib(GL_ENABLE_BIT or GL_CURRENT_BIT or GL_TRANSFORM_BIT or GL_DEPTH_BUFFER_BIT);
 glDisable(GL_DEPTH_TEST);
 glMatrixMode(GL_PROJECTION);
 glPushMatrix;
 glLoadIdentity;
 glOrtho(0, w, 0, h, -1, 1);
 glMatrixMode(GL_MODELVIEW);
 glPushMatrix;
 glLoadIdentity;
 for i := 0 to Count - 1 do
 begin
  t := TplugTree(Items[i]);
  if t = nil then Continue;
  x0 := t.TreePosX - AOriginX;
  y0 := t.TreePosY - AOriginY;
  hTree := t.TreeHeight - t.TreePosZ;
  if hTree < 0 then hTree := 0;
  z1 := (t.TreePosZ + hTree) - AOriginZ;
  s := FormatFloat('0.0', hTree, fs) + 'm';
  if gluProject(x0, y0, z1 + 0.2, @mvm[0], @pm[0], @vp[0], @winX, @winY, @winZ) <> 0 then
  begin
   if (winZ >= 0) and (winZ <= 1) then
   begin
    cx := Round(winX);
    cy := Round(winY);
    if (cx >= 0) and (cx < w) and (cy >= 0) and (cy < h) then
    begin
     glColor3f(0, 0, 0);
     RenderText2D(cx - 2, cy, s);
     RenderText2D(cx + 2, cy, s);
     RenderText2D(cx, cy - 2, s);
     RenderText2D(cx, cy + 2, s);
     RenderText2D(cx - 2, cy - 2, s);
     RenderText2D(cx - 2, cy + 2, s);
     RenderText2D(cx + 2, cy - 2, s);
     RenderText2D(cx + 2, cy + 2, s);
     glColor3f(1, 1, 1);
     RenderText2D(cx, cy, s);
    end;
   end;
  end;
 end;
 glPopMatrix;
 glMatrixMode(GL_PROJECTION);
 glPopMatrix;
 glMatrixMode(GL_MODELVIEW);
 glPopAttrib;
end;

end.
