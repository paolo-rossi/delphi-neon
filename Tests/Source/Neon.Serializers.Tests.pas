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
unit Neon.Serializers.Tests;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs, System.TypInfo,
  System.Generics.Collections, System.Math.Vectors, System.JSON, Data.DB,

  // FireDAC Units
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.BatchMove.JSON,
  FireDAC.Comp.BatchMove, FireDAC.Comp.BatchMove.DataSet, FireDAC.Comp.DataSet,

  // Neon Units
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence;

type
  TGUIDSerializerTest = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TFDDataSetSerializerTest = class(TCustomSerializer)
  private
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

procedure RegisterSerializers(ARegistry: TNeonSerializerRegistry);

implementation

uses
  Neon.Core.Utils;

procedure RegisterSerializers(ARegistry: TNeonSerializerRegistry);
begin
  ARegistry.RegisterSerializer(TFDDataSetSerializerTest);
end;

{ TFDDataSetSerializerTest }

class function TFDDataSetSerializerTest.GetTargetInfo: PTypeInfo;
begin
  Result := TFDDataSet.ClassInfo;
end;

class function TFDDataSetSerializerTest.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TFDDataSetSerializerTest.Deserialize(AValue: TJSONValue; const AData:
    TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
begin
  Result := AData;
  TDataSetUtils.JSONToDataSet(AValue, AData.AsObject as TDataSet, AContext.GetConfiguration.GetUseUTCDate);
end;

function TFDDataSetSerializerTest.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LDataSet: TFDDataSet;
begin
  LDataSet := AValue.AsType<TFDDataSet>;

  if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
    if LDataSet.IsEmpty then
      Exit(nil);

  Result := TDataSetUtils.DataSetToJSONArray(LDataSet, AContext.GetConfiguration.GetUseUTCDate);
end;

{ TGUIDSerializerTest }

class function TGUIDSerializerTest.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TGUID);
end;

function TGUIDSerializerTest.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LGUID: TGUID;
begin
  LGUID := AValue.AsType<TGUID>;
  Result := TJSONString.Create(Format('%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x-Test',
    [LGUID.D1, LGUID.D2, LGUID.D3, LGUID.D4[0], LGUID.D4[1], LGUID.D4[2],
     LGUID.D4[3], LGUID.D4[4], LGUID.D4[5], LGUID.D4[6], LGUID.D4[7]])
    );
end;

class function TGUIDSerializerTest.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TGUIDSerializerTest.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LGUID: TGUID;
begin
  LGUID := StringToGUID(Format('{%s}', [StringReplace(AValue.Value, '-Test', '', [])]));
  Result := TValue.From<TGUID>(LGUID);
end;

end.
