unit uLasPointCloudGpu;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Math,
 dglOpenGL,
 ogcLas;

type
 TLasPointPacked = packed record
  X: Single;
  Y: Single;
  Z: Single;
  R: Byte;
  G: Byte;
  B: Byte;
  A: Byte;
 end;

 PLasPointPacked = ^TLasPointPacked;

 TMat4 = array[0..15] of Single;

 TLasPointCloudGpu = class
  private
   FProgramBase: GLuint;
   FProgramFx: GLuint;
   FVBO: GLuint;
   FVAO: GLuint;
   FCount: Integer;

   FBaseLocMVP: GLint;
   FBaseLocPointSize: GLint;
   FBaseLocAlpha: GLint;
   FBaseLocClipEnabled: GLint;
   FBaseLocClipZ: GLint;

   FFxLocMVP: GLint;
   FFxLocPointSize: GLint;
   FFxLocAlpha: GLint;
   FFxLocClipEnabled: GLint;
   FFxLocClipZ: GLint;
   FFxLocPickEnabled: GLint;
   FFxLocPickPos: GLint;
   FFxLocPickRadius: GLint;
   FFxLocPickZRadius: GLint;
   FFxLocHighlightOnly: GLint;
   FFxLocHighlightColor: GLint;

   FGLReady: Boolean;

   function CompileShader(AShaderType: GLenum; const ASource: AnsiString): GLuint;
   function LinkProgram(AVS, AFS: GLuint): GLuint;
   procedure QueryBaseLocations;
   procedure QueryFxLocations;
  public
   constructor Create;
   destructor Destroy; override;

   procedure InitGL;
   procedure ReleaseGL;

   procedure BuildFromLas(ALas: TogsLas; AMaxPoints: Int64 = 0;
                        AMinX: Double = 1E300; AMinY: Double = 1E300;
                        AMaxX: Double = -1E300; AMaxY: Double = -1E300);
   procedure BuildFromPacked(APoints: PLasPointPacked; ACount: Integer);
   procedure Render(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                    AClipEnabled: Boolean = False; AClipZ: Single = 0);
   procedure RenderCount(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                       ACount: Integer; AClipEnabled: Boolean = False; AClipZ: Single = 0);

   procedure RenderHighlight(const MVP: TMat4; APointSize: Single;
                            APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                            AColR, AColG, AColB, AColA: Single;
                            AClipEnabled: Boolean = False; AClipZ: Single = 0);
   procedure RenderHighlightCount(const MVP: TMat4; APointSize: Single;
                                ACount: Integer;
                                APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                AColR, AColG, AColB, AColA: Single;
                                AClipEnabled: Boolean = False; AClipZ: Single = 0);

   class procedure DrawBBoxLines(AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Single);

   property Count: Integer read FCount;
 end;

procedure MatMul(out R: TMat4; const A, B: TMat4);

implementation uses ogcWriter;

const
 ENABLE_SHADER_CLIP = True;

procedure MatMul(out R: TMat4; const A, B: TMat4);
var
 i, j: Integer;
begin
 // Матрицы хранятся в column-major формате как в OpenGL (индекс = Col*4 + Row)
 for i := 0 to 3 do
  for j := 0 to 3 do
   R[j*4 + i] := A[0*4 + i]*B[j*4 + 0] + A[1*4 + i]*B[j*4 + 1] + A[2*4 + i]*B[j*4 + 2] + A[3*4 + i]*B[j*4 + 3];
end;

constructor TLasPointCloudGpu.Create;
begin
 inherited Create;
 FProgramBase := 0;
 FProgramFx := 0;
 FVBO := 0;
 FVAO := 0;
 FCount := 0;
 FGLReady := False;
end;

destructor TLasPointCloudGpu.Destroy;
begin
 ReleaseGL;
 inherited Destroy;
end;

function TLasPointCloudGpu.CompileShader(AShaderType: GLenum; const ASource: AnsiString): GLuint;
var src: PGLchar;
    len: GLint;
    status: GLint;
    logLen: GLint;
    log: AnsiString;
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
  glGetShaderiv(Result, GL_INFO_LOG_LENGTH, @logLen);
  if logLen > 0 then
  begin
   SetLength(log, logLen);
   glGetShaderInfoLog(Result, logLen, @logLen, PGLchar(PAnsiChar(log)));
   WriteLn('Shader compile error: ', log);
  end;
  glDeleteShader(Result);
  Result := 0;
 end;
end;

function TLasPointCloudGpu.LinkProgram(AVS, AFS: GLuint): GLuint;
var status: GLint;
    logLen: GLint;
    log: AnsiString;
begin
 Result := glCreateProgram();
 if Result = 0 then Exit;
 glBindAttribLocation(Result, 0, PGLchar(PAnsiChar('aPos')));
 glBindAttribLocation(Result, 1, PGLchar(PAnsiChar('aColor')));
 glAttachShader(Result, AVS);
 glAttachShader(Result, AFS);
 glLinkProgram(Result);
 glGetProgramiv(Result, GL_LINK_STATUS, @status);
 if status = 0 then
 begin
  glGetProgramiv(Result, GL_INFO_LOG_LENGTH, @logLen);
  if logLen > 0 then
  begin
   SetLength(log, logLen);
   glGetProgramInfoLog(Result, logLen, @logLen, PGLchar(PAnsiChar(log)));
   WriteLn('Program link error: ', log);
  end;
  glDeleteProgram(Result);
  Result := 0;
 end;
end;

procedure TLasPointCloudGpu.QueryBaseLocations;
begin
 FBaseLocMVP := glGetUniformLocation(FProgramBase, PGLchar(PAnsiChar('uMVP')));
 FBaseLocPointSize := glGetUniformLocation(FProgramBase, PGLchar(PAnsiChar('uPointSize')));
 FBaseLocAlpha := glGetUniformLocation(FProgramBase, PGLchar(PAnsiChar('uAlpha')));
 FBaseLocClipEnabled := glGetUniformLocation(FProgramBase, PGLchar(PAnsiChar('uClipEnabled')));
 FBaseLocClipZ := glGetUniformLocation(FProgramBase, PGLchar(PAnsiChar('uClipZ')));
end;

procedure TLasPointCloudGpu.QueryFxLocations;
begin
 FFxLocMVP := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uMVP')));
 FFxLocPointSize := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uPointSize')));
 FFxLocAlpha := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uAlpha')));
 FFxLocClipEnabled := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uClipEnabled')));
 FFxLocClipZ := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uClipZ')));

 FFxLocPickEnabled := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uPickEnabled')));
 FFxLocPickPos := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uPickPos')));
 FFxLocPickRadius := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uPickRadius')));
 FFxLocPickZRadius := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uPickZRadius')));
 FFxLocHighlightOnly := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uHighlightOnly')));
 FFxLocHighlightColor := glGetUniformLocation(FProgramFx, PGLchar(PAnsiChar('uHighlightColor')));
end;

procedure TLasPointCloudGpu.InitGL;
const
 VS_BASE: AnsiString =
  '#version 120'#10+
  'attribute vec3 aPos;'#10+
  'attribute vec4 aColor;'#10+
  'varying vec4 vColor;'#10+
  'varying float vZ;'#10+
  'uniform mat4 uMVP;'#10+
  'uniform float uPointSize;'#10+
  'uniform float uAlpha;'#10+
  'void main() {'#10+
  '  gl_Position = uMVP * vec4(aPos, 1.0);'#10+
  '  gl_PointSize = uPointSize;'#10+
  '  vColor = vec4(aColor.rgb, aColor.a * uAlpha);'#10+
  '  vZ = aPos.z;'#10+
  '}'#10;
//
 FS_BASE: AnsiString =
  '#version 120'#10+
  'varying vec4 vColor;'#10+
  'varying float vZ;'#10+
  'uniform int uClipEnabled;'#10+
  'uniform float uClipZ;'#10+
  'void main() {'#10+
  '  if ((uClipEnabled != 0) && (vZ > uClipZ)) discard;'#10+
  '  gl_FragColor = vColor;'#10+
  '}'#10;

 VS_FX: AnsiString =
  '#version 120'#10+
  'attribute vec3 aPos;'#10+
  'attribute vec4 aColor;'#10+
  'varying vec4 vColor;'#10+
  'varying float vZ;'#10+
  'varying float vPick;'#10+
  'uniform mat4 uMVP;'#10+
  'uniform float uPointSize;'#10+
  'uniform float uAlpha;'#10+
  'uniform int uClipEnabled;'#10+
  'uniform float uClipZ;'#10+
  'uniform int uPickEnabled;'#10+
  'uniform vec3 uPickPos;'#10+
  'uniform float uPickRadius;'#10+
  'uniform float uPickZRadius;'#10+
  'void main() {'#10+
  '  gl_Position = uMVP * vec4(aPos, 1.0);'#10+
  '  gl_PointSize = uPointSize;'#10+
  '  vColor = vec4(aColor.rgb, aColor.a * uAlpha);'#10+
  '  vZ = aPos.z;'#10+
  '  if (uPickEnabled != 0) {'#10+
  '    float dx = aPos.x - uPickPos.x;'#10+
  '    float dy = aPos.y - uPickPos.y;'#10+
  '    float r = uPickRadius;'#10+
  '    float dz = abs(aPos.z - uPickPos.z);'#10+
  '    if ((dx*dx + dy*dy <= r*r) && (dz <= uPickZRadius)) vPick = 1.0; else vPick = 0.0;'#10+
  '  } else {'#10+
  '    vPick = 0.0;'#10+
  '  }'#10+
  '}'#10;

 FS_FX: AnsiString =
  '#version 120'#10+
  'varying vec4 vColor;'#10+
  'varying float vZ;'#10+
  'varying float vPick;'#10+
  'uniform int uClipEnabled;'#10+
  'uniform float uClipZ;'#10+
  'uniform int uPickEnabled;'#10+
  'uniform int uHighlightOnly;'#10+
  'uniform vec4 uHighlightColor;'#10+
  'void main() {'#10+
  '  if ((uClipEnabled != 0) && (vZ > uClipZ)) discard;'#10+
  '  if ((uPickEnabled != 0) && (uHighlightOnly != 0)) {'#10+
  '    if (vPick < 0.5) discard;'#10+
  '    gl_FragColor = uHighlightColor;'#10+
  '  } else {'#10+
  '    gl_FragColor = vColor;'#10+
  '  }'#10+
  '}'#10;
var
 vsId, fsId: GLuint;
 vsFxId, fsFxId: GLuint;
begin
 if FGLReady then Exit;
 vsId := CompileShader(GL_VERTEX_SHADER, VS_BASE);
 fsId := CompileShader(GL_FRAGMENT_SHADER, FS_BASE);
 if (vsId = 0) or (fsId = 0) then
 begin
  if vsId <> 0 then glDeleteShader(vsId);
  if fsId <> 0 then glDeleteShader(fsId);
  Exit;
 end;

 vsFxId := CompileShader(GL_VERTEX_SHADER, VS_FX);
 fsFxId := CompileShader(GL_FRAGMENT_SHADER, FS_FX);
 if (vsFxId = 0) or (fsFxId = 0) then
 begin
  glDeleteShader(vsId);
  glDeleteShader(fsId);
  if vsFxId <> 0 then glDeleteShader(vsFxId);
  if fsFxId <> 0 then glDeleteShader(fsFxId);
  Exit;
 end;

 FProgramBase := LinkProgram(vsId, fsId);
 FProgramFx := LinkProgram(vsFxId, fsFxId);
 glDeleteShader(vsId);
 glDeleteShader(fsId);
 glDeleteShader(vsFxId);
 glDeleteShader(fsFxId);
 if (FProgramBase = 0) or (FProgramFx = 0) then
 begin
  if FProgramBase <> 0 then glDeleteProgram(FProgramBase);
  if FProgramFx <> 0 then glDeleteProgram(FProgramFx);
  FProgramBase := 0;
  FProgramFx := 0;
  Exit;
 end;

 QueryBaseLocations;
 QueryFxLocations;

 glGenBuffers(1, @FVBO);
 if Assigned(glGenVertexArrays) then
  glGenVertexArrays(1, @FVAO);

 FGLReady := True;
end;

procedure TLasPointCloudGpu.ReleaseGL;
begin
 if FVAO <> 0 then
 begin
  if Assigned(glDeleteVertexArrays) then
   glDeleteVertexArrays(1, @FVAO);
  FVAO := 0;
 end;
 if FVBO <> 0 then
 begin
  glDeleteBuffers(1, @FVBO);
  FVBO := 0;
 end;
 if FProgramBase <> 0 then
 begin
  glDeleteProgram(FProgramBase);
  FProgramBase := 0;
 end;
 if FProgramFx <> 0 then
 begin
  glDeleteProgram(FProgramFx);
  FProgramFx := 0;
 end;
 FCount := 0;
 FGLReady := False;
end;

procedure TLasPointCloudGpu.BuildFromLas(ALas: TogsLas; AMaxPoints: Int64;
                                         AMinX: Double; AMinY: Double;
                                         AMaxX: Double; AMaxY: Double);
var
 cnt: Int64;
 step: Int64;
 i: Int64;
 x, y, z: Double;
 r, g, b: Word;
 originX, originY, originZ: Double;
 p: TLasPointPacked;
 data: array of TLasPointPacked;
 idx: Integer;
 cR, cG, cB: Byte;
 useFilter: Boolean;

 function ColorWordToByte(V: Word): Byte;
 begin
  if V <= 255 then Result := Byte(V)
  else Result := Byte(V shr 8);
 end;
begin
 if not FGLReady then Exit;
 if (ALas = nil) or (ALas.Source = nil) or (not ALas.Source.IsOpen) then Exit;

 originX := (ALas.Source.Header.MinX + ALas.Source.Header.MaxX) * 0.5;
 originY := (ALas.Source.Header.MinY + ALas.Source.Header.MaxY) * 0.5;
 originZ := (ALas.Source.Header.MinZ + ALas.Source.Header.MaxZ) * 0.5;

 WriteIn(['PtCount', ALas.Source.PointCount, 'PtSize', Int64(ALas.Source.PointCount) * SizeOf(TLasPointPacked)]);
 WriteIn(['MaxPts=', AMaxPoints]);
 cnt := ALas.Source.PointCount;
 if cnt <= 0 then Exit;

 step := 1;
 if (AMaxPoints > 0) and (cnt > AMaxPoints) then
  step := Ceil(cnt / AMaxPoints);

 SetLength(data, (cnt + step - 1) div step);
 useFilter := (AMinX <= AMaxX) and (AMinY <= AMaxY);
 idx := 0;
 i := 0;
 while i < cnt do
 begin
  if not ALas.Source.GetPointXYZRGB(i, x, y, z, r, g, b) then
  begin
   Inc(i, step);
   Continue;
  end;

  if useFilter then
   if (x < AMinX) or (x > AMaxX) or (y < AMinY) or (y > AMaxY) then
   begin
    Inc(i, step);
    Continue;
   end;

  if r > 65535 then r := 65535;
  if g > 65535 then g := 65535;
  if b > 65535 then b := 65535;

  cR := ColorWordToByte(r);
  cG := ColorWordToByte(g);
  cB := ColorWordToByte(b);

  p.X := Single(x - originX);
  p.Y := Single(y - originY);
  p.Z := Single(z - originZ);
  p.R := cR;
  p.G := cG;
  p.B := cB;
  p.A := 255;

  data[idx] := p;
  Inc(idx);
  Inc(i, step);
 end;

 FCount := idx;
 if FCount <= 0 then Exit;

 if FVAO <> 0 then
  glBindVertexArray(FVAO);

 glBindBuffer(GL_ARRAY_BUFFER, FVBO);
 WriteIn(['CountPt=', Int64(FCount) * SizeOf(TLasPointPacked)]);
 glBufferData(GL_ARRAY_BUFFER, PtrInt(Int64(FCount) * SizeOf(TLasPointPacked)), @data[0], GL_STATIC_DRAW);

 if 0 >= 0 then
 begin
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TLasPointPacked), Pointer(PtrUInt(0)));
 end;

 if 1 >= 0 then
 begin
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, SizeOf(TLasPointPacked), Pointer(PtrUInt(12)));
 end;

 glBindBuffer(GL_ARRAY_BUFFER, 0);
 if FVAO <> 0 then
  glBindVertexArray(0);

 SetLength(data, 0);
end;

procedure TLasPointCloudGpu.BuildFromPacked(APoints: PLasPointPacked; ACount: Integer);
begin
 if not FGLReady then Exit;
 if (FVBO = 0) then Exit;
 if (APoints = nil) or (ACount <= 0) then
 begin
  FCount := 0;
  Exit;
 end;

 FCount := ACount;

 if FVAO <> 0 then
  glBindVertexArray(FVAO);

 glBindBuffer(GL_ARRAY_BUFFER, FVBO);
 glBufferData(GL_ARRAY_BUFFER, PtrInt(Int64(FCount) * SizeOf(TLasPointPacked)), APoints, GL_STATIC_DRAW);

 if 0 >= 0 then
 begin
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TLasPointPacked), Pointer(PtrUInt(0)));
 end;

 if 1 >= 0 then
 begin
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, SizeOf(TLasPointPacked), Pointer(PtrUInt(12)));
 end;

 glBindBuffer(GL_ARRAY_BUFFER, 0);
 if FVAO <> 0 then
  glBindVertexArray(0);
end;

procedure TLasPointCloudGpu.Render(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                                   AClipEnabled: Boolean; AClipZ: Single);
begin
 RenderCount(MVP, APointSize, AAlpha, FCount, AClipEnabled, AClipZ);
end;

procedure TLasPointCloudGpu.RenderCount(const MVP: TMat4; APointSize: Single; AAlpha: Single;
                                      ACount: Integer; AClipEnabled: Boolean; AClipZ: Single);
var drawN: Integer;
begin
 if not FGLReady then Exit;
 if (FProgramBase = 0) or (FVBO = 0) or (FCount <= 0) then Exit;
 drawN := EnsureRange(ACount, 0, FCount);
 if drawN <= 0 then Exit;
//
 glUseProgram(FProgramBase);

 if FBaseLocMVP >= 0 then
  glUniformMatrix4fv(FBaseLocMVP, 1, GL_FALSE, @MVP[0]);
 if FBaseLocPointSize >= 0 then
  glUniform1f(FBaseLocPointSize, APointSize);
 if FBaseLocAlpha >= 0 then
  glUniform1f(FBaseLocAlpha, EnsureRange(AAlpha, 0.0, 1.0));
 if FBaseLocClipEnabled >= 0 then
  glUniform1i(FBaseLocClipEnabled, Ord(AClipEnabled));
 if FBaseLocClipZ >= 0 then
  glUniform1f(FBaseLocClipZ, AClipZ);

 if FVAO <> 0 then
 begin
  glBindVertexArray(FVAO);
  glDrawArrays(GL_POINTS, 0, drawN);
  glBindVertexArray(0);
 end
 else
 begin
  glBindBuffer(GL_ARRAY_BUFFER, FVBO);
  if 0 >= 0 then
  begin
   glEnableVertexAttribArray(0);
   glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TLasPointPacked), Pointer(PtrUInt(0)));
  end;
  if 1 >= 0 then
  begin
   glEnableVertexAttribArray(1);
   glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, SizeOf(TLasPointPacked), Pointer(PtrUInt(12)));
  end;
  glDrawArrays(GL_POINTS, 0, drawN);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
 end;
 glUseProgram(0);
end;

procedure TLasPointCloudGpu.RenderHighlight(const MVP: TMat4; APointSize: Single;
                                            APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                            AColR, AColG, AColB, AColA: Single;
                                            AClipEnabled: Boolean; AClipZ: Single);
begin
 RenderHighlightCount(MVP, APointSize, FCount, APickX, APickY, APickZ, APickRadius, APickZRadius,
                     AColR, AColG, AColB, AColA, AClipEnabled, AClipZ);
end;

procedure TLasPointCloudGpu.RenderHighlightCount(const MVP: TMat4; APointSize: Single;
                                               ACount: Integer;
                                               APickX, APickY, APickZ: Single; APickRadius, APickZRadius: Single;
                                               AColR, AColG, AColB, AColA: Single;
                                               AClipEnabled: Boolean; AClipZ: Single);
var
 drawN: Integer;
begin
 if not FGLReady then Exit;
 if (FProgramFx = 0) or (FVBO = 0) or (FCount <= 0) then Exit;
 if APickRadius <= 0 then Exit;
 drawN := EnsureRange(ACount, 0, FCount);
 if drawN <= 0 then Exit;

 glEnable(GL_PROGRAM_POINT_SIZE);
 glPointSize(APointSize);

 glUseProgram(FProgramFx);

 if FFxLocMVP >= 0 then
  glUniformMatrix4fv(FFxLocMVP, 1, GL_FALSE, @MVP[0]);
 if FFxLocPointSize >= 0 then
  glUniform1f(FFxLocPointSize, APointSize);
 if FFxLocAlpha >= 0 then
  glUniform1f(FFxLocAlpha, 1.0);

 if FFxLocPickEnabled >= 0 then
  glUniform1i(FFxLocPickEnabled, 1);
 if FFxLocPickPos >= 0 then
  glUniform3f(FFxLocPickPos, APickX, APickY, APickZ);
 if FFxLocPickRadius >= 0 then
  glUniform1f(FFxLocPickRadius, APickRadius);
 if FFxLocPickZRadius >= 0 then
  glUniform1f(FFxLocPickZRadius, APickZRadius);
 if FFxLocHighlightOnly >= 0 then
  glUniform1i(FFxLocHighlightOnly, 1);
 if FFxLocHighlightColor >= 0 then
  glUniform4f(FFxLocHighlightColor, AColR, AColG, AColB, AColA);

 if ENABLE_SHADER_CLIP then
 begin
  if FFxLocClipEnabled >= 0 then
   glUniform1i(FFxLocClipEnabled, Ord(AClipEnabled));
  if FFxLocClipZ >= 0 then
   glUniform1f(FFxLocClipZ, AClipZ);
 end
 else
 begin
  if FFxLocClipEnabled >= 0 then
   glUniform1i(FFxLocClipEnabled, 0);
 end;

 if FVAO <> 0 then
 begin
  glBindVertexArray(FVAO);
  glDrawArrays(GL_POINTS, 0, drawN);
  glBindVertexArray(0);
 end
 else
 begin
  glBindBuffer(GL_ARRAY_BUFFER, FVBO);
  if 0 >= 0 then
  begin
   glEnableVertexAttribArray(0);
   glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TLasPointPacked), Pointer(PtrUInt(0)));
  end;
  if 1 >= 0 then
  begin
   glEnableVertexAttribArray(1);
   glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, SizeOf(TLasPointPacked), Pointer(PtrUInt(12)));
  end;
  glDrawArrays(GL_POINTS, 0, drawN);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
 end;

 glUseProgram(0);
 glDisable(GL_PROGRAM_POINT_SIZE);
end;

class procedure TLasPointCloudGpu.DrawBBoxLines(AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Single);
begin
 glBegin(GL_LINES);
  glVertex3f(AMinX, AMinY, AMinZ); glVertex3f(AMaxX, AMinY, AMinZ);
  glVertex3f(AMaxX, AMinY, AMinZ); glVertex3f(AMaxX, AMaxY, AMinZ);
  glVertex3f(AMaxX, AMaxY, AMinZ); glVertex3f(AMinX, AMaxY, AMinZ);
  glVertex3f(AMinX, AMaxY, AMinZ); glVertex3f(AMinX, AMinY, AMinZ);

  glVertex3f(AMinX, AMinY, AMaxZ); glVertex3f(AMaxX, AMinY, AMaxZ);
  glVertex3f(AMaxX, AMinY, AMaxZ); glVertex3f(AMaxX, AMaxY, AMaxZ);
  glVertex3f(AMaxX, AMaxY, AMaxZ); glVertex3f(AMinX, AMaxY, AMaxZ);
  glVertex3f(AMinX, AMaxY, AMaxZ); glVertex3f(AMinX, AMinY, AMaxZ);

  glVertex3f(AMinX, AMinY, AMinZ); glVertex3f(AMinX, AMinY, AMaxZ);
  glVertex3f(AMaxX, AMinY, AMinZ); glVertex3f(AMaxX, AMinY, AMaxZ);
  glVertex3f(AMaxX, AMaxY, AMinZ); glVertex3f(AMaxX, AMaxY, AMaxZ);
  glVertex3f(AMinX, AMaxY, AMinZ); glVertex3f(AMinX, AMaxY, AMaxZ);
 glEnd;
end;

end.
