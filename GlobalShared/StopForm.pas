unit StopForm;

{$mode Delphi}

interface

uses
 LCLType, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

 { TStopFrm }

 TStopFrm = class(TForm)
  Button1: TButton;
  Edit1: TEdit;
  procedure Button1Click(Sender: TObject);
  procedure CreateParams(var Params : TCreateParams); override;
  procedure FormActivate(Sender: TObject);
  procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
 public

 end;

var
 StopFrm: TStopFrm;

implementation

{$R *.frm}

{ TStopFrm }

procedure TStopFrm.CreateParams(var Params: TCreateParams);
begin
 inherited CreateParams(Params);
 Params.Style := Params.Style or ws_Child;
 Params.exStyle := Params.exStyle or WS_EX_ToolWindow;
end;

procedure TStopFrm.FormActivate(Sender: TObject);
begin
 Edit1.SetFocus;
end;

procedure TStopFrm.Button1Click(Sender: TObject);
begin
 Close;
end;

procedure TStopFrm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 CloseAction := caFree;
end;

end.

