{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2019 Paolo Rossi                                         }
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

  Demo.Forms.Serialization.Base,
  Demo.Frame.Configuration,
  Neon.Core.Types,
  Neon.Core.Nullables,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Utils, System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList,
  Vcl.CategoryButtons;

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
    procedure actDesNeonIncludeExecute(Sender: TObject);
    procedure actDesNullableClassExecute(Sender: TObject);
    procedure actDesNullableIntegerExecute(Sender: TObject);
    procedure actDesTCaseClassExecute(Sender: TObject);
    procedure actDesTFontExecute(Sender: TObject);
    procedure actDesTMyClassExecute(Sender: TObject);
    procedure actDesTParameterExecute(Sender: TObject);
    procedure actSerNeonIncludeExecute(Sender: TObject);
    procedure actSerNullableClassExecute(Sender: TObject);
    procedure actSerNullableIntegerExecute(Sender: TObject);
    procedure actSerTCaseClassExecute(Sender: TObject);
    procedure actSerTFontExecute(Sender: TObject);
    procedure actSerTMyClassExecute(Sender: TObject);
    procedure actSerTParameterExecute(Sender: TObject);
  private
    { Private declarations }
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

procedure TfrmSerializationCustom.actDesNeonIncludeExecute(Sender: TObject);
var
  LObj: TNeonIncludeEntity;
begin
  LObj := TNeonIncludeEntity.Create;
  try
    DeserializeObject(LObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LObj, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
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
    DeserializeObject(LObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LObj, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationCustom.actDesNullableIntegerExecute(Sender: TObject);
var
  LValue: Nullable<Integer>;
begin
  LValue := DeserializeValueTo<Nullable<Integer>>(memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  SerializeValueFrom<Nullable<Integer>>(TValue.From<Nullable<Integer>>(LValue), memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationCustom.actDesTCaseClassExecute(Sender: TObject);
var
  LVal: TCaseClass;
begin
  LVal := TCaseClass.Create;
  try
    DeserializeObject(LVal, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LVal, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LVal.Free;
  end;
end;

procedure TfrmSerializationCustom.actDesTFontExecute(Sender: TObject);
var
  LFont: TFont;
begin
  LFont := pnlDeserialize.Font;

  DeserializeObject(LFont, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  SerializeObject(LFont, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationCustom.actDesTMyClassExecute(Sender: TObject);
var
  LSimple: TMyClass;
begin
	// Instantiating derived class
  LSimple := TMyDerivedClass.Create;
  try
    DeserializeObject(LSimple, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LSimple, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
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
    DeserializeObject(LVal, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LVal, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LVal.Free;
  end;
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

    SerializeObject(LObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
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

    SerializeObject(LObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationCustom.actSerNullableIntegerExecute(Sender: TObject);
var
  LNullInt: Nullable<Integer>;
begin
  LNullInt := 42;
  SerializeValueFrom<Nullable<Integer>>(TValue.From<Nullable<Integer>>(LNullInt), memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationCustom.actSerTCaseClassExecute(Sender: TObject);
var
  LVal: TCaseClass;
begin
  LVal := TCaseClass.DefaultValues;
  try
    SerializeObject(LVal, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LVal.Free;
  end;
end;

procedure TfrmSerializationCustom.actSerTFontExecute(Sender: TObject);
var
  LFont: TFont;
begin
  LFont := pnlSerialize.Font;
  SerializeObject(LFont, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationCustom.actSerTMyClassExecute(Sender: TObject);
var
  LObj: TMyClass;
begin
  LObj := TMyDerivedClass.Create;
  try
    LObj.DefaultValues;
    SerializeObject(LObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
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
    //LParam.ref.ref := 'http://doc.url';
    LParam.par._in := '\pets\findByStatus?status=available';
    LParam.par.name := 'Host';
    LParam.par.description := 'Host Name (Server)';

    SerializeObject(LParam, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LParam.Free;
  end;
end;

end.
