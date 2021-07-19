unit Demo.Forms.Serialization.Schema;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList, Vcl.CategoryButtons,
  System.JSON, System.Rtti,

  Demo.Forms.Serialization.Base,
  Demo.Frame.Configuration,
  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON.Schema,
  Neon.Core.Utils;

type
  TfrmSerializationSchema = class(TfrmSerializationBase)
    actSerJSONSchema: TAction;
    actSerAttrUnwrapped: TAction;
    actDesAttrUnwrapped: TAction;
    procedure actDesAttrUnwrappedExecute(Sender: TObject);
    procedure actSerAttrUnwrappedExecute(Sender: TObject);
    procedure actSerJSONSchemaExecute(Sender: TObject);
  private
    function BuildConfig: INeonConfiguration;
  public
    { Public declarations }
  end;

var
  frmSerializationSchema: TfrmSerializationSchema;

implementation

uses
  Demo.Neon.Entities, Neon.Core.Persistence.JSON;

{$R *.dfm}

procedure TfrmSerializationSchema.actDesAttrUnwrappedExecute(Sender: TObject);
var
  LObj: TUnwrappedClass;
begin
  LObj := TUnwrappedClass.Create;
  try
    DeserializeObject(LObj, memoSerialize.Lines, BuildConfig);
    SerializeObject(LObj, memoDeserialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationSchema.actSerAttrUnwrappedExecute(Sender: TObject);
var
  LObj: TUnwrappedClass;
begin
  LObj := TUnwrappedClass.Sample1;
  try
    SerializeObject(LObj, memoSerialize.Lines, BuildConfig);
  finally
    LObj.Free;
  end;
end;

procedure TfrmSerializationSchema.actSerJSONSchemaExecute(Sender: TObject);
var
  LJSON: TJSONObject;
begin
  LJSON := TNeonSchemaGenerator.ClassToJSONSchema(TCaseClass);
  try
    memoSerialize.Lines.Text := TNeon.Print(LJSON, True);
  finally
    LJSON.Free;
  end;
end;

function TfrmSerializationSchema.BuildConfig: INeonConfiguration;
begin
  Result := frmConfiguration.BuildSerializerConfig([TSerializersType.CustomNeon]);
end;

end.
