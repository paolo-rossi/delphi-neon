{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018 Paolo Rossi                                              }
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
unit Demo.Forms.Serialization.Simple;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.ImageList,
  System.Actions,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ImgList,
  Vcl.CategoryButtons,
  Vcl.ActnList,
  Demo.Forms.Serialization.Base;

type
  TfrmSerializationSimple = class(TfrmSerializationBase)
    actSerInteger: TAction;
    actSerString: TAction;
    actSerFloat: TAction;
    actSerBoolean: TAction;
    actSerDateTime: TAction;
    actSerTypesClass: TAction;
    actSerVariants: TAction;
    actSerEnum: TAction;
    actSerEnumCustom: TAction;
    actDesInteger: TAction;
    actDesString: TAction;
    actDesFloat: TAction;
    actDesBoolean: TAction;
    actDesDateTime: TAction;
    actDesTypesClass: TAction;
    actDesVariants: TAction;
    actDesEnum: TAction;
    actDesEnumCustom: TAction;
    procedure actDesDateTimeExecute(Sender: TObject);
    procedure actDesBooleanExecute(Sender: TObject);
    procedure actDesEnumCustomExecute(Sender: TObject);
    procedure actDesEnumExecute(Sender: TObject);
    procedure actDesFloatExecute(Sender: TObject);
    procedure actDesIntegerExecute(Sender: TObject);
    procedure actDesStringExecute(Sender: TObject);
    procedure actDesTypesClassExecute(Sender: TObject);
    procedure actDesVariantsExecute(Sender: TObject);
    procedure actSerBooleanExecute(Sender: TObject);
    procedure actSerDateTimeExecute(Sender: TObject);
    procedure actSerEnumCustomExecute(Sender: TObject);
    procedure actSerEnumExecute(Sender: TObject);
    procedure actSerFloatExecute(Sender: TObject);
    procedure actSerIntegerExecute(Sender: TObject);
    procedure actSerStringExecute(Sender: TObject);
    procedure actSerTypesClassExecute(Sender: TObject);
    procedure actSerVariantsExecute(Sender: TObject);
  end;

var
  frmSerializationSimple: TfrmSerializationSimple;

implementation

uses
  System.Rtti,
  Demo.Neon.Entities;

{$R *.dfm}

procedure TfrmSerializationSimple.actDesDateTimeExecute(Sender: TObject);
begin
  DeserializeSimple<TDateTime>;
end;

procedure TfrmSerializationSimple.actDesBooleanExecute(Sender: TObject);
begin
  DeserializeSimple<Boolean>;
end;

procedure TfrmSerializationSimple.actDesEnumCustomExecute(Sender: TObject);
begin
  DeserializeSimple<TEnumSpeed>;
end;

procedure TfrmSerializationSimple.actDesEnumExecute(Sender: TObject);
begin
  DeserializeSimple<TDuplicates>;
end;

procedure TfrmSerializationSimple.actDesFloatExecute(Sender: TObject);
begin
  DeserializeSimple<Double>;
end;

procedure TfrmSerializationSimple.actDesIntegerExecute(Sender: TObject);
begin
  DeserializeSimple<UInt64>;
end;

procedure TfrmSerializationSimple.actDesStringExecute(Sender: TObject);
begin
  DeserializeSimple<string>;
end;

procedure TfrmSerializationSimple.actDesTypesClassExecute(Sender: TObject);
var
  LTypeClass: TTypeClass;
begin
  LTypeClass := TTypeClass.Create;
  try
    DeserializeObject(LTypeClass, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
    SerializeObject(LTypeClass, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LTypeClass.Free;
  end;
end;

procedure TfrmSerializationSimple.actDesVariantsExecute(Sender: TObject);
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

procedure TfrmSerializationSimple.actSerBooleanExecute(Sender: TObject);
begin
  SerializeSimple<Boolean>(True);
end;

procedure TfrmSerializationSimple.actSerDateTimeExecute(Sender: TObject);
begin
  SerializeSimple<TDateTime>(Now);
end;

procedure TfrmSerializationSimple.actSerEnumCustomExecute(Sender: TObject);
begin
  SerializeSimple<TEnumSpeed>(TEnumSpeed.High);
end;

procedure TfrmSerializationSimple.actSerEnumExecute(Sender: TObject);
begin
  SerializeSimple<TDuplicates>(dupIgnore);
end;

procedure TfrmSerializationSimple.actSerFloatExecute(Sender: TObject);
begin
  SerializeSimple<Double>(123.42);
end;

procedure TfrmSerializationSimple.actSerIntegerExecute(Sender: TObject);
begin
  SerializeSimple<Integer>(42);
end;

procedure TfrmSerializationSimple.actSerStringExecute(Sender: TObject);
begin
  SerializeSimple<string>('Lorem "Ipsum" \n \\ {} �����');
end;

procedure TfrmSerializationSimple.actSerTypesClassExecute(Sender: TObject);
var
  LTypeObj: TTypeClass;
begin
  LTypeObj := TTypeClass.Create;
  try
    SerializeObject(LTypeObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LTypeObj.Free;
  end;
end;

procedure TfrmSerializationSimple.actSerVariantsExecute(Sender: TObject);
var
  LVariantObj: TVariantEntity;
begin
  LVariantObj := TVariantEntity.Create;

  LVariantObj.Prop1 := Null;
  LVariantObj.Prop2 := 'Paolo';
  LVariantObj.Prop3 := 123.45;
  LVariantObj.Prop4 := True;
  LVariantObj.Prop5 := Now();

  try
    SerializeObject(LVariantObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LVariantObj.Free;
  end;
end;

end.
