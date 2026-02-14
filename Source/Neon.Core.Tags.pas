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
unit Neon.Core.Tags;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Rtti, System.TypInfo, System.JSON;

type
  TAttributeTags = class
  private
    FTagSeparator: string;
    FValueSeparator: string;
    function ExtractValue(const AName: string; AType: TRttiType): TValue;
    function GetCount: Integer;
  protected
    class var FContext: TRttiContext;
  protected
    FTagMap: TDictionary<string, string>;

    function GetValue(const AName: string): string;
  public
    class constructor Create;
  public
    constructor Create(const ATagSeparator: string = ','; const AValueSeparator: string = '=');
    destructor Destroy; override;

    procedure Parse(const ATags: string);

    procedure ApplyToFields(const AEntity: TValue);
    procedure ApplyToProps(const AEntity: TValue);

    function Exists(const AName: string): Boolean;
    function GetValueAs<T>(const AName: string): T;
    function GetBoolValue(const AName: string): Boolean;

    property TagMap: TDictionary<string, string> read FTagMap write FTagMap;
    property Count: Integer read GetCount;
  end;


  TStructTagsSerializer = class

  end;

implementation

{ TAttributeTags }

procedure TAttributeTags.ApplyToFields(const AEntity: TValue);
var
  LEntityType: TRttiType;
  LInstance: Pointer;
  LField: TRttiField;
  LValue: TValue;
begin
  if not ((AEntity.Kind = tkClass) or (AEntity.Kind = tkRecord)) then
    raise Exception.Create('You can apply tags values to records or objects');

  LInstance := nil;
  LEntityType := FContext.GetType(AEntity.TypeInfo);

  if AEntity.Kind = tkClass then
    LInstance := AEntity.AsObject;

  if AEntity.Kind = tkRecord then
    LInstance := AEntity.GetReferenceToRawData;

  for LField in LEntityType.GetFields do
  begin
    if Exists(LField.Name) then
    begin
      LValue := ExtractValue(LField.Name, LField.FieldType);
      LField.SetValue(LInstance, LValue);
    end;
  end;
end;

procedure TAttributeTags.ApplyToProps(const AEntity: TValue);
begin

end;

constructor TAttributeTags.Create(const ATagSeparator, AValueSeparator: string);
begin
  FTagSeparator := ATagSeparator;
  FValueSeparator := AValueSeparator;
  FTagMap := TDictionary<string, string>.Create;
end;

class constructor TAttributeTags.Create;
begin
  FContext := TRttiContext.Create;
end;

destructor TAttributeTags.Destroy;
begin
  FTagMap.Free;

  inherited;
end;

function TAttributeTags.Exists(const AName: string): Boolean;
begin
  Result := FTagMap.ContainsKey(AName);
end;

function TAttributeTags.ExtractValue(const AName: string; AType: TRttiType): TValue;
var
  LOrdinal: Integer;
  LTypeData: PTypeData;
  LValueStr: string;
begin
  LValueStr := GetValue(AName);
  if LValueStr.IsEmpty then
    Exit(nil);

  try
    case AType.TypeKind of
      // Only simple types
      tkInteger:
      begin
        Result := StrToInt(LValueStr);
      end;
      tkInt64:
      begin
        Result := StrToInt64(LValueStr);
      end;
      tkChar,
      tkWChar:
      begin
        Result := TValue.From<Char>(LValueStr.Chars[0]);
      end;
      tkFloat:
      begin
        if AType.Handle = System.TypeInfo(TDate) then
          Result := TValue.From<TDate>(StrToDate(LValueStr))
        else if AType.Handle = System.TypeInfo(TTime) then
          Result := TValue.From<TTime>(StrToTime(LValueStr))
        else if AType.Handle = System.TypeInfo(TDateTime) then
          Result := TValue.From<TDateTime>(StrToDateTime(LValueStr))
        else
          Result := StrToFloat(LValueStr);
      end;
      tkLString,
      tkWString,
      tkUString,
      tkString:
      begin
        Result := LValueStr;
      end;
      tkEnumeration:
      begin
        if AType.Handle = System.TypeInfo(Boolean) then
          Result := StrToBool(LValueStr)
        else
        begin
          LOrdinal := GetEnumValue(AType.Handle, GetValue(AName));
          LTypeData := GetTypeData(AType.Handle);

          if (LOrdinal >= LTypeData.MinValue) and (LOrdinal <= LTypeData.MaxValue) then
            TValue.Make(LOrdinal, AType.Handle, Result)
          else
            raise Exception.Create('No correspondence with enum names');
        end;

      end;
    end;
  except
    on E: Exception do
      Exit(nil);
  end;
end;

function TAttributeTags.GetBoolValue(const AName: string): Boolean;
begin
  if not Exists(AName) then
    Exit(False);

  if GetValue(AName) = '' then
    Exit(True);

  Result := GetValueAs<Boolean>(AName);
end;

function TAttributeTags.GetCount: Integer;
begin
  Result := FTagMap.Count;
end;

function TAttributeTags.GetValue(const AName: string): string;
begin
  Result := '';
  FTagMap.TryGetValue(AName, Result);
    //Exit(
    //raise Exception.CreateFmt('Value for %s not found', [AName]);
end;

function TAttributeTags.GetValueAs<T>(const AName: string): T;
var
  LValue: TValue;
  LType: TRttiType;
begin
  Result := Default(T);

  LType := FContext.GetType(System.TypeInfo(T));
  LValue := ExtractValue(AName, LType);
  Result := LValue.AsType<T>;
end;

procedure TAttributeTags.Parse(const ATags: string);
var
  LPart: string;
  LParts, LFrag: TArray<string>;
begin
  LParts := ATags.Split([FTagSeparator]);

  if Length(LParts) = 0 then
    FTagMap.Clear;

  for LPart in LParts do
  begin
    LFrag := LPart.Split([FValueSeparator]);
    case Length(LFrag) of
      0: ;
      1: FTagMap.Add(LFrag[0], '');       // Named tag without value (bool true)
      2: FTagMap.Add(LFrag[0], LFrag[1]); // Named tag with value
    else
      raise Exception.Create('Error decoding tag');
    end;
  end;

end;

end.
