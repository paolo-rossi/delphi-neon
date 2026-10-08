{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                }
{  Copyright (c) 2018 Paolo Rossi                                             }
{  https://github.com/paolo-rossi/neon-library                                }
{                                                                             }
{  Licensed under the MIT license                                             }
{                                                                             }
{******************************************************************************}
program Playground;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON,

  Neon.Core.Types,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Neon.Core.Serializers.RTL,

  Playground.Entities in 'Playground.Entities.pas';

const
  /// <summary>
  ///   The documents the deserialization half reads: edit them and run again
  /// </summary>
  ADDRESS_JSON =
    '{"Id":1969,"Street":"Piazza Duomo 1","City":"Milano","zip":"20121","Country":"IT"}';

  CUSTOMER_JSON =
    '{' +
    '  "ID": 7,' +
    '  "customer_name": "Marco Bianchi",' +
    '  "Level": "Silver",' +
    '  "Active": false,' +
    '  "Balance": 42.5,' +
    '  "CreatedAt": "2026-03-01T08:30:00.000Z",' +
    '  "Address": {"Street":"Corso Italia 5","City":"Torino","zip":"10121","Country":"IT"},' +
    '  "Tags": ["eu", "trial"],' +
    '  "PasswordHash": "ignored, [NeonIgnore] keeps it out of the object"' +
    '}';

var
  LAddress: TAddress;
  LCustomer: TCustomer;
  LJSON: TJSONValue;
  LConfig: INeonConfiguration;
begin
  ReportMemoryLeaksOnShutdown := True;


  LConfig := TNeonConfiguration
    .Default
    .RegisterSerializer(TTValueSerializer);


  try
    // -------------------------------------------------------------- record --
    LAddress.Id := 123;
    LAddress.Street := 'Via Emilia 1';
    LAddress.City := 'Piacenza';
    LAddress.ZipCode := '29122';
    LAddress.Country := 'IT';

    LJSON := TNeon.ValueToJSON(TValue.From<TAddress>(LAddress), LConfig);
    try
      Writeln('TAddress -> JSON');
      Writeln(TNeon.Print(LJSON, True));
    finally
      LJSON.Free;
    end;
    Writeln;

    LAddress := TNeon.JSONToValue<TAddress>(ADDRESS_JSON, LConfig);
    Writeln('JSON -> TAddress');
    Writeln(Format('  Id: %s, City: %s, ZipCode: %s', [LAddress.Id.ToString, LAddress.City, LAddress.ZipCode]));
    Writeln;

    // --------------------------------------------------------------- class --
    LCustomer := TCustomer.Create;
    try
      LCustomer.ID := 42;
      LCustomer.Name := 'Paolo Rossi';
      LCustomer.Level := TCustomerLevel.Gold;
      LCustomer.Active := True;
      LCustomer.Balance := 1250.75;
      LCustomer.CreatedAt := EncodeDate(2026, 8, 27) + EncodeTime(10, 15, 0, 0);
      LCustomer.Address := LAddress;
      LCustomer.Tags := ['premium', 'eu'];
      LCustomer.PasswordHash := 'never serialized';

      LJSON := TNeon.ObjectToJSON(LCustomer, LConfig);
      try
        Writeln('TCustomer -> JSON');
        Writeln(TNeon.Print(LJSON, True));
      finally
        LJSON.Free;
      end;
    finally
      LCustomer.Free;
    end;
    Writeln;

    LCustomer := TNeon.JSONToObject<TCustomer>(CUSTOMER_JSON, LConfig);
    try
      Writeln('JSON -> TCustomer');
      Writeln(Format('  ID: %d, Name: %s, Level: %s', [LCustomer.ID, LCustomer.Name,
        GetEnumName(TypeInfo(TCustomerLevel), Ord(LCustomer.Level))]));
      Writeln(Format('  Address.City: %s, Tags: %d, PasswordHash: "%s"',
        [LCustomer.Address.City, Length(LCustomer.Tags), LCustomer.PasswordHash]));
    finally
      LCustomer.Free;
    end;

    Writeln;
    Writeln('Press Enter to quit');
  except
    on E: Exception do
    begin
      Writeln(Format('Error: [%s] %s', [E.ClassName, E.Message]));
      ExitCode := 1;
    end;
  end;

  Readln;
end.
