object DemoForm: TDemoForm
  Left = 271
  Height = 599
  Top = 0
  Width = 953
  Caption = 'DemoForm'
  ClientHeight = 599
  ClientWidth = 953
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  Position = poScreenCenter
  LCLVersion = '7.8'
  object Image1: TPaintBox
    Left = 296
    Height = 505
    Top = 16
    Width = 529
    Anchors = [akTop, akLeft, akRight, akBottom]
    Color = clBlack
    ParentColor = False
    OnDblClick = Image1DblClick
    OnMouseDown = Image1MouseDown
    OnMouseLeave = Image1MouseLeave
    OnMouseMove = Image1MouseMove
    OnMouseUp = Image1MouseUp
    OnMouseWheel = Image1MouseWheel
    OnMouseWheelLeft = Image1MouseWheelDown
    OnPaint = Image1Paint
  end
  object Button1: TButton
    Left = 850
    Height = 25
    Top = 8
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'Console'
    TabOrder = 0
  end
  object Button2: TButton
    Left = 849
    Height = 25
    Top = 40
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'Repaint'
    OnClick = Button2Click
    TabOrder = 1
  end
  object up: TButton
    Left = 850
    Height = 26
    Top = 112
    Width = 72
    Anchors = [akTop, akRight]
    Caption = 'up'
    OnClick = upClick
    TabOrder = 2
  end
  object right: TButton
    Left = 890
    Height = 26
    Top = 140
    Width = 60
    Anchors = [akTop, akRight]
    Caption = 'right'
    OnClick = upClick
    TabOrder = 3
  end
  object left: TButton
    Left = 829
    Height = 26
    Top = 140
    Width = 56
    Anchors = [akTop, akRight]
    Caption = 'left'
    OnClick = upClick
    TabOrder = 4
  end
  object down: TButton
    Left = 853
    Height = 26
    Top = 168
    Width = 72
    Anchors = [akTop, akRight]
    Caption = 'down'
    OnClick = upClick
    TabOrder = 5
  end
  object plus: TButton
    Left = 850
    Height = 25
    Top = 224
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'plus'
    OnClick = minusClick
    TabOrder = 6
  end
  object minus: TButton
    Left = 849
    Height = 25
    Top = 256
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'minus'
    OnClick = minusClick
    TabOrder = 7
  end
  object btnImage32: TButton
    Left = 847
    Height = 25
    Top = 299
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'Image32'
    OnClick = btnImage32Click
    TabOrder = 8
  end
  object btnCanvas: TButton
    Left = 847
    Height = 25
    Top = 332
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'stdCanvas'
    OnClick = btnCanvasClick
    TabOrder = 9
  end
  object GLCanvas: TButton
    Left = 847
    Height = 25
    Top = 363
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'glCanvas'
    OnClick = GLCanvasClick
    TabOrder = 10
  end
  object btnLoadGMF: TButton
    Left = 8
    Height = 26
    Top = 561
    Width = 147
    Anchors = [akLeft, akBottom]
    Caption = 'btnLoadGMF'
    OnClick = btnLoadGMFClick
    TabOrder = 11
  end
  object Store: TButton
    Left = 847
    Height = 25
    Top = 407
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'Store'
    OnClick = StoreClick
    TabOrder = 12
  end
  object Load: TButton
    Left = 847
    Height = 25
    Top = 442
    Width = 75
    Anchors = [akTop, akRight]
    Caption = 'Load'
    OnClick = LoadClick
    TabOrder = 13
  end
  object CheckBox1: TCheckBox
    Left = 720
    Height = 19
    Top = 528
    Width = 99
    Anchors = [akRight, akBottom]
    Caption = 'disable console'
    OnClick = CheckBox1Click
    TabOrder = 14
  end
  object bJSON: TButton
    Left = 176
    Height = 25
    Top = 562
    Width = 120
    Anchors = [akLeft, akBottom]
    Caption = 'LoadJSON'
    OnClick = bJSONClick
    TabOrder = 15
  end
  object Label1: TLabel
    Left = 850
    Height = 15
    Top = 488
    Width = 63
    Alignment = taCenter
    Anchors = [akRight, akBottom]
    AutoSize = False
    Caption = 'Label1'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 8
    Height = 15
    Top = 533
    Width = 62
    Anchors = [akLeft, akBottom]
    Caption = 'Geoscheme'
  end
  object Edit1: TEdit
    Left = 79
    Height = 23
    Top = 528
    Width = 505
    Anchors = [akLeft, akBottom]
    TabOrder = 16
  end
  object OGLC: TOpenGLCanvas
    Left = 304
    Height = 120
    Top = 24
    Width = 120
    Caption = 'OGLC'
    Color = clBtnFace
    ParentColor = False
    TabOrder = 17
    TabStop = False
    Visible = False
    UseDockManager = False
    OnMouseMove = Image1MouseMove
    OnMouseUp = Image1MouseUp
    OnMouseWheel = OGLCMouseWheel
    OnMouseWheelDown = Image1MouseWheelDown
  end
  object VLE: TValueListEditor
    Left = 5
    Height = 432
    Top = 16
    Width = 280
    Color = clBtnFace
    FixedCols = 0
    RowCount = 10
    TabOrder = 18
    Strings.Strings = (
      ''
      ''
      ''
      ''
      ''
      ''
      ''
      ''
      ''
    )
    ColWidths = (
      64
      216
    )
  end
  object JSONView: TVirtualJSONInspector
    Left = 8
    Height = 65
    Top = 456
    Width = 277
    PropertyDefs = <>
    Header.AutoSizeIndex = -1
    Header.Columns = <    
      item
        Position = 0
        Text = 'Property'
        Width = 150
      end    
      item
        Position = 1
        Text = 'Value'
        Width = 123
      end>
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible, hoAutoSpring]
    TabOrder = 19
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSort, toAutoSpanColumns, toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toEditable, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toHideFocusRect, toPopupMode, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages]
    TreeOptions.SelectionOptions = [toExtendedFocus]
  end
  object Button3: TButton
    Left = 320
    Height = 25
    Top = 562
    Width = 75
    Anchors = [akLeft, akBottom]
    Caption = 'SaveText'
    OnClick = Button3Click
    TabOrder = 20
  end
  object Label3: TLabel
    Left = 600
    Height = 15
    Top = 568
    Width = 34
    Anchors = [akRight, akBottom]
    Caption = 'Label3'
  end
  object Button4: TButton
    Left = 853
    Height = 25
    Top = 555
    Width = 75
    Caption = 'Button4'
    OnClick = Button4Click
    TabOrder = 21
  end
  object CheckBox2: TCheckBox
    Left = 720
    Height = 19
    Top = 552
    Width = 94
    Anchors = [akRight, akBottom]
    Caption = 'disable drawer'
    OnChange = CheckBox2Change
    OnClick = CheckBox2Click
    TabOrder = 22
  end
  object ImageList1: TImageList
    Left = 189
    Top = 88
    Bitmap = {
      4C7A020000001000000010000000580100000000000078DA3B70E000C3012AE3
      458B16696CDFBE9DA7A4A4241584274D9A645B5B5B1B49AC7E90DE7DFBF631AF
      5CB9520E84376DDA24B466CD1A2962F583EC04E9636760F8AF00C43E3E3EB3C4
      C4C41E92AA5F07A8771711FAD1FDEBE6E6B6282D2DAD1CA65F4F4FEF102F2FEF
      5B5CE181EE5F90DEA953A75AC2F43B3B3B2F131111798A2B3C90FDAB83840381
      F8189A18B6F080E95780DA07C320BD6FD1C43AB0E807F907E42690380883FC0B
      7233CCFD727272D73939393FC3E4ABAAAA62A3A2A23A60FA416101F20FC84C10
      068515C8BF30FD20BD4C4C4C7F60F220BDDADADAC7A8157FB8F42BE0F02F218C
      1E1EE8FE2584D1C383907F29C1FF47E1A0810C8CDDFF89C1B8F44EDBF8FFBF67
      DAFFFFDE79509CFBE3BF4FEE27207EFDDF36EED17F93D03BFF4D226F62350324
      669F09141601621910FEF59F41FA1D103FFACF207503C83F03C487FE33C8EFC1
      EB0672DD3F0A07060200C85CE560
    }
  end
end
