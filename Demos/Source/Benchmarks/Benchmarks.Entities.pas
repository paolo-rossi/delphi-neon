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
  end;

  /// <summary>
  ///   Simple User class for benchmarks
  /// </summary>
  TUser = class
  private
    FBirthDate: TDateTime;
    FID: Integer;
    FName: string;
  public
    property ID: Integer read FID write FID;
    property Name: string read FName write FName;
    property BirthDate: TDateTime read FBirthDate write FBirthDate;
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
  public
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
    FEMail: string;
    FPhone: string;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Dept: TDepartment read FDept write FDept;
    property Name: string read FName write FName;
    property EMail: string read FEMail write FEMail;
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
    FID: string;
    FContacts: TContacts;
    FCompanyName: string;
    FAddress: TAddress;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ClearContacts;
  public
    property ID: string read FID write FID;
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
