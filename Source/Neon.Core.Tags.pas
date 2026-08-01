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
  System.Rtti, System.TypInfo, System.JSON,
  Neon.Core.Types;

type
  /// <summary>
  ///   Parses a single Go-inspired tag string into a flat map of
  ///   key=value pairs (e.g. "description=A person's name,required,readOnly")
  ///   and applies the values to an entity's fields/properties via RTTI.
  /// </summary>
  /// <remarks>
  ///   A value may be wrapped in double quotes to include the tag/value
  ///   separator characters literally, e.g. description="Hello, World".
  ///   A literal quote inside a quoted value is escaped as \".
  /// </remarks>
  TAttributeTags = class
  private
    FTagSeparator: string;
    FValueSeparator: string;
    FQuoteChar: Char;
    function ExtractValue(const AName: string; AType: TRttiType): TValue;
    function GetCount: Integer;
    function UnquoteValue(const AValue: string): string;
    class function SplitRespectingQuotes(const AStr, ASeparator: string; AQuoteChar: Char): TArray<string>; static;
  protected
    class var FContext: TRttiContext;
    class var FInvariantFormat: TFormatSettings;
  protected
    FTagMap: TDictionary<string, string>;

    function GetValue(const AName: string): string;
  public
    class constructor Create;
  public
    constructor Create(const ATagSeparator: string = ','; const AValueSeparator: string = '='; AQuoteChar: Char = '"');
    destructor Destroy; override;

    /// <summary>
    ///   Returns a new instance with the same separators/quote char and a
    ///   copy of the parsed tags. The caller owns the returned instance.
    /// </summary>
    function Clone: TAttributeTags;

    /// <summary>
    ///   Replaces the separators/quote char and parsed tags of this instance
    ///   with a copy of ASource's
    /// </summary>
    procedure CopyFrom(ASource: TAttributeTags);

    /// <summary>
    ///   Parses ATags (e.g. "description=A name,required") into the internal
    ///   key/value map, replacing any tags parsed by a previous call
    /// </summary>
    procedure Parse(const ATags: string);

    /// <summary>
    ///   Applies the parsed tag values to the fields of AEntity (an object
    ///   or record) whose name matches a tag key, via RTTI
    /// </summary>
    procedure ApplyToFields(const AEntity: TValue);

    /// <summary>
    ///   Applies the parsed tag values to the writable properties of
    ///   AEntity (an object or record) whose name matches a tag key,
    ///   via RTTI; a matching read-only property is silently skipped
    /// </summary>
    procedure ApplyToProps(const AEntity: TValue);

    /// <summary>
    ///   Adds AName with AValue to the tag map, or overwrites its value
    ///   if AName is already present
    /// </summary>
    procedure AddOrSetTag(const AName: string; const AValue: string = '');

    /// <summary>
    ///   Returns True if a tag named AName was parsed
    /// </summary>
    function Exists(const AName: string): Boolean;

    /// <summary>
    ///   Returns the AName tag's value converted to T
    /// </summary>
    function GetValueAs<T>(const AName: string): T;

    /// <summary>
    ///   Returns True if AName is present as a bare flag (no value) or its
    ///   value is a valid boolean literal; returns False if AName wasn't parsed
    /// </summary>
    function GetBoolValue(const AName: string): Boolean;

    property TagMap: TDictionary<string, string> read FTagMap write FTagMap;
    property Count: Integer read GetCount;
  end;

  /// <summary>
  ///   Parses a raw Go-style struct tag string containing one or more named
  ///   tag groups, e.g.:
  ///     json:"name,omitempty" xml:"name" validate:"required,min=1"
  ///   Modeled after Go's reflect.StructTag: each group is `key:"value"`,
  ///   groups are separated by spaces, and a value may contain an escaped
  ///   quote (\") to include a literal double quote.
  /// </summary>
  /// <remarks>
  ///   This type only splits the raw string into its named groups (the
  ///   outer key:"value" pairs); it does not interpret a group's inner
  ///   content, since that convention differs per tag (e.g. json's first
  ///   token is the member name followed by bare option flags, while other
  ///   tags use key=value pairs). Use GetAttributeTags to parse a group's
  ///   content with the key=value convention from Neon.Core.Tags.
  /// </remarks>
  TStructTag = class
  private
    FRaw: string;
    FGroups: TDictionary<string, string>;
    procedure ParseRaw(const ARaw: string);
  public
    constructor Create(const ARaw: string = '');
    destructor Destroy; override;

    /// <summary>
    ///   Parses ARaw and returns a ready-to-use instance (caller owns it)
    /// </summary>
    class function Parse(const ARaw: string): TStructTag; static;

    /// <summary>
    ///   Looks up AKey and returns whether it was present in the raw string;
    ///   AValue receives the group's (unescaped) inner content
    /// </summary>
    function Lookup(const AKey: string; out AValue: string): Boolean;

    /// <summary>
    ///   Returns the group's inner content, or '' if AKey isn't present
    /// </summary>
    function Get(const AKey: string): string;

    /// <summary>
    ///   Returns True if AKey is one of the raw string's named tag groups
    /// </summary>
    function Exists(const AKey: string): Boolean;

    /// <summary>
    ///   Parses the AKey group's content with the key=value convention from
    ///   Neon.Core.Tags (e.g. validate:"required,min=1").
    /// </summary>
    /// <returns>
    ///   Returns an empty TAttributeTags ifAKey isn't present.
    /// </returns>
    /// <remarks>
    ///   The caller owns the returned instance.
    /// </remarks>
    function GetAttributeTags(const AKey: string): TAttributeTags;

    property Raw: string read FRaw;
  end;


implementation

{ TAttributeTags }

procedure TAttributeTags.AddOrSetTag(const AName, AValue: string);
begin
  FTagMap.AddOrSetValue(AName, AValue);
end;

procedure TAttributeTags.ApplyToFields(const AEntity: TValue);
var
  LEntityType: TRttiType;
  LInstance: Pointer;
  LField: TRttiField;
  LValue: TValue;
begin
  if not ((AEntity.Kind = tkClass) or (AEntity.Kind = tkRecord)) then
    raise ENeonException.Create(SNeonErrorTagTargetInvalid);

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
      if not LValue.IsEmpty then
        LField.SetValue(LInstance, LValue);
    end;
  end;
end;

procedure TAttributeTags.ApplyToProps(const AEntity: TValue);
var
  LEntityType: TRttiType;
  LInstance: Pointer;
  LProp: TRttiProperty;
  LValue: TValue;
begin
  if not ((AEntity.Kind = tkClass) or (AEntity.Kind = tkRecord)) then
    raise ENeonException.Create(SNeonErrorTagTargetInvalid);

  LInstance := nil;
  LEntityType := FContext.GetType(AEntity.TypeInfo);

  if AEntity.Kind = tkClass then
    LInstance := AEntity.AsObject;

  if AEntity.Kind = tkRecord then
    LInstance := AEntity.GetReferenceToRawData;

  for LProp in LEntityType.GetProperties do
  begin
    if LProp.IsWritable and Exists(LProp.Name) then
    begin
      LValue := ExtractValue(LProp.Name, LProp.PropertyType);
      if not LValue.IsEmpty then
        LProp.SetValue(LInstance, LValue);
    end;
  end;
end;

function TAttributeTags.Clone: TAttributeTags;
begin
  Result := TAttributeTags.Create(FTagSeparator, FValueSeparator, FQuoteChar);
  Result.CopyFrom(Self);
end;

procedure TAttributeTags.CopyFrom(ASource: TAttributeTags);
var
  LPair: TPair<string, string>;
begin
  FTagSeparator := ASource.FTagSeparator;
  FValueSeparator := ASource.FValueSeparator;
  FQuoteChar := ASource.FQuoteChar;

  FTagMap.Clear;
  for LPair in ASource.FTagMap do
    FTagMap.Add(LPair.Key, LPair.Value);
end;

constructor TAttributeTags.Create(const ATagSeparator, AValueSeparator: string; AQuoteChar: Char);
begin
  FTagSeparator := ATagSeparator;
  FValueSeparator := AValueSeparator;
  FQuoteChar := AQuoteChar;
  FTagMap := TDictionary<string, string>.Create;
end;

class constructor TAttributeTags.Create;
begin
  FContext := TRttiContext.Create;
  FInvariantFormat := TFormatSettings.Create;
  FInvariantFormat.DecimalSeparator := '.';
  FInvariantFormat.ThousandSeparator := #0;
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
    Exit(TValue.Empty);

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
          // Tag values are literal tokens (like Go struct tags), so the decimal
          // point is always '.' regardless of the current locale settings
          Result := StrToFloat(LValueStr, FInvariantFormat);
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
          LOrdinal := GetEnumValue(AType.Handle, LValueStr);
          LTypeData := GetTypeData(AType.Handle);

          if (LOrdinal >= LTypeData.MinValue) and (LOrdinal <= LTypeData.MaxValue) then
            TValue.Make(LOrdinal, AType.Handle, Result)
          else
            raise ENeonException.Create(SNeonErrorEnumNames);
        end;

      end;
    end;
  except
    on E: Exception do
      Exit(TValue.Empty);
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
end;

function TAttributeTags.GetValueAs<T>(const AName: string): T;
var
  LValue: TValue;
  LType: TRttiType;
begin
  LType := FContext.GetType(System.TypeInfo(T));
  LValue := ExtractValue(AName, LType);
  Result := LValue.AsType<T>;
end;

procedure TAttributeTags.Parse(const ATags: string);
var
  LPart, LTrimmedPart: string;
  LParts, LFrag: TArray<string>;
begin
  FTagMap.Clear;

  LParts := SplitRespectingQuotes(ATags, FTagSeparator, FQuoteChar);

  for LPart in LParts do
  begin
    LTrimmedPart := LPart.Trim;
    if LTrimmedPart.IsEmpty then
      Continue;

    LFrag := SplitRespectingQuotes(LTrimmedPart, FValueSeparator, FQuoteChar);
    case Length(LFrag) of
      1: FTagMap.AddOrSetValue(LFrag[0].Trim, '');                          // Named tag without value (bool true)
      2: FTagMap.AddOrSetValue(LFrag[0].Trim, UnquoteValue(LFrag[1].Trim)); // Named tag with value
    else
      raise ENeonException.CreateFmt(SNeonErrorTagParseF1, [LTrimmedPart]);
    end;
  end;
end;

class function TAttributeTags.SplitRespectingQuotes(const AStr, ASeparator: string; AQuoteChar: Char): TArray<string>;
var
  LResult: TList<string>;
  LBuffer: TStringBuilder;
  LInQuotes: Boolean;
  LIndex: Integer;
begin
  LResult := TList<string>.Create;
  LBuffer := TStringBuilder.Create;
  try
    LInQuotes := False;
    LIndex := 1;
    while LIndex <= AStr.Length do
    begin
      // Escaped quote: keep both characters literally, don't toggle quote state
      if (AStr[LIndex] = '\') and (LIndex < AStr.Length) and (AStr[LIndex + 1] = AQuoteChar) then
      begin
        LBuffer.Append(AStr[LIndex]).Append(AStr[LIndex + 1]);
        Inc(LIndex, 2);
        Continue;
      end;

      if AStr[LIndex] = AQuoteChar then
      begin
        LInQuotes := not LInQuotes;
        LBuffer.Append(AStr[LIndex]);
        Inc(LIndex);
        Continue;
      end;

      if (not LInQuotes) and (ASeparator <> '') and
         (LIndex + ASeparator.Length - 1 <= AStr.Length) and
         (AStr.Substring(LIndex - 1, ASeparator.Length) = ASeparator) then
      begin
        LResult.Add(LBuffer.ToString);
        LBuffer.Clear;
        Inc(LIndex, ASeparator.Length);
        Continue;
      end;

      LBuffer.Append(AStr[LIndex]);
      Inc(LIndex);
    end;
    LResult.Add(LBuffer.ToString);

    Result := LResult.ToArray;
  finally
    LBuffer.Free;
    LResult.Free;
  end;
end;

function TAttributeTags.UnquoteValue(const AValue: string): string;
begin
  Result := AValue;
  if (Result.Length >= 2) and (Result.Chars[0] = FQuoteChar) and (Result.Chars[Result.Length - 1] = FQuoteChar) then
  begin
    Result := Result.Substring(1, Result.Length - 2);
    Result := Result.Replace('\' + FQuoteChar, FQuoteChar, [rfReplaceAll]);
  end;
end;

{ TStructTag }

constructor TStructTag.Create(const ARaw: string);
begin
  FGroups := TDictionary<string, string>.Create;
  ParseRaw(ARaw);
end;

destructor TStructTag.Destroy;
begin
  FGroups.Free;

  inherited;
end;

class function TStructTag.Parse(const ARaw: string): TStructTag;
begin
  Result := TStructTag.Create(ARaw);
end;

procedure TStructTag.ParseRaw(const ARaw: string);
var
  LLength, LIndex, LKeyStart, LValueStart: Integer;
  LKey, LValue: string;
  LInEscape: Boolean;
begin
  FRaw := ARaw;
  FGroups.Clear;

  LLength := ARaw.Length;
  LIndex := 1;
  while True do
  begin
    // Skip leading spaces between groups
    while (LIndex <= LLength) and (ARaw[LIndex] = ' ') do
      Inc(LIndex);
    if LIndex > LLength then
      Break;

    // Scan the key: everything up to the first ':'
    LKeyStart := LIndex;
    while (LIndex <= LLength) and (ARaw[LIndex] <> ':') and
          (ARaw[LIndex] <> ' ') and (ARaw[LIndex] <> '"') do
      Inc(LIndex);

    // Malformed remainder (no ':"' following the key) - stop parsing,
    // mirroring Go's tolerant "ignore the rest" behavior
    if (LIndex >= LLength) or (ARaw[LIndex] <> ':') or (ARaw[LIndex + 1] <> '"') then
      Break;

    LKey := ARaw.Substring(LKeyStart - 1, LIndex - LKeyStart);
    Inc(LIndex, 2); // skip past : and the opening quote

    // Scan the quoted value, honoring \" as an escaped literal quote
    LValueStart := LIndex;
    LInEscape := False;
    while LIndex <= LLength do
    begin
      if LInEscape then
        LInEscape := False
      else if ARaw[LIndex] = '\' then
        LInEscape := True
      else if ARaw[LIndex] = '"' then
        Break;
      Inc(LIndex);
    end;

    if LIndex > LLength then
      Break; // unterminated quote

    LValue := ARaw.Substring(LValueStart - 1, LIndex - LValueStart);
    LValue := LValue.Replace('\"', '"', [rfReplaceAll]).Replace('\\', '\', [rfReplaceAll]);
    Inc(LIndex); // skip past the closing quote

    FGroups.AddOrSetValue(LKey, LValue);
  end;
end;

function TStructTag.Lookup(const AKey: string; out AValue: string): Boolean;
begin
  Result := FGroups.TryGetValue(AKey, AValue);
end;

function TStructTag.Get(const AKey: string): string;
begin
  Lookup(AKey, Result);
end;

function TStructTag.Exists(const AKey: string): Boolean;
var
  LValue: string;
begin
  Result := Lookup(AKey, LValue);
end;

function TStructTag.GetAttributeTags(const AKey: string): TAttributeTags;
var
  LValue: string;
begin
  Result := TAttributeTags.Create;
  if Lookup(AKey, LValue) then
    Result.Parse(LValue);
end;

end.
