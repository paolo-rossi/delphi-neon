unit Demo.Forms.Serialization.Simple;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Demo.Forms.Serialization.Base;

type
  TfrmSerializationSimple = class(TfrmSerializationBase)
    btnSerSimpleInteger: TButton;
    btnSerSimpleString: TButton;
    btnSerSimpleDatTime: TButton;
    btnSerSimpleRecord: TButton;
    btnSerSimpleArray: TButton;
    btnSerSimpleFloat: TButton;
    btnSerSimpleBool: TButton;
    btnDesSimpleInteger: TButton;
    btnDesSimpleString: TButton;
    btnDesSimpleDateTime: TButton;
    btnDesSimpleRecord: TButton;
    btnDesSimpleArray: TButton;
    btnDesSimpleFloat: TButton;
    btnDesSimpleBool: TButton;
    procedure btnDesSimpleArrayClick(Sender: TObject);
    procedure btnDesSimpleBoolClick(Sender: TObject);
    procedure btnDesSimpleDateTimeClick(Sender: TObject);
    procedure btnDesSimpleFloatClick(Sender: TObject);
    procedure btnDesSimpleIntegerClick(Sender: TObject);
    procedure btnDesSimpleRecordClick(Sender: TObject);
    procedure btnDesSimpleStringClick(Sender: TObject);
    procedure btnSerSimpleArrayClick(Sender: TObject);
    procedure btnSerSimpleBoolClick(Sender: TObject);
    procedure btnSerSimpleDatTimeClick(Sender: TObject);
    procedure btnSerSimpleFloatClick(Sender: TObject);
    procedure btnSerSimpleIntegerClick(Sender: TObject);
    procedure btnSerSimpleRecordClick(Sender: TObject);
    procedure btnSerSimpleStringClick(Sender: TObject);
  private
   procedure SerializeSimple<T>(AValue: T);
   procedure DeserializeSimple<T>;
  public
    { Public declarations }
  end;

var
  frmSerializationSimple: TfrmSerializationSimple;

implementation

uses
  System.Rtti,
  Demo.Neon.Entities;

{$R *.dfm}

procedure TfrmSerializationSimple.btnDesSimpleArrayClick(Sender: TObject);
begin
  DeserializeSimple<TIntArray>;
end;

procedure TfrmSerializationSimple.btnDesSimpleBoolClick(Sender: TObject);
begin
  DeserializeSimple<Boolean>;
end;

procedure TfrmSerializationSimple.btnDesSimpleDateTimeClick(Sender: TObject);
begin
  DeserializeSimple<TDateTime>;
end;

procedure TfrmSerializationSimple.btnDesSimpleFloatClick(Sender: TObject);
begin
  DeserializeSimple<Double>;
end;

procedure TfrmSerializationSimple.btnDesSimpleIntegerClick(Sender: TObject);
begin
  DeserializeSimple<Integer>;
end;

procedure TfrmSerializationSimple.btnDesSimpleRecordClick(Sender: TObject);
begin
  DeserializeSimple<TMyRecord>;
end;

procedure TfrmSerializationSimple.btnDesSimpleStringClick(Sender: TObject);
begin
  DeserializeSimple<string>;
end;

procedure TfrmSerializationSimple.btnSerSimpleArrayClick(Sender: TObject);
var
  LVal: TIntArray;
begin
  SetLength(LVal, 4);
  LVal[0] := 12;
  LVal[1] := 34;
  LVal[2] := 797;
  LVal[3] := 5236;
  SerializeSimple<TIntArray>(LVal);
end;

procedure TfrmSerializationSimple.btnSerSimpleBoolClick(Sender: TObject);
begin
  SerializeSimple<Boolean>(True);
end;

procedure TfrmSerializationSimple.btnSerSimpleDatTimeClick(Sender: TObject);
begin
  SerializeSimple<TDateTime>(Now);
end;

procedure TfrmSerializationSimple.btnSerSimpleFloatClick(Sender: TObject);
begin
  SerializeSimple<Double>(123.42);
end;

procedure TfrmSerializationSimple.btnSerSimpleIntegerClick(Sender: TObject);
begin
  SerializeSimple<Integer>(42);
end;

procedure TfrmSerializationSimple.btnSerSimpleRecordClick(Sender: TObject);
var
  LVal: TMyRecord;
begin
  LVal.One := 'Test Test Test';
  LVal.Two := 42;
  SerializeSimple<TMyRecord>(LVal);
end;

procedure TfrmSerializationSimple.btnSerSimpleStringClick(Sender: TObject);
begin
  SerializeSimple<string>('Paolo Rossi');
end;

procedure TfrmSerializationSimple.DeserializeSimple<T>;
var
  LVal: T;
begin
  LVal := DeserializeValueTo<T>(
    memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);

  SerializeValueFrom<T>(
    TValue.From<T>(LVal), memoDeserialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

procedure TfrmSerializationSimple.SerializeSimple<T>(AValue: T);
begin
  SerializeValueFrom<T>(
    TValue.From<T>(AValue), memoSerialize.Lines, frmConfiguration.BuildSerializerConfig);
end;

end.
