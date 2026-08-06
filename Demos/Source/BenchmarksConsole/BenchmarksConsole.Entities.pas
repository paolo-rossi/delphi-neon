{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit BenchmarksConsole.Entities;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,

  Neon.Core.Attributes;

type
  /// <summary>
  ///   Address type used by the complex PODO (TCustomer)
  /// </summary>
  TAddressType = (atPersonal, atWork, atBilling, atShipping);

  /// <summary>
  ///   Nested value object used by TCustomer
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

  /// <summary>
  ///   Small, flat PODO: a handful of simple-type properties, no nesting
  /// </summary>
  TSimpleUser = class
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
  TSimpleUserArray = TArray<TSimpleUser>;

  /// <summary>
  ///   Order status enum used by the complex PODO (TCustomer)
  /// </summary>
  TOrderStatus = (osNew, osProcessing, osShipped, osDelivered, osCancelled);

  /// <summary>
  ///   Nested object contained in the TCustomer.Items array
  /// </summary>
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
  ///   Complex PODO: nested objects (Address), an array of nested objects
  ///   (Items), an enum (Status) and a string/string map (Metadata)
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
    property Items: TOrderItems read FItems write FItems;
    property Metadata: TDictionary<string, string> read FMetadata write FMetadata;
  end;
  TCustomerArray = TArray<TCustomer>;

  /// <summary>
  ///   Envelope (contains only an array) for TSimpleUser: a bare JSON array
  ///   at the root is awkward to round-trip identically across all three
  ///   libraries, so every dataset is wrapped in a single "Items" property.
  /// </summary>
  TSimpleUsersEnvelope = class
  private
    FItems: TSimpleUserArray;
  public
    destructor Destroy; override;

    procedure Clear;

    property Items: TSimpleUserArray read FItems write FItems;
  end;

  /// <summary>
  ///   Envelope (contains only an array) for TCustomer
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
  ///   Deterministic synthetic-data generator, so every library serializes
  ///   and deserializes exactly the same payload
  /// </summary>
  TEntityFactory = class
    class function CreateSimpleUsers(ACount: Integer): TSimpleUsersEnvelope; static;
    class function CreateCustomers(ACount: Integer): TCustomersEnvelope; static;
  end;

implementation

{ TCustomer }

procedure TCustomer.ClearItems;
var
  LItem: TOrderItem;
begin
  for LItem in FItems do
    LItem.Free;
  FItems := nil;
end;

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

{ TSimpleUsersEnvelope }

procedure TSimpleUsersEnvelope.Clear;
var
  LItem: TSimpleUser;
begin
  for LItem in FItems do
    LItem.Free;
end;

destructor TSimpleUsersEnvelope.Destroy;
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
end;

destructor TCustomersEnvelope.Destroy;
begin
  Clear;
  inherited;
end;

{ TEntityFactory }

class function TEntityFactory.CreateSimpleUsers(ACount: Integer): TSimpleUsersEnvelope;
var
  LUser: TSimpleUser;
  LIndex: Integer;
begin
  Result := TSimpleUsersEnvelope.Create;

  for LIndex := 0 to ACount - 1 do
  begin
    LUser := TSimpleUser.Create;
    LUser.ID := LIndex + 1;
    LUser.Name := Format('User %d', [LIndex + 1]);
    LUser.Email := Format('user%d@example.com', [LIndex + 1]);
    LUser.BirthDate := EncodeDate(1970, 1, 1) + (LIndex mod 18000);
    LUser.Active := (LIndex mod 3) <> 0;
    LUser.Score := (LIndex mod 100) / 3.7;

    Result.Items := Result.Items + [LUser];
  end;
end;

class function TEntityFactory.CreateCustomers(ACount: Integer): TCustomersEnvelope;
const
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
    LCustomer.Metadata.Add('lastReviewDate', FormatDateTime('yyyy-mm-dd', EncodeDate(2025, 1, 1) + (LIndex mod 365)));

    Result.Items := Result.Items + [LCustomer];
  end;
end;

end.
