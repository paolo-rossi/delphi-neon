inherited frmSerializationSchema: TfrmSerializationSchema
  Caption = 'frmSerializationSchema'
  PixelsPerInch = 96
  TextHeight = 13
  inherited pnlSerialize: TPanel
    Width = 955
    ExplicitWidth = 955
  end
  inherited memoSerialize: TMemo
    Width = 813
    ExplicitWidth = 813
  end
  inherited pnlDeserialize: TPanel
    Visible = False
  end
  inherited memoDeserialize: TMemo
    Visible = False
  end
  object btnSchemaCaseClass: TButton
    Left = 3
    Top = 33
    Width = 131
    Height = 25
    Caption = 'TCaseClass'
    TabOrder = 5
    OnClick = btnSchemaCaseClassClick
  end
end
