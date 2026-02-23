object frmVFLineTester: TfrmVFLineTester
  Left = 300
  Height = 466
  Top = 200
  Width = 640
  Caption = 'Тестирование типа линии'
  ClientHeight = 466
  ClientWidth = 640
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  Position = poScreenCenter
  LCLVersion = '7.8'
  object lblThickness: TLabel
    Left = 16
    Height = 15
    Top = 16
    Width = 75
    Caption = 'Толщина (px)'
  end
  object edtThickness: TEdit
    Left = 16
    Height = 23
    Top = 36
    Width = 120
    TabOrder = 0
    Text = '14'
  end
  object btnCreateStyle: TButton
    Left = 152
    Height = 25
    Top = 36
    Width = 140
    Caption = 'Создать стиль'
    OnClick = btnCreateStyleClick
    TabOrder = 1
  end
  object lblDash: TLabel
    Left = 312
    Height = 15
    Top = 16
    Width = 60
    Caption = 'Штрих (px)'
  end
  object edtDash: TEdit
    Left = 312
    Height = 23
    Top = 36
    Width = 80
    TabOrder = 2
    Text = '30'
  end
  object lblGap: TLabel
    Left = 400
    Height = 15
    Top = 16
    Width = 67
    Caption = 'Пробел (px)'
  end
  object edtGap: TEdit
    Left = 400
    Height = 23
    Top = 36
    Width = 80
    TabOrder = 3
    Text = '12'
  end
  object lblDashOffset: TLabel
    Left = 488
    Height = 15
    Top = 16
    Width = 60
    Caption = 'Смещение'
  end
  object edtDashOffset: TEdit
    Left = 488
    Height = 23
    Top = 36
    Width = 80
    TabOrder = 4
    Text = '0'
  end
  object lblTrimStart: TLabel
    Left = 16
    Height = 15
    Top = 64
    Width = 82
    Caption = 'Отсечь начало'
  end
  object edtTrimStart: TEdit
    Left = 16
    Height = 23
    Top = 84
    Width = 80
    TabOrder = 5
    Text = '0'
  end
  object lblTrimEnd: TLabel
    Left = 104
    Height = 15
    Top = 64
    Width = 75
    Caption = 'Отсечь конец'
  end
  object edtTrimEnd: TEdit
    Left = 104
    Height = 23
    Top = 84
    Width = 80
    TabOrder = 6
    Text = '0'
  end
  object btnInitDashed: TButton
    Left = 200
    Height = 25
    Top = 84
    Width = 180
    Caption = 'Инициализировать пунктир'
    OnClick = btnInitDashedClick
    TabOrder = 7
  end
  object btnPythonLib: TButton
    Left = 400
    Height = 25
    Top = 84
    Width = 120
    Caption = 'PythonLib'
    OnClick = btnPythonLibClick
    TabOrder = 8
  end
  object lblHint: TLabel
    Left = 16
    Height = 15
    Top = 116
    Width = 329
    Caption = 'ЛКМ — задавать точки; ПКМ — завершить текущую линию'
  end
  object pbPreview: TPaintBox
    Left = 16
    Height = 310
    Top = 144
    Width = 608
    Anchors = [akTop, akLeft, akRight, akBottom]
    OnMouseDown = pbPreviewMouseDown
    OnPaint = pbPreviewPaint
  end
end
