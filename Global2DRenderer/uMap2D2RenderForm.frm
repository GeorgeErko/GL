inherited Map2D2RenderForm: TMap2D2RenderForm
  inherited pnlBottom: TPanel
    object sbMode: TSpeedButton[0]
      Left = 555
      Height = 22
      Top = 4
      Width = 74
      AllowAllUp = True
      Caption = 'Low RS'
      Down = True
      GroupIndex = 1
      OnClick = sbModeClick
    end
    object sbBlocks: TSpeedButton[1]
      Left = 631
      Height = 22
      Top = 4
      Width = 74
      AllowAllUp = True
      Caption = 'useBlocks'
      GroupIndex = 2
      OnClick = sbModeClick
    end
    object sbText: TSpeedButton[2]
      Left = 706
      Height = 22
      Top = 4
      Width = 74
      AllowAllUp = True
      Caption = 'useText'
      GroupIndex = 3
      OnClick = sbModeClick
    end
  end
end
