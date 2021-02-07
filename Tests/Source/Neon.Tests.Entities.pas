{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2019 Paolo Rossi                                         }
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
unit Neon.Tests.Entities;

interface

{$INCLUDE ..\Source\Neon.inc}

uses
  System.SysUtils, System.Classes, System.Generics.Collections,

  Neon.Core.Attributes,
  Neon.Core.Nullables;

{$SCOPEDENUMS ON}

type
  TResponseType = (Ignore, Confirm, Decline);

  [NeonEnumNames('Low Speed,Medium Speed,Very High Speed')]
  TSpeedType = (Low, Medium, High);
  TSpeedSet = set of TSpeedType;
  TSpeedArray = TArray<TSpeedType>;

  TContactType = (Phone, Email, Skype);

  TSimpleRecord = record
    Name: string;
    BirthDate: TDateTime;
    Age: Integer;
  end;

  TManagedRecord = record
    Name: string;
    Age: Integer;
    Height: Double;
    {$IFDEF HAS_MRECORDS}
    class operator Initialize (out Dest: TManagedRecord);
    class operator Finalize (var Dest: TManagedRecord);
    {$ENDIF}
  end;

  TRecordInsideClass = class
  private
    FManagedRecord: TManagedRecord;
    FSimpleRecord: TSimpleRecord;
  public
    property SimpleRecord: TSimpleRecord read FSimpleRecord write FSimpleRecord;
    property ManagedRecord: TManagedRecord read FManagedRecord write FManagedRecord;
  end;

  TContact = class
  private
    FContactType: TContactType;
    FNumber: string;
  public
    property ContactType: TContactType read FContactType write FContactType;
    property Number: string read FNumber write FNumber;
  end;

  TAddress = class
  private
    FCity: string;
    FCountry: string;
    FPrimary: Boolean;
    FStreet: string;
  public
    property Street: string read FStreet write FStreet;
    property City: string read FCity write FCity;
    property Country: string read FCountry write FCountry;
    property Primary: Boolean read FPrimary write FPrimary;
  end;

  TPerson = class
  private
    FName: string;
    FAge: Integer;
    FAddresses: TArray<TAddress>;
    FContacts: TObjectList<TContact>;
  public
    constructor Create(const AName: string; AAge: Integer);
    destructor Destroy; override;

    function AddAddress(const AStreet, ACity, ACountry: string; APrimary: Boolean): TAddress;
    function AddContact(AType: TContactType; const ANumber: string): TContact;

    property Name: string read FName write FName;
    property Age: Integer read FAge write FAge;
    property Addresses: TArray<TAddress> read FAddresses write FAddresses;
    property Contacts: TObjectList<TContact> read FContacts write FContacts;
  end;

  /// <summary>
  ///   Entity to test the MemberCase configuration
  /// </summary>
  TCaseClass = class
  private
    FFirstName: string;
    FGender: string;
    Flastname: string;
    FCOUNTRY: string;
    F_Age_: Integer;
  public
    constructor Create(const AFirstName, ALastName, AGender, ACountry: string; AAge: Integer);
  public
    property FirstName: string read FFirstName write FFirstName;
    property lastname: string read Flastname write Flastname;
    property _Age_: Integer read F_Age_ write F_Age_;
    property Gender: string read FGender write FGender;
    property COUNTRY: string read FCOUNTRY write FCOUNTRY;
  end;

  /// <summary>
  ///   Entity to test the NeonInclude attribute (IncludeIf enum)
  /// </summary>
  TNeonIncludeEntity = class
  private
    FNullObject1: TObject;
    FNullObject2: TObject;
    FNString: NullString;
    FNInteger: NullInteger;
  public
    [NeonInclude(IncludeIf.Always)]
    property NullObject1: TObject read FNullObject1 write FNullObject1;
    [NeonInclude(IncludeIf.NotNull)]
    property NullObject2: TObject read FNullObject2 write FNullObject2;
    [NeonInclude(IncludeIf.NotEmpty)]
    property NString: NullString read FNString write FNString;
    [NeonInclude(IncludeIf.NotDefault)]
    property NInteger: NullInteger read FNInteger write FNInteger;
  end;

implementation

{ TPerson }

function TPerson.AddAddress(const AStreet, ACity, ACountry: string; APrimary: Boolean): TAddress;
begin
  Result := TAddress.Create;
  Result.Street := AStreet;
  Result.City := ACity;
  Result.Country := ACountry;
  Result.Primary := APrimary;
  FAddresses := FAddresses + [Result];
end;

function TPerson.AddContact(AType: TContactType; const ANumber: string): TContact;
begin
  Result := TContact.Create;
  Result.ContactType := AType;
  Result.Number := ANumber;
  FContacts.Add(Result);
end;

constructor TPerson.Create(const AName: string; AAge: Integer);
begin
  FContacts := TObjectlist<TContact>.Create(True);

  FName := AName;
  FAge := AAge;
end;

destructor TPerson.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := Length(FAddresses) - 1 downto 0 do
    FAddresses[LIndex].Free;

  FContacts.Free;
  inherited;
end;

{ TCaseClass }

constructor TCaseClass.Create(const AFirstName, ALastName, AGender,
  ACountry: string; AAge: Integer);
begin
  FFirstName := AFirstName;
  Flastname := ALastName;
  F_Age_ := AAge;
  FGender := AGender;
  FCOUNTRY := ACountry;
end;

{$IFDEF HAS_MRECORDS}

{ TManagedRecord }

class operator TManagedRecord.Initialize(out Dest: TManagedRecord);
begin
  Dest.Name := '';
  Dest.Age := 0;
  Dest.Height := 0;
end;

class operator TManagedRecord.Finalize(var Dest: TManagedRecord);
begin

end;

{$ENDIF}
end.
