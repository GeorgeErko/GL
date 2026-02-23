inherited FormTTF: TFormTTF
  Height = 651
  Width = 909
  Caption = 'FormTTF'
  ClientHeight = 651
  ClientWidth = 909
  inherited Image1: TPaintBox
    Height = 507
    Width = 485
  end
  inherited Button1: TButton
    Left = 806
  end
  inherited Button2: TButton
    Left = 806
  end
  inherited up: TButton
    Left = 806
  end
  inherited right: TButton
    Left = 846
  end
  inherited left: TButton
    Left = 785
  end
  inherited down: TButton
    Left = 809
  end
  inherited plus: TButton
    Left = 806
  end
  inherited minus: TButton
    Left = 805
  end
  inherited btnImage32: TButton
    Left = 803
  end
  inherited btnCanvas: TButton
    Left = 803
  end
  inherited GLCanvas: TButton
    Left = 803
  end
  inherited btnLoadGMF: TButton
    Top = 610
    Anchors = [akLeft]
  end
  inherited Store: TButton
    Left = 803
  end
  inherited Load: TButton
    Left = 803
  end
  inherited CheckBox1: TCheckBox
    Left = 651
    Top = 577
    Anchors = [akLeft]
  end
  inherited bJSON: TButton
    Left = 176
    Top = 612
    Anchors = [akLeft]
  end
  inherited Label1: TLabel
    Left = 806
    Top = 508
    Anchors = [akRight]
  end
  inherited Label2: TLabel
    Top = 581
    Anchors = [akLeft]
  end
  inherited Edit1: TEdit
    Top = 576
    Anchors = [akLeft]
  end
  inherited VLE: TValueListEditor
    Height = 72
  end
  inherited JSONView: TVirtualJSONInspector
    Height = 425
    Top = 96
  end
  inherited Button3: TButton
    Left = 320
    Top = 612
    Anchors = [akLeft]
  end
  inherited Label3: TLabel
    Left = 579
    Top = 618
    Anchors = [akLeft]
  end
  inherited Button4: TButton
    Left = 805
    Top = 600
    Anchors = [akLeft]
  end
  inherited Button5: TButton
    Left = 806
  end
  object Button6: TButton[27]
    Left = 13
    Height = 25
    Top = 538
    Width = 91
    Caption = 'TT FLoad'
    OnClick = Button6Click
    TabOrder = 23
  end
  object Label4: TLabel[28]
    Left = 121
    Height = 15
    Top = 544
    Width = 40
    Caption = 'Symbol'
  end
  object Edit2: TEdit[29]
    Left = 169
    Height = 23
    Top = 541
    Width = 80
    OnChange = Edit2Change
    TabOrder = 24
    Text = 'A'
  end
  object Index: TLabel[30]
    Left = 264
    Height = 15
    Top = 544
    Width = 35
    Caption = 'LIndex'
  end
  object Edit3: TEdit[31]
    Left = 304
    Height = 23
    Top = 540
    Width = 80
    OnChange = Edit2Change
    TabOrder = 25
  end
  inherited ImageList1: TImageList[32]
  end
  inherited OD: TOpenDialog[33]
  end
  object FontDlg: TOpenDialog[34]
    DefaultExt = '.*.ttf'
    Filter = '*.ttf|*.ttf'
    Left = 167
    Top = 293
  end
end
