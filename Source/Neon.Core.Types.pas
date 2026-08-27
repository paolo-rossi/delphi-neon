{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
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

  /// <summary>
  ///   Which of the structural shapes in Neon.Core.DynamicTypes a class matches:
  ///   the outcome of the IDynamicMap / IDynamicList / IDynamicStream probes,
  ///   or Plain for a class that is none of them and is written member by
  ///   member. Undetermined means "not probed yet"
  /// </summary>
  /// <remarks>
  ///   A property of the class, not of the instance - the probes only look at
  ///   methods and properties - which is what lets the engine resolve it once
  ///   per class and cache it
  /// </remarks>
  TNeonDynamicKind = (Undetermined, Plain, Map, List, Stream);

  TNeonIgnoreIfContext = record
  public
    MemberName: string;
    Operation: TNeonOperation;
    constructor Create(const AMemberName: string; AOperation: TNeonOperation);
  end;

  TNeonIgnoreCallback = function(const AContext: TNeonIgnoreIfContext): Boolean of object;
  TCaseFunc = reference to function (const AString: string): string;

  /// <summary>
  ///   Handler for the messages Neon logs while (de)serializing, set with
  ///   INeonConfiguration.SetOnError
  /// </summary>
  /// <remarks>
  ///   With RaiseExceptions off (the default) a member that fails is logged and
  ///   skipped: for a caller of the TNeon facade - which frees the serializer,
  ///   and its error list with it, before returning - this handler is the only
  ///   way to learn that it happened. It is called on the thread doing the work
  ///   and must not raise: it runs inside the except block that handled the
  ///   original error, and an exception from it would replace that error
  /// </remarks>
  TNeonErrorCallback = reference to procedure (const AMessage: string; AOperation: TNeonOperation);

resourcestring
  { Catalog of every message Neon raises or logs, so the whole library can
    be localized (e.g. with a translated resource DLL) without recompiling. }
  SNeonErrorParse = 'Error parsing JSON string';
  SNeonErrorRawValueF1 = 'NeonRawValue: the member does not contain valid JSON [%s]';
  SNeonErrorNumExpected = 'Invalid JSON value. Number expected';
  SNeonErrorBoolExpected = 'Invalid JSON value. Boolean expected';
  SNeonErrorDateInvalidF1 = 'Invalid JSON date value [%s]';
  SNeonErrorTimeInvalidF1 = 'Invalid JSON time value [%s]';
  SNeonErrorDateTimeInvalidF1 = 'Invalid JSON date/time value [%s]';
  SNeonErrorArrExpected = 'Set deserialization: Expected JSON Array';
  SNeonErrorDictKeyInvalid = 'Dictionary [Key]: type not supported';
  SNeonErrorVariantNotScalarF1 = 'Variant deserialization: the JSON %s is not a scalar value';
  SNeonErrorVariantArray = 'Variant serialization: variant arrays are not supported';
  SNeonErrorFieldProp = 'Member type must be Field or Property';
  SNeonErrorEnumInvalid = 'Invalid enum value';
  SNeonErrorEnumNames = 'No correspondence with enum names';
  SNeonErrorEnumValueF1 = 'Enum value [%d] out of bound';
  SNeonErrorEmptyType = 'Empty RttiType in JSONToValue';
  SNeonErrorRangeOutF2 = 'The value [%s] is outside the range for the type [%s]';
  SNeonErrorNoMethodF2 = 'NeonInclude Method name [%s] not found in class [%s]';
  SNeonErrorAccessorNoNameF1 = '%s: no member name, expected name=<member>';
  SNeonErrorAccessorNotFoundF3 = '%s: member [%s] not found in type [%s]';
  SNeonErrorAccessorTypeF4 = '%s: member [%s] must be of type [%s], but it is [%s]';
  SNeonErrorAccessorNotReadableF2 = '%s: member [%s] cannot be read';
  SNeonErrorAccessorNotWritableF2 = '%s: member [%s] cannot be written';
  SNeonErrorAccessorMethodClassF2 = '%s: method [%s] can only be used on a member of a class';
  SNeonErrorMemberF3 = 'Error processing member [%s] of type [%s]: %s';
  SNeonErrorSerializeTypeF2 = 'Error serializing the type [%s]: %s';
  SNeonErrorTagTargetInvalid = 'You can apply tag values only to records or objects';
  SNeonErrorTagParseF1 = 'Error decoding tag: [%s]';
  SNeonErrorTagKeyUnknownF2 = 'Unknown tag key: [%s] for attribute [%s]';

  SNeonErrorPropertyNotFoundF1 = 'Property [%s] not found';
  SNeonErrorMethodNotFoundF1 = 'Method [%s] not found';
  SNeonErrorNullableNoRtti = 'Nullable contains type with no RTTI';
  SNeonErrorNullableNoValue = 'Nullable type has no value';
  SNeonErrorAnyOfWrongTypeF1 = 'TAnyOf does not currently hold a value of type [%s]';
  SNeonErrorAnyOfTypeMismatchF3 = 'TAnyOf: a value of type [%s] matches neither of the declared types [%s] and [%s]';
  SNeonErrorAnyOfValidateF4 = 'TAnyOf<%s, %s>: attempting to get [%s] when [%s] is set';
  SNeonErrorAnyOfNotAnAnyOfF1 = 'TAnyOf: the type [%s] is not a TAnyOf';
  SNeonErrorAnyOfNoTarget = 'TAnyOf: no target value to read into, so which TAnyOf is being read cannot be told';
  SNeonErrorAnyOfNoBranchF3 = 'TAnyOf: a JSON %s fits neither of the declared types [%s] and [%s]';
  SNeonErrorUnknownGenericType = 'TTypeConfigurator: Unknown type T';
  SNeonErrorDeserializeIncompatible = '.Deserialize: incompatible types';
  SNeonErrorDeserializeNilF1 = 'Deserialization skipped: instance of [%s] is nil and could not be created';
  SNeonErrorInterfaceNoFactoryF1 = 'Deserialization skipped: the interface [%s] has no instance to read into and no [NeonFactory] to build one';
  SNeonErrorInterfaceNoGuidF1 = 'Interface deserialization: the interface [%s] has no GUID, so no object can be asked for it';
  SNeonErrorInterfaceNotImplF2 = 'Interface deserialization: the factory built a [%s], which does not implement [%s]';
  SNeonErrorStreamableNoValue = 'Streamable deserialization: the JSON object has no $value member';
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
  SNeonErrorSchemaKeywordUnsupportedF1 = 'Unsupported keyword [%s]: refusing to validate (keyword not implemented)';
  SNeonErrorSchemaDuplicateAnchorF1 = 'Duplicate $anchor [%s] in the same document';

  SNeonErrorGenNoDocument = 'Entity generator: no JSON document, call Parse first';
  SNeonErrorGenNoSample = 'Entity generator: the JSON sample is empty';
  SNeonWarnGenConflictF2 = 'Position [%s] holds incompatible JSON types: generated as [%s]';
  SNeonWarnGenNoTypeF2 = 'Position [%s] is always null: generated as [%s]';
  SNeonWarnGenEmptyArrayF2 = 'Array [%s] is always empty: items generated as [%s]';
  SNeonWarnGenRootNotEntity = 'The root of the document is not an object (or an array of objects): no entity generated for it';

implementation

{ TNeonIgnoreIfContext }

constructor TNeonIgnoreIfContext.Create(const AMemberName: string; AOperation: TNeonOperation);
begin
  MemberName := AMemberName;
  Operation := AOperation;
end;

end.
