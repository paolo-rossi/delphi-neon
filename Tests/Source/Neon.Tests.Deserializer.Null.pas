{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Deserializer.Null;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON,
  System.Generics.Collections, DUnitX.TestFramework,

  Neon.Core.Nullables,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Types;

type
  TNullInner = class
  private
    FCode: Integer;
  public
    property Code: Integer read FCode write FCode;
  end;

  TNullHolder = class
  private
    FName: string;
    FCount: Integer;
    FInner: TNullInner;
    FItems: TList<Integer>;
    FNick: Nullable<string>;
  public
    constructor Create;
    destructor Destroy; override;

    property Name: string read FName write FName;
    property Count: Integer read FCount write FCount;
    property Inner: TNullInner read FInner write FInner;
    property Items: TList<Integer> read FItems write FItems;
    property Nick: Nullable<string> read FNick write FNick;
  end;

  TNullItem = class
  private
    FId: Integer;
  public
    property Id: Integer read FId write FId;
  end;

  TNullItemHolder = class
  private
    FItems: TObjectList<TNullItem>;
  public
    constructor Create;
    destructor Destroy; override;

    property Items: TObjectList<TNullItem> read FItems write FItems;
  end;

  /// <summary>
  ///   What a JSON null and an empty object/array mean for a member: they used
  ///   to be skipped, so a value the document states explicitly could not
  ///   clear, create or empty anything
  /// </summary>
  [TestFixture]
  [Category('nullvalues')]
  TTestDeserializerNull = class(TObject)
  private
    FHolder: TNullHolder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNullClearsStringMember;

    [Test]
    procedure TestNullClearsIntegerMember;

    [Test]
    procedure TestNullClearsNullableMember;

    [Test]
    procedure TestNullKeepsObjectMember;

    [Test]
    procedure TestEmptyStringIsAssigned;

    [Test]
    procedure TestEmptyArrayEmptiesTheList;

    [Test]
    procedure TestEmptyObjectCreatesTheMember;

    [Test]
    procedure TestNullListItemIsNil;
  end;

implementation

{ TNullHolder }

constructor TNullHolder.Create;
begin
  FItems := TList<Integer>.Create;
end;

destructor TNullHolder.Destroy;
begin
  FInner.Free;
  FItems.Free;
  inherited;
end;

{ TNullItemHolder }

constructor TNullItemHolder.Create;
begin
  FItems := TObjectList<TNullItem>.Create(True);
end;

destructor TNullItemHolder.Destroy;
begin
  FItems.Free;
  inherited;
end;

{ TTestDeserializerNull }

procedure TTestDeserializerNull.Setup;
begin
  FHolder := TNullHolder.Create;
end;

procedure TTestDeserializerNull.TearDown;
begin
  FHolder.Free;
end;

procedure TTestDeserializerNull.TestNullClearsStringMember;
begin
  FHolder.Name := 'Paolo';
  TNeon.JSONToObject(FHolder, '{"Name":null}', TNeonConfiguration.Default);
  Assert.AreEqual('', FHolder.Name, 'null must clear the member, not keep it');
end;

procedure TTestDeserializerNull.TestNullClearsIntegerMember;
begin
  FHolder.Count := 42;
  TNeon.JSONToObject(FHolder, '{"Count":null}', TNeonConfiguration.Default);
  Assert.AreEqual(0, FHolder.Count);
end;

procedure TTestDeserializerNull.TestNullClearsNullableMember;
begin
  FHolder.Nick := 'Paul';
  Assert.IsTrue(FHolder.Nick.HasValue, 'the Nullable starts with a value');

  TNeon.JSONToObject(FHolder, '{"Nick":null}', TNeonConfiguration.Default);
  Assert.IsFalse(FHolder.Nick.HasValue, 'null must empty the Nullable');
end;

procedure TTestDeserializerNull.TestNullKeepsObjectMember;
begin
  // Neon does not own what a member points to, so a null cannot clear an object
  // reference without leaking it: the reference is documented to survive
  FHolder.Inner := TNullInner.Create;
  FHolder.Inner.Code := 7;

  TNeon.JSONToObject(FHolder, '{"Inner":null}', TNeonConfiguration.Default);

  Assert.IsNotNull(FHolder.Inner, 'null must not nil (and leak) an object member');
  Assert.AreEqual(7, FHolder.Inner.Code);
end;

procedure TTestDeserializerNull.TestEmptyStringIsAssigned;
begin
  // Pins the neighbouring case: an empty string was never part of the skip, and
  // must keep being assigned now that the filter is gone
  FHolder.Name := 'Paolo';
  TNeon.JSONToObject(FHolder, '{"Name":""}', TNeonConfiguration.Default);
  Assert.AreEqual('', FHolder.Name, 'an empty string is a value, not a missing member');
end;

procedure TTestDeserializerNull.TestEmptyArrayEmptiesTheList;
begin
  FHolder.Items.AddRange([1, 2, 3]);
  TNeon.JSONToObject(FHolder, '{"Items":[]}', TNeonConfiguration.Default);
  Assert.AreEqual(0, FHolder.Items.Count, 'an empty array must empty the list');
end;

procedure TTestDeserializerNull.TestEmptyObjectCreatesTheMember;
var
  LConfig: INeonConfiguration;
begin
  // An empty object still declares the member: it used to count as "nothing to
  // read" and left the member nil even with AutoCreate on
  LConfig := TNeonConfiguration.Default.SetAutoCreate(True);

  Assert.IsNull(FHolder.Inner, 'the member starts nil');
  TNeon.JSONToObject(FHolder, '{"Inner":{}}', LConfig);
  Assert.IsNotNull(FHolder.Inner, '{} must create the member');
end;

procedure TTestDeserializerNull.TestNullListItemIsNil;
var
  LHolder: TNullItemHolder;
begin
  // A null item has no object to read into: it used to be replaced by a freshly
  // created, empty instance, which is indistinguishable from a real {} item
  LHolder := TNullItemHolder.Create;
  try
    TNeon.JSONToObject(LHolder, '{"Items":[null,{"Id":2}]}', TNeonConfiguration.Default);

    Assert.AreEqual(2, LHolder.Items.Count);
    Assert.IsNull(LHolder.Items[0], 'a null item must stay nil');
    Assert.IsNotNull(LHolder.Items[1]);
    Assert.AreEqual(2, LHolder.Items[1].Id);
  finally
    LHolder.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeserializerNull);

end.
