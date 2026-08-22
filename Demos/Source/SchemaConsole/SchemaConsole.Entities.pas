{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}
unit SchemaConsole.Entities;

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,

  Neon.Core.Attributes,
  Neon.Core.Persistence.JSON.Schema;

type
  /// <summary>
  ///   Serialized by its name, so the generator describes it as a "string" with
  ///   an "enum" of the four names
  /// </summary>
  TOrderStatus = (Pending, Paid, Shipped, Cancelled);

  /// <summary>
  ///   The [JsonSchema] tags are what turns a plain Delphi type into a
  ///   *constrained* schema: without them the generator can only say "string",
  ///   with them it can say how long a string may be and what it must look like
  /// </summary>
  TAddress = class
  private
    FStreet: string;
    FCity: string;
    FZipCode: string;
    FCountry: string;
  public
    [JsonSchema('required,description=Street and house number,minLength=3,maxLength=80')]
    property Street: string read FStreet write FStreet;

    [JsonSchema('required,minLength=2,maxLength=60')]
    property City: string read FCity write FCity;

    // A value containing the tag separator (the comma of {2,4}, a comma in a
    // description, ...) has to be quoted, or the tag parser would split on it
    [JsonSchema('required,description=Five-digit postal code,pattern="^[0-9]{5}$"')]
    property ZipCode: string read FZipCode write FZipCode;

    [JsonSchema('required,description=ISO 3166-1 alpha-2 code,pattern="^[A-Z]{2}$"')]
    property Country: string read FCountry write FCountry;
  end;

  TOrderItem = class
  private
    FSku: string;
    FDescription: string;
    FQuantity: Integer;
    FUnitPrice: Double;
  public
    [JsonSchema('required,description=Stock keeping unit,pattern="^SKU-[0-9]{4}$"')]
    property Sku: string read FSku write FSku;

    [JsonSchema('required,minLength=1,maxLength=120')]
    property Description: string read FDescription write FDescription;

    [JsonSchema('required,description=Pieces ordered,minimum=1.0,maximum=100.0')]
    property Quantity: Integer read FQuantity write FQuantity;

    [JsonSchema('required,description=Price of one piece,exclusiveMinimum=0.0,maximum=100000.0')]
    property UnitPrice: Double read FUnitPrice write FUnitPrice;
  end;

  TCustomer = class
  private
    FId: Integer;
    FFullName: string;
    FEmail: string;
    FBillingAddress: TAddress;
    FShippingAddress: TAddress;
  public
    constructor Create;
    destructor Destroy; override;

    [JsonSchema('required,minimum=1.0')]
    property Id: Integer read FId write FId;

    [JsonSchema('required,minLength=2,maxLength=100')]
    property FullName: string read FFullName write FFullName;

    [JsonSchema('required,pattern="^[^@ ]+@[^@ ]+\.[a-z]{2,}$"')]
    property Email: string read FEmail write FEmail;

    [JsonSchema('required')]
    property BillingAddress: TAddress read FBillingAddress write FBillingAddress;

    /// <summary>
    ///   Not in the schema's "required" list, and [NeonInclude] keeps it out of
    ///   the document altogether when there is no separate shipping address:
    ///   the two annotations have to agree, or a valid object would produce an
    ///   invalid document (a "null" where the schema asks for an object)
    /// </summary>
    [NeonInclude(IncludeIf.NotNull)]
    [JsonSchema('description=Only present when it differs from the billing one')]
    property ShippingAddress: TAddress read FShippingAddress write FShippingAddress;
  end;

  [JsonSchema('title=Customer order,description=One order as accepted by the API')]
  TOrder = class
  private
    FOrderId: string;
    FCreatedAt: TDateTime;
    FStatus: TOrderStatus;
    FCustomer: TCustomer;
    FItems: TObjectList<TOrderItem>;
    FTotal: Double;
    FNotes: string;
  public
    constructor Create;
    destructor Destroy; override;

    [JsonSchema('required,pattern="^ORD-[0-9]{6}$"')]
    property OrderId: string read FOrderId write FOrderId;

    [JsonSchema('required,description=When the order was accepted')]
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;

    [JsonSchema('required')]
    property Status: TOrderStatus read FStatus write FStatus;

    [JsonSchema('required')]
    property Customer: TCustomer read FCustomer write FCustomer;

    [JsonSchema('required,minItems=1,maxItems=20,description=At least one line')]
    property Items: TObjectList<TOrderItem> read FItems;

    [JsonSchema('required,minimum=0.0')]
    property Total: Double read FTotal write FTotal;

    [JsonSchema('maxLength=500')]
    property Notes: string read FNotes write FNotes;
  end;

  /// <summary>
  ///   A type that contains itself. The generator cannot inline it (it would
  ///   never stop), so it moves the schema into "$defs" and leaves a "$ref"
  ///   behind - which is exactly what the recursion needs to be expressible
  /// </summary>
  [JsonSchema('title=Category tree')]
  TCategory = class
  private
    FName: string;
    FChildren: TObjectList<TCategory>;
  public
    constructor Create(const AName: string = '');
    destructor Destroy; override;

    function AddChild(const AName: string): TCategory;

    [JsonSchema('required,minLength=1,maxLength=40')]
    property Name: string read FName write FName;

    [JsonSchema('description="Sub-categories, empty for a leaf"')]
    property Children: TObjectList<TCategory> read FChildren;
  end;

implementation

{ TCustomer }

constructor TCustomer.Create;
begin
  inherited Create;
  FBillingAddress := TAddress.Create;
end;

destructor TCustomer.Destroy;
begin
  FShippingAddress.Free;
  FBillingAddress.Free;
  inherited;
end;

{ TOrder }

constructor TOrder.Create;
begin
  inherited Create;
  FCustomer := TCustomer.Create;
  FItems := TObjectList<TOrderItem>.Create(True);
end;

destructor TOrder.Destroy;
begin
  FItems.Free;
  FCustomer.Free;
  inherited;
end;

{ TCategory }

constructor TCategory.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FChildren := TObjectList<TCategory>.Create(True);
end;

destructor TCategory.Destroy;
begin
  FChildren.Free;
  inherited;
end;

function TCategory.AddChild(const AName: string): TCategory;
begin
  Result := TCategory.Create(AName);
  FChildren.Add(Result);
end;

end.
