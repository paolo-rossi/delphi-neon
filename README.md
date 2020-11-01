# Neon - Serialization Library for Delphi

<br />

<p align="center">
  <a href="http://wirl.delphiblocks.com/">
    <img src="https://user-images.githubusercontent.com/4686497/54478586-175c9500-4814-11e9-98c3-09b9aca9ad66.png" alt="Neon Library" width="400" />
  </a>
</p>

## What is Neon

**Neon** is a serialization library for [Delphi](https://www.embarcadero.com/products/delphi) that helps you to convert (back and forth) objects and other values to JSON. It supports simple Delphi types but also complex class and records. **Neon** has been designed with **REST** in mind, to exchange pure data between applications with no *"metadata"* or added fields, in fact **Neon** is the default JSON serialization engine for the [WiRL REST Library](https://github.com/delphi-blocks/WiRL).

Please take a look at the Demos to see **Neon** in action.

## General Features

### Configuration

Extensive configuration through `INeonConfiguration` interface:
- Word case (UPPERCASE, lowercase, PascalCase, camelCase, snake_case)
- CuStOM CAse (through anonymous method)
- Member types (Fields, Properties)
- Option to ignore the "F" if you choose to serialize the fields
- Member visibility (private, protected, public, published)
- Custom serializer registration
- Use UTC date in serialization

### Delphi Types Support

Neon supports the (de)serialization of most Delphi standard types, records, array and of course classes. Classes can be complex as you want them to be, can contain array, (generic) lists, sub-classes, record, etc...


#### Simple values
- Basic types: string, Integer, Double, Boolean, TDateTime

#### Complex values
- Arrays of (basic types, records, classes, etc...)
- Records with fields of (basic types, records, classes, arrays, etc...)
- Classes with fields of (basic types, records, classes, arrays, etc...)
- Generic lists
- Dictionaries (key must be of type string)
- Streamable classes

#### Custom Serializers
- Inherit from TCustomSerializer and register this new class in the configuration


## Todo

##### Features
- Better way to register (and find) a custom serializer

##### Code
- Unit Tests

## Prerequisite
This library has been tested with **Delphi 10.4 Sydney**, **Delphi 10.3 Rio**, **Delphi 10.2 Tokyo**, **Delphi 10.1 Berlin**, but with a minimum amount of work it should compile with **Delphi XE7 and higher**

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
    Memo1.Lines.Text := TJSONUtils.PrettyPrint(LJSON);
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
      Memo1.Lines.Text := TJSONUtils.PrettyPrint(LJSON);
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

    // Custom serializer registration
    .GetSerializers.RegisterSerializer(TGUIDSerializer)
  ;
end;
```


<hr />
<div style="text-align:right">Paolo Rossi</div>
