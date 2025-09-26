unit pbasic_signals;

{$mode objfpc}{$H+}

interface

procedure InstallSignalHandlers;
function CheckAndResetInterrupted: Boolean;
procedure SetInterrupted(Val: Boolean);

implementation

uses
  BaseUnix;

var
  InterruptedFlag: Boolean = False;

procedure SigIntHandler(Sig: LongInt); cdecl;
begin
  InterruptedFlag := True;
end;

procedure InstallSignalHandlers;
begin
  fpSignal(SIGINT, SignalHandler(@SigIntHandler));
end;

function CheckAndResetInterrupted: Boolean;
begin
  Result := InterruptedFlag;
  InterruptedFlag := False;
end;

procedure SetInterrupted(Val: Boolean);
begin
  InterruptedFlag := Val;
end;

end.
