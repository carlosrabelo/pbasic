unit pbasic_interpreter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  pbasic_token,
  pbasic_program,
  pbasic_env,
  pbasic_evaluator;

type
  TExecResult = (
    erOk,
    erStop,
    erSyntaxError
  );

  TInterpreter = class
  private
    FProg: TProgramStore;
    FVars: TVariableStore;
    FRandSeed: Word;
    FGosubStack: array of Word;
    FHalted: Boolean;
    FExitRequested: Boolean;
    FIsRunning: Boolean;
    FCaptureOutput: Boolean;
    FOutputBuffer: string;

    procedure SyntaxError;
  public
    constructor Create(AProg: TProgramStore = nil; AVars: TVariableStore = nil; ARandSeed: Word = 12345);
    destructor Destroy; override;

    procedure PrintStr(const S: string);
    procedure PrintLn(const S: string = '');
    procedure PrintNum(Val: LongInt);
    procedure ClearOutputBuffer;

    function ExecuteStatement(const Tokens: TTokenArray): TExecResult;

    property Prog: TProgramStore read FProg write FProg;
    property Vars: TVariableStore read FVars write FVars;
    property RandSeed: Word read FRandSeed write FRandSeed;
    property Halted: Boolean read FHalted write FHalted;
    property ExitRequested: Boolean read FExitRequested write FExitRequested;
    property IsRunning: Boolean read FIsRunning write FIsRunning;
    property CaptureOutput: Boolean read FCaptureOutput write FCaptureOutput;
    property OutputBuffer: string read FOutputBuffer write FOutputBuffer;
  end;

implementation

constructor TInterpreter.Create(AProg: TProgramStore; AVars: TVariableStore; ARandSeed: Word);
begin
  inherited Create;
  FProg := AProg;
  FVars := AVars;
  if ARandSeed = 0 then
    FRandSeed := 12345
  else
    FRandSeed := ARandSeed;
  SetLength(FGosubStack, 0);
  FHalted := False;
  FExitRequested := False;
  FIsRunning := False;
  FCaptureOutput := False;
  FOutputBuffer := '';
end;

destructor TInterpreter.Destroy;
begin
  SetLength(FGosubStack, 0);
  inherited Destroy;
end;

procedure TInterpreter.PrintStr(const S: string);
begin
  if FCaptureOutput then
    FOutputBuffer := FOutputBuffer + S
  else
  begin
    write(Output, S);
    Flush(Output);
  end;
end;

procedure TInterpreter.PrintLn(const S: string);
begin
  PrintStr(S + LineEnding);
end;

procedure TInterpreter.PrintNum(Val: LongInt);
begin
  PrintStr(IntToStr(Val));
end;

procedure TInterpreter.ClearOutputBuffer;
begin
  FOutputBuffer := '';
end;

procedure TInterpreter.SyntaxError;
begin
  PrintLn('?SYNTAX ERROR');
end;

function TInterpreter.ExecuteStatement(const Tokens: TTokenArray): TExecResult;
var
  Cursor: Integer;
  First: TToken;
begin
  if Length(Tokens) = 0 then
    Exit(erOk);

  Cursor := 0;
  First := Tokens[Cursor];

  case First.TokenType of
    ttEOL, ttEOF:
      Exit(erOk);

    ttRem:
      Exit(erOk);

    ttPrint, ttLet, ttIdent, ttNew, ttFree, ttList, ttRun,
    ttGoto, ttGosub, ttReturn, ttIf, ttEnd, ttExit, ttInput:
      Exit(erOk);

    else
    begin
      SyntaxError;
      Exit(erSyntaxError);
    end;
  end;
end;

end.
