{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Tests.Config.MapSort;

interface

uses
  System.SysUtils, System.Rtti, System.JSON, System.Generics.Collections,
  DUnitX.TestFramework,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}

  Neon.Core.Types,
  Neon.Core.Persistence,
  Neon.Tests.Utils;

type
  TMapSortClass = class
  private
    FItems: TDictionary<string, Integer>;
  public
    constructor Create;
    destructor Destroy; override;

    property Items: TDictionary<string, Integer> read FItems write FItems;
  end;

  [TestFixture]
  [Category('mapsort')]
  TTestConfigMapSort = class(TObject)
  private
    FTestObj: TMapSortClass;

    function ExtractItemKeys(const AJSON: string): TArray<string>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDefaultIsRtti;

    [Test]
    procedure TestRttiReverseIsReverseOfRtti;

    [Test]
    procedure TestAlphaSort;

    [Test]
    procedure TestAlphaReverseSort;

    [Test]
    procedure TestAlphaSortIsCaseSensitive;
  end;

implementation

{ TMapSortClass }

constructor TMapSortClass.Create;
begin
  FItems := TDictionary<string, Integer>.Create;
  FItems.Add('banana', 2);
  FItems.Add('date', 4);
  FItems.Add('apple', 1);
  FItems.Add('cherry', 3);
end;

destructor TMapSortClass.Destroy;
begin
  FItems.Free;
  inherited;
end;

{ TTestConfigMapSort }

function TTestConfigMapSort.ExtractItemKeys(const AJSON: string): TArray<string>;
var
  LJSON: TJSONValue;
  LItems: TJSONObject;
  LKeys: TList<string>;
  I: Integer;
begin
  LKeys := TList<string>.Create;
  try
    LJSON := TJSONObject.ParseJSONValue(AJSON);
    try
      LItems := (LJSON as TJSONObject).GetValue('Items') as TJSONObject;

      for I := 0 to LItems.Count - 1 do
        LKeys.Add(LItems.Pairs[I].JsonString.Value);

      Result := LKeys.ToArray;
    finally
      LJSON.Free;
    end;
  finally
    LKeys.Free;
  end;
end;

procedure TTestConfigMapSort.Setup;
begin
  FTestObj := TMapSortClass.Create;
end;

procedure TTestConfigMapSort.TearDown;
begin
  FTestObj.Free;
end;

procedure TTestConfigMapSort.TestDefaultIsRtti;
var
  LDefaultJSON, LExplicitRttiJSON: string;
begin
  // The unconfigured default must keep the natural (Rtti) enumeration order
  LDefaultJSON := TTestUtils.SerializeObject(FTestObj, TNeonConfiguration.Default);
  LExplicitRttiJSON := TTestUtils.SerializeObject(FTestObj,
    TNeonConfiguration.Default.SetMapSort(TNeonSort.Rtti));

  Assert.AreEqual(LDefaultJSON, LExplicitRttiJSON);
end;

procedure TTestConfigMapSort.TestRttiReverseIsReverseOfRtti;
var
  LRttiJSON, LReverseJSON: string;
  LRttiKeys, LReverseKeys: TArray<string>;
  I: Integer;
begin
  // TDictionary enumeration order is not contractually fixed, so RttiReverse
  // is verified relative to Rtti rather than against a hardcoded key order
  LRttiJSON := TTestUtils.SerializeObject(FTestObj,
    TNeonConfiguration.Default.SetMapSort(TNeonSort.Rtti));
  LReverseJSON := TTestUtils.SerializeObject(FTestObj,
    TNeonConfiguration.Default.SetMapSort(TNeonSort.RttiReverse));

  LRttiKeys := ExtractItemKeys(LRttiJSON);
  LReverseKeys := ExtractItemKeys(LReverseJSON);

  Assert.AreEqual(Length(LRttiKeys), Length(LReverseKeys));
  for I := 0 to High(LRttiKeys) do
    Assert.AreEqual(LRttiKeys[I], LReverseKeys[High(LReverseKeys) - I]);
end;

procedure TTestConfigMapSort.TestAlphaSort;
var
  LJSON: string;
  LKeys: TArray<string>;
begin
  LJSON := TTestUtils.SerializeObject(FTestObj,
    TNeonConfiguration.Default.SetMapSort(TNeonSort.Alpha));
  LKeys := ExtractItemKeys(LJSON);

  Assert.AreEqual('apple,banana,cherry,date', string.Join(',', LKeys));
end;

procedure TTestConfigMapSort.TestAlphaReverseSort;
var
  LJSON: string;
  LKeys: TArray<string>;
begin
  LJSON := TTestUtils.SerializeObject(FTestObj,
    TNeonConfiguration.Default.SetMapSort(TNeonSort.AlphaReverse));
  LKeys := ExtractItemKeys(LJSON);

  Assert.AreEqual('date,cherry,banana,apple', string.Join(',', LKeys));
end;

procedure TTestConfigMapSort.TestAlphaSortIsCaseSensitive;
var
  LObj: TMapSortClass;
  LJSON: string;
  LKeys: TArray<string>;
begin
  // Alpha sort uses CompareStr (ordinal): uppercase letters sort before
  // lowercase ones, so 'Zebra' comes before 'apple'
  LObj := TMapSortClass.Create;
  try
    LObj.Items.Clear;
    LObj.Items.Add('apple', 1);
    LObj.Items.Add('Zebra', 2);

    LJSON := TTestUtils.SerializeObject(LObj,
      TNeonConfiguration.Default.SetMapSort(TNeonSort.Alpha));
    LKeys := ExtractItemKeys(LJSON);

    Assert.AreEqual('Zebra,apple', string.Join(',', LKeys));
  finally
    LObj.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfigMapSort);

end.
