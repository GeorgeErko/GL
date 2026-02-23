object PrimitiveCreateForm: TPrimitiveCreateForm
  Left = 450
  Height = 320
  Top = 250
  Width = 420
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Новый элемент'
  ClientHeight = 320
  ClientWidth = 420
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
    Left = 84
    Height = 23
    Top = 12
    Width = 320
    TabOrder = 0
  end
  object Label2: TLabel
    Left = 12
    Height = 15
    Top = 48
    Width = 68
    Caption = 'Заголовок'
  end
  object EText: TEdit
    Left = 84
    Height = 23
    Top = 44
    Width = 320
    TabOrder = 1
  end
  object Label3: TLabel
    Left = 12
    Height = 15
    Top = 80
    Width = 91
    Caption = 'Элементы списка'
  end
  object MemoItems: TMemo
    Left = 12
    Height = 108
    Top = 100
    Width = 392
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object Label4: TLabel
    Left = 12
    Height = 15
    Top = 216
    Width = 36
    Caption = 'Глиф'
  end
  object EGlyphFile: TEdit
    Left = 84
    Height = 23
    Top = 212
    Width = 284
    TabOrder = 3
  end
  object btnGlyph: TButton
    Left = 376
    Height = 23
    Top = 212
    Width = 28
    Caption = '...'
    OnClick = btnGlyphClick
    TabOrder = 4
  end
  object ImageGlyph: TImage
    Left = 84
    Height = 64
    Top = 244
    Width = 64
    Stretch = True
  end
  object lblGlyphHash: TLabel
    Left = 156
    Height = 15
    Top = 244
    Width = 10
    Caption = ''
  end
  object btnOK: TButton
    Left = 252
    Height = 28
    Top = 284
    Width = 72
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 332
    Height = 28
    Top = 284
    Width = 72
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Images|*.bmp;*.png;*.jpg;*.jpeg;*.gif|All files|*.*'
    Title = 'Выбор глифа'
    Left = 12
    Top = 280
  end
end
