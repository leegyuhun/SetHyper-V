object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Windows Hyper-V '#44288#47532
  ClientHeight = 170
  ClientWidth = 380
  Color = clBtnFace
  Font.Charset = HANGEUL_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Malgun Gothic'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object lblStatusCaption: TLabel
    Left = 24
    Top = 24
    Width = 70
    Height = 18
    Caption = #54788#51116' '#49345#53468':'
    Font.Charset = HANGEUL_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Malgun Gothic'
    Font.Style = []
    ParentFont = False
  end
  object lblStatusValue: TLabel
    Left = 100
    Top = 24
    Width = 120
    Height = 18
    Caption = #54869#51064' '#51473'...'
    Font.Charset = HANGEUL_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Malgun Gothic'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblHint: TLabel
    Left = 24
    Top = 148
    Width = 332
    Height = 16
    Caption = '* '#48320#44221' '#54980' '#51116#48512#54305#51060' '#54596#50836#54633#45768#45796'.'
    Font.Charset = HANGEUL_CHARSET
    Font.Color = clGrayText
    Font.Height = -11
    Font.Name = 'Malgun Gothic'
    Font.Style = []
    ParentFont = False
  end
  object pnlStatusColor: TPanel
    Left = 24
    Top = 52
    Width = 332
    Height = 32
    BevelOuter = bvNone
    Color = clOlive
    Caption = ''
    TabOrder = 1
  end
  object btnToggle: TButton
    Left = 115
    Top = 100
    Width = 150
    Height = 35
    Caption = #54869#51064' '#51473'...'
    Enabled = False
    Font.Charset = HANGEUL_CHARSET
    Font.Color = clWindowText
    Font.Height = -14
    Font.Name = 'Malgun Gothic'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
end
