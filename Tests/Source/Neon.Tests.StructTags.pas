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
unit Neon.Tests.StructTags;

interface

uses
  System.SysUtils, DUnitX.TestFramework,

  Neon.Core.Tags;

type
  [TestFixture]
  [Category('tags')]
  TTestStructTag = class(TObject)
  private
    FTag: TStructTag;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestMultiGroupParse;

    [Test]
    procedure TestLookupPresentKey;

    [Test]
    procedure TestLookupMissingKey;

    [Test]
    procedure TestGetMissingKeyReturnsEmpty;

    [Test]
    procedure TestExists;

    [Test]
    procedure TestEscapedQuoteInsideGroupValue;

    [Test]
    procedure TestEmptyRawString;

    [Test]
    procedure TestMalformedTrailingContentIsTolerated;

    [Test]
    procedure TestGetAttributeTagsLayering;

    [Test]
    procedure TestGetAttributeTagsForMissingGroupIsEmpty;
  end;

implementation

procedure TTestStructTag.TearDown;
begin
  FTag.Free;
  FTag := nil;
end;

procedure TTestStructTag.TestMultiGroupParse;
begin
  FTag := TStructTag.Parse('json:"name,omitempty" validate:"required,min=1" xml:"-"');
  Assert.AreEqual('name,omitempty', FTag.Get('json'));
  Assert.AreEqual('required,min=1', FTag.Get('validate'));
  Assert.AreEqual('-', FTag.Get('xml'));
end;

procedure TTestStructTag.TestLookupPresentKey;
var
  LValue: string;
begin
  FTag := TStructTag.Parse('json:"name"');
  Assert.IsTrue(FTag.Lookup('json', LValue));
  Assert.AreEqual('name', LValue);
end;

procedure TTestStructTag.TestLookupMissingKey;
var
  LValue: string;
begin
  FTag := TStructTag.Parse('json:"name"');
  Assert.IsFalse(FTag.Lookup('xml', LValue));
end;

procedure TTestStructTag.TestGetMissingKeyReturnsEmpty;
begin
  FTag := TStructTag.Parse('json:"name"');
  Assert.AreEqual('', FTag.Get('xml'));
end;

procedure TTestStructTag.TestExists;
begin
  FTag := TStructTag.Parse('json:"name"');
  Assert.IsTrue(FTag.Exists('json'));
  Assert.IsFalse(FTag.Exists('xml'));
end;

procedure TTestStructTag.TestEscapedQuoteInsideGroupValue;
begin
  FTag := TStructTag.Parse('note:"She said \"hi\""');
  Assert.AreEqual('She said "hi"', FTag.Get('note'));
end;

procedure TTestStructTag.TestEmptyRawString;
begin
  FTag := TStructTag.Parse('');
  Assert.IsFalse(FTag.Exists('json'));
  Assert.AreEqual('', FTag.Get('json'));
end;

procedure TTestStructTag.TestMalformedTrailingContentIsTolerated;
begin
  FTag := TStructTag.Parse('good:"value" trailing-garbage-without-quotes');
  Assert.AreEqual('value', FTag.Get('good'));
end;

procedure TTestStructTag.TestGetAttributeTagsLayering;
var
  LValidate: TAttributeTags;
begin
  FTag := TStructTag.Parse('validate:"required,min=1"');
  LValidate := FTag.GetAttributeTags('validate');
  try
    Assert.IsTrue(LValidate.Exists('required'));
    Assert.AreEqual(1, LValidate.GetValueAs<Integer>('min'));
  finally
    LValidate.Free;
  end;
end;

procedure TTestStructTag.TestGetAttributeTagsForMissingGroupIsEmpty;
var
  LValidate: TAttributeTags;
begin
  FTag := TStructTag.Parse('json:"name"');
  LValidate := FTag.GetAttributeTags('validate');
  try
    Assert.AreEqual(0, LValidate.Count);
  finally
    LValidate.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStructTag);

end.
