unit ogcDrawerOGL;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Math, Graphics, Types, Controls, fgl,
 ogcBasic,
 uGLSceneIndexer,
 OpenGLPanel,
 dglOpenGL;

type
 TMat4 = array[0..15] of Single;

 TGLTileIndexMap = specialize TFPGMap<TGLTileId, Integer>;

 TDebugLabel = record
  X: Double;
  Y: Double;
  Text: String;
  Color: TColor;
 end;

 TLineVertex = packed record
  X: Single;
  Y: Single;
  R: Byte;
  G: Byte;
  B: Byte;
  A: Byte;
 end;

 TDrawerOGL = class(TogsDrawer)
 private
  FPanel: TOpenGLPanel;
  FCanvas: TControlCanvas;
  FOnPaint: TNotifyEvent;
  FGLInited: Boolean;
  FBuildingScene: Boolean;
  FProgram: GLuint;
  FLocMVP: GLint;
  FDrawPrim: GLenum;
  FVertCount: Integer;
  FVerts: array of TLineVertex;
  FSceneVertCount: Integer;
  FSceneVBO: GLuint;
  FSceneVAO: GLuint;
  FVBO: GLuint;
  FVAO: GLuint;
  FOverlayThick: Boolean;
  FOverlayWidthPx: Integer;
  FTileCount: Integer;
  FTileIds: array of TGLTileId;
  FTileIndex: TGLTileIndexMap;
  FTileVBO: array of GLuint;
  FTileIBO: array of GLuint;
  FTileVAO: array of GLuint;
  FTileVertCount: array of Integer;
  FTileIndCount: array of Integer;
  FTileVertUsed: array of Integer;
  FTileIndUsed: array of Integer;
  FTileVerts: array of array of TLineVertex;
  FTileInds: array of array of GLuint;
  FTileFillVBO: array of GLuint;
  FTileFillIBO: array of GLuint;
  FTileFillVAO: array of GLuint;
  FTileFillVertCount: array of Integer;
  FTileFillIndCount: array of Integer;
  FTileFillVertUsed: array of Integer;
  FTileFillIndUsed: array of Integer;
  FTileFillVerts: array of array of TLineVertex;
  FTileFillInds: array of array of GLuint;
  FIndexer: TGLSceneIndexer;
  FCurObjectId: TGLObjectId;
  FCurObjectTiles: TGLTileIdArray;
  FShowTiles: Boolean;
  FPendingColor: TColor;
  FForceColor: Boolean;
  FForcedColor: TColor;
  FDebugLabels: array of TDebugLabel;
  procedure RenderTilesOverlay;
  function GetHeight: Integer; override;
  function GetWidth: Integer; override;
  procedure SetHeight(AValue: Integer); override;
  procedure SetWidth(AValue: Integer); override;
  function CompileShader(AShaderType: GLenum; const ASource: AnsiString): GLuint;
  function LinkProgram(AVS, AFS: GLuint): GLuint;
  procedure EnsureCapacity(AddVerts: Integer);
  function FindOrAddTile(ATileId: TGLTileId): Integer;
  procedure EnsureTileCapacity(TileIndex, AddVerts: Integer);
  procedure EnsureTileIndexCapacity(TileIndex, AddInds: Integer);
  procedure EnsureTileFillCapacity(TileIndex, AddVerts: Integer);
  procedure EnsureTileFillIndexCapacity(TileIndex, AddInds: Integer);
  procedure TileAddVertex(TileIndex: Integer; const V: TLineVertex);
  procedure TileAddIndex(TileIndex: Integer; Ind: GLuint);
  procedure TileFillAddVertex(TileIndex: Integer; const V: TLineVertex);
  procedure TileFillAddIndex(TileIndex: Integer; Ind: GLuint);
  procedure Flush;
  procedure ApplyVertexColor(var V: TLineVertex);
  procedure ApplyFillVertexColor(var V: TLineVertex);
  procedure UseColor(ColorRGB: TColor);
  procedure GetMVP(out MVP: TMat4);
 protected
  procedure SetPen(AValue: TogsPen); override;
  function GetCanvas: TCanvas; override;
 public
  constructor Create(ogsSelector_: TogsSelector; Panel_: TOpenGLPanel; OnPaint_: TNotifyEvent);
  destructor Destroy; override;
 //
  procedure InitGL;
  procedure ReleaseGL;
 //
  procedure BeginObject(AObjectId: TGLObjectId);
  procedure EndObject;
  procedure Clear(AColor: Integer); override;
  procedure BeginPaint; override;
  procedure EndPaint; override;
  procedure BeginScene;
  procedure EndScene;
  procedure RenderScene;
  property ShowTiles: Boolean read FShowTiles write FShowTiles;
  property ForceColor: Boolean read FForceColor write FForceColor;
  property ForcedColor: TColor read FForcedColor write FForcedColor;
  property OverlayThick: Boolean read FOverlayThick write FOverlayThick;
  property OverlayWidthPx: Integer read FOverlayWidthPx write FOverlayWidthPx;
  procedure AddDebugLabel(X, Y: Double; const Text: String; Color_: TColor = clRed);
  procedure ClearDebugLabels;
  procedure RenderDebugLabels;
  procedure FlushOverlay;
  procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); override;
  procedure DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean = True); override;
  procedure DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean = True); override;
  procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); override;
  procedure DrawPolyTess(Geom: TogsGeometry; polyRect: TogsRect); override;
  function geoWidth: Double; override;
  function geoHeight: Double; override;
  procedure DrawTo(Image_: TCanvas; Rect: TRect); override; overload;
  property Indexer: TGLSceneIndexer read FIndexer write FIndexer;
 end;

implementation uses ogcGeometry, ogctess, ogcWriter;


constructor TDrawerOGL.Create(ogsSelector_: TogsSelector; Panel_: TOpenGLPanel; OnPaint_: TNotifyEvent);
begin
 inherited Create(ogsSelector_, OnPaint_);
 FPanel := Panel_;
 FCanvas := TControlCanvas.Create;
 FCanvas.Control := FPanel;
 FTileIndex := TGLTileIndexMap.Create;
 FTileIndex.Sorted := True;
 FGLInited := False;
 FProgram := 0;
 FVBO := 0;
 FVAO := 0;
 FLocMVP := -1;
 FDrawPrim := GL_LINES;
 FPendingColor := clBlack;
 FForceColor := False;
 FForcedColor := clRed;
 FOverlayThick := False;
 FOverlayWidthPx := 3;
 FShowTiles := False;
 SetLength(FVerts, 0);
 FVertCount := 0;
 FTileCount := 0;
 SetLength(FTileIds, 0);
 SetLength(FTileVBO, 0);
 SetLength(FTileIBO, 0);
 SetLength(FTileVAO, 0);
 SetLength(FTileVertCount, 0);
 SetLength(FTileIndCount, 0);
 SetLength(FTileVerts, 0);
 SetLength(FTileVertUsed, 0);
 SetLength(FTileIndUsed, 0);
 SetLength(FTileInds, 0);
 SetLength(FTileFillVBO, 0);
 SetLength(FTileFillIBO, 0);
 SetLength(FTileFillVAO, 0);
 SetLength(FTileFillVertCount, 0);
 SetLength(FTileFillIndCount, 0);
 SetLength(FTileFillVerts, 0);
 SetLength(FTileFillVertUsed, 0);
 SetLength(FTileFillIndUsed, 0);
 SetLength(FTileFillInds, 0);
 FBuildingScene := False;
 FIndexer := nil;
 FCurObjectId := 0;
 SetLength(FCurObjectTiles, 0);
 SetLength(FDebugLabels, 0);
end;

destructor TDrawerOGL.Destroy;
begin
 ReleaseGL;
 FreeAndNil(FTileIndex);
 FreeAndNil(FCanvas);
 inherited Destroy;
end;


function TDrawerOGL.GetWidth: Integer;
begin
 if FPanel <> nil then Result := FPanel.Width else Result := 0;
end;

function TDrawerOGL.GetHeight: Integer;
begin
 if FPanel <> nil then Result := FPanel.Height else Result := 0;
end;

procedure TDrawerOGL.SetWidth(AValue: Integer);
begin
 if FPanel <> nil then FPanel.Width := AValue;
end;

procedure TDrawerOGL.SetHeight(AValue: Integer);
begin
 if FPanel <> nil then FPanel.Height := AValue;
end;

function TDrawerOGL.GetCanvas: TCanvas;
begin
 Result := FCanvas;
end;

procedure TDrawerOGL.SetPen(AValue: TogsPen);
begin
 inherited SetPen(AValue);
 if AValue <> nil then
 begin
  UseColor(AValue.penColor);
  if (AValue.penWidth > 0) then glLineWidth(AValue.penWidth)
  else glLineWidth(1);
 end;
end;

function TDrawerOGL.CompileShader(AShaderType: GLenum; const ASource: AnsiString): GLuint;
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

function TDrawerOGL.LinkProgram(AVS, AFS: GLuint): GLuint;
var
 status: GLint;
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
  glDeleteProgram(Result);
  Result := 0;
 end;
end;

procedure TDrawerOGL.InitGL;
const
 VS_SRC: AnsiString =
  '#version 120'#10+
  'attribute vec2 aPos;'#10+
  'attribute vec4 aColor;'#10+
  'varying vec4 vColor;'#10+
  'uniform mat4 uMVP;'#10+
  'void main() {'#10+
  ' gl_Position = uMVP * vec4(aPos.xy, 0.0, 1.0);'#10+
  ' vColor = aColor;'#10+
  '}'#10;
 FS_SRC: AnsiString =
  '#version 120'#10+
  'varying vec4 vColor;'#10+
  'void main() {'#10+
  ' gl_FragColor = vColor;'#10+
  '}'#10;
var
 vsId: GLuint;
 fsId: GLuint;
begin
 if FGLInited then Exit;
 vsId := CompileShader(GL_VERTEX_SHADER, VS_SRC);
 fsId := CompileShader(GL_FRAGMENT_SHADER, FS_SRC);
 if (vsId = 0) or (fsId = 0) then
 begin
  if vsId <> 0 then glDeleteShader(vsId);
  if fsId <> 0 then glDeleteShader(fsId);
  Exit;
 end;
 FProgram := LinkProgram(vsId, fsId);
 glDeleteShader(vsId);
 glDeleteShader(fsId);
 if FProgram = 0 then Exit;
 FLocMVP := glGetUniformLocation(FProgram, PGLchar(PAnsiChar('uMVP')));
 glGenBuffers(1, @FVBO);
 if Assigned(glGenVertexArrays) then glGenVertexArrays(1, @FVAO);
 FGLInited := True;
end;

procedure TDrawerOGL.ReleaseGL;
var i: Integer;
begin
 if FVAO <> 0 then
 begin
  if Assigned(glDeleteVertexArrays) then glDeleteVertexArrays(1, @FVAO);
  FVAO := 0;
 end;
 if FVBO <> 0 then
 begin
  glDeleteBuffers(1, @FVBO);
  FVBO := 0;
 end;
 for i := 0 to FTileCount - 1 do
 begin
  if (Length(FTileVAO) > i) and (FTileVAO[i] <> 0) then
  begin
   if Assigned(glDeleteVertexArrays) then glDeleteVertexArrays(1, @FTileVAO[i]);
   FTileVAO[i] := 0;
  end;
  if (Length(FTileVBO) > i) and (FTileVBO[i] <> 0) then
  begin
   glDeleteBuffers(1, @FTileVBO[i]);
   FTileVBO[i] := 0;
  end;
  if (Length(FTileIBO) > i) and (FTileIBO[i] <> 0) then
  begin
   glDeleteBuffers(1, @FTileIBO[i]);
   FTileIBO[i] := 0;
  end;
  if (Length(FTileFillVAO) > i) and (FTileFillVAO[i] <> 0) then
  begin
   if Assigned(glDeleteVertexArrays) then glDeleteVertexArrays(1, @FTileFillVAO[i]);
   FTileFillVAO[i] := 0;
  end;
  if (Length(FTileFillVBO) > i) and (FTileFillVBO[i] <> 0) then
  begin
   glDeleteBuffers(1, @FTileFillVBO[i]);
   FTileFillVBO[i] := 0;
  end;
  if (Length(FTileFillIBO) > i) and (FTileFillIBO[i] <> 0) then
  begin
   glDeleteBuffers(1, @FTileFillIBO[i]);
   FTileFillIBO[i] := 0;
  end;
 end;
 if FProgram <> 0 then
 begin
  glDeleteProgram(FProgram);
  FProgram := 0;
 end;
 FGLInited := False;
end;

function TDrawerOGL.FindOrAddTile(ATileId: TGLTileId): Integer;
var idx: Integer;
begin
 if FTileIndex <> nil then
 begin
  idx := FTileIndex.IndexOf(ATileId);
  if idx >= 0 then Exit(FTileIndex.Data[idx]);
 end;
 Result := FTileCount;
 Inc(FTileCount);
 SetLength(FTileIds, FTileCount);
 SetLength(FTileVBO, FTileCount);
 SetLength(FTileIBO, FTileCount);
 SetLength(FTileVAO, FTileCount);
 SetLength(FTileVertCount, FTileCount);
 SetLength(FTileIndCount, FTileCount);
 SetLength(FTileVerts, FTileCount);
 SetLength(FTileVertUsed, FTileCount);
 SetLength(FTileIndUsed, FTileCount);
 SetLength(FTileInds, FTileCount);
 SetLength(FTileFillVBO, FTileCount);
 SetLength(FTileFillIBO, FTileCount);
 SetLength(FTileFillVAO, FTileCount);
 SetLength(FTileFillVertCount, FTileCount);
 SetLength(FTileFillIndCount, FTileCount);
 SetLength(FTileFillVerts, FTileCount);
 SetLength(FTileFillVertUsed, FTileCount);
 SetLength(FTileFillIndUsed, FTileCount);
 SetLength(FTileFillInds, FTileCount);
 FTileIds[Result] := ATileId;
 FTileVBO[Result] := 0;
 FTileIBO[Result] := 0;
 FTileVAO[Result] := 0;
 FTileVertCount[Result] := 0;
 FTileIndCount[Result] := 0;
 SetLength(FTileVerts[Result], 0);
 FTileVertUsed[Result] := 0;
 SetLength(FTileInds[Result], 0);
 FTileIndUsed[Result] := 0;
 FTileFillVBO[Result] := 0;
 FTileFillIBO[Result] := 0;
 FTileFillVAO[Result] := 0;
 FTileFillVertCount[Result] := 0;
 FTileFillIndCount[Result] := 0;
 SetLength(FTileFillVerts[Result], 0);
 FTileFillVertUsed[Result] := 0;
 SetLength(FTileFillInds[Result], 0);
 FTileFillIndUsed[Result] := 0;
 if FTileIndex <> nil then
  FTileIndex.Add(ATileId, Result);
end;

procedure TDrawerOGL.EnsureTileCapacity(TileIndex, AddVerts: Integer);
var need, n: Integer;
begin
 if (TileIndex < 0) or (TileIndex >= FTileCount) then Exit;
 need := FTileVertUsed[TileIndex] + AddVerts;
 if Length(FTileVerts[TileIndex]) >= need then Exit;
 n := Length(FTileVerts[TileIndex]);
 if n < 1024 then n := 1024;
 while n < need do n := n * 2;
 SetLength(FTileVerts[TileIndex], n);
end;

procedure TDrawerOGL.EnsureTileIndexCapacity(TileIndex, AddInds: Integer);
var need, n: Integer;
begin
 if (TileIndex < 0) or (TileIndex >= FTileCount) then Exit;
 need := FTileIndUsed[TileIndex] + AddInds;
 if Length(FTileInds[TileIndex]) >= need then Exit;
 n := Length(FTileInds[TileIndex]);
 if n < 1024 then n := 1024;
 while n < need do n := n * 2;
 SetLength(FTileInds[TileIndex], n);
end;

procedure TDrawerOGL.EnsureTileFillCapacity(TileIndex, AddVerts: Integer);
var need, n: Integer;
begin
 if (TileIndex < 0) or (TileIndex >= FTileCount) then Exit;
 need := FTileFillVertUsed[TileIndex] + AddVerts;
 if Length(FTileFillVerts[TileIndex]) >= need then Exit;
 n := Length(FTileFillVerts[TileIndex]);
 if n < 1024 then n := 1024;
 while n < need do n := n * 2;
 SetLength(FTileFillVerts[TileIndex], n);
end;

procedure TDrawerOGL.EnsureTileFillIndexCapacity(TileIndex, AddInds: Integer);
var need, n: Integer;
begin
 if (TileIndex < 0) or (TileIndex >= FTileCount) then Exit;
 need := FTileFillIndUsed[TileIndex] + AddInds;
 if Length(FTileFillInds[TileIndex]) >= need then Exit;
 n := Length(FTileFillInds[TileIndex]);
 if n < 1024 then n := 1024;
 while n < need do n := n * 2;
 SetLength(FTileFillInds[TileIndex], n);
end;

procedure TDrawerOGL.TileAddVertex(TileIndex: Integer; const V: TLineVertex);
begin
 EnsureTileCapacity(TileIndex, 1);
 FTileVerts[TileIndex][FTileVertUsed[TileIndex]] := V;
 Inc(FTileVertUsed[TileIndex]);
end;

procedure TDrawerOGL.TileAddIndex(TileIndex: Integer; Ind: GLuint);
begin
 EnsureTileIndexCapacity(TileIndex, 1);
 FTileInds[TileIndex][FTileIndUsed[TileIndex]] := Ind;
 Inc(FTileIndUsed[TileIndex]);
end;

procedure TDrawerOGL.TileFillAddVertex(TileIndex: Integer; const V: TLineVertex);
begin
 EnsureTileFillCapacity(TileIndex, 1);
 FTileFillVerts[TileIndex][FTileFillVertUsed[TileIndex]] := V;
 Inc(FTileFillVertUsed[TileIndex]);
end;

procedure TDrawerOGL.TileFillAddIndex(TileIndex: Integer; Ind: GLuint);
begin
 EnsureTileFillIndexCapacity(TileIndex, 1);
 FTileFillInds[TileIndex][FTileFillIndUsed[TileIndex]] := Ind;
 Inc(FTileFillIndUsed[TileIndex]);
end;

procedure TDrawerOGL.EnsureCapacity(AddVerts: Integer);
var
 need: Integer;
 n: Integer;
begin
 need := FVertCount + AddVerts;
 if Length(FVerts) >= need then Exit;
 n := Length(FVerts);
 if n < 1024 then n := 1024;
 while n < need do n := n * 2;
 SetLength(FVerts, n);
end;

procedure TDrawerOGL.Flush;
var
 MVP: TMat4;
begin
 if FVertCount <= 0 then Exit;
 if not FGLInited then Exit;
 if (FProgram = 0) or (FVBO = 0) then Exit;
 glUseProgram(FProgram);
 GetMVP(MVP);
 if FLocMVP >= 0 then glUniformMatrix4fv(FLocMVP, 1, GL_FALSE, @MVP[0]);
 if FVAO <> 0 then glBindVertexArray(FVAO);
 glBindBuffer(GL_ARRAY_BUFFER, FVBO);
 glBufferData(GL_ARRAY_BUFFER, PtrInt(FVertCount * SizeOf(TLineVertex)), @FVerts[0], GL_STREAM_DRAW);
 glEnableVertexAttribArray(0);
 glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, SizeOf(TLineVertex), Pointer(PtrUInt(0)));
 glEnableVertexAttribArray(1);
 glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, SizeOf(TLineVertex), Pointer(PtrUInt(8)));
 if FDrawPrim = GL_LINES then
  glDrawArrays(GL_LINES, 0, FVertCount)
 else
  glDrawArrays(FDrawPrim, 0, FVertCount);
 glBindBuffer(GL_ARRAY_BUFFER, 0);
 if FVAO <> 0 then glBindVertexArray(0);
 FVertCount := 0;
end;

procedure TDrawerOGL.FlushOverlay;
begin
 if FOverlayThick then FDrawPrim := GL_TRIANGLES else FDrawPrim := GL_LINES;
 Flush;
 FDrawPrim := GL_LINES;
end;

procedure TDrawerOGL.ApplyVertexColor(var V: TLineVertex);
var col: Cardinal;
    c: TColor;
begin
 if FForceColor then c := FForcedColor else c := FPendingColor;
 col := ColorToRGB(c);
 V.R := Byte((col shr 0) and $FF);
 V.G := Byte((col shr 8) and $FF);
 V.B := Byte((col shr 16) and $FF);
 V.A := 255;
end;

procedure TDrawerOGL.ApplyFillVertexColor(var V: TLineVertex);
var col: Cardinal;
    c: TColor;
begin
 if FForceColor then c := FForcedColor else
  if Brush <> nil then c := Brush.brColor else c := FPendingColor;
 col := ColorToRGB(c);
 V.R := Byte((col shr 0) and $FF);
 V.G := Byte((col shr 8) and $FF);
 V.B := Byte((col shr 16) and $FF);
 V.A := 255;
end;

procedure TDrawerOGL.UseColor(ColorRGB: TColor);
begin
 FPendingColor := ColorRGB;
end;

procedure TDrawerOGL.GetMVP(out MVP: TMat4);
var
 L, R, B, T: Double;
 sx, sy, tx, ty: Double;
begin
 FillChar(MVP, SizeOf(MVP), 0);
 if (ogsSelector = nil) or (ogsSelector.ActiveRect = nil) then
 begin
  MVP[0] := 1;
  MVP[5] := 1;
  MVP[10] := 1;
  MVP[15] := 1;
  Exit;
 end;
 L := ogsSelector.ActiveRect.XMin;
 R := ogsSelector.ActiveRect.XMax;
 B := ogsSelector.ActiveRect.YMax;
 T := ogsSelector.ActiveRect.YMin;
 if (R = L) or (T = B) then
 begin
  MVP[0] := 1;
  MVP[5] := 1;
  MVP[10] := 1;
  MVP[15] := 1;
  Exit;
 end;
 sx := 2.0 / (R - L);
 sy := 2.0 / (T - B);
 tx := - (R + L) / (R - L);
 ty := - (T + B) / (T - B);
 MVP[0] := sx;
 MVP[5] := sy;
 MVP[10] := 1;
 MVP[12] := tx;
 MVP[13] := ty;
 MVP[15] := 1;
end;

procedure TDrawerOGL.BeginPaint;
begin
 if (FPanel = nil) then Exit;
 if not FPanel.MakeCurrent then Exit;
 InitGL;
 glViewport(0, 0, FPanel.Width, FPanel.Height);
 glDisable(GL_DEPTH_TEST);
 glEnable(GL_BLEND);
 glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
end;

procedure TDrawerOGL.EndPaint;
begin
 if FPanel <> nil then FPanel.SwapBuffers;
end;

procedure TDrawerOGL.Clear(AColor: Integer);
var r, g, b: Single;
begin
 r := ((AColor shr 16) and $FF) / 255.0;
 g := ((AColor shr 8) and $FF) / 255.0;
 b := ((AColor shr 0) and $FF) / 255.0;
 glClearColor(r, g, b, 1.0);
 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
end;

procedure TDrawerOGL.BeginScene;
begin
 FBuildingScene := True;
 FVertCount := 0;
 FTileCount := 0;
 if FTileIndex <> nil then FTileIndex.Clear;
 SetLength(FTileIds, 0);
 SetLength(FTileVBO, 0);
 SetLength(FTileIBO, 0);
 SetLength(FTileVAO, 0);
 SetLength(FTileVertCount, 0);
 SetLength(FTileIndCount, 0);
 SetLength(FTileVerts, 0);
 SetLength(FTileVertUsed, 0);
 SetLength(FTileIndUsed, 0);
 SetLength(FTileInds, 0);
 SetLength(FTileFillVBO, 0);
 SetLength(FTileFillIBO, 0);
 SetLength(FTileFillVAO, 0);
 SetLength(FTileFillVertCount, 0);
 SetLength(FTileFillIndCount, 0);
 SetLength(FTileFillVerts, 0);
 SetLength(FTileFillVertUsed, 0);
 SetLength(FTileFillIndUsed, 0);
 SetLength(FTileFillInds, 0);
end;

procedure TDrawerOGL.EndScene;
var
 i: Integer;
 vertCnt: Integer;
 indCnt: Integer;
begin
 FBuildingScene := False;
 if not FGLInited then Exit;
 if (FProgram = 0) then Exit;
 for i := 0 to FTileCount - 1 do
 begin
  vertCnt := FTileFillVertUsed[i];
  indCnt := FTileFillIndUsed[i];
  FTileFillVertCount[i] := vertCnt;
  FTileFillIndCount[i] := indCnt;
  if (vertCnt > 0) and (indCnt > 0) then
  begin
   if (Length(FTileFillVBO) > i) and (FTileFillVBO[i] = 0) then glGenBuffers(1, @FTileFillVBO[i]);
   if (Length(FTileFillIBO) > i) and (FTileFillIBO[i] = 0) then glGenBuffers(1, @FTileFillIBO[i]);
   if (Length(FTileFillVAO) > i) and (FTileFillVAO[i] = 0) and Assigned(glGenVertexArrays) then glGenVertexArrays(1, @FTileFillVAO[i]);
   if (Length(FTileFillVAO) > i) and (FTileFillVAO[i] <> 0) then glBindVertexArray(FTileFillVAO[i]);
   glBindBuffer(GL_ARRAY_BUFFER, FTileFillVBO[i]);
   glBufferData(GL_ARRAY_BUFFER, PtrInt(vertCnt * SizeOf(TLineVertex)), @FTileFillVerts[i][0], GL_STATIC_DRAW);
   glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, FTileFillIBO[i]);
   glBufferData(GL_ELEMENT_ARRAY_BUFFER, PtrInt(indCnt * SizeOf(GLuint)), @FTileFillInds[i][0], GL_STATIC_DRAW);
   glBindBuffer(GL_ARRAY_BUFFER, 0);
   glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
   if (Length(FTileFillVAO) > i) and (FTileFillVAO[i] <> 0) then glBindVertexArray(0);
  end;
  vertCnt := FTileVertUsed[i];
  indCnt := FTileIndUsed[i];
  FTileVertCount[i] := vertCnt;
  FTileIndCount[i] := indCnt;
  if (vertCnt <= 0) or (indCnt <= 0) then Continue;
  if (Length(FTileVBO) > i) and (FTileVBO[i] = 0) then glGenBuffers(1, @FTileVBO[i]);
  if (Length(FTileIBO) > i) and (FTileIBO[i] = 0) then glGenBuffers(1, @FTileIBO[i]);
  if (Length(FTileVAO) > i) and (FTileVAO[i] = 0) and Assigned(glGenVertexArrays) then glGenVertexArrays(1, @FTileVAO[i]);
  if (Length(FTileVAO) > i) and (FTileVAO[i] <> 0) then glBindVertexArray(FTileVAO[i]);
  glBindBuffer(GL_ARRAY_BUFFER, FTileVBO[i]);
  glBufferData(GL_ARRAY_BUFFER, PtrInt(vertCnt * SizeOf(TLineVertex)), @FTileVerts[i][0], GL_STATIC_DRAW);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, FTileIBO[i]);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, PtrInt(indCnt * SizeOf(GLuint)), @FTileInds[i][0], GL_STATIC_DRAW);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  if (Length(FTileVAO) > i) and (FTileVAO[i] <> 0) then glBindVertexArray(0);
 end;
end;

procedure TDrawerOGL.BeginObject(AObjectId: TGLObjectId);
begin
 FCurObjectId := AObjectId;
 SetLength(FCurObjectTiles, 0);
end;

procedure TDrawerOGL.EndObject;
begin
 FCurObjectId := 0;
 SetLength(FCurObjectTiles, 0);
end;

procedure TDrawerOGL.RenderScene;
var
 MVP: TMat4;
 i: Integer;
begin
 if not FGLInited then Exit;
 if (FProgram = 0) then Exit;
 if FTileCount <= 0 then Exit;
 glUseProgram(FProgram);
 GetMVP(MVP);
 if FLocMVP >= 0 then glUniformMatrix4fv(FLocMVP, 1, GL_FALSE, @MVP[0]);
 // Pass 1: draw ALL fills first, so fills from later tiles cannot cover lines from earlier tiles
 for i := 0 to FTileCount - 1 do
 begin
  if (Length(FTileFillVBO) > i) and (FTileFillVBO[i] <> 0) and
     (Length(FTileFillIBO) > i) and (FTileFillIBO[i] <> 0) and
     (FTileFillIndCount[i] > 0) then
  begin
   if (Length(FTileFillVAO) > i) and (FTileFillVAO[i] <> 0) then glBindVertexArray(FTileFillVAO[i]);
   glBindBuffer(GL_ARRAY_BUFFER, FTileFillVBO[i]);
   glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, FTileFillIBO[i]);
   glEnableVertexAttribArray(0);
   glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, SizeOf(TLineVertex), Pointer(PtrUInt(0)));
   glEnableVertexAttribArray(1);
   glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, SizeOf(TLineVertex), Pointer(PtrUInt(8)));
   glDrawElements(GL_TRIANGLES, FTileFillIndCount[i], GL_UNSIGNED_INT, Pointer(PtrUInt(0)));
   glBindBuffer(GL_ARRAY_BUFFER, 0);
   glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
   if (Length(FTileFillVAO) > i) and (FTileFillVAO[i] <> 0) then glBindVertexArray(0);
  end;
 end;

 // Pass 2: draw ALL lines after fills, so lines are always on top of fills
 for i := 0 to FTileCount - 1 do
 begin
  if (Length(FTileVBO) <= i) or (FTileVBO[i] = 0) then Continue;
  if (FTileVertCount[i] <= 0) or (Length(FTileIBO) <= i) or (FTileIBO[i] = 0) or (FTileIndCount[i] <= 0) then Continue;
  if (Length(FTileVAO) > i) and (FTileVAO[i] <> 0) then glBindVertexArray(FTileVAO[i]);
  glBindBuffer(GL_ARRAY_BUFFER, FTileVBO[i]);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, FTileIBO[i]);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, SizeOf(TLineVertex), Pointer(PtrUInt(0)));
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, SizeOf(TLineVertex), Pointer(PtrUInt(8)));
  glDrawElements(GL_LINES, FTileIndCount[i], GL_UNSIGNED_INT, Pointer(PtrUInt(0)));
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  if (Length(FTileVAO) > i) and (FTileVAO[i] <> 0) then glBindVertexArray(0);
 end;
 if FShowTiles then RenderTilesOverlay;
end;

procedure TDrawerOGL.RenderTilesOverlay;
var
 tx, ty: LongInt;
 tx0, ty0, tx1, ty1: LongInt;
 x0, y0, x1, y1: Double;
 s: Double;
 oldForce: Boolean;
 oldColor: TColor;
 gRect: TogsRect;
begin
 if (FIndexer = nil) then Exit;
 s := FIndexer.TileSize;
 if s <= 0 then Exit;
 gRect := nil;
 if (ogsSelector <> nil) then gRect := ogsSelector.GlobalRect;
 if gRect = nil then Exit;
 oldForce := FForceColor;
 oldColor := FForcedColor;
 FForceColor := True;
 FForcedColor := clSilver;
 try
  tx0 := Floor(Min(gRect.XMin, gRect.XMax) / s);
  tx1 := Floor(Max(gRect.XMin, gRect.XMax) / s);
  ty0 := Floor(Min(gRect.YMin, gRect.YMax) / s);
  ty1 := Floor(Max(gRect.YMin, gRect.YMax) / s);
  for ty := ty0 to ty1 do
   for tx := tx0 to tx1 do
   begin
    x0 := tx * s;
    y0 := ty * s;
    x1 := x0 + s;
    y1 := y0 + s;
    DrawLine(x0, y0, x1, y0, True);
    DrawLine(x1, y0, x1, y1, True);
    DrawLine(x1, y1, x0, y1, True);
    DrawLine(x0, y1, x0, y0, True);
   end;
  Flush;
 finally
  FForceColor := oldForce;
  FForcedColor := oldColor;
 end;
end;

procedure TDrawerOGL.AddDebugLabel(X, Y: Double; const Text: String; Color_: TColor);
var n: Integer;
begin
 n := Length(FDebugLabels);
 SetLength(FDebugLabels, n + 1);
 FDebugLabels[n].X := X;
 FDebugLabels[n].Y := Y;
 FDebugLabels[n].Text := Text;
 FDebugLabels[n].Color := Color_;
end;

procedure TDrawerOGL.ClearDebugLabels;
begin
 SetLength(FDebugLabels, 0);
end;

procedure TDrawerOGL.RenderDebugLabels;
var
 i: Integer;
 cx, cy: Integer;
begin
 if (FCanvas = nil) or (ogsSelector = nil) then Exit;
 for i := 0 to Length(FDebugLabels) - 1 do
 begin
  cx := ogsSelector.XPix(FDebugLabels[i].X);
  cy := ogsSelector.YPix(FDebugLabels[i].Y);
  FCanvas.Font.Color := FDebugLabels[i].Color;
  FCanvas.TextOut(cx, cy, FDebugLabels[i].Text);
 end;
end;

procedure TDrawerOGL.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
const
 C = 0;
var
 V: TLineVertex;
 t, tileIndex: Integer;
 X_, Y_, X1_, Y1_: Double;
 dx, dy, len: Double;
 nx, ny, off: Double;
 vx0, vy0, vx1, vy1: Double;
function MakeV(AX, AY: Double): TLineVertex;
begin
 Result.X := AX;
 Result.Y := AY;
 ApplyVertexColor(Result);
end;
begin
 if Disable then Exit;
 if FBuildingScene then cutRequest := False;
 if (not FBuildingScene) and FOverlayThick and (ogsSelector <> nil) and (FOverlayWidthPx > 1) then
 begin
  dx := X1 - X;
  dy := Y1 - Y;
  len := Hypot(dx, dy);
  if len <= 0 then Exit;
  nx := -dy / len;
  ny := dx / len;
  off := ogsSelector.geoDist(FOverlayWidthPx) * 0.5;
  vx0 := X + nx * off;
  vy0 := Y + ny * off;
  vx1 := X - nx * off;
  vy1 := Y - ny * off;
  EnsureCapacity(6);
  FVerts[FVertCount] := MakeV(vx0, vy0);
  Inc(FVertCount);
  FVerts[FVertCount] := MakeV(vx1, vy1);
  Inc(FVertCount);
  FVerts[FVertCount] := MakeV(X1 + nx * off, Y1 + ny * off);
  Inc(FVertCount);
  FVerts[FVertCount] := MakeV(X1 + nx * off, Y1 + ny * off);
  Inc(FVertCount);
  FVerts[FVertCount] := MakeV(vx1, vy1);
  Inc(FVertCount);
  FVerts[FVertCount] := MakeV(X1 - nx * off, Y1 - ny * off);
  Inc(FVertCount);
  if FVertCount >= 65536 then FlushOverlay;
  Exit;
 end;

 if FBuildingScene then
 begin
  V.X := X;
  V.Y := Y;
  ApplyVertexColor(V);
  tileIndex := FindOrAddTile(0);
  TileAddVertex(tileIndex, V);
  TileAddIndex(tileIndex, GLuint(FTileVertUsed[tileIndex] - 1));
  v.X := X1;
  v.Y := Y1;
  ApplyVertexColor(v);
  tileIndex := FindOrAddTile(0);
  TileAddVertex(tileIndex, v);
  TileAddIndex(tileIndex, GLuint(FTileVertUsed[tileIndex] - 1));
  Exit;
 end;
 X_ := X;
 Y_ := Y;
 X1_ := X1;
 Y1_ := Y1;
 with ogsSelector, ActiveRect do
  if pointVisible(X, Y) and pointVisible(X1, Y1) then
  begin
   EnsureCapacity(2);
   FVerts[FVertCount].X := X_;
   FVerts[FVertCount].Y := Y_;
   ApplyVertexColor(FVerts[FVertCount]);
   Inc(FVertCount);
   FVerts[FVertCount].X := X1_;
   FVerts[FVertCount].Y := Y1_;
   ApplyVertexColor(FVerts[FVertCount]);
   Inc(FVertCount);
  end else
  if lineVisible(X, Y, X1, Y1) then
   if cutLine(XMin + C, YMin + C, XMax - C, YMax - C, X_, Y_, X1_, Y1_) then
   begin
    EnsureCapacity(2);
    FVerts[FVertCount].X := X_;
    FVerts[FVertCount].Y := Y_;
    ApplyVertexColor(FVerts[FVertCount]);
    Inc(FVertCount);
    FVerts[FVertCount].X := X1_;
    FVerts[FVertCount].Y := Y1_;
    ApplyVertexColor(FVerts[FVertCount]);
    Inc(FVertCount);
   end;
 if (not FBuildingScene) and (FVertCount >= 65536) then Flush;
end;

procedure TDrawerOGL.DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean);
var
 i: Integer;
 p0: TogsDot;
 p1: TogsDot;
 v0, v1: TLineVertex;
 t, tileIndex: Integer;
 base: Integer;
 vu: Integer;
 iu: Integer;
begin
 if (Points = nil) then Exit;
 if Points.Count < 2 then Exit;
 if (not FBuildingScene) and FOverlayThick and (FOverlayWidthPx > 1) then
 begin
  for i := 1 to Points.Count - 1 do
  begin
   p0 := TogsDot(Points[i - 1]);
   p1 := TogsDot(Points[i]);
   if (p0 <> nil) and (p1 <> nil) then DrawLine(p0.fX, p0.fY, p1.fX, p1.fY, False);
  end;
  Exit;
 end;
 if not cutRequest then
 begin
  if FBuildingScene then
  begin
   tileIndex := FindOrAddTile(0);
   base := FTileVertUsed[tileIndex];
   EnsureTileCapacity(tileIndex, Points.Count);
   EnsureTileIndexCapacity(tileIndex, (Points.Count - 1) * 2);
   vu := FTileVertUsed[tileIndex];
   iu := FTileIndUsed[tileIndex];
   for i := 0 to Points.Count - 1 do
   begin
    p0 := TogsDot(Points[i]);
    v0.X := p0.fX;
    v0.Y := p0.fY;
    ApplyVertexColor(v0);
    FTileVerts[tileIndex][vu] := v0;
    Inc(vu);
   end;
   for i := 0 to Points.Count - 2 do
   begin
    FTileInds[tileIndex][iu] := GLuint(base + i);
    Inc(iu);
    FTileInds[tileIndex][iu] := GLuint(base + i + 1);
    Inc(iu);
   end;
   FTileVertUsed[tileIndex] := vu;
   FTileIndUsed[tileIndex] := iu;
   Exit;
  end;
  for i := 1 to Points.Count - 1 do
  begin
   p0 := TogsDot(Points[i - 1]);
   p1 := TogsDot(Points[i]);
   if (p0 = nil) or (p1 = nil) then Continue;
   EnsureCapacity(2);
   FVerts[FVertCount].X := p0.fX;
   FVerts[FVertCount].Y := p0.fY;
   ApplyVertexColor(FVerts[FVertCount]);
   Inc(FVertCount);
   FVerts[FVertCount].X := p1.fX;
   FVerts[FVertCount].Y := p1.fY;
   ApplyVertexColor(FVerts[FVertCount]);
   Inc(FVertCount);
  end;
  if (not FBuildingScene) and (FVertCount >= 65536) then Flush;
  Exit;
 end;
 for i := 1 to Points.Count - 1 do
 begin
  p0 := TogsDot(Points[i - 1]);
  p1 := TogsDot(Points[i]);
  if (p0 <> nil) and (p1 <> nil) then DrawLine(p0.fX, p0.fY, p1.fX, p1.fY, cutRequest);
 end;
end;

procedure TDrawerOGL.DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean);
var
 i: Integer;
 poly: TogsPolyCollection;
begin
 if Parts = nil then Exit;
 for i := 0 to Parts.Count - 1 do
 begin
  poly := TogsPolyCollection(Parts[i]);
  if poly <> nil then DrawPolyline(poly, cutRequest);
 end;
end;

procedure TDrawerOGL.DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect);
var
 i: Integer;
 j: Integer;
 ring: TogsPolyCollection;
 p0: TogsDot;
 p1: TogsDot;
begin
 if (Polygons = nil) then Exit;
 for i := 0 to Polygons.Count - 1 do
 begin
  ring := TogsPolyCollection(Polygons[i]);
  if (ring = nil) or (ring.Count < 2) then Continue;
  for j := 1 to ring.Count - 1 do
  begin
   p0 := TogsDot(ring[j - 1]);
   p1 := TogsDot(ring[j]);
   if (p0 <> nil) and (p1 <> nil) then DrawLine(p0.X, p0.Y, p1.X, p1.Y, False);
  end;
  p0 := TogsDot(ring[ring.Count - 1]);
  p1 := TogsDot(ring[0]);
  if (p0 <> nil) and (p1 <> nil) then DrawLine(p0.X, p0.Y, p1.X, p1.Y, False);
 end;
end;

procedure TDrawerOGL.DrawPolyTess(Geom: TogsGeometry; polyRect: TogsRect);
var
 tess: TogsTess;
 t: Integer;
 tileIndex: Integer;
 base: Integer;
 i: Integer;
 v: TLineVertex;
 idx: GLuint;
 Matrix: TogsMatrix;
 useMatrix: Boolean;
begin
 if Disable then Exit;
 if not FBuildingScene then Exit;
 if (Geom = nil) then Exit;
 if not (Geom is TogsPolygon) and not (Geom is TogsMultiPolygon) then Exit;
 if Geom is TogsPolygon then tess := TogsPolygon(Geom).ogsTess else tess := TogsMultiPolygon(Geom).ogsTess;
 if Tess = nil then exit;
 if (Length(tess.Vertices) = 0) or (Length(tess.Indices) = 0) then Exit;
 Matrix := ogsMatrix;
 useMatrix := Matrix <> nil;
 tileIndex := FindOrAddTile(0);
 base := FTileFillVertUsed[tileIndex];
 EnsureTileFillCapacity(tileIndex, Length(tess.Vertices));
 EnsureTileFillIndexCapacity(tileIndex, Length(tess.Indices));
 for i := 0 to Length(tess.Vertices) - 1 do
 begin
  if useMatrix then
  begin
   v.X := xMatrix(Matrix.X, tess.Vertices[i].X, tess.Vertices[i].Y, Matrix.Angle, Matrix.Scale);
   v.Y := yMatrix(Matrix.Y, tess.Vertices[i].X, tess.Vertices[i].Y, Matrix.Angle, Matrix.Scale);
  end else
  begin
   v.X := tess.Vertices[i].X;
   v.Y := tess.Vertices[i].Y;
  end;
  ApplyFillVertexColor(v);
  FTileFillVerts[tileIndex][FTileFillVertUsed[tileIndex]] := v;
  Inc(FTileFillVertUsed[tileIndex]);
 end;
 for i := 0 to Length(tess.Indices) - 1 do
 begin
  idx := GLuint(base) + GLuint(tess.Indices[i]);
  FTileFillInds[tileIndex][FTileFillIndUsed[tileIndex]] := idx;
  Inc(FTileFillIndUsed[tileIndex]);
 end;
end;

function TDrawerOGL.geoWidth: Double;
begin
 if (ogsSelector = nil) or (ogsSelector.ActiveRect = nil) then Result := 0
 else Result := ogsSelector.ActiveRect.XMax - ogsSelector.ActiveRect.XMin;
end;

function TDrawerOGL.geoHeight: Double;
begin
 if (ogsSelector = nil) or (ogsSelector.ActiveRect = nil) then Result := 0
 else Result := ogsSelector.ActiveRect.YMax - ogsSelector.ActiveRect.YMin;
end;

procedure TDrawerOGL.DrawTo(Image_: TCanvas; Rect: TRect);
begin
end;

end.
