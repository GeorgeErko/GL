object ChildComboBoxForm: TChildComboBoxForm
  Left = 450
  Height = 268
  Top = 260
  Width = 380
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'TComboBox'
  ClientHeight = 268
  ClientWidth = 380
  Position = poScreenCenter
  LCLVersion = '7.8'
  object Label1: TLabel
    Left = 12
    Height = 15
    Top = 16
    Width = 135
    Caption = 'Элементы (через ; )'
  end
  object EItems: TEdit
    Left = 12
    Height = 23
    Top = 36
    Width = 352
    TabOrder = 0
  end
  object Label2: TLabel
    Left = 12
    Height = 15
    Top = 72
    Width = 57
    Caption = 'Подсказка'
  end
  object EHint: TEdit
    Left = 12
    Height = 23
    Top = 92
    Width = 352
    TabOrder = 1
  end
  object Label3: TLabel
    Left = 12
    Height = 15
    Top = 128
    Width = 58
    Caption = 'btnWidth'
  end
  object seW: TSpinEdit
    Left = 76
    Height = 23
    Top = 124
    Width = 100
    MaxValue = 2000
    MinValue = 1
    TabOrder = 2
    Value = 6
  end
  object btnOK: TButton
    Left = 212
    Height = 28
    Top = 224
    Width = 72
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 296
    Height = 28
    Top = 224
    Width = 72
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
