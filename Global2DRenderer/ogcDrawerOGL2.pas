unit ogcDrawerOGL2;

{$mode ObjFPC}{$H+}

interface

uses Classes, SysUtils, Math, Graphics, fgl, OpenGLPanel, dglOpenGL,
 ogcDrawerOGL, ogcBasic, ogcGeometry, ogctess, ttfgeometry;

type
 TUsedGlyphMap = specialize TFPGMap<Pointer, Byte>;

 TGlyphVertex = packed record
  X: Single;
  Y: Single;
 end;

 TGlyphGL = record
  VBO: GLuint;
  IBO: GLuint;
  VAO: GLuint;
  IndCount: Integer;
 end;

 TGlyphGLMap = specialize TFPGMap<Pointer, TGlyphGL>;

 TGlyphInstance = packed record
  GlyphKey: Pointer;
  X: Single;
  Y: Single;
  Angle: Single;
  Scale: Single;
  ColorRGBA: Cardinal;
 end;

 TDrawerOGL2 = class(TDrawerOGL)
 protected
  FUsedGlyphs: TUsedGlyphMap;
  FGlyphGL: TGlyphGLMap;
  FGlyphInst: array of TGlyphInstance;
  FGlyphInstCount: Integer;

  FGlyphCacheEnabled: Boolean;

  FGlyphProgram: GLuint;
  FGlyphLocMVP: GLint;
  FGlyphLocTRS: GLint;
  FGlyphLocColor: GLint;

  function CompileShader(AShaderType: GLenum; const ASource: AnsiString): GLuint;
  function LinkProgram(AVS, AFS: GLuint): GLuint;
  procedure InitGlyphGL;
  procedure ReleaseGlyphGL;
  procedure EnsureGlyphInstCapacity(AddCount: Integer);
  procedure AddGlyphInstance(GlyphKey: Pointer; const M: TogsMatrix; ColorRGBA: Cardinal);
  procedure EnsureGlyphUploaded(Glyph: TFontSymbol);
 public
  constructor Create(ogsSelector_: TogsSelector; Panel_: TOpenGLPanel; OnPaint_: TNotifyEvent);
  destructor Destroy; override;
  procedure BeginScene; override;
  procedure ReleaseGL; override;
  procedure RenderScene; override;
  procedure DrawPolyTess(Geom: TogsGeometry; polyRect: TogsRect); override;

  property GlyphCacheEnabled: Boolean read FGlyphCacheEnabled write FGlyphCacheEnabled;
 end;


implementation

function TDrawerOGL2.CompileShader(AShaderType: GLenum; const ASource: AnsiString): GLuint;
var
 src: PGLchar;
 len: GLint;
 status: GLint;
begin
 Result := glCreateShader(AShaderType);
 if Result = 0 then Exit;
 src := PGLchar(PAnsiChar(ASource));
 len := Length(ASource);
 glShaderSource(Result, 1, @src, @len);
 glCompileShader(Result);
 glGetShaderiv(Result, GL_COMPILE_STATUS, @status);
 if status = 0 then
 begin
  glDeleteShader(Result);
  Result := 0;
 end;
end;

function TDrawerOGL2.LinkProgram(AVS, AFS: GLuint): GLuint;
var
 status: GLint;
begin
 Result := glCreateProgram();
 if Result = 0 then Exit;
 glBindAttribLocation(Result, 0, PGLchar(PAnsiChar('aPos')));
 glAttachShader(Result, AVS);
 glAttachShader(Result, AFS);
 glLinkProgram(Result);
 glGetProgramiv(Result, GL_LINK_STATUS, @status);
 if status = 0 then
 begin
  glDeleteProgram(Result);
  Result := 0;
 end;
end;

procedure TDrawerOGL2.InitGlyphGL;
const
 VS_SRC: AnsiString =
  '#version 120'#10+
  'attribute vec2 aPos;'#10+
  'uniform mat4 uMVP;'#10+
  'uniform vec4 uTRS;'#10+
  'void main() {'#10+
  ' float c = cos(uTRS.z);'#10+
  ' float s = sin(uTRS.z);'#10+
  ' vec2 p = aPos * uTRS.w;'#10+
  ' vec2 pr = vec2(p.x*c - p.y*s, p.x*s + p.y*c) + uTRS.xy;'#10+
  ' gl_Position = uMVP * vec4(pr.xy, 0.0, 1.0);'#10+
  '}'#10;
 FS_SRC: AnsiString =
  '#version 120'#10+
  'uniform vec4 uColor;'#10+
  'void main() {'#10+
  ' gl_FragColor = uColor;'#10+
  '}'#10;
var
 vsId: GLuint;
 fsId: GLuint;
begin
 if (not FGLInited) then Exit;
 if FGlyphProgram <> 0 then Exit;
 vsId := CompileShader(GL_VERTEX_SHADER, VS_SRC);
 fsId := CompileShader(GL_FRAGMENT_SHADER, FS_SRC);
 if (vsId = 0) or (fsId = 0) then
 begin
  if vsId <> 0 then glDeleteShader(vsId);
  if fsId <> 0 then glDeleteShader(fsId);
  Exit;
 end;
 FGlyphProgram := LinkProgram(vsId, fsId);
 glDeleteShader(vsId);
 glDeleteShader(fsId);
 if FGlyphProgram = 0 then Exit;
 FGlyphLocMVP := glGetUniformLocation(FGlyphProgram, PGLchar(PAnsiChar('uMVP')));
 FGlyphLocTRS := glGetUniformLocation(FGlyphProgram, PGLchar(PAnsiChar('uTRS')));
 FGlyphLocColor := glGetUniformLocation(FGlyphProgram, PGLchar(PAnsiChar('uColor')));
end;

procedure TDrawerOGL2.ReleaseGlyphGL;
var
 i: Integer;
 g: TGlyphGL;
begin
 if FGlyphGL <> nil then
 begin
  for i := 0 to FGlyphGL.Count - 1 do
  begin
   g := FGlyphGL.Data[i];
   if g.VAO <> 0 then
   begin
    if Assigned(glDeleteVertexArrays) then glDeleteVertexArrays(1, @g.VAO);
    g.VAO := 0;
   end;
   if g.VBO <> 0 then
   begin
    glDeleteBuffers(1, @g.VBO);
    g.VBO := 0;
   end;
   if g.IBO <> 0 then
   begin
    glDeleteBuffers(1, @g.IBO);
    g.IBO := 0;
   end;
   FGlyphGL.Data[i] := g;
  end;
  FGlyphGL.Clear;
 end;

 if FGlyphProgram <> 0 then
 begin
  glDeleteProgram(FGlyphProgram);
  FGlyphProgram := 0;
 end;
 FGlyphLocMVP := -1;
 FGlyphLocTRS := -1;
 FGlyphLocColor := -1;
end;

procedure TDrawerOGL2.EnsureGlyphInstCapacity(AddCount: Integer);
var
 need: Integer;
 n: Integer;
begin
 need := FGlyphInstCount + AddCount;
 if Length(FGlyphInst) >= need then Exit;
 n := Length(FGlyphInst);
 if n < 1024 then n := 1024;
 while n < need do n := n * 2;
 SetLength(FGlyphInst, n);
end;

procedure TDrawerOGL2.AddGlyphInstance(GlyphKey: Pointer; const M: TogsMatrix; ColorRGBA: Cardinal);
var
 inst: TGlyphInstance;
begin
 EnsureGlyphInstCapacity(1);
 inst.GlyphKey := GlyphKey;
 inst.X := M.X;
 inst.Y := M.Y;
 inst.Angle := M.Angle;
 inst.Scale := M.Scale;
 inst.ColorRGBA := ColorRGBA;
 FGlyphInst[FGlyphInstCount] := inst;
 Inc(FGlyphInstCount);
end;

procedure TDrawerOGL2.EnsureGlyphUploaded(Glyph: TFontSymbol);
var
 key: Pointer;
 idx: Integer;
 tess: TogsTess;
 g: TGlyphGL;
 verts: array of TGlyphVertex;
 inds: array of GLuint;
 i: Integer;
begin
 if (Glyph = nil) then Exit;
 tess := Glyph.ogsTess;
 if tess = nil then Exit;
 if (Length(tess.Vertices) = 0) or (Length(tess.Indices) = 0) then Exit;

 key := Pointer(Glyph);
 idx := -1;
 if FGlyphGL <> nil then idx := FGlyphGL.IndexOf(key);
 if idx >= 0 then Exit;

 FillChar(g, SizeOf(g), 0);
 g.IndCount := Length(tess.Indices);

 SetLength(verts, Length(tess.Vertices));
 for i := 0 to Length(tess.Vertices) - 1 do
 begin
  verts[i].X := tess.Vertices[i].X;
  verts[i].Y := tess.Vertices[i].Y;
 end;
 SetLength(inds, Length(tess.Indices));
 for i := 0 to Length(tess.Indices) - 1 do inds[i] := GLuint(tess.Indices[i]);

 glGenBuffers(1, @g.VBO);
 glGenBuffers(1, @g.IBO);
 if Assigned(glGenVertexArrays) then glGenVertexArrays(1, @g.VAO);

 if g.VAO <> 0 then glBindVertexArray(g.VAO);
 glBindBuffer(GL_ARRAY_BUFFER, g.VBO);
 glBufferData(GL_ARRAY_BUFFER, PtrInt(Length(verts) * SizeOf(TGlyphVertex)), @verts[0], GL_STATIC_DRAW);
 glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g.IBO);
 glBufferData(GL_ELEMENT_ARRAY_BUFFER, PtrInt(Length(inds) * SizeOf(GLuint)), @inds[0], GL_STATIC_DRAW);
 glEnableVertexAttribArray(0);
 glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, SizeOf(TGlyphVertex), Pointer(PtrUInt(0)));
 glBindBuffer(GL_ARRAY_BUFFER, 0);
 glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
 if g.VAO <> 0 then glBindVertexArray(0);

 if FGlyphGL <> nil then FGlyphGL.Add(key, g);
end;

constructor TDrawerOGL2.Create(ogsSelector_: TogsSelector; Panel_: TOpenGLPanel; OnPaint_: TNotifyEvent);
begin
 inherited Create(ogsSelector_, Panel_, OnPaint_);
 FUsedGlyphs := TUsedGlyphMap.Create;
 FUsedGlyphs.Sorted := True;
 FGlyphGL := TGlyphGLMap.Create;
 FGlyphGL.Sorted := True;
 SetLength(FGlyphInst, 0);
 FGlyphInstCount := 0;
 FGlyphProgram := 0;
 FGlyphLocMVP := -1;
 FGlyphLocTRS := -1;
 FGlyphLocColor := -1;

 FGlyphCacheEnabled := True;
end;

destructor TDrawerOGL2.Destroy;
begin
 ReleaseGlyphGL;
 FreeAndNil(FGlyphGL);
 FreeAndNil(FUsedGlyphs);
 inherited Destroy;
end;

procedure TDrawerOGL2.BeginScene;
begin
 if FUsedGlyphs <> nil then FUsedGlyphs.Clear;
 FGlyphInstCount := 0;
 inherited BeginScene;
end;

procedure TDrawerOGL2.ReleaseGL;
begin
 ReleaseGlyphGL;
 inherited ReleaseGL;
end;

procedure TDrawerOGL2.RenderScene;
var
 i: Integer;
 inst: TGlyphInstance;
 idx: Integer;
 g: TGlyphGL;
 MVP: TMat4;
 col: Cardinal;
 r, gg, b, a: Single;
 trs: array[0..3] of Single;
begin
 inherited RenderScene;

 if not FGlyphCacheEnabled then Exit;

 if (not FGLInited) then Exit;
 if (FGlyphInstCount <= 0) then Exit;
 if FGlyphGL = nil then Exit;
 InitGlyphGL;
 if FGlyphProgram = 0 then Exit;

 glUseProgram(FGlyphProgram);
 GetMVP(MVP);
 if FGlyphLocMVP >= 0 then glUniformMatrix4fv(FGlyphLocMVP, 1, GL_FALSE, @MVP[0]);

 for i := 0 to FGlyphInstCount - 1 do
 begin
  inst := FGlyphInst[i];
  idx := FGlyphGL.IndexOf(inst.GlyphKey);
  if idx < 0 then Continue;
  g := FGlyphGL.Data[idx];
  if (g.VBO = 0) or (g.IBO = 0) or (g.IndCount <= 0) then Continue;

  trs[0] := inst.X;
  trs[1] := inst.Y;
  trs[2] := inst.Angle;
  trs[3] := inst.Scale;
  if FGlyphLocTRS >= 0 then glUniform4fv(FGlyphLocTRS, 1, @trs[0]);

  col := inst.ColorRGBA;
  r := ((col shr 0) and $FF) / 255.0;
  gg := ((col shr 8) and $FF) / 255.0;
  b := ((col shr 16) and $FF) / 255.0;
  a := ((col shr 24) and $FF) / 255.0;
  if FGlyphLocColor >= 0 then glUniform4f(FGlyphLocColor, r, gg, b, a);

  if (g.VAO <> 0) then glBindVertexArray(g.VAO);
  glBindBuffer(GL_ARRAY_BUFFER, g.VBO);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g.IBO);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, SizeOf(TGlyphVertex), Pointer(PtrUInt(0)));
  glDrawElements(GL_TRIANGLES, g.IndCount, GL_UNSIGNED_INT, Pointer(PtrUInt(0)));
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  if (g.VAO <> 0) then glBindVertexArray(0);
 end;
end;

procedure TDrawerOGL2.DrawPolyTess(Geom: TogsGeometry; polyRect: TogsRect);
var
 key: Pointer;
 idx: Integer;
 Matrix: TogsMatrix;
 col: Cardinal;
 c: TColor;
begin
 if not FGlyphCacheEnabled then
 begin
  inherited DrawPolyTess(Geom, polyRect);
  Exit;
 end;

 // Capture glyph usage: when drawing a font glyph (TFontSymbol), it arrives here as a TogsMultiPolygon.
 // At this point, current ogsMatrix corresponds to the glyph instance transform set by TogsSymbol/TogsTextString.
 if (Geom <> nil) and (Geom is TFontSymbol) then
 begin
  Matrix := ogsMatrix;
  if Matrix = nil then Exit;

  // Pick fill color similar to base ApplyFillVertexColor.
  if ForceColor then c := ForcedColor else
   if Brush <> nil then c := Brush.brColor else c := clBlack;
  col := ColorToRGB(c) or $FF000000;

  EnsureGlyphUploaded(TFontSymbol(Geom));
  key := Pointer(Geom);
  if FUsedGlyphs <> nil then
  begin
   idx := FUsedGlyphs.IndexOf(key);
   if idx < 0 then FUsedGlyphs.Add(key, 1);
  end;
  AddGlyphInstance(key, Matrix, col);
  Exit;
 end;

 inherited DrawPolyTess(Geom, polyRect);
end;

end.

