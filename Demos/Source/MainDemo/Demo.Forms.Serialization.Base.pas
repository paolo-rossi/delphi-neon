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
    procedure LogError(ALog: TArray<string>); overload;

    procedure SerializeObject(AObject: TObject; AWhere: TStrings; ASettings: TNeonSettings);
    procedure DeserializeObject(AObject: TObject; AWhere: TStrings; ASettings: TNeonSettings);

    procedure SerializeValueFrom<T>(const AValue: TValue; AWhere: TStrings; ASettings: TNeonSettings);
    function DeserializeValueTo<T>(AWhere: TStrings; ASettings: TNeonSettings): T; overload;
    function DeserializeValueTo<T>(const AValue: T; AWhere: TStrings; ASettings: TNeonSettings): T; overload;

    procedure SerializeSimple<T>(const AValue: T);
    procedure DeserializeSimple<T>; overload;
    procedure DeserializeSimple<T>(const AValue: T); overload;
  public
    constructor CreateEx(AOwner: TComponent; AConfigForm: TFrameConfiguration; AColor: TColor);
  public
    class function CreateTabForm(AOwner: TComponent; AConfigForm: TFrameConfiguration; AColor: TColor): TfrmSerializationBase;
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

procedure TfrmSerializationBase.SerializeObject(AObject: TObject; AWhere: TStrings; ASettings: TNeonSettings);
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(ASettings);
  try
    LJSON := LWriter.ObjectToJSON(AObject);
    try
      Log(TNeon.Print(LJSON, ASettings.PrettyPrint), AWhere);
      LogError(LWriter.Errors.ToStrings);
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

procedure TfrmSerializationBase.DeserializeObject(AObject: TObject; AWhere: TStrings; ASettings: TNeonSettings);
var
  LJSON: TJSONValue;
  LReader: TNeonDeserializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(AWhere.Text);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(ASettings);
    try
      LReader.JSONToObject(AObject, LJSON);
      LogError(LReader.Errors.ToStrings);
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
    memoSerialize.Lines, frmConfiguration.BuildSerializerSettings);

  SerializeValueFrom<T>(
    TValue.From<T>(LVal), memoDeserialize.Lines, frmConfiguration.BuildSerializerSettings);
end;

procedure TfrmSerializationBase.DeserializeSimple<T>(const AValue: T);
var
  LVal: T;
begin
  LVal := DeserializeValueTo<T>(AValue,
    memoSerialize.Lines, frmConfiguration.BuildSerializerSettings);

  SerializeValueFrom<T>(
    TValue.From<T>(LVal), memoDeserialize.Lines, frmConfiguration.BuildSerializerSettings);
end;

function TfrmSerializationBase.DeserializeValueTo<T>(const AValue: T; AWhere: TStrings;
  ASettings: TNeonSettings): T;
var
  LJSON: TJSONValue;
  LValue: TValue;
  LReader: TNeonDeserializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(AWhere.Text);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(ASettings);
    try
      LValue := LReader.JSONToTValue(LJSON, TRttiUtils.Context.GetType(TypeInfo(T)), TValue.From<T>(AValue));
      LogError(LReader.Errors.ToStrings);
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

procedure TfrmSerializationBase.LogError(ALog: TArray<string>);
var
  LError: string;
begin
  for LError in ALog do
    memoLog.Lines.Add(LError);
end;

procedure TfrmSerializationBase.LogError(const ALog: string);
begin
  memoLog.Lines.Add(ALog);
end;

procedure TfrmSerializationBase.SerializeValueFrom<T>(const AValue: TValue; AWhere: TStrings; ASettings: TNeonSettings);
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(ASettings);
  try
    LJSON := LWriter.ValueToJSON(AValue);
    try
      Log(TNeon.Print(LJSON, ASettings.PrettyPrint), AWhere);
      LogError(LWriter.Errors.ToStrings);
    finally
      LJSON.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

function TfrmSerializationBase.DeserializeValueTo<T>(AWhere: TStrings; ASettings: TNeonSettings): T;
var
  LJSON: TJSONValue;
  LValue: TValue;
  LReader: TNeonDeserializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(AWhere.Text);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(ASettings);
    try
      LValue := LReader.JSONToTValue(LJSON, TRttiUtils.Context.GetType(TypeInfo(T)));
      LogError(LReader.Errors.ToStrings);
      Result := LValue.AsType<T>;
    finally
      LReader.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TfrmSerializationBase.SerializeSimple<T>(const AValue: T);
begin
  SerializeValueFrom<T>(
    TValue.From<T>(AValue), memoSerialize.Lines, frmConfiguration.BuildSerializerSettings);
end;

end.
