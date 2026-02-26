unit uMap2D2RenderForm;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, uMap2DRenderForm, ogcDrawerOGL,
 ogcDrawerOGL2;

type

 { TMap2D2RenderForm }

 TMap2D2RenderForm = class(TMap2DRenderForm)
  sbMode: TSpeedButton;
  sbBlocks: TSpeedButton;
  sbText: TSpeedButton;
  procedure sbModeClick(Sender: TObject);
 private
  procedure BuildSceneMode;
 protected
  function CreateDrawer: TDrawerOGL; override;
  procedure FormCreate(Sender: TObject);
  procedure BuildScene; override;
 end;

var
 Map2D2RenderForm: TMap2D2RenderForm;

implementation

{$R *.frm}

function TMap2D2RenderForm.CreateDrawer: TDrawerOGL;
begin
 Result := TDrawerOGL2.Create(nil, OpenGLPanel1, @OpenGLPanel1Paint);
end;

procedure TMap2D2RenderForm.FormCreate(Sender: TObject);
begin
 inherited FormCreate(Sender);
 sbModeClick(nil);
end;

procedure TMap2D2RenderForm.BuildSceneMode;
begin
 inherited BuildScene;
end;

procedure TMap2D2RenderForm.sbModeClick(Sender: TObject);
var d2: TDrawerOGL2;
begin
 RenderBlocks := sbBlocks.Down;
 RenderText := sbText.Down;

 d2 := TDrawerOGL2(Drawer);
 d2.GlyphCacheEnabled := sbMode.Down;

 ClearDrawerScene;
 MarkSceneDirty;
 if OpenGLPanel1 <> nil then OpenGLPanel1.Invalidate;
end;


procedure TMap2D2RenderForm.BuildScene;
var d2: TDrawerOGL2;
begin
 RenderBlocks := sbBlocks.Down;
 RenderText := sbText.Down;

 d2 := TDrawerOGL2(Drawer);
 d2.GlyphCacheEnabled := sbMode.Down;

 inherited BuildScene;
end;

end.

