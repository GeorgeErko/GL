object ChildLabelForm: TChildLabelForm
  Left = 450
  Height = 236
  Top = 260
  Width = 360
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'TLabel'
  ClientHeight = 236
  ClientWidth = 360
  Position = poScreenCenter
  LCLVersion = '7.8'
  object Label1: TLabel
    Left = 12
    Height = 15
    Top = 16
    Width = 47
    Caption = 'Надпись'
  end
  object ECaption: TEdit
    Left = 84
    Height = 23
    Top = 12
    Width = 252
    TabOrder = 0
  end
  object Label2: TLabel
    Left = 12
    Height = 15
    Top = 48
    Width = 57
    Caption = 'Подсказка'
  end
  object EHint: TEdit
    Left = 84
    Height = 23
    Top = 44
    Width = 252
    TabOrder = 1
  end
  object Label3: TLabel
    Left = 12
    Height = 15
    Top = 80
    Width = 58
    Caption = 'btnWidth'
  end
  object seW: TSpinEdit
    Left = 84
    Height = 23
    Top = 76
    Width = 100
    MaxValue = 2000
    MinValue = 1
    TabOrder = 2
    Value = 4
  end
  object btnOK: TButton
    Left = 192
    Height = 28
    Top = 176
    Width = 72
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 276
    Height = 28
    Top = 176
    Width = 72
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
