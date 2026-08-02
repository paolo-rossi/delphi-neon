{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Tags;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Types,
  Neon.Core.Tags;

type
  TTagsTestFields = class
  public
    Name: string;
    Age: Integer;
    Active: Boolean;
  end;

  TTagsTestProps = class
  private
    FName: string;
    FAge: Integer;
  public
    property Name: string read FName write FName;
    property Age: Integer read FAge write FAge;
    // Read-only: a matching tag must be skipped, not raise
    property Label_: string read FName;
  end;

  [TestFixture]
  [Category('tags')]
  TTestAttributeTags = class(TObject)
  private
    FTags: TAttributeTags;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestKeyValue;

    [Test]
    procedure TestBareFlagIsBoolTrue;

    [Test]
    procedure TestMissingKey;

    [Test]
    procedure TestGetValueAsTypes;

    [Test]
    procedure TestQuotedValueWithSeparator;

    [Test]
    procedure TestEscapedQuoteInsideValue;

    [Test]
    procedure TestReParseIsIdempotent;

    [Test]
    procedure TestDuplicateKeyInSameString;

    [Test]
    procedure TestMalformedTagRaises;

    [Test]
    procedure TestApplyToFields;

    [Test]
    procedure TestApplyToPropsSkipsReadOnly;

    [Test]
    procedure TestApplyToFieldsRejectsNonClassNonRecord;

    [Test]
    procedure TestCloneCopiesTagsAndSettings;

    [Test]
    procedure TestCloneIsIndependentOfSource;

    [Test]
    procedure TestCopyFromReplacesExistingTags;
  end;

implementation

procedure TTestAttributeTags.Setup;
begin
  FTags := TAttributeTags.Create;
end;

procedure TTestAttributeTags.TearDown;
begin
  FTags.Free;
end;

procedure TTestAttributeTags.TestKeyValue;
begin
  FTags.Parse('description=A name,required');
  Assert.IsTrue(FTags.Exists('description'));
  Assert.IsTrue(FTags.Exists('required'));
  Assert.AreEqual('A name', FTags.GetValueAs<string>('description'));
  Assert.AreEqual(2, FTags.Count);
end;

procedure TTestAttributeTags.TestBareFlagIsBoolTrue;
begin
  FTags.Parse('enabled');
  Assert.IsTrue(FTags.Exists('enabled'));
  Assert.IsTrue(FTags.GetBoolValue('enabled'));
end;

procedure TTestAttributeTags.TestMissingKey;
begin
  FTags.Parse('description=A name');
  Assert.IsFalse(FTags.Exists('missing'));
  Assert.IsFalse(FTags.GetBoolValue('missing'));
end;

procedure TTestAttributeTags.TestGetValueAsTypes;
begin
  FTags.Parse('age=42,active=true,ratio=1.5');
  Assert.AreEqual(42, FTags.GetValueAs<Integer>('age'));
  Assert.AreEqual(True, FTags.GetValueAs<Boolean>('active'));
  Assert.AreEqual(1.5, FTags.GetValueAs<Double>('ratio'), 0.0001);
end;

procedure TTestAttributeTags.TestQuotedValueWithSeparator;
begin
  FTags.Parse('description="Hello, World",required');
  Assert.AreEqual('Hello, World', FTags.GetValueAs<string>('description'));
  Assert.IsTrue(FTags.Exists('required'));
  Assert.AreEqual(2, FTags.Count);
end;

procedure TTestAttributeTags.TestEscapedQuoteInsideValue;
begin
  FTags.Parse('note="She said \"hi\""');
  Assert.AreEqual('She said "hi"', FTags.GetValueAs<string>('note'));
end;

procedure TTestAttributeTags.TestReParseIsIdempotent;
begin
  FTags.Parse('a=1,b=2');
  FTags.Parse('a=1,b=2');
  Assert.AreEqual(2, FTags.Count);
  Assert.AreEqual(1, FTags.GetValueAs<Integer>('a'));
end;

procedure TTestAttributeTags.TestDuplicateKeyInSameString;
begin
  FTags.Parse('a=1,a=2,a=3');
  Assert.AreEqual(1, FTags.Count);
  Assert.AreEqual(3, FTags.GetValueAs<Integer>('a'));
end;

procedure TTestAttributeTags.TestMalformedTagRaises;
begin
  Assert.WillRaise(
    procedure begin FTags.Parse('a=1=2') end,
    ENeonException
  );
end;

procedure TTestAttributeTags.TestApplyToFields;
var
  LEntity: TTagsTestFields;
begin
  FTags.Parse('Name=John,Age=42,Active=true');
  LEntity := TTagsTestFields.Create;
  try
    FTags.ApplyToFields(LEntity);
    Assert.AreEqual('John', LEntity.Name);
    Assert.AreEqual(42, LEntity.Age);
    Assert.IsTrue(LEntity.Active);
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributeTags.TestApplyToPropsSkipsReadOnly;
var
  LEntity: TTagsTestProps;
begin
  // "Label_" has no setter: must be silently skipped, not raise
  FTags.Parse('Name=Jane,Age=7,Label_=ignored');
  LEntity := TTagsTestProps.Create;
  try
    FTags.ApplyToProps(LEntity);
    Assert.AreEqual('Jane', LEntity.Name);
    Assert.AreEqual(7, LEntity.Age);
  finally
    LEntity.Free;
  end;
end;

procedure TTestAttributeTags.TestApplyToFieldsRejectsNonClassNonRecord;
var
  LValue: TValue;
begin
  FTags.Parse('a=1');
  LValue := 123;
  Assert.WillRaise(
    procedure begin FTags.ApplyToFields(LValue) end,
    ENeonException
  );
end;

procedure TTestAttributeTags.TestCloneCopiesTagsAndSettings;
var
  LSource, LClone: TAttributeTags;
begin
  LSource := TAttributeTags.Create(';', ':');
  try
    LSource.Parse('description:A name;required');
    LClone := LSource.Clone;
    try
      Assert.AreEqual('A name', LClone.GetValueAs<string>('description'));
      Assert.IsTrue(LClone.Exists('required'));
      Assert.AreEqual(2, LClone.Count);

      // Custom separators must have been copied too
      LClone.Parse('a:1;b:2');
      Assert.AreEqual(1, LClone.GetValueAs<Integer>('a'));
      Assert.AreEqual(2, LClone.GetValueAs<Integer>('b'));
    finally
      LClone.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TTestAttributeTags.TestCloneIsIndependentOfSource;
var
  LClone: TAttributeTags;
begin
  FTags.Parse('a=1');
  LClone := FTags.Clone;
  try
    FTags.Parse('a=2,b=3');

    Assert.AreEqual(1, LClone.GetValueAs<Integer>('a'));
    Assert.IsFalse(LClone.Exists('b'));
  finally
    LClone.Free;
  end;
end;

procedure TTestAttributeTags.TestCopyFromReplacesExistingTags;
var
  LOther: TAttributeTags;
begin
  FTags.Parse('old=1');

  LOther := TAttributeTags.Create;
  try
    LOther.Parse('new=2,another=3');
    FTags.CopyFrom(LOther);

    Assert.IsFalse(FTags.Exists('old'));
    Assert.AreEqual(2, FTags.GetValueAs<Integer>('new'));
    Assert.AreEqual(3, FTags.GetValueAs<Integer>('another'));
    Assert.AreEqual(2, FTags.Count);
  finally
    LOther.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAttributeTags);

end.
