# Neon - JSON Serialization Library for Delphi

<br />

<p align="center">
  <a href="http://blog.paolorossi.net/">
    <img src="https://user-images.githubusercontent.com/4686497/54478586-175c9500-4814-11e9-98c3-09b9aca9ad66.png" alt="Neon Library" width="400" />
  </a>
</p>


## What is Neon

![Top language](https://img.shields.io/github/languages/top/paolo-rossi/delphi-neon)
[![GitHub release](https://img.shields.io/github/release/paolo-rossi/delphi-neon)](https://github.com/paolo-rossi/delphi-neon/release)
[![GitHub issues](https://img.shields.io/github/issues/paolo-rossi/delphi-neon)](https://github.com/paolo-rossi/delphi-neon/issues)
[![GitHub PR](https://img.shields.io/github/issues-pr/paolo-rossi/delphi-neon)](https://github.com/paolo-rossi/delphi-neon/pulls)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/paolo-rossi/delphi-neon)
![GitHub last commit](https://img.shields.io/github/last-commit/paolo-rossi/delphi-neon)
![GitHub contributors](https://img.shields.io/github/contributors-anon/paolo-rossi/delphi-neon)
[![GitHub license](https://img.shields.io/github/license/paolo-rossi/delphi-neon)](https://github.com/paolo-rossi/delphi-neon/blob/master/LICENSE)

**Neon** is a serialization library for [Delphi](https://www.embarcadero.com/products/delphi) that helps you to convert (back and forth) objects and other values to JSON. It supports simple Delphi types but also complex class and records. **Neon** has been designed with **REST** in mind, to exchange pure data between applications with no *"metadata"* or added fields, in fact **Neon** is the default JSON serialization engine for the [WiRL REST Library](https://github.com/delphi-blocks/WiRL).

Please take a look at the Demos to see **Neon** in action.

### Neon Main Demo
This is the main demo where you can see how you can serialize/deserialize simple types, records, classes, Delphi specific types (TStringList, TDataSet, etc...):

![Neon Mega Demo](https://user-images.githubusercontent.com/4686497/103461978-64c83000-4d22-11eb-85c5-1a829b4ec0c0.png)

### Neon Benchmarks Demo
This new demo tries to compare the standard TJSON serialization engine with the TNeon engine, with a few changes you can compare TNeon with other serialization engines out there:

![Neon Benchmarks Demo](https://user-images.githubusercontent.com/4686497/216270908-0a702077-02fe-4295-bce5-8da78ee46599.png)

### Console Demos
Four console applications (grouped in `Demos/Source/ConsoleDemos.groupproj`), two for measuring **Neon** without a UI in the way and two for the code it generates from (and for) a JSON document:

- **BenchmarksConsole** compares **Neon** against `REST.Json` and `System.JSON.Serializers` (`TJsonSerializer`) on the same datasets, with a separate source object per library. It prints a summary table, writes the report to disk and saves one pretty-printed JSON sample per library so the output can be diffed for correctness, not just timed
- **ProfilingConsole** breaks **Neon**'s own work down by internal stage (RTTI resolve, member preparation, object/enumerable/map/record writing, the dynamic-type probes...) using the `TNeonLogger` profiler. It runs three scenarios — one flat object per call, many flat objects per call and many composite objects per call — to show what the per-type caches do and do not amortize
- **Classify** turns a JSON document into the Delphi entities that hold it, from the command line (see the [Entity Generator](#entity-generator) below, and the demo's own [README](Demos/Source/Classify/README.md))
- **SchemaConsole** generates a **JSON Schema Draft 2020-12** document from a Delphi type and then validates JSON against it: a serialized object, a document from elsewhere (every violation reported with a JSON Pointer and the keyword that rejected it), a self-referencing type resolved through `$defs`/`$ref`, and a schema written by hand using keywords no Delphi type can express (see the demo's own [README](Demos/Source/SchemaConsole/README.md))

### A Neon Introduction by Holger Flick (Video)
[![Modern Delphi web development #7](https://img.youtube.com/vi/djzfeS9k4KU/0.jpg)](https://www.youtube.com/watch?v=djzfeS9k4KU)

## General Features

### Configuration

Extensive configuration through `INeonConfiguration` interface:
- Word case (Unchanged, UPPERCASE, lowercase, PascalCase, camelCase, snake_case, kebab-case, SCREAMING_SNAKE_CASE)
- CuStOM CAse (through anonymous method)
- Member types (Fields, Properties)
- Option to ignore the "F" prefix of private/protected fields, if you choose to serialize the fields (see the note below: it removes the first letter of *any* such field starting with an F)
- Member visibility (private, protected, public, published)
- Custom serializer registration
- Use UTC date in serialization
- Auto creation of nil (object) members
- Map/dictionary key sort order (natural, reverse, alphabetical, reverse-alphabetical)

> [!NOTE]
> **A run of capitals counts as one word.** `snake_case`, `kebab-case` and `SCREAMING_SNAKE_CASE` split a member name before a capital that starts a new capitalized word, so an acronym is never split:
>
> | Delphi member | camelCase | snake_case | kebab-case |
> | --- | --- | --- | --- |
> | `FirstName` | `firstName` | `first_name` | `first-name` |
> | `HTTPResponse` | `hTTPResponse` | `httpresponse` | `httpresponse` |
> | `IPAddress` | `iPAddress` | `ipaddress` | `ipaddress` |
> | `MyURLValue` | `myURLValue` | `my_urlvalue` | `my-urlvalue` |
> | `UserID` | `userID` | `user_id` | `user-id` |
> | `ValueX` | `valueX` | `valuex` | `valuex` |
>
> A trailing run of two or more capitals splits (`UserID` → `user_id`), a single trailing capital does not (`ValueX` → `valuex`), and `camelCase` only lowercases the first character.
>
> Inside Neon this is symmetric — the JSON name of a member is computed the same way when writing and when reading, so a Neon-to-Neon round trip matches. It is interop that breaks: a producer that spells the same field `http_response` will not match `httpresponse`. Give the member the name the document uses, which wins over the case conversion:
>
> ```delphi
> [NeonProperty('http_response')]
> property HTTPResponse: string read FHTTPResponse write FHTTPResponse;
> ```
>
> Two more consequences: names that differ only in the capitalization of a run (`ID` and `Id`) converge on the same JSON name, and Neon does not check for collisions; and `TCaseAlgorithm.SnakeToPascal`/`KebabToPascal` are not exact inverses of the conversions above, since the capitalization of a run cannot be recovered (`user_id` comes back as `UserId`, not `UserID`).

> [!NOTE]
> **`IgnoreFieldPrefix` is a convention, not a heuristic.** With it on, Neon removes the *first character* of every private or protected field whose name starts with an `F` — or an `f` — without checking what follows it, so a field that does not follow the `FSomething` convention loses its first letter:
>
> | Field | Visibility | Prefix off | Prefix on |
> | --- | --- | --- | --- |
> | `FFirstName` | private | `FFirstName` | `FirstName` |
> | `firstName` | private | `firstName` | `irstName` |
> | `Formula` | private | `Formula` | `ormula` |
> | `Total` | private | `Total` | `Total` |
> | `FCode` | protected | `FCode` | `Code` |
> | `FPublicField` | public | `FPublicField` | `FPublicField` |
>
> It applies to fields only — a *property* named `FirstName` keeps its name — and only when fields are serialized at all (see the member types setting). It is off by default, but **`TNeonConfiguration.Snake` and `.ScreamingSnake` turn it on**, so `Formula` is published as `ormula` there without anyone asking for it. As always, `[NeonProperty('formula')]` overrides the computed name for a single member.

### Delphi Types Support

Neon supports the (de)serialization of most Delphi standard types, records, array and of course classes. Classes can be complex as you want them to be, can contain array, (generic) lists, sub-classes, record, etc...


#### Simple values
- Basic types: **string, Integer, Double, Boolean, TDateTime**

#### Complex values
- **Dynamic Arrays** of (basic types, records, classes, etc...)
- **Records** with fields of (basic types, records, classes, arrays, etc...)
- **Classes** with fields of (basic types, records, classes, arrays, etc...)
- **Generic lists**
- **Dictionaries** (key must be of type string)
- **Streamable classes**

#### Custom Serializers
- Inherit from `TCustomSerializer` and register the new serializer class in the configuration

Neon ships with serializers for a number of RTL / FireDAC / VCL types — `TGUID`, `TBytes`, `TStream`, `TJSONValue`, `TCollection` (`Neon.Core.Serializers.RTL`), `TDataSet` (`.DB`), `TImage` (`.VCL`) and `Nullable<T>` (`.Nullables`).

> [!IMPORTANT]
> **None of them is registered for you.** `TNeonConfiguration.Default` — and `Create`, `.Camel`, `.Snake`, `.Kebab`, `.Pretty`, `.ScreamingSnake` — starts with an *empty* serializer registry. A type whose serializer is not registered falls back to the generic RTTI handling, which is rarely what you want:
>
> | Member | Fresh configuration | With its serializer registered |
> | --- | --- | --- |
> | `TGUID` | `{"D1":3298963421,"D2":17471,"D3":18231}` | `"C4A22FDD-443F-4737-AA7D-2323F635E207"` |
> | `TCollection` | `{"Capacity":4,"Count":1,"IsEmpty":false}` — the items are lost | `[{"Name":"first","ID":0}]` |
> | `TJSONValue` | `{"Count":1,"IsEmpty":false,"Null":false,"Owned":true}` | `{"key":"value"}` |
> | `TBytes` | `[104,101,108,108,111]` | `"aGVsbG8="` |
> | `TDataSet` | not the rows: the engine falls back to walking the dataset object itself, and a `TFDMemTable` member access-violates outright | `[{"Name":"Paolo","Age":42}]` |
>
> `TStream` and `Nullable<T>` are the two exceptions: the engine recognizes them structurally, so they are written as Base64 and as their inner value whether or not their serializers are registered.

Register what you need through the **configuration**:

```delphi
uses
  Neon.Core.Serializers.RTL,
  Neon.Core.Serializers.DB,        // needs Data.DB
  Neon.Core.Serializers.VCL,       // needs Vcl.ExtCtrls
  Neon.Core.Serializers.Nullables;

LConfig := TNeonConfiguration.Default
  .RegisterSerializer(TGUIDSerializer)
  .RegisterSerializer(TBytesSerializer)
  .RegisterSerializer(TStreamSerializer)
  .RegisterSerializer(TJSONValueSerializer)
  .RegisterSerializer(TCollectionSerializer)
  .RegisterSerializer(TDataSetSerializer)
  .RegisterSerializer(TImageSerializer);

RegisterNullableSerializers(LConfig.GetSerializers);
```

> [!WARNING]
> `INeonConfiguration.RegisterSerializer` is the registration path to use: it is the one that runs the serializer's `ChangeConfig` hook. The `RegisterDefaultSerializers` helpers in `Neon.Core.Serializers.RTL` / `.DB` add classes straight to the registry and skip that hook — with `TCollectionSerializer` that leaves the `TCollectionItem.Collection` back-reference in play, and serializing a `TCollection` recurses until the stack gives out. (The two `RegisterDefaultSerializers` are also different procedures sharing a name: qualify them with the unit name when both units are in the `uses` clause.)

A configuration is worth keeping around rather than rebuilding per call — it owns the RTTI caches as well as the registry.

#### Writing a custom serializer

A serializer is a class inheriting from `TCustomSerializer`, with four members to override and two optional hooks:

| Member | Role |
| --- | --- |
| `GetTargetInfo` | the `PTypeInfo` of the type the serializer is written for |
| `CanHandle` | whether this serializer claims a given type — `TypeInfoIs(AType)` claims the target class and its descendants, and the most derived registered serializer wins |
| `Serialize` | returns the JSON to write for a value, or `nil` to write nothing at all (which is how the `IncludeIf` policies are honoured) |
| `Deserialize` | returns the value the target must be set to |
| `NeedsInstance` *(optional)* | whether `Deserialize` needs an instance to read into — see below |
| `SerializeSchema` *(optional)* | the JSON Schema describing what `Serialize` writes; returning `nil` (the default) lets the schema generator infer the shape from the RTTI of the type instead |

##### Who builds the instance to read into

Serializing is the easy direction: the value exists, and `Serialize` is handed it. Deserializing a **class-typed** member is not, because something has to create the object before the JSON can be read into it. Neon tries, in this order:

1. a `[NeonFactory]` on the member or on its type, if there is one;
2. `AutoCreate` (`SetAutoCreate(True)`) or `[NeonAutoCreate]` on the member — which builds the instance through the first parameterless constructor RTTI finds for the class;
3. nothing.

Case 3 is the common one: **`AutoCreate` is off by default**, so a class member that starts out `nil` and carries no attribute simply has no instance. `Deserialize` is then not called at all — the member is skipped and the reason logged:

```
Deserialization skipped: instance of [TMoney] is nil and could not be created
```

That is the right default: a serializer written to fill in the object it is given would dereference `nil`. But it is wrong for a serializer that does not need the object in the first place, because it *constructs* the value it returns. Such a serializer says so by overriding `NeedsInstance`:

```delphi
class function TMoneySerializer.NeedsInstance: Boolean;
begin
  Result := False;
end;
```

It is then called even with nothing to read into, and whatever `TValue` it returns is assigned to the member.

> [!NOTE]
> `NeedsInstance` only affects **class-typed** targets. Records, and every simple type, have nothing to construct: their serializers are always called.

##### An example: a class Neon cannot construct meaningfully

`TMoney` below has no parameterless constructor — its two fields are read-only and set at construction. It is exactly the shape that has no useful instance to read into:

```delphi
uses
  System.SysUtils, System.Rtti, System.TypInfo, System.JSON,
  Neon.Core.Types, Neon.Core.Persistence, Neon.Core.Persistence.JSON;

type
  TMoney = class
  private
    FAmount: Currency;
    FCurrency: string;
  public
    constructor Create(AAmount: Currency; const ACurrency: string);
    property Amount: Currency read FAmount;
    property Currency: string read FCurrency;
  end;

  TMoneySerializer = class(TCustomSerializer)
  protected
    class function GetTargetInfo: PTypeInfo; override;
    class function CanHandle(AType: PTypeInfo): Boolean; override;
  public
    class function NeedsInstance: Boolean; override;
    function Serialize(const AValue: TValue; ANeonObject: TNeonRttiObject;
      AContext: ISerializerContext): TJSONValue; override;
    function Deserialize(AValue: TJSONValue; const AData: TValue;
      ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue; override;
  end;

class function TMoneySerializer.GetTargetInfo: PTypeInfo;
begin
  Result := TMoney.ClassInfo;
end;

class function TMoneySerializer.CanHandle(AType: PTypeInfo): Boolean;
begin
  Result := TypeInfoIs(AType);
end;

// Deserialize builds the TMoney itself, so a member with no instance is not a
// reason to skip it
class function TMoneySerializer.NeedsInstance: Boolean;
begin
  Result := False;
end;

function TMoneySerializer.Serialize(const AValue: TValue;
  ANeonObject: TNeonRttiObject; AContext: ISerializerContext): TJSONValue;
var
  LMoney: TMoney;
begin
  LMoney := AValue.AsObject as TMoney;
  Result := TJSONString.Create(Format('%s %s', [LMoney.Currency,
    CurrToStrF(LMoney.Amount, ffFixed, 2, TFormatSettings.Invariant)]));
end;

function TMoneySerializer.Deserialize(AValue: TJSONValue; const AData: TValue;
  ANeonObject: TNeonRttiObject; AContext: IDeserializerContext): TValue;
var
  LParts: TArray<string>;
  LAmount: Currency;
begin
  LParts := AValue.Value.Split([' ']);
  if (Length(LParts) <> 2) or
     not TryStrToCurr(LParts[1], LAmount, TFormatSettings.Invariant) then
  begin
    AContext.LogError(Format('Not a money value [%s]', [AValue.Value]));
    Exit(AData);
  end;

  // Replacing a value means disposing of the one it replaces - nothing else
  // will. Here AData is normally empty, which is the whole point
  if AData.IsObject and not AContext.IsOriginalInstance(AData) then
    AData.AsObject.Free;

  Result := TMoney.Create(LAmount, LParts[0]);
end;
```

With the serializer registered, a `TMoney` member round-trips with no `AutoCreate` and no attribute on the member:

```delphi
LConfig := TNeonConfiguration.Default.RegisterSerializer(TMoneySerializer);

LJSON := TNeon.ObjectToJSON(LInvoice, LConfig);
// {"Number":"INV-1","Price":"EUR 12.50"}

LInvoice := TNeon.JSONToObject<TInvoice>('{"Number":"INV-2","Price":"USD 99.90"}', LConfig);
// LInvoice.Price is a TMoney of USD 99.90
```

Without the `NeedsInstance` override, the same code writes the JSON correctly and reads `Price` back as `nil`.

`TJSONValueSerializer` (`Neon.Core.Serializers.RTL`) is the bundled example: its `Deserialize` returns a clone of the JSON it is given, so it never had a use for the instance either, and a `TJSONValue` member works without `AutoCreate`.

##### Ownership rules for `Deserialize`

`AData` is what the target holds right now, and the returned `TValue` is what it will hold. Three rules follow from that:

- **Return `AData`** once it has been filled in place, or a **different value** to replace it.
- **Replacing means freeing.** The instance being replaced is the serializer's to dispose of — nothing else will do it.
- **One instance must never be replaced**: the one the caller passed to `JSONToObject`. There is no reference to update, and the entry point discards the result, so a serializer that would otherwise return something new has to read into that one instead. `AContext.IsOriginalInstance(AData)` is how it is recognised.

Two more things `Deserialize` should expect: `AValue` can be a `TJSONNull` — a null reaches the serializer so it can decide what "no value" means for its type — and the returned `TValue` has to fit the target's declared type, since the engine assigns it as it is.

> [!TIP]
> Turning `AutoCreate` on is not a substitute for `NeedsInstance`. It builds the instance through the first parameterless constructor RTTI finds, which for a class declaring only parameterized ones is the inherited `TObject.Create` — an allocated but *uninitialized* object, which the serializer then has to free before returning its own. `NeedsInstance = False` skips that round trip, and keeps the decision with the serializer instead of with a global setting.

#### Unwrapped members
- `[NeonUnwrapped]` flattens a class/record member: its own members are written directly into the parent object instead of being nested under the member's name

> [!WARNING]
> Neon does **not** check for name collisions when flattening. If the parent and the unwrapped member both declare a member with the same JSON name, that name is written twice — in the serialized JSON and in the generated JSON Schema alike:
>
> ```json
> {"Name":"outer","Name":"inner","Code":7}
> ```
>
> Duplicate names are not forbidden outright by the JSON spec, but it says they SHOULD be unique and leaves the handling of repeats undefined. The practical consequence is that the second value is written out but can never be read back — `TJSONObject.GetValue` returns the first match, so deserializing the JSON above sets **both** properties to `"outer"` and the inner value is lost:
>
> ```
> outer.Name       : outer
> outer.Inner.Name : outer
> ```
>
> Give the two members distinct JSON names, using `[NeonProperty]` if the Delphi names have to stay as they are.

### JSON Schema

Neon can generate and validate [JSON Schema](https://json-schema.org/) documents for your Delphi types:
- `TNeonSchemaGenerator` generates a JSON Schema document from a Delphi type (classes, records, arrays, enums...) and its Neon attributes, supporting both **Draft 2020-12** and **Draft-07**
- `TJSONSchemaValidator` validates a `TJSONValue` against any JSON Schema document (`$ref`/`$anchor` resolution, `allOf`/`anyOf`/`oneOf`/`not`, numeric/string/array/object constraints, etc...), working directly against `TJSONObject` with no need for the original Delphi type
- The `JsonSchemaAttribute` lets you annotate types for more complete schema generation (e.g. `title`, `description`, `format`, `examples`)

### Entity Generator

`TNeonEntityGenerator` (in `Neon.Core.Generator`) goes the other way around: it takes a JSON document as a sample and writes the Delphi entities that hold it, attributes included.

```delphi
WriteLn(TNeonEntityGenerator.JSONToUnit(LResponse, 'Api.Entities'));
```

```delphi
type
  TAddress = class
  private
    FCity: string;
  public
    [NeonProperty('city')]
    property City: string read FCity write FCity;
  end;

  TRoot = class
  private
    FFirstName: string;
    FCreatedAt: TDateTime;
    FAddress: TAddress;
    FOrders: TObjectList<TOrder>;
  public
    constructor Create;
    destructor Destroy; override;

    [NeonProperty('first_name')]
    property FirstName: string read FFirstName write FFirstName;
    ...
```

- Classes (private fields and properties) or records, `TObjectList<T>`/`TList<T>`/`TArray<T>` for the arrays of objects
- `[NeonProperty]` wherever the Delphi identifier is not the JSON member name, so that the entities round-trip the document they were generated from
- The JSON member names are turned into Delphi identifiers whatever convention they follow (`user_name`, `zip-code`, `USER_ID`), reserved words included
- ISO8601 strings become `TDateTime`, large integers become `Int64`, and members that are null (or missing from some samples) can become `Nullable<T>`
- Objects with the same structure share one entity, and a constructor/destructor pair is generated for the entities owning others
- `AddSample` reads more than one document, so an entity can be generated from a whole set of responses instead of a single one
- Whatever the document could not say (a member that is always null, an array that is always empty, samples with incompatible types) is reported in `Warnings`

`Demos/Source/Classify` is a command line generator built on it — run it with `--help` for the switches, or with no arguments at all for a set of examples:

```
Classify customer.json                                  # print the classes
Classify -k record --no-header customer.json            # records instead
Classify -o Api.Customer.pas -p TApi -r Customer -n customer.json
```

Its [README](Demos/Source/Classify/README.md) walks through each of them with the source they generate.

### Attribute Tags

`Neon.Core.Tags` offers a runtime alternative to compile-time attributes, inspired by Go's struct tags:
- `TAttributeTags` parses a delimited tag string (e.g. `"description=A person's name,required,readOnly"`) and applies the values to a field/property via RTTI
- `TStructTag` parses a string containing multiple named groups of tags (Go struct-tag style, e.g. `` `json:"name" neon:"required"` ``), useful when a single string needs to carry configuration for more than one concern

### Localization

All exception and error messages raised or logged by the library are centralized as `resourcestring` (in `Neon.Core.Types`), so the library can be localized without recompiling.

### Profiling

`TNeonLogger` (in `Neon.Core.Utils`) contains a lightweight, opt-in profiler that accumulates elapsed time and call count per named section of the engine (`Serialize:Object`, `Core:GetNeonMembers`, `Dynamic:GuessList`, ...):

```delphi
TNeonLogger.ProfileReset;
TNeonLogger.ProfileEnabled := True;
try
  LJSON := TNeon.ObjectToJSON(AObject, LConfig);
  LJSON.Free;
finally
  TNeonLogger.ProfileEnabled := False;
end;
WriteLn(TNeonLogger.ProfileReport);  // Section | Calls | Total (ms) | Avg (us) | %
```

It is disabled by default, in which case the instrumentation costs a single boolean check, so the calls are safe to leave in place. Timings are *inclusive* of nested calls, so the rows show where time is nested rather than a flat, mutually-exclusive breakdown.


## Todo

##### Code
- More Unit Tests

## Prerequisite
This library has been tested with **Delphi 12 Athens**, **Delphi 11 Alexandria**, **Delphi 10.4 Sydney**, **Delphi 10.3 Rio**, **Delphi 10.2 Tokyo**, but with a minimum amount of work it should compile with **Delphi XE7 and higher**

#### Libraries/Units dependencies
This library has no dependencies on external libraries/units.

Delphi units used:
- System.JSON (DXE6+)
- System.Rtti (D2010+)
- System.Generics.Collections (D2009+)

## Installation
Simply add the source path "Source" to your Delphi project path and.. you are good to go!

## Code Examples

### Serialize an object

#### Using TNeon utility class
The easiest way to serialize and deserialize is to use the `TNeon` utility class:

Object serialization:
```delphi
var
  LJSON: TJSONValue;
begin
  LJSON := TNeon.ObjectToJSON(AObject);
  try
    Memo1.Lines.Text := TNeon.Print(LJSON, True);
  finally
    LJSON.Free;
  end;
end;
```

Object deserialization:
```delphi
var
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue(Memo1.Lines.Text);
  try
    TNeon.JSONToObject(AObject, LJSON, AConfig);
  finally
    LJSON.Free;
  end;
```

#### Using TNeonSerializer and TNeonDeserializer classes
Using the `TNeonSerializerJSON` and `TNeonDeserializerJSON` classes you have more control over the process.

Object serialization:
```delphi
var
  LJSON: TJSONValue;
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    LJSON := LWriter.ObjectToJSON(AObject);
    try
      Memo1.Lines.Text := TNeon.Print(LJSON, True);
      MemoError.Lines.AddStrings(LWriter.Errors);
    finally
      LJSON.Free;
    end;
  finally
    LWriter.Free;
  end;
end;
```

Object deserialization:
```delphi
var
  LJSON: TJSONValue;
  LReader: TNeonDeserializerJSON;
begin
  LJSON := TJSONObject.ParseJSONValue(Memo1.Lines.Text);
  if not Assigned(LJSON) then
    raise Exception.Create('Error parsing JSON string');

  try
    LReader := TNeonDeserializerJSON.Create(AConfig);
    try
      LReader.JSONToObject(AObject, LJSON);
      MemoError.Lines.AddStrings(LWriter.Errors);
    finally
      LReader.Free;
    end;
  finally
    LJSON.Free;
  end;
```

#### Neon configuration
It's very easy to configure **Neon**, 

```delphi
var
  LConfig: INeonConfiguration;
begin
  LConfig := TNeonConfiguration.Default
    .SetMemberCase(TNeonCase.SnakeCase)     // Case settings
    .SetMembers(TNeonMembers.Properties)    // Member type settings
    .SetIgnoreFieldPrefix(True)             // F Prefix settings
    .SetVisibility([mvPublic, mvPublished]) // Visibility settings

    // Custom serializer registration (nothing is registered by default)
    .RegisterSerializer(TGUIDSerializer)
  ;
end;
```


<hr />
<div style="text-align:right">Paolo Rossi</div>
