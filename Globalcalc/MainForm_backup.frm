inherited frmCalculator: TfrmCalculator
  Caption = 'Калькулятор'
  ClientHeight = 320
  ClientWidth = 300
  PixelsPerInch = 96
  TextHeight = 13
  object edtDisplay: TEdit
    Left = 10
    Top = 10
    Width = 280
    Height = 40
    Alignment = taRightJustify
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Tahoma'
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
    Text = '0'
  end
  object btn7: TButton
    Left = 10
    Top = 60
    Width = 50
    Height = 50
    Caption = '7'
    TabOrder = 1
    OnClick = NumberClick
  end
  object btn8: TButton
    Left = 70
    Top = 60
    Width = 50
    Height = 50
    Caption = '8'
    TabOrder = 2
    OnClick = NumberClick
  end
  object btn9: TButton
    Left = 130
    Top = 60
    Width = 50
    Height = 50
    Caption = '9'
    TabOrder = 3
    OnClick = NumberClick
  end
  object btnDivide: TButton
    Left = 190
    Top = 60
    Width = 50
    Height = 50
    Caption = '/'
    TabOrder = 4
    OnClick = OperationClick
  end
  object btnClear: TButton
    Left = 250
    Top = 60
    Width = 40
    Height = 50
    Caption = 'C'
    TabOrder = 5
    OnClick = btnClearClick
  end
  object btn4: TButton
    Left = 10
    Top = 120
    Width = 50
    Height = 50
    Caption = '4'
    TabOrder = 6
    OnClick = NumberClick
  end
  object btn5: TButton
    Left = 70
    Top = 120
    Width = 50
    Height = 50
    Caption = '5'
    TabOrder = 7
    OnClick = NumberClick
  end
  object btn6: TButton
    Left = 130
    Top = 120
    Width = 50
    Height = 50
    Caption = '6'
    TabOrder = 8
    OnClick = NumberClick
  end
  object btnMultiply: TButton
    Left = 190
    Top = 120
    Width = 50
    Height = 50
    Caption = '*'
    TabOrder = 9
    OnClick = OperationClick
  end
  object btnSqrt: TButton
    Left = 250
    Top = 120
    Width = 40
    Height = 50
    Caption = '√'
    TabOrder = 10
    OnClick = btnSqrtClick
  end
  object btn1: TButton
    Left = 10
    Top = 180
    Width = 50
    Height = 50
    Caption = '1'
    TabOrder = 11
    OnClick = NumberClick
  end
  object btn2: TButton
    Left = 70
    Top = 180
    Width = 50
    Height = 50
    Caption = '2'
    TabOrder = 12
    OnClick = NumberClick
  end
  object btn3: TButton
    Left = 130
    Top = 180
    Width = 50
    Height = 50
    Caption = '3'
    TabOrder = 13
    OnClick = NumberClick
  end
  object btnMinus: TButton
    Left = 190
    Top = 180
    Width = 50
    Height = 50
    Caption = '-'
    TabOrder = 14
    OnClick = OperationClick
  end
  object btnPercent: TButton
    Left = 250
    Top = 180
    Width = 40
    Height = 50
    Caption = '%'
    TabOrder = 15
    OnClick = btnPercentClick
  end
  object btn0: TButton
    Left = 10
    Top = 240
    Width = 110
    Height = 50
    Caption = '0'
    TabOrder = 16
    OnClick = NumberClick
  end
  object btnDecimal: TButton
    Left = 130
    Top = 240
    Width = 50
    Height = 50
    Caption = '.'
    TabOrder = 17
    OnClick = btnDecimalClick
  end
  object btnEquals: TButton
    Left = 190
    Top = 240
    Width = 50
    Height = 50
    Caption = '='
    TabOrder = 18
    OnClick = btnEqualsClick
  end
  object btnPlus: TButton
    Left = 250
    Top = 240
    Width = 40
    Height = 50
    Caption = '+'
    TabOrder = 19
    OnClick = OperationClick
  end
end
