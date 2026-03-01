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
    Height = 364
    Top = 72
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
    Top = 36
    Width = 827
    Align = alTop
    ClientHeight = 36
    ClientWidth = 827
    TabOrder = 2
    object Button2D: TButton
      Left = 33
      Height = 25
      Top = 6
      Width = 35
      Caption = '2D'
      OnClick = Button2DClick
      TabOrder = 0
    end
    object Button3D: TButton
      Left = 73
      Height = 25
      Top = 6
      Width = 35
      Caption = '3D'
      OnClick = Button3DClick
      TabOrder = 1
    end
    object ButtonReset: TButton
      Left = 112
      Height = 25
      Top = 6
      Width = 47
      Caption = 'Reset'
      OnClick = ButtonResetClick
      TabOrder = 2
    end
    object Label1: TLabel
      Left = 198
      Height = 15
      Top = 11
      Width = 35
      Caption = 'Точка:'
    end
    object LabelCamera: TLabel
      Left = 637
      Height = 19
      Top = 6
      Width = 187
      Anchors = [akTop, akRight]
      AutoSize = False
      OnClick = LabelCameraClick
    end
    object UpDown1: TUpDown
      Left = 240
      Height = 31
      Top = 1
      Width = 17
      Max = 4
      Min = 1
      OnClick = UpDown1Click
      Position = 1
      TabOrder = 3
    end
    object BlendCheck: TCheckBox
      Left = 270
      Height = 19
      Top = 7
      Width = 48
      Caption = 'Blend'
      OnChange = UIChanged
      TabOrder = 4
    end
    object AlphaBar: TTrackBar
      Left = 324
      Height = 30
      Top = 4
      Width = 160
      Max = 255
      OnChange = UIChanged
      Position = 255
      TabOrder = 5
    end
    object TilesCheck: TCheckBox
      Left = 502
      Height = 19
      Top = 7
      Width = 41
      Caption = 'Tiles'
      OnChange = UIChanged
      TabOrder = 6
    end
    object Label3: TLabel
      Left = 8
      Height = 15
      Top = 11
      Width = 20
      Caption = 'Вид'
    end
    object sbRun1: TSpeedButton
      Left = 165
      Height = 25
      Top = 6
      Width = 23
      AllowAllUp = True
      Glyph.Data = {
        66010000424D6601000000000000760000002800000014000000140000000100
        040000000000F000000000000000000000000000000000000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
        7777777700007777777777777777777700007777777777777777777700007777
        7777777777777777000077777770777777777777000077777770077777777777
        0000777777700077777777770000777777700007777777770000777777700000
        7777777700007777777000000777777700007777777000007777777700007777
        7770000777777777000077777770007777777777000077777770077777777777
        0000777777707777777777770000777777777777777777770000777777777777
        7777777700007777777777777777777700007777777777777777777700007777
        77777777777777770000
      }
      GroupIndex = 1
    end
  end
  object Panel1: TPanel
    Left = 0
    Height = 36
    Top = 0
    Width = 827
    Align = alTop
    ClientHeight = 36
    ClientWidth = 827
    TabOrder = 3
    OnClick = Panel1Click
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
    object r3sbOpen1: TSpeedButton
      Left = 374
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
    object r3sbAddLas: TSpeedButton
      Left = 27
      Height = 22
      Top = 7
      Width = 23
      Glyph.Data = {
        F6000000424D0E00000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000000000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
        88888800000000888888880FFFFF80088888880F8A8F80808888880F8A8F80F8
        0888880FFFFFF0000088880F000888FFF088880FCC48888FF0888808CC488888
        F0888444CC444088F0888CCCCCCCC088F0888CCCCC444FFFF088880FCC48FFFF
        F088880FCC4FFFFFF088880FFFFFFFFFF0888800000000000088
      }
    end
    object Label2: TLabel
      Left = 58
      Height = 15
      Top = 10
      Width = 41
      Caption = 'Облака'
    end
    object cbClouds: TComboBox
      Left = 104
      Height = 23
      Top = 7
      Width = 202
      ItemHeight = 15
      TabOrder = 0
      Text = 'cbClouds'
    end
  end
  object cbTileSize: TComboBox
    Left = 550
    Height = 23
    Top = 41
    Width = 74
    ItemHeight = 15
    ItemIndex = 1
    Items.Strings = (
      '50'
      '100'
      '150'
      '200'
      '250'
      '350'
      '500'
      '750'
      '1000'
    )
    OnChange = cbTileSizeChange
    TabOrder = 4
    Text = '100'
  end
  object r3sbAddLas1: TSpeedButton
    Left = 337
    Height = 22
    Top = 7
    Width = 23
    Enabled = False
    Glyph.Data = {
      F6000000424D0E00000000000000760000002800000010000000100000000100
      0400000000008000000000000000000000000000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
      88888800000000888888880FFFFF80088888880F8A8F80808888880F8A8F80F8
      0888880FFFFFF0000088880FFFF888FFF088880FFF88888FF088800000000088
      F088999999999088F088999999999088F0889999999990FFF088999999999FFF
      F088880FFFFFFFFFF088880FFFFFFFFFF0888800000000000088
    }
  end
  object r3sbAddLas2: TSpeedButton
    Left = 311
    Height = 22
    Top = 7
    Width = 23
    Enabled = False
    Glyph.Data = {
      42010000424D4201000000000000760000002800000011000000110000000100
      040000000000CC00000000000000000000001000000010000000000000000000
      BF0000BF000000BFBF00BF000000BF00BF00BFBF0000C0C0C000808080000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
      7777700000007777777777777777700000007777777774F77777700000007777
      7777444F77777000000077777774444F777770000000700000444F44F7777000
      000070FFF444F0744F777000000070F8884FF0774F777000000070FFFFFFF077
      74F77000000070F88888F077774F7000000070FFFFFFF0777774F000000070F8
      8777F07777774000000070FFFF00007777777000000070F88707077777777000
      000070FFFF007777777770000000700000077777777770000000777777777777
      777770000000
    }
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
