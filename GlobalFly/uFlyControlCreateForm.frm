object FlyControlCreateForm: TFlyControlCreateForm
  Left = 200
  Height = 331
  Top = 86
  Width = 360
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Новый контрол'
  ClientHeight = 331
  ClientWidth = 360
  OnCreate = FormCreate
  Position = poScreenCenter
  LCLVersion = '7.8'
  object Label1: TLabel
    Left = 12
    Height = 15
    Top = 16
    Width = 24
    Caption = 'Имя'
  end
  object EName: TEdit
    Left = 64
    Height = 23
    Top = 12
    Width = 244
    TabOrder = 0
  end
  object Label6: TLabel
    Left = 12
    Height = 15
    Top = 44
    Width = 47
    Caption = 'Надпись'
  end
  object ECaption: TEdit
    Left = 64
    Height = 23
    Top = 40
    Width = 284
    TabOrder = 1
  end
  object Label7: TLabel
    Left = 12
    Height = 15
    Top = 72
    Width = 57
    Caption = 'Подсказка'
  end
  object EHint: TEdit
    Left = 74
    Height = 23
    Top = 68
    Width = 274
    TabOrder = 2
  end
  object Label2: TLabel
    Left = 12
    Height = 15
    Top = 104
    Width = 40
    Caption = 'Размер'
  end
  object seW: TSpinEdit
    Left = 64
    Height = 23
    Top = 100
    Width = 56
    MaxValue = 64
    MinValue = 1
    TabOrder = 3
    Value = 1
  end
  object seH: TSpinEdit
    Left = 128
    Height = 23
    Top = 100
    Width = 56
    MaxValue = 64
    MinValue = 1
    TabOrder = 4
    Value = 1
  end
  object Label3: TLabel
    Left = 12
    Height = 15
    Top = 140
    Width = 20
    Caption = 'Тип'
  end
  object cbKind: TComboBox
    Left = 64
    Height = 23
    Top = 136
    Width = 241
    ItemHeight = 15
    Style = csDropDownList
    TabOrder = 5
  end
  object Label4: TLabel
    Left = 12
    Height = 15
    Top = 176
    Width = 29
    Caption = 'Глиф'
  end
  object btnSelect: TButton
    Left = 233
    Height = 23
    Top = 101
    Width = 112
    Caption = 'Short-Cut кнопка'
    OnClick = btnSelectClick
    TabOrder = 6
  end
  object ImageGlyph: TImage
    Left = 64
    Height = 64
    Top = 174
    Width = 64
    Stretch = True
  end
  object Label5: TLabel
    Left = 18
    Height = 15
    Top = 252
    Width = 27
    Caption = 'Hash'
  end
  object lblGlyphHash: TLabel
    Left = 63
    Height = 19
    Top = 252
    Width = 137
    AutoSize = False
    Caption = '-'
  end
  object btnOK: TButton
    Left = 188
    Height = 28
    Top = 284
    Width = 72
    Caption = 'OK'
    Default = True
    ModalResult = 0
    OnClick = btnOKClick
    TabOrder = 8
  end
  object btnCancel: TButton
    Left = 276
    Height = 28
    Top = 284
    Width = 72
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 7
  end
  object OpenDialog1: TOpenDialog
    Title = 'Выбор глифа'
    Filter = 'Images|*.bmp;*.png;*.jpg;*.jpeg;*.gif|All files|*.*'
    Left = 24
    Top = 344
  end
end
