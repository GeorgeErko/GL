object MainFrm: TMainFrm
  Left = 343
  Height = 543
  Top = 257
  Width = 939
  Caption = 'MainFrm'
  ClientHeight = 543
  ClientWidth = 939
  OnChangeBounds = FormChangeBounds
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  LCLVersion = '7.8'
  object SpkToolbar1: TSpkToolbar
    Left = 0
    Height = 112
    Top = 0
    Width = 939
    Color = clSilver
    Style = spkOffice2007Silver
    Appearance.Tab.TabHeaderFont.Color = 8016716
    Appearance.Tab.BorderColor = 12500670
    Appearance.Tab.CornerRadius = 4
    Appearance.Tab.GradientFromColor = 16052978
    Appearance.Tab.GradientToColor = 15722209
    Appearance.Tab.GradientType = bkConcave
    Appearance.Tab.InactiveTabHeaderFontColor = 8016716
    Appearance.MenuButton.CaptionFont.Color = clWhite
    Appearance.MenuButton.IdleFrameColor = 10569759
    Appearance.MenuButton.IdleGradientFromColor = 14649927
    Appearance.MenuButton.IdleGradientToColor = 12017961
    Appearance.MenuButton.IdleGradientType = bkConcave
    Appearance.MenuButton.IdleCaptionColor = clWhite
    Appearance.MenuButton.HotTrackFrameColor = 10569759
    Appearance.MenuButton.HotTrackGradientFromColor = 15179099
    Appearance.MenuButton.HotTrackGradientToColor = 12478257
    Appearance.MenuButton.HotTrackGradientType = bkConcave
    Appearance.MenuButton.HotTrackCaptionColor = clWhite
    Appearance.MenuButton.HotTrackBrightnessChange = 40
    Appearance.MenuButton.ActiveFrameColor = 11095324
    Appearance.MenuButton.ActiveGradientFromColor = 14518846
    Appearance.MenuButton.ActiveGradientToColor = 12411174
    Appearance.MenuButton.ActiveGradientType = bkConcave
    Appearance.MenuButton.ActiveCaptionColor = clWhite
    Appearance.MenuButton.ShapeStyle = mbssRounded
    Appearance.Pane.BorderDarkColor = 10921638
    Appearance.Pane.BorderLightColor = clWhite
    Appearance.Pane.CaptionBgColor = 15000804
    Appearance.Pane.CaptionFont.Color = 3552822
    Appearance.Pane.GradientFromColor = 16316664
    Appearance.Pane.GradientToColor = 15329769
    Appearance.Pane.GradientType = bkConcave
    Appearance.Element.CaptionFont.Color = 9126421
    Appearance.Element.IdleFrameColor = 12104105
    Appearance.Element.IdleGradientFromColor = 16053490
    Appearance.Element.IdleGradientToColor = 15132131
    Appearance.Element.IdleGradientType = bkConcave
    Appearance.Element.IdleInnerLightColor = 16184048
    Appearance.Element.IdleInnerDarkColor = 13091002
    Appearance.Element.IdleCaptionColor = 6317407
    Appearance.Element.HotTrackFrameColor = 10211293
    Appearance.Element.HotTrackGradientFromColor = 14351615
    Appearance.Element.HotTrackGradientToColor = 5101567
    Appearance.Element.HotTrackGradientType = bkConcave
    Appearance.Element.HotTrackInnerLightColor = 12972543
    Appearance.Element.HotTrackInnerDarkColor = 8045272
    Appearance.Element.HotTrackCaptionColor = 8864367
    Appearance.Element.HotTrackBrightnessChange = 40
    Appearance.Element.ActiveFrameColor = 5535371
    Appearance.Element.ActiveGradientFromColor = 7126014
    Appearance.Element.ActiveGradientToColor = 4035324
    Appearance.Element.ActiveGradientType = bkConcave
    Appearance.Element.ActiveInnerLightColor = 961020
    Appearance.Element.ActiveInnerDarkColor = 961020
    Appearance.Element.ActiveCaptionColor = 8405614
    Appearance.Element.Style = esRounded
    TabIndex = 0
    MenuButtonCaption = 'Menu'
    MenuButtonDropdownMenu = PopupMenu1
    ShowMenuButton = True
    Tabs = (
      'SpkTab1'
      'SpkTab2'
    )
    object SpkTab1: TSpkTab
      CustomAppearance.Tab.TabHeaderFont.Color = 9126421
      CustomAppearance.Tab.BorderColor = 14922381
      CustomAppearance.Tab.CornerRadius = 4
      CustomAppearance.Tab.GradientFromColor = 16115934
      CustomAppearance.Tab.GradientToColor = 15587527
      CustomAppearance.Tab.GradientType = bkConcave
      CustomAppearance.Tab.InactiveTabHeaderFontColor = 9126421
      CustomAppearance.MenuButton.CaptionFont.Color = clWhite
      CustomAppearance.MenuButton.IdleFrameColor = 10569759
      CustomAppearance.MenuButton.IdleGradientFromColor = 14649927
      CustomAppearance.MenuButton.IdleGradientToColor = 12017961
      CustomAppearance.MenuButton.IdleGradientType = bkConcave
      CustomAppearance.MenuButton.IdleCaptionColor = clWhite
      CustomAppearance.MenuButton.HotTrackFrameColor = 10569759
      CustomAppearance.MenuButton.HotTrackGradientFromColor = 15179099
      CustomAppearance.MenuButton.HotTrackGradientToColor = 12478257
      CustomAppearance.MenuButton.HotTrackGradientType = bkConcave
      CustomAppearance.MenuButton.HotTrackCaptionColor = clWhite
      CustomAppearance.MenuButton.HotTrackBrightnessChange = 40
      CustomAppearance.MenuButton.ActiveFrameColor = 11095324
      CustomAppearance.MenuButton.ActiveGradientFromColor = 14518846
      CustomAppearance.MenuButton.ActiveGradientToColor = 12411174
      CustomAppearance.MenuButton.ActiveGradientType = bkConcave
      CustomAppearance.MenuButton.ActiveCaptionColor = clWhite
      CustomAppearance.MenuButton.ShapeStyle = mbssRounded
      CustomAppearance.Pane.BorderDarkColor = 14335646
      CustomAppearance.Pane.BorderLightColor = 16315117
      CustomAppearance.Pane.CaptionBgColor = 15849922
      CustomAppearance.Pane.CaptionFont.Color = 9126421
      CustomAppearance.Pane.GradientFromColor = 16115934
      CustomAppearance.Pane.GradientToColor = 15587527
      CustomAppearance.Pane.GradientType = bkConcave
      CustomAppearance.Element.IdleFrameColor = 14727067
      CustomAppearance.Element.IdleGradientFromColor = 15653832
      CustomAppearance.Element.IdleGradientToColor = 15323324
      CustomAppearance.Element.IdleGradientType = bkConcave
      CustomAppearance.Element.IdleInnerLightColor = 15852501
      CustomAppearance.Element.IdleInnerDarkColor = 15520702
      CustomAppearance.Element.IdleCaptionColor = 11631958
      CustomAppearance.Element.HotTrackFrameColor = 10211293
      CustomAppearance.Element.HotTrackGradientFromColor = 14351615
      CustomAppearance.Element.HotTrackGradientToColor = 5101567
      CustomAppearance.Element.HotTrackGradientType = bkConcave
      CustomAppearance.Element.HotTrackInnerLightColor = 12972543
      CustomAppearance.Element.HotTrackInnerDarkColor = 8045272
      CustomAppearance.Element.HotTrackCaptionColor = 8864367
      CustomAppearance.Element.HotTrackBrightnessChange = 40
      CustomAppearance.Element.ActiveFrameColor = 5535371
      CustomAppearance.Element.ActiveGradientFromColor = 7126014
      CustomAppearance.Element.ActiveGradientToColor = 4035324
      CustomAppearance.Element.ActiveGradientType = bkConcave
      CustomAppearance.Element.ActiveInnerLightColor = 961020
      CustomAppearance.Element.ActiveInnerDarkColor = 961020
      CustomAppearance.Element.ActiveCaptionColor = 8405614
      CustomAppearance.Element.Style = esRounded
      Caption = 'Main'
      Panes = (
        'SpkPane1'
        'SpkPane2'
      )
      object SpkPane1: TSpkPane
        Caption = 'Test'
        ShowMoreOptionsButtonStyle = mobsArrow
        ShowMoreOptionsButton = True
        Items = (
          'btnOpenGMF'
          'btnFitView'
          'SpkSmallButton1'
          'SpkLargeButton3'
          'SpkLargeButton2'
        )
        object btnOpenGMF: TSpkSmallButton
          Action = actnOpenGMF
          Caption = 'Открыть'
        end
        object btnFitView: TSpkSmallButton
          Action = actnFitView
          Caption = 'FitView'
        end
        object SpkSmallButton1: TSpkSmallButton
          Caption = 'ShowInform'
          OnClick = SpkSmallButton1Click
        end
        object SpkLargeButton3: TSpkLargeButton
          Caption = 'Arc'
          OnClick = SpkLargeButton3Click
        end
        object SpkLargeButton2: TSpkLargeButton
          Caption = 'Multiline'
          OnClick = SpkLargeButton2Click
        end
      end
      object SpkPane2: TSpkPane
        Caption = 'OpenLib'
        Items = (
          'SpkLargeButton1'
          'spkSort'
          'SpkLargeButton4'
        )
        object SpkLargeButton1: TSpkLargeButton
          Action = actnOpenDWG
          Caption = 'actnOpenDWG'
        end
        object spkSort: TSpkLargeButton
          Caption = 'SortBy'
          OnClick = spkSortClick
        end
        object SpkLargeButton4: TSpkLargeButton
          Caption = 'Mem'
          OnClick = SpkLargeButton4Click
        end
      end
    end
    object SpkTab2: TSpkTab
      CustomAppearance.Tab.TabHeaderFont.Color = 9126421
      CustomAppearance.Tab.BorderColor = 14922381
      CustomAppearance.Tab.CornerRadius = 4
      CustomAppearance.Tab.GradientFromColor = 16115934
      CustomAppearance.Tab.GradientToColor = 15587527
      CustomAppearance.Tab.GradientType = bkConcave
      CustomAppearance.Tab.InactiveTabHeaderFontColor = 9126421
      CustomAppearance.MenuButton.CaptionFont.Color = clWhite
      CustomAppearance.MenuButton.IdleFrameColor = 10569759
      CustomAppearance.MenuButton.IdleGradientFromColor = 14649927
      CustomAppearance.MenuButton.IdleGradientToColor = 12017961
      CustomAppearance.MenuButton.IdleGradientType = bkConcave
      CustomAppearance.MenuButton.IdleCaptionColor = clWhite
      CustomAppearance.MenuButton.HotTrackFrameColor = 10569759
      CustomAppearance.MenuButton.HotTrackGradientFromColor = 15179099
      CustomAppearance.MenuButton.HotTrackGradientToColor = 12478257
      CustomAppearance.MenuButton.HotTrackGradientType = bkConcave
      CustomAppearance.MenuButton.HotTrackCaptionColor = clWhite
      CustomAppearance.MenuButton.HotTrackBrightnessChange = 40
      CustomAppearance.MenuButton.ActiveFrameColor = 11095324
      CustomAppearance.MenuButton.ActiveGradientFromColor = 14518846
      CustomAppearance.MenuButton.ActiveGradientToColor = 12411174
      CustomAppearance.MenuButton.ActiveGradientType = bkConcave
      CustomAppearance.MenuButton.ActiveCaptionColor = clWhite
      CustomAppearance.MenuButton.ShapeStyle = mbssRounded
      CustomAppearance.Pane.BorderDarkColor = 14335646
      CustomAppearance.Pane.BorderLightColor = 16315117
      CustomAppearance.Pane.CaptionBgColor = 15849922
      CustomAppearance.Pane.CaptionFont.Color = 9126421
      CustomAppearance.Pane.GradientFromColor = 16115934
      CustomAppearance.Pane.GradientToColor = 15587527
      CustomAppearance.Pane.GradientType = bkConcave
      CustomAppearance.Element.IdleFrameColor = 14727067
      CustomAppearance.Element.IdleGradientFromColor = 15653832
      CustomAppearance.Element.IdleGradientToColor = 15323324
      CustomAppearance.Element.IdleGradientType = bkConcave
      CustomAppearance.Element.IdleInnerLightColor = 15852501
      CustomAppearance.Element.IdleInnerDarkColor = 15520702
      CustomAppearance.Element.IdleCaptionColor = 11631958
      CustomAppearance.Element.HotTrackFrameColor = 10211293
      CustomAppearance.Element.HotTrackGradientFromColor = 14351615
      CustomAppearance.Element.HotTrackGradientToColor = 5101567
      CustomAppearance.Element.HotTrackGradientType = bkConcave
      CustomAppearance.Element.HotTrackInnerLightColor = 12972543
      CustomAppearance.Element.HotTrackInnerDarkColor = 8045272
      CustomAppearance.Element.HotTrackCaptionColor = 8864367
      CustomAppearance.Element.HotTrackBrightnessChange = 40
      CustomAppearance.Element.ActiveFrameColor = 5535371
      CustomAppearance.Element.ActiveGradientFromColor = 7126014
      CustomAppearance.Element.ActiveGradientToColor = 4035324
      CustomAppearance.Element.ActiveGradientType = bkConcave
      CustomAppearance.Element.ActiveInnerLightColor = 961020
      CustomAppearance.Element.ActiveInnerDarkColor = 961020
      CustomAppearance.Element.ActiveCaptionColor = 8405614
      CustomAppearance.Element.Style = esRounded
      Caption = 'Tab'
      Panes = (
        'SpkPane3'
      )
      object SpkPane3: TSpkPane
        Caption = 'Pane'
        Items = (
          'sbAutorise'
          'spConnect'
          'SpkCreateSession'
        )
        object sbAutorise: TSpkLargeButton
          Caption = 'Autorize'
          OnClick = sbAutoriseClick
        end
        object spConnect: TSpkLargeButton
          Caption = 'Connect'
          OnClick = spConnectClick
        end
        object SpkCreateSession: TSpkLargeButton
          Caption = 'CreateSession'
          OnClick = SpkCreateSessionClick
        end
      end
    end
  end
  object mainPanel: TPanel
    Left = 0
    Height = 375
    Top = 112
    Width = 939
    Align = alClient
    BevelOuter = bvNone
    Caption = 'mainPanel'
    ClientHeight = 375
    ClientWidth = 939
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 280
      Height = 375
      Top = 0
      Width = 6
    end
    object VLE: TValueListEditor
      Left = 0
      Height = 375
      Top = 0
      Width = 280
      Align = alLeft
      Color = clBtnFace
      FixedCols = 0
      RowCount = 10
      TabOrder = 1
      OnClick = VLEClick
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
        212
      )
    end
    object Image32: TImage32
      Left = 286
      Height = 375
      Top = 0
      Width = 653
      Align = alClient
      Bitmap.ResamplerClassName = 'TNearestResampler'
      BitmapAlign = baTopLeft
      Scale = 1
      ScaleMode = smNormal
      TabOrder = 2
      OnMouseDown = Image32MouseDown
      OnMouseMove = Image32MouseMove
      OnMouseUp = Image32MouseUp
      OnMouseWheel = Image32MouseWheel
      OnResize = Image32Resize
    end
  end
  object btmPanel: TPanel
    Left = 0
    Height = 50
    Top = 493
    Width = 939
    Align = alBottom
    ClientHeight = 50
    ClientWidth = 939
    TabOrder = 2
    object LabelXY: TLabel
      Left = 12
      Height = 15
      Top = 16
      Width = 42
      Caption = 'LabelXY'
    end
  end
  object Splitter2: TSplitter
    Cursor = crVSplit
    Left = 0
    Height = 6
    Top = 487
    Width = 939
    Align = alBottom
    ResizeAnchor = akBottom
  end
  object ToggleBox1: TToggleBox
    Left = 481
    Height = 25
    Top = 80
    Width = 75
    Caption = 'ToggleBox1'
    OnChange = ToggleBox1Change
    TabOrder = 4
    Visible = False
  end
  object btnTestTiles: TButton
    Left = 480
    Height = 25
    Top = 27
    Width = 75
    Caption = 'TestTiles'
    OnClick = btnTestTilesClick
    TabOrder = 5
  end
  object btnTestTiles1: TButton
    Left = 480
    Height = 25
    Top = 54
    Width = 75
    Caption = 'FreeTiles'
    OnClick = btnTestTilesClick
    TabOrder = 6
  end
  object GroupBox1: TGroupBox
    Left = 576
    Height = 74
    Top = 30
    Width = 204
    Caption = 'Layers'
    ClientHeight = 54
    ClientWidth = 200
    TabOrder = 7
    OnClick = GroupBox1Click
    object Label1: TLabel
      Left = 9
      Height = 15
      Top = 6
      Width = 79
      Caption = 'ZLayer (0...255)'
    end
    object FloatSpinEdit1: TFloatSpinEdit
      Left = 100
      Height = 23
      Top = 3
      Width = 80
      Increment = 10
      MaxValue = 100
      OnChange = FloatSpinEdit1Change
      TabOrder = 0
    end
    object Button1: TButton
      Left = 11
      Height = 25
      Top = 32
      Width = 42
      Caption = 'GL'
      OnClick = Button1Click
      TabOrder = 1
    end
    object ButtonMap2D: TButton
      Left = 60
      Height = 25
      Top = 32
      Width = 60
      Caption = 'Map2D'
      OnClick = ButtonMap2DClick
      TabOrder = 2
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 296
    Top = 24
    object MenuItem1: TMenuItem
      Caption = 'Очистить'
      OnClick = MenuItem1Click
    end
    object MenuItem2: TMenuItem
      Caption = 'MenuItem2'
      OnClick = MenuItem2Click
    end
  end
  object ODGmf: TOpenDialog
    OnShow = ODGmfShow
    Filter = '*.gmf'
    Left = 296
    Top = 67
  end
  object ActionList1: TActionList
    Left = 876
    Top = 82
    object actnOpenGMF: TAction
      Caption = 'Открыть'
      OnExecute = actnOpenGMFExecute
    end
    object actnFitView: TAction
      Caption = 'FitView'
      OnExecute = actnFitViewExecute
    end
    object actnOpenDWG: TAction
      Caption = 'actnOpenDWG'
      OnExecute = actnOpenDWGExecute
    end
  end
  object ImgList: TImageList
    Left = 440
    Top = 67
  end
  object ODDwg: TOpenDialog
    OnShow = ODGmfShow
    Filter = '*.dwg|*.dwg'
    Left = 296
    Top = 120
  end
  object ODLas: TOpenDialog
    Filter = 'las|*.las'
    Left = 710
    Top = 133
  end
end
