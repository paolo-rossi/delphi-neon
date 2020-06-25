unit Demo.Forms.Serialization.Records;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Demo.Forms.Serialization.Base;

type
  TfrmSerializationRecords = class(TfrmSerializationBase)
    btnSerSimpleMRecord: TButton;
    btnDesSimpleMRecord: TButton;
    btnSerSimpleRecord: TButton;
    btnDesSimpleRecord: TButton;
    procedure btnSerSimpleRecordClick(Sender: TObject);
    procedure btnDesSimpleRecordClick(Sender: TObject);
    procedure btnSerSimpleMRecordClick(Sender: TObject);
  private
    procedure SerializeSimple<T>(AValue: T);
    procedure DeserializeSimple<T>(AValue: T);
  public
    { Public declarations }
  end;

var
  frmSerializationRecords: TfrmSerializationRecords;

implementation

uses
  System.Rtti,
  Demo.Neon.Entities;

{$R *.dfm}

procedure TfrmSerializationRecords.btnDesSimpleRecordClick(Sender: TObject);
var
  LRecord: TMyRecord;
begin
  DeserializeSimple<TMyRecord>(LRecord);
end;

procedure TfrmSerializationRecords.btnSerSimpleMRecordClick(Sender: TObject);
var
  LVal: TManagedRecord;
begin
  LVal.Name := 'Paolo';
  LVal.Age := 50;
  LVal.Height := 1.70;
  SerializeSimple<TManagedRecord>(LVal);
end;

procedure TfrmSerializationRecords.btnSerSimpleRecordClick(Sender: TObject);
var
  LVal: TMyRecord;
begin
  LVal.Speed := TEnumSpeed.Low;
  LVal.One := 'Test Test Test';
  LVal.Two := 42;
  SerializeSimple<TMyRecord>(LVal);
end;

procedure TfrmSerializationRecords.DeserializeSimple<T>(AValue: T);
var
  LVal: T;
begin
  LVal := DeserializeValueTo<T>(AValue,
    memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);

  SerializeValueFrom<T>(
    TValue.From<T>(LVal), memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationRecords.SerializeSimple<T>(AValue: T);
begin
  SerializeValueFrom<T>(
    TValue.From<T>(AValue), memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

end.
