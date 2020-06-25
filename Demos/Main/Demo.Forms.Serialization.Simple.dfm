inherited frmSerializationSimple: TfrmSerializationSimple
  Caption = 'frmSerializationSimple'
  PixelsPerInch = 96
  TextHeight = 13
  inherited pnlSerialize: TPanel
    TabOrder = 14
  end
  object btnSerSimpleInteger: TButton [1]
    Left = 3
    Top = 32
    Width = 131
    Height = 25
    Caption = 'Intgeger'
    TabOrder = 0
    OnClick = btnSerSimpleIntegerClick
  end
  object btnSerSimpleString: TButton [2]
    Left = 3
    Top = 63
    Width = 131
    Height = 25
    Caption = 'String'
    TabOrder = 1
    OnClick = btnSerSimpleStringClick
  end
  object btnSerSimpleDatTime: TButton [3]
    Left = 3
    Top = 156
    Width = 131
    Height = 25
    Caption = 'DateTime'
    TabOrder = 2
    OnClick = btnSerSimpleDatTimeClick
  end
  object btnSerSimpleArray: TButton [4]
    Left = 3
    Top = 187
    Width = 131
    Height = 25
    Caption = 'Int Array'
    TabOrder = 4
    OnClick = btnSerSimpleArrayClick
  end
  object btnSerSimpleFloat: TButton [5]
    Left = 3
    Top = 94
    Width = 131
    Height = 25
    Caption = 'Float'
    TabOrder = 5
    OnClick = btnSerSimpleFloatClick
  end
  object btnSerSimpleBool: TButton [6]
    Left = 3
    Top = 125
    Width = 131
    Height = 25
    Caption = 'Boolean'
    TabOrder = 6
    OnClick = btnSerSimpleBoolClick
  end
  object btnDesSimpleInteger: TButton [7]
    Left = 485
    Top = 33
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Intgeger'
    TabOrder = 7
    OnClick = btnDesSimpleIntegerClick
  end
  object btnDesSimpleString: TButton [8]
    Left = 485
    Top = 64
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'String'
    TabOrder = 8
    OnClick = btnDesSimpleStringClick
  end
  object btnDesSimpleDateTime: TButton [9]
    Left = 485
    Top = 157
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'DateTime'
    TabOrder = 9
    OnClick = btnDesSimpleDateTimeClick
  end
  object btnDesSimpleArray: TButton [10]
    Left = 485
    Top = 188
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Int Array'
    TabOrder = 10
    OnClick = btnDesSimpleArrayClick
  end
  object btnDesSimpleFloat: TButton [11]
    Left = 485
    Top = 95
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Float'
    TabOrder = 11
    OnClick = btnDesSimpleFloatClick
  end
  object btnDesSimpleBool: TButton [12]
    Left = 485
    Top = 126
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Boolean'
    TabOrder = 12
    OnClick = btnDesSimpleBoolClick
  end
  inherited memoSerialize: TMemo
    TabOrder = 15
  end
  inherited pnlDeserialize: TPanel
    TabOrder = 16
  end
  inherited memoLog: TMemo
    TabOrder = 13
  end
  object btnSerTypeClass: TButton
    Left = 3
    Top = 217
    Width = 131
    Height = 25
    Caption = 'Types Class'
    TabOrder = 17
    OnClick = btnSerTypeClassClick
  end
  object btnDesTypeClass: TButton
    Left = 485
    Top = 217
    Width = 131
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Types Class'
    TabOrder = 18
    OnClick = btnDesTypeClassClick
  end
end
