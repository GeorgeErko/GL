object Las3DRenderForm: TLas3DRenderForm
  Left = 314
  Height = 486
  Top = 257
  Width = 884
  Caption = 'LAS Point Cloud Viewer'
  ClientHeight = 486
  ClientWidth = 884
  Menu = r3MainMenu1
  LCLVersion = '8.9'
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  object r3pnlBottom: TPanel
    Left = 0
    Height = 30
    Top = 456
    Width = 884
    Align = alBottom
    ClientHeight = 30
    ClientWidth = 884
    TabOrder = 0
    object ProgressBar1: TProgressBar
      Left = 662
      Height = 20
      Top = 4
      Width = 215
      Anchors = [akTop, akLeft, akRight]
      TabOrder = 0
    end
    object LabelZInfo: TLabel
      Left = 426
      Height = 20
      Top = 6
      Width = 288
      Anchors = [akTop, akLeft, akRight]
      AutoSize = False
    end
    object PlaneCheck: TCheckBox
      Left = 9
      Height = 19
      Top = 5
      Width = 47
      Caption = 'Plane'
      TabOrder = 1
      OnChange = UIChanged
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
      TabOrder = 2
      OnChange = UIChanged
    end
    object kZoom: TCheckBox
      Left = 135
      Height = 19
      Top = 5
      Width = 56
      Caption = 'kZoom'
      TabOrder = 3
      OnChange = UIChanged
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
      TabOrder = 4
      OnChange = UIChanged
    end
    object ColorModeCombo: TComboBox
      Left = 265
      Height = 23
      Top = 3
      Width = 155
      ItemHeight = 15
      Style = csDropDownList
      TabOrder = 5
      OnChange = ColorModeComboChange
    end
  end
  object OpenGLPanel1: TOpenGLPanel
    Left = 0
    Height = 384
    Top = 72
    Width = 884
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
    Width = 884
    Align = alTop
    ClientHeight = 36
    ClientWidth = 884
    TabOrder = 2
    object Button2D: TButton
      Left = 33
      Height = 25
      Top = 6
      Width = 35
      Caption = '2D'
      TabOrder = 0
      OnClick = Button2DClick
    end
    object Button3D: TButton
      Left = 73
      Height = 25
      Top = 6
      Width = 35
      Caption = '3D'
      TabOrder = 1
      OnClick = Button3DClick
    end
    object ButtonReset: TButton
      Left = 112
      Height = 25
      Top = 6
      Width = 47
      Caption = 'Reset'
      TabOrder = 2
      OnClick = ButtonResetClick
    end
    object Label1: TLabel
      Left = 223
      Height = 15
      Top = 11
      Width = 35
      Caption = 'Точка:'
    end
    object LabelCamera: TLabel
      Left = 719
      Height = 19
      Top = 6
      Width = 187
      Anchors = [akTop, akRight]
      AutoSize = False
      OnClick = LabelCameraClick
    end
    object UpDown1: TUpDown
      Left = 265
      Height = 31
      Top = 1
      Width = 17
      Max = 4
      Min = 1
      Position = 1
      TabOrder = 3
      OnClick = UpDown1Click
    end
    object BlendCheck: TCheckBox
      Left = 295
      Height = 19
      Top = 7
      Width = 48
      Caption = 'Blend'
      TabOrder = 4
      OnChange = UIChanged
    end
    object AlphaBar: TTrackBar
      Left = 349
      Height = 30
      Top = 4
      Width = 160
      Max = 255
      Position = 255
      OnChange = UIChanged
      TabOrder = 5
    end
    object TilesCheck: TCheckBox
      Left = 527
      Height = 19
      Top = 7
      Width = 41
      Caption = 'Tiles'
      TabOrder = 6
      OnChange = UIChanged
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
      OnClick = sbRun1Click
    end
    object sbRun2: TSpeedButton
      Left = 189
      Height = 22
      Top = 7
      Width = 23
      Glyph.Data = {
        36030000424D3603000000000000360000002800000010000000100000000100
        1800000000000003000000000000000000000000000000000000FF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF66666666666666666666666666
        6666666666666666666666666666666666FF00FFFF00FFFF00FFFF00FFFF00FF
        B24E1DB24E1DB24E1DB24E1DB24E1DB24E1DB24E1DB24E1DB24E1DB24E1DB24E
        1D666666FF00FFFF00FFB8B6B1FF00FFB17C59D8EAEFD8EAEFD8EAEFD8EAEFD8
        EAEFD8EAEFD8EAEFD8EAEFD8EAEFB24E1D666666FF00FFFF00FFFF00FFFF00FF
        B17C59D7E7EBCED3D3C9CCCCC9CCCCC9CCCCC9CCCCC9CCCCC9CCCCE8F2F5BEA1
        8C784428666666FF00FFBBB6AE999C9DFF00FFB17C59CBDDE18F9697FFFFFFFF
        FFFFFFFFFFFFFFFFF3F6F7E2E9EBD9EAEFB4753B666666FF00FFFF00FFFF00FF
        FF00FFB17C59D8EAEF94A2ACD0D0D0FFFFFFFFFFFFFFFFFFFFFFFFD6E1E4EBF4
        F7B48A6B666666FF00FFB6AFA5949490FF00FFB17C59D6E4E8D8EAEF80898980
        89898089898089898089898B9697E7ECEDCFD0CDB4753B666666FF00FFFF00FF
        FF00FFFF00FFB17C59D8EAEFD8EAEFD8EAEFD8EAEFD8EAEFD8EAEFD8EAEFD8EA
        EFD8EAEFB4753B666666CDC5BAB6B2ACA3A5A4FF00FFB17C59DF902EDF8D27DF
        8D27DF8D27DF8D27DF8D27E8A34EE7A049D49449B4753B865339FF00FFFF00FF
        FF00FFFF00FFFF00FFB24E1DB24E1DB24E1DB24E1DB24E1DB24E1DB24E1DB24E
        1DB24E1DB24E1DFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
      }
      GroupIndex = 1
      OnClick = sbRun2Click
    end
  end
  object Panel1: TPanel
    Left = 0
    Height = 36
    Top = 0
    Width = 884
    Align = alTop
    ClientHeight = 36
    ClientWidth = 884
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
    object btnMap: TButton
      Left = 720
      Height = 25
      Top = 5
      Width = 48
      Caption = 'Map'
      TabOrder = 1
      OnClick = btnMapClick
    end
    object btnCut: TButton
      Left = 664
      Height = 25
      Top = 4
      Width = 51
      Caption = 'btnCut'
      TabOrder = 2
      OnClick = btnCutClick
    end
    object XYLabel: TLabel
      Left = 407
      Height = 15
      Top = 12
      Width = 42
      Caption = 'XYLabel'
    end
    object btnDel: TButton
      Left = 776
      Height = 25
      Top = 5
      Width = 48
      Caption = 'Del'
      TabOrder = 3
      OnClick = btnDelClick
    end
  end
  object cbTileSize: TComboBox
    Left = 575
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
    TabOrder = 4
    Text = '100'
    OnChange = cbTileSizeChange
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
    Interval = 1
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
