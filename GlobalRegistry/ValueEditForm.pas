unit ValueEditForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type
  { TValueEditForm }

  TValueEditForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    EditName: TEdit;
    EditValue: TEdit;
    RadioGroupType: TRadioGroup;
    ButtonOK: TButton;
    ButtonCancel: TButton;
    procedure FormCreate(Sender: TObject);
  public
  end;

var
  ValueEditForm_: TValueEditForm;

implementation

{$R *.frm}

{ TValueEditForm }

procedure TValueEditForm.FormCreate(Sender: TObject);
begin
  RadioGroupType.Items.Add('None');
  RadioGroupType.Items.Add('Integer');
  RadioGroupType.Items.Add('Float');
  RadioGroupType.Items.Add('Boolean');
  RadioGroupType.Items.Add('String');
  RadioGroupType.Items.Add('Color');
  RadioGroupType.ItemIndex := 4; // String по умолчанию
end;

end.
