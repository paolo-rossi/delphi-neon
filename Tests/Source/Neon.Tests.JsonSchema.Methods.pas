{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.JsonSchema.Methods;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON,
  DUnitX.TestFramework,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Persistence.JSON.Schema;

type
  TSchemaMethodNode = record
    Name: string;
    Children: TArray<TSchemaMethodNode>;
  end;

  TSchemaMethodPoint = record
    X: Integer;
    Y: Integer;
  end;

  /// <summary>
  ///   Methods whose signatures the fixture describes; none of them is ever
  ///   called. Public methods get extended RTTI by default
  /// </summary>
  TSchemaMethods = class
  public
    function Add(
      [JsonSchema('required,description=First addend,minimum=0')] A: Integer;
      [JsonSchema('required')] B: Double): Double;

    procedure NoParams;

    procedure Optional(const AName: string; ACount: Integer);

    procedure Renamed([NeonProperty('customer_id'), JsonSchema('required')] ACustomerId: Integer);

    procedure TagNamed([JsonSchema('name=order_id,required,description=The order,minimum=1')] AOrderId: Integer);

    procedure TagNameWins([NeonProperty('neon_name'), JsonSchema('name=tag_name')] const AValue: string);

    procedure WithOut(const AInput: string; out AOutput: string; var AInOut: Integer);

    procedure WithIgnored(const AValue: string; [NeonIgnore] AContext: TObject);

    procedure WithEvent([JsonSchema('description=Callback')] AEvent: TNotifyEvent);

    procedure WithNodes(const ARoot: TSchemaMethodNode; const AOther: TSchemaMethodNode);

    procedure WithArray([JsonSchema('minItems=1')] const ATags: TArray<string>);

    procedure PascalName(const SomeValue: string);

    [JsonSchema('description=The sum,minimum=0')]
    function Total: Integer;

    function GetPoint: TSchemaMethodPoint;

    function GetTree: TSchemaMethodNode;

    function GetEvent: TNotifyEvent;
  end;

  [TestFixture]
  [Category('jsonschema')]
  TTestJsonSchemaMethodParams = class(TObject)
  private
    FSchema: TJSONObject;
    function Method(const AName: string): TRttiMethod;
    function Properties: TJSONObject;
    function Prop(const AName: string): TJSONObject;
    function Validates(const AInstanceJSON: string): Boolean;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestParamsAreAnObject;

    [Test]
    procedure TestOnePropertyPerParam;

    [Test]
    procedure TestParamTypesAreDescribed;

    [Test]
    procedure TestParamTagsAreApplied;

    [Test]
    procedure TestRequiredParamsAreListed;

    [Test]
    procedure TestNoRequiredArrayWithoutRequiredTags;

    [Test]
    procedure TestNoParamsGivesEmptyProperties;

    [Test]
    procedure TestNeonPropertyRenamesParam;

    [Test]
    procedure TestNameTagRenamesParam;

    [Test]
    procedure TestNameTagIsNotWrittenIntoTheSchema;

    [Test]
    procedure TestNameTagWinsOverNeonProperty;

    [Test]
    procedure TestParamNamesIgnoreMemberCase;

    [Test]
    procedure TestOutParamIsLeftOut;

    [Test]
    procedure TestNeonIgnoreParamIsLeftOut;

    [Test]
    procedure TestParamWithoutSchemaIsUnconstrained;

    [Test]
    procedure TestArrayParamKeepsItsTags;

    [Test]
    procedure TestRecursiveTypeSharesOneDefinition;

    [Test]
    procedure TestDraft07UsesDefinitions;

    [Test]
    procedure TestNoVersionOmitsSchemaKeyword;

    [Test]
    procedure TestVersionWritesSchemaKeyword;

    [Test]
    [TestCase('Valid', '{"A":1,"B":2.5}|True', '|')]
    [TestCase('MissingRequired', '{"A":1}|False', '|')]
    [TestCase('BelowMinimum', '{"A":-1,"B":2.5}|False', '|')]
    [TestCase('WrongType', '{"A":"one","B":2.5}|False', '|')]
    procedure TestInstanceValidatesAgainstParams(const AInstanceJSON: string; AExpectedValid: Boolean);

    [Test]
    procedure TestResolverSeesNeonDefaults;

    [Test]
    procedure TestNilResolverIsTheDefault;

    [Test]
    procedure TestResolverRenamesAndRequires;

    [Test]
    procedure TestResolverDescriptionReplacesTag;

    [Test]
    procedure TestResolverEmptyDescriptionKeepsTag;

    [Test]
    procedure TestResolverCanSkip;

    [Test]
    procedure TestResolverCanIncludeOutParam;

    [Test]
    procedure TestDuplicateParamNameRaises;

    [Test]
    procedure TestEmptyParamNameRaises;
  end;

  [TestFixture]
  [Category('jsonschema')]
  TTestJsonSchemaMethodResult = class(TObject)
  private
    FSchema: TJSONObject;
    function Method(const AName: string): TRttiMethod;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestProcedureHasNoResultSchema;

    [Test]
    procedure TestResultTypeIsDescribed;

    [Test]
    procedure TestMethodTagsApplyToResult;

    [Test]
    procedure TestRecordResultIsAnObject;

    [Test]
    procedure TestResultWithoutSchemaIsNil;

    [Test]
    procedure TestRecursiveResultCarriesDefinitions;

    [Test]
    procedure TestDraft07RecursiveResultWrapsRefInAllOf;

    [Test]
    procedure TestNoVersionOmitsSchemaKeyword;

    [Test]
    procedure TestResultTypeOverrideKeepsMethodTags;

    [Test]
    procedure TestNilResultTypeGivesNil;
  end;

implementation

{ TSchemaMethods }

function TSchemaMethods.Add(A: Integer; B: Double): Double;
begin
  Result := A + B;
end;

function TSchemaMethods.GetEvent: TNotifyEvent;
begin
  Result := nil;
end;

function TSchemaMethods.GetPoint: TSchemaMethodPoint;
begin
  Result := Default(TSchemaMethodPoint);
end;

function TSchemaMethods.GetTree: TSchemaMethodNode;
begin
  Result := Default(TSchemaMethodNode);
end;

procedure TSchemaMethods.NoParams;
begin
end;

procedure TSchemaMethods.Optional(const AName: string; ACount: Integer);
begin
end;

procedure TSchemaMethods.PascalName(const SomeValue: string);
begin
end;

procedure TSchemaMethods.Renamed(ACustomerId: Integer);
begin
end;

procedure TSchemaMethods.TagNamed(AOrderId: Integer);
begin
end;

procedure TSchemaMethods.TagNameWins(const AValue: string);
begin
end;

function TSchemaMethods.Total: Integer;
begin
  Result := 0;
end;

procedure TSchemaMethods.WithArray(const ATags: TArray<string>);
begin
end;

procedure TSchemaMethods.WithEvent(AEvent: TNotifyEvent);
begin
end;

procedure TSchemaMethods.WithIgnored(const AValue: string; AContext: TObject);
begin
end;

procedure TSchemaMethods.WithNodes(const ARoot, AOther: TSchemaMethodNode);
begin
end;

procedure TSchemaMethods.WithOut(const AInput: string; out AOutput: string; var AInOut: Integer);
begin
  AOutput := AInput;
end;

function GetSchemaMethod(const AName: string): TRttiMethod;
begin
  Result := TRttiContext.Create.GetType(TSchemaMethods).GetMethod(AName);
  Assert.IsNotNull(Result, 'no RTTI for method ' + AName);
end;

function CountPairs(AObject: TJSONObject; const AName: string): Integer;
var
  LPair: TJSONPair;
begin
  Result := 0;
  for LPair in AObject do
    if LPair.JsonString.Value = AName then
      Inc(Result);
end;

{ TTestJsonSchemaMethodParams }

function TTestJsonSchemaMethodParams.Method(const AName: string): TRttiMethod;
begin
  Result := GetSchemaMethod(AName);
end;

function TTestJsonSchemaMethodParams.Properties: TJSONObject;
begin
  Result := FSchema.GetValue('properties') as TJSONObject;
end;

function TTestJsonSchemaMethodParams.Prop(const AName: string): TJSONObject;
begin
  Result := Properties.GetValue(AName) as TJSONObject;
end;

procedure TTestJsonSchemaMethodParams.TearDown;
begin
  FreeAndNil(FSchema);
end;

function TTestJsonSchemaMethodParams.Validates(const AInstanceJSON: string): Boolean;
var
  LInstance: TJSONValue;
begin
  LInstance := TJSONObject.ParseJSONValue(AInstanceJSON);
  try
    Result := TNeon.ValidateJSON(LInstance, FSchema).IsValid;
  finally
    LInstance.Free;
  end;
end;

procedure TTestJsonSchemaMethodParams.TestParamsAreAnObject;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'));
  Assert.AreEqual('object', FSchema.GetValue('type').Value);
  Assert.IsNotNull(Properties);
end;

procedure TTestJsonSchemaMethodParams.TestOnePropertyPerParam;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'));
  Assert.AreEqual(2, Properties.Count);
  Assert.IsNotNull(Prop('A'));
  Assert.IsNotNull(Prop('B'));
end;

procedure TTestJsonSchemaMethodParams.TestParamTypesAreDescribed;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'));
  Assert.AreEqual('integer', Prop('A').GetValue('type').Value);
  Assert.AreEqual('number', Prop('B').GetValue('type').Value);
end;

procedure TTestJsonSchemaMethodParams.TestParamTagsAreApplied;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'));
  Assert.AreEqual('First addend', Prop('A').GetValue('description').Value);
  Assert.AreEqual(0.0, (Prop('A').GetValue('minimum') as TJSONNumber).AsDouble, 0.0);
  // "required" belongs to the parent, never to the parameter's own schema
  Assert.IsNull(Prop('A').GetValue('required'));
  Assert.IsNull(Prop('B').GetValue('description'));
end;

procedure TTestJsonSchemaMethodParams.TestRequiredParamsAreListed;
var
  LRequired: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'));
  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired);
  Assert.AreEqual(2, LRequired.Count);
  Assert.AreEqual('A', LRequired.Items[0].Value);
  Assert.AreEqual('B', LRequired.Items[1].Value);
end;

procedure TTestJsonSchemaMethodParams.TestNoRequiredArrayWithoutRequiredTags;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Optional'));
  Assert.AreEqual(2, Properties.Count);
  Assert.IsNull(FSchema.GetValue('required'));
end;

procedure TTestJsonSchemaMethodParams.TestNoParamsGivesEmptyProperties;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('NoParams'));
  Assert.AreEqual('object', FSchema.GetValue('type').Value);
  Assert.AreEqual(0, Properties.Count);
  Assert.IsNull(FSchema.GetValue('required'));
end;

procedure TTestJsonSchemaMethodParams.TestNeonPropertyRenamesParam;
var
  LRequired: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Renamed'));
  Assert.IsNotNull(Prop('customer_id'));
  Assert.IsNull(Properties.GetValue('ACustomerId'));

  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired);
  Assert.AreEqual('customer_id', LRequired.Items[0].Value);
end;

procedure TTestJsonSchemaMethodParams.TestNameTagRenamesParam;
var
  LOrder: TJSONObject;
  LRequired: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('TagNamed'));
  Assert.IsNull(Properties.GetValue('AOrderId'));
  LOrder := Prop('order_id');
  Assert.IsNotNull(LOrder);
  Assert.AreEqual('integer', LOrder.GetValue('type').Value);
  Assert.AreEqual('The order', LOrder.GetValue('description').Value);
  Assert.AreEqual(1.0, (LOrder.GetValue('minimum') as TJSONNumber).AsDouble, 0.0);

  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired);
  Assert.AreEqual('order_id', LRequired.Items[0].Value);
end;

procedure TTestJsonSchemaMethodParams.TestNameTagIsNotWrittenIntoTheSchema;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('TagNamed'));
  Assert.IsNull(Prop('order_id').GetValue('name'));
end;

procedure TTestJsonSchemaMethodParams.TestNameTagWinsOverNeonProperty;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('TagNameWins'));
  Assert.IsNotNull(Prop('tag_name'));
  Assert.IsNull(Properties.GetValue('neon_name'));
  Assert.AreEqual(1, Properties.Count);
end;

procedure TTestJsonSchemaMethodParams.TestParamNamesIgnoreMemberCase;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('PascalName'), TNeonConfiguration.Snake);
  Assert.IsNotNull(Prop('SomeValue'), 'parameters keep their declared name');
  Assert.IsNull(Properties.GetValue('some_value'));
end;

procedure TTestJsonSchemaMethodParams.TestOutParamIsLeftOut;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('WithOut'));
  Assert.IsNotNull(Prop('AInput'));
  Assert.IsNull(Properties.GetValue('AOutput'), 'an out parameter is not an input');
  Assert.IsNotNull(Prop('AInOut'), 'a var parameter is an input too');
  Assert.AreEqual(2, Properties.Count);
end;

procedure TTestJsonSchemaMethodParams.TestNeonIgnoreParamIsLeftOut;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('WithIgnored'));
  Assert.IsNotNull(Prop('AValue'));
  Assert.IsNull(Properties.GetValue('AContext'));
  Assert.AreEqual(1, Properties.Count);
end;

procedure TTestJsonSchemaMethodParams.TestParamWithoutSchemaIsUnconstrained;
var
  LEvent: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('WithEvent'));
  LEvent := Prop('AEvent');
  Assert.IsNotNull(LEvent, 'the caller still has to pass the parameter');
  Assert.IsNull(LEvent.GetValue('type'));
  Assert.AreEqual('Callback', LEvent.GetValue('description').Value, 'the tags are kept');
end;

procedure TTestJsonSchemaMethodParams.TestArrayParamKeepsItsTags;
var
  LTags: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('WithArray'));
  LTags := Prop('ATags');
  Assert.AreEqual('array', LTags.GetValue('type').Value);
  Assert.AreEqual(1, (LTags.GetValue('minItems') as TJSONNumber).AsInt);
end;

procedure TTestJsonSchemaMethodParams.TestRecursiveTypeSharesOneDefinition;
var
  LDefs: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('WithNodes'), TNeonJSchemaVersion.v202012);
  LDefs := FSchema.GetValue('$defs') as TJSONObject;
  Assert.IsNotNull(LDefs, 'the definitions belong at the root');
  Assert.AreEqual(1, LDefs.Count);
  Assert.IsNotNull(LDefs.GetValue('TSchemaMethodNode'));
  Assert.AreEqual('#/$defs/TSchemaMethodNode', Prop('ARoot').GetValue('$ref').Value);
  Assert.AreEqual('#/$defs/TSchemaMethodNode', Prop('AOther').GetValue('$ref').Value);

  Assert.IsTrue(Validates('{"ARoot":{"Name":"a","Children":[{"Name":"b","Children":[]}]},' +
    '"AOther":{"Name":"c","Children":[]}}'));
end;

procedure TTestJsonSchemaMethodParams.TestDraft07UsesDefinitions;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('WithNodes'), TNeonJSchemaVersion.Draft07);
  Assert.IsNotNull(FSchema.GetValue('definitions'));
  Assert.IsNull(FSchema.GetValue('$defs'));
  Assert.AreEqual('#/definitions/TSchemaMethodNode', Prop('ARoot').GetValue('$ref').Value);
end;

procedure TTestJsonSchemaMethodParams.TestNoVersionOmitsSchemaKeyword;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'));
  Assert.IsNull(FSchema.GetValue('$schema'));
end;

procedure TTestJsonSchemaMethodParams.TestVersionWritesSchemaKeyword;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'), TNeonJSchemaVersion.v202012);
  Assert.AreEqual('https://json-schema.org/draft/2020-12/schema', FSchema.GetValue('$schema').Value);
end;

procedure TTestJsonSchemaMethodParams.TestInstanceValidatesAgainstParams(const AInstanceJSON: string;
  AExpectedValid: Boolean);
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'), TNeonJSchemaVersion.v202012);
  Assert.AreEqual(AExpectedValid, Validates(AInstanceJSON));
end;

procedure TTestJsonSchemaMethodParams.TestResolverSeesNeonDefaults;
var
  LSeen: string;
begin
  LSeen := '';
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('WithOut'), TNeonConfiguration.Default,
    procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
    begin
      LSeen := LSeen + Format('%s=%s,%s,%s,%s;', [AParam.Name, AInfo.Name, AInfo.Description,
        BoolToStr(AInfo.Required, True), BoolToStr(AInfo.Skip, True)]);
    end);
  Assert.AreEqual('AInput=AInput,,False,False;AOutput=AOutput,,False,True;AInOut=AInOut,,False,False;', LSeen,
    'every parameter is offered, the out one already marked to skip');

  LSeen := '';
  FreeAndNil(FSchema);
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('TagNamed'), TNeonConfiguration.Default,
    procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
    begin
      LSeen := LSeen + Format('%s=%s,%s', [AParam.Name, AInfo.Name, BoolToStr(AInfo.Required, True)]);
    end);
  Assert.AreEqual('AOrderId=order_id,True', LSeen, 'the name and required tags are already applied');
end;

procedure TTestJsonSchemaMethodParams.TestNilResolverIsTheDefault;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'), TNeonConfiguration.Default, nil);
  Assert.AreEqual('First addend', Prop('A').GetValue('description').Value);
  Assert.AreEqual(2, (FSchema.GetValue('required') as TJSONArray).Count);
end;

procedure TTestJsonSchemaMethodParams.TestResolverRenamesAndRequires;
var
  LRequired: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Optional'), TNeonConfiguration.Default,
    procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
    begin
      AInfo.Name := AParam.Name.Substring(1).ToLower;
      AInfo.Required := True;
    end);
  Assert.AreEqual('string', Prop('name').GetValue('type').Value);
  Assert.AreEqual('integer', Prop('count').GetValue('type').Value);
  Assert.IsNull(Properties.GetValue('AName'));

  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired);
  Assert.AreEqual(2, LRequired.Count);
  Assert.AreEqual('name', LRequired.Items[0].Value);
  Assert.AreEqual('count', LRequired.Items[1].Value);
end;

procedure TTestJsonSchemaMethodParams.TestResolverDescriptionReplacesTag;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'), TNeonConfiguration.Default,
    procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
    begin
      AInfo.Description := 'Described ' + AParam.Name;
    end);
  Assert.AreEqual(1, CountPairs(Prop('A'), 'description'), 'replaced, not added a second time');
  Assert.AreEqual('Described A', Prop('A').GetValue('description').Value);
  Assert.AreEqual(0.0, (Prop('A').GetValue('minimum') as TJSONNumber).AsDouble, 0.0, 'the other tags stay');
  Assert.AreEqual('Described B', Prop('B').GetValue('description').Value);
end;

procedure TTestJsonSchemaMethodParams.TestResolverEmptyDescriptionKeepsTag;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'), TNeonConfiguration.Default,
    procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
    begin
      AInfo.Description := '';
    end);
  Assert.AreEqual('First addend', Prop('A').GetValue('description').Value);
  Assert.IsNull(Prop('B').GetValue('description'), 'no description is invented');
end;

procedure TTestJsonSchemaMethodParams.TestResolverCanSkip;
var
  LRequired: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'), TNeonConfiguration.Default,
    procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
    begin
      AInfo.Skip := AParam.Name = 'B';
    end);
  Assert.AreEqual(1, Properties.Count);
  Assert.IsNull(Properties.GetValue('B'));
  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.AreEqual(1, LRequired.Count, 'a skipped parameter is not required either');
end;

procedure TTestJsonSchemaMethodParams.TestResolverCanIncludeOutParam;
begin
  FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('WithOut'), TNeonConfiguration.Default,
    procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
    begin
      AInfo.Skip := False;
    end);
  Assert.AreEqual(3, Properties.Count);
  Assert.AreEqual('string', Prop('AOutput').GetValue('type').Value);
end;

procedure TTestJsonSchemaMethodParams.TestDuplicateParamNameRaises;
begin
  Assert.WillRaiseWithMessage(
    procedure
    begin
      FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Optional'), TNeonConfiguration.Default,
        procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
        begin
          AInfo.Name := 'same';
        end);
    end,
    ENeonException,
    'Parameters [AName] and [ACount] are both described as [same]');
end;

procedure TTestJsonSchemaMethodParams.TestEmptyParamNameRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      FSchema := TNeonSchemaGenerator.MethodParamsToSchema(Method('Add'), TNeonConfiguration.Default,
        procedure (AParam: TRttiParameter; var AInfo: TNeonParamSchemaInfo)
        begin
          AInfo.Name := '';
        end);
    end,
    ENeonException);
end;

{ TTestJsonSchemaMethodResult }

function TTestJsonSchemaMethodResult.Method(const AName: string): TRttiMethod;
begin
  Result := GetSchemaMethod(AName);
end;

procedure TTestJsonSchemaMethodResult.TearDown;
begin
  FreeAndNil(FSchema);
end;

procedure TTestJsonSchemaMethodResult.TestProcedureHasNoResultSchema;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('NoParams'));
  Assert.IsNull(FSchema);
end;

procedure TTestJsonSchemaMethodResult.TestResultTypeIsDescribed;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('Add'));
  Assert.IsNotNull(FSchema);
  Assert.AreEqual('number', FSchema.GetValue('type').Value);
end;

procedure TTestJsonSchemaMethodResult.TestMethodTagsApplyToResult;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('Total'));
  Assert.AreEqual('integer', FSchema.GetValue('type').Value);
  Assert.AreEqual('The sum', FSchema.GetValue('description').Value);
  Assert.AreEqual(0.0, (FSchema.GetValue('minimum') as TJSONNumber).AsDouble, 0.0);
end;

procedure TTestJsonSchemaMethodResult.TestRecordResultIsAnObject;
var
  LProps: TJSONObject;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('GetPoint'));
  Assert.AreEqual('object', FSchema.GetValue('type').Value);
  LProps := FSchema.GetValue('properties') as TJSONObject;
  Assert.IsNotNull(LProps.GetValue('X'));
  Assert.IsNotNull(LProps.GetValue('Y'));
end;

procedure TTestJsonSchemaMethodResult.TestResultWithoutSchemaIsNil;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('GetEvent'));
  Assert.IsNull(FSchema);
end;

procedure TTestJsonSchemaMethodResult.TestRecursiveResultCarriesDefinitions;
var
  LInstance: TJSONValue;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('GetTree'), TNeonJSchemaVersion.v202012);
  Assert.IsNotNull(FSchema.GetValue('$defs'));
  Assert.AreEqual('https://json-schema.org/draft/2020-12/schema', FSchema.GetValue('$schema').Value);

  LInstance := TJSONObject.ParseJSONValue('{"Name":"a","Children":[{"Name":"b","Children":[]}]}');
  try
    Assert.IsTrue(TNeon.ValidateJSON(LInstance, FSchema).IsValid);
  finally
    LInstance.Free;
  end;
end;

procedure TTestJsonSchemaMethodResult.TestDraft07RecursiveResultWrapsRefInAllOf;
var
  LAllOf: TJSONArray;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('GetTree'), TNeonJSchemaVersion.Draft07);
  Assert.IsNotNull(FSchema.GetValue('definitions'));
  Assert.IsNull(FSchema.GetValue('$ref'), 'a Draft-07 "$ref" would hide its sibling definitions');
  LAllOf := FSchema.GetValue('allOf') as TJSONArray;
  Assert.IsNotNull(LAllOf);
  Assert.AreEqual('#/definitions/TSchemaMethodNode',
    (LAllOf.Items[0] as TJSONObject).GetValue('$ref').Value);
end;

procedure TTestJsonSchemaMethodResult.TestNoVersionOmitsSchemaKeyword;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('Add'));
  Assert.IsNull(FSchema.GetValue('$schema'));
end;

procedure TTestJsonSchemaMethodResult.TestResultTypeOverrideKeepsMethodTags;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('Total'),
    TRttiContext.Create.GetType(TypeInfo(Double)), TNeonConfiguration.Default);
  Assert.AreEqual('number', FSchema.GetValue('type').Value, 'the type given, not the one declared');
  Assert.AreEqual('The sum', FSchema.GetValue('description').Value, 'the method''s tags still apply');
end;

procedure TTestJsonSchemaMethodResult.TestNilResultTypeGivesNil;
begin
  FSchema := TNeonSchemaGenerator.MethodResultToSchema(Method('Total'), nil, TNeonConfiguration.Default);
  Assert.IsNull(FSchema);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJsonSchemaMethodParams);
  TDUnitX.RegisterTestFixture(TTestJsonSchemaMethodResult);

end.
