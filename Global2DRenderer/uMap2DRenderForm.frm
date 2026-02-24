object Map2DRenderForm: TMap2DRenderForm
  Left = 300
  Height = 600
  Top = 200
  Width = 800
  Caption = '2D Map OGL'
  ClientHeight = 580
  ClientWidth = 800
  Menu = MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  LCLVersion = '7.8'
  object PanelTop: TPanel
    Left = 0
    Height = 30
    Top = 0
    Width = 800
    Align = alTop
    BevelOuter = bvNone
    ClientHeight = 30
    ClientWidth = 800
    TabOrder = 0
    object CBTiles: TCheckBox
      Left = 8
      Height = 19
      Top = 6
      Width = 41
      Caption = 'Tiles'
      OnClick = CBTilesClick
      TabOrder = 0
    end
  end
  object PBScene: TProgressBar
    Left = 435
    Height = 16
    Top = 5
    Width = 352
    Anchors = [akTop, akRight]
    Smooth = True
    TabOrder = 4
    Visible = False
  end
  object OpenGLPanel1: TOpenGLPanel
    Left = 280
    Height = 527
    Top = 30
    Width = 520
    Align = alClient
    OnMouseDown = OpenGLPanel1MouseDown
    OnMouseMove = OpenGLPanel1MouseMove
    OnMouseUp = OpenGLPanel1MouseUp
    OnMouseWheel = OpenGLPanel1MouseWheel
    OnPaint = OpenGLPanel1Paint
  end
  object StatusBar1: TStatusBar
    Left = 0
    Height = 23
    Top = 557
    Width = 800
    Panels = <>
    SimplePanel = True
  end
  object VLE: TValueListEditor
    Left = 0
    Height = 527
    Top = 30
    Width = 280
    Align = alLeft
    Color = clBtnFace
    FixedCols = 0
    RowCount = 10
    TabOrder = 3
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
  object MainMenu1: TMainMenu
    Left = 56
    Top = 40
    object MenuFile: TMenuItem
      Caption = 'Файл'
      object MenuFileOpen: TMenuItem
        Caption = 'Открыть...'
        OnClick = MenuFileOpenClick
      end
    end
  end
  object ODGmf: TOpenDialog
    Filter = '*.gmf'
    Left = 56
    Top = 88
  end
  object ImgList: TImageList
    Left = 468
    Top = 95
  end
end
