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
unit Neon.Core.Nullables;

interface

uses
  System.SysUtils, System.Variants, System.Classes, System.Generics.Defaults, System.Rtti,
  System.TypInfo, System.JSON;

type
  ENullableException = class(Exception);

  {$RTTI EXPLICIT FIELDS([vcPrivate]) METHODS([vcPrivate])}
  Nullable<T> = record
  private
    FValue: T;
    FHasValue: string;
    procedure Clear;
    function GetValueType: PTypeInfo;
    function GetValue: T;
    procedure SetValue(const AValue: T);
    function GetHasValue: Boolean;
  public
    constructor Create(const Value: T); overload;
    constructor Create(const Value: Variant); overload;
    function Equals(const Value: Nullable<T>): Boolean;
    function GetValueOrDefault: T; overload;
    function GetValueOrDefault(const Default: T): T; overload;

    property HasValue: Boolean read GetHasValue;
    function IsNull: Boolean;

    property Value: T read GetValue;

    class operator Implicit(const Value: Nullable<T>): T;
    class operator Implicit(const Value: Nullable<T>): Variant;
    class operator Implicit(const Value: Pointer): Nullable<T>;
    class operator Implicit(const Value: T): Nullable<T>;
    class operator Implicit(const Value: Variant): Nullable<T>;
    class operator Equal(const Left, Right: Nullable<T>): Boolean;
    class operator NotEqual(const Left, Right: Nullable<T>): Boolean;
  end;

  NullString = Nullable<string>;
  NullBoolean = Nullable<Boolean>;
  NullInteger = Nullable<Integer>;
  NullInt64 = Nullable<Int64>;
  NullDouble = Nullable<Double>;
  NullDateTime = Nullable<TDateTime>;

implementation

uses
  Neon.Core.Utils;

{ Nullable<T> }

constructor Nullable<T>.Create(const Value: T);
var
  a: TValue;
begin
  FValue := Value;
  FHasValue := DefaultTrueBoolStr;
end;

constructor Nullable<T>.Create(const Value: Variant);
begin
  if not VarIsNull(Value) and not VarIsEmpty(Value) then
    Create(TValue.FromVariant(Value).AsType<T>)
  else
    Clear;
end;

procedure Nullable<T>.Clear;
begin
  FValue := Default(T);
  FHasValue := '';
end;

function Nullable<T>.Equals(const Value: Nullable<T>): Boolean;
begin
  if HasValue and Value.HasValue then
    Result := TEqualityComparer<T>.Default.Equals(Self.Value, Value.Value)
  else
    Result := HasValue = Value.HasValue;
end;

function Nullable<T>.GetHasValue: Boolean;
begin
  Result := FHasValue <> '';
end;

function Nullable<T>.GetValueType: PTypeInfo;
begin
  Result := TypeInfo(T);
end;

function Nullable<T>.GetValue: T;
begin
  if not HasValue then
    raise ENullableException.Create('Nullable type has no value');
  Result := FValue;
end;

function Nullable<T>.GetValueOrDefault(const Default: T): T;
begin
  if HasValue then
    Result := FValue
  else
    Result := Default;
end;

function Nullable<T>.GetValueOrDefault: T;
begin
  Result := GetValueOrDefault(Default(T));
end;

class operator Nullable<T>.Implicit(const Value: Nullable<T>): T;
begin
  Result := Value.Value;
end;

class operator Nullable<T>.Implicit(const Value: Nullable<T>): Variant;
begin
  if Value.HasValue then
    Result := TValue.From<T>(Value.Value).AsVariant
  else
    Result := Null;
end;

class operator Nullable<T>.Implicit(const Value: Pointer): Nullable<T>;
begin
  if Value = nil then
    Result.Clear
  else
    Result := Nullable<T>.Create(T(Value^));
end;

class operator Nullable<T>.Implicit(const Value: T): Nullable<T>;
begin
  Result := Nullable<T>.Create(Value);
end;

class operator Nullable<T>.Implicit(const Value: Variant): Nullable<T>;
begin
  Result := Nullable<T>.Create(Value);
end;

function Nullable<T>.IsNull: Boolean;
begin
  Result := FHasValue = '';
end;

class operator Nullable<T>.Equal(const Left, Right: Nullable<T>): Boolean;
begin
  Result := Left.Equals(Right);
end;

class operator Nullable<T>.NotEqual(const Left, Right: Nullable<T>): Boolean;
begin
  Result := not Left.Equals(Right);
end;

procedure Nullable<T>.SetValue(const AValue: T);
begin
  FValue := AValue;
  FHasValue := DefaultTrueBoolStr;
end;

end.
