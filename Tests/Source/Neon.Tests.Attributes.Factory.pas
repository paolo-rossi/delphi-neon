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
unit Neon.Tests.Attributes.Factory;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON,
  System.Generics.Collections,
  DUnitX.TestFramework,

  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Tests.Entities,
  Neon.Tests.Utils,
  Neon.Data.Tests;

type
  TPet = class
  private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  TCat = class(TPet)
  private
    FMood: string;
  public
    property Mood: string read FMood write FMood;
  end;

  TDog = class(TPet)
  private
    FBreed: string;
  public
    property Breed: string read FBreed write FBreed;
  end;

  TWatchDog = class(TDog)
  private
    FStrength: Integer;
  public
    property Strength: Integer read FStrength write FStrength;
  end;

  TPetClass = class of TPet;

  TPetFactory = class(TCustomFactory)
  public
    function Build(const AType: TRttiType; AValue: TJSONValue): TObject; override;
  end;

  TFixedPetFactory = class(TCustomFactory)
  public
    function Build(const AType: TRttiType; AValue: TJSONValue): TObject; override;
  end;

  TObjFactory = class(TCustomFactory)
  public
    function Build(const AType: TRttiType; AValue: TJSONValue): TObject; override;
  end;

  TPetList = TObjectList<TPet>;
  TPetArray = TArray<TPet>;
  TPetStatic = array[0..2] of TPet;
  TPetDict = TObjectDictionary<string, TPet>;

  TFactoryTestObj = class
  private
    FTestObj: TObject;
  public
    [NeonFactory(TObjFactory)]
    property Obj: TObject read FTestObj write FTestObj;
  end;

  TFactoryTestList = class
  private
    FPets: TPetList;
  public
    constructor Create;
    destructor Destroy; override;

    function HasItemOfType(AClass: TPetClass): Boolean;

    [NeonItemFactory(TPetFactory)]
    property Pets: TPetList read FPets write FPets;
  end;

  TFactoryTestDict = class
  private
    FPets: TPetDict;
  public
    constructor Create;
    destructor Destroy; override;

    function HasItemOfType(AClass: TPetClass): Boolean;

    [NeonItemFactory(TPetFactory)]
    property Pets: TPetDict read FPets write FPets;
  end;

  TFactoryTestArray = class
  private
    FPets: TPetArray;
    FOtherPets: TPetArray;
  public
    destructor Destroy; override;

    function HasItemOfType(const AList: TPetArray; AClass: TPetClass): Boolean;

    [NeonItemFactory(TPetFactory)]
    property Pets: TPetArray read FPets write FPets;

    [NeonItemFactory(TFixedPetFactory)]
    property OtherPets: TPetArray read FOtherPets write FOtherPets;
  end;

  TFactoryTestStatic = class
  private
    FPets: TPetStatic;
  public
    destructor Destroy; override;

    function HasItemOfType(AClass: TPetClass): Boolean;

    [NeonItemFactory(TPetFactory)]
    property Pets: TPetStatic read FPets write FPets;
  end;

  [TestFixture]
  [Category('items')]
  TTestItemFactory = class(TObject)
  private
    FNeonConfig: INeonConfiguration;
    FTestObj: TFactoryTestObj;
    FItemsArray: TFactoryTestArray;
    FItemsStatic: TFactoryTestStatic;
    FItemsList: TFactoryTestList;
    FItemsDict: TFactoryTestDict;
  public
    constructor Create;
    destructor Destroy; override;
  public
    [TestCase('TestObj', '{"Obj":{"Breed":"Bulldog"}}|Bulldog', '|')]
    procedure TestObjType(const AInput, ABreed: string);
  public
    [TestCase('TestArrayItemType', '{"Pets":[{"$Type":0,"Name":"Ant"},{"$Type":1,"Name":"Cat"},{"$Type":3,"Name":"WatchDog"}],"OtherPets":[{"$Type":1,"Name":"Cat"},{"$Type":3,"Name":"WatchDog"},{"$Type":0,"Name":"Ant"}]}', '|')]
    procedure TestArrayItemType(const AInput: string);

    [TestCase('TestArrayItemValues', '{"Pets":[{"$Type":3,"Name":"WatchDog","Race":"German shepherd","Strength":12},{"$Type":3,"Name":"WatchDog","Race":"Bulldog","Strength":14}]}|26', '|')]
    procedure TestArrayItemValues(const AInput: string; _Result: Integer);
  public
    [TestCase('TestStaticItemType', '{"Pets":[{"$Type":0,"Name":"Ant"},{"$Type":1,"Name":"Cat","Mood":"Sleepy"},{"$Type":3,"Name":"WatchDog","Breed":"Bulldog","Strength":12}]}', '|')]
    procedure TestStaticItemType(const AInput: string);

    [TestCase('TestStaticItemValues', '{"Pets":[{"$Type":0,"Name":"Ant"},{"$Type":3,"Name":"WatchDog","Race":"German shepherd","Strength":12},{"$Type":3,"Name":"WatchDog","Race":"Bulldog","Strength":14}]}|26', '|')]
    procedure TestStaticItemValues(const AInput: string; _Result: Integer);
  public
    [TestCase('TestListItemType', '{"Pets":[{"$Type":0,"Name":"Ant"},{"$Type":1,"Name":"Cat","Mood":"Sleepy"},{"$Type":3,"Name":"WatchDog","Breed":"Bulldog","Strength":12}]}', '|')]
    procedure TestListItemType(const AInput: string);

    [TestCase('TestListItemValues', '{"Pets":[{"$Type":3,"Name":"WatchDog","Race":"German shepherd","Strength":12},{"$Type":3,"Name":"WatchDog","Race":"Bulldog","Strength":14}]}|26', '|')]
    procedure TestListItemValues(const AInput: string; _Result: Integer);
  public
    [TestCase('TestDictItemType', '{"Pets":{"ant":{"$Type":0,"Name":"Ant"},"cat":{"$Type":1,"Name":"Cat","Mood":"Sleepy"},"watchdog":{"$Type":3,"Name":"WatchDog","Breed":"Bulldog","Strength":12}}}', '|')]
    procedure TestDictItemType(const AInput: string);

    [TestCase('TestDictItemValues', '{"Pets":{"dog1":{"$Type":3,"Name":"WatchDog","Race":"German shepherd","Strength":12},"dog2":{"$Type":3,"Name":"WatchDog","Race":"Bulldog","Strength":14}}}|26', '|')]
    procedure TestDictItemValues(const AInput: string; _Result: Integer);
  end;

implementation

uses
  Neon.Core.Serializers.RTL,
  Neon.Serializers.Tests;

{ TTestItemFactory }

constructor TTestItemFactory.Create;
begin
  FNeonConfig := TNeonConfiguration.Default
    .RegisterFactory(TPetFactory)
    .RegisterFactory(TObjFactory)
  ;
  FTestObj := TFactoryTestObj.Create;
  FItemsArray := TFactoryTestArray.Create;
  FItemsStatic := TFactoryTestStatic.Create;
  FItemsList := TFactoryTestList.Create;
  FItemsDict := TFactoryTestDict.Create;
end;

destructor TTestItemFactory.Destroy;
begin
  FTestObj.Free;
  FItemsArray.Free;
  FItemsStatic.Free;
  FItemsList.Free;
  FItemsDict.Free;
  inherited;
end;

procedure TTestItemFactory.TestArrayItemType(const AInput: string);
begin
  TTestUtils.DeserializeObject(AInput, FItemsArray, FNeonConfig);

  Assert.IsTrue(FItemsArray.HasItemOfType(FItemsArray.Pets, TCat));
  Assert.IsTrue(FItemsArray.HasItemOfType(FItemsArray.Pets, TWatchDog));

  Assert.IsTrue(FItemsArray.OtherPets[0].ClassName = 'TDog');
  Assert.IsTrue(FItemsArray.OtherPets[1].ClassName = 'TDog');
  Assert.IsTrue(FItemsArray.OtherPets[2].ClassName = 'TDog');
end;

procedure TTestItemFactory.TestArrayItemValues(const AInput: string; _Result: Integer);
var
  LPet: TPet;
  LResult: Integer;
begin
  LResult := 0;
  TTestUtils.DeserializeObject(AInput, FItemsArray, FNeonConfig);

  for LPet in FItemsArray.Pets do
    if LPet is TWatchDog then
      LResult := LResult + (LPet as TWatchDog).FStrength;
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestItemFactory.TestDictItemType(const AInput: string);
begin
  TTestUtils.DeserializeObject(AInput, FItemsDict, FNeonConfig);
  Assert.IsTrue(FItemsDict.HasItemOfType(TCat));
  Assert.IsTrue(FItemsDict.HasItemOfType(TWatchDog));
end;

procedure TTestItemFactory.TestDictItemValues(const AInput: string; _Result: Integer);
var
  LPet: TPair<string, TPet>;
  LResult: Integer;
begin
  LResult := 0;
  TTestUtils.DeserializeObject(AInput, FItemsDict, FNeonConfig);

  for LPet in FItemsDict.Pets do
    if LPet.Value is TWatchDog then
      LResult := LResult + (LPet.Value as TWatchDog).FStrength;
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestItemFactory.TestListItemType(const AInput: string);
begin
  TTestUtils.DeserializeObject(AInput, FItemsList, FNeonConfig);
  Assert.IsTrue(FItemsList.HasItemOfType(TCat));
  Assert.IsTrue(FItemsList.HasItemOfType(TWatchDog));
end;

procedure TTestItemFactory.TestListItemValues(const AInput: string; _Result: Integer);
var
  LPet: TPet;
  LResult: Integer;
begin
  LResult := 0;
  TTestUtils.DeserializeObject(AInput, FItemsList, FNeonConfig);

  for LPet in FItemsList.Pets do
    if LPet is TWatchDog then
      LResult := LResult + (LPet as TWatchDog).FStrength;
  Assert.AreEqual(_Result, LResult);
end;

procedure TTestItemFactory.TestObjType(const AInput, ABreed: string);
begin
  TTestUtils.DeserializeObject(AInput, FTestObj, FNeonConfig);
  Assert.IsTrue(FTestObj.Obj is TDog);
  Assert.IsTrue((FTestObj.Obj as TDog).Breed = ABreed);
end;

procedure TTestItemFactory.TestStaticItemType(const AInput: string);
begin
  TTestUtils.DeserializeObject(AInput, FItemsStatic, FNeonConfig);
  Assert.IsTrue(FItemsStatic.Pets[1] is TCat);
  Assert.IsTrue(FItemsStatic.Pets[2] is TWatchDog);
end;

procedure TTestItemFactory.TestStaticItemValues(const AInput: string; _Result: Integer);
var
  LPet: TPet;
  LResult: Integer;
begin
  LResult := 0;
  TTestUtils.DeserializeObject(AInput, FItemsStatic, FNeonConfig);

  for LPet in FItemsStatic.Pets do
    if LPet is TWatchDog then
      LResult := LResult + (LPet as TWatchDog).FStrength;
  Assert.AreEqual(_Result, LResult);
end;

{ TPetFactory }

function TPetFactory.Build(const AType: TRttiType; AValue: TJSONValue): TObject;
var
  LTypeInt: Integer;
begin
  if AValue.TryGetValue<Integer>('$Type', LTypeInt)  then
  begin
    case LTypeInt of
      0: Exit(TPet.Create);
      1: Exit(TCat.Create);
      2: Exit(TDog.Create);
      3: Exit(TWatchDog.Create);
    end;
  end;

  Result := TPet.Create;
end;

{ TFixedPetFactory }

function TFixedPetFactory.Build(const AType: TRttiType; AValue: TJSONValue): TObject;
begin
  Result := TDog.Create;
end;


{ TObjFactory }

function TObjFactory.Build(const AType: TRttiType; AValue: TJSONValue): TObject;
begin
  Result := TDog.Create;
end;

{ TFactoryTestDict }

constructor TFactoryTestDict.Create;
begin
  FPets := TPetDict.Create([doOwnsValues]);
end;

destructor TFactoryTestDict.Destroy;
begin
  FPets.Free;
  inherited;
end;

function TFactoryTestDict.HasItemOfType(AClass: TPetClass): Boolean;
var
  LPet: TPair<string, TPet>;
begin
  for LPet in Pets do
    if LPet.Value is AClass then
      Exit(True);

  Result := False;
end;

{ TFactoryTestList }

constructor TFactoryTestList.Create;
begin
  FPets := TPetList.Create(True);
end;

destructor TFactoryTestList.Destroy;
begin
  FPets.Free;
  inherited;
end;

function TFactoryTestList.HasItemOfType(AClass: TPetClass): Boolean;
var
  LPet: TPet;
begin
  for LPet in Pets do
    if LPet is AClass then
      Exit(True);

  Result := False;
end;

{ TFactoryTestArray }

destructor TFactoryTestArray.Destroy;
var
  LPet: TObject;
begin
  for LPet in Pets do
    LPet.Free;
  inherited;
end;

function TFactoryTestArray.HasItemOfType(const AList: TPetArray; AClass: TPetClass): Boolean;
var
  LPet: TPet;
begin
  for LPet in AList do
    if LPet is AClass then
      Exit(True);

  Result := False;
end;

{ TFactoryTestStatic }

destructor TFactoryTestStatic.Destroy;
var
  LPet: TObject;
begin
  for LPet in Pets do
    LPet.Free;
  inherited;
end;

function TFactoryTestStatic.HasItemOfType(AClass: TPetClass): Boolean;
var
  LPet: TPet;
begin
  for LPet in Pets do
    if LPet is AClass then
      Exit(True);

  Result := False;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestItemFactory);

end.
