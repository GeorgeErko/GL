object BitHashItemCreateForm: TBitHashItemCreateForm
  Left = 457
  Height = 320
  Top = 257
  Width = 420
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Новая кнопка'
  ClientHeight = 320
  ClientWidth = 420
  OnCreate = FormCreate
  Position = poScreenCenter
  LCLVersion = '7.8'
  object Label1: TLabel
    Left = 12
    Height = 15
    Top = 16
    Width = 39
    Caption = 'Группа'
  end
  object Label2: TLabel
    Left = 12
    Height = 15
    Top = 48
    Width = 24
    Caption = 'Имя'
  end
  object ECaption: TEdit
    Left = 72
    Height = 23
    Top = 44
    Width = 332
    TabOrder = 0
  end
  object Label3: TLabel
    Left = 12
    Height = 15
    Top = 80
    Width = 57
    Caption = 'Подсказка'
  end
  object EHint: TEdit
    Left = 72
    Height = 23
    Top = 76
    Width = 332
    TabOrder = 1
  end
  object Label4: TLabel
    Left = 12
    Height = 15
    Top = 112
    Width = 39
    Caption = 'HotKey'
  end
  object EHotKey: TEdit
    Left = 72
    Height = 23
    Top = 108
    Width = 332
    OnKeyDown = EHotKeyKeyDown
    OnKeyPress = EHotKeyKeyPress
    TabOrder = 2
  end
  object Label5: TLabel
    Left = 12
    Height = 15
    Top = 144
    Width = 29
    Caption = 'Глиф'
  end
  object btnGlyph: TButton
    Left = 372
    Height = 23
    Top = 140
    Width = 32
    Caption = '...'
    OnClick = btnGlyphClick
    TabOrder = 3
  end
  object ImageGlyph: TImage
    Left = 72
    Height = 64
    Top = 140
    Width = 64
    Stretch = True
  end
  object lblGlyphHash: TLabel
    Left = 148
    Height = 1
    Top = 140
    Width = 1
  end
  object btnOK: TButton
    Left = 252
    Height = 28
    Top = 280
    Width = 72
    Caption = 'OK'
    Default = True
    OnClick = btnOKClick
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 332
    Height = 28
    Top = 280
    Width = 72
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
  object cbGroup: TComboBox
    Left = 73
    Height = 23
    Top = 12
    Width = 305
    ItemHeight = 15
    TabOrder = 6
  end
  object SpeedButton2: TSpeedButton
    Left = 382
    Height = 22
    Top = 12
    Width = 23
    Glyph.Data = {
      8E010000424D90010000000000008E0000002800000010000000100000000100
      08000000000000000000120B0000120B0000160000001600000000000000FFFF
      FF00FF00FF00FDFDFD00DADADA00D9D9D900D8D8D800D6D6D600D4D4D400D3D3
      D300C8C8C800C0C0C000BFBFBF00A7A7A700A5A5A500A1A1A1009C9C9C009898
      980094949400909090008D8D8D00797979000202020202020202020202020202
      0202020202020202020202020202020202020202020202020202020202020202
      0202020202020202020202020202020202020202020202020202020202020202
      0202020202020202020202020202020202020202021515151515151515151502
      0202020215080D0D0E0F1011121314150202020215030504040607090A0B0C15
      0202020202151515151515151515150202020202020202020202020202020202
      0202020202020202020202020202020202020202020202020202020202020202
      0202020202020202020202020202020202020202020202020202020202020202
      020202020202020202020202020202020202
    }
  end
  object OpenDialog1: TOpenDialog
    Title = 'Выбор глифа'
    Filter = 'Images|*.bmp;*.png;*.jpg;*.jpeg;*.gif|All files|*.*'
    Left = 24
    Top = 272
  end
end
