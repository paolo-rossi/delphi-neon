inherited frmSerializationDelphi: TfrmSerializationDelphi
  Caption = 'frmSerializationDelphi'
  ClientWidth = 971
  OnCreate = FormCreate
  ExplicitWidth = 983
  TextHeight = 13
  inherited memoLog: TMemo
    Width = 971
    ExplicitWidth = 967
  end
  inherited pnlLeft: TPanel
    inherited catSerialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Delphi Types'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actSerDataSet
            end
            item
              Action = actSerImage
            end
            item
              Action = actSerBitmap
            end
            item
              Action = actStringList
            end>
        end>
    end
    object btnShowDetailsLeft: TButton
      Left = 19
      Top = 174
      Width = 116
      Height = 25
      Caption = 'Show Details'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = btnShowDetailsClick
    end
  end
  inherited pnlRight: TPanel
    Width = 468
    ExplicitWidth = 464
    inherited pnlDeserialize: TPanel
      Width = 468
      ExplicitWidth = 464
    end
    inherited catDeserialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Delphi Types'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actDesDataSet
            end
            item
              Action = actDesImage
            end
            item
              Action = actDesBitmap
            end
            item
              Action = actDesStringList
            end>
        end>
    end
    inherited memoDeserialize: TMemo
      Width = 315
      ExplicitWidth = 311
    end
    object btnShowDetails: TButton
      Left = 19
      Top = 174
      Width = 116
      Height = 25
      Caption = 'Show Details'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = btnShowDetailsClick
    end
  end
  inherited aclMain: TActionList
    object actSerDataSet: TAction
      Caption = 'DataSet'
      ImageIndex = 0
      OnExecute = actSerDataSetExecute
    end
    object actSerImage: TAction
      Caption = 'Image (TImage)'
      ImageIndex = 0
      OnExecute = actSerImageExecute
    end
    object actSerBitmap: TAction
      Caption = 'Image (TBitmap)'
      ImageIndex = 0
      OnExecute = actSerBitmapExecute
    end
    object actStringList: TAction
      Caption = 'StringList'
      ImageIndex = 0
      OnExecute = actStringListExecute
    end
    object actDesDataSet: TAction
      Caption = 'DataSet'
      ImageIndex = 1
      OnExecute = actDesDataSetExecute
    end
    object actDesImage: TAction
      Caption = 'Image (TImage)'
      ImageIndex = 1
      OnExecute = actDesImageExecute
    end
    object actDesBitmap: TAction
      Caption = 'Image (TBitmap)'
      ImageIndex = 1
      OnExecute = actDesBitmapExecute
    end
    object actDesStringList: TAction
      Caption = 'StringList'
      ImageIndex = 1
      OnExecute = actDesStringListExecute
    end
  end
end
