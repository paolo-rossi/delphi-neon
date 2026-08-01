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
unit Neon.Tests.JsonSchema;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  DUnitX.TestFramework,
  Neon.Core.Persistence.JSON.Schema;

type
  TSchemaPerson = class
  private
    FName: string;
    FAge: Integer;
    FEmail: string;
    FNickname: string;
  public
    [JsonSchema('description=The person''s full name,required')]
    property Name: string read FName write FName;

    [JsonSchema('readOnly')]
    property Age: Integer read FAge write FAge;

    property Email: string read FEmail write FEmail;

    // Description value contains the tag separator (comma) and must be quoted
    [JsonSchema('description="A name, informally"')]
    property Nickname: string read FNickname write FNickname;
  end;

  [TestFixture]
  [Category('jsonschema')]
  TTestJsonSchemaAttribute = class(TObject)
  public
    [Test]
    procedure TestParseTagsExposesTags;

    [Test]
    procedure TestParseTagsIsIdempotent;
  end;

  [TestFixture]
  [Category('jsonschema')]
  TTestJsonSchemaGenerator = class(TObject)
  private
    FSchema: TJSONObject;
    function Properties: TJSONObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestObjectType;

    [Test]
    procedure TestDescriptionIsApplied;

    [Test]
    procedure TestDescriptionWithQuotedCommaIsApplied;

    [Test]
    procedure TestRequiredMemberIsMovedToTopLevelArray;

    [Test]
    procedure TestRequiredKeyIsRemovedFromMemberSchema;

    [Test]
    procedure TestReadOnlyIsApplied;

    [Test]
    procedure TestMemberWithoutAttributeHasNoExtraKeys;
  end;

implementation

{ TTestJsonSchemaAttribute }

procedure TTestJsonSchemaAttribute.TestParseTagsExposesTags;
var
  LAttribute: JsonSchemaAttribute;
begin
  LAttribute := JsonSchemaAttribute.Create('description=Foo,required');
  try
    LAttribute.ParseTags;
    Assert.IsTrue(LAttribute.Tags.Exists('description'));
    Assert.AreEqual('Foo', LAttribute.Tags.GetValueAs<string>('description'));
    Assert.IsTrue(LAttribute.Tags.Exists('required'));
  finally
    LAttribute.Free;
  end;
end;

procedure TTestJsonSchemaAttribute.TestParseTagsIsIdempotent;
var
  LAttribute: JsonSchemaAttribute;
begin
  LAttribute := JsonSchemaAttribute.Create('description=Foo,required');
  try
    LAttribute.ParseTags;
    LAttribute.ParseTags;
    Assert.AreEqual(2, LAttribute.Tags.Count);
  finally
    LAttribute.Free;
  end;
end;

{ TTestJsonSchemaGenerator }

function TTestJsonSchemaGenerator.Properties: TJSONObject;
begin
  Result := FSchema.GetValue('properties') as TJSONObject;
end;

procedure TTestJsonSchemaGenerator.Setup;
begin
  FSchema := TNeonSchemaGenerator.ClassToJSONSchema(TSchemaPerson);
end;

procedure TTestJsonSchemaGenerator.TearDown;
begin
  FSchema.Free;
end;

procedure TTestJsonSchemaGenerator.TestObjectType;
begin
  Assert.AreEqual('object', FSchema.GetValue('type').Value);
  Assert.IsNotNull(Properties);
end;

procedure TTestJsonSchemaGenerator.TestDescriptionIsApplied;
var
  LName: TJSONObject;
begin
  LName := Properties.GetValue('Name') as TJSONObject;
  Assert.IsNotNull(LName);
  Assert.AreEqual('The person''s full name', LName.GetValue('description').Value);
end;

procedure TTestJsonSchemaGenerator.TestDescriptionWithQuotedCommaIsApplied;
var
  LNickname: TJSONObject;
begin
  LNickname := Properties.GetValue('Nickname') as TJSONObject;
  Assert.IsNotNull(LNickname);
  Assert.AreEqual('A name, informally', LNickname.GetValue('description').Value);
end;

procedure TTestJsonSchemaGenerator.TestRequiredMemberIsMovedToTopLevelArray;
var
  LRequired: TJSONArray;
begin
  LRequired := FSchema.GetValue('required') as TJSONArray;
  Assert.IsNotNull(LRequired);
  Assert.AreEqual(1, LRequired.Count);
  Assert.AreEqual('Name', LRequired.Items[0].Value);
end;

procedure TTestJsonSchemaGenerator.TestRequiredKeyIsRemovedFromMemberSchema;
var
  LName: TJSONObject;
begin
  LName := Properties.GetValue('Name') as TJSONObject;
  Assert.IsNull(LName.GetValue('required'));
end;

procedure TTestJsonSchemaGenerator.TestReadOnlyIsApplied;
var
  LAge: TJSONObject;
begin
  LAge := Properties.GetValue('Age') as TJSONObject;
  Assert.IsNotNull(LAge);
  Assert.IsTrue((LAge.GetValue('readOnly') as TJSONBool).AsBoolean);
end;

procedure TTestJsonSchemaGenerator.TestMemberWithoutAttributeHasNoExtraKeys;
var
  LEmail: TJSONObject;
begin
  LEmail := Properties.GetValue('Email') as TJSONObject;
  Assert.IsNotNull(LEmail);
  Assert.IsNull(LEmail.GetValue('description'));
  Assert.IsNull(LEmail.GetValue('required'));
  Assert.IsNull(LEmail.GetValue('readOnly'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJsonSchemaAttribute);
  TDUnitX.RegisterTestFixture(TTestJsonSchemaGenerator);

end.
