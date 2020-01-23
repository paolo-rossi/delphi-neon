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
unit Neon.Core.Serializers.RTL;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs, System.TypInfo,
  System.Generics.Collections, System.Math.Vectors, System.JSON,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence;

type
  TGUIDSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

  TStreamSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

procedure RegisterDefaultSerializers(ARegistry: TNeonSerializerRegistry);

implementation

uses
  Neon.Core.Utils;

procedure RegisterDefaultSerializers(ARegistry: TNeonSerializerRegistry);
begin
  ARegistry.RegisterSerializer(TGUIDSerializer);
  ARegistry.RegisterSerializer(TStreamSerializer);
end;

{ TGUIDSerializer }

class function TGUIDSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TypeInfo(TGUID);
end;

function TGUIDSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LGUID: TGUID;
begin
  LGUID := AValue.AsType<TGUID>;
  Result := TJSONString.Create(Format('%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x',
    [LGUID.D1, LGUID.D2, LGUID.D3, LGUID.D4[0], LGUID.D4[1], LGUID.D4[2],
     LGUID.D4[3], LGUID.D4[4], LGUID.D4[5], LGUID.D4[6], LGUID.D4[7]])
    );
end;

class function TGUIDSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  if AType = GetTargetInfo then
    Result := True
  else
    Result := False;
end;

function TGUIDSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
    ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LGUID: TGUID;
begin
  LGUID := StringToGUID(Format('{%s}', [AValue.Value]));
  Result := TValue.From<TGUID>(LGUID);
end;

{ TStreamSerializer }

class function TStreamSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TStream.ClassInfo;
end;

class function TStreamSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TStreamSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LStream: TStream;
  LBase64: string;
begin
  LStream := AValue.AsObject as TStream;

  if LStream.Size = 0 then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotEmpty, IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONString.Create(''));
    end;
  end;

  LStream.Position := soFromBeginning;
  LBase64 := TBase64.Encode(LStream);
  Result := TJSONString.Create(LBase64);
end;

function TStreamSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LStream: TStream;
begin
  Result := AData;
  LStream := AData.AsObject as TStream;
  LStream.Position := soFromBeginning;

  TBase64.Decode(AValue.Value, LStream);
end;

end.
