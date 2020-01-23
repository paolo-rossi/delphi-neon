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
unit Neon.Core.TypeInfo;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, System.TypInfo,
  System.Generics.Collections;

type
  INeonTypeInfo = interface
  ['{DA498D59-E50C-490C-8F7F-4F0B8804D322}']
  end;

  INeonTypeInfoStream = interface(INeonTypeInfo)
  ['{285B6152-BC07-4195-8A10-B6A9B2A54536}']
    function GetStreamType: TRttiType;
  end;

  INeonTypeInfoList = interface(INeonTypeInfo)
  ['{0432B934-A484-46BE-8AF8-D2207694E1EA}']
    function GetItemType: TRttiType;
  end;

  INeonTypeInfoMap = interface(INeonTypeInfo)
  ['{9788B4FE-8F9E-4284-86F5-6DB5EFF326FC}']
    function GetKeyType: TRttiType;
    function GetValueType: TRttiType;
  end;

  INeonTypeInfoNullable = interface(INeonTypeInfo)
  ['{20924A89-A952-4048-9A3A-7E209CA7C40D}']
    function GetBaseType: TRttiType;
  end;

  TNeonTypeInfoStream = class(TInterfacedObject, INeonTypeInfoStream)
  private
    FStreamType: TRttiType;
    constructor Create(AStreamType: TRttiType);
  public
    class function GuessType(AType: TRttiType): INeonTypeInfoStream;
  public
    function GetStreamType: TRttiType;
  end;

  TNeonTypeInfoList = class(TInterfacedObject, INeonTypeInfoList)
  private
    FItemType: TRttiType;
    constructor Create(AItemType: TRttiType);
  public
    class function GuessType(AType: TRttiType): INeonTypeInfoList;
  public
    function GetItemType: TRttiType;
  end;

  TNeonTypeInfoMap = class(TInterfacedObject, INeonTypeInfoMap)
  private
    FKeyType: TRttiType;
    FValueType: TRttiType;
    constructor Create(AKeyType, AValueType: TRttiType);
  public
    class function GuessType(AType: TRttiType): INeonTypeInfoMap;
  public
    function GetKeyType: TRttiType;
    function GetValueType: TRttiType;
  end;

  TNeonTypeInfoNullable = class(TInterfacedObject, INeonTypeInfoNullable)
  private
    FBaseType: TRttiType;
    constructor Create(ABaseType: TRttiType);
  public
    class function GuessType(AType: TRttiType): INeonTypeInfoNullable;
  public
    function GetBaseType: TRttiType;
  end;

implementation

uses
  Neon.Core.Types,
  Neon.Core.Utils;

{ TNeonTypeInfoStream }

constructor TNeonTypeInfoStream.Create(AStreamType: TRttiType);
begin
  FStreamType := AStreamType;
end;

function TNeonTypeInfoStream.GetStreamType: TRttiType;
begin
  Result := FStreamType;
end;

class function TNeonTypeInfoStream.GuessType(AType: TRttiType): INeonTypeInfoStream;
begin
  if not Assigned(AType) then
    Exit(nil);

  if not Assigned(AType.GetMethod('LoadFromStream')) then
    Exit(nil);

  if not Assigned(AType.GetMethod('SaveToStream')) then
    Exit(nil);

  Result := Self.Create(TRttiUtils.Context.GetType(TypeInfo(string)));
end;

{ TNeonTypeInfoList }

constructor TNeonTypeInfoList.Create(AItemType: TRttiType);
begin
  FItemType := AItemType;
end;

function TNeonTypeInfoList.GetItemType: TRttiType;
begin
  Result := FItemType;
end;

class function TNeonTypeInfoList.GuessType(AType: TRttiType): INeonTypeInfoList;
var
  LMethodGetEnumerator, LMethodAdd: TRttiMethod;
  LItemType: TRttiType;
begin
  Result := nil;

  LMethodGetEnumerator := AType.GetMethod('GetEnumerator');
  if not Assigned(LMethodGetEnumerator) or
     (LMethodGetEnumerator.MethodKind <> mkFunction) or
     (LMethodGetEnumerator.ReturnType.Handle.Kind <> tkClass)
  then
    Exit;

  if not Assigned(AType.GetMethod('Clear')) then
    Exit;

  LMethodAdd := AType.GetMethod('Add');
  if not Assigned(LMethodAdd) or (Length(LMethodAdd.GetParameters) <> 1) then
    Exit;

  LItemType := LMethodAdd.GetParameters[0].ParamType;

  if not Assigned(AType.GetProperty('Count')) then
    Exit;

  Result := TNeonTypeInfoList.Create(LItemType);
end;

{ TNeonTypeInfoMap }

constructor TNeonTypeInfoMap.Create(AKeyType, AValueType: TRttiType);
begin
  FKeyType := AKeyType;
  FValueType := AValueType;
end;

function TNeonTypeInfoMap.GetKeyType: TRttiType;
begin
  Result := FKeyType;
end;

function TNeonTypeInfoMap.GetValueType: TRttiType;
begin
  Result := FValueType;
end;

class function TNeonTypeInfoMap.GuessType(AType: TRttiType): INeonTypeInfoMap;
var
  LKeyType, LValType: TRttiType;
  LAddMethod: TRttiMethod;
begin
  Result := nil;

  if not Assigned(AType.GetProperty('Keys')) then
    Exit;

  if not Assigned(AType.GetProperty('Values')) then
    Exit;

  if not Assigned(AType.GetMethod('Clear')) then
    Exit;

  LAddMethod := AType.GetMethod('Add');
  if not Assigned(LAddMethod) or (Length(LAddMethod.GetParameters) <> 2) then
    Exit;

  LKeyType := LAddMethod.GetParameters[0].ParamType;
  LValType := LAddMethod.GetParameters[1].ParamType;

  if not Assigned(AType.GetProperty('Count')) then
    Exit;

  Result := TNeonTypeInfoMap.Create(LKeyType, LValType);
end;

{ TNeonTypeInfoNullable }

constructor TNeonTypeInfoNullable.Create(ABaseType: TRttiType);
begin
  FBaseType := ABaseType;
end;

function TNeonTypeInfoNullable.GetBaseType: TRttiType;
begin
  Result := FBaseType;
end;

class function TNeonTypeInfoNullable.GuessType(AType: TRttiType): INeonTypeInfoNullable;
var
  LGetValueMethod: TRttiMethod;
begin
  if not Assigned(AType) then
    Exit(nil);

  LGetValueMethod := AType.GetMethod('GetValue');
  if not Assigned(LGetValueMethod) then
    Exit(nil);

  if not Assigned(AType.GetMethod('GetValueType')) then
    Exit(nil);

  if not Assigned(AType.GetMethod('GetHasValue')) then
    Exit(nil);

  if not Assigned(AType.GetMethod('SetValue')) then
    Exit(nil);

  Result := Self.Create(LGetValueMethod.ReturnType);
end;

end.
