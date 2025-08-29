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
    class function SerializeObject(AObject: TObject; ASettings: TNeonSettings): string; overload;

    class function DeserializeObject(const AValue: string; AObject: TObject; ASettings: TNeonSettings): string;

    class function SerializeValue(AValue: TValue): string; overload;
    class function SerializeValue(AValue: TValue; ASettings: TNeonSettings): string; overload;

    class function DeserializeValueTo<T>(const AValue: string): T; overload;
    class function DeserializeValueTo<T>(const AValue: string; ASettings: TNeonSettings): T; overload;
  end;

implementation

uses
  System.IOUtils;

class function TTestUtils.SerializeObject(AObject: TObject; ASettings: TNeonSettings): string;
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(ASettings);
  try
    LJSON := LWriter.ObjectToJSON(AObject);
    try
      Result := TNeon.Print(LJSON, ASettings.PrettyPrint)
    finally
      LJSON.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

class function TTestUtils.SerializeValue(AValue: TValue): string;
begin
  Result := SerializeValue(AValue, TNeonSettings.Default);
end;

class function TTestUtils.DeserializeObject(const AValue: string; AObject:
    TObject; ASettings: TNeonSettings): string;
var
  LJSON: TJSONValue;
  LReader: TNeonDeserializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(AValue);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(ASettings);
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
  Result := SerializeObject(AObject, TNeonSettings.Default);
end;

class function TTestUtils.SerializeValue(AValue: TValue; ASettings: TNeonSettings): string;
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(ASettings);
  try
    LJSON := LWriter.ValueToJSON(AValue);
    try
      Result := TNeon.Print(LJSON, ASettings.PrettyPrint);
    finally
      LJSON.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

class function TTestUtils.DeserializeValueTo<T>(const AValue: string; ASettings: TNeonSettings): T;
var
  LJSON: TJSONValue;
  LValue: TValue;
  LReader: TNeonDeserializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(AValue);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(ASettings);
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

class function TTestUtils.DeserializeValueTo<T>(const AValue: string): T;
begin
  Result := DeserializeValueTo<T>(AValue, TNeonSettings.Default);
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
