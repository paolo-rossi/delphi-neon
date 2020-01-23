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
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  Demo.Forms.Serialization.Base,
  Demo.Frame.Configuration,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Utils;

type
  TfrmSerializationCustom = class(TfrmSerializationBase)
    btnSerMyClass: TButton;
    btnDesMyClass: TButton;
    btnSerParameter: TButton;
    btnSerFont: TButton;
    btnSerCaseClass: TButton;
    btnDesCaseClass: TButton;
    btnDesParameter: TButton;
    btnDesFont: TButton;
    btnSerNullables: TButton;
    btnDesNullables: TButton;
    procedure btnSerCaseClassClick(Sender: TObject);
    procedure btnDesCaseClassClick(Sender: TObject);
    procedure btnDesFontClick(Sender: TObject);
    procedure btnSerFontClick(Sender: TObject);
    procedure btnSerParameterClick(Sender: TObject);
    procedure btnSerMyClassClick(Sender: TObject);
    procedure btnDesMyClassClick(Sender: TObject);
    procedure btnDesNullablesClick(Sender: TObject);
    procedure btnDesParameterClick(Sender: TObject);
    procedure btnSerNullablesClick(Sender: TObject);
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

procedure TfrmSerializationCustom.btnSerCaseClassClick(Sender: TObject);
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

procedure TfrmSerializationCustom.btnDesCaseClassClick(Sender: TObject);
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

procedure TfrmSerializationCustom.btnDesFontClick(Sender: TObject);
var
  LVal: TFont;
begin
  LVal := (Sender as TButton).Font;

  DeserializeObject(LVal, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  SerializeObject(LVal, memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationCustom.btnSerFontClick(Sender: TObject);
var
  LFont: TFont;
begin
  LFont := (Sender as TButton).Font;
  SerializeObject(LFont, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationCustom.btnSerParameterClick(Sender: TObject);
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

procedure TfrmSerializationCustom.btnSerMyClassClick(Sender: TObject);
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

procedure TfrmSerializationCustom.btnDesMyClassClick(Sender: TObject);
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

procedure TfrmSerializationCustom.btnDesNullablesClick(Sender: TObject);
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

procedure TfrmSerializationCustom.btnDesParameterClick(Sender: TObject);
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

procedure TfrmSerializationCustom.btnSerNullablesClick(Sender: TObject);
var
  LObj: TClassOfNullables;
begin
  LObj := TClassOfNullables.Create;
  try
    LObj.Name := 'Paolo';
    //LObj.Age := 50;
    LObj.Speed := TEnumSpeed.Medium;

    SerializeObject(LObj, memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
  finally
    LObj.Free;
  end;
end;

end.
