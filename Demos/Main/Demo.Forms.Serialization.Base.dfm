object frmSerializationBase: TfrmSerializationBase
  Left = 0
  Top = 0
  Caption = 'frmSerializationBase'
  ClientHeight = 339
  ClientWidth = 969
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    969
    339)
  PixelsPerInch = 96
  TextHeight = 13
  object pnlSerialize: TPanel
    Left = 3
    Top = 3
    Width = 473
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    BevelOuter = bvNone
    Caption = 'Serialize'
    Color = clMaroon
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 0
  end
  object memoSerialize: TMemo
    Left = 140
    Top = 33
    Width = 336
    Height = 240
    Anchors = [akLeft, akTop, akRight]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
  end
  object pnlDeserialize: TPanel
    Left = 485
    Top = 4
    Width = 473
    Height = 23
    Anchors = [akTop, akRight]
    BevelOuter = bvNone
    Caption = 'Deserialize'
    Color = clMaroon
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 2
  end
  object memoDeserialize: TMemo
    Left = 619
    Top = 33
    Width = 339
    Height = 240
    Anchors = [akTop, akRight]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 3
    WordWrap = False
  end
  object memoLog: TMemo
    Left = 0
    Top = 279
    Width = 969
    Height = 60
    Align = alBottom
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
end
