{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}

/// <summary>
///   Two entities to try things out on: one record and one class. Add a
///   member here, run the demo, look at the JSON.
/// </summary>
unit Playground.Entities;

{$I Neon.inc}

interface

uses
  System.SysUtils, System.Classes,

  Neon.Core.Types,
  Neon.Core.Types.Schema,
  Neon.Core.Attributes;

type
  /// <summary>
  ///   Serialized by its name ("Gold"), not by its ordinal
  /// </summary>
  TCustomerLevel = (Bronze, Silver, Gold);

  TTestId = TAnyOf<Int64, string>;

  /// <summary>
  ///   The record entity: with the default configuration Neon reads the
  ///   *fields* of a record, so there is nothing to declare beyond them
  /// </summary>
  TAddress = record
    Id: TTestId;
    Street: string;
    City: string;

    [NeonProperty('zip')]
    ZipCode: string;

    Country: string;
  end;

  /// <summary>
  ///   The class entity: with the default configuration Neon reads the
  ///   *public and published properties*, not the fields behind them
  /// </summary>
  TCustomer = class
  private
    FId: TTestId;
    FName: string;
    FLevel: TCustomerLevel;
    FActive: Boolean;
    FBalance: Double;
    FCreatedAt: TDateTime;
    FAddress: TAddress;
    FTags: TArray<string>;
    FPasswordHash: string;
    FFakeField: TDateTime;
  public
    procedure SetMultipleField(AValue: TDateTime);

    property Id: TTestId read FId write FId;

    /// <summary>
    ///   Renames the member on both sides of the round trip
    /// </summary>
    [NeonProperty('customer_name')]
    property Name: string read FName write FName;

    property Level: TCustomerLevel read FLevel write FLevel;

    property Active: Boolean read FActive write FActive;
    property Balance: Double read FBalance write FBalance;

    /// <summary>
    ///   Written as ISO8601, in UTC unless the configuration says otherwise
    /// </summary>
    [NeonSetter('SetMultipleField')]
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;

    /// <summary>
    ///   A record inside a class: it becomes a nested JSON object
    /// </summary>
    property Address: TAddress read FAddress write FAddress;

    /// <summary>
    ///   Left out of the JSON when the array is empty
    /// </summary>
    [NeonInclude(IncludeIf.NotEmpty)]
    property Tags: TArray<string> read FTags write FTags;

    /// <summary>
    ///   Never written, never read
    /// </summary>
    [NeonIgnore]
    property PasswordHash: string read FPasswordHash write FPasswordHash;
  end;





implementation

{ TCustomer }

procedure TCustomer.SetMultipleField(AValue: TDateTime);
begin
  FCreatedAt := AValue;
  FFakeField := AValue;
end;

end.
