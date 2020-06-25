inherited frmSerializationRecords: TfrmSerializationRecords
  Caption = 'frmSerializationRecords'
  PixelsPerInch = 96
  TextHeight = 13
  object btnSerSimpleMRecord: TButton
    Left = 3
    Top = 64
    Width = 131
    Height = 25
    Caption = 'TManagedRecord'
    TabOrder = 5
    OnClick = btnSerSimpleMRecordClick
  end
  object btnDesSimpleMRecord: TButton
    Left = 485
    Top = 64
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'TManagedRecord'
    TabOrder = 6
  end
  object btnSerSimpleRecord: TButton
    Left = 3
    Top = 33
    Width = 131
    Height = 25
    Caption = 'TMyRecord'
    TabOrder = 7
    OnClick = btnSerSimpleRecordClick
  end
  object btnDesSimpleRecord: TButton
    Left = 485
    Top = 33
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'TMyRecord'
    TabOrder = 8
    OnClick = btnDesSimpleRecordClick
  end
end
