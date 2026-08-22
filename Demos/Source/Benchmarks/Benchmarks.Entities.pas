{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Benchmarks.Entities;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Neon.Core.Attributes;

type
  /// <summary>
  ///   Base class for the envelope. The "envelope" is needed in order to be
  ///   able to use TJSON on arrays
  /// </summary>
  TEnvelope = class
    procedure Clear; virtual; abstract;

    /// <summary>
    ///   First element of the envelope, nil when it holds none. Lets the
    ///   benchmark write out a single entity without knowing which kind of
    ///   envelope it is holding.
    /// </summary>
    function FirstItem: TObject; virtual; abstract;
  end;

  TDevLanguage = (Delphi, Go, Java, CSharp, Cpp);

  /// <summary>
  ///   Simple User class for benchmarks
  /// </summary>
  TUser = class
  private
    FId: Integer;
    FName: string;
    FBirthDate: TDate;
    FLanguage: TDevLanguage;
  public
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property BirthDate: TDate read FBirthDate write FBirthDate;
    property Language: TDevLanguage read FLanguage write FLanguage;
  end;
  TUsers = TArray<TUser>;
  TUserList = TObjectList<TUser>;

  /// <summary>
  ///   Envelope (contains only an array) for the class TUser
  /// </summary>
  TUsersEnvelope = class(TEnvelope)
  private
    FItems: TUsers;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;
    function FirstItem: TObject; override;
  public
    property Items: TUsers read FItems write FItems;
  end;

  TAddressType = (Personal, Work);

  /// <summary>
  ///   Address class
  /// </summary>
  TAddress = class
  private
    FAddressType: TAddressType;
    FStreet: string;
    FCity: string;
    FValidFrom: TDate;
  public
    property ValidFrom: TDate read FValidFrom write FValidFrom;
    property AddressType: TAddressType read FAddressType write FAddressType;
    property Street: string read FStreet write FStreet;
    property City: string read FCity write FCity;
  end;
  TAddresses = TArray<TAddress>;
  TAddressList = TObjectList<TAddress>;

  TDepartment = (HR, Sales, Marketing, Accounting);

  /// <summary>
  ///   Contact class
  /// </summary>
  TContact = class
  private
    FDept: TDepartment;
    FName: string;
    FAddress: TAddress;
    FEmail: string;
    FPhone: string;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Dept: TDepartment read FDept write FDept;
    property Name: string read FName write FName;
    property Email: string read FEmail write FEmail;
    property Phone: string read FPhone write FPhone;
    property Address: TAddress read FAddress write FAddress;
  end;
  TContacts = TArray<TContact>;
  TContactList = TObjectList<TContact>;

  /// <summary>
  ///   Complex TCustomer class for benchmarks
  /// </summary>
  TCustomer = class
  private
    FId: string;
    FContacts: TContacts;
    FCompanyName: string;
    FAddress: TAddress;
    FInsertDate: TDate;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ClearContacts;
  public
    property Id: string read FId write FId;
    property InsertDate: TDate read FInsertDate write FInsertDate;
    property CompanyName: string read FCompanyName write FCompanyName;
    property Address: TAddress read FAddress write FAddress;
    property Contacts: TContacts read FContacts write FContacts;
  end;
  TCustomers = TArray<TCustomer>;
  TCustomerList = TObjectList<TCustomer>;

  /// <summary>
  ///   Envelope (contains only an array) for the class TCustomer
  /// </summary>
  TCustomersEnvelope = class(TEnvelope)
  private
    FItems: TCustomers;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    function FirstItem: TObject; override;

    property Items: TCustomers read FItems write FItems;
  end;

implementation

{ TContact }

constructor TContact.Create;
begin
  FAddress := TAddress.Create;
end;

destructor TContact.Destroy;
begin
  FAddress.Free;
  inherited;
end;

{ TCustomer }

procedure TCustomer.ClearContacts;
var
  LContact: TContact;
begin
  for LContact in FContacts do
    LContact.Free;
  FContacts := [];
end;

constructor TCustomer.Create;
begin
  FAddress := TAddress.Create;
end;

destructor TCustomer.Destroy;
begin
  FAddress.Free;
  ClearContacts;
  inherited;
end;

{ TCustomersEnvelope }

procedure TCustomersEnvelope.Clear;
var
  LCustomer: TCustomer;
begin
  for LCustomer in FItems do
    LCustomer.Free;
  FItems := [];
end;

function TCustomersEnvelope.FirstItem: TObject;
begin
  if Length(FItems) = 0 then
    Result := nil
  else
    Result := FItems[0];
end;

constructor TCustomersEnvelope.Create;
begin
  FItems := [];
end;

destructor TCustomersEnvelope.Destroy;
begin
  Clear;

  inherited;
end;

{ TUsersEnvelope }

procedure TUsersEnvelope.Clear;
var
  LUser: TUser;
begin
  for LUser in FItems do
    LUser.Free;
  FItems := [];
end;

function TUsersEnvelope.FirstItem: TObject;
begin
  if Length(FItems) = 0 then
    Result := nil
  else
    Result := FItems[0];
end;

constructor TUsersEnvelope.Create;
begin
  FItems := [];
end;

destructor TUsersEnvelope.Destroy;
begin
  Clear;

  inherited;
end;

end.
