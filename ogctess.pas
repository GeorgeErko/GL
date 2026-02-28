unit ogctess;

{$mode Delphi}{$H+}

interface

uses Classes, SysUtils, Math, ogcBasic, dglOpenGL, GLU;

type
 TogsTessVertex = packed record
  X, Y: Single;
 end;

 TogsTessIndex = Cardinal;

 TogsTessVertexArray = array of TogsTessVertex;
 TogsTessIndexArray = array of TogsTessIndex;

 TogsTess = class(TogsBasic)
 private
  FVertices: TogsTessVertexArray;
  FIndices: TogsTessIndexArray;
  FSourceOgsId: Int64;
  FSourceRenderOrder: Integer;
 public
  constructor CreateAs(ogsObject: TogsBasic); override;
  procedure Clear;
  procedure BuildTess(Geom: TogsGeometry); overload;
  property Vertices: TogsTessVertexArray read FVertices write FVertices;
  property Indices: TogsTessIndexArray read FIndices write FIndices;
  property SourceOgsId: Int64 read FSourceOgsId write FSourceOgsId;
  property SourceRenderOrder: Integer read FSourceRenderOrder write FSourceRenderOrder;
 end;

implementation uses ogcGeometry, ogcWriter;

 type
  PTessCtx = ^TTessCtx;
  TTessCtx = record
   Mode: Integer;
   Current: Integer;
   V: array[0..2] of TogsTessVertex;
   Tri: array of TogsTessVertex;
   TriCount: Integer;
   Alloc: array of Pointer;
   AllocCount: Integer;
  end;

 type
  PTessVertData = ^TTessVertData;
  TTessVertData = record
   Coords: array[0..2] of Double;
   V: TogsTessVertex;
  end;

 procedure TessBegin(Mode: Integer; userData: Pointer); stdcall;
 var ctx: PTessCtx;
 begin
  ctx := PTessCtx(userData);
  if ctx = nil then Exit;
  ctx^.Mode := Mode;
  ctx^.Current := 0;
 end;

 procedure TessVertex(VertexData: Pointer; userData: Pointer); stdcall;
 var ctx: PTessCtx;
     p: ^TogsTessVertex;
 begin
  ctx := PTessCtx(userData);
  if (ctx = nil) or (VertexData = nil) then Exit;
  p := VertexData;
  if ctx^.TriCount + 3 > Length(ctx^.Tri) then
   SetLength(ctx^.Tri, Length(ctx^.Tri) + 65536);
  ctx^.V[ctx^.Current] := p^;
  Inc(ctx^.Current);
  if ctx^.Current <> 3 then Exit;
  case ctx^.Mode of
   GL_TRIANGLES:
    begin
     ctx^.Tri[ctx^.TriCount] := ctx^.V[0]; Inc(ctx^.TriCount);
     ctx^.Tri[ctx^.TriCount] := ctx^.V[1]; Inc(ctx^.TriCount);
     ctx^.Tri[ctx^.TriCount] := ctx^.V[2]; Inc(ctx^.TriCount);
     ctx^.Current := 0;
    end;
   GL_TRIANGLE_STRIP:
    begin
     ctx^.Tri[ctx^.TriCount] := ctx^.V[1]; Inc(ctx^.TriCount);
     ctx^.Tri[ctx^.TriCount] := ctx^.V[2]; Inc(ctx^.TriCount);
     ctx^.Tri[ctx^.TriCount] := ctx^.V[0]; Inc(ctx^.TriCount);
     ctx^.V[0] := ctx^.V[1];
     ctx^.V[1] := ctx^.V[2];
     ctx^.Current := 2;
    end;
   GL_TRIANGLE_FAN:
    begin
     ctx^.Tri[ctx^.TriCount] := ctx^.V[0]; Inc(ctx^.TriCount);
     ctx^.Tri[ctx^.TriCount] := ctx^.V[1]; Inc(ctx^.TriCount);
     ctx^.Tri[ctx^.TriCount] := ctx^.V[2]; Inc(ctx^.TriCount);
     ctx^.V[1] := ctx^.V[2];
     ctx^.Current := 2;
    end;
  end;
 end;

 procedure TessCombine(Coords: PDouble; VertexData: Pointer; Weight: PSingle; outData: PPointer; userData: Pointer); stdcall;
 var vd: PTessVertData;
     ctx: PTessCtx;
 begin
  outData^ := nil;
  if Coords = nil then Exit;
  ctx := PTessCtx(userData);
  GetMem(vd, SizeOf(TTessVertData));
  vd^.Coords[0] := Coords[0];
  vd^.Coords[1] := Coords[1];
  vd^.Coords[2] := Coords[2];
  vd^.V.X := Coords[0];
  vd^.V.Y := Coords[1];
  if ctx <> nil then begin
   if ctx^.AllocCount + 1 > Length(ctx^.Alloc) then SetLength(ctx^.Alloc, ctx^.AllocCount + 1024);
   ctx^.Alloc[ctx^.AllocCount] := vd;
   Inc(ctx^.AllocCount);
  end;
  outData^ := @vd^.V;
 end;

 procedure TessError(Err: Integer; userData: Pointer); stdcall;
 begin
  WriteIn(['glu tess error=', Err], nil, 9);
 end;

procedure TogsTess.Clear;
begin
 SetLength(FVertices, 0);
 SetLength(FIndices, 0);
 FSourceOgsId := 0;
 FSourceRenderOrder := 0;
end;

 constructor TogsTess.CreateAs(ogsObject: TogsBasic);
 var src: TogsTess;
 begin
  if not (ogsObject is TogsTess) then raise Exception.Create(ClassName + '.CreateAs raised type conversion exception');
  inherited CreateAs(ogsObject);
  src := TogsTess(ogsObject);
  FSourceOgsId := src.FSourceOgsId;
  FSourceRenderOrder := src.FSourceRenderOrder;
  SetLength(FVertices, Length(src.FVertices));
  if Length(FVertices) > 0 then Move(src.FVertices[0], FVertices[0], Length(FVertices) * SizeOf(FVertices[0]));
  SetLength(FIndices, Length(src.FIndices));
  if Length(FIndices) > 0 then Move(src.FIndices[0], FIndices[0], Length(FIndices) * SizeOf(FIndices[0]));
 end;

 procedure TogsTess.BuildTess(Geom: TogsGeometry);
 var tess: PGLUtesselator;
     ctx: TTessCtx;
     offX, offY: Single;
     offSet: Boolean;
     scale, invScale: Single;
     scaleSet: Boolean;
     ringVerts: array of TogsTessVertex;
     polyCount: Integer;
     i, k, j, n: Integer;
     p: TogsDot;
     p0: TogsDot;
     plast: TogsDot;
     qx, qy: Single;
     lastX, lastY: Single;
     outN: Integer;
     base: Integer;
     map: array of Integer;
     idx: Integer;
     minX, minY, maxX, maxY: Single;
     dx, dy: Double;
     minSeg2: Double;
     useLocalCoords: Boolean;

 procedure FreeVertexAllocs;
 var t: Integer;
 begin
  for t := 0 to ctx.AllocCount - 1 do
   FreeMem(ctx.Alloc[t]);
  SetLength(ctx.Alloc, 0);
  ctx.AllocCount := 0;
 end;

 procedure StartPolygon;
 begin
  FillChar(ctx, SizeOf(ctx), 0);
  SetLength(ctx.Tri, 0);
  SetLength(ctx.Alloc, 0);
  tess := gluNewTess();
  if tess = nil then Exit;
  gluTessCallback(tess, GLU_TESS_BEGIN_DATA, @TessBegin);
  gluTessCallback(tess, GLU_TESS_VERTEX_DATA, @TessVertex);
  gluTessCallback(tess, GLU_TESS_COMBINE_DATA, @TessCombine);
  gluTessCallback(tess, GLU_TESS_ERROR_DATA, @TessError);
  gluTessProperty(tess, GLU_TESS_WINDING_RULE, GLU_TESS_WINDING_ODD);
  gluTessBeginPolygon(tess, @ctx);
 end;

 procedure FinishPolygon;
 begin
  if tess = nil then Exit;
  gluTessEndPolygon(tess);
  gluDeleteTess(tess);
  tess := nil;
  FreeVertexAllocs;
 end;

 procedure AddRing(Ring: TPoly_Single);
 var vd: PTessVertData; j: Integer;
 begin
  if Ring = nil then Exit;
  n := Ring.Count;
  p0 := Ring.PointN(0);
  plast := Ring.PointN(n - 1);
  if (p0 <> nil) and (plast <> nil) then
   if useLocalCoords then begin
    if (p0.fX = plast.fX) and (p0.fY = plast.fY) then Dec(n);
   end else begin
    if (p0.X = plast.X) and (p0.Y = plast.Y) then Dec(n);
   end;
  SetLength(ringVerts, n);
  outN := 0;
  minX := 0; minY := 0; maxX := 0; maxY := 0;
  for j := 0 to n - 1 do begin
   p := Ring.PointN(j);
   if useLocalCoords then begin
    qx := p.fX;
    qy := p.fY;
   end else begin
    qx := p.X;
    qy := p.Y;
   end;
   ringVerts[outN].X := qx;
   ringVerts[outN].Y := qy;
   if outN = 0 then begin
    minX := ringVerts[outN].X; maxX := ringVerts[outN].X;
    minY := ringVerts[outN].Y; maxY := ringVerts[outN].Y;
   end else begin
    if ringVerts[outN].X < minX then minX := ringVerts[outN].X;
    if ringVerts[outN].X > maxX then maxX := ringVerts[outN].X;
    if ringVerts[outN].Y < minY then minY := ringVerts[outN].Y;
    if ringVerts[outN].Y > maxY then maxY := ringVerts[outN].Y;
   end;
   Inc(outN);
  end;
  minSeg2 := -1;
  for j := 0 to outN - 1 do begin
   dx := ringVerts[(j + 1) mod outN].X - ringVerts[j].X;
   dy := ringVerts[(j + 1) mod outN].Y - ringVerts[j].Y;
   if minSeg2 < 0 then minSeg2 := dx * dx + dy * dy
   else if dx * dx + dy * dy < minSeg2 then minSeg2 := dx * dx + dy * dy;
  end;
//  WriteIn(['glu ring n=', outN, ' bbox=', minX, ',', minY, ' .. ', maxX, ',', maxY, ' minSeg2=', minSeg2], nil, 9);
  gluTessBeginContour(tess);
  for j := 0 to outN - 1 do begin
   GetMem(vd, SizeOf(TTessVertData));
   vd^.Coords[0] := ringVerts[j].X;
   vd^.Coords[1] := ringVerts[j].Y;
   vd^.Coords[2] := 0;
   vd^.V := ringVerts[j];
   if ctx.AllocCount + 1 > Length(ctx.Alloc) then SetLength(ctx.Alloc, ctx.AllocCount + 1024);
   ctx.Alloc[ctx.AllocCount] := vd;
   Inc(ctx.AllocCount);
   gluTessVertex(tess, @vd^.Coords[0], @vd^.V);
  end;
  gluTessEndContour(tess);
 end;

 procedure AppendTriangles;
 var t, u: Integer;
 begin
  if ctx.TriCount <= 0 then Exit;
  SetLength(map, ctx.TriCount);
  base := Length(FVertices);
  for t := 0 to ctx.TriCount - 1 do begin
   idx := -1;
   for u := 0 to base - 1 do
    if (FVertices[u].X = ctx.Tri[t].X) and (FVertices[u].Y = ctx.Tri[t].Y) then begin
     idx := u;
     Break;
    end;
   if idx < 0 then begin
    idx := Length(FVertices);
    SetLength(FVertices, idx + 1);
    FVertices[idx] := ctx.Tri[t];
   end;
   map[t] := idx;
  end;
  j := Length(FIndices);
  SetLength(FIndices, j + ctx.TriCount);
  for t := 0 to ctx.TriCount - 1 do
   FIndices[j + t] := map[t];
 end;

 procedure TriangulatePolygon(Poly: TogsPolygon);
 var i, k: integer;
 begin
  if (Poly = nil) or (Poly.Count <= 0) then Exit;
  StartPolygon;
  if tess = nil then Exit;
  try
   AddRing(Poly.Polygon[0]);
   if Poly.Count > 1 then
    for k := 1 to Poly.Count - 1 do AddRing(Poly.Polygon[k]);
  finally
   FinishPolygon;
  end;
  AppendTriangles;
 end;
 begin
  Clear;
  if Geom <> nil then
  begin
   FSourceOgsId := Geom.ogsID;
   FSourceRenderOrder := Geom.RenderOrder;
  end;

 if Geom = nil then Exit;
 useLocalCoords := (Pos('FontSymbol', Geom.ClassName) > 0);
 tess := nil;
 if Geom is TogsPolygon then
  TriangulatePolygon(TogsPolygon(Geom))
 else if Geom is TogsMultiPolygon then begin
  polyCount := TogsMultiPolygon(Geom).Count;
  for k := 0 to polyCount - 1 do TriangulatePolygon(TogsMultiPolygon(Geom).Polygon[k]);
 end;
 end;

 end.
