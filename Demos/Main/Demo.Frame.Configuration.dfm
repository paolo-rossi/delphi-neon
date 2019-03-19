object frameConfiguration: TframeConfiguration
  Left = 0
  Top = 0
  Width = 567
  Height = 156
  TabOrder = 0
  object Label1: TLabel
    Left = 16
    Top = 7
    Width = 207
    Height = 18
    Alignment = taCenter
    Caption = 'Neon Configuration Options'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -15
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object grpCase: TGroupBox
    Left = 142
    Top = 35
    Width = 387
    Height = 46
    Caption = 'Case '
    TabOrder = 0
    object rbCasePascal: TRadioButton
      Left = 8
      Top = 16
      Width = 57
      Height = 17
      Caption = 'Pascal'
      Checked = True
      TabOrder = 0
      TabStop = True
    end
    object rbCaseCamel: TRadioButton
      Left = 71
      Top = 16
      Width = 50
      Height = 17
      Caption = 'Camel'
      TabOrder = 1
    end
    object rbCaseSnake: TRadioButton
      Left = 133
      Top = 16
      Width = 50
      Height = 17
      Caption = 'Snake'
      TabOrder = 2
    end
    object rbCaseLower: TRadioButton
      Left = 195
      Top = 16
      Width = 50
      Height = 17
      Caption = 'Lower'
      TabOrder = 3
    end
    object rbCaseUpper: TRadioButton
      Left = 251
      Top = 16
      Width = 50
      Height = 17
      Caption = 'Upper'
      TabOrder = 4
    end
    object rbCaseCustom: TRadioButton
      Left = 310
      Top = 16
      Width = 58
      Height = 17
      Caption = 'Custom'
      TabOrder = 5
    end
  end
  object grpPrefix: TGroupBox
    Left = 246
    Top = 87
    Width = 283
    Height = 46
    Caption = 'Visibility '
    TabOrder = 1
    object chkVisibilityPrivate: TCheckBox
      Left = 7
      Top = 16
      Width = 66
      Height = 17
      Caption = 'Private'
      TabOrder = 0
    end
    object chkVisibilityPublic: TCheckBox
      Left = 147
      Top = 16
      Width = 66
      Height = 17
      Caption = 'Public'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object chkVisibilityPublished: TCheckBox
      Left = 205
      Top = 16
      Width = 66
      Height = 17
      Caption = 'Published'
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
    object chkVisibilityProtected: TCheckBox
      Left = 69
      Top = 16
      Width = 66
      Height = 17
      Caption = 'Protected'
      TabOrder = 3
    end
  end
  object grpType: TGroupBox
    Left = 16
    Top = 87
    Width = 224
    Height = 46
    Hint = 'Standard: FIelds for records, Properties for Objects'
    Caption = 'Members '
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    object rbMemberStandard: TRadioButton
      Left = 7
      Top = 16
      Width = 81
      Height = 17
      Caption = 'Standard'
      Checked = True
      ParentShowHint = False
      ShowHint = False
      TabOrder = 0
      TabStop = True
    end
    object rbMemberFields: TRadioButton
      Left = 83
      Top = 16
      Width = 49
      Height = 17
      Caption = 'Fields'
      TabOrder = 1
    end
    object rbMemberProperties: TRadioButton
      Left = 139
      Top = 16
      Width = 74
      Height = 17
      Caption = 'Properties'
      TabOrder = 2
    end
  end
  object grpVisibility: TGroupBox
    Left = 16
    Top = 35
    Width = 120
    Height = 46
    Caption = 'Field Prefix "F" '
    TabOrder = 3
    object chkIgnorePrefix: TCheckBox
      Left = 7
      Top = 16
      Width = 107
      Height = 17
      Caption = 'Ignore Prefix "F"'
      TabOrder = 0
    end
  end
end
