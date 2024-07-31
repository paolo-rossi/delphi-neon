{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization library for Delphi                                 }
{  Copyright (c) 2018  Paolo Rossi                                             }
{  https://github.com/paolo-rossi/delphi-neon                                  }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit Demo.Forms.Serialization.Records;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Actions,
  System.ImageList,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.CategoryButtons,
  Vcl.ActnList,
  Vcl.ImgList,
  Demo.Forms.Serialization.Base;

type
  TfrmSerializationRecords = class(TfrmSerializationBase)
    actSerRecord: TAction;
    actSerRecordManaged: TAction;
    actDesRecord: TAction;
    actDesRecordManaged: TAction;
    actSerArrayInt: TAction;
    actSerArrayString: TAction;
    actSerArrayEnum: TAction;
    actSerArrayEnumCustom: TAction;
    actSerEnum: TAction;
    actSerEnumCustom: TAction;
    actSerSetEnum: TAction;
    actSerSetEnumCustom: TAction;
    actDesArrayInt: TAction;
    actDesArrayString: TAction;
    actDesArrayEnum: TAction;
    actDesArrayEnumCustom: TAction;
    actDesEnum: TAction;
    actDesEnumCustom: TAction;
    actDesSetEnum: TAction;
    actDesSetEnumCustom: TAction;
    actSerSetNumber: TAction;
    actDesSetNumber: TAction;
    actSerSetBoolean: TAction;
    actDesSetBoolean: TAction;
    actSerSetChar: TAction;
    procedure actDesRecordExecute(Sender: TObject);
    procedure actDesRecordManagedExecute(Sender: TObject);
    procedure actSerRecordExecute(Sender: TObject);
    procedure actSerRecordManagedExecute(Sender: TObject);
    procedure actDesArrayEnumCustomExecute(Sender: TObject);
    procedure actDesArrayEnumExecute(Sender: TObject);
    procedure actDesArrayIntExecute(Sender: TObject);
    procedure actDesArrayStringExecute(Sender: TObject);
    procedure actDesEnumCustomExecute(Sender: TObject);
    procedure actDesEnumExecute(Sender: TObject);
    procedure actDesSetBooleanExecute(Sender: TObject);
    procedure actDesSetEnumCustomExecute(Sender: TObject);
    procedure actDesSetEnumExecute(Sender: TObject);
    procedure actDesSetNumberExecute(Sender: TObject);
    procedure actDesVariantsExecute(Sender: TObject);
    procedure actSerArrayEnumCustomExecute(Sender: TObject);
    procedure actSerArrayEnumExecute(Sender: TObject);
    procedure actSerArrayIntExecute(Sender: TObject);
    procedure actSerArrayStringExecute(Sender: TObject);
    procedure actSerEnumCustomExecute(Sender: TObject);
    procedure actSerEnumExecute(Sender: TObject);
    procedure actSerSetBooleanExecute(Sender: TObject);
    procedure actSerSetCharExecute(Sender: TObject);
    procedure actSerSetEnumCustomExecute(Sender: TObject);
    procedure actSerSetEnumExecute(Sender: TObject);
    procedure actSerSetNumberExecute(Sender: TObject);
  end;

var
  frmSerializationRecords: TfrmSerializationRecords;

implementation

uses
  System.Rtti,
  Demo.Neon.Entities;

{$R *.dfm}

procedure TfrmSerializationRecords.actDesArrayEnumCustomExecute(Sender: TObject);
var
  LVal: TArraySpeed;
begin
  LVal := [];
  DeserializeSimple<TArraySpeed>(LVal);
end;

procedure TfrmSerializationRecords.actDesArrayEnumExecute(Sender: TObject);
var
  LVal: TArrayDuplicates;
begin
  LVal := [];
  DeserializeSimple<TArrayDuplicates>(LVal);
end;

procedure TfrmSerializationRecords.actDesArrayIntExecute(Sender: TObject);
var
  LVal: TIntArray;
begin
  LVal := [];
  DeserializeSimple<TIntArray>(LVal);
end;

procedure TfrmSerializationRecords.actDesArrayStringExecute(Sender: TObject);
var
  LVal: TArray<string>;
begin
  LVal := [];
  DeserializeSimple<TArray<string>>(LVal);
end;

procedure TfrmSerializationRecords.actDesEnumCustomExecute(Sender: TObject);
begin
  DeserializeSimple<TEnumSpeed>;
end;

procedure TfrmSerializationRecords.actDesEnumExecute(Sender: TObject);
begin
  DeserializeSimple<TDuplicates>;
end;

procedure TfrmSerializationRecords.actDesSetEnumCustomExecute(Sender: TObject);
var
  LVal: TSetSpeed;
begin
  LVal := [];
  DeserializeSimple<TSetSpeed>(LVal);
end;

procedure TfrmSerializationRecords.actDesSetEnumExecute(Sender: TObject);
var
  LVal: TSetDuplicates;
begin
  LVal := [];
  DeserializeSimple<TSetDuplicates>(LVal);
end;

procedure TfrmSerializationRecords.actDesVariantsExecute(Sender: TObject);
var
  LVariantObj: TVariantEntity;
begin
  LVariantObj := TVariantEntity.Create;
  try
    DeserializeObject(LVariantObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LVariantObj, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LVariantObj.Free;
  end;
end;

procedure TfrmSerializationRecords.actSerArrayEnumCustomExecute(Sender: TObject);
var
  LVal: TArraySpeed;
begin
  SetLength(LVal, 4);
  LVal[0] := TEnumSpeed.Low;
  LVal[1] := TEnumSpeed.High;
  LVal[2] := TEnumSpeed.Low;
  LVal[3] := TEnumSpeed.Medium;
  SerializeSimple<TArraySpeed>(LVal);
end;

procedure TfrmSerializationRecords.actSerArrayEnumExecute(Sender: TObject);
var
  LVal: TArrayDuplicates;
begin
  SetLength(LVal, 4);
  LVal[0] := dupIgnore;
  LVal[1] := dupAccept;
  LVal[2] := dupAccept;
  LVal[3] := dupError;
  SerializeSimple<TArrayDuplicates>(LVal);
end;

procedure TfrmSerializationRecords.actSerArrayIntExecute(Sender: TObject);
var
  LVal: TIntArray;
begin
  SetLength(LVal, 4);
  LVal[0] := 12;
  LVal[1] := 3243;
  LVal[2] := 0;
  LVal[3] := -234;
  SerializeSimple<TIntArray>(LVal);
end;

procedure TfrmSerializationRecords.actSerArrayStringExecute(Sender: TObject);
var
  LVal: TArray<string>;
begin
  SetLength(LVal, 4);
  LVal[0] := 'Paolo';
  LVal[1] := 'Rossi';
  LVal[2] := '';
  LVal[3] := '�����';
  SerializeSimple<TArray<string>>(LVal);
end;

procedure TfrmSerializationRecords.actSerEnumCustomExecute(Sender: TObject);
begin
  SerializeSimple<TEnumSpeed>(TEnumSpeed.High);
end;

procedure TfrmSerializationRecords.actSerEnumExecute(Sender: TObject);
begin
  SerializeSimple<TDuplicates>(dupIgnore);
end;

procedure TfrmSerializationRecords.actSerSetEnumCustomExecute(Sender: TObject);
var
  LValue: TSetSpeed;
begin
  LValue := [TEnumSpeed.Low, TEnumSpeed.High];
  SerializeSimple<TSetSpeed>(LValue);
end;

procedure TfrmSerializationRecords.actSerSetEnumExecute(Sender: TObject);
var
  LValue: TSetDuplicates;
begin
  LValue := [dupIgnore, dupAccept];
  SerializeSimple<TSetDuplicates>(LValue);
end;

procedure TfrmSerializationRecords.actDesRecordExecute(Sender: TObject);
var
  LRecord: TMyRecord;
begin
  DeserializeSimple<TMyRecord>(LRecord);
end;

procedure TfrmSerializationRecords.actDesRecordManagedExecute(Sender: TObject);
var
  LRecord: TManagedRecord;
begin
  DeserializeSimple<TManagedRecord>(LRecord);
end;

procedure TfrmSerializationRecords.actDesSetBooleanExecute(Sender: TObject);
var
  LVal: TSetBoolean;
begin
  LVal := [];
  DeserializeSimple<TSetBoolean>(LVal);
end;

procedure TfrmSerializationRecords.actDesSetNumberExecute(Sender: TObject);
var
  LVal: TSetWeekDays;
begin
  LVal := [];
  DeserializeSimple<TSetWeekDays>(LVal);
end;

procedure TfrmSerializationRecords.actSerRecordExecute(Sender: TObject);
var
  LVal: TMyRecord;
begin
  LVal.Speed := TEnumSpeed.Low;
  LVal.One := 'Test Test Test';
  LVal.Two := 42;
  SerializeSimple<TMyRecord>(LVal);
end;

procedure TfrmSerializationRecords.actSerRecordManagedExecute(Sender: TObject);
var
  LVal: TManagedRecord;
begin
  LVal.Name := 'Paolo';
  LVal.Age := 50;
  LVal.Height := 1.70;
  SerializeSimple<TManagedRecord>(LVal);
end;

procedure TfrmSerializationRecords.actSerSetBooleanExecute(Sender: TObject);
var
  LValue: TSetBoolean;
begin
  LValue := [False, True];
  SerializeSimple<TSetBoolean>(LValue);
end;

procedure TfrmSerializationRecords.actSerSetCharExecute(Sender: TObject);
var
  LValue: TSetUppercase;
begin
  LValue := ['P', 'Z', 'Q', 'A'];
  SerializeSimple<TSetUppercase>(LValue);
end;

procedure TfrmSerializationRecords.actSerSetNumberExecute(Sender: TObject);
var
  LValue: TSetWeekDays;
begin
  LValue := [1,4,7];
  SerializeSimple<TSetWeekDays>(LValue);
end;

end.
