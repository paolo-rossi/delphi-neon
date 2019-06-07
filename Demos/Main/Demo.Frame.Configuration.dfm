object frameConfiguration: TframeConfiguration
  Left = 0
  Top = 0
  Width = 693
  Height = 148
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
    Width = 513
    Height = 46
    Caption = 'Case '
    TabOrder = 0
    object rbCasePascal: TRadioButton
      Left = 8
      Top = 16
      Width = 80
      Height = 17
      Caption = 'PascalCase'
      Checked = True
      TabOrder = 0
      TabStop = True
    end
    object rbCaseCamel: TRadioButton
      Left = 94
      Top = 16
      Width = 74
      Height = 17
      Caption = 'CamelCase'
      TabOrder = 1
    end
    object rbCaseSnake: TRadioButton
      Left = 174
      Top = 16
      Width = 75
      Height = 17
      Caption = 'SnakeCase'
      TabOrder = 2
    end
    object rbCaseLower: TRadioButton
      Left = 257
      Top = 16
      Width = 73
      Height = 17
      Caption = 'LowerCase'
      TabOrder = 3
    end
    object rbCaseUpper: TRadioButton
      Left = 340
      Top = 16
      Width = 74
      Height = 17
      Caption = 'UpperCase'
      TabOrder = 4
    end
    object rbCaseCustom: TRadioButton
      Left = 421
      Top = 16
      Width = 78
      Height = 17
      Caption = 'CustomCase'
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
      Width = 68
      Height = 17
      Caption = 'Properties'
      TabOrder = 2
    end
  end
  object GroupBox1: TGroupBox
    Left = 535
    Top = 35
    Width = 146
    Height = 98
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
  end
end
