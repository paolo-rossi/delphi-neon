{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Serializers.VCL;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo,
  System.Generics.Collections, System.JSON,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence;

type
  TImageSerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue; ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

implementation

uses
  Vcl.ExtCtrls,
  Neon.Core.Utils;

{ TImageSerializer }

class function TImageSerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

class function TImageSerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TImage.ClassInfo;
end;

function TImageSerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LImage: TImage;
  LStream: TMemoryStream;
  LBase64: string;
begin
  LImage := AValue.AsObject as TImage;

  if LImage.Picture = nil then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotEmpty, IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONString.Create(''));
    end;
  end;

  LStream := TMemoryStream.Create;
  try
{$IF CompilerVersion >= 30}
    LImage.Picture.SaveToStream(LStream);
{$ELSE}
    LImage.Picture.Bitmap.SaveToStream(LStream);
{$ENDIF}
    LStream.Position := soFromBeginning;
    LBase64 := TBase64.Encode(LStream);
  finally
    LStream.Free;
  end;
  Result := TJSONString.Create(LBase64);
end;

function TImageSerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LImage: TImage;
  LStream: TMemoryStream;
begin
  Result := AData;
  LImage := AData.AsObject as TImage;

  if AValue.Value.IsEmpty then
  begin
    LImage.Picture := nil;
    Exit(AData);
  end;

  LStream := TMemoryStream.Create;
  try
    TBase64.Decode(AValue.Value, LStream);
    LStream.Position := soFromBeginning;
{$IF CompilerVersion >= 30}
    LImage.Picture.LoadFromStream(LStream);
{$ELSE}
    LImage.Picture.Bitmap.LoadFromStream(LStream);
{$ENDIF}
  finally
    LStream.Free;
  end;
end;

end.
