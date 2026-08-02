{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Serializers.DB;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs, System.TypInfo,
  System.Generics.Collections, System.Math.Vectors, System.JSON, Data.DB,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence;

type
  TDataSetSerializer = class(TCustomSerializer)
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
  ARegistry.RegisterSerializer(TDataSetSerializer);
end;

{ TDataSetSerializer }

class function TDataSetSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TDataSet.ClassInfo;
end;

class function TDataSetSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

function TDataSetSerializer.Deserialize(AValue: TJSONValue; const AData:
    TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
begin
  Result := AData;
  TDataSetUtils.JSONToDataSet(AValue, AData.AsObject as TDataSet, AContext.GetConfiguration.GetUseUTCDate);
end;

function TDataSetSerializer.Serialize(const AValue: TValue; ANeonObject:
    TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LDataSet: TDataSet;
begin
  LDataSet := AValue.AsType<TDataSet>;

  if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
    if LDataSet.IsEmpty then
      Exit(nil);

  Result := TDataSetUtils.DataSetToJSONArray(LDataSet, AContext.GetConfiguration.GetUseUTCDate);
end;

end.
