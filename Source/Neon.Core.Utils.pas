{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Utils;

{$I Neon.inc}

interface

uses
  System.Classes, System.SysUtils, Data.DB, System.Rtti, System.JSON, System.TypInfo,
  {$IFDEF HAS_NET_ENCODING}
  System.NetEncoding,
  {$ELSE}
  IdCoder, IdCoderMIME, IdGlobal,
  {$ENDIF}
  System.Diagnostics,
  System.Generics.Collections;

type
  TJSONUtils = class
  public
    class procedure Decode(const ASource: string; ADest: TStream); overload;
    class function Encode(const ASource: TStream): string; overload;

    class function ToJSON(AJSONValue: TJSONValue): string; static;

    class function StringArrayToJsonArray(const AValues: TArray<string>): string; static;
    class function DoubleArrayToJsonArray(const AValues: TArray<Double>): string; static;
    class function IntegerArrayToJsonArray(const AValues: TArray<Integer>): string; static;

    class function HasItems(const AJSON: TJSONValue): Boolean;
    class function IsNotEmpty(const AJSON: TJSONValue): Boolean;
    class function IsNotDefault(const AJSON: TJSONValue): Boolean;

    class procedure JSONCopyFrom(ASource, ADestination: TJSONObject); static;

    class function GetValueBool(AJSON: TJSONValue): Boolean;
    class function GetJSONBool(const AValue: TValue): TJSONValue; overload;
    class function GetJSONBool(AValue: Boolean): TJSONValue; overload;
    class function IsBool(AJSON: TJSONValue): Boolean;

    class function BooleanToTJSON(AValue: Boolean): TJSONValue;

    class function DateToJSON(ADate: TDate): string; static;
    class function DateToJSONValue(ADate: TDate): TJSONValue; static;

    class function TimeToJSON(ATime: TTime): string; static;
    class function TimeToJSONValue(ATime: TTime): TJSONValue; static;

    class function DateTimeToJSON(ADateTime: TDateTime; AInputIsUTC: Boolean = True): string; static;
    class function DateTimeToJSONValue(ADateTime: TDateTime; AInputIsUTC: Boolean = True): TJSONValue; static;

    class function JSONToDate(const ADate: string): TDate; static;
    class function JSONToTime(const ATime: string): TTime; static;
    class function JSONToDateTime(const ADateTime: string; AReturnUTC: Boolean = True): TDateTime; static;

    class function TryJSONToDate(const ADate: string; out AValue: TDate): Boolean; static;
    class function TryJSONToTime(const ATime: string; out AValue: TTime): Boolean; static;
    class function TryJSONToDateTime(const ADateTime: string; out AValue: TDateTime; AReturnUTC: Boolean = True): Boolean; static;

    class procedure Prettify(const AJSONString: string; AWriter: TTextWriter);
  end;

  TRttiUtils = class
  private
    class var FContext: TRttiContext;
  public
    // TRttiObject helpers functions
    class function FindAttribute<T: TCustomAttribute>(AType: TRttiObject): T; overload; static;
    class function FindAttribute<T: TCustomAttribute>(const Attributes: TArray<TCustomAttribute>): T; overload; static;

    class function HasAttribute<T: TCustomAttribute>(AClass: TClass): Boolean; overload; static;

    class function HasAttribute<T: TCustomAttribute>(ARttiObj: TRttiObject): Boolean; overload; static;

    class function HasAttribute<T: TCustomAttribute>(ARttiObj: TRttiObject; const ADoSomething: TProc<T>): Boolean; overload; static;

    class function ForEachAttribute<T: TCustomAttribute>(
      ARttiObj: TRttiObject; const ADoSomething: TProc<T>): Integer; overload; static;

    // TRttiType helpers functions
    class function ForEachMethodWithAttribute<T: TCustomAttribute>(
      ARttiType: TRttiType; const ADoSomething: TFunc<TRttiMethod, T, Boolean>): Integer; static;

    class function ForEachFieldWithAttribute<T: TCustomAttribute>(
      ARttiType: TRttiType; const ADoSomething: TFunc<TRttiField, T, Boolean>): Integer; overload; static;

    class function ForEachPropertyWithAttribute<T: TCustomAttribute>(
      ARttiType: TRttiType; const ADoSomething: TFunc<TRttiProperty, T, Boolean>): Integer; overload; static;

    class function IsDynamicArrayOf<T: class>(ARttiType: TRttiType;
      const AAllowInherithance: Boolean = True): Boolean; overload; static;

    class function IsDynamicArrayOf(ARttiType: TRttiType; const AClass: TClass;
      const AAllowInherithance: Boolean = True): Boolean; overload; static;

    class function IsObjectOfType<T: class>(ARttiType: TRttiType;
      const AAllowInherithance: Boolean = True): Boolean; overload; static;

    class function IsObjectOfType(ARttiType: TRttiType; const AClass: TClass;
      const AAllowInherithance: Boolean = True): Boolean; overload; static;

    /// <summary>
    ///   Free array items (only if these are object)
    /// </summary>
    class procedure FreeArrayItems(const AData: TValue); static;

    /// <summary>
    ///   Raises when there is no type to create an instance of, so the
    ///   CreateInstance overloads report it instead of dereferencing nil
    /// </summary>
    class procedure CheckType(AType: TRttiType); static;

    /// <summary>
    ///   Create new value data
    /// </summary>
    class function CreateNewValue(AType: TRttiType): TValue; static;

    /// <summary>
    ///   Creates an instance of a class through its parameterless constructor,
    ///   and returns an empty value when the class has none
    /// </summary>
    /// <remarks>
    ///   The no-raise primitive the TryCreateInstance overloads are built on
    /// </remarks>
    class function CreateInstanceValue(AType: TRttiType): TValue; overload;

    // Create instance of class with parameterless constructor. Raises
    // ENeonException (SNeonErrorCreateInstanceF1) when the class has no such
    // constructor - see TryCreateInstance for the overloads that return nil
    class function CreateInstance<T: class, constructor>: TObject;  overload;
    class function CreateInstance(AClass: TClass): TObject;  overload;
    class function CreateInstance(AType: TRttiType): TObject; overload;
    class function CreateInstance(const ATypeName: string): TObject; overload;

    // Create instance of class with one string parameter
    class function CreateInstance(AClass: TClass; const AValue: string): TObject;  overload;
    class function CreateInstance(AType: TRttiType; const AValue: string): TObject; overload;
    class function CreateInstance(const ATypeName, AValue: string): TObject; overload;

    // Create instance of class with an array of TValue
    class function CreateInstance(AClass: TClass; const Args: array of TValue): TObject;  overload;
    class function CreateInstance(AType: TRttiType;  const Args: array of TValue): TObject; overload;
    class function CreateInstance(const ATypeName: string; const Args: array of TValue): TObject; overload;

    /// <summary>
    ///   The CreateInstance overloads for callers that treat "cannot create" as
    ///   a normal outcome: they return nil where CreateInstance raises
    /// </summary>
    /// <remarks>
    ///   The engine uses these where a member that cannot be built is logged and
    ///   skipped (no AutoCreate, no factory, an abstract class); everything that
    ///   cannot continue without the instance calls CreateInstance and lets the
    ///   exception out
    /// </remarks>
    class function TryCreateInstance<T: class, constructor>: TObject;  overload;
    class function TryCreateInstance(AClass: TClass): TObject;  overload;
    class function TryCreateInstance(AType: TRttiType): TObject; overload;
    class function TryCreateInstance(const ATypeName: string): TObject; overload;

    class function TryCreateInstance(AClass: TClass; const AValue: string): TObject;  overload;
    class function TryCreateInstance(AType: TRttiType; const AValue: string): TObject; overload;
    class function TryCreateInstance(const ATypeName, AValue: string): TObject; overload;

    class function TryCreateInstance(AClass: TClass; const Args: array of TValue): TObject;  overload;
    class function TryCreateInstance(AType: TRttiType; const Args: array of TValue): TObject; overload;
    class function TryCreateInstance(const ATypeName: string; const Args: array of TValue): TObject; overload;

    // Rtti general helper functions
    class function IfHasAttribute<T: TCustomAttribute>(AInstance: TObject): Boolean; overload;
    class function IfHasAttribute<T: TCustomAttribute>(AInstance: TObject; const ADoSomething: TProc<T>): Boolean; overload;

    class function ForEachAttribute<T: TCustomAttribute>(AInstance: TObject; const ADoSomething: TProc<T>): Integer; overload;

    class function ForEachFieldWithAttribute<T: TCustomAttribute>(AInstance: TObject; const ADoSomething: TFunc<TRttiField, T, Boolean>): Integer; overload;
    class function ForEachField(AInstance: TObject; const ADoSomething: TFunc<TRttiField, Boolean>): Integer;

    class function GetType(AValue: TValue): TRttiType; overload;
    class function GetType(AObject: TRttiObject): TRttiType; overload;

    class function GetSetElementType(ASetType: TRttiType): TRttiType;

    class function ClassDistanceFromRoot(AClass: TClass): Integer; overload; static;
    class function ClassDistanceFromRoot(AInfo: PTypeInfo): Integer; overload; static;

    class property Context: TRttiContext read FContext;
  end;

  TBase64 = class
  public
    class function Encode(const ASource: TBytes): string; overload;
    class function Encode(const ASource: TStream): string; overload;

    class function Decode(const ASource: string): TBytes; overload;
    class procedure Decode(const ASource: string; ADest: TStream); overload;
  end;

  TDataSetUtils = class
  private
    class procedure SetField(AField: TField; AJSON: TJSONValue; AUseUTCDate: Boolean);
  public
    class function RecordToJSONSchema(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject; static;

    class function FieldToJSONValue(const AField: TField; AUseUTCDate: Boolean): TJSONValue; static;
    class function RecordToJSONObject(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONArray; overload; static;
    class function DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AUseUTCDate: Boolean): TJSONArray; overload; static;

    class procedure JSONToRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AUseUTCDate: Boolean); static;
    class procedure JSONToCurrentRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AUseUTCDate: Boolean); static;
    class procedure JSONToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean); static;
    class procedure JSONObjectToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean); static;

    class function BlobFieldToBase64(ABlobField: TBlobField): string;
    class procedure Base64ToBlobField(const ABase64: string; ABlobField: TBlobField);
  end;

  TNeonLogger = class
  private
    class var FProfileEnabled: Boolean;
    class var FProfileData: TDictionary<string, TPair<Int64, Int64>>;
  public
    class procedure Console(const AMessage: string); static; inline;
    class procedure ConsoleWatch(const AMessage: string; var AWatch: TStopwatch); static; inline;
    class procedure Debug(const AMessage: string); static; inline;
    class procedure DebugWatch(const AMessage: string; var AWatch: TStopwatch); static; inline;

    /// <summary>
    ///   Lightweight, opt-in profiler: accumulates total elapsed time and
    ///   call count per named section (e.g. "Serialize:Object"). Disabled
    ///   by default, in which case ProfileBegin/ProfileEnd cost only a
    ///   boolean check, so it is safe to leave the calls in shipped code.
    /// </summary>
    class property ProfileEnabled: Boolean read FProfileEnabled write FProfileEnabled;
    class procedure ProfileReset; static;
    class function ProfileBegin: Int64; static; inline;
    class procedure ProfileEnd(const ASection: string; AStartStamp: Int64); static;
    class function ProfileReport: string; static;
  end;

implementation

uses
  System.StrUtils, System.DateUtils, System.Math, System.Variants,
  System.Generics.Defaults,
  {$IFDEF MSWINDOWS}Winapi.Windows,{$ENDIF}
  Neon.Core.Types;

class function TRttiUtils.ClassDistanceFromRoot(AClass: TClass): Integer;
var
  LClass: TClass;
begin
  Result := 0;
  LClass := AClass;
  while LClass <> TObject do
  begin
    LClass := LClass.ClassParent;
    Inc(Result);
  end;
end;

class function TRttiUtils.ClassDistanceFromRoot(AInfo: PTypeInfo): Integer;
var
  LType: TRttiType;
begin
  Result := -1;

  LType := TRttiUtils.Context.GetType(AInfo);
  if Assigned(LType) and (LType.TypeKind = tkClass) then
    Result := TRttiUtils.ClassDistanceFromRoot(LType.AsInstance.MetaclassType);
end;

class procedure TRttiUtils.FreeArrayItems(const AData: TValue);
var
  LIndex: NativeInt;
  LItemValue: TValue;
  LArrayLength: NativeInt;
begin
  // Free Array Items (if objects)
  LArrayLength := AData.GetArrayLength;
  for LIndex := 0 to LArrayLength - 1 do
  begin
    LItemValue := AData.GetArrayElement(LIndex);
    if LItemValue.IsObject then
      if Assigned(LItemValue.AsObject()) then
        LItemValue.AsObject.Free;
  end;
end;

class procedure TRttiUtils.CheckType(AType: TRttiType);
begin
  if not Assigned(AType) then
    raise ENeonException.Create(SNeonErrorObjectNoType);
end;

class function TRttiUtils.CreateNewValue(AType: TRttiType): TValue;
var
  LAllocatedMem: Pointer;
begin
  case AType.TypeKind of
    tkEnumeration: Result := TValue.From<Byte>(0);
    tkInteger:     Result := TValue.From<Integer>(0);
    tkInt64:       Result := TValue.From<Int64>(0);
{$IFDEF HAS_UTF8CHAR}
    tkChar:        Result := TValue.From<UTF8Char>(#0);
{$ELSE}
    tkChar,
{$ENDIF}
    tkWChar:       Result := TValue.From<Char>(#0);
    tkFloat:       Result := TValue.From<Double>(0);
    tkString:      Result := TValue.From<UTF8String>('');
    tkWString:     Result := TValue.From<string>('');
    tkLString:     Result := TValue.From<UTF8String>('');
    tkUString:     Result := TValue.From<string>('');
    tkVariant:     Result := TValue.From<Variant>(Null);

    // A class with no parameterless constructor is left as a nil object here:
    // the caller (a list/array/map item, a member) logs and skips it, which is
    // why this is the Try overload and not CreateInstance
    tkClass:       Result := TryCreateInstance(AType);

    {$IFDEF HAS_MRECORDS}tkMRecord,{$ENDIF}
    tkRecord, tkDynArray:
    begin
      LAllocatedMem := AllocMem(AType.TypeSize);
      try
        TValue.Make(LAllocatedMem, AType.Handle, Result);
      finally
        FreeMem(LAllocatedMem);
      end;
    end;
  else
    raise ENeonException.CreateFmt(SNeonErrorCreateTypeF1, [AType.Name]);
  end;
end;

class function TRttiUtils.TryCreateInstance(AClass: TClass): TObject;
var
  LType: TRttiType;
begin
  LType := FContext.GetType(AClass);
  Result := CreateInstanceValue(LType).AsObject;
end;

class function TRttiUtils.TryCreateInstance(AType: TRttiType): TObject;
begin
  Result := CreateInstanceValue(AType).AsObject;
end;

class function TRttiUtils.TryCreateInstance(const ATypeName: string): TObject;
var
  LType: TRttiType;
begin
  LType := Context.FindType(ATypeName);
  Result := CreateInstanceValue(LType).AsObject;
end;

class function TRttiUtils.CreateInstance(AClass: TClass): TObject;
begin
  Result := CreateInstance(FContext.GetType(AClass));
end;

class function TRttiUtils.CreateInstance(AType: TRttiType): TObject;
begin
  CheckType(AType);
  Result := CreateInstanceValue(AType).AsObject;
  if not Assigned(Result) then
    raise ENeonException.CreateFmt(SNeonErrorCreateInstanceF1, [AType.Name]);
end;

class function TRttiUtils.CreateInstance(const ATypeName: string): TObject;
var
  LType: TRttiType;
begin
  LType := Context.FindType(ATypeName);
  if not Assigned(LType) then
    raise ENeonException.CreateFmt(SNeonErrorCreateInstanceF1, [ATypeName]);
  Result := CreateInstance(LType);
end;

class function TRttiUtils.TryCreateInstance(AClass: TClass; const AValue: string): TObject;
begin
  Result := TryCreateInstance(FContext.GetType(AClass), AValue);
end;

class function TRttiUtils.CreateInstance(AClass: TClass; const AValue: string): TObject;
begin
  Result := CreateInstance(FContext.GetType(AClass), AValue);
end;

class function TRttiUtils.TryCreateInstance(AType: TRttiType; const AValue: string): TObject;
var
  LMethod: TRttiMethod;
  LMetaClass: TClass;
begin
  Result := nil;
  if Assigned(AType) then
  begin
    for LMethod in AType.GetMethods do
    begin
      if LMethod.HasExtendedInfo and LMethod.IsConstructor then
      begin
        if Length(LMethod.GetParameters) = 1 then
        begin
          if LMethod.GetParameters[0].ParamType.TypeKind in [tkLString, tkUString, tkWString, tkString] then
          begin
            LMetaClass := AType.AsInstance.MetaclassType;
            Exit(LMethod.Invoke(LMetaClass, [AValue]).AsObject);
          end;
        end;
      end;
    end;
  end;
end;

class function TRttiUtils.CreateInstance(AType: TRttiType; const AValue: string): TObject;
begin
  CheckType(AType);
  Result := TryCreateInstance(AType, AValue);
  if not Assigned(Result) then
    raise ENeonException.CreateFmt(SNeonErrorCreateInstanceF1, [AType.Name]);
end;

class function TRttiUtils.TryCreateInstance(const ATypeName, AValue: string): TObject;
begin
  Result := TryCreateInstance(Context.FindType(ATypeName), AValue);
end;

class function TRttiUtils.CreateInstance(const ATypeName, AValue: string): TObject;
var
  LType: TRttiType;
begin
  LType := Context.FindType(ATypeName);
  if not Assigned(LType) then
    raise ENeonException.CreateFmt(SNeonErrorCreateInstanceF1, [ATypeName]);
  Result := CreateInstance(LType, AValue);
end;

class function TRttiUtils.CreateInstanceValue(AType: TRttiType): TValue;
var
  LMethod: TRTTIMethod;
  LMetaClass: TClass;
begin
  Result := nil;
  if Assigned(AType) then
    for LMethod in AType.GetMethods do
    begin
      if LMethod.HasExtendedInfo and LMethod.IsConstructor then
      begin
        if Length(LMethod.GetParameters) = 0 then
        begin
          LMetaClass := AType.AsInstance.MetaclassType;
          Exit(LMethod.Invoke(LMetaClass, []));
        end;
      end;
    end;
end;

class function TRttiUtils.FindAttribute<T>(const Attributes: TArray<TCustomAttribute>): T;
var
  LAttribute: TCustomAttribute;
begin
  Result := nil;
  for LAttribute in Attributes do
  begin
    if LAttribute.InheritsFrom(TClass(T)) then
    begin
      Result := LAttribute as T;

      Break;
    end;
  end;
end;

class function TRttiUtils.ForEachAttribute<T>(AInstance: TObject;
  const ADoSomething: TProc<T>): Integer;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  Result := 0;
  LType := LContext.GetType(AInstance.ClassType);
  if Assigned(LType) then
    Result := TRttiUtils.ForEachAttribute<T>(LType, ADoSomething);
end;

class function TRttiUtils.ForEachField(AInstance: TObject;
  const ADoSomething: TFunc<TRttiField, Boolean>): Integer;
var
  LContext: TRttiContext;
  LField: TRttiField;
  LType: TRttiType;
  LBreak: Boolean;
begin
  Result := 0;
  LType := LContext.GetType(AInstance.ClassType);
  for LField in LType.GetFields do
  begin
    LBreak := False;

    if Assigned(ADoSomething) then
    begin
      if not ADoSomething(LField) then
        LBreak := True
      else
        Inc(Result);
    end;

    if LBreak then
      Break;
  end;
end;

class function TRttiUtils.ForEachFieldWithAttribute<T>(AInstance: TObject;
  const ADoSomething: TFunc<TRttiField, T, Boolean>): Integer;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  Result := 0;
  LType := LContext.GetType(AInstance.ClassType);
  if Assigned(LType) then
    Result := TRttiUtils.ForEachFieldWithAttribute<T>(LType, ADoSomething);
end;

class function TRttiUtils.IfHasAttribute<T>(AInstance: TObject): Boolean;
begin
  Result := TRttiUtils.IfHasAttribute<T>(AInstance, nil);
end;

class function TRttiUtils.IfHasAttribute<T>(AInstance: TObject; const ADoSomething: TProc<T>): Boolean;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  Result := False;
  LType := LContext.GetType(AInstance.ClassType);
  if Assigned(LType) then
    Result := TRttiUtils.HasAttribute<T>(LType, ADoSomething);
end;

class function TRttiUtils.ForEachAttribute<T>(ARttiObj: TRttiObject;
    const ADoSomething: TProc<T>): Integer;
var
  LAttribute: TCustomAttribute;
begin
  Result := 0;
  for LAttribute in ARttiObj.GetAttributes do
  begin
    if LAttribute.InheritsFrom(TClass(T)) then
    begin
      if Assigned(ADoSomething) then
        ADoSomething(T(LAttribute));
      Inc(Result);
    end;
  end;
end;

class function TRttiUtils.HasAttribute<T>(ARttiObj: TRttiObject): Boolean;
begin
  Result := HasAttribute<T>(ARttiObj, nil);
end;

class function TRttiUtils.HasAttribute<T>(ARttiObj: TRttiObject; const ADoSomething: TProc<T>): Boolean;
var
  LAttribute: TCustomAttribute;
begin
  Result := False;
  for LAttribute in ARttiObj.GetAttributes do
  begin
    if LAttribute.InheritsFrom(TClass(T)) then
    begin
      Result := True;

      if Assigned(ADoSomething) then
        ADoSomething(T(LAttribute));

      Break;
    end;
  end;
end;

class function TRttiUtils.ForEachFieldWithAttribute<T>(ARttiType: TRttiType;
  const ADoSomething: TFunc<TRttiField, T, Boolean>): Integer;
var
  LField: TRttiField;
  LBreak: Boolean;
begin
  Result := 0;
  for LField in ARttiType.GetFields do
  begin
    LBreak := False;
    if TRttiUtils.HasAttribute<T>(LField,
       procedure (AAttrib: T)
       begin
         if Assigned(ADoSomething) then
         begin
           if not ADoSomething(LField, AAttrib) then
             LBreak := True;
         end;
       end
    )
    then
      Inc(Result);

    if LBreak then
      Break;
  end;
end;

class function TRttiUtils.ForEachMethodWithAttribute<T>(ARttiType: TRttiType;
  const ADoSomething: TFunc<TRttiMethod, T, Boolean>): Integer;
var
  LMethod: TRttiMethod;
  LBreak: Boolean;
begin
  Result := 0;
  for LMethod in ARttiType.GetMethods do
  begin
    LBreak := False;
    if TRttiUtils.HasAttribute<T>(LMethod,
       procedure (AAttrib: T)
       begin
         if Assigned(ADoSomething) then
         begin
           if not ADoSomething(LMethod, AAttrib) then
             LBreak := True;
         end;
       end
    )
    then
      Inc(Result);

    if LBreak then
      Break;
  end;
end;

class function TRttiUtils.ForEachPropertyWithAttribute<T>(ARttiType: TRttiType;
  const ADoSomething: TFunc<TRttiProperty, T, Boolean>): Integer;
var
  LProperty: TRttiProperty;
  LBreak: Boolean;
begin
  Result := 0;
  for LProperty in ARttiType.GetProperties do
  begin
    LBreak := False;
    if TRttiUtils.HasAttribute<T>(LProperty,
       procedure (AAttrib: T)
       begin
         if Assigned(ADoSomething) then
         begin
           if not ADoSomething(LProperty, AAttrib) then
             LBreak := True;
         end;
       end
    )
    then
      Inc(Result);

    if LBreak then
      Break;
  end;
end;

class function TRttiUtils.GetSetElementType(ASetType: TRttiType): TRttiType;
var
  LEnumInfo: PPTypeInfo;
begin
  LEnumInfo := GetTypeData(ASetType.Handle)^.CompType;
  Result := TRttiUtils.Context.GetType(LEnumInfo^);
end;

class function TRttiUtils.GetType(AValue: TValue): TRttiType;
begin
  Result := FContext.GetType(AValue.TypeInfo);
end;

class function TRttiUtils.GetType(AObject: TRttiObject): TRttiType;
begin
  if AObject is TRttiParameter then
    Result := TRttiParameter(AObject).ParamType
  else if AObject is TRttiField then
    Result := TRttiField(AObject).FieldType
  else if AObject is TRttiProperty then
    Result := TRttiProperty(AObject).PropertyType
  else if AObject is TRttiManagedField then
    Result := TRttiManagedField(AObject).FieldType
  else
    raise Exception.Create(SNeonErrorObjectNoType);
end;

class function TRttiUtils.HasAttribute<T>(AClass: TClass): Boolean;
begin
  Result := HasAttribute<T>(Context.GetType(AClass));
end;

class function TRttiUtils.IsDynamicArrayOf(ARttiType: TRttiType;
  const AClass: TClass; const AAllowInherithance: Boolean): Boolean;
begin
  Result := False;
  if ARttiType is TRttiDynamicArrayType then
    Result := TRttiUtils.IsObjectOfType(
      TRttiDynamicArrayType(ARttiType).ElementType, AClass, AAllowInherithance);
end;

class function TRttiUtils.IsDynamicArrayOf<T>(ARttiType: TRttiType;
  const AAllowInherithance: Boolean): Boolean;
begin
  Result := TRttiUtils.IsDynamicArrayOf(ARttiType, TClass(T), AAllowInherithance);
end;

class function TRttiUtils.IsObjectOfType(ARttiType: TRttiType;
  const AClass: TClass; const AAllowInherithance: Boolean): Boolean;
begin
  Result := False;
  if ARttiType is TRttiInstanceType then
  begin
    if AAllowInherithance then
      Result := TRttiInstanceType(ARttiType).MetaclassType.InheritsFrom(AClass)
    else
      Result := TRttiInstanceType(ARttiType).MetaclassType = AClass;
  end;
end;

class function TRttiUtils.IsObjectOfType<T>(ARttiType: TRttiType; const AAllowInherithance: Boolean): Boolean;
begin
  Result := TRttiUtils.IsObjectOfType(ARttiType, TClass(T), AAllowInherithance);
end;

class function TRttiUtils.FindAttribute<T>(AType: TRttiObject): T;
var
  LAttribute: TCustomAttribute;
begin
  Result := nil;
  for LAttribute in AType.GetAttributes do
  begin
    if LAttribute.InheritsFrom(TClass(T)) then
    begin
      Result := LAttribute as T;

      Break;
    end;
  end;
end;

class function TRttiUtils.TryCreateInstance(AClass: TClass; const Args: array of TValue): TObject;
begin
  Result := TryCreateInstance(FContext.GetType(AClass), Args);
end;

class function TRttiUtils.CreateInstance(AClass: TClass; const Args: array of TValue): TObject;
begin
  Result := CreateInstance(FContext.GetType(AClass), Args);
end;

class function TRttiUtils.TryCreateInstance(AType: TRttiType; const Args: array of TValue): TObject;
var
  LMethod: TRttiMethod;
  LMetaClass: TClass;
begin
  Result := nil;
  if Assigned(AType) then
  begin
    for LMethod in AType.GetMethods do
    begin
      if LMethod.HasExtendedInfo and LMethod.IsConstructor then
      begin
        if Length(LMethod.GetParameters) = Length(Args) then
        begin
          LMetaClass := AType.AsInstance.MetaclassType;
          Exit(LMethod.Invoke(LMetaClass, Args).AsObject);
        end;
      end;
    end;
  end;
end;

class function TRttiUtils.CreateInstance(AType: TRttiType; const Args: array of TValue): TObject;
begin
  CheckType(AType);
  Result := TryCreateInstance(AType, Args);
  if not Assigned(Result) then
    raise ENeonException.CreateFmt(SNeonErrorCreateInstanceF1, [AType.Name]);
end;

class function TRttiUtils.TryCreateInstance(const ATypeName: string; const Args: array of TValue): TObject;
begin
  Result := TryCreateInstance(Context.FindType(ATypeName), Args);
end;

class function TRttiUtils.CreateInstance(const ATypeName: string; const Args: array of TValue): TObject;
var
  LType: TRttiType;
begin
  LType := Context.FindType(ATypeName);
  if not Assigned(LType) then
    raise ENeonException.CreateFmt(SNeonErrorCreateInstanceF1, [ATypeName]);
  Result := CreateInstance(LType, Args);
end;

class function TRttiUtils.TryCreateInstance<T>: TObject;
begin
  Result := TryCreateInstance(TRttiUtils.Context.GetType(TClass(T)));
end;

class function TRttiUtils.CreateInstance<T>: TObject;
begin
  Result := CreateInstance(TRttiUtils.Context.GetType(TClass(T)));
end;

class function TJSONUtils.BooleanToTJSON(AValue: Boolean): TJSONValue;
begin
  if AValue then
    Result := TJSONTrue.Create
  else
    Result := TJSONFalse.Create;
end;

class function TJSONUtils.DateToJSON(ADate: TDate): string;
begin
  Result := '';
  if ADate <> 0 then
    Result := FormatDateTime('YYYY-MM-DD', ADate);
end;

class function TJSONUtils.DateToJSONValue(ADate: TDate): TJSONValue;
begin
  Result := TJSONString.Create(TJSONUtils.DateToJSON(ADate));
end;

class function TJSONUtils.TimeToJSON(ATime: TTime): string;
var
  LHour, LMin, LSec, LMSec: Word;
begin
  Result := '';
  if ATime = 0 then
    Exit;

  { Milliseconds are emitted only when they carry information, so whole-second
    times keep the plain hh:nn:ss form and no sub-second data is ever lost }
  DecodeTime(ATime, LHour, LMin, LSec, LMSec);
  if LMSec = 0 then
    Result := Format('%.2d:%.2d:%.2d', [LHour, LMin, LSec])
  else
    Result := Format('%.2d:%.2d:%.2d.%.3d', [LHour, LMin, LSec, LMSec]);
end;

class function TJSONUtils.TimeToJSONValue(ATime: TTime): TJSONValue;
begin
  Result := TJSONString.Create(TJSONUtils.TimeToJSON(ATime));
end;

class function TJSONUtils.DateTimeToJSON(ADateTime: TDateTime; AInputIsUTC: Boolean = True): string;
begin
  Result := '';
  if ADateTime <> 0 then
    Result := DateToISO8601(ADateTime, AInputIsUTC);
end;

class function TJSONUtils.DateTimeToJSONValue(ADateTime: TDateTime; AInputIsUTC: Boolean): TJSONValue;
begin
  Result := TJSONString.Create(TJSONUtils.DateTimeToJSON(ADateTime, AInputIsUTC));
end;

class procedure TJSONUtils.Decode(const ASource: string; ADest: TStream);
{$IFDEF HAS_NET_ENCODING}
var
  LBase64Stream: TStringStream;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create(ASource);
  LBase64Stream.Position := soFromBeginning;
  try
    TNetEncoding.Base64.Decode(LBase64Stream, ADest);
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  TIdDecoderMIME.DecodeStream(ASource, ADest);
{$ENDIF}
end;

class function TJSONUtils.DoubleArrayToJsonArray(const AValues: TArray<Double>): string;
var
  LArray: TJSONArray;
  LIndex: Integer;
begin
  LArray := TJSONArray.Create;
  try
    for LIndex := 0 to High(AValues) do
      LArray.Add(AValues[LIndex]);
    Result := ToJSON(LArray);
  finally
    LArray.Free;
  end;
end;

class function TJSONUtils.Encode(const ASource: TStream): string;
{$IFDEF HAS_NET_ENCODING}
var
  LBase64Stream: TStringStream;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create;
  try
    TNetEncoding.Base64.Encode(ASource, LBase64Stream);
    Result := LBase64Stream.DataString;
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  Result := TIdEncoderMIME.EncodeStream(ASource);
{$ENDIF}
end;

class function TJSONUtils.GetJSONBool(const AValue: TValue): TJSONValue;
begin
{$IFDEF HAS_JSON_BOOL}
  Result := TJSONBool.Create(AValue.AsBoolean);
{$ELSE}
  if AValue.AsBoolean then
    Result := TJSONTrue.Create
  else
    Result := TJsonFalse.Create;
{$ENDIF}
end;

class function TJSONUtils.GetJSONBool(AValue: Boolean): TJSONValue;
begin
{$IFDEF HAS_JSON_BOOL}
  Result := TJSONBool.Create(AValue);
{$ELSE}
  if AValue then
    Result := TJSONTrue.Create
  else
    Result := TJsonFalse.Create;
{$ENDIF}
end;

class function TJSONUtils.GetValueBool(AJSON: TJSONValue): Boolean;
begin
{$IFDEF HAS_JSON_BOOL}
  if AJSON is TJSONBool then
    Result := (AJSON as TJSONBool).AsBoolean
  else
    raise ENeonException.Create(SNeonErrorJSONNotBoolean);
{$ELSE}
  if AJSON is TJSONTrue then
    Result := True
  else if AJSON is TJSONFalse then
    Result := False
  else
    raise ENeonException.Create(SNeonErrorJSONNotBoolean);
{$ENDIF}
end;

class function TJSONUtils.IsBool(AJSON: TJSONValue): Boolean;
begin
  Result := False;
{$IFDEF HAS_JSON_BOOL}
  if AJSON is TJSONBool then
    Result := True;
{$ELSE}
  if (AJSON is TJSONTrue) or (AJSON is TJSONFalse) then
    Result := True;
{$ENDIF}
end;

class function TJSONUtils.HasItems(const AJSON: TJSONValue): Boolean;
begin
  Result := True;

  if AJSON = nil then
    Exit(False);

  if AJSON is TJSONNull then
    Exit(False);

  if AJSON is TJSONObject then
    Exit((AJSON as TJSONObject).Count > 0);

  if AJSON is TJSONArray then
    Exit((AJSON as TJSONArray).Count > 0);
end;

class function TJSONUtils.IsNotEmpty(const AJSON: TJSONValue): Boolean;
begin
  Result := True;

  if AJSON = nil then
    Exit(False);

  if AJSON is TJSONNull then
    Exit(False);

  if AJSON is TJSONString then
    Exit(not (AJSON as TJSONString).Value.IsEmpty);

  if AJSON is TJSONObject then
    Exit((AJSON as TJSONObject).Count > 0);

  if AJSON is TJSONArray then
    Exit((AJSON as TJSONArray).Count > 0);
end;

class function TJSONUtils.IsNotDefault(const AJSON: TJSONValue): Boolean;
begin
  Result := True;

  if AJSON = nil then
    Exit(False);

  if AJSON is TJSONNull then
    Exit(False);

  if AJSON is TJSONString then
    Exit(not (AJSON as TJSONString).Value.IsEmpty);

  if AJSON is TJSONNumber then
  begin
    if (AJSON as TJSONNumber).Value.Contains('.') then
      Exit(not IsZero((AJSON as TJSONNumber).AsDouble));

    Exit(not (AJSON as TJSONNumber).AsInt = 0);
  end;

  if AJSON is TJSONObject then
    Exit((AJSON as TJSONObject).Count > 0);

  if AJSON is TJSONArray then
    Exit((AJSON as TJSONArray).Count > 0);
end;

class function TJSONUtils.IntegerArrayToJsonArray(const AValues: TArray<Integer>): string;
var
  LArray: TJSONArray;
  LIndex: Integer;
begin
  LArray := TJSONArray.Create;
  try
    for LIndex := 0 to High(AValues) do
      LArray.Add(AValues[LIndex]);
    Result := ToJSON(LArray);
  finally
    LArray.Free;
  end;
end;

class function TJSONUtils.TryJSONToDate(const ADate: string; out AValue: TDate): Boolean;

  {YYYY-MM-DD} // Possible RegEx => ^(?:\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01]))$
  function TryParsePlainDate(const AText: string; out ADateTime: TDateTime): Boolean;
  var
    LYear, LMonth, LDay: Integer;
  begin
    Result := False;

    if (Length(AText) <> 10) or (AText[5] <> '-') or (AText[8] <> '-') then
      Exit;

    if not TryStrToInt(Copy(AText, 1, 4), LYear) then
      Exit;
    if not TryStrToInt(Copy(AText, 6, 2), LMonth) then
      Exit;
    if not TryStrToInt(Copy(AText, 9, 2), LDay) then
      Exit;

    { Explicit range check: TryEncodeDate takes Word parameters }
    if (LYear < 1) or (LYear > 9999) or (LMonth < 1) or (LMonth > 12) or
       (LDay < 1) or (LDay > 31) then
      Exit;

    Result := TryEncodeDate(LYear, LMonth, LDay, ADateTime);
  end;

var
  LDateTime: TDateTime;
begin
  AValue := 0.0;
  if ADate.IsEmpty then
    Exit(True);

  if TryParsePlainDate(ADate, LDateTime) then
  begin
    AValue := LDateTime;
    Exit(True);
  end;

  { Anything else is handed to the RTL parser, so a full ISO-8601 date/time is
    accepted for a TDate as well (the time part is dropped) }
  Result := TryISO8601ToDate(ADate, LDateTime, True);
  if Result then
    AValue := DateOf(LDateTime);
end;

class function TJSONUtils.TryJSONToTime(const ATime: string; out AValue: TTime): Boolean;

  {hh:nn[:ss[.zzz]][Z]} // Possible RegEx => ^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d(?:[.,]\d+)?)?Z?$
  function TryParsePlainTime(const AText: string; out ADateTime: TDateTime): Boolean;
  var
    LTime, LFraction: string;
    LParts: TArray<string>;
    LHour, LMin, LSec, LMSec, LSepIndex: Integer;
  begin
    Result := False;

    LTime := AText;
    if LTime.EndsWith('Z', True) then
      LTime := LTime.Substring(0, LTime.Length - 1);

    LMSec := 0;
    LSepIndex := LTime.IndexOfAny(['.', ',']);
    if LSepIndex >= 0 then
    begin
      { Normalize the fractional part to exactly 3 digits (milliseconds) }
      LFraction := LTime.Substring(LSepIndex + 1);
      LTime := LTime.Substring(0, LSepIndex);
      if LFraction.IsEmpty then
        Exit;
      LFraction := Copy(LFraction + '000', 1, 3);
      if not TryStrToInt(LFraction, LMSec) then
        Exit;
    end;

    LParts := LTime.Split([':']);
    if (Length(LParts) < 2) or (Length(LParts) > 3) then
      Exit;

    LSec := 0;
    if not TryStrToInt(LParts[0], LHour) then
      Exit;
    if not TryStrToInt(LParts[1], LMin) then
      Exit;
    if (Length(LParts) = 3) and not TryStrToInt(LParts[2], LSec) then
      Exit;

    { Explicit range check: TryEncodeTime takes Word parameters }
    if (LHour < 0) or (LHour > 23) or (LMin < 0) or (LMin > 59) or
       (LSec < 0) or (LSec > 59) or (LMSec < 0) or (LMSec > 999) then
      Exit;

    Result := TryEncodeTime(LHour, LMin, LSec, LMSec, ADateTime);
  end;

var
  LDateTime: TDateTime;
begin
  AValue := 0.0;
  if ATime.IsEmpty then
    Exit(True);

  if not ATime.Contains('-') and TryParsePlainTime(ATime, LDateTime) then
  begin
    AValue := LDateTime;
    Exit(True);
  end;

  { Anything else is handed to the RTL parser, so a full ISO-8601 date/time is
    accepted for a TTime as well (the date part is dropped) }
  Result := TryISO8601ToDate(ATime, LDateTime, True);
  if Result then
    AValue := TimeOf(LDateTime);
end;

class function TJSONUtils.TryJSONToDateTime(const ADateTime: string; out AValue: TDateTime;
  AReturnUTC: Boolean): Boolean;
begin
  AValue := 0.0;
  if ADateTime.IsEmpty then
    Exit(True);

  Result := TryISO8601ToDate(ADateTime, AValue, AReturnUTC);
end;

class function TJSONUtils.JSONToDate(const ADate: string): TDate;
begin
  if not TryJSONToDate(ADate, Result) then
    raise ENeonException.CreateFmt(SNeonErrorDateInvalidF1, [ADate]);
end;

class function TJSONUtils.JSONToTime(const ATime: string): TTime;
begin
  if not TryJSONToTime(ATime, Result) then
    raise ENeonException.CreateFmt(SNeonErrorTimeInvalidF1, [ATime]);
end;

class procedure TJSONUtils.Prettify(const AJSONString: string; AWriter: TTextWriter);
var
  LChar: Char;
  LOffset: Integer;
  LIndex: Integer;
  LBackslashes: Integer;
  LOutsideString: Boolean;

  function Spaces(AOffset: Integer): string; inline;
  begin
    Result := StringOfChar(#32, AOffset * 2);
  end;

begin
  LOffset := 0;
  LOutsideString := True;

  LBackslashes := 0;
  for LIndex := 0 to Length(AJSONString) - 1 do
  begin
    LChar := AJSONString.Chars[LIndex];

    // A quote ends the string only when it is not escaped, and it is escaped
    // only after an odd number of backslashes: in "C:\\" the two backslashes
    // escape each other, so the quote that follows them is the terminator
    if (LChar = '"') and not Odd(LBackslashes) then
      LOutsideString := not LOutsideString;

    if LChar = '\' then
      Inc(LBackslashes)
    else
      LBackslashes := 0;

    if LOutsideString and (LChar = '{') then
    begin
      Inc(LOffset);
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = '}') then
    begin
      Dec(LOffset);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
      AWriter.Write(LChar);
    end
    else if LOutsideString and (LChar = ',') then
    begin
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = '[') then
    begin
      Inc(LOffset);
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = ']') then
    begin
      Dec(LOffset);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
      AWriter.Write(LChar);
    end
    else if LOutsideString and (LChar = ':') then
    begin
      AWriter.Write(LChar);
      AWriter.Write(' ');
    end
    else
      AWriter.Write(LChar);
  end;

end;

class function TJSONUtils.JSONToDateTime(const ADateTime: string; AReturnUTC: Boolean = True): TDateTime;
begin
  if not TryJSONToDateTime(ADateTime, Result, AReturnUTC) then
    raise ENeonException.CreateFmt(SNeonErrorDateTimeInvalidF1, [ADateTime]);
end;

class function TJSONUtils.ToJSON(AJSONValue: TJSONValue): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AJSONValue.ToString.Length * 6);
  SetLength(LBytes, AJSONValue.ToBytes(LBytes, 0));
  Result := TEncoding.Default.GetString(LBytes);
end;

class function TJSONUtils.StringArrayToJsonArray(const AValues: TArray<string>): string;
var
  LArray: TJSONArray;
  LIndex: Integer;
begin
  LArray := TJSONArray.Create;
  try
    for LIndex := 0 to High(AValues) do
      LArray.Add(AValues[LIndex]);
    Result := ToJSON(LArray);
  finally
    LArray.Free;
  end;
end;

class procedure TJSONUtils.JSONCopyFrom(ASource, ADestination: TJSONObject);
var
  LPair: TJSONPair;
begin
  for LPair in ASource do
    ADestination.AddPair(TJSONPair(LPair.Clone));
end;

class function TBase64.Encode(const ASource: TBytes): string;
begin
{$IFDEF HAS_NET_ENCODING}
  Result := TNetEncoding.Base64.EncodeBytesToString(ASource);
{$ELSE}
  Result := TIdEncoderMIME.EncodeBytes(TIdBytes(ASource));
{$ENDIF}
end;

class function TBase64.Encode(const ASource: TStream): string;
{$IFDEF HAS_NET_ENCODING}
var
  LBase64Stream: TStringStream;
  LEncoder: TBase64Encoding;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create;
  try
    // FIX: if CharsPerLine is not initialized, it adds \r\n line feeds to
    //      each line that are not part of Base64
    LEncoder := TBase64Encoding.Create(0);
    try
      LEncoder.Encode(ASource, LBase64Stream);
      Result := LBase64Stream.DataString;
    finally
      LEncoder.Free;
    end;
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  Result := TIdEncoderMIME.EncodeStream(ASource);
{$ENDIF}
end;

class function TBase64.Decode(const ASource: string): TBytes;
{$IFNDEF HAS_NET_ENCODING}
var
  LBytes: TIdBytes;
  LIndex: Integer;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  Result := TNetEncoding.Base64.DecodeStringToBytes(ASource);
{$ELSE}
  LBytes := TIdDecoderMIME.DecodeBytes(ASource);

  SetLength(Result, Length(LBytes));
  for LIndex := 0 to Length(LBytes) - 1 do
    Result[LIndex] := LBytes[LIndex];
{$ENDIF}
end;

class procedure TBase64.Decode(const ASource: string; ADest: TStream);
{$IFDEF HAS_NET_ENCODING}
var
  LBase64Stream: TStringStream;
{$ENDIF}
begin
{$IFDEF HAS_NET_ENCODING}
  LBase64Stream := TStringStream.Create(ASource);
  LBase64Stream.Position := soFromBeginning;
  try
    TNetEncoding.Base64.Decode(LBase64Stream, ADest);
  finally
    LBase64Stream.Free;
  end;
{$ELSE}
  TIdDecoderMIME.DecodeStream(ASource, ADest);
{$ENDIF}
end;

class function TDataSetUtils.RecordToJSONObject(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject;
var
  LField: TField;
  LPairName: string;
  LJSONValue: TJSONValue;
begin
  Result := TJSONObject.Create;

  for LField in ADataSet.Fields do
  begin
    LPairName := LField.FieldName;

    if ContainsStr(LPairName, '.') then
      Continue;

    LJSONValue := FieldToJSONValue(LField, AUseUTCDate);
    if Assigned(LJSONValue) then
      Result.AddPair(LPairName, LJSONValue);
  end;
end;

class function TDataSetUtils.RecordToJSONSchema(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONObject;
var
  LField: TField;
  LPairName: string;
  LJSONField: TJSONObject;
begin
  Result := TJSONObject.Create;

  if not Assigned(ADataSet) then
    Exit;

  if not ADataSet.Active then
    ADataSet.Open;

  for LField in ADataSet.Fields do
  begin
    LPairName := LField.FieldName;

    if LPairName.Contains('.') then
      Continue;

    LJSONField := TJSONObject.Create;
    Result.AddPair(LPairName, LJSONField);

    case LField.DataType of
      TFieldType.ftString:
      begin
        LJSONField.AddPair('type', 'string');
      end;

      TFieldType.ftSmallint,
      TFieldType.ftInteger,
      TFieldType.ftWord,
      TFieldType.ftLongWord,
      TFieldType.ftShortint,
      TFieldType.ftByte:
      begin
        LJSONField.AddPair('type', 'integer').AddPair('format', 'int32');
      end;

      TFieldType.ftBoolean:
      begin
        LJSONField.AddPair('type', 'boolean');
      end;

      TFieldType.ftFloat,
      TFieldType.ftSingle:
      begin
        LJSONField.AddPair('type', 'number').AddPair('format', 'float');
      end;

      TFieldType.ftCurrency,
      TFieldType.ftExtended:
      begin
        LJSONField.AddPair('type', 'number').AddPair('format', 'double');
      end;

      TFieldType.ftBCD:
      begin
        LJSONField.AddPair('type', 'number').AddPair('format', 'double');
      end;

      TFieldType.ftDate:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'date');
      end;

      TFieldType.ftTime:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'time');
      end;

      TFieldType.ftDateTime:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'date-time');
      end;

//      TFieldType.ftBytes: ;
//      TFieldType.ftVarBytes: ;

      TFieldType.ftAutoInc:
      begin
        LJSONField.AddPair('type', 'integer').AddPair('format', 'int32');
      end;

//      TFieldType.ftBlob: ;

      TFieldType.ftMemo,
      TFieldType.ftWideMemo:
      begin
        LJSONField.AddPair('type', 'string');
      end;

//      TFieldType.ftGraphic: ;
//      TFieldType.ftFmtMemo: ;
//      TFieldType.ftParadoxOle: ;
//      TFieldType.ftDBaseOle: ;
//      TFieldType.ftTypedBinary: ;
//      TFieldType.ftCursor: ;
      TFieldType.ftFixedChar,
      TFieldType.ftFixedWideChar,
      TFieldType.ftWideString:
      begin
        LJSONField.AddPair('type', 'string');
      end;

      TFieldType.ftLargeint:
      begin
        LJSONField.AddPair('type', 'integer').AddPair('format', 'int64');
      end;

//      TFieldType.ftADT: ;
//      TFieldType.ftArray: ;
//      TFieldType.ftReference: ;
//      TFieldType.ftDataSet: ;
//      TFieldType.ftOraBlob: ;
//      TFieldType.ftOraClob: ;

      TFieldType.ftVariant:
      begin
        LJSONField.AddPair('type', 'string');
      end;

//      TFieldType.ftInterface: ;
//      TFieldType.ftIDispatch: ;

      TFieldType.ftGuid:
      begin
        LJSONField.AddPair('type', 'string');
      end;

      TFieldType.ftTimeStamp:
      begin
        LJSONField.AddPair('type', 'string').AddPair('format', 'date-time');
      end;

      TFieldType.ftFMTBcd:
      begin
        LJSONField.AddPair('type', 'number').AddPair('format', 'double');
      end;


//      TFieldType.ftOraTimeStamp: ;
//      TFieldType.ftOraInterval: ;
//      TFieldType.ftConnection: ;
//      TFieldType.ftParams: ;
//      TFieldType.ftStream: ;
//      TFieldType.ftTimeStampOffset: ;
//      TFieldType.ftObject: ;
    end;
  end;
end;

class procedure TDataSetUtils.SetField(AField: TField; AJSON: TJSONValue; AUseUTCDate: Boolean);
begin
  case AField.DataType of
    //TFieldType.ftUnknown: ;
    TFieldType.ftString:          AField.AsString := AJSON.Value;
    TFieldType.ftSmallint:        AField.AsString := AJSON.Value;
    TFieldType.ftInteger:         AField.AsString := AJSON.Value;
    TFieldType.ftWord:            AField.AsString := AJSON.Value;
    TFieldType.ftBoolean:         AField.AsString := AJSON.Value;
    TFieldType.ftFloat:           AField.AsString := AJSON.Value;
    TFieldType.ftCurrency:        AField.AsString := AJSON.Value;
    TFieldType.ftBCD:             AField.AsString := AJSON.Value;
    TFieldType.ftDate:            AField.AsDateTime := TJSONUtils.JSONToDate(AJSON.Value);
    TFieldType.ftTime:            AField.AsDateTime := TJSONUtils.JSONToTime(AJSON.Value);
    TFieldType.ftDateTime:        AField.AsDateTime := TJSONUtils.JSONToDateTime(AJSON.Value, AUseUTCDate);
    TFieldType.ftBytes:           AField.AsBytes := TBase64.Decode(AJSON.Value);
    TFieldType.ftVarBytes:        AField.AsBytes := TBase64.Decode(AJSON.Value);
    TFieldType.ftAutoInc:         AField.AsString := AJSON.Value;
    TFieldType.ftBlob:            Base64ToBlobField(AJSON.Value, AField as TBlobField);
    TFieldType.ftMemo:            AField.AsString := AJSON.Value;
    TFieldType.ftGraphic:         (AField as TGraphicField).Value := TBase64.Decode(AJSON.Value);
    //TFieldType.ftFmtMemo: ;
    //TFieldType.ftParadoxOle: ;
    //TFieldType.ftDBaseOle: ;
    TFieldType.ftTypedBinary:     AField.AsBytes := TBase64.Decode(AJSON.Value);
    //TFieldType.ftCursor: ;
    TFieldType.ftFixedChar:       AField.AsString := AJSON.Value;
    TFieldType.ftWideString:      AField.AsString := AJSON.Value;
    TFieldType.ftLargeint:        AField.AsString := AJSON.Value;
    TFieldType.ftADT:             AField.AsBytes := TBase64.Decode(AJSON.Value);
    TFieldType.ftArray:           AField.AsBytes := TBase64.Decode(AJSON.Value);
    //TFieldType.ftReference: ;
    TFieldType.ftDataSet:         JSONToDataSet(AJSON, (AField as TDataSetField).NestedDataSet, AUseUTCDate);
    TFieldType.ftOraBlob:         Base64ToBlobField(AJSON.Value, AField as TBlobField);
    TFieldType.ftOraClob:         Base64ToBlobField(AJSON.Value, AField as TBlobField);
    TFieldType.ftVariant:         Base64ToBlobField(AJSON.Value, AField as TBlobField);
    //TFieldType.ftInterface: ;
    //TFieldType.ftIDispatch: ;
    TFieldType.ftGuid:            AField.AsString := AJSON.Value;
    TFieldType.ftTimeStamp:       AField.AsDateTime := TJSONUtils.JSONToDateTime(AJSON.Value, AUseUTCDate);
    TFieldType.ftFMTBcd:          AField.AsBytes := TBase64.Decode(AJSON.Value);
    TFieldType.ftFixedWideChar:   AField.AsString := AJSON.Value;
    TFieldType.ftWideMemo:        AField.AsString := AJSON.Value;
    TFieldType.ftOraTimeStamp:    AField.AsDateTime := TJSONUtils.JSONToDateTime(AJSON.Value, AUseUTCDate);
    TFieldType.ftOraInterval:     AField.AsString := AJSON.Value;
    TFieldType.ftLongWord:        AField.AsString := AJSON.Value;
    TFieldType.ftShortint:        AField.AsString := AJSON.Value;
    TFieldType.ftByte:            AField.AsString := AJSON.Value;
    TFieldType.ftExtended:        AField.AsString := AJSON.Value;
    //TFieldType.ftConnection: ;
    //TFieldType.ftParams: ;
    TFieldType.ftStream:          AField.AsBytes := TBase64.Decode(AJSON.Value);
    //TFieldType.ftTimeStampOffset: ;
    //TFieldType.ftObject: ;
    TFieldType.ftSingle:          AField.AsString := AJSON.Value;
  end;

end;

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; AUseUTCDate: Boolean): TJSONArray;
begin
  Result := DataSetToJSONArray(ADataSet, nil, AUseUTCDate);
end;

class function TDataSetUtils.DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean>; AUseUTCDate: Boolean): TJSONArray;
var
  LBookmark: TBookmark;
begin
  Result := TJSONArray.Create;
  if not Assigned(ADataSet) then
    Exit;

  if not ADataSet.Active then
    ADataSet.Open;

  ADataSet.DisableControls;
  try
    LBookmark := ADataSet.Bookmark;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      try
        if (not Assigned(AAcceptFunc)) or (AAcceptFunc()) then
          Result.AddElement(RecordToJSONObject(ADataSet, AUseUTCDate));
      finally
        ADataSet.Next;
      end;
    finally
      ADataSet.GotoBookmark(LBookmark);
    end;
  finally
    ADataSet.EnableControls;
  end;
end;

class function TDataSetUtils.FieldToJSONValue(const AField: TField; AUseUTCDate: Boolean): TJSONValue;
begin
  Result := nil;

  if AField.IsNull then
    Exit(TJSONNull.Create);

  case AField.DataType of
    TFieldType.ftString:          Result := TJSONString.Create(AField.AsString);
    TFieldType.ftSmallint:        Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftInteger:         Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftWord:            Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftBoolean:         Result := TJSONUtils.BooleanToTJSON(AField.AsBoolean);
    TFieldType.ftFloat:           Result := TJSONNumber.Create(AField.AsFloat);
    TFieldType.ftCurrency:        Result := TJSONNumber.Create(AField.AsCurrency);
    TFieldType.ftBCD:             Result := TJSONNumber.Create(AField.AsFloat);
    TFieldType.ftDate:            Result := TJSONUtils.DateToJSONValue(AField.AsDateTime);
    TFieldType.ftTime:            Result := TJSONUtils.TimeToJSONValue(AField.AsDateTime);
    TFieldType.ftDateTime:        Result := TJSONUtils.DateTimeToJSONValue(AField.AsDateTime, AUseUTCDate);
    TFieldType.ftBytes:           Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftVarBytes:        Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftAutoInc:         Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftBlob:            Result := TJSONString.Create(BlobFieldToBase64(AField as TBlobField));
    TFieldType.ftMemo:            Result := TJSONString.Create(AField.AsString);
    TFieldType.ftGraphic:         Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
//      TFieldType.ftFmtMemo: ;
//      TFieldType.ftParadoxOle: ;
//      TFieldType.ftDBaseOle: ;
    TFieldType.ftTypedBinary:     Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
//      TFieldType.ftCursor: ;
    TFieldType.ftFixedChar:       Result := TJSONString.Create(AField.AsString);
    TFieldType.ftWideString:      Result := TJSONString.Create(AField.AsWideString);
    TFieldType.ftLargeint:        Result := TJSONNumber.Create(AField.AsLargeInt);
    TFieldType.ftADT:             Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftArray:           Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
//      TFieldType.ftReference: ;
    TFieldType.ftDataSet:         Result := DataSetToJSONArray((AField as TDataSetField).NestedDataSet, AUseUTCDate);
    TFieldType.ftOraBlob:         Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftOraClob:         Result := TJSONString.Create(TBase64.Encode(AField.AsBytes));
    TFieldType.ftVariant:         Result := TJSONString.Create(AField.AsString);
//      TFieldType.ftInterface: ;
//      TFieldType.ftIDispatch: ;
    TFieldType.ftGuid:            Result := TJSONString.Create(AField.AsString);
    TFieldType.ftTimeStamp:       Result := TJSONUtils.DateTimeToJSONValue(AField.AsDateTime, AUseUTCDate);
    TFieldType.ftFMTBcd:          Result := TJSONNumber.Create(AField.AsFloat);
    TFieldType.ftFixedWideChar:   Result := TJSONString.Create(AField.AsString);
    TFieldType.ftWideMemo:        Result := TJSONString.Create(AField.AsString);
    TFieldType.ftOraTimeStamp:    Result := TJSONUtils.DateTimeToJSONValue(AField.AsDateTime, AUseUTCDate);
    TFieldType.ftOraInterval:     Result := TJSONString.Create(AField.AsString);
    TFieldType.ftLongWord:        Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftShortint:        Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftByte:            Result := TJSONNumber.Create(AField.AsInteger);
    TFieldType.ftExtended:        Result := TJSONNumber.Create(AField.AsFloat);
//      TFieldType.ftConnection: ;
//      TFieldType.ftParams: ;
//      TFieldType.ftStream: ;
    TFieldType.ftTimeStampOffset: Result := TJSONString.Create(AField.AsString);
//      TFieldType.ftObject: ;
    TFieldType.ftSingle:          Result := TJSONNumber.Create(AField.AsFloat);
  end;
end;

class procedure TDataSetUtils.JSONObjectToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean);
var
  LJSONArray: TJSONArray;
begin
  if AJSONValue is TJSONObject then
  begin
    LJSONArray := TJSONArray.Create;
    try
      LJSONArray.AddElement(AJSONValue.Clone as TJSONValue);
      JSONToDataSet(LJSONArray, ADataSet, AUseUTCDate);
    finally
      LJSONArray.Free;
    end;
  end;
end;

class procedure TDataSetUtils.JSONToCurrentRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AUseUTCDate: Boolean);
var
  LJSONField: TJSONValue;
  LIndex: Integer;
  LField: TField;
begin
  ADataSet.Edit;

  for LIndex := 0 to ADataSet.Fields.Count - 1 do
  begin
    LField := ADataSet.Fields[LIndex];

    if LField.ReadOnly or not LField.CanModify then
      Continue;

    LJSONField := AJSONObject.GetValue(LField.FieldName);
    if not Assigned(LJSONField) then
      Continue;

    if LJSONField is TJSONNull then
    begin
      LField.Clear;
      Continue;
    end;

    SetField(LField, LJSONField, AUseUTCDate);
  end;

  try
    ADataSet.Post;
  except
    ADataSet.Cancel;
    raise;
  end;
end;

class procedure TDataSetUtils.JSONToDataSet(AJSONValue: TJSONValue; ADataSet: TDataSet; AUseUTCDate: Boolean);
var
  LJSONArray: TJSONArray;
  LJSONItem: TJSONObject;
  LIndex: Integer;
begin
  if not (AJSONValue is TJSONArray) then
    raise ENeonException.Create(SNeonErrorDataSetJSONNotArray);

  LJSONArray := AJSONValue as TJSONArray;

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex] as TJSONObject;

    JSONToRecord(LJSONItem, ADataSet, AUseUTCDate);
  end;
end;

class procedure TDataSetUtils.JSONToRecord(AJSONObject: TJSONObject; ADataSet: TDataSet; AUseUTCDate: Boolean);
var
  LJSONField: TJSONValue;
  LIndex: Integer;
  LField: TField;
begin
  ADataSet.Append;

  for LIndex := 0 to ADataSet.Fields.Count - 1 do
  begin
    LField := ADataSet.Fields[LIndex];

    if LField.ReadOnly or not LField.CanModify then
      Continue;

    LJSONField := AJSONObject.GetValue(LField.FieldName);
    if not Assigned(LJSONField) then
      Continue;

    if LJSONField is TJSONNull then
    begin
      LField.Clear;
      Continue;
    end;

    SetField(LField, LJSONField, AUseUTCDate);
  end;

  try
    ADataSet.Post;
  except
    ADataSet.Cancel;
    raise;
  end;
end;

class procedure TDataSetUtils.Base64ToBlobField(const ABase64: string; ABlobField: TBlobField);
var
  LBinaryStream: TMemoryStream;
begin
  LBinaryStream := TMemoryStream.Create;
  try
    TBase64.Decode(ABase64, LBinaryStream);
    ABlobField.LoadFromStream(LBinaryStream);
  finally
    LBinaryStream.Free;
  end;
end;

class function TDataSetUtils.BlobFieldToBase64(ABlobField: TBlobField): string;
var
  LBlobStream: TMemoryStream;
begin
  LBlobStream := TMemoryStream.Create;
  try
    ABlobField.SaveToStream(LBlobStream);
    LBlobStream.Position := soFromBeginning;
    Result := TBase64.Encode(LBlobStream);
  finally
    LBlobStream.Free;
  end;
end;

{ TNeonLogger }

class procedure TNeonLogger.Console(const AMessage: string);
begin
  WriteLn(AMessage);
end;

class procedure TNeonLogger.ConsoleWatch(const AMessage: string; var AWatch: TStopWatch);
begin
  AWatch.Stop;
  WriteLn(AMessage + ' - msec: ' + AWatch.ElapsedMilliseconds.ToString);
end;

class procedure TNeonLogger.Debug(const AMessage: string);
begin
  {$IFDEF MSWINDOWS}
  OutputDebugString(PChar(AMessage));
  {$ENDIF}
end;

class procedure TNeonLogger.DebugWatch(const AMessage: string; var AWatch: TStopwatch);
begin
  AWatch.Stop;
  {$IFDEF MSWINDOWS}
  OutputDebugString(PChar(AMessage + ' - msec: ' + AWatch.ElapsedMilliseconds.ToString));
  {$ENDIF}
end;

class procedure TNeonLogger.ProfileReset;
begin
  if not Assigned(FProfileData) then
    FProfileData := TDictionary<string, TPair<Int64, Int64>>.Create
  else
    FProfileData.Clear;
end;

class function TNeonLogger.ProfileBegin: Int64;
begin
  if FProfileEnabled then
    Result := TStopwatch.GetTimeStamp
  else
    Result := 0;
end;

class procedure TNeonLogger.ProfileEnd(const ASection: string; AStartStamp: Int64);
var
  LElapsed: Int64;
  LEntry: TPair<Int64, Int64>;
begin
  if not FProfileEnabled then
    Exit;

  LElapsed := TStopwatch.GetTimeStamp - AStartStamp;

  if not Assigned(FProfileData) then
    FProfileData := TDictionary<string, TPair<Int64, Int64>>.Create;

  if FProfileData.TryGetValue(ASection, LEntry) then
    FProfileData[ASection] := TPair<Int64, Int64>.Create(LEntry.Key + LElapsed, LEntry.Value + 1)
  else
    FProfileData.Add(ASection, TPair<Int64, Int64>.Create(LElapsed, 1));
end;

class function TNeonLogger.ProfileReport: string;
type
  TSectionStat = TPair<string, TPair<Int64, Int64>>;
var
  LStats: TList<TSectionStat>;
  LStat: TSectionStat;
  LPair: TPair<string, TPair<Int64, Int64>>;
  LFreq: Int64;
  LTotalMs, LGrandTotalMs: Double;
  LSB: TStringBuilder;
begin
  if not Assigned(FProfileData) or (FProfileData.Count = 0) then
    Exit('(no profiling data - TNeonLogger.ProfileEnabled was False during the run)');

  LFreq := TStopwatch.Frequency;
  LStats := TList<TSectionStat>.Create;
  try
    for LPair in FProfileData do
      LStats.Add(LPair);

    LStats.Sort(TComparer<TSectionStat>.Construct(
      function(const L, R: TSectionStat): Integer
      begin
        Result := TComparer<Int64>.Default.Compare(R.Value.Key, L.Value.Key);
      end));

    LGrandTotalMs := 0;
    for LStat in LStats do
      LGrandTotalMs := LGrandTotalMs + (LStat.Value.Key / LFreq) * 1000;

    LSB := TStringBuilder.Create;
    try
      LSB.AppendLine(Format('  %-26s %10s %14s %12s %9s',
        ['Section', 'Calls', 'Total (ms)', 'Avg (us)', '% ']));
      LSB.Append('  ').AppendLine(StringOfChar('-', 74));
      for LStat in LStats do
      begin
        LTotalMs := (LStat.Value.Key / LFreq) * 1000;
        LSB.AppendLine(Format('  %-26s %10d %14.3f %12.3f %7.1f%%',
          [LStat.Key, LStat.Value.Value, LTotalMs, (LTotalMs * 1000) / LStat.Value.Value,
           IfThen(LGrandTotalMs > 0, LTotalMs / LGrandTotalMs * 100, 0)]));
      end;
      Result := LSB.ToString;
    finally
      LSB.Free;
    end;
  finally
    LStats.Free;
  end;
end;

initialization

finalization
  FreeAndNil(TNeonLogger.FProfileData);

end.
