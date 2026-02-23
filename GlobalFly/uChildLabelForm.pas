unit uChildLabelForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls, Spin;

type

  { TChildLabelForm }

  TChildLabelForm = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    ECaption: TEdit;
    EHint: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    seW: TSpinEdit;
  public
    function Execute(var ACaption, AHint: String; var ABtnWidth: Integer): Boolean;
  end;

implementation

{$R *.frm}

function TChildLabelForm.Execute(var ACaption, AHint: String; var ABtnWidth: Integer): Boolean;
begin
  if ECaption <> nil then
    ECaption.Text := ACaption;
  if EHint <> nil then
    EHint.Text := AHint;
  if seW <> nil then
    seW.Value := ABtnWidth;

  Result := ShowModal = mrOk;
  if not Result then Exit;

  if ECaption <> nil then
    ACaption := ECaption.Text;
  if EHint <> nil then
    AHint := EHint.Text;
  if seW <> nil then
    ABtnWidth := seW.Value;
end;

end.
