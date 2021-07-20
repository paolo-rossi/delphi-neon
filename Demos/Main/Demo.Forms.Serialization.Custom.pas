{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2021 Paolo Rossi                                         }
{  https://github.com/paolo-rossi/neon-library                                 }
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
unit Demo.Forms.Serialization.Custom;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Rtti,
  System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList, Vcl.CategoryButtons,

  Demo.Forms.Serialization.Base,
  Demo.Frame.Configuration,
  Neon.Core.Types,
  Neon.Core.Nullables,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Utils;

type
  TfrmSerializationCustom = class(TfrmSerializationBase)
    actSerTMyClass: TAction;
    actSerTParameter: TAction;
    actSerTFont: TAction;
    actSerTCaseClass: TAction;
    actSerNullableClass: TAction;
    actSerNeonInclude: TAction;
    actDesTMyClass: TAction;
    actDesTParameter: TAction;
    actDesTFont: TAction;
    actDesTCaseClass: TAction;
    actDesNullableClass: TAction;
    actDesNeonInclude: TAction;
    actSerNullableInteger: TAction;
    actDesNullableInteger: TAction;
    actSerTGUID: TAction;
    actSerTTime: TAction;
    actDesTGUID: TAction;
    actDesTTime: TAction;
    actSerDates: TAction;
    actDesDates: TAction;
    procedure actDesDatesExecute(Sender: TObject);
    procedure actDesNeonIncludeExecute(Sender: TObject);
    procedure actDesNullableClassExecute(Sender: TObject);
    procedure actDesNullableIntegerExecute(Sender: TObject);
    procedure actDesTCaseClassExecute(Sender: TObject);
    procedure actDesTFontExecute(Sender: TObject);
    procedure actDesTGUIDExecute(Sender: TObject);
    procedure actDesTMyClassExecute(Sender: TObject);
    procedure actDesTParameterExecute(Sender: TObject);
    procedure actDesTTimeExecute(Sender: TObject);
    procedure actSerDatesExecute(Sender: TObject);
    procedure actSerNeonIncludeExecute(Sender: TObject);
    procedure actSerNullableClassExecute(Sender: TObject);
    procedure actSerNullableIntegerExecute(Sender: TObject);
    procedure actSerTCaseClassExecute(Sender: TObject);
    procedure actSerTFontExecute(Sender: TObject);
    procedure actSerTGUIDExecute(Sender: TObject);
    procedure actSerTMyClassExecute(Sender: TObject);
    procedure actSerTParameterExecute(Sender: TObject);
    procedure actSerTTimeExecute(Sender: TObject);
  private
    function BuildConfig: INeonConfiguration;
  public
    { Public declarations }
  end;

var
  frmSerializationCustom: TfrmSerializationCustom;

implementation

uses
  System.Generics.Collections,
  Demo.Neon.Serializers,
  Demo.Neon.Entities;

{$R *.dfm}

procedure TfrmSerializationCustom.actDesDatesExecute(Sender: TObject);
var
  LValue: TDates;
begin
  DeserializeSimple<TDates>(LValue);
end;

procedure TfrmSerializationCustom.actDesNeonIncludeExecute(Sender: TObject);
var
  LObj: TNeonIncludeEntity;
begin
  LObj := TNeonIncludeEntity.Create;
  try
    DeserializeObject(LObj, memoSerialize.Lines, BuildConfig);
    SerializeObject(LObj, memoDeserialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationCustom.actDesNullableClassExecute(Sender: TObject);
var
  LObj: TClassOfNullables;
begin
  LObj := TClassOfNullables.Create;
  try
    DeserializeObject(LObj, memoSerialize.Lines, BuildConfig);
    SerializeObject(LObj, memoDeserialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationCustom.actDesNullableIntegerExecute(Sender: TObject);
var
  LValue: Nullable<Integer>;
begin
  LValue := DeserializeValueTo<Nullable<Integer>>(memoSerialize.Lines, BuildConfig);
  SerializeValueFrom<Nullable<Integer>>(TValue.From<Nullable<Integer>>(LValue), memoDeserialize.Lines, BuildConfig);
end;

procedure TfrmSerializationCustom.actDesTCaseClassExecute(Sender: TObject);
var
  LVal: TCaseClass;
begin
  LVal := TCaseClass.Create;
  try
    DeserializeObject(LVal, memoSerialize.Lines, BuildConfig);
    SerializeObject(LVal, memoDeserialize.Lines, BuildConfig);
  finally
    LVal.Free;
  end;
end;

procedure TfrmSerializationCustom.actDesTFontExecute(Sender: TObject);
var
  LFont: TFont;
begin
  LFont := pnlDeserialize.Font;

  DeserializeObject(LFont, memoSerialize.Lines, BuildConfig);
  SerializeObject(LFont, memoDeserialize.Lines, BuildConfig);
end;

procedure TfrmSerializationCustom.actDesTGUIDExecute(Sender: TObject);
var
  LValue: TGUID;
begin
  LValue := DeserializeValueTo<TGUID>(memoSerialize.Lines, BuildConfig);
  SerializeValueFrom<TGUID>(TValue.From<TGUID>(LValue), memoDeserialize.Lines, BuildConfig);
end;

procedure TfrmSerializationCustom.actDesTMyClassExecute(Sender: TObject);
var
  LSimple: TMyClass;
begin
	// Instantiating derived class
  LSimple := TMyDerivedClass.Create;
  try
    DeserializeObject(LSimple, memoSerialize.Lines, BuildConfig);
    SerializeObject(LSimple, memoDeserialize.Lines, BuildConfig);
  finally
    LSimple.Free;
  end;
end;

procedure TfrmSerializationCustom.actDesTParameterExecute(Sender: TObject);
var
  LVal: TParameterContainer;
begin
  LVal := TParameterContainer.Create;
  try
    DeserializeObject(LVal, memoSerialize.Lines, BuildConfig);
    SerializeObject(LVal, memoDeserialize.Lines, BuildConfig);
  finally
    LVal.Free;
  end;
end;

procedure TfrmSerializationCustom.actDesTTimeExecute(Sender: TObject);
var
  LValue: TTime;
begin
  LValue := DeserializeValueTo<TTime>(memoSerialize.Lines, BuildConfig);
  SerializeValueFrom<TTime>(TValue.From<TTime>(LValue), memoDeserialize.Lines, BuildConfig);
end;

procedure TfrmSerializationCustom.actSerDatesExecute(Sender: TObject);
var
  LDates: TDates;
begin
  LDates.SampleData;
  SerializeValueFrom<TDates>(TValue.From<TDates>(LDates), memoSerialize.Lines, BuildConfig);
end;

procedure TfrmSerializationCustom.actSerNeonIncludeExecute(Sender: TObject);
var
  LObj: TNeonIncludeEntity;
begin
  LObj := TNeonIncludeEntity.Create;
  try
    LObj.Name := 'Paolo';
    LObj.Obj := nil;
    LObj.NullObject1 := nil;
    LObj.NullObject2 := nil;
    LObj.NString := '';
    LObj.NInteger := 0;

    SerializeObject(LObj, memoSerialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationCustom.actSerNullableClassExecute(Sender: TObject);
var
  LObj: TClassOfNullables;
begin
  LObj := TClassOfNullables.Create;
  try
    LObj.Name := nil;
    //LObj.Age := 50;
    LObj.Speed := TEnumSpeed.Medium;

    LObj.BirthDate := nil;

    SerializeObject(LObj, memoSerialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationCustom.actSerNullableIntegerExecute(Sender: TObject);
var
  LNullInt: Nullable<Integer>;
begin
  LNullInt := 42;
  SerializeValueFrom<Nullable<Integer>>(TValue.From<Nullable<Integer>>(LNullInt), memoSerialize.Lines, BuildConfig);
end;

procedure TfrmSerializationCustom.actSerTCaseClassExecute(Sender: TObject);
var
  LVal: TCaseClass;
begin
  LVal := TCaseClass.DefaultValues;
  try
    SerializeObject(LVal, memoSerialize.Lines, BuildConfig);
  finally
    LVal.Free;
  end;
end;

procedure TfrmSerializationCustom.actSerTFontExecute(Sender: TObject);
var
  LFont: TFont;
begin
  LFont := pnlSerialize.Font;
  SerializeObject(LFont, memoSerialize.Lines, BuildConfig);
end;

procedure TfrmSerializationCustom.actSerTGUIDExecute(Sender: TObject);
var
  LVal: TGUID;
begin
  CreateGUID(LVal);
  SerializeSimple<TGUID>(LVal);
end;

procedure TfrmSerializationCustom.actSerTMyClassExecute(Sender: TObject);
var
  LObj: TMyClass;
begin
  LObj := TMyDerivedClass.Create;
  try
    LObj.DefaultValues;
    SerializeObject(LObj, memoSerialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationCustom.actSerTParameterExecute(Sender: TObject);
var
  LParam: TParameterContainer;
begin
  LParam := TParameterContainer.Create;
  try
    //LParam.ref := TReference.Create;
    //LParam.ref.ref := '#components/schemas/Pets';
    LParam.name := 'Parameter Name';
    LParam.code := 200;
    //LParam.ref.ref := 'http://doc.url';
    LParam.par._in := '/pets/findByStatus?status=available';
    LParam.par.name := 'Host';
    LParam.par.description := 'Host Name (Server)';

    SerializeObject(LParam, memoSerialize.Lines, BuildConfig);
  finally
    LParam.Free;
  end;
end;

procedure TfrmSerializationCustom.actSerTTimeExecute(Sender: TObject);
begin
  SerializeSimple<TTime>(Now);
end;

function TfrmSerializationCustom.BuildConfig: INeonConfiguration;
begin
  Result := frmConfiguration.BuildSerializerConfig([TSerializersType.CustomNeon, TSerializersType.CustomDemo]);
end;

end.
