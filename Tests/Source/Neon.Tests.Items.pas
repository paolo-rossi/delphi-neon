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
unit Neon.Tests.Items;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON,

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

  TPetFactory = class(TCustomItemFactory)
  public
    function Build(const AType: TRttiType; AValue: TJSONValue): TObject; override;
  end;


  TAnimals = class
  private
    FPets: TArray<TPet>;
  public
    //constructor Create;
    //destructor Destroy; override;

    function HasItemOfType(AClass: TPetClass): Boolean;

    [NeonItemFactory(TPetFactory)]
    property Pets: TArray<TPet> read FPets write FPets;
  end;


  [TestFixture]
  [Category('items')]
  TTestItemFactory = class(TObject)
  public
    // Bytes Tests
    [Test]
    [TestCase('TestPets', '{"Pets":[{"$Type":0,"Name":"Ant"},{"$Type":1,"Name":"Cat","Mood":"Sleepy"},{"$Type":3,"Name":"WatchDog","Breed":"Bulldog","Strength":12}]}', '|')]
    procedure TestItemType(const AInput: string);

    [TestCase('TestItemValues', '{"Pets":[{"$Type":3,"Name":"WatchDog","Race":"German shepherd","Strength":12},{"$Type":3,"Name":"WatchDog","Race":"Bulldog","Strength":14}]}|26', '|')]
    procedure TestItemValues(const AInput: string; _Result: Integer);
  end;



implementation

uses
  Neon.Core.Serializers.RTL,
  Neon.Serializers.Tests;

{ TTestItemFactory }

procedure TTestItemFactory.TestItemType(const AInput: string);
var
  LAnimals: TAnimals;
  LConf: INeonConfiguration;
begin
  LConf := TNeonConfiguration.Default;
  LConf.RegisterItemFactory(TPetFactory);

  LAnimals := TAnimals.Create;
  try
    TTestUtils.DeserializeObject(AInput, LAnimals, LConf);
    Assert.IsTrue(LAnimals.HasItemOfType(TCat));
    Assert.IsTrue(LAnimals.HasItemOfType(TWatchDog));
  finally
    LAnimals.Free;
  end;
end;

procedure TTestItemFactory.TestItemValues(const AInput: string; _Result: Integer);
var
  LAnimals: TAnimals;
  LConf: INeonConfiguration;
  LPet: TPet;
  LResult: Integer;
begin
  LResult := 0;
  LConf := TNeonConfiguration.Default;
  LConf.RegisterItemFactory(TPetFactory);

  LAnimals := TAnimals.Create;
  try
    TTestUtils.DeserializeObject(AInput, LAnimals, LConf);
    for LPet in LAnimals.Pets do
      if LPet is TWatchDog then
        LResult := LResult + (LPet as TWatchDog).FStrength;
    Assert.AreEqual(_Result, LResult);
  finally
    LAnimals.Free;
  end;
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

{ TAnimals }

function TAnimals.HasItemOfType(AClass: TPetClass): Boolean;
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
