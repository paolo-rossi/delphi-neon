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
unit Neon.Tests.Attributes;

interface

uses
  System.SysUtils, System.Rtti, DUnitX.TestFramework,

  Neon.Core.Persistence,
  Neon.Tests.Entities,
  Neon.Tests.Utils;

type
  [TestFixture]
  [Category('attrinclude')]
  TTestAttributesInclude = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestIncludeIfAlways(const AMethod: string);
  end;

implementation

uses
  System.IOUtils, System.DateUtils;

constructor TTestAttributesInclude.Create;
begin

end;

destructor TTestAttributesInclude.Destroy;
begin

  inherited;
end;

procedure TTestAttributesInclude.Setup;
begin
end;

procedure TTestAttributesInclude.TearDown;
begin
end;

procedure TTestAttributesInclude.TestIncludeIfAlways(const AMethod: string);
begin

end;

initialization
  TDUnitX.RegisterTestFixture(TTestAttributesInclude);

end.
