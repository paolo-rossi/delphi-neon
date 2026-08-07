{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.JsonSchemaValidator;

interface

uses
  System.SysUtils, System.JSON, DUnitX.TestFramework,
  Neon.Core.Persistence.JSON.Schema;

type
  [TestFixture]
  [Category('jsonschemavalidator')]
  TTestJsonSchemaValidator = class(TObject)
  private
    function CheckValid(const ASchemaJSON, AInstanceJSON: string): Boolean;
  public
    [Test]
    [TestCase('String matches', '{"type":"string"}|"foo"|True', '|')]
    [TestCase('Number does not match string', '{"type":"string"}|42|False', '|')]
    [TestCase('Null matches union type', '{"type":["string","null"]}|null|True', '|')]
    [TestCase('1.0 matches integer', '{"type":"integer"}|1.0|True', '|')]
    [TestCase('1.5 does not match integer', '{"type":"integer"}|1.5|False', '|')]
    procedure TestType(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    [TestCase('Enum: matching value', '{"enum":[1,2,3]}|2|True', '|')]
    [TestCase('Enum: non-matching value', '{"enum":[1,2,3]}|4|False', '|')]
    [TestCase('Const: matching value', '{"const":"foo"}|"foo"|True', '|')]
    [TestCase('Const: non-matching value', '{"const":"foo"}|"bar"|False', '|')]
    procedure TestEnumConst(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    [TestCase('minLength: exact length ok', '{"minLength":2}|"fo"|True', '|')]
    [TestCase('minLength: too short', '{"minLength":2}|"f"|False', '|')]
    [TestCase('minLength: ignores non-strings', '{"minLength":2}|1|True', '|')]
    [TestCase('maxLength: exact length ok', '{"maxLength":2}|"fo"|True', '|')]
    [TestCase('maxLength: too long', '{"maxLength":2}|"foo"|False', '|')]
    [TestCase('maxLength: ignores non-strings', '{"maxLength":2}|12345|True', '|')]
    [TestCase('pattern: matches', '{"pattern":"^[A-Z]+$"}|"ABC"|True', '|')]
    [TestCase('pattern: does not match', '{"pattern":"^[A-Z]+$"}|"abc"|False', '|')]
    [TestCase('pattern: ignores non-strings', '{"pattern":"^[A-Z]+$"}|1|True', '|')]
    procedure TestString(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    procedure TestMinLengthCountsUnicodeCodepointsNotUTF16Units;

    [Test]
    [TestCase('minimum: on boundary ok', '{"minimum":1.1}|1.1|True', '|')]
    [TestCase('minimum: below fails', '{"minimum":1.1}|0.6|False', '|')]
    [TestCase('maximum: on boundary ok', '{"maximum":5}|5|True', '|')]
    [TestCase('maximum: above fails', '{"maximum":5}|6|False', '|')]
    [TestCase('exclusiveMinimum: on boundary fails', '{"exclusiveMinimum":1.1}|1.1|False', '|')]
    [TestCase('exclusiveMaximum: on boundary fails', '{"exclusiveMaximum":5}|5|False', '|')]
    [TestCase('multipleOf: valid', '{"multipleOf":2}|10|True', '|')]
    [TestCase('multipleOf: invalid', '{"multipleOf":2}|7|False', '|')]
    procedure TestNumeric(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    [TestCase('required: present', '{"required":["foo"]}|{"foo":1}|True', '|')]
    [TestCase('required: missing', '{"required":["foo"]}|{"bar":1}|False', '|')]
    [TestCase('additionalProperties false: extra rejected',
      '{"properties":{"foo":{}},"additionalProperties":false}|{"foo":1,"bar":2}|False', '|')]
    [TestCase('additionalProperties false: no extra ok',
      '{"properties":{"foo":{}},"additionalProperties":false}|{"foo":1}|True', '|')]
    [TestCase('minProperties: ok', '{"minProperties":1}|{"foo":1}|True', '|')]
    [TestCase('minProperties: too few', '{"minProperties":1}|{}|False', '|')]
    [TestCase('maxProperties: ok', '{"maxProperties":1}|{"foo":1}|True', '|')]
    [TestCase('maxProperties: too many', '{"maxProperties":1}|{"foo":1,"bar":2}|False', '|')]
    [TestCase('propertyNames: all match', '{"propertyNames":{"pattern":"^[a-z]+$"}}|{"foo":1,"bar":2}|True', '|')]
    [TestCase('propertyNames: one fails', '{"propertyNames":{"pattern":"^[a-z]+$"}}|{"Foo":1}|False', '|')]
    [TestCase('patternProperties: matching key validated',
      '{"patternProperties":{"^S_":{"type":"string"}}}|{"S_1":"foo"}|True', '|')]
    [TestCase('patternProperties: matching key fails inner schema',
      '{"patternProperties":{"^S_":{"type":"string"}}}|{"S_1":1}|False', '|')]
    procedure TestObject(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    [TestCase('items: all match', '{"items":{"type":"integer"}}|[1,2,3]|True', '|')]
    [TestCase('items: one fails', '{"items":{"type":"integer"}}|[1,"x",3]|False', '|')]
    [TestCase('prefixItems: tuple ok', '{"prefixItems":[{"type":"string"},{"type":"integer"}]}|["a",1]|True', '|')]
    [TestCase('prefixItems: tuple fails', '{"prefixItems":[{"type":"string"},{"type":"integer"}]}|[1,"a"]|False', '|')]
    [TestCase('minItems: ok', '{"minItems":2}|[1,2]|True', '|')]
    [TestCase('minItems: too few', '{"minItems":2}|[1]|False', '|')]
    [TestCase('maxItems: ok', '{"maxItems":2}|[1,2]|True', '|')]
    [TestCase('maxItems: too many', '{"maxItems":2}|[1,2,3]|False', '|')]
    [TestCase('uniqueItems: unique ok', '{"uniqueItems":true}|[1,2,3]|True', '|')]
    [TestCase('uniqueItems: duplicate fails', '{"uniqueItems":true}|[1,2,2]|False', '|')]
    [TestCase('contains: at least one matches', '{"contains":{"type":"integer"}}|["a",1,"b"]|True', '|')]
    [TestCase('contains: none match', '{"contains":{"type":"integer"}}|["a","b"]|False', '|')]
    [TestCase('minContains: satisfied', '{"contains":{"type":"integer"},"minContains":2}|[1,2,"a"]|True', '|')]
    [TestCase('minContains: not satisfied', '{"contains":{"type":"integer"},"minContains":2}|[1,"a"]|False', '|')]
    [TestCase('maxContains: satisfied', '{"contains":{"type":"integer"},"maxContains":1}|[1,"a"]|True', '|')]
    [TestCase('maxContains: exceeded', '{"contains":{"type":"integer"},"maxContains":1}|[1,2]|False', '|')]
    // Draft-07 tuple form: "items" is itself the per-index schema array, "additionalItems" governs the tail
    [TestCase('Draft-07 items tuple: matches',
      '{"items":[{"type":"integer"},{"type":"string"}],"additionalItems":false}|[1,"a"]|True', '|')]
    [TestCase('Draft-07 items tuple: wrong type at an index',
      '{"items":[{"type":"integer"},{"type":"string"}],"additionalItems":false}|["x","a"]|False', '|')]
    [TestCase('Draft-07 items tuple: additionalItems false rejects extra',
      '{"items":[{"type":"integer"},{"type":"string"}],"additionalItems":false}|[1,"a",true]|False', '|')]
    [TestCase('Draft-07 items tuple: additionalItems schema validates extra',
      '{"items":[{"type":"integer"}],"additionalItems":{"type":"string"}}|[1,"a","b"]|True', '|')]
    [TestCase('Draft-07 items tuple: additionalItems schema rejects wrong extra',
      '{"items":[{"type":"integer"}],"additionalItems":{"type":"string"}}|[1,"a",5]|False', '|')]
    [TestCase('Draft-07 items tuple: no additionalItems allows anything extra',
      '{"items":[{"type":"integer"}]}|[1,"a",5,true]|True', '|')]
    procedure TestArray(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    [TestCase('allOf: both match', '{"allOf":[{"type":"integer"},{"minimum":2}]}|5|True', '|')]
    [TestCase('allOf: one fails', '{"allOf":[{"type":"integer"},{"minimum":2}]}|1|False', '|')]
    [TestCase('anyOf: one matches', '{"anyOf":[{"type":"integer"},{"type":"string"}]}|"foo"|True', '|')]
    [TestCase('anyOf: none match', '{"anyOf":[{"type":"integer"},{"type":"boolean"}]}|"foo"|False', '|')]
    [TestCase('oneOf: exactly one', '{"oneOf":[{"type":"integer"},{"minimum":2}]}|1|True', '|')]
    [TestCase('oneOf: matches none', '{"oneOf":[{"type":"string"},{"minimum":2}]}|1.5|False', '|')]
    [TestCase('oneOf: matches more than one', '{"oneOf":[{"type":"integer"},{"minimum":2}]}|3|False', '|')]
    [TestCase('not: schema fails as expected -> valid', '{"not":{"type":"integer"}}|"foo"|True', '|')]
    [TestCase('not: schema matches -> invalid', '{"not":{"type":"integer"}}|5|False', '|')]
    procedure TestLogic(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    [TestCase('$ref: root pointer recursive match',
      '{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}|{"foo":{"foo":false}}|True', '|')]
    [TestCase('$ref: root pointer recursive mismatch',
      '{"properties":{"foo":{"$ref":"#"}},"additionalProperties":false}|{"foo":{"bar":false}}|False', '|')]
    [TestCase('$ref: relative pointer to property',
      '{"properties":{"foo":{"type":"integer"},"bar":{"$ref":"#/properties/foo"}}}|{"bar":3}|True', '|')]
    [TestCase('$ref: relative pointer to property mismatch',
      '{"properties":{"foo":{"type":"integer"},"bar":{"$ref":"#/properties/foo"}}}|{"bar":true}|False', '|')]
    [TestCase('$ref: to $defs valid',
      '{"$defs":{"posInt":{"type":"integer","minimum":1}},"properties":{"n":{"$ref":"#/$defs/posInt"}}}|{"n":5}|True', '|')]
    [TestCase('$ref: to $defs invalid',
      '{"$defs":{"posInt":{"type":"integer","minimum":1}},"properties":{"n":{"$ref":"#/$defs/posInt"}}}|{"n":-5}|False', '|')]
    // Draft-07 names/conventions: "definitions" (instead of "$defs") and a fragment-only
    // "$id" (instead of the dedicated "$anchor" keyword) for a plain-name anchor
    [TestCase('$ref: Draft-07 "definitions" valid',
      '{"definitions":{"posInt":{"type":"integer","minimum":1}},"properties":{"n":{"$ref":"#/definitions/posInt"}}}|{"n":5}|True', '|')]
    [TestCase('$ref: Draft-07 "definitions" invalid',
      '{"definitions":{"posInt":{"type":"integer","minimum":1}},"properties":{"n":{"$ref":"#/definitions/posInt"}}}|{"n":-5}|False', '|')]
    [TestCase('$ref: Draft-07 "$id" fragment anchor valid',
      '{"definitions":{"pos":{"$id":"#pos","type":"integer","minimum":0}},"properties":{"n":{"$ref":"#pos"}}}|{"n":5}|True', '|')]
    [TestCase('$ref: Draft-07 "$id" fragment anchor invalid',
      '{"definitions":{"pos":{"$id":"#pos","type":"integer","minimum":0}},"properties":{"n":{"$ref":"#pos"}}}|{"n":-5}|False', '|')]
    // Subschemas (and therefore anchors) also live inside arrays: anyOf/oneOf/
    // allOf branches, prefixItems entries, ...
    [TestCase('$ref: $anchor inside an anyOf branch valid',
      '{"$defs":{"any":{"anyOf":[{"$anchor":"pos","type":"integer","minimum":1},{"type":"string"}]}},"properties":{"n":{"$ref":"#pos"}}}|{"n":5}|True', '|')]
    [TestCase('$ref: $anchor inside an anyOf branch invalid',
      '{"$defs":{"any":{"anyOf":[{"$anchor":"pos","type":"integer","minimum":1},{"type":"string"}]}},"properties":{"n":{"$ref":"#pos"}}}|{"n":-5}|False', '|')]
    [TestCase('$ref: $anchor inside a prefixItems entry valid',
      '{"$defs":{"tup":{"prefixItems":[{"$anchor":"pos","type":"integer","minimum":1}]}},"properties":{"n":{"$ref":"#pos"}}}|{"n":5}|True', '|')]
    [TestCase('$ref: $anchor inside a prefixItems entry invalid',
      '{"$defs":{"tup":{"prefixItems":[{"$anchor":"pos","type":"integer","minimum":1}]}},"properties":{"n":{"$ref":"#pos"}}}|{"n":-5}|False', '|')]
    procedure TestRef(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    [TestCase('Boolean schema true: always valid', 'true|{"anything":"goes"}|True', '|')]
    [TestCase('Boolean schema false: always invalid', 'false|{"anything":"goes"}|False', '|')]
    [TestCase('Boolean schema false in additionalProperties',
      '{"additionalProperties":false}|{"foo":1}|False', '|')]
    procedure TestBooleanSchema(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    procedure TestCollectsMultipleErrors;

    [Test]
    procedure TestStopOnFirstErrorLimitsToOne;

    [Test]
    procedure TestErrorPathPointsToNestedProperty;
  end;

implementation

function TTestJsonSchemaValidator.CheckValid(const ASchemaJSON, AInstanceJSON: string): Boolean;
var
  LSchema, LInstance: TJSONValue;
  LValidator: TJSONSchemaValidator;
begin
  LSchema := TJSONObject.ParseJSONValue(ASchemaJSON);
  LInstance := TJSONObject.ParseJSONValue(AInstanceJSON);
  try
    LValidator := TJSONSchemaValidator.Create(LSchema);
    try
      Result := LValidator.Validate(LInstance).IsValid;
    finally
      LValidator.Free;
    end;
  finally
    LInstance.Free;
    LSchema.Free;
  end;
end;

procedure TTestJsonSchemaValidator.TestType(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestEnumConst(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestString(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestMinLengthCountsUnicodeCodepointsNotUTF16Units;
var
  LSchema: TJSONValue;
  LInstance: TJSONString;
  LValidator: TJSONSchemaValidator;
begin
  // U+1F4A9 requires a UTF-16 surrogate pair (2 Char code units) but is 1 codepoint
  LSchema := TJSONObject.ParseJSONValue('{"minLength":2}');
  LInstance := TJSONString.Create(Char($D83D) + Char($DCA9));
  try
    LValidator := TJSONSchemaValidator.Create(LSchema);
    try
      Assert.IsFalse(LValidator.Validate(LInstance).IsValid);
    finally
      LValidator.Free;
    end;
  finally
    LInstance.Free;
    LSchema.Free;
  end;
end;

procedure TTestJsonSchemaValidator.TestNumeric(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestObject(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestArray(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestLogic(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestRef(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestBooleanSchema(const ASchemaJSON, AInstanceJSON: string; AExpectedValid: Boolean);
begin
  Assert.AreEqual(AExpectedValid, CheckValid(ASchemaJSON, AInstanceJSON));
end;

procedure TTestJsonSchemaValidator.TestCollectsMultipleErrors;
var
  LSchema, LInstance: TJSONValue;
  LValidator: TJSONSchemaValidator;
  LResult: TJSONValidationResult;
begin
  LSchema := TJSONObject.ParseJSONValue('{"properties":{"name":{"minLength":3},"age":{"maximum":10}}}');
  LInstance := TJSONObject.ParseJSONValue('{"name":"ab","age":20}');
  try
    LValidator := TJSONSchemaValidator.Create(LSchema);
    try
      LResult := LValidator.Validate(LInstance);
      Assert.IsFalse(LResult.IsValid);
      Assert.AreEqual(2, Length(LResult.Errors));
    finally
      LValidator.Free;
    end;
  finally
    LInstance.Free;
    LSchema.Free;
  end;
end;

procedure TTestJsonSchemaValidator.TestStopOnFirstErrorLimitsToOne;
var
  LSchema, LInstance: TJSONValue;
  LValidator: TJSONSchemaValidator;
  LResult: TJSONValidationResult;
begin
  LSchema := TJSONObject.ParseJSONValue('{"properties":{"name":{"minLength":3},"age":{"maximum":10}}}');
  LInstance := TJSONObject.ParseJSONValue('{"name":"ab","age":20}');
  try
    LValidator := TJSONSchemaValidator.Create(LSchema);
    LValidator.StopOnFirstError := True;
    try
      LResult := LValidator.Validate(LInstance);
      Assert.IsFalse(LResult.IsValid);
      Assert.AreEqual(1, Length(LResult.Errors));
    finally
      LValidator.Free;
    end;
  finally
    LInstance.Free;
    LSchema.Free;
  end;
end;

procedure TTestJsonSchemaValidator.TestErrorPathPointsToNestedProperty;
var
  LSchema, LInstance: TJSONValue;
  LValidator: TJSONSchemaValidator;
  LResult: TJSONValidationResult;
begin
  LSchema := TJSONObject.ParseJSONValue('{"properties":{"address":{"properties":{"zip":{"type":"integer"}}}}}');
  LInstance := TJSONObject.ParseJSONValue('{"address":{"zip":"not-a-number"}}');
  try
    LValidator := TJSONSchemaValidator.Create(LSchema);
    try
      LResult := LValidator.Validate(LInstance);
      Assert.IsFalse(LResult.IsValid);
      Assert.AreEqual(1, Length(LResult.Errors));
      Assert.AreEqual('/address/zip', LResult.Errors[0].Path);
    finally
      LValidator.Free;
    end;
  finally
    LInstance.Free;
    LSchema.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJsonSchemaValidator);

end.
