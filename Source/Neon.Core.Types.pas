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
unit Neon.Core.Types;

{$I Neon.inc}

interface

uses
  System.Classes, System.SysUtils, System.TypInfo;

{$SCOPEDENUMS ON}

type
  ENeonException = class(Exception);

type
  TNeonCase = (Unchanged, LowerCase, UpperCase, PascalCase, CamelCase, SnakeCase, KebabCase, ScreamingSnakeCase, CustomCase);
  TNeonSort = (Rtti, RttiReverse, Alpha, AlphaReverse);
  TNeonMemberType = (Unknown, Prop, Field, Indexed);
  TNeonMembers = (Standard, Fields, Properties);
  TNeonMembersSet = set of TNeonMembers;
  TNeonVisibility = set of TMemberVisibility;
  TNeonIncludeOption = (Default, Include, Exclude);
  TNeonOperation = (Serialize, Deserialize);
  TNeonJSchemaVersion = (None, Draft07, v202012);

  TNeonIgnoreIfContext = record
  public
    MemberName: string;
    Operation: TNeonOperation;
    constructor Create(const AMemberName: string; AOperation: TNeonOperation);
  end;

  TNeonIgnoreCallback = function(const AContext: TNeonIgnoreIfContext): Boolean of object;
  TCaseFunc = reference to function (const AString: string): string;

resourcestring
  { Catalog of every message Neon raises or logs, so the whole library can
    be localized (e.g. with a translated resource DLL) without recompiling. }
  SNeonErrorParse = 'Error parsing JSON string';
  SNeonErrorNumExpected = 'Invalid JSON value. Number expected';
  SNeonErrorBoolExpected = 'Invalid JSON value. Number expected';
  SNeonErrorArrExpected = 'Set deserialization: Expected JSON Array';
  SNeonErrorDictKeyInvalid = 'Dictionary [Key]: type not supported';
  SNeonErrorFieldProp = 'Member type must be Field or Property';
  SNeonErrorEnumInvalid = 'Invalid enum value';
  SNeonErrorEnumNames = 'No correspondence with enum names';
  SNeonErrorEnumValueF1 = 'Enum value [%d] out of bound';
  SNeonErrorEmptyType = 'Empty RttiType in JSONToValue';
  SNeonErrorRangeOutF2 = 'The value [%s] is outside the range for the type [%s]';
  SNeonErrorNoMethodF2 = 'NeonInclude Method name [%s] not found in class [%s]';
  SNeonErrorConvertNumF3 = 'Error converting member [%s] of type [%s]: %s';
  SNeonErrorTagTargetInvalid = 'You can apply tag values only to records or objects';
  SNeonErrorTagParseF1 = 'Error decoding tag: [%s]';

  SNeonErrorPropertyNotFoundF1 = 'Property [%s] not found';
  SNeonErrorMethodNotFoundF1 = 'Method [%s] not found';
  SNeonErrorNullableNoRtti = 'Nullable contains type with no RTTI';
  SNeonErrorNullableNoValue = 'Nullable type has no value';
  SNeonErrorUnknownGenericType = 'TTypeConfigurator: Unknown type T';
  SNeonErrorDeserializeIncompatible = '.Deserialize: incompatible types';
  SNeonErrorJSONNotString = 'JSONValue must be a string';
  SNeonErrorJSONNotArray = 'The JSON must be an array';
  SNeonErrorJSONItemNotObject = 'The item must be an object';
  SNeonErrorJSONNotBoolean = 'The JSON value is not boolean';
  SNeonErrorDataSetJSONNotArray = 'JSONToDataSet: The JSON must be an array';
  SNeonErrorCreateTypeF1 = 'Error creating type [%s]';
  SNeonErrorObjectNoType = 'Object doesn''t have a type';
  SNeonErrorCreateInstanceF1 = 'TRttiUtils.CreateInstance: can''t create object [%s]';
  SNeonErrorConvertPropF2 = 'Error converting property [%s] of object [%s]';
  SNeonErrorSerializerIncompatibleF2 = 'TJSONValueSerializer: %s and %s not compatible';
  SNeonErrorSchemaCycleF1 = 'Cycle detected while generating JSON Schema for type [%s]';
  SNeonErrorSchemaRefNotFoundF1 = 'Could not resolve $ref [%s]';
  SNeonErrorSchemaRefUnsupportedF1 = 'Unsupported $ref [%s]: only local (same-document) refs are supported';

implementation

{ TNeonIgnoreIfContext }

constructor TNeonIgnoreIfContext.Create(const AMemberName: string; AOperation: TNeonOperation);
begin
  MemberName := AMemberName;
  Operation := AOperation;
end;

end.
