unit pbasic_env;

{$mode objfpc}{$H+}

interface

type
  TVariableStore = class
  private
    FVars: array['A'..'Z'] of LongInt;
  public
    constructor Create;
    procedure Clear;
    function Count: Integer;
  end;

implementation

constructor TVariableStore.Create;
begin
  inherited Create;
  Clear;
end;

procedure TVariableStore.Clear;
var
  C: Char;
begin
  for C := 'A' to 'Z' do
    FVars[C] := 0;
end;

function TVariableStore.Count: Integer;
begin
  Result := 26;
end;

end.
