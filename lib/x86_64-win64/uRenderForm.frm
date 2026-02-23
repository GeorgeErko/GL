object RenderForm: TRenderForm
  Left = 314
  Height = 486
  Top = 257
  Width = 761
  Caption = 'LAS Point Cloud Viewer'
  ClientHeight = 466
  ClientWidth = 761
  Menu = MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  LCLVersion = '7.8'
  object pBottom: TPanel
    Left = 0
    Height = 36
    Top = 430
    Width = 761
    Align = alBottom
    ClientHeight = 36
    ClientWidth = 761
    TabOrder = 0
    object ProgressBar1: TProgressBar
      Left = 605
      Height = 20
      Top = 8
      Width = 148
      Anchors = [akTop, akLeft, akRight]
      TabOrder = 0
    end
    object LabelZInfo: TLabel
      Left = 147
      Height = 20
      Top = 11
      Width = 444
      Anchors = [akTop, akLeft, akRight]
      AutoSize = False
    end
    object PlaneCheck: TCheckBox
      Left = 9
      Height = 19
      Top = 10
      Width = 47
      Caption = 'Plane'
      OnChange = UIChanged
      TabOrder = 1
    end
    object DeltaZEdit: TFloatSpinEdit
      Left = 65
      Height = 23
      Top = 8
      Width = 60
      DecimalPlaces = 3
      Increment = 0.1
      MaxValue = 1E30
      MinValue = -1E30
      OnChange = UIChanged
      TabOrder = 2
    end
  end
  object OpenGLPanel1: TOpenGLPanel
    Left = 0
    Height = 394
    Top = 36
    Width = 761
    Align = alClient
    OnMouseDown = OpenGLPanel1MouseDown
    OnMouseMove = OpenGLPanel1MouseMove
    OnMouseUp = OpenGLPanel1MouseUp
    OnMouseWheel = OpenGLPanel1MouseWheel
    OnPaint = OpenGLPanel1Paint
  end
  object pTop: TPanel
    Left = 0
    Height = 36
    Top = 0
    Width = 761
    Align = alTop
    ClientHeight = 36
    ClientWidth = 761
    TabOrder = 2
    object Button2D: TButton
      Left = 8
      Height = 25
      Top = 6
      Width = 75
      Caption = '2D'
      OnClick = Button2DClick
      TabOrder = 0
    end
    object Button3D: TButton
      Left = 88
      Height = 25
      Top = 6
      Width = 75
      Caption = '3D'
      OnClick = Button3DClick
      TabOrder = 1
    end
    object ButtonReset: TButton
      Left = 168
      Height = 25
      Top = 6
      Width = 75
      Caption = 'Reset'
      OnClick = ButtonResetClick
      TabOrder = 2
    end
    object Label1: TLabel
      Left = 256
      Height = 15
      Top = 10
      Width = 35
      Caption = 'Точка:'
    end
    object LabelCamera: TLabel
      Left = 618
      Height = 19
      Top = 6
      Width = 130
      Anchors = [akTop, akRight]
      AutoSize = False
      OnClick = LabelCameraClick
    end
    object UpDown1: TUpDown
      Left = 298
      Height = 31
      Top = 0
      Width = 17
      Max = 4
      Min = 1
      OnClick = UpDown1Click
      Position = 1
      TabOrder = 3
    end
    object BlendCheck: TCheckBox
      Left = 328
      Height = 19
      Top = 6
      Width = 48
      Caption = 'Blend'
      OnChange = UIChanged
      TabOrder = 4
    end
    object AlphaBar: TTrackBar
      Left = 392
      Height = 30
      Top = 3
      Width = 160
      Max = 255
      OnChange = UIChanged
      Position = 255
      TabOrder = 5
    end
    object TilesCheck: TCheckBox
      Left = 560
      Height = 19
      Top = 6
      Width = 41
      Caption = 'Tiles'
      OnChange = UIChanged
      TabOrder = 6
    end
  end
  object MainMenu1: TMainMenu
    Left = 400
    Top = 100
    object MenuFile: TMenuItem
      Caption = 'Файл'
      object MenuFileOpen: TMenuItem
        Caption = 'Открыть...'
        OnClick = MenuFileOpenClick
      end
      object MenuFileOpenTrees: TMenuItem
        Caption = 'Открыть CSV (деревья)...'
        OnClick = MenuFileOpenTreesClick
      end
      object MenuFileInfo: TMenuItem
        Caption = 'Инфо...'
        OnClick = MenuFileInfoClick
      end
    end
  end
  object UpdateTimer: TTimer
    Enabled = False
    Interval = 250
    OnTimer = UpdateTimerTimer
    Left = 480
    Top = 100
  end
end
