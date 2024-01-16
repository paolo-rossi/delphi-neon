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
unit Neon.Core.Attributes;

{$I Neon.inc}

interface

{$SCOPEDENUMS ON}

uses
  System.Classes, System.SysUtils, System.Rtti,
  Neon.Core.Types;

type
  NeonAttribute = class(TCustomAttribute)
  end;

  NeonNamedAttribute = class(NeonAttribute)
  private
    FValue: string;
  public
    constructor Create(const AValue: string);
    property Value: string read FValue write FValue;
  end;

  /// <summary>
  ///   The attribute [NeonProperty] is used to indicate the property name in JSON.
  /// </summary>
  /// <remarks>
  ///   Read + Write Attribute
  /// </remarks>
  NeonPropertyAttribute = class(NeonNamedAttribute);

  /// <summary>
  ///   The attribute [NeonEnum] is used to indicate the names of an enum
  /// </summary>
  /// <remarks>
  ///   Read + Write Attribute
  /// </remarks>
  NeonEnumNamesAttribute = class(TCustomAttribute)
  private
    FNames: TArray<string>;
  public
    constructor Create(const ANames: string);
    property Names: TArray<string> read FNames write FNames;
  end;

  /// <summary>
  ///   The Neon attribute [NeonIgnore] is used to tell Neon to ignore a certain property (field)
  ///   of a Delphi object. The property is ignored both when reading JSON into Delphi objects, and
  ///   when writing Delphi objects into JSON.
  /// </summary>
  /// <remarks>
  ///   Read + Write Attribute
  /// </remarks>
  NeonIgnoreAttribute = class(NeonAttribute);

  /// <summary>
  ///   The Neon attribute [NeonUnwrapped] is a property/field annotation used to
  ///   define that value should be "unwrapped" when serialized (and
  ///   wrapped again when deserializing), resulting in flattening of data structure,
  ///   compared to PODO structure.
  /// </summary>
  /// <remarks>
  ///   Must be applied only to class/record's properties/fields
  /// </remarks>
  NeonUnwrappedAttribute = class(NeonAttribute);

  /// <summary>
  ///   The Neon annotation NeonInclude tells Neon to include the property (or field)
  ///   based on the value
  /// </summary>
  /// <remarks>
  ///   Write Attribute
  /// </remarks>
  IncludeIf = (
    /// <summary>
    ///   Include the member if it's not nil
    /// </summary>
    NotNull,
    /// <summary>
    ///   Include the member if the value it's not empty
    /// </summary>
    NotEmpty,
    /// <summary>
    ///   Include the member if it's value it's not the default value
    /// </summary>
    NotDefault,
    /// <summary>
    ///   Include the member always
    /// </summary>
    Always,
    /// <summary>
    ///   Include the member based on the result of the function specified as string
    ///   (default function is ShouldInclude)
    /// </summary>
    CustomFunction);
  TIncludeValue = record
    Present: Boolean;
    Value: IncludeIf;
    IncludeFunction: string;
  end;

  /// <summary>
  ///   The Neon annotation NeonInclude tells Neon to include the property (or field)
  ///   based on the value of the enumeration Include
  /// </summary>
  NeonIncludeAttribute = class(TCustomAttribute)
  private
    FIncludeValue: TIncludeValue;
  public
    constructor Create(AIncludeValue: IncludeIf = IncludeIf.Always; const AIncludeFunction: string = 'ShouldInclude');

    property IncludeValue: TIncludeValue read FIncludeValue write FIncludeValue;
  end;

  /// <summary>
  ///   The Neon annotation NeonFormat tells Neon to output the property (or field)
  ///   in the specified format
  /// </summary>
  /// <remarks>
  ///   Currently Base64 is supported for TBytes through a CustomSerializer
  /// </remarks>
  NeonFormat = (Native, Base64);
  NeonFormatAttribute = class(NeonAttribute)
  private
    FFormatValue: NeonFormat;
  public
    constructor Create(AOutputValue: NeonFormat = NeonFormat.Native);
    property FormatValue: NeonFormat read FFormatValue write FFormatValue;
  end;

  /// <summary>
  ///   The NeonIgnoreProperties Neon annotation is used to specify a list of properties
  ///   of a class to ignore. The NeonIgnoreProperties annotation is placed above the
  ///   class declaration instead of above the individual properties (fields) to ignore.
  /// </summary>
  /// <remarks>
  ///   Read + Write Attribute
  /// </remarks>
  NeonIgnorePropertiesAttribute = class(NeonAttribute);

  /// <summary>
  ///   The NeonIgnoreType Neon annotation is used to mark a whole type (class) to be
  ///   ignored everywhere that type is used.
  /// </summary>
  /// <remarks>
  ///   Read + Write Attribute
  /// </remarks>
  NeonIgnoreTypeAttribute = class(NeonAttribute);

  /// <summary>
  ///   The Neon attribute NeonMembers is used to tell Neon to change the Members
  ///   when reading/writing a specific record/object
  /// </summary>
  /// <remarks>
  ///   Read + Write Attribute
  /// </remarks>
  NeonMembersSetAttribute = class(NeonAttribute)
  private
    FValue: TNeonMembersSet;
  public
    constructor Create(const AValue: TNeonMembersSet);
    property Value: TNeonMembersSet read FValue write FValue;
  end;

  /// <summary>
  ///   The Neon attribute NeonVisibilityAttribute is used to tell Neon to change the Visibility
  ///   when reading/writing a specific record/object
  /// </summary>
  /// <remarks>
  ///   Read + Write Attribute
  /// </remarks>
  NeonVisibilityAttribute = class(NeonAttribute)
  private
    FValue: TNeonVisibility;
  public
    constructor Create(const AValue: TNeonVisibility);
    property Value: TNeonVisibility read FValue write FValue;
  end;

  /// <summary>
  ///   The NeonSerialize Neon annotation is used to specify a custom serializer for a
  ///   field in a Delphi object.
  /// </summary>
  NeonSerializeAttribute = class(NeonAttribute)
  private
    FClazz: TClass;
    FName: string;
  public
    constructor Create(const AClass: TClass); overload;
    constructor Create(const AName: string); overload;
    property Clazz: TClass read FClazz write FClazz;
    property Name: string read FName write FName;
  end;

  /// <summary>
  ///   The Neon annotation NeonDeserialize is used to specify a custom de-serializer
  ///   class for a given field in a Delphi object.
  /// </summary>
  NeonDeserializeAttribute = class(NeonSerializeAttribute);

  NeonItemFactoryAttribute = class(NeonAttribute)
  private
    FFactoryClass: TClass;
  public
    constructor Create(const AClass: TClass); overload;
    property FactoryClass: TClass read FFactoryClass write FFactoryClass;
  end;

  /// <summary>
  ///   The Neon annotation NeonValue tells Neon that Neon should not attempt to
  ///   serialize the object itself, but rather call a method on the object which
  ///   serializes the object to a TJSONValue.
  /// </summary>
  NeonValueAttribute = class(NeonAttribute);
  NeonMethodAttribute = class(NeonAttribute);
  NeonSerializerMethodAttribute = class(NeonAttribute);

  /// <summary>
  ///   The NeonRawValue annotation tells Neon that this property value should written
  ///   directly as it is to the JSON output. If the property is a String Neon would
  ///   normally have enclosed the value in quotation marks, but if annotated with the
  ///   NeonRawValue property Neon won't do that.
  /// </summary>
  NeonRawValueAttribute = class(NeonAttribute);


  /// <summary>
  ///   The NeonAutoCreate tells Neon to create an object if it's nil. The
  ///   class must have at least one parameterless Create constructor.
  /// </summary>
  NeonAutoCreateAttribute = class(NeonAttribute);

  {
  //Read Annotations
  NeonSetterAttribute = class(NeonAttribute);
  NeonAnySetterAttribute = class(NeonAttribute);
  NeonCreatorAttribute = class(NeonAttribute);
  NeonInjectAttribute = class(NeonAttribute);
  //Write Annotations
  NeonGetterAttribute = class(NeonAttribute);
  NeonAnyGetterAttribute = class(NeonAttribute);
  }

implementation

uses
  System.StrUtils, System.DateUtils;

{ NeonNamedAttribute }

constructor NeonNamedAttribute.Create(const AValue: string);
begin
  FValue := AValue;
end;

{ NeonMembersTypeAttribute }

constructor NeonMembersSetAttribute.Create(const AValue: TNeonMembersSet);
begin
  FValue := AValue;
end;

{ NeonVisibilityAttribute }

constructor NeonVisibilityAttribute.Create(const AValue: TNeonVisibility);
begin
  FValue := AValue;
end;

constructor NeonSerializeAttribute.Create(const AClass: TClass);
begin
  FClazz := AClass;
end;

constructor NeonSerializeAttribute.Create(const AName: string);
begin
  FName := AName;
end;

{ NeonIncludeAttribute }

constructor NeonIncludeAttribute.Create(AIncludeValue: IncludeIf; const AIncludeFunction: string);
begin
  FIncludeValue.Present := True;
  FIncludeValue.Value := AIncludeValue;
  FIncludeValue.IncludeFunction := AIncludeFunction;
end;

{ NeonEnumNamesAttribute }

constructor NeonEnumNamesAttribute.Create(const ANames: string);
begin
  FNames := ANames.Split([',']);
end;

{ NeonFormatAttribute }

constructor NeonFormatAttribute.Create(AOutputValue: NeonFormat);
begin
  FFormatValue := AOutputValue;
end;

{ NeonItemFactoryAttribute }

constructor NeonItemFactoryAttribute.Create(const AClass: TClass);
begin
  FFactoryClass := AClass;
end;

end.
