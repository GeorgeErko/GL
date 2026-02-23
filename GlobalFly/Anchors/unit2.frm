object Form2: TForm
  Left = 552
  Top = 124
  Caption = 'Form2'
  LCLVersion = '7.8'
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Ãîðÿ÷èå êëàâèøè'
  ClientHeight = 621
  ClientWidth = 615
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object sPanel1: TPanel
    Left = 0
    Top = 0
    Width = 615
    Height = 621
    Align = alClient
    Caption = 'sPanel1'
    TabOrder = 0
    SkinData.SkinSection = 'PANEL'
    object sLabel1: TLabel
      Left = 17
      Top = 10
      Width = 592
      Height = 45
      AutoSize = False
      Caption =
        'Âûáåðèòå êîìáèíàöèþ ãîðÿ÷èõ êëàâèø äëÿ ïðèâÿçêè èíñòðóìåíòàëüíû ' +
        'êíîïîê. Èçìåíÿéòå ïîäñêàçêè. '#13#10'Äëÿ êíîïîê, ïðåäïîëàãàþùèõ îòìåíó' +
        ' äåéñòâèÿ ïðè îòæàòèè, ïîâòîðíàÿ êîìáèíàöèÿ ãîðÿ÷èõ êëàâèø '#13#10'ïðè' +
        'âåäåò ê îòìåíå òåêóùåé èíñòðóìåíòàëüíîé îïåðàöèè.'
    end
    object Grid: TStringGrid
      Left = 6
      Top = 58
      Width = 603
      Height = 501
      ColCount = 3
      Ctl3D = True
      DefaultRowHeight = 22
      FixedCols = 0
      RowCount = 2
      FixedRows = 0
      Options = []
      ParentCtl3D = False
      TabOrder = 0
      OnDrawCell = GridDrawCell
      OnKeyDown = GridKeyDown
      OnSelectCell = GridSelectCell
      ColWidths = (
        23
        106
        449)
    end
    object sButton4: TButton
      Left = 14
      Top = 578
      Width = 117
      Height = 25
      Caption = 'Íà ñåðâåð'
      Enabled = False
      TabOrder = 1
    end
    object sButton1: TButton
      Left = 278
      Top = 578
      Width = 87
      Height = 25
      Caption = 'Ñîõðàíèòü'
      TabOrder = 2
      OnClick = sButton1Click
    end
    object sButton2: TButton
      Left = 382
      Top = 578
      Width = 117
      Height = 25
      Caption = 'Ñîõðàíèòü êàê...'
      Enabled = False
      TabOrder = 3
    end
    object sButton3: TButton
      Left = 514
      Top = 578
      Width = 75
      Height = 25
      Caption = 'Çàêðûòü'
      Default = True
      ModalResult = 1
      TabOrder = 4
      OnClick = sButton3Click
    end
  end
end
