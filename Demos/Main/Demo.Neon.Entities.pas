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
unit Demo.Neon.Entities;

interface

{$I Neon.inc}

uses
  System.SysUtils, System.Classes, System.Contnrs, System.Generics.Collections,
  System.Math, System.Math.Vectors, System.Types, system.JSON, Vcl.Graphics,

  Neon.Core.Types,
  Neon.Core.Nullables,
  Neon.Core.Attributes;

{$M+}
{$SCOPEDENUMS ON}

type
  TCustomDate = type TDateTime;

  TDates = record
    Date: TDateTime;
    Time: TTime;
    Custom: TCustomDate;
    procedure SampleData;
  end;

  [NeonEnumNames('Low Speed,Medium Speed,High Speed')]
  TEnumSpeed = (Low, Medium, High);

  TSetSpeed = set of TEnumSpeed;

  TArraySpeed = TArray<TEnumSpeed>;

  TArrayDuplicates = TArray<TDuplicates>;

  TSetDuplicates = set of TDuplicates;

  TSetBoolean = set of Boolean;

  TWeekDays = 1..7;
  TSetWeekDays = set of TWeekDays;

  TUppercase = 'A'..'Z';
  TSetUppercase = set of TUppercase;

  TManagedRecord = record
    Name: string;
    Age: Integer;
    Height: Double;
    {$IFDEF HAS_MRECORDS}
    class operator Initialize (out Dest: TManagedRecord);
    class operator Finalize (var Dest: TManagedRecord);
    {$ENDIF}
  end;

  // Sample
  TVector3f = record
    X, Y, Z: Double;
  end;

  // Complex type for Custom Serializer
  TReference = class
  private
    Fref: string;
  public
    [NeonProperty('$ref')]
    property ref: string read Fref write Fref;
  end;

  TParameter = class
  private
    FallowEmptyValue: Boolean;
    F_deprecated: Boolean;
    Fdescription: string;
    Fname: string;
    Frequired: Boolean;
    F_in: string;
  public
    property name: string read Fname write Fname;
    [NeonProperty('in')]
    property _in: string read F_in write F_in;
    property description: string read Fdescription write Fdescription;
    property required: Boolean read Frequired write Frequired;
    [NeonProperty('deprecated')]
    property _deprecated: Boolean read F_deprecated write F_deprecated;
    property allowEmptyValue: Boolean read FallowEmptyValue write FallowEmptyValue;
  end;

  TParameterContainer = class
  private
    Fpar: TParameter;
    Fref: TReference;
  public
    constructor Create;
    destructor Destroy; override;

    property par: TParameter read Fpar write Fpar;
    property ref: TReference read Fref write Fref;
  end;

  TStreamableSample = class
  private
    FPayload: TBytes;
    procedure SetAsString(const Value: string);
  public
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToStream(AStream: TStream);
    function GetAsString: string;
    property AsString: string read GetAsString write SetAsString;
  end;

  TStreamableComposition = class
  private
    FInValue: Integer;
    FStream: TStreamableSample;
  public
    constructor Create;
    destructor Destroy; override;
    property InValue: Integer read FInValue write FInValue;
    property Stream: TStreamableSample read FStream write FStream;
  end;

  TIntArray = TArray<Integer>;

  TMyEnum = (First, Second, Third, Fourth);

  TMySet = set of TMyEnum;

  TMyRecord = record
  public
    Speed: TEnumSpeed;
    One: string;
    Two: Integer;

    function ToString: string;
    procedure FromString(const AValue: string);
  end;

  TAddress = class
  private
    FCity: string;
    FCountry: string;
  public
    Rec: TMyRecord;
    constructor Create(const ACity, ACountry: string);
  published
    property City: string read FCity write FCity;
    property Country: string read FCountry write FCountry;

    function ToString: string; override;
    procedure FromString(const AValue: string);
  end;

  TAddresses = TArray<TAddress>;
  TAddressList = TList<TAddress>;

  TAddressBook = class
  private
    FAddressList: TAddressList;
    FNoteList: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    function Add(ACity, ACountry: string): TAddress;
  published
    property AddressList: TAddressList read FAddressList write FAddressList;
    property NoteList: TStringList read FNoteList write FNoteList;
  end;

  TNote = class
  private
    FDate: TDateTime;
    FText: string;
  public
    constructor Create(ADate: TDateTime; const AText: string); overload;
  published
    property Date: TDateTime read FDate write FDate;
    property Text: string read FText write FText;
  end;

  TPerson = class
  private
    FAddresses: TAddresses;
    FDateProp: TDateTime;
    FDoubleProp: Double;
    FEnum: TMyEnum;
    FName: string;
    FNote: TNote;
    FOptions: TMySet;
    FSurname: string;
    FMap: TObjectDictionary<string, TNote>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddAddress(const ACity, ACountry: string);
  published
    property Name: string read FName write FName;

    [NeonProperty('LastName')]
    property Surname: string read FSurname write FSurname;

    property Addresses: TAddresses read FAddresses write FAddresses;
    property DateProp: TDateTime read FDateProp write FDateProp;
    property DoubleProp: Double read FDoubleProp write FDoubleProp;
    property Enum: TMyEnum read FEnum write FEnum;
    property Note: TNote read FNote write FNote;
    property Options: TMySet read FOptions write FOptions;

    property Map: TObjectDictionary<string, TNote> read FMap write FMap;
  end;

  TCaseClass = class
  private
    //[NeonInclude]
    FPrivateField: Double;
    FFirstProp: Integer;
    FSecondXProp: string;
    FThirdPascalCaseProp: TDateTime;
    FDefProp: Integer;
    //[NeonInclude, NeonMembers(TNeonMembers.Fields)]
    FirstRecord: TMyRecord;
    FNote: TNote;
  public
    constructor Create;
    destructor Destroy; override;

    class function DefaultValues: TCaseClass;
  public
    property DefProp: Integer read FDefProp write FDefProp;
    property FirstProp: Integer read FFirstProp write FFirstProp;
    property SecondXProp: string read FSecondXProp write FSecondXProp;
    property ThirdPascalCaseProp: TDateTime read FThirdPascalCaseProp write FThirdPascalCaseProp;
    property Note: TNote read FNote write FNote;
  end;

  {$RTTI EXPLICIT METHODS([vcPrivate])}
  TFilterClass = class
  private
    FProp1: Integer;
    FProp2: string;
    FProp3: TDateTime;
    FProp4: TPoint3D;

    FProp5: TVector3D;

    [NeonInclude]
    Field1: TArray<TDateTime>;

    [NeonInclude(IncludeIf.CustomFunction)]
    Field2: TRect;
  private
    function ShouldInclude(const AContext: TNeonIgnoreIfContext): Boolean;

    //[NeonSerializerMethod]
    //function Serializer(const AContext: TNeonIgnoreIfContext): TJSONValue;
  public
    class function DefaultValues: TFilterClass;

    property Prop1: Integer read FProp1 write FProp1;
    property Prop2: string read FProp2 write FProp2;
    property Prop3: TDateTime read FProp3 write FProp3;
    [NeonIgnore]
    property Prop4: TPoint3D read FProp4 write FProp4;
    [NeonInclude(IncludeIf.CustomFunction)]
    property Prop5: TVector3D read FProp5 write FProp5;
  end;

  TClassSubClass = class
  private
    FName: string;
    FDate: TDateTime;
    FNote: TNote;
  public
    property Name: string read FName write FName;
    property Date: TDateTime read FDate write FDate;
    property Note: TNote read FNote write FNote;
  end;

  TMyClass = class
  private
    FGUID: TGUID;
    FPoint: TPoint3D;
    FVector: TVector3D;
  public
    procedure DefaultValues; virtual;
  public
    property GUID: TGUID read FGUID write FGUID;
    property Point: TPoint3D read FPoint write FPoint;
    property Vector: TVector3D read FVector write FVector;
  end;

  TMyDerivedClass = class(TMyClass)
  private
    FPropertyTest: string;
  public
    FieldTest: string;
    property PropertyTest: string read FPropertyTest write FPropertyTest;
    procedure DefaultValues; override;
  end;

  /// <summary>
  ///   Entity to test simple type properties
  /// </summary>
  TTypeClass = class
  private
    FPropInteger: Integer;
    FPropInt64: Int64;
    FPropDouble: Double;
    FPropDate: TDateTime;
    FPropChar: Char;
    FPropString: string;
    FPropBoolean: Boolean;
    FPropEnum: TTypeKind;
  public
    constructor Create;

    [NeonInclude(IncludeIf.NotDefault)]
    property PropInteger: Integer read FPropInteger write FPropInteger;

    [NeonInclude(IncludeIf.NotDefault)]
    property PropInt64: Int64 read FPropInt64 write FPropInt64;

    [NeonInclude(IncludeIf.NotDefault)]
    property PropDouble: Double read FPropDouble write FPropDouble;

    [NeonInclude(IncludeIf.NotDefault)]
    property PropDate: TDateTime read FPropDate write FPropDate;

    [NeonInclude(IncludeIf.NotEmpty)]
    property PropChar: Char read FPropChar write FPropChar;

    [NeonInclude(IncludeIf.NotEmpty)]
    property PropString: string read FPropString write FPropString;

    [NeonInclude(IncludeIf.NotEmpty)]
    property PropBoolean: Boolean read FPropBoolean write FPropBoolean;

    [NeonInclude(IncludeIf.NotEmpty)]
    property PropEnum: TTypeKind read FPropEnum write FPropEnum;
  end;

  /// <summary>
  ///   Entity to test the Nullables serialization
  /// </summary>
  TClassOfNullables = class
  private
    FName: NullString;
    FAge: NullInteger;
    FSpeed: Nullable<TEnumSpeed>;
    FObj: TObject;
  public
    [NeonInclude(IncludeIf.Always)]
    property Obj: TObject read FObj write FObj;
    [NeonInclude(IncludeIf.Always)]
    property Name: NullString read FName write FName;
    [NeonInclude(IncludeIf.NotNull)]
    property Age: NullInteger read FAge write FAge;
    property Speed: Nullable<TEnumSpeed> read FSpeed write FSpeed;
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
    FName: string;
    FObj: TObject;

    function ShouldInclude(const AContext: TNeonIgnoreIfContext): Boolean;
  public
    [NeonInclude(IncludeIf.CustomFunction)]
    property Name: string read FName write FName;
    [NeonInclude(IncludeIf.CustomFunction)]
    property Obj: TObject read FObj write FObj;

    [NeonInclude(IncludeIf.Always)]
    property NullObject1: TObject read FNullObject1 write FNullObject1;
    [NeonInclude(IncludeIf.NotNull)]
    property NullObject2: TObject read FNullObject2 write FNullObject2;
    [NeonInclude(IncludeIf.NotEmpty)]
    property NString: NullString read FNString write FNString;
    [NeonInclude(IncludeIf.NotDefault)]
    property NInteger: NullInteger read FNInteger write FNInteger;
  end;

  /// <summary>
  ///   Entity to test conversion to and from variants
  /// </summary>
  TVariantEntity = class
  private
    FProp1: Variant;
    FProp2: Variant;
    FProp3: Variant;
    FProp4: Variant;
    FProp5: Variant;
  public
    property Prop1: Variant read FProp1 write FProp1;
    property Prop2: Variant read FProp2 write FProp2;
    property Prop3: Variant read FProp3 write FProp3;
    property Prop4: Variant read FProp4 write FProp4;
    property Prop5: Variant read FProp5 write FProp5;
  end;


implementation


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

{ TPerson }

procedure TPerson.AddAddress(const ACity, ACountry: string);
var
  LAddress: TAddress;
begin
  LAddress := TAddress.Create(ACity, ACountry);
  LAddress.Rec.One := 'Qwerty';
  LAddress.Rec.Two := 12;

  SetLength(FAddresses, Length(FAddresses) + 1);
  FAddresses[Length(FAddresses) - 1] := LAddress;
end;

constructor TPerson.Create;
begin
  FNote := TNote.Create;
  FEnum := TMyEnum.Second;
  FDoubleProp := 56.7870988623;
  FDateProp := Now;
  FOptions := [TMyEnum.First, TMyEnum.Second, TMyEnum.Fourth];
  FMap := TObjectDictionary<string, TNote>.Create([doOwnsValues]);
end;

destructor TPerson.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := High(FAddresses) downto Low(FAddresses) do
    FAddresses[LIndex].Free;
  SetLength(FAddresses, 0);
  FNote.Free;
  FMap.Free;
  inherited;
end;

{ TAddressBook }

function TAddressBook.Add(ACity, ACountry: string): TAddress;
begin
  Result := TAddress.Create(ACity, ACountry);
  FAddressList.Add(Result);
end;

constructor TAddressBook.Create;
begin
  FAddressList := TAddressList.Create;
  FNoteList := TStringList.Create;
end;

destructor TAddressBook.Destroy;
var
  LAddress: TObject;
begin
  for LAddress in FAddressList do
  begin
    LAddress.Free;
  end;
  FAddressList.Free;
  FNoteList.Free;
  inherited;
end;

{ TMyRecord }

procedure TMyRecord.FromString(const AValue: string);
begin
  One := AValue;
  Speed := TEnumSpeed.High;
end;

function TMyRecord.ToString: string;
begin
  Result := One + '-' + Two.ToString;
end;

{ TStreamableSample }

function TStreamableSample.GetAsString: string;
begin
  Result := TEncoding.UTF8.GetString(FPayload);
end;

procedure TStreamableSample.LoadFromStream(AStream: TStream);
begin
  AStream.Position := soFromBeginning;
  SetLength(FPayload, AStream.Size);
  AStream.Read(FPayload[0], AStream.Size);
end;

procedure TStreamableSample.SaveToStream(AStream: TStream);
begin
  AStream.Position := soFromBeginning;
  AStream.Write(FPayload[0], Length(FPayload));
end;

procedure TStreamableSample.SetAsString(const Value: string);
begin
  FPayload := TEncoding.UTF8.GetBytes(Value);
end;

{ TStreamableComposition }

constructor TStreamableComposition.Create;
begin
  FStream := TStreamableSample.Create;
end;

destructor TStreamableComposition.Destroy;
begin
  FStream.Free;
  inherited;
end;

{ TCaseClass }

constructor TCaseClass.Create;
begin
  FNote := TNote.Create;
end;

destructor TCaseClass.Destroy;
begin
  FNote.Free;
  inherited;
end;

class function TCaseClass.DefaultValues: TCaseClass;
begin
  Result := TCaseClass.Create;
  Result.DefProp := 12399;
  Result.FPrivateField := 3.1415926535;
  Result.FirstRecord.One := 'Record text field';
  Result.FirstRecord.Two := Random(1000);
  Result.FirstProp := Random(1000);
  Result.SecondXProp := 'Metà';
  Result.ThirdPascalCaseProp := EncodeDate(2018, Random(11)+1, Random(27)+1);
  Result.Note.Date := Now;
  Result.Note.Text := 'Lorem Ipsum';
end;

{ TFilterClass }

class function TFilterClass.DefaultValues: TFilterClass;
begin
  Result := Create;

  Result.Field1 := [Now, Now+1, Now+2, Now+3];
  Result.Field2 := TRect.Create(11, 22, 33, 44);
  Result.Prop1 := 42;
  Result.Prop2 := 'Paolo';
  Result.Prop3 := Now;
  Result.Prop4 := TPoint3D.Create(10, 20, 30);
  Result.Prop5 := TVector3D.Create(40, 50, 60);
end;

function TFilterClass.ShouldInclude(const AContext: TNeonIgnoreIfContext): Boolean;
begin
  Result := False;

  // You can filter by the member name
  if SameText(AContext.MemberName, 'Prop5') then
  begin
    // And you can filter on additional conditions
    if Prop5.X > Prop5.Y then
      Result := True;
  end
  // You can reuse (only if you want) the same function for several members
  else if SameText(AContext.MemberName, 'Field1') then
  begin
    Result := True;
  end;

end;

{ TNote }

constructor TNote.Create(ADate: TDateTime; const AText: string);
begin
  FDate := ADate;
  FText := AText;
end;

{ TMyClass }

procedure TMyClass.DefaultValues;
begin
  FGUID := StringToGUID('{41F2541A-E0AE-47EB-8C5F-8C8840891371}');
  FPoint.X := 23.887;
  FPoint.Y := 4.003;
  FPoint.Z := 12.37;
  FVector.X := 10;
  FVector.Y := 20;
  FVector.Z := 30;
  FVector.W := 40;
end;

{ TParameterContainer }

constructor TParameterContainer.Create;
begin
  ref := TReference.Create;
  par := TParameter.Create;
end;

destructor TParameterContainer.Destroy;
begin
  par.Free;
  ref.Free;
  inherited;
end;

{ TTypeClass }

constructor TTypeClass.Create;
begin
  FPropInteger := Random(10000);
  FPropInt64 := Random(100000000);
  FPropDouble := Random * 100;
  FPropEnum := TTypeKind(Random(20));
  FPropString := 'Lorem ipsum';
  FPropChar := Char(Random(125));

  FPropBoolean := FPropInteger > 4000;
  FPropDate := IfThen(FPropEnum = tkInteger, Random * 50000, 0);
end;

{ TAddress }

constructor TAddress.Create(const ACity, ACountry: string);
begin
  FCity := ACity;
  FCountry := ACountry;
end;

procedure TAddress.FromString(const AValue: string);
begin
  FCity := AValue;
  FCountry := AValue;
end;

function TAddress.ToString: string;
begin
  Result := FCity;
end;


{ TMyDerivedClass }

procedure TMyDerivedClass.DefaultValues;
begin
  inherited;
  FPropertyTest := 'property added';
  FieldTest := 'my field: hello world!';
end;

{ TNeonIncludeEntity }

function TNeonIncludeEntity.ShouldInclude(const AContext: TNeonIgnoreIfContext): Boolean;
begin
  Result := False;

  // You can filter by the member name
  if SameText(AContext.MemberName, 'Name') then
  begin
    Result := True;
  end
  // You can reuse (only if you want) the same function for several members
  else if SameText(AContext.MemberName, 'Obj') then
  begin
    Result := True;
  end;
end;

{ TDates }

procedure TDates.SampleData;
begin
  Date := Now;
  Time := Now + 0.5;
  Custom := Now + 2;
end;

initialization
  Randomize();

end.
