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
  TNeonMemberType = (Unknown, Prop, Field, Indexed);
  TNeonMembers = (Standard, Fields, Properties);
  TNeonMembersSet = set of TNeonMembers;
  TNeonVisibility = set of TMemberVisibility;
  TNeonIncludeOption = (Default, Include, Exclude);
  TNeonOperation = (Serialize, Deserialize);

  TNeonIgnoreIfContext = record
  public
    MemberName: string;
    Operation: TNeonOperation;
    constructor Create(const AMemberName: string; AOperation: TNeonOperation);
  end;

type
  TNeonIgnoreCallback = function(const AContext: TNeonIgnoreIfContext): Boolean of object;
  TCaseFunc = reference to function (const AString: string): string;

type
  TNeonError = class
  public const
    PARSE = 'Error parsing JSON string';
    NUM_EXPECTED = 'Invalid JSON value. Number expected';
    BOOL_EXPECTED = 'Invalid JSON value. Number expected';
    ARR_EXPECTED = 'Set deserialization: Expected JSON Array';
    DICT_KEY_INVALID = 'Dictionary [Key]: type not supported';
    FIELD_PROP = 'Member type must be Field or Property';
    ENUM_INVALID = 'Invalid enum value';
    ENUM_NAMES = 'No correspondence with enum names';
    ENUM_VALUE_F1 = 'Enum value [%d] out of bound';
    EMPTY_TYPE = 'Empty RttiType in JSONToValue';
    RANGE_OUT_F2 = 'The value [%s] is outside the range for the type [%s]';
    NO_METHOD_F2 = 'NeonInclude Method name [%s] not found in class [%s]';
    CONVERT_NUM_F3 = 'Error converting member [%s] of type [%s]: %s';
  end;

implementation

{ TNeonIgnoreIfContext }

constructor TNeonIgnoreIfContext.Create(const AMemberName: string; AOperation: TNeonOperation);
begin
  MemberName := AMemberName;
  Operation := AOperation;
end;

end.
