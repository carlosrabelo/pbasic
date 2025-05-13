unit pbasic_interpreter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  pbasic_signals,
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
    FCurrentLineNo: Word;
    FBranchTarget: Word;
    FBranchTaken: Boolean;
    FCaptureOutput: Boolean;
    FOutputBuffer: string;

    procedure SyntaxError;
    function ExecPrint(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
    function ExecLet(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
    function ExecNew: TExecResult;
    function ExecFree: TExecResult;
    function ExecList: TExecResult;
    function ExecGoto(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
    function ExecGosub(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
    function ExecReturn: TExecResult;
    function ExecIf(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
    function ExecEnd: TExecResult;
    function ExecExit: TExecResult;
  public
    constructor Create(AProg: TProgramStore = nil; AVars: TVariableStore = nil; ARandSeed: Word = 12345);
    destructor Destroy; override;

    procedure PrintStr(const S: string);
    procedure PrintLn(const S: string = '');
    procedure PrintNum(Val: LongInt);
    procedure ClearOutputBuffer;

    function ExecuteStatement(const Tokens: TTokenArray): TExecResult;
    function RunProgram: TExecResult;

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
  FCurrentLineNo := 0;
  FBranchTarget := 0;
  FBranchTaken := False;
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

function TInterpreter.ExecPrint(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
var
  TrailingSemicolon: Boolean;
  Tok: TToken;
  Eval: TEvaluator;
  Val: LongInt;
begin
  TrailingSemicolon := False;

  while Cursor < Length(Tokens) do
  begin
    Tok := Tokens[Cursor];
    if (Tok.TokenType = ttEOL) or (Tok.TokenType = ttEOF) then
      Break;

    if Tok.TokenType = ttString then
    begin
      PrintStr(Tok.Literal);
      Inc(Cursor);
      TrailingSemicolon := False;
    end
    else if Tok.TokenType = ttComma then
    begin
      PrintStr('        ');
      Inc(Cursor);
      TrailingSemicolon := False;
    end
    else if Tok.TokenType = ttSemicolon then
    begin
      Inc(Cursor);
      TrailingSemicolon := True;
    end
    else
    begin
      Eval := TEvaluator.Create(Tokens, FVars, FProg, @FRandSeed);
      Eval.SetCursor(Cursor);
      Val := Eval.EvalExpression();
      Cursor := Eval.GetCursor();
      Eval.Free;
      PrintNum(Val);
      TrailingSemicolon := False;
    end;
  end;

  if not TrailingSemicolon then
    PrintLn();

  Result := erOk;
end;

function TInterpreter.ExecLet(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
var
  VarName: Char;
  Eval: TEvaluator;
  Val: LongInt;
begin
  if (Cursor >= Length(Tokens)) or (Tokens[Cursor].TokenType <> ttIdent) then
  begin
    SyntaxError;
    Exit(erSyntaxError);
  end;

  VarName := Tokens[Cursor].VarName;
  Inc(Cursor);

  if (Cursor >= Length(Tokens)) or (Tokens[Cursor].TokenType <> ttEq) then
  begin
    SyntaxError;
    Exit(erSyntaxError);
  end;
  Inc(Cursor);

  Eval := TEvaluator.Create(Tokens, FVars, FProg, @FRandSeed);
  Eval.SetCursor(Cursor);
  Val := Eval.EvalExpression();
  Cursor := Eval.GetCursor();
  Eval.Free;

  if FVars <> nil then
    FVars.SetVar(VarName, Val);

  Result := erOk;
end;

function TInterpreter.ExecNew: TExecResult;
begin
  if FProg <> nil then
    FProg.Clear;
  if FVars <> nil then
    FVars.Clear;
  PrintLn('OK');
  Result := erOk;
end;

function TInterpreter.ExecFree: TExecResult;
var
  ByteSize, FreeBytes: LongInt;
begin
  ByteSize := 0;
  if FProg <> nil then
    ByteSize := FProg.ByteSize;
  if 16384 >= ByteSize then
    FreeBytes := 16384 - ByteSize
  else
    FreeBytes := 0;
  PrintNum(FreeBytes);
  PrintLn();
  Result := erOk;
end;

function TInterpreter.ExecList: TExecResult;
begin
  if FProg <> nil then
    PrintStr(FProg.ListLines);
  Result := erOk;
end;

function TInterpreter.RunProgram: TExecResult;
var
  CurLineNo: Word;
  HasLine: Boolean;
  LineTokens: TTokenArray;
  Raw: string;
  Res: TExecResult;
begin
  if (FProg = nil) or FProg.Empty then
  begin
    PrintLn('?NO PROGRAM');
    Exit(erOk);
  end;

  SetLength(FGosubStack, 0);
  FHalted := False;
  FIsRunning := True;

  HasLine := FProg.GetFirstLine(CurLineNo);

  while HasLine and (not FHalted) and (not FExitRequested) do
  begin
    if CheckAndResetInterrupted then
    begin
      FHalted := True;
      PrintLn();
      Break;
    end;

    FCurrentLineNo := CurLineNo;
    FBranchTaken := False;

    FProg.GetLine(CurLineNo, LineTokens, Raw);
    Res := ExecuteStatement(LineTokens);
    if Res = erSyntaxError then
    begin
      FIsRunning := False;
      Exit(Res);
    end;

    if FHalted or FExitRequested then
      Break;

    if FBranchTaken then
    begin
      CurLineNo := FBranchTarget;
      HasLine := FProg.HasLine(CurLineNo);
    end
    else
    begin
      HasLine := FProg.GetNextLine(FCurrentLineNo, CurLineNo);
    end;
  end;

  FIsRunning := False;
  Result := erOk;
end;

function TInterpreter.ExecGoto(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
var
  Eval: TEvaluator;
  Target: LongInt;
begin
  Eval := TEvaluator.Create(Tokens, FVars, FProg, @FRandSeed);
  Eval.SetCursor(Cursor);
  Target := Eval.EvalExpression();
  Cursor := Eval.GetCursor();
  Eval.Free;

  if (Target < 1) or (Target > 65535) or (FProg = nil) or (not FProg.HasLine(Word(Target))) then
  begin
    SyntaxError;
    FHalted := True;
    Exit(erSyntaxError);
  end;

  FBranchTarget := Word(Target);
  FBranchTaken := True;
  Result := erOk;
end;

function TInterpreter.ExecGosub(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
var
  NextLineNo: Word;
  RetLine: Word;
begin
  if Length(FGosubStack) >= 16 then
  begin
    SyntaxError;
    FHalted := True;
    Exit(erSyntaxError);
  end;

  RetLine := 0;
  if (FProg <> nil) and FProg.GetNextLine(FCurrentLineNo, NextLineNo) then
    RetLine := NextLineNo;

  SetLength(FGosubStack, Length(FGosubStack) + 1);
  FGosubStack[High(FGosubStack)] := RetLine;

  Result := ExecGoto(Tokens, Cursor);
end;

function TInterpreter.ExecReturn: TExecResult;
var
  RetLine: Word;
begin
  if Length(FGosubStack) = 0 then
  begin
    SyntaxError;
    FHalted := True;
    Exit(erSyntaxError);
  end;

  RetLine := FGosubStack[High(FGosubStack)];
  SetLength(FGosubStack, Length(FGosubStack) - 1);

  if RetLine = 0 then
  begin
    FHalted := True;
    Exit(erOk);
  end;

  FBranchTarget := RetLine;
  FBranchTaken := True;
  Result := erOk;
end;

function TInterpreter.ExecIf(const Tokens: TTokenArray; var Cursor: Integer): TExecResult;
var
  Eval: TEvaluator;
  Cond: Boolean;
  Target: Word;
  Remaining: TTokenArray;
  I, RemCount: Integer;
begin
  Eval := TEvaluator.Create(Tokens, FVars, FProg, @FRandSeed);
  Eval.SetCursor(Cursor);
  Cond := Eval.EvalCondition();
  Cursor := Eval.GetCursor();
  Eval.Free;

  if (Cursor >= Length(Tokens)) or (Tokens[Cursor].TokenType <> ttThen) then
  begin
    SyntaxError;
    Exit(erSyntaxError);
  end;
  Inc(Cursor);

  if not Cond then
    Exit(erOk);

  if (Cursor < Length(Tokens)) and (Tokens[Cursor].TokenType = ttNumber) then
  begin
    Target := Word(Tokens[Cursor].NumberVal);
    if (FProg = nil) or (not FProg.HasLine(Target)) then
    begin
      SyntaxError;
      FHalted := True;
      Exit(erSyntaxError);
    end;
    FBranchTarget := Target;
    FBranchTaken := True;
    Exit(erOk);
  end;

  RemCount := Length(Tokens) - Cursor;
  SetLength(Remaining, RemCount);
  for I := 0 to RemCount - 1 do
    Remaining[I] := Tokens[Cursor + I];

  Result := ExecuteStatement(Remaining);
end;

function TInterpreter.ExecEnd: TExecResult;
begin
  FHalted := True;
  Result := erStop;
end;

function TInterpreter.ExecExit: TExecResult;
begin
  FExitRequested := True;
  FHalted := True;
  Result := erStop;
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

    ttPrint:
    begin
      Inc(Cursor);
      Exit(ExecPrint(Tokens, Cursor));
    end;

    ttLet:
    begin
      Inc(Cursor);
      Exit(ExecLet(Tokens, Cursor));
    end;

    ttIdent:
    begin
      Exit(ExecLet(Tokens, Cursor));
    end;

    ttNew:
      Exit(ExecNew());

    ttFree:
      Exit(ExecFree());

    ttRun:
      Exit(RunProgram());

    ttList:
      Exit(ExecList());

    ttGoto:
    begin
      Inc(Cursor);
      Exit(ExecGoto(Tokens, Cursor));
    end;

    ttGosub:
    begin
      Inc(Cursor);
      Exit(ExecGosub(Tokens, Cursor));
    end;

    ttReturn:
      Exit(ExecReturn());

    ttIf:
    begin
      Inc(Cursor);
      Exit(ExecIf(Tokens, Cursor));
    end;

    ttEnd:
      Exit(ExecEnd());

    ttExit:
      Exit(ExecExit());

    ttInput:
      Exit(erOk);

    else
    begin
      SyntaxError;
      Exit(erSyntaxError);
    end;
  end;
end;

end.
