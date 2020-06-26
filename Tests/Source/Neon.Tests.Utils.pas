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
unit Neon.Tests.Utils;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON,

  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON;

type
  TTestUtils = class
  private class var
    FContext: TRttiContext;
  public
    class function ExpectedFromFile(const AFileName: string): string;
  public
    class function SerializeObject(AObject: TObject): string; overload;
    class function SerializeObject(AObject: TObject; AConfig: INeonConfiguration): string; overload;

    class function DeserializeObject(AObject: TObject; AConfig: INeonConfiguration): string;

    class function SerializeValue(AValue: TValue): string; overload;
    class function SerializeValue(AValue: TValue; AConfig: INeonConfiguration): string; overload;

    class function DeserializeValueTo<T>(AValue: T; AConfig: INeonConfiguration): T;
  end;

implementation

uses
  System.IOUtils;

class function TTestUtils.SerializeObject(AObject: TObject; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    LJSON := LWriter.ObjectToJSON(AObject);
    try
      Result := TNeon.Print(LJSON, AConfig.GetPrettyPrint)
    finally
      LJSON.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

class function TTestUtils.SerializeValue(AValue: TValue): string;
begin
  Result := SerializeValue(AValue, TNeonConfiguration.Default);
end;

class function TTestUtils.DeserializeObject(AObject: TObject; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
  LReader: TNeonDeserializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue('');
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(AConfig);
    try
      LReader.JSONToObject(AObject, LJSON);
    finally
      LReader.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

class function TTestUtils.SerializeObject(AObject: TObject): string;
begin
  Result := SerializeObject(AObject, TNeonConfiguration.Default);
end;

class function TTestUtils.SerializeValue(AValue: TValue; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    LJSON := LWriter.ValueToJSON(AValue);
    try
      Result := TNeon.Print(LJSON, AConfig.GetPrettyPrint);
    finally
      LJSON.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

class function TTestUtils.DeserializeValueTo<T>(AValue: T; AConfig: INeonConfiguration): T;
var
  LJSON: TJSONValue;
  LValue: TValue;
  LReader: TNeonDeserializerJSON;
  LWriter: TNeonSerializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue('');
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(AConfig);
    try
      LValue := LReader.JSONToTValue(LJSON, FContext.GetType(TypeInfo(T)));
      Result := LValue.AsType<T>;
    finally
      LReader.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

class function TTestUtils.ExpectedFromFile(const AFileName: string): string;
var
  LReader: TStreamReader;
begin
  LReader := TStreamReader.Create(AFileName, TEncoding.UTF8);
  try
    Result := AdjustLineBreaks(LReader.ReadToEnd, tlbsCRLF);
  finally
    LReader.Free;
  end;
end;

end.
