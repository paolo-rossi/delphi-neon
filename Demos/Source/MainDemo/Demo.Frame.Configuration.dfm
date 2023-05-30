object frameConfiguration: TframeConfiguration
  Left = 0
  Top = 0
  Width = 710
  Height = 157
  TabOrder = 0
  object lblCaption: TLabel
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
    Left = 16
    Top = 35
    Width = 529
    Height = 46
    Caption = 'Case '
    TabOrder = 0
    object rbCaseUnchanged: TRadioButton
      Left = 10
      Top = 16
      Width = 90
      Height = 17
      Caption = 'Unchanged'
      TabOrder = 6
    end
    object rbCasePascal: TRadioButton
      Left = 106
      Top = 16
      Width = 65
      Height = 17
      Caption = 'Pascal'
      Checked = True
      TabOrder = 0
      TabStop = True
    end
    object rbCaseCamel: TRadioButton
      Left = 177
      Top = 16
      Width = 65
      Height = 17
      Caption = 'Camel'
      TabOrder = 1
    end
    object rbCaseSnake: TRadioButton
      Left = 248
      Top = 16
      Width = 65
      Height = 17
      Caption = 'Snake'
      TabOrder = 2
    end
    object rbCaseLower: TRadioButton
      Left = 319
      Top = 16
      Width = 65
      Height = 17
      Caption = 'Lower'
      TabOrder = 3
    end
    object rbCaseUpper: TRadioButton
      Left = 390
      Top = 16
      Width = 65
      Height = 17
      Caption = 'Upper'
      TabOrder = 4
    end
    object rbCaseCustom: TRadioButton
      Left = 461
      Top = 16
      Width = 65
      Height = 17
      Caption = 'Custom'
      TabOrder = 5
    end
  end
  object grpPrefix: TGroupBox
    Left = 246
    Top = 99
    Width = 299
    Height = 46
    Caption = 'Visibility '
    TabOrder = 1
    object chkVisibilityPrivate: TCheckBox
      Left = 7
      Top = 16
      Width = 70
      Height = 17
      Caption = 'Private'
      TabOrder = 0
    end
    object chkVisibilityPublic: TCheckBox
      Left = 145
      Top = 16
      Width = 70
      Height = 17
      Caption = 'Public'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object chkVisibilityPublished: TCheckBox
      Left = 213
      Top = 16
      Width = 76
      Height = 17
      Caption = 'Published'
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
    object chkVisibilityProtected: TCheckBox
      Left = 69
      Top = 16
      Width = 70
      Height = 17
      Caption = 'Protected'
      TabOrder = 3
    end
  end
  object grpType: TGroupBox
    Left = 16
    Top = 99
    Width = 224
    Height = 46
    Hint = 'Standard: FIelds for records, Properties for Objects'
    Caption = 'Members '
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    object chkMemberStandard: TCheckBox
      Left = 7
      Top = 16
      Width = 66
      Height = 17
      Caption = 'Standard'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object chkMemberFields: TCheckBox
      Left = 83
      Top = 16
      Width = 50
      Height = 17
      Caption = 'Field'
      TabOrder = 1
    end
    object chkMemberProperties: TCheckBox
      Left = 139
      Top = 16
      Width = 82
      Height = 17
      Caption = 'Properties'
      TabOrder = 2
    end
  end
  object grpMisc: TGroupBox
    Left = 551
    Top = 3
    Width = 146
    Height = 142
    Caption = 'Misc Options '
    TabOrder = 3
    object chkUseUTCDate: TCheckBox
      Left = 7
      Top = 47
      Width = 107
      Height = 17
      Caption = 'Use UTC Dates'
      TabOrder = 0
    end
    object chkPrettyPrinting: TCheckBox
      Left = 7
      Top = 72
      Width = 107
      Height = 17
      Caption = 'Pretty Printing'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object chkIgnorePrefix: TCheckBox
      Left = 7
      Top = 22
      Width = 107
      Height = 17
      Caption = 'Ignore Prefix "F"'
      TabOrder = 2
    end
    object chkAutoCreate: TCheckBox
      Left = 7
      Top = 95
      Width = 107
      Height = 17
      Caption = 'AutoCreate'
      TabOrder = 3
    end
    object chkStrictTypes: TCheckBox
      Left = 7
      Top = 118
      Width = 107
      Height = 17
      Caption = 'Strict Types'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
  end
end
