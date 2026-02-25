object Las3DRenderForm: TLas3DRenderForm
  Left = 314
  Height = 486
  Top = 257
  Width = 827
  Caption = 'LAS Point Cloud Viewer'
  ClientHeight = 466
  ClientWidth = 827
  Menu = r3MainMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  LCLVersion = '7.8'
  object r3pnlBottom: TPanel
    Left = 0
    Height = 30
    Top = 436
    Width = 827
    Align = alBottom
    ClientHeight = 30
    ClientWidth = 827
    TabOrder = 0
    object ProgressBar1: TProgressBar
      Left = 662
      Height = 20
      Top = 4
      Width = 158
      Anchors = [akTop, akLeft, akRight]
      TabOrder = 0
    end
    object LabelZInfo: TLabel
      Left = 426
      Height = 20
      Top = 6
      Width = 231
      Anchors = [akTop, akLeft, akRight]
      AutoSize = False
    end
    object PlaneCheck: TCheckBox
      Left = 9
      Height = 19
      Top = 5
      Width = 47
      Caption = 'Plane'
      OnChange = UIChanged
      TabOrder = 1
    end
    object DeltaZEdit: TFloatSpinEdit
      Left = 65
      Height = 23
      Top = 3
      Width = 60
      DecimalPlaces = 3
      Increment = 0.1
      MaxValue = 1E30
      MinValue = -1E30
      OnChange = UIChanged
      TabOrder = 2
    end
    object kZoom: TCheckBox
      Left = 135
      Height = 19
      Top = 5
      Width = 56
      Caption = 'kZoom'
      OnChange = UIChanged
      TabOrder = 3
    end
    object ZoomKEdit: TFloatSpinEdit
      Left = 195
      Height = 23
      Top = 3
      Width = 60
      DecimalPlaces = 3
      Increment = 0.01
      MaxValue = 1E30
      MinValue = -1E30
      OnChange = UIChanged
      TabOrder = 4
    end
    object ColorModeCombo: TComboBox
      Left = 265
      Height = 23
      Top = 3
      Width = 155
      ItemHeight = 15
      OnChange = ColorModeComboChange
      Style = csDropDownList
      TabOrder = 5
    end
  end
  object OpenGLPanel1: TOpenGLPanel
    Left = 0
    Height = 400
    Top = 36
    Width = 827
    Align = alClient
    OnClick = OpenGLPanel1Click
    OnMouseDown = OpenGLPanel1MouseDown
    OnMouseMove = OpenGLPanel1MouseMove
    OnMouseUp = OpenGLPanel1MouseUp
    OnMouseWheel = OpenGLPanel1MouseWheel
    OnPaint = OpenGLPanel1Paint
  end
  object r3pnlTop: TPanel
    Left = 0
    Height = 36
    Top = 0
    Width = 827
    Align = alTop
    ClientHeight = 36
    ClientWidth = 827
    TabOrder = 2
    object Button2D: TButton
      Left = 53
      Height = 25
      Top = 6
      Width = 75
      Caption = '2D'
      OnClick = Button2DClick
      TabOrder = 0
    end
    object Button3D: TButton
      Left = 133
      Height = 25
      Top = 6
      Width = 75
      Caption = '3D'
      OnClick = Button3DClick
      TabOrder = 1
    end
    object ButtonReset: TButton
      Left = 213
      Height = 25
      Top = 6
      Width = 75
      Caption = 'Reset'
      OnClick = ButtonResetClick
      TabOrder = 2
    end
    object Label1: TLabel
      Left = 301
      Height = 15
      Top = 10
      Width = 35
      Caption = 'Точка:'
    end
    object LabelCamera: TLabel
      Left = 682
      Height = 19
      Top = 6
      Width = 130
      Anchors = [akTop, akRight]
      AutoSize = False
      OnClick = LabelCameraClick
    end
    object UpDown1: TUpDown
      Left = 343
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
      Left = 373
      Height = 19
      Top = 6
      Width = 48
      Caption = 'Blend'
      OnChange = UIChanged
      TabOrder = 4
    end
    object AlphaBar: TTrackBar
      Left = 427
      Height = 30
      Top = 3
      Width = 160
      Max = 255
      OnChange = UIChanged
      Position = 255
      TabOrder = 5
    end
    object TilesCheck: TCheckBox
      Left = 605
      Height = 19
      Top = 6
      Width = 41
      Caption = 'Tiles'
      OnChange = UIChanged
      TabOrder = 6
    end
    object r3sbOpen: TSpeedButton
      Left = 3
      Height = 22
      Top = 7
      Width = 23
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000010000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
        88888888888888888888000000000008888800333333333088880B0333333333
        08880FB03333333330880BFB0333333333080FBFB000000000000BFBFBFBFB08
        88880FBFBFBFBF0888880BFB0000000888888000888888880008888888888888
        8008888888880888080888888888800088888888888888888888
      }
      OnClick = MenuFileOpenClick
    end
  end
  object r3sbOpen1: TSpeedButton
    Left = 26
    Height = 22
    Top = 7
    Width = 23
    Glyph.Data = {
      F6000000424DF600000000000000760000002800000010000000100000000100
      0400000000008000000000000000000000001000000010000000000000000000
      BF0000BF000000BFBF00BF000000BF00BF00BFBF0000C0C0C000808080000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00DDDDDDDDDDDD
      DDDDDDDDDDDDDDDDDDDDDDD00DDDDDDDDDDDDDD0000DDDDDDDDDDDDD0000DDDD
      DDDDDDDD00070DDDDDDDDDDDD07770DDDDDDDDDDDD07770D0DDDD0000DD07770
      0DDDD000DDDD07000DDDD000DDDDD00000DDD0D00DDD0000000DDDDD00DDDDD0
      000DDDDDD0DDDDDD000DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
    }
    OnClick = MenuFileOpenClick
  end
  object r3MainMenu1: TMainMenu
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
  object ODLAS: TOpenDialog
    DefaultExt = '.las'
    Filter = 'LAS cloud|*.las'
    Left = 70
    Top = 84
  end
end
