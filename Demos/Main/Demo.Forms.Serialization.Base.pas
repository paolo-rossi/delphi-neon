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
unit Demo.Forms.Serialization.Base;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Rtti, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.CategoryButtons, System.ImageList, Vcl.ImgList, System.Actions, Vcl.ActnList,

  Demo.Frame.Configuration,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Utils;

type
  TfrmSerializationBase = class(TForm)
    pnlSerialize: TPanel;
    memoSerialize: TMemo;
    pnlDeserialize: TPanel;
    memoDeserialize: TMemo;
    memoLog: TMemo;
    catSerialize: TCategoryButtons;
    imlMain: TImageList;
    catDeserialize: TCategoryButtons;
    aclMain: TActionList;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    splMain: TSplitter;
  protected
    frmConfiguration: TframeConfiguration;
    procedure Log(const ALog: string; AWhere: TStrings); overload;
    procedure LogError(const ALog: string); overload;
    procedure LogError(ALog: TStrings); overload;

    procedure SerializeObject(AObject: TObject; AWhere: TStrings; AConfig: INeonConfiguration);
    procedure DeserializeObject(AObject: TObject; AWhere: TStrings; AConfig: INeonConfiguration);

    procedure SerializeValueFrom<T>(AValue: TValue; AWhere: TStrings; AConfig: INeonConfiguration);
    function DeserializeValueTo<T>(AWhere: TStrings; AConfig: INeonConfiguration): T; overload;
    function DeserializeValueTo<T>(AValue: T; AWhere: TStrings; AConfig: INeonConfiguration): T; overload;

    procedure SerializeSimple<T>(AValue: T);
    procedure DeserializeSimple<T>; overload;
    procedure DeserializeSimple<T>(AValue: T); overload;
  public
    constructor CreateEx(AOwner: TComponent; AConfigForm: TframeConfiguration; AColor: TColor);
  public
    class function CreateTabForm(AOwner: TComponent; AConfigForm: TframeConfiguration; AColor: TColor): TfrmSerializationBase;
  end;

  TfrmSerializationClass = class of TfrmSerializationBase;

var
  frmSerializationBase: TfrmSerializationBase;

implementation

uses
  System.JSON;

{$R *.dfm}

{ TfrmSerializationBase }

constructor TfrmSerializationBase.CreateEx(AOwner: TComponent; AConfigForm: TframeConfiguration; AColor: TColor);
begin
  inherited Create(AOwner);
  frmConfiguration := AConfigForm;
  pnlSerialize.Color := AColor;
  pnlDeserialize.Color := AColor;
end;

procedure TfrmSerializationBase.SerializeObject(AObject: TObject; AWhere: TStrings; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    LJSON := LWriter.ObjectToJSON(AObject);
    try
      Log(TNeon.Print(LJSON, AConfig.GetPrettyPrint), AWhere);
      LogError(LWriter.Errors);
    finally
      LJSON.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

class function TfrmSerializationBase.CreateTabForm(AOwner: TComponent;
    AConfigForm: TframeConfiguration; AColor: TColor): TfrmSerializationBase;
begin
  Result := Self.CreateEx(AOwner, AConfigForm, AColor);
end;

procedure TfrmSerializationBase.DeserializeObject(AObject: TObject; AWhere: TStrings; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
  LReader: TNeonDeserializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(AWhere.Text);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(AConfig);
    try
      LReader.JSONToObject(AObject, LJSON);
      LogError(LReader.Errors);
    finally
      LReader.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TfrmSerializationBase.DeserializeSimple<T>;
var
  LVal: T;
begin
  LVal := DeserializeValueTo<T>(
    memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);

  SerializeValueFrom<T>(
    TValue.From<T>(LVal), memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationBase.DeserializeSimple<T>(AValue: T);
var
  LVal: T;
begin
  LVal := DeserializeValueTo<T>(AValue,
    memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);

  SerializeValueFrom<T>(
    TValue.From<T>(LVal), memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

function TfrmSerializationBase.DeserializeValueTo<T>(AValue: T; AWhere: TStrings;
  AConfig: INeonConfiguration): T;
var
  LJSON: TJSONValue;
  LValue: TValue;
  LReader: TNeonDeserializerJSON;
  LWriter: TNeonSerializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(AWhere.Text);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(AConfig);
    try
      LValue := LReader.JSONToTValue(LJSON, TRttiUtils.Context.GetType(TypeInfo(T)), TValue.From<T>(AValue));
      LogError(LReader.Errors);
      Result := LValue.AsType<T>;
    finally
      LReader.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TfrmSerializationBase.Log(const ALog: string; AWhere: TStrings);
begin
  AWhere.Text := ALog;
end;

procedure TfrmSerializationBase.LogError(ALog: TStrings);
begin
  memoLog.Lines.AddStrings(ALog);
end;

procedure TfrmSerializationBase.LogError(const ALog: string);
begin
  memoLog.Lines.Add(ALog);
end;

procedure TfrmSerializationBase.SerializeValueFrom<T>(AValue: TValue; AWhere: TStrings; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    LJSON := LWriter.ValueToJSON(AValue);
    try
      Log(TNeon.Print(LJSON, AConfig.GetPrettyPrint), AWhere);
      LogError(LWriter.Errors);
    finally
      LJSON.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

function TfrmSerializationBase.DeserializeValueTo<T>(AWhere: TStrings; AConfig: INeonConfiguration): T;
var
  LJSON: TJSONValue;
  LValue: TValue;
  LReader: TNeonDeserializerJSON;
  LWriter: TNeonSerializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(AWhere.Text);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(AConfig);
    try
      LValue := LReader.JSONToTValue(LJSON, TRttiUtils.Context.GetType(TypeInfo(T)));
      LogError(LReader.Errors);
      Result := LValue.AsType<T>;
    finally
      LReader.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TfrmSerializationBase.SerializeSimple<T>(AValue: T);
begin
  SerializeValueFrom<T>(
    TValue.From<T>(AValue), memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

end.
