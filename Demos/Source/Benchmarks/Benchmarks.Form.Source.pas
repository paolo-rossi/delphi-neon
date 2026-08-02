{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization Library for Delphi                                 }
{  Copyright (c) 2018 Paolo Rossi                                              }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{  Licensed under the MIT license                                              }
{                                                                              }
{******************************************************************************}
unit Benchmarks.Form.Source;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TfrmSource = class(TForm)
    richSourceSimple: TRichEdit;
    richSourceComplex: TRichEdit;
    pgcSource: TPageControl;
    tsSourceSimple: TTabSheet;
    tsSourceComplex: TTabSheet;
    lblSimple: TLabel;
    pnlHeader: TPanel;
    shpHeader: TShape;
    lblHeader: TLabel;
    lblHeader2: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSource: TfrmSource;

implementation

{$R *.dfm}

procedure TfrmSource.FormCreate(Sender: TObject);
begin
  richSourceSimple.Lines.LoadFromFile('..\Data\Benchmarks\benchmark-simple.rtf');
  richSourceComplex.Lines.LoadFromFile('..\Data\Benchmarks\benchmark-complex.rtf');
end;

end.
