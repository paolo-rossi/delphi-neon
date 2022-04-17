inherited frmSerializationCustom: TfrmSerializationCustom
  Caption = 'frmSerializationCustom'
  TextHeight = 13
  inherited memoLog: TMemo
    TabOrder = 2
  end
  inherited pnlLeft: TPanel
    TabOrder = 0
    inherited catSerialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Classes'
          Color = 13026810
          Collapsed = False
          Items = <
            item
              Action = actSerTMyClass
            end
            item
              Action = actSerTParameter
            end
            item
              Action = actSerTFont
            end
            item
              Action = actSerTCaseClass
            end>
        end
        item
          Caption = 'Value Types'
          Color = 4040177
          Collapsed = False
          Items = <
            item
              Action = actSerTGUID
            end
            item
              Action = actSerTTime
            end>
        end
        item
          Caption = 'Nullables'
          Color = 15459203
          Collapsed = False
          Items = <
            item
              Action = actSerNullableInteger
            end
            item
              Action = actSerNullableClass
            end>
        end
        item
          Caption = 'Misc'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actSerNeonInclude
            end
            item
              Action = actSerDates
            end>
        end>
    end
  end
  inherited pnlRight: TPanel
    TabOrder = 1
    inherited catDeserialize: TCategoryButtons
      Categories = <
        item
          Caption = 'Classes'
          Color = 13026810
          Collapsed = False
          Items = <
            item
              Action = actDesTMyClass
            end
            item
              Action = actDesTParameter
            end
            item
              Action = actDesTFont
            end
            item
              Action = actDesTCaseClass
            end>
        end
        item
          Caption = 'Value Types'
          Color = 4040177
          Collapsed = False
          Items = <
            item
              Action = actDesTGUID
            end
            item
              Action = actDesTTime
            end>
        end
        item
          Caption = 'Nullables'
          Color = 15459203
          Collapsed = False
          Items = <
            item
              Action = actDesNullableInteger
            end
            item
              Action = actDesNullableClass
            end>
        end
        item
          Caption = 'Misc'
          Color = 7928316
          Collapsed = False
          Items = <
            item
              Action = actDesNeonInclude
            end
            item
              Action = actDesDates
            end>
        end>
    end
  end
  inherited aclMain: TActionList
    object actSerTMyClass: TAction
      Caption = 'TMyClass'
      ImageIndex = 0
      OnExecute = actSerTMyClassExecute
    end
    object actSerTParameter: TAction
      Caption = 'TParameter'
      ImageIndex = 0
      OnExecute = actSerTParameterExecute
    end
    object actSerTFont: TAction
      Caption = 'TFont'
      ImageIndex = 0
      OnExecute = actSerTFontExecute
    end
    object actSerTCaseClass: TAction
      Caption = 'TCaseClass'
      ImageIndex = 0
      OnExecute = actSerTCaseClassExecute
    end
    object actSerNullableInteger: TAction
      Caption = 'Nullable<Integer>'
      ImageIndex = 0
      OnExecute = actSerNullableIntegerExecute
    end
    object actSerNullableClass: TAction
      Caption = 'Class of Nullables'
      ImageIndex = 0
      OnExecute = actSerNullableClassExecute
    end
    object actSerNeonInclude: TAction
      Caption = 'NeonInclude Test'
      ImageIndex = 0
      OnExecute = actSerNeonIncludeExecute
    end
    object actSerTGUID: TAction
      Caption = 'TGUID'
      ImageIndex = 0
      OnExecute = actSerTGUIDExecute
    end
    object actSerTTime: TAction
      Caption = 'TTime'
      ImageIndex = 0
      OnExecute = actSerTTimeExecute
    end
    object actSerDates: TAction
      Caption = 'Dates (record)'
      ImageIndex = 0
      OnExecute = actSerDatesExecute
    end
    object actDesTMyClass: TAction
      Caption = 'TMyClass'
      ImageIndex = 1
      OnExecute = actDesTMyClassExecute
    end
    object actDesTParameter: TAction
      Caption = 'TParameter'
      ImageIndex = 1
      OnExecute = actDesTParameterExecute
    end
    object actDesTFont: TAction
      Caption = 'TFont'
      ImageIndex = 1
      OnExecute = actDesTFontExecute
    end
    object actDesTCaseClass: TAction
      Caption = 'TCaseClass'
      ImageIndex = 1
      OnExecute = actDesTCaseClassExecute
    end
    object actDesNullableClass: TAction
      Caption = 'Class of Nullables'
      ImageIndex = 1
      OnExecute = actDesNullableClassExecute
    end
    object actDesNeonInclude: TAction
      Caption = 'NeonInclude Test'
      ImageIndex = 1
      OnExecute = actDesNeonIncludeExecute
    end
    object actDesNullableInteger: TAction
      Caption = 'Nullable<Integer>'
      ImageIndex = 1
      OnExecute = actDesNullableIntegerExecute
    end
    object actDesTGUID: TAction
      Caption = 'TGUID'
      ImageIndex = 1
      OnExecute = actDesTGUIDExecute
    end
    object actDesTTime: TAction
      Caption = 'TTime'
      ImageIndex = 1
      OnExecute = actDesTTimeExecute
    end
    object actDesDates: TAction
      Caption = 'Dates (record)'
      ImageIndex = 1
      OnExecute = actDesDatesExecute
    end
  end
end
