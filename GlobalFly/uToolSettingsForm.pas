unit uToolSettingsForm;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin;

type

 { TToolSettingsForm }

 TToolSettingsForm = class(TForm)
  btnCancel: TButton;
  btnOK: TButton;
  cbLeft: TCheckBox;
  cbTop: TCheckBox;
  cbRight: TCheckBox;
  cbBottom: TCheckBox;
  EName: TEdit;
  gbTool: TGroupBox;
  gbHPanel: TGroupBox;
  gbVPanel: TGroupBox;
  GroupBox1: TGroupBox;
  Label1: TLabel;
  Label2: TLabel;
  lblToolW: TLabel;
  lblToolH: TLabel;
  lblHW: TLabel;
  lblHH: TLabel;
  lblVW: TLabel;
  lblVH: TLabel;
  seToolW: TSpinEdit;
  seToolH: TSpinEdit;
  seHW: TSpinEdit;
  seHH: TSpinEdit;
  seVW: TSpinEdit;
  seVH: TSpinEdit;
  procedure cbTopChange(Sender: TObject);
 public
  function Execute(var Nm: String; var ToolW, ToolH, HPanelW, HPanelH,
                    VPanelW, VPanelH: Integer; var pL, pT, pR, pB: Boolean): Boolean;
 end;

var
 ToolSettingsForm: TToolSettingsForm;

implementation

{$R *.frm}

procedure TToolSettingsForm.cbTopChange(Sender: TObject);
begin

end;

function TToolSettingsForm.Execute(var Nm: String; var ToolW, ToolH, HPanelW,
 HPanelH, VPanelW, VPanelH: Integer; var pL, pT, pR, pB: Boolean): Boolean;
begin
 EName.Text := Nm;
 seToolW.Value := ToolW;
 seToolH.Value := ToolH;
 seHW.Value := HPanelW;
 seHH.Value := HPanelH;
 seVW.Value := VPanelW;
 seVH.Value := VPanelH;
 cbLeft.Checked := pL; cbTop.Checked := pT;
 cbRight.Checked := pR; cbBottom.Checked := pB;
 Result := ShowModal = mrOk;
 if not Result then Exit;
 Nm := ENAme.Text;
 ToolW := seToolW.Value;
 ToolH := seToolH.Value;
 HPanelW := seHW.Value;
 HPanelH := seHH.Value;
 VPanelW := seVW.Value;
 VPanelH := seVH.Value;
 pL := cbLeft.Checked; pT := cbTop.Checked;
 pR := cbRight.Checked; pB := cbBottom.Checked;
end;

end.
