inherited Form1: TForm1
  Left = 343
  Height = 665
  Top = 114
  Width = 940
  Caption = 'Form1'
  ClientHeight = 645
  ClientWidth = 940
  Menu = MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  inherited Image1: TPaintBox
    Height = 543
    Width = 516
    Color = clDefault
  end
  inherited Button1: TButton
    Left = 837
    OnClick = Button1Click
  end
  inherited Button2: TButton
    Left = 837
  end
  inherited up: TButton
    Left = 837
  end
  inherited right: TButton
    Left = 877
  end
  inherited left: TButton
    Left = 816
  end
  inherited down: TButton
    Left = 840
  end
  inherited plus: TButton
    Left = 837
  end
  inherited minus: TButton
    Left = 836
  end
  inherited btnImage32: TButton
    Left = 834
  end
  inherited btnCanvas: TButton
    Left = 834
  end
  inherited GLCanvas: TButton
    Left = 834
  end
  inherited btnLoadGMF: TButton
    Left = 7
    Top = 604
    OnClick = btnLoadGMFClick
  end
  inherited Store: TButton
    Left = 834
  end
  inherited Load: TButton
    Left = 834
  end
  inherited CheckBox1: TCheckBox
    Left = 707
    Top = 573
  end
  inherited bJSON: TButton
    Left = 167
    Top = 605
  end
  inherited Label1: TLabel
    Left = 837
    Top = 534
  end
  inherited Label2: TLabel
    Left = 7
    Top = 577
  end
  inherited Edit1: TEdit
    Left = 78
    Top = 572
  end
  inherited VLE: TValueListEditor
    Height = 472
    Anchors = [akTop, akLeft, akBottom]
  end
  inherited JSONView: TVirtualJSONInspector
    Left = 5
    Height = 33
    Top = 528
    Anchors = [akLeft, akBottom]
  end
  inherited Button3: TButton
    Left = 295
    Top = 605
    OnClick = Button3Click
  end
  inherited Label3: TLabel
    Left = 811
    Top = 620
  end
  inherited Button4: TButton
    Left = 836
    Top = 588
    Anchors = [akRight, akBottom]
  end
  inherited CheckBox2: TCheckBox
    Left = 719
    Top = 591
    TabOrder = 24
  end
  object Button5: TButton[27]
    Left = 837
    Height = 25
    Top = 72
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'Load'
    OnClick = Button5Click
    TabOrder = 22
  end
  object Edit2: TEdit[28]
    Left = 391
    Height = 23
    Top = 607
    Width = 56
    Anchors = [akLeft, akBottom]
    TabOrder = 23
    Text = 'ТестN'
  end
  object Button6: TButton[29]
    Left = 503
    Height = 25
    Top = 607
    Width = 75
    Anchors = [akLeft, akBottom]
    Caption = 'Counter'
    OnClick = Button6Click
    TabOrder = 25
  end
  object Button7: TButton[30]
    Left = 591
    Height = 25
    Top = 607
    Width = 75
    Anchors = [akLeft, akBottom]
    Caption = 'Load'
    OnClick = Button7Click
    TabOrder = 26
  end
  object Button8: TButton[31]
    Left = 5
    Height = 25
    Top = 496
    Width = 75
    Caption = 'Props'
    OnClick = Button8Click
    TabOrder = 27
  end
  object Button9: TButton[32]
    Left = 453
    Height = 24
    Top = 606
    Width = 21
    Caption = 'Button9'
    OnClick = Button9Click
    TabOrder = 28
  end
  inherited ImageList1: TImageList[33]
    Left = 704
    Top = 96
  end
  object OD: TOpenDialog[34]
    Filter = '*.gmf'
    Left = 752
    Top = 96
  end
  object MainMenu1: TMainMenu[35]
    Left = 132
    Top = 68
    object MenuItem1: TMenuItem
      Caption = 'Memory'
      object MImemStart: TMenuItem
        Caption = 'memStart'
      end
      object MIMemFinish: TMenuItem
        Caption = 'MIMemFinish'
      end
    end
  end
end
