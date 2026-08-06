{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                              }
{  Licensed under the MIT license                                             }
{                                                                              }
{******************************************************************************}
unit ProfilingConsole.Entities;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  /// <summary>
  ///   Small, flat PODO with no nested objects, arrays or maps, so a profile
  ///   of its (de)serialization isolates Neon's baseline per-call overhead
  ///   (RTTI resolve, attribute parsing, member iteration) from the extra
  ///   cost of handling composite members.
  /// </summary>
  TPerson = class
  private
    FID: Integer;
    FName: string;
    FEmail: string;
    FBirthDate: TDateTime;
    FActive: Boolean;
    FScore: Double;
  public
    property ID: Integer read FID write FID;
    property Name: string read FName write FName;
    property Email: string read FEmail write FEmail;
    property BirthDate: TDateTime read FBirthDate write FBirthDate;
    property Active: Boolean read FActive write FActive;
    property Score: Double read FScore write FScore;
  end;
  TPersonArray = TArray<TPerson>;

  TAddressType = (atPersonal, atWork, atBilling, atShipping);

  /// <summary>
  ///   Nested value object: exercises the Serialize:Object / Deserialize:Object
  ///   path for a member (not just for the root instance).
  /// </summary>
  TAddress = class
  private
    FStreet: string;
    FCity: string;
    FZipCode: string;
    FCountry: string;
    FAddressType: TAddressType;
  public
    property Street: string read FStreet write FStreet;
    property City: string read FCity write FCity;
    property ZipCode: string read FZipCode write FZipCode;
    property Country: string read FCountry write FCountry;
    property AddressType: TAddressType read FAddressType write FAddressType;
  end;

  TOrderStatus = (osNew, osProcessing, osShipped, osDelivered, osCancelled);

  TOrderItem = class
  private
    FSKU: string;
    FDescription: string;
    FQuantity: Integer;
    FUnitPrice: Currency;
  public
    property SKU: string read FSKU write FSKU;
    property Description: string read FDescription write FDescription;
    property Quantity: Integer read FQuantity write FQuantity;
    property UnitPrice: Currency read FUnitPrice write FUnitPrice;
  end;
  TOrderItems = TArray<TOrderItem>;

  /// <summary>
  ///   Composite PODO: nested object, array of nested objects, array of
  ///   primitives, enum and a string/string map. Every one of those members
  ///   goes through the per-element WriteDataMember/ReadDataMember entry
  ///   overload and the (uncached) TDynamic*.GuessType probes, so this is the
  ///   type that makes Serialize:RttiResolve and Dynamic:Guess* visible.
  /// </summary>
  TCustomer = class
  private
    FID: string;
    FCompanyName: string;
    FCreditLimit: Double;
    FIsActive: Boolean;
    FStatus: TOrderStatus;
    FBillingAddress: TAddress;
    FShippingAddress: TAddress;
    FTags: TArray<string>;
    FItems: TOrderItems;
    FMetadata: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ClearItems;
  public
    property ID: string read FID write FID;
    property CompanyName: string read FCompanyName write FCompanyName;
    property CreditLimit: Double read FCreditLimit write FCreditLimit;
    property IsActive: Boolean read FIsActive write FIsActive;
    property Status: TOrderStatus read FStatus write FStatus;
    property BillingAddress: TAddress read FBillingAddress write FBillingAddress;
    property ShippingAddress: TAddress read FShippingAddress write FShippingAddress;
    property Tags: TArray<string> read FTags write FTags;
    property Items: TOrderItems read FItems write FItems;
    property Metadata: TDictionary<string, string> read FMetadata write FMetadata;
  end;
  TCustomerArray = TArray<TCustomer>;

  /// <summary>
  ///   Envelope holding many TPerson. Serializing this in ONE call is what
  ///   exercises the per-type member caches: TNeon.ObjectToJSON builds a fresh
  ///   TNeonSerializerJSON (and therefore a fresh member registry) per call, so
  ///   the caches only amortize across the objects written within a single call.
  /// </summary>
  TPeopleEnvelope = class
  private
    FItems: TPersonArray;
  public
    destructor Destroy; override;

    procedure Clear;

    property Items: TPersonArray read FItems write FItems;
  end;

  /// <summary>
  ///   Envelope holding many TCustomer
  /// </summary>
  TCustomersEnvelope = class
  private
    FItems: TCustomerArray;
  public
    destructor Destroy; override;

    procedure Clear;

    property Items: TCustomerArray read FItems write FItems;
  end;

  /// <summary>
  ///   Deterministic synthetic-data generator, so every profiling run works on
  ///   exactly the same payload
  /// </summary>
  TEntityFactory = class
    class function CreatePerson(AIndex: Integer = 0): TPerson; static;
    class function CreatePeople(ACount: Integer): TPeopleEnvelope; static;
    class function CreateCustomers(ACount: Integer): TCustomersEnvelope; static;
  end;

implementation

{ TCustomer }

constructor TCustomer.Create;
begin
  FBillingAddress := TAddress.Create;
  FShippingAddress := TAddress.Create;
  FMetadata := TDictionary<string, string>.Create;
end;

destructor TCustomer.Destroy;
begin
  ClearItems;
  FBillingAddress.Free;
  FShippingAddress.Free;
  FMetadata.Free;

  inherited;
end;

procedure TCustomer.ClearItems;
var
  LItem: TOrderItem;
begin
  for LItem in FItems do
    LItem.Free;
  FItems := nil;
end;

{ TPeopleEnvelope }

procedure TPeopleEnvelope.Clear;
var
  LItem: TPerson;
begin
  for LItem in FItems do
    LItem.Free;
  FItems := nil;
end;

destructor TPeopleEnvelope.Destroy;
begin
  Clear;
  inherited;
end;

{ TCustomersEnvelope }

procedure TCustomersEnvelope.Clear;
var
  LItem: TCustomer;
begin
  for LItem in FItems do
    LItem.Free;
  FItems := nil;
end;

destructor TCustomersEnvelope.Destroy;
begin
  Clear;
  inherited;
end;

{ TEntityFactory }

class function TEntityFactory.CreatePerson(AIndex: Integer): TPerson;
begin
  Result := TPerson.Create;
  Result.ID := AIndex + 1;
  Result.Name := Format('Person %d', [AIndex + 1]);
  Result.Email := Format('person%d@example.com', [AIndex + 1]);
  Result.BirthDate := EncodeDate(1970, 1, 1) + (AIndex mod 18000);
  Result.Active := (AIndex mod 3) <> 0;
  Result.Score := (AIndex mod 100) / 3.7;
end;

class function TEntityFactory.CreatePeople(ACount: Integer): TPeopleEnvelope;
var
  LIndex: Integer;
begin
  Result := TPeopleEnvelope.Create;

  for LIndex := 0 to ACount - 1 do
    Result.Items := Result.Items + [CreatePerson(LIndex)];
end;

class function TEntityFactory.CreateCustomers(ACount: Integer): TCustomersEnvelope;
const
  TAGS: array [0..4] of string = ('vip', 'wholesale', 'retail', 'eu', 'partner');
  STATUSES: array [0..4] of TOrderStatus = (osNew, osProcessing, osShipped, osDelivered, osCancelled);
  ITEMS_PER_CUSTOMER = 5;
var
  LCustomer: TCustomer;
  LOrderItem: TOrderItem;
  LIndex, LItemIndex: Integer;
begin
  Result := TCustomersEnvelope.Create;

  for LIndex := 0 to ACount - 1 do
  begin
    LCustomer := TCustomer.Create;
    LCustomer.ID := Format('CUST-%.6d', [LIndex + 1]);
    LCustomer.CompanyName := Format('Company %d Ltd.', [LIndex + 1]);
    LCustomer.CreditLimit := 1000 + (LIndex mod 50) * 250.5;
    LCustomer.IsActive := (LIndex mod 4) <> 0;
    LCustomer.Status := STATUSES[LIndex mod Length(STATUSES)];

    LCustomer.BillingAddress.Street := Format('%d Main St', [LIndex + 1]);
    LCustomer.BillingAddress.City := 'Springfield';
    LCustomer.BillingAddress.ZipCode := Format('%.5d', [10000 + LIndex]);
    LCustomer.BillingAddress.Country := 'US';
    LCustomer.BillingAddress.AddressType := atBilling;

    LCustomer.ShippingAddress.Street := Format('%d Elm St', [LIndex + 1]);
    LCustomer.ShippingAddress.City := 'Shelbyville';
    LCustomer.ShippingAddress.ZipCode := Format('%.5d', [20000 + LIndex]);
    LCustomer.ShippingAddress.Country := 'US';
    LCustomer.ShippingAddress.AddressType := atShipping;

    LCustomer.Tags := [TAGS[LIndex mod 5], TAGS[(LIndex + 1) mod 5], TAGS[(LIndex + 2) mod 5]];

    for LItemIndex := 0 to ITEMS_PER_CUSTOMER - 1 do
    begin
      LOrderItem := TOrderItem.Create;
      LOrderItem.SKU := Format('SKU-%.4d-%d', [LIndex + 1, LItemIndex]);
      LOrderItem.Description := Format('Product %d variant %d', [LIndex + 1, LItemIndex]);
      LOrderItem.Quantity := (LItemIndex + 1) * 2;
      LOrderItem.UnitPrice := 9.99 + LItemIndex * 5.5;

      LCustomer.Items := LCustomer.Items + [LOrderItem];
    end;

    LCustomer.Metadata.Add('accountManager', Format('Manager %d', [(LIndex mod 10) + 1]));
    LCustomer.Metadata.Add('segment', TAGS[LIndex mod 5]);
    LCustomer.Metadata.Add('lastReviewDate', FormatDateTime('yyyy-mm-dd', EncodeDate(2025, 1, 1) + (LIndex mod 365)));

    Result.Items := Result.Items + [LCustomer];
  end;
end;

end.
