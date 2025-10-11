program test_runner;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Process, pbasic_repl, pbasic_signals, pbasic_token, pbasic_lexer, pbasic_program, pbasic_env, pbasic_evaluator, pbasic_interpreter;

var
  TotalTests: Integer = 0;
  PassedTests: Integer = 0;
  FailedTests: Integer = 0;

procedure AssertTrue(Condition: Boolean; const TestName: string);
begin
  Inc(TotalTests);
  if Condition then
  begin
    Inc(PassedTests);
    writeln('  --- PASS: ', TestName);
  end
  else
  begin
    Inc(FailedTests);
    writeln('  --- FAIL: ', TestName);
  end;
end;

procedure AssertContains(const SubStr, Str, TestName: string);
begin
  AssertTrue(Pos(SubStr, Str) > 0, TestName + ' (expected to contain "' + SubStr + '")');
end;

function RunCommandCapture(const ExePath, Args: string; out OutputStr, StderrStr: string): Integer;
var
  Proc: TProcess;
  Buffer: array[0..1023] of Byte;
  BytesRead: LongInt;
  MemStreamOut, MemStreamErr: TMemoryStream;
begin
  Proc := TProcess.Create(nil);
  MemStreamOut := TMemoryStream.Create;
  MemStreamErr := TMemoryStream.Create;
  try
    Proc.Executable := ExePath;
    if Length(Args) > 0 then
      Proc.Parameters.Add(Args);
    Proc.Options := [poUsePipes];
    Proc.Execute;
    Proc.CloseInput;

    while Proc.Running do
    begin
      while Proc.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
          MemStreamOut.Write(Buffer, BytesRead);
      end;
      while Proc.Stderr.NumBytesAvailable > 0 do
      begin
        BytesRead := Proc.Stderr.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
          MemStreamErr.Write(Buffer, BytesRead);
      end;
      Sleep(10);
    end;

    while Proc.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
        MemStreamOut.Write(Buffer, BytesRead);
    end;
    while Proc.Stderr.NumBytesAvailable > 0 do
    begin
      BytesRead := Proc.Stderr.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
        MemStreamErr.Write(Buffer, BytesRead);
    end;

    SetLength(OutputStr, MemStreamOut.Size);
    if MemStreamOut.Size > 0 then
      Move(MemStreamOut.Memory^, OutputStr[1], MemStreamOut.Size);

    SetLength(StderrStr, MemStreamErr.Size);
    if MemStreamErr.Size > 0 then
      Move(MemStreamErr.Memory^, StderrStr[1], MemStreamErr.Size);

    Proc.WaitOnExit;
    Result := Proc.ExitCode;
  finally
    MemStreamOut.Free;
    MemStreamErr.Free;
    Proc.Free;
  end;
end;

procedure TestCLIArgumentDispatch;
var
  BinPath, TempFile, OutStr, ErrStr: string;
  ExitCode: Integer;
  F: TextFile;
begin
  writeln('=== RUN TestCLIArgumentDispatch');
  BinPath := ExtractFilePath(ParamStr(0)) + 'pbasic';

  // 1. Missing file returns error and exit code 1
  ExitCode := RunCommandCapture(BinPath, 'non_existent_file.bas', OutStr, ErrStr);
  AssertTrue(ExitCode = 1, 'TestCLIArgumentDispatch/missing_file_returns_exit_code_1');
  AssertContains('Cannot open file: non_existent_file.bas', ErrStr, 'TestCLIArgumentDispatch/missing_file_stderr_message');

  // 2. Existing file exits cleanly with code 0
  TempFile := GetTempDir + 'pbasic_test_temp.bas';
  AssignFile(F, TempFile);
  Rewrite(F);
  writeln(F, '10 PRINT "FROM FILE"');
  writeln(F, '20 END');
  CloseFile(F);

  try
    ExitCode := RunCommandCapture(BinPath, TempFile, OutStr, ErrStr);
    AssertTrue(ExitCode = 0, 'TestCLIArgumentDispatch/existing_file_exit_code_0');
  finally
    DeleteFile(TempFile);
  end;

  // 3. Interactive mode banner without arguments
  ExitCode := RunCommandCapture(BinPath, '', OutStr, ErrStr);
  AssertTrue(ExitCode = 0, 'TestCLIArgumentDispatch/interactive_banner_exit_code_0');
  AssertContains('PBasic', OutStr, 'TestCLIArgumentDispatch/interactive_banner_text');
end;

procedure AssertEquals(const Expected, Actual, TestName: string);
begin
  AssertTrue(Expected = Actual, TestName + ' (expected "' + Expected + '", got "' + Actual + '")');
end;

procedure TestConsoleIOHelpers;
var
  TempFile, Captured: string;
  F: TextFile;
  Line: string;
begin
  writeln('=== RUN TestConsoleIOHelpers');
  TempFile := GetTempDir + 'pbasic_io_capture.tmp';

  // 1. PrintStr outputs exact string
  AssignFile(F, TempFile);
  Rewrite(F);
  PrintStr(F, 'HELLO');
  CloseFile(F);

  Reset(F);
  Captured := '';
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Captured := Captured + Line;
  end;
  CloseFile(F);
  AssertEquals('HELLO', Captured, 'TestConsoleIOHelpers/PrintStr_outputs_exact_string');

  // 2. PrintNumber outputs signed 32-bit integers
  Rewrite(F);
  PrintNumber(F, 123456);
  PrintStr(F, ' ');
  PrintNumber(F, -98765);
  PrintStr(F, ' ');
  PrintNumber(F, 0);
  CloseFile(F);

  Reset(F);
  Captured := '';
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Captured := Captured + Line;
  end;
  CloseFile(F);
  AssertEquals('123456 -98765 0', Captured, 'TestConsoleIOHelpers/PrintNumber_outputs_signed_32bit_integers');

  // 3. PrintOK outputs OK followed by newline
  Rewrite(F);
  PrintOK(F);
  CloseFile(F);

  Reset(F);
  Captured := '';
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Captured := Captured + Line;
  end;
  CloseFile(F);
  AssertEquals('OK', Captured, 'TestConsoleIOHelpers/PrintOK_outputs_OK');

  DeleteFile(TempFile);
end;

procedure TestFoldCase;
begin
  writeln('=== RUN TestFoldCase');
  AssertEquals('PRINT "hello world"', FoldCase('print "hello world"'), 'TestFoldCase/preserves_quoted_string');
  AssertEquals('10 LET A = 5', FoldCase('10 let a = 5'), 'TestFoldCase/converts_keywords_and_vars');
  AssertEquals('PRINT "MiXeD cAsE"', FoldCase('print "MiXeD cAsE"'), 'TestFoldCase/preserves_mixed_case_in_quotes');
end;

procedure TestReadLine;
var
  TempFile, Line: string;
  F: TextFile;
  HasLine: Boolean;
begin
  writeln('=== RUN TestReadLine');
  TempFile := GetTempDir + 'pbasic_readline_test.tmp';
  AssignFile(F, TempFile);
  Rewrite(F);
  write(F, '10 print "hello"' + #13#10);
  write(F, '20 end' + #10);
  CloseFile(F);

  Reset(F);
  HasLine := ReadLine(F, Line);
  AssertTrue(HasLine, 'TestReadLine/first_line_exists');
  AssertEquals('10 PRINT "hello"', Line, 'TestReadLine/first_line_content');

  HasLine := ReadLine(F, Line);
  AssertTrue(HasLine, 'TestReadLine/second_line_exists');
  AssertEquals('20 END', Line, 'TestReadLine/second_line_content');

  HasLine := ReadLine(F, Line);
  AssertTrue(not HasLine, 'TestReadLine/eof_returns_false');
  CloseFile(F);

  DeleteFile(TempFile);
end;

procedure TestSignalInterruptedFlag;
begin
  writeln('=== RUN TestSignalInterruptedFlag');
  SetInterrupted(False);
  AssertTrue(not CheckAndResetInterrupted, 'TestSignalInterruptedFlag/initially_false');

  SetInterrupted(True);
  AssertTrue(CheckAndResetInterrupted, 'TestSignalInterruptedFlag/returns_true_when_set');
  AssertTrue(not CheckAndResetInterrupted, 'TestSignalInterruptedFlag/resets_to_false_after_check');
end;

procedure TestREPLStart;
var
  InFile, OutFile: TextFile;
  InPath, OutPath, Captured, Line: string;
begin
  writeln('=== RUN TestREPLStart');
  InPath := GetTempDir + 'pbasic_repl_in.tmp';
  OutPath := GetTempDir + 'pbasic_repl_out.tmp';

  AssignFile(InFile, InPath);
  Rewrite(InFile);
  writeln(InFile, 'EXIT');
  CloseFile(InFile);

  AssignFile(InFile, InPath);
  Reset(InFile);
  AssignFile(OutFile, OutPath);
  Rewrite(OutFile);

  StartREPL(InFile, OutFile);

  CloseFile(InFile);
  CloseFile(OutFile);

  AssignFile(OutFile, OutPath);
  Reset(OutFile);
  Captured := '';
  while not Eof(OutFile) do
  begin
    ReadLn(OutFile, Line);
    Captured := Captured + Line + #10;
  end;
  CloseFile(OutFile);

  AssertContains('PBasic', Captured, 'TestREPLStart/displays_banner');
  AssertContains('> ', Captured, 'TestREPLStart/displays_prompt');

  DeleteFile(InPath);
  DeleteFile(OutPath);
end;

procedure TestTokenDataStructures;
var
  T1, T2, T3, T4: TToken;
  Arr: TTokenArray;
begin
  writeln('=== RUN TestTokenDataStructures');

  T1 := CreateToken(ttPrint, 'PRINT');
  AssertTrue(T1.TokenType = ttPrint, 'TestTokenDataStructures/token_type_print');
  AssertEquals('PRINT', T1.Literal, 'TestTokenDataStructures/token_literal_print');

  T2 := CreateNumberToken(42, '42');
  AssertTrue(T2.TokenType = ttNumber, 'TestTokenDataStructures/token_type_number');
  AssertTrue(T2.NumberVal = 42, 'TestTokenDataStructures/token_numberval_42');
  AssertEquals('42', T2.Literal, 'TestTokenDataStructures/token_literal_42');

  T3 := CreateStringToken('HELLO WORLD');
  AssertTrue(T3.TokenType = ttString, 'TestTokenDataStructures/token_type_string');
  AssertEquals('HELLO WORLD', T3.Literal, 'TestTokenDataStructures/token_literal_string');

  T4 := CreateIdentToken('X');
  AssertTrue(T4.TokenType = ttIdent, 'TestTokenDataStructures/token_type_ident');
  AssertTrue(T4.VarName = 'X', 'TestTokenDataStructures/token_varname_x');
  AssertEquals('X', T4.Literal, 'TestTokenDataStructures/token_literal_x');

  SetLength(Arr, 2);
  Arr[0] := T1;
  Arr[1] := T4;
  AssertTrue(Length(Arr) = 2, 'TestTokenDataStructures/array_length');
  AssertEquals('PRINT', TokenTypeToString(Arr[0].TokenType), 'TestTokenDataStructures/type_to_string_print');
  AssertEquals('IDENT', TokenTypeToString(Arr[1].TokenType), 'TestTokenDataStructures/type_to_string_ident');
end;

procedure TestLexerPunctuation;
var
  Tokens: TTokenArray;
begin
  writeln('=== RUN TestLexerPunctuation');

  // Empty string produces single EOL token
  Tokens := Tokenize('   ');
  AssertTrue(Length(Tokens) = 1, 'TestLexerPunctuation/empty_len');
  AssertTrue(Tokens[0].TokenType = ttEOL, 'TestLexerPunctuation/empty_eol');

  // Punctuation stream with whitespace
  Tokens := Tokenize(' + - * / ( ) , ; : ');
  AssertTrue(Length(Tokens) = 10, 'TestLexerPunctuation/punct_len');
  AssertTrue(Tokens[0].TokenType = ttPlus, 'TestLexerPunctuation/tok_plus');
  AssertTrue(Tokens[1].TokenType = ttMinus, 'TestLexerPunctuation/tok_minus');
  AssertTrue(Tokens[2].TokenType = ttStar, 'TestLexerPunctuation/tok_star');
  AssertTrue(Tokens[3].TokenType = ttSlash, 'TestLexerPunctuation/tok_slash');
  AssertTrue(Tokens[4].TokenType = ttOpenParen, 'TestLexerPunctuation/tok_openparen');
  AssertTrue(Tokens[5].TokenType = ttCloseParen, 'TestLexerPunctuation/tok_closeparen');
  AssertTrue(Tokens[6].TokenType = ttComma, 'TestLexerPunctuation/tok_comma');
  AssertTrue(Tokens[7].TokenType = ttSemicolon, 'TestLexerPunctuation/tok_semicolon');
  AssertTrue(Tokens[8].TokenType = ttColon, 'TestLexerPunctuation/tok_colon');
  AssertTrue(Tokens[9].TokenType = ttEOL, 'TestLexerPunctuation/tok_eol');
end;

procedure TestLexerKeywordsAndVars;
var
  Tokens: TTokenArray;
begin
  writeln('=== RUN TestLexerKeywordsAndVars');

  // Single-letter variable recognition
  Tokens := Tokenize('A B Z');
  AssertTrue(Length(Tokens) = 4, 'TestLexerKeywordsAndVars/vars_len');
  AssertTrue(Tokens[0].TokenType = ttIdent, 'TestLexerKeywordsAndVars/tok_a');
  AssertTrue(Tokens[0].VarName = 'A', 'TestLexerKeywordsAndVars/var_a');
  AssertTrue(Tokens[1].TokenType = ttIdent, 'TestLexerKeywordsAndVars/tok_b');
  AssertTrue(Tokens[1].VarName = 'B', 'TestLexerKeywordsAndVars/var_b');
  AssertTrue(Tokens[2].TokenType = ttIdent, 'TestLexerKeywordsAndVars/tok_z');
  AssertTrue(Tokens[2].VarName = 'Z', 'TestLexerKeywordsAndVars/var_z');

  // Keywords recognition
  Tokens := Tokenize('LET PRINT IF THEN GOTO GOSUB RETURN END');
  AssertTrue(Tokens[0].TokenType = ttLet, 'TestLexerKeywordsAndVars/tok_let');
  AssertTrue(Tokens[1].TokenType = ttPrint, 'TestLexerKeywordsAndVars/tok_print');
  AssertTrue(Tokens[2].TokenType = ttIf, 'TestLexerKeywordsAndVars/tok_if');
  AssertTrue(Tokens[3].TokenType = ttThen, 'TestLexerKeywordsAndVars/tok_then');
  AssertTrue(Tokens[4].TokenType = ttGoto, 'TestLexerKeywordsAndVars/tok_goto');
  AssertTrue(Tokens[5].TokenType = ttGosub, 'TestLexerKeywordsAndVars/tok_gosub');
  AssertTrue(Tokens[6].TokenType = ttReturn, 'TestLexerKeywordsAndVars/tok_return');
  AssertTrue(Tokens[7].TokenType = ttEnd, 'TestLexerKeywordsAndVars/tok_end');

  // Built-in functions
  Tokens := Tokenize('FREE RND ABS');
  AssertTrue(Tokens[0].TokenType = ttFree, 'TestLexerKeywordsAndVars/tok_free');
  AssertTrue(Tokens[1].TokenType = ttRnd, 'TestLexerKeywordsAndVars/tok_rnd');
  AssertTrue(Tokens[2].TokenType = ttAbs, 'TestLexerKeywordsAndVars/tok_abs');

  // REM consumes rest of line
  Tokens := Tokenize('REM this is a test comment 123 + -');
  AssertTrue(Length(Tokens) = 2, 'TestLexerKeywordsAndVars/rem_len');
  AssertTrue(Tokens[0].TokenType = ttRem, 'TestLexerKeywordsAndVars/rem_type');
  AssertEquals('this is a test comment 123 + -', Tokens[0].Literal, 'TestLexerKeywordsAndVars/rem_literal');
  AssertTrue(Tokens[1].TokenType = ttEOL, 'TestLexerKeywordsAndVars/rem_eol');
end;

procedure TestLexerLiteralsAndOperators;
var
  Tokens: TTokenArray;
begin
  writeln('=== RUN TestLexerLiteralsAndOperators');

  // Integer literals
  Tokens := Tokenize('0 42 65535');
  AssertTrue(Length(Tokens) = 4, 'TestLexerLiteralsAndOperators/num_len');
  AssertTrue(Tokens[0].TokenType = ttNumber, 'TestLexerLiteralsAndOperators/num0_type');
  AssertTrue(Tokens[0].NumberVal = 0, 'TestLexerLiteralsAndOperators/num0_val');
  AssertTrue(Tokens[1].TokenType = ttNumber, 'TestLexerLiteralsAndOperators/num42_type');
  AssertTrue(Tokens[1].NumberVal = 42, 'TestLexerLiteralsAndOperators/num42_val');
  AssertTrue(Tokens[2].TokenType = ttNumber, 'TestLexerLiteralsAndOperators/num65535_type');
  AssertTrue(Tokens[2].NumberVal = 65535, 'TestLexerLiteralsAndOperators/num65535_val');

  // String literals
  Tokens := Tokenize('"HELLO WORLD" "" "123 + 456"');
  AssertTrue(Length(Tokens) = 4, 'TestLexerLiteralsAndOperators/str_len');
  AssertTrue(Tokens[0].TokenType = ttString, 'TestLexerLiteralsAndOperators/str1_type');
  AssertEquals('HELLO WORLD', Tokens[0].Literal, 'TestLexerLiteralsAndOperators/str1_val');
  AssertTrue(Tokens[1].TokenType = ttString, 'TestLexerLiteralsAndOperators/str2_type');
  AssertEquals('', Tokens[1].Literal, 'TestLexerLiteralsAndOperators/str2_val');
  AssertTrue(Tokens[2].TokenType = ttString, 'TestLexerLiteralsAndOperators/str3_type');
  AssertEquals('123 + 456', Tokens[2].Literal, 'TestLexerLiteralsAndOperators/str3_val');

  // Relational operators
  Tokens := Tokenize('= == <> <= >= < >');
  AssertTrue(Length(Tokens) = 8, 'TestLexerLiteralsAndOperators/rel_len');
  AssertTrue(Tokens[0].TokenType = ttEq, 'TestLexerLiteralsAndOperators/tok_eq');
  AssertTrue(Tokens[1].TokenType = ttEq, 'TestLexerLiteralsAndOperators/tok_eqeq');
  AssertTrue(Tokens[2].TokenType = ttNotEq, 'TestLexerLiteralsAndOperators/tok_neq');
  AssertTrue(Tokens[3].TokenType = ttLtEq, 'TestLexerLiteralsAndOperators/tok_lteq');
  AssertTrue(Tokens[4].TokenType = ttGtEq, 'TestLexerLiteralsAndOperators/tok_gteq');
  AssertTrue(Tokens[5].TokenType = ttLt, 'TestLexerLiteralsAndOperators/tok_lt');
  AssertTrue(Tokens[6].TokenType = ttGt, 'TestLexerLiteralsAndOperators/tok_gt');
  AssertTrue(Tokens[7].TokenType = ttEOL, 'TestLexerLiteralsAndOperators/rel_eol');
end;

procedure TestTokenDetokenizer;
var
  InputStr, Reconstructed: string;
  Tokens: TTokenArray;
begin
  writeln('=== RUN TestTokenDetokenizer');

  // PRINT statement round-trip
  InputStr := 'PRINT "ANSWER IS: ", 42';
  Tokens := Tokenize(InputStr);
  Reconstructed := Detokenize(Tokens);
  AssertEquals('PRINT "ANSWER IS: ", 42', Reconstructed, 'TestTokenDetokenizer/print_statement');

  // LET assignment with math expression
  InputStr := 'LET A = B + 10 * (C - 2)';
  Tokens := Tokenize(InputStr);
  Reconstructed := Detokenize(Tokens);
  AssertEquals('LET A = B + 10 * (C - 2)', Reconstructed, 'TestTokenDetokenizer/let_math_expr');

  // IF THEN statement with relational operator
  InputStr := 'IF X <> 0 THEN GOTO 100';
  Tokens := Tokenize(InputStr);
  Reconstructed := Detokenize(Tokens);
  AssertEquals('IF X <> 0 THEN GOTO 100', Reconstructed, 'TestTokenDetokenizer/if_then_goto');
end;

procedure TestProgramStoreDataStructures;
var
  Prog: TProgram;
  Line: TProgramLine;
  Toks: TTokenArray;
  Raw: string;
begin
  writeln('=== RUN TestProgramStoreDataStructures');

  // Verify ProgramLine record fields
  Line.LineNumber := 10;
  SetLength(Line.Tokens, 1);
  Line.Tokens[0] := CreateToken(ttRem, 'A COMMENT');
  Line.RawText := '10 REM A COMMENT';
  AssertTrue(Line.LineNumber = 10, 'TestProgramStoreDataStructures/line_no');
  AssertEquals('10 REM A COMMENT', Line.RawText, 'TestProgramStoreDataStructures/line_raw');

  // Verify TProgram initialization and empty state
  Prog := TProgram.Create;
  try
    AssertTrue(Prog.Empty, 'TestProgramStoreDataStructures/initially_empty');
    AssertTrue(Prog.LineCount = 0, 'TestProgramStoreDataStructures/initial_count_zero');
    AssertTrue(not Prog.HasLine(10), 'TestProgramStoreDataStructures/has_line_false');
    AssertTrue(not Prog.GetLine(10, Toks, Raw), 'TestProgramStoreDataStructures/get_line_false');
  finally
    Prog.Free;
  end;
end;

procedure TestProgramStoreInsertionAndReplacement;
var
  Prog: TProgram;
  Toks: TTokenArray;
  Raw: string;
begin
  writeln('=== RUN TestProgramStoreInsertionAndReplacement');

  Prog := TProgram.Create;
  try
    // Insert out of order: 30, 10, 20
    Prog.SetLine(30, Tokenize('PRINT "THIRTY"'), '30 PRINT "THIRTY"');
    Prog.SetLine(10, Tokenize('PRINT "TEN"'), '10 PRINT "TEN"');
    Prog.SetLine(20, Tokenize('PRINT "TWENTY"'), '20 PRINT "TWENTY"');

    AssertTrue(Prog.LineCount = 3, 'TestProgramStoreInsertionAndReplacement/count_3');
    AssertTrue(Prog.HasLine(10), 'TestProgramStoreInsertionAndReplacement/has_10');
    AssertTrue(Prog.HasLine(20), 'TestProgramStoreInsertionAndReplacement/has_20');
    AssertTrue(Prog.HasLine(30), 'TestProgramStoreInsertionAndReplacement/has_30');

    // Verify content of line 20
    AssertTrue(Prog.GetLine(20, Toks, Raw), 'TestProgramStoreInsertionAndReplacement/get_20');
    AssertEquals('20 PRINT "TWENTY"', Raw, 'TestProgramStoreInsertionAndReplacement/raw_20');

    // Replace line 20 with new statement
    Prog.SetLine(20, Tokenize('PRINT "TWENTY REPLACED"'), '20 PRINT "TWENTY REPLACED"');
    AssertTrue(Prog.LineCount = 3, 'TestProgramStoreInsertionAndReplacement/count_still_3');
    AssertTrue(Prog.GetLine(20, Toks, Raw), 'TestProgramStoreInsertionAndReplacement/get_20_replaced');
    AssertEquals('20 PRINT "TWENTY REPLACED"', Raw, 'TestProgramStoreInsertionAndReplacement/raw_20_replaced');

    // Setting empty line deletes line 10
    Prog.SetLine(10, Tokenize(''), '10');
    AssertTrue(Prog.LineCount = 2, 'TestProgramStoreInsertionAndReplacement/count_after_empty_line');
    AssertTrue(not Prog.HasLine(10), 'TestProgramStoreInsertionAndReplacement/line_10_deleted');
  finally
    Prog.Free;
  end;
end;

procedure TestProgramStoreLineDeletion;
var
  Prog: TProgram;
begin
  writeln('=== RUN TestProgramStoreLineDeletion');

  Prog := TProgram.Create;
  try
    Prog.SetLine(100, Tokenize('PRINT 100'), '100 PRINT 100');
    Prog.SetLine(200, Tokenize('PRINT 200'), '200 PRINT 200');
    Prog.SetLine(300, Tokenize('PRINT 300'), '300 PRINT 300');

    // Removing non-existent line returns false
    AssertTrue(not Prog.RemoveLine(999), 'TestProgramStoreLineDeletion/remove_nonexistent_false');
    AssertTrue(Prog.LineCount = 3, 'TestProgramStoreLineDeletion/count_unchanged');

    // Removing existing middle line returns true
    AssertTrue(Prog.RemoveLine(200), 'TestProgramStoreLineDeletion/remove_200_true');
    AssertTrue(Prog.LineCount = 2, 'TestProgramStoreLineDeletion/count_is_2');
    AssertTrue(not Prog.HasLine(200), 'TestProgramStoreLineDeletion/line_200_absent');
    AssertTrue(Prog.HasLine(100), 'TestProgramStoreLineDeletion/line_100_present');
    AssertTrue(Prog.HasLine(300), 'TestProgramStoreLineDeletion/line_300_present');

    // Removing remaining lines
    AssertTrue(Prog.RemoveLine(100), 'TestProgramStoreLineDeletion/remove_100_true');
    AssertTrue(Prog.RemoveLine(300), 'TestProgramStoreLineDeletion/remove_300_true');
    AssertTrue(Prog.Empty, 'TestProgramStoreLineDeletion/now_empty');
  finally
    Prog.Free;
  end;
end;

procedure TestProgramStoreTraversal;
var
  Prog: TProgram;
  LineNo, NextNo: Word;
begin
  writeln('=== RUN TestProgramStoreTraversal');

  Prog := TProgram.Create;
  try
    // Empty program traversal
    AssertTrue(not Prog.GetFirstLine(LineNo), 'TestProgramStoreTraversal/empty_first_false');
    AssertTrue(not Prog.GetNextLine(10, NextNo), 'TestProgramStoreTraversal/empty_next_false');

    // Populate with 10, 25, 50, 100
    Prog.SetLine(50, Tokenize('PRINT 50'), '50 PRINT 50');
    Prog.SetLine(10, Tokenize('PRINT 10'), '10 PRINT 10');
    Prog.SetLine(100, Tokenize('PRINT 100'), '100 PRINT 100');
    Prog.SetLine(25, Tokenize('PRINT 25'), '25 PRINT 25');

    // First line should be 10
    AssertTrue(Prog.GetFirstLine(LineNo), 'TestProgramStoreTraversal/get_first_true');
    AssertTrue(LineNo = 10, 'TestProgramStoreTraversal/first_is_10');

    // Next after 10 should be 25
    AssertTrue(Prog.GetNextLine(10, NextNo), 'TestProgramStoreTraversal/next_after_10_true');
    AssertTrue(NextNo = 25, 'TestProgramStoreTraversal/next_after_10_is_25');

    // Next after arbitrary line not in program (e.g. 15) should be 25
    AssertTrue(Prog.GetNextLine(15, NextNo), 'TestProgramStoreTraversal/next_after_15_true');
    AssertTrue(NextNo = 25, 'TestProgramStoreTraversal/next_after_15_is_25');

    // Next after 25 should be 50
    AssertTrue(Prog.GetNextLine(25, NextNo), 'TestProgramStoreTraversal/next_after_25_is_50');
    AssertTrue(NextNo = 50, 'TestProgramStoreTraversal/next_after_25_val');

    // Next after 50 should be 100
    AssertTrue(Prog.GetNextLine(50, NextNo), 'TestProgramStoreTraversal/next_after_50_is_100');
    AssertTrue(NextNo = 100, 'TestProgramStoreTraversal/next_after_50_val');

    // Next after 100 (or beyond) should return false
    AssertTrue(not Prog.GetNextLine(100, NextNo), 'TestProgramStoreTraversal/next_after_100_false');
    AssertTrue(not Prog.GetNextLine(200, NextNo), 'TestProgramStoreTraversal/next_after_200_false');
  finally
    Prog.Free;
  end;
end;

procedure TestProgramStoreListingAndMemory;
var
  Prog: TProgram;
  Listing: string;
  ExpectedSize: LongInt;
begin
  writeln('=== RUN TestProgramStoreListingAndMemory');

  Prog := TProgram.Create;
  try
    // Empty program listing and size
    AssertEquals('', Prog.ListLines, 'TestProgramStoreListingAndMemory/empty_list');
    AssertTrue(Prog.ByteSize = 0, 'TestProgramStoreListingAndMemory/empty_bytesize_zero');

    // Add lines 20 and 10
    Prog.SetLine(20, Tokenize('PRINT "WORLD"'), '20 PRINT "WORLD"');
    Prog.SetLine(10, Tokenize('PRINT "HELLO"'), '10 PRINT "HELLO"');

    // Formatted listing should be sorted
    Listing := Prog.ListLines;
    AssertEquals('10 PRINT "HELLO"' + #10 + '20 PRINT "WORLD"' + #10, Listing, 'TestProgramStoreListingAndMemory/sorted_listing');

    // Memory calculation:
    ExpectedSize := (4 + Length('PRINT "HELLO"') + 1) + (4 + Length('PRINT "WORLD"') + 1);
    AssertTrue(Prog.ByteSize = ExpectedSize, 'TestProgramStoreListingAndMemory/bytesize_36');
  finally
    Prog.Free;
  end;
end;

procedure TestVariableStoreContainer;
var
  Store: TVariableStore;
begin
  writeln('=== RUN TestVariableStoreContainer');

  Store := TVariableStore.Create;
  try
    AssertTrue(Store.Count = 26, 'TestVariableStoreContainer/count_26');
  finally
    Store.Free;
  end;
end;

procedure TestVariableGetSetOperations;
var
  Store: TVariableStore;
begin
  writeln('=== RUN TestVariableGetSetOperations');

  Store := TVariableStore.Create;
  try
    // Initial values are 0
    AssertTrue(Store.Get('A') = 0, 'TestVariableGetSetOperations/initial_a_zero');
    AssertTrue(Store.Get('Z') = 0, 'TestVariableGetSetOperations/initial_z_zero');

    // Setting values and reading with uppercase / lowercase
    Store.SetVal('A', 12345);
    Store.SetVal('z', -98765);
    Store.SetVar('M', 2147483647);

    AssertTrue(Store.Get('a') = 12345, 'TestVariableGetSetOperations/get_a_lowercase');
    AssertTrue(Store.Get('Z') = -98765, 'TestVariableGetSetOperations/get_z_uppercase');
    AssertTrue(Store.GetVar('M') = 2147483647, 'TestVariableGetSetOperations/get_m_maxint');

    // Invalid character returns 0 and does not crash
    AssertTrue(Store.Get('1') = 0, 'TestVariableGetSetOperations/invalid_char_zero');
    Store.SetVal('?', 999);
    AssertTrue(Store.Get('?') = 0, 'TestVariableGetSetOperations/invalid_char_ignored');

    // Clear resets all variables to 0
    Store.Clear;
    AssertTrue(Store.Get('A') = 0, 'TestVariableGetSetOperations/after_clear_a_zero');
    AssertTrue(Store.Get('Z') = 0, 'TestVariableGetSetOperations/after_clear_z_zero');
    AssertTrue(Store.Get('M') = 0, 'TestVariableGetSetOperations/after_clear_m_zero');
  finally
    Store.Free;
  end;
end;

procedure TestMul16AndArithmetic;
begin
  writeln('=== RUN TestMul16AndArithmetic');

  // Basic multiplication
  AssertTrue(Mul16(100, 20) = 2000, 'TestMul16AndArithmetic/mul_simple');

  // Overflow truncation to 16 bits: 1000 * 1000 = 1,000,000 mod 65536 = 16960
  AssertTrue(Mul16(1000, 1000) = (1000000 and $FFFF), 'TestMul16AndArithmetic/mul_overflow_trunc');

  // Max word multiplication
  AssertTrue(Mul16(65535, 2) = ((65535 * 2) and $FFFF), 'TestMul16AndArithmetic/mul_maxword');

  // 32-bit arithmetic helpers
  AssertTrue(Add32(100, 200) = 300, 'TestMul16AndArithmetic/add32');
  AssertTrue(Sub32(100, 200) = -100, 'TestMul16AndArithmetic/sub32');
  AssertTrue(Neg32(15) = -15, 'TestMul16AndArithmetic/neg32_pos');
  AssertTrue(Neg32(-15) = 15, 'TestMul16AndArithmetic/neg32_neg');
end;

procedure TestDiv16AndMod16;
var
  Seed, R1, R2: Word;
begin
  writeln('=== RUN TestDiv16AndMod16');

  // Div16 standard division
  AssertTrue(Div16(100, 10) = 10, 'TestDiv16AndMod16/div_simple');
  AssertTrue(Div16(7, 2) = 3, 'TestDiv16AndMod16/div_trunc');
  AssertTrue(Div16(0, 5) = 0, 'TestDiv16AndMod16/div_zero_num');
  AssertTrue(Div16(65535, 1) = 65535, 'TestDiv16AndMod16/div_maxword');

  // Div16 zero-divisor guards -> 65535 ($FFFF)
  AssertTrue(Div16(1234, 0) = $FFFF, 'TestDiv16AndMod16/div_zero_guard_1234');
  AssertTrue(Div16(0, 0) = $FFFF, 'TestDiv16AndMod16/div_zero_guard_0');

  // Mod16 standard modulo
  AssertTrue(Mod16(100, 10) = 0, 'TestDiv16AndMod16/mod_even');
  AssertTrue(Mod16(7, 2) = 1, 'TestDiv16AndMod16/mod_remainder');
  AssertTrue(Mod16(0, 5) = 0, 'TestDiv16AndMod16/mod_zero_num');
  AssertTrue(Mod16(65535, 10) = 5, 'TestDiv16AndMod16/mod_maxword');

  // Mod16 zero-divisor guards -> preserves dividend
  AssertTrue(Mod16(1234, 0) = 1234, 'TestDiv16AndMod16/mod_zero_guard_1234');
  AssertTrue(Mod16(0, 0) = 0, 'TestDiv16AndMod16/mod_zero_guard_0');

  // Abs32
  AssertTrue(Abs32(42) = 42, 'TestDiv16AndMod16/abs_pos');
  AssertTrue(Abs32(-42) = 42, 'TestDiv16AndMod16/abs_neg');
  AssertTrue(Abs32(0) = 0, 'TestDiv16AndMod16/abs_zero');

  // NextRND LCG
  Seed := 1;
  R1 := NextRND(Seed);
  R2 := NextRND(Seed);
  AssertTrue(R1 <> R2, 'TestDiv16AndMod16/rnd_distinct');
  AssertTrue(R1 = ((1 * 25173 + 13849) and $FFFF), 'TestDiv16AndMod16/rnd_first_value');
end;

procedure TestExpressionFactorParser;
var
  Vars: TVariableStore;
  Prog: TProgramStore;
  Seed: Word;
  Toks: TTokenArray;
  Eval: TEvaluator;
  Val: LongInt;
begin
  writeln('=== RUN TestExpressionFactorParser');
  Vars := TVariableStore.Create;
  Prog := TProgramStore.Create;
  Seed := 42;

  Vars.SetVar('A', 100);
  Vars.SetVar('Z', -50);

  // Number literal
  Toks := Tokenize('12345');
  Eval := TEvaluator.Create(Toks, Vars, Prog, @Seed);
  AssertTrue(Eval.EvalFactor = 12345, 'TestExpressionFactorParser/number');
  Eval.Free;

  // Variable lookup
  Toks := Tokenize('A');
  Eval := TEvaluator.Create(Toks, Vars, Prog, @Seed);
  AssertTrue(Eval.EvalFactor = 100, 'TestExpressionFactorParser/var_a');
  Eval.Free;

  // Unary minus
  Toks := Tokenize('-42');
  Eval := TEvaluator.Create(Toks, Vars, Prog, @Seed);
  AssertTrue(Eval.EvalFactor = -42, 'TestExpressionFactorParser/unary_minus');
  Eval.Free;

  // Unary plus
  Toks := Tokenize('+99');
  Eval := TEvaluator.Create(Toks, Vars, Prog, @Seed);
  AssertTrue(Eval.EvalFactor = 99, 'TestExpressionFactorParser/unary_plus');
  Eval.Free;

  // Parenthesized factor
  Toks := Tokenize('(777)');
  Eval := TEvaluator.Create(Toks, Vars, Prog, @Seed);
  AssertTrue(Eval.EvalFactor = 777, 'TestExpressionFactorParser/paren');
  Eval.Free;

  // ABS function
  Toks := Tokenize('ABS(Z)');
  Eval := TEvaluator.Create(Toks, Vars, Prog, @Seed);
  AssertTrue(Eval.EvalFactor = 50, 'TestExpressionFactorParser/abs');
  Eval.Free;

  // FREE function
  Toks := Tokenize('FREE');
  Eval := TEvaluator.Create(Toks, Vars, Prog, @Seed);
  AssertTrue(Eval.EvalFactor = 16384, 'TestExpressionFactorParser/free_empty');
  Eval.Free;

  // RND function
  Toks := Tokenize('RND(10)');
  Eval := TEvaluator.Create(Toks, Vars, Prog, @Seed);
  Val := Eval.EvalFactor;
  AssertTrue((Val >= 1) and (Val <= 10), 'TestExpressionFactorParser/rnd_range');
  Eval.Free;

  Vars.Free;
  Prog.Free;
end;

procedure TestExpressionTermParser;
var
  Vars: TVariableStore;
  Toks: TTokenArray;
  Eval: TEvaluator;
begin
  writeln('=== RUN TestExpressionTermParser');
  Vars := TVariableStore.Create;
  Vars.SetVar('A', 10);

  // Simple multiplication
  Toks := Tokenize('6 * 7');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalTerm = 42, 'TestExpressionTermParser/mul_simple');
  Eval.Free;

  // Simple division
  Toks := Tokenize('100 / 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalTerm = 20, 'TestExpressionTermParser/div_simple');
  Eval.Free;

  // Chained terms
  Toks := Tokenize('2 * 3 * 4');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalTerm = 24, 'TestExpressionTermParser/chained_mul');
  Eval.Free;

  Toks := Tokenize('100 / 2 / 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalTerm = 10, 'TestExpressionTermParser/chained_div');
  Eval.Free;

  // Variable in term
  Toks := Tokenize('A * 3');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalTerm = 30, 'TestExpressionTermParser/var_mul');
  Eval.Free;

  // Division by zero safe guard
  Toks := Tokenize('10 / 0');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalTerm = $FFFF, 'TestExpressionTermParser/div_by_zero');
  Eval.Free;

  // Truncation past 16 bits
  Toks := Tokenize('1000 * 1000');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalTerm = (1000000 and $FFFF), 'TestExpressionTermParser/overflow_trunc');
  Eval.Free;

  Vars.Free;
end;

procedure TestAdditiveExpressionParser;
var
  Vars: TVariableStore;
  Toks: TTokenArray;
  Eval: TEvaluator;
begin
  writeln('=== RUN TestAdditiveExpressionParser');
  Vars := TVariableStore.Create;
  Vars.SetVar('A', 5);
  Vars.SetVar('B', 10);

  // Precedence: 2 + 3 * 4 = 14
  Toks := Tokenize('2 + 3 * 4');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalExpression = 14, 'TestAdditiveExpressionParser/precedence');
  Eval.Free;

  // Parentheses overriding precedence: (2 + 3) * 4 = 20
  Toks := Tokenize('(2 + 3) * 4');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalExpression = 20, 'TestAdditiveExpressionParser/parentheses');
  Eval.Free;

  // Chained additions and subtractions: 100 - 20 - 5 + 10 = 85
  Toks := Tokenize('100 - 20 - 5 + 10');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalExpression = 85, 'TestAdditiveExpressionParser/chained_add_sub');
  Eval.Free;

  // Variables with arithmetic: A + B * 2 = 25
  Toks := Tokenize('A + B * 2');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalExpression = 25, 'TestAdditiveExpressionParser/vars_arithmetic');
  Eval.Free;

  // Complex nested expression: (10 - 2) * (3 + 1) / 2 = 16
  Toks := Tokenize('(10 - 2) * (3 + 1) / 2');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalExpression = 16, 'TestAdditiveExpressionParser/nested_complex');
  Eval.Free;

  // Unary minus with additive expression: -5 + 10 = 5
  Toks := Tokenize('-5 + 10');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalExpression = 5, 'TestAdditiveExpressionParser/unary_minus_expr');
  Eval.Free;

  Vars.Free;
end;

procedure TestRelationalExpressionEvaluator;
var
  Vars: TVariableStore;
  Toks: TTokenArray;
  Eval: TEvaluator;
begin
  writeln('=== RUN TestRelationalExpressionEvaluator');
  Vars := TVariableStore.Create;
  Vars.SetVar('X', 5);
  Vars.SetVar('Y', 10);

  // Equal
  Toks := Tokenize('10 = 10');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/eq_true');
  Eval.Free;

  Toks := Tokenize('10 = 20');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(not Eval.EvalCondition, 'TestRelationalExpressionEvaluator/eq_false');
  Eval.Free;

  // Not Equal
  Toks := Tokenize('10 <> 20');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/neq_true');
  Eval.Free;

  Toks := Tokenize('10 <> 10');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(not Eval.EvalCondition, 'TestRelationalExpressionEvaluator/neq_false');
  Eval.Free;

  // Less Than
  Toks := Tokenize('5 < 10');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/lt_true');
  Eval.Free;

  Toks := Tokenize('10 < 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(not Eval.EvalCondition, 'TestRelationalExpressionEvaluator/lt_false');
  Eval.Free;

  // Less or Equal
  Toks := Tokenize('5 <= 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/lteq_equal');
  Eval.Free;

  Toks := Tokenize('6 <= 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(not Eval.EvalCondition, 'TestRelationalExpressionEvaluator/lteq_false');
  Eval.Free;

  // Greater Than
  Toks := Tokenize('10 > 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/gt_true');
  Eval.Free;

  Toks := Tokenize('5 > 10');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(not Eval.EvalCondition, 'TestRelationalExpressionEvaluator/gt_false');
  Eval.Free;

  // Greater or Equal
  Toks := Tokenize('5 >= 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/gteq_equal');
  Eval.Free;

  Toks := Tokenize('4 >= 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(not Eval.EvalCondition, 'TestRelationalExpressionEvaluator/gteq_false');
  Eval.Free;

  // Truthiness without relational operator
  Toks := Tokenize('42');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/truthy_pos');
  Eval.Free;

  Toks := Tokenize('0');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(not Eval.EvalCondition, 'TestRelationalExpressionEvaluator/truthy_zero');
  Eval.Free;

  // Relational comparisons with arithmetic
  Toks := Tokenize('2 + 3 = 5');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/expr_arith_eq');
  Eval.Free;

  Toks := Tokenize('(10 * 2) > (5 + 3)');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/expr_arith_gt');
  Eval.Free;

  // Variables in comparison
  Toks := Tokenize('X < Y');
  Eval := TEvaluator.Create(Toks, Vars);
  AssertTrue(Eval.EvalCondition, 'TestRelationalExpressionEvaluator/vars_lt');
  Eval.Free;

  Vars.Free;
end;

procedure TestStatementDispatcherSkeleton;
var
  Interp: TInterpreter;
  Prog: TProgramStore;
  Vars: TVariableStore;
  Toks: TTokenArray;
  Res: TExecResult;
begin
  writeln('=== RUN TestStatementDispatcherSkeleton');
  Prog := TProgramStore.Create;
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(Prog, Vars);
  Interp.CaptureOutput := True;

  // Empty tokens
  SetLength(Toks, 0);
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestStatementDispatcherSkeleton/empty_tokens');

  // EOL token
  SetLength(Toks, 1);
  Toks[0] := CreateToken(ttEOL);
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestStatementDispatcherSkeleton/eol_token');

  // REM token
  Toks[0] := CreateToken(ttRem, 'A COMMENT');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestStatementDispatcherSkeleton/rem_token');

  // Known command tokens dispatched successfully
  Toks[0] := CreateToken(ttPrint);
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestStatementDispatcherSkeleton/known_cmd_print');

  // Unrecognized / syntax error
  Interp.ClearOutputBuffer;
  Toks[0] := CreateToken(ttIllegal, '@');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erSyntaxError, 'TestStatementDispatcherSkeleton/syntax_error_code');
  AssertContains('?SYNTAX ERROR', Interp.OutputBuffer, 'TestStatementDispatcherSkeleton/syntax_error_output');

  Interp.Free;
  Prog.Free;
  Vars.Free;
end;

procedure TestExecPrintFormatting;
var
  Interp: TInterpreter;
  Vars: TVariableStore;
  Toks: TTokenArray;
  ExpectedNewline: string;
begin
  writeln('=== RUN TestExecPrintFormatting');
  ExpectedNewline := LineEnding;
  Vars := TVariableStore.Create;
  Vars.SetVar('A', 42);
  Interp := TInterpreter.Create(nil, Vars);
  Interp.CaptureOutput := True;

  // String literal
  Interp.ClearOutputBuffer;
  Toks := Tokenize('PRINT "HELLO"');
  Interp.ExecuteStatement(Toks);
  AssertTrue(Interp.OutputBuffer = 'HELLO' + ExpectedNewline, 'TestExecPrintFormatting/string_literal');

  // Expression
  Interp.ClearOutputBuffer;
  Toks := Tokenize('PRINT 10 + 20');
  Interp.ExecuteStatement(Toks);
  AssertTrue(Interp.OutputBuffer = '30' + ExpectedNewline, 'TestExecPrintFormatting/expression');

  // Comma separation
  Interp.ClearOutputBuffer;
  Toks := Tokenize('PRINT A, 100');
  Interp.ExecuteStatement(Toks);
  AssertTrue(Interp.OutputBuffer = '42        100' + ExpectedNewline, 'TestExecPrintFormatting/comma_spacing');

  // Semicolon concatenation
  Interp.ClearOutputBuffer;
  Toks := Tokenize('PRINT 10; 20');
  Interp.ExecuteStatement(Toks);
  AssertTrue(Interp.OutputBuffer = '1020' + ExpectedNewline, 'TestExecPrintFormatting/semicolon_concat');

  // Trailing semicolon suppresses newline
  Interp.ClearOutputBuffer;
  Toks := Tokenize('PRINT "LINE";');
  Interp.ExecuteStatement(Toks);
  AssertTrue(Interp.OutputBuffer = 'LINE', 'TestExecPrintFormatting/trailing_semicolon');

  Interp.Free;
  Vars.Free;
end;

procedure TestExecLetStatements;
var
  Interp: TInterpreter;
  Vars: TVariableStore;
  Toks: TTokenArray;
  Res: TExecResult;
begin
  writeln('=== RUN TestExecLetStatements');
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(nil, Vars);
  Interp.CaptureOutput := True;

  // Explicit LET
  Toks := Tokenize('LET A = 100');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecLetStatements/explicit_let_ok');
  AssertTrue(Vars.Get('A') = 100, 'TestExecLetStatements/explicit_let_val');

  // Explicit LET with expression
  Toks := Tokenize('LET B = A * 2 + 5');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecLetStatements/let_expr_ok');
  AssertTrue(Vars.Get('B') = 205, 'TestExecLetStatements/let_expr_val');

  // Implicit LET
  Toks := Tokenize('C = B - 5');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecLetStatements/implicit_let_ok');
  AssertTrue(Vars.Get('C') = 200, 'TestExecLetStatements/implicit_let_val');

  // Implicit LET summing variables
  Toks := Tokenize('Z = A + B + C');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecLetStatements/implicit_sum_ok');
  AssertTrue(Vars.Get('Z') = 505, 'TestExecLetStatements/implicit_sum_val');

  // Syntax error: target not variable
  Interp.ClearOutputBuffer;
  Toks := Tokenize('LET 10 = 20');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erSyntaxError, 'TestExecLetStatements/non_var_target');
  AssertContains('?SYNTAX ERROR', Interp.OutputBuffer, 'TestExecLetStatements/non_var_output');

  // Syntax error: missing equal sign
  Interp.ClearOutputBuffer;
  Toks := Tokenize('LET A 10');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erSyntaxError, 'TestExecLetStatements/missing_equal');
  AssertContains('?SYNTAX ERROR', Interp.OutputBuffer, 'TestExecLetStatements/missing_equal_output');

  Interp.Free;
  Vars.Free;
end;

procedure TestExecNewRemFree;
var
  Interp: TInterpreter;
  Prog: TProgramStore;
  Vars: TVariableStore;
  Toks: TTokenArray;
  Res: TExecResult;
  ExpectedNewline: string;
begin
  writeln('=== RUN TestExecNewRemFree');
  ExpectedNewline := LineEnding;
  Prog := TProgramStore.Create;
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(Prog, Vars);
  Interp.CaptureOutput := True;

  // FREE on empty program: 16384
  Interp.ClearOutputBuffer;
  Toks := Tokenize('FREE');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecNewRemFree/free_empty_ok');
  AssertTrue(Interp.OutputBuffer = '16384' + ExpectedNewline, 'TestExecNewRemFree/free_empty_output');

  // Populate program and vars
  Prog.SetLine(10, Tokenize('PRINT "HELLO"'), '10 PRINT "HELLO"');
  Prog.SetLine(20, Tokenize('LET A = 99'), '20 LET A = 99');
  Vars.SetVar('A', 99);
  Vars.SetVar('B', 123);
  AssertTrue(Prog.LineCount = 2, 'TestExecNewRemFree/populated_lines');
  AssertTrue(Vars.Get('A') = 99, 'TestExecNewRemFree/populated_var');

  // FREE with program stored
  Interp.ClearOutputBuffer;
  Toks := Tokenize('FREE');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecNewRemFree/free_prog_ok');
  AssertTrue(Interp.OutputBuffer = IntToStr(16384 - Prog.ByteSize) + ExpectedNewline, 'TestExecNewRemFree/free_prog_output');

  // REM statement
  Interp.ClearOutputBuffer;
  Toks := Tokenize('REM this does nothing');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecNewRemFree/rem_ok');
  AssertTrue(Interp.OutputBuffer = '', 'TestExecNewRemFree/rem_no_output');

  // NEW statement clears program and vars and prints OK
  Interp.ClearOutputBuffer;
  Toks := Tokenize('NEW');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecNewRemFree/new_ok');
  AssertTrue(Interp.OutputBuffer = 'OK' + ExpectedNewline, 'TestExecNewRemFree/new_output');
  AssertTrue(Prog.LineCount = 0, 'TestExecNewRemFree/new_prog_cleared');
  AssertTrue(Vars.Get('A') = 0, 'TestExecNewRemFree/new_vars_cleared_a');
  AssertTrue(Vars.Get('B') = 0, 'TestExecNewRemFree/new_vars_cleared_b');

  Interp.Free;
  Prog.Free;
  Vars.Free;
end;

procedure TestRunExecutionLoop;
var
  Interp: TInterpreter;
  Prog: TProgramStore;
  Vars: TVariableStore;
  Toks: TTokenArray;
  Res: TExecResult;
  ExpectedNewline: string;
begin
  writeln('=== RUN TestRunExecutionLoop');
  ExpectedNewline := LineEnding;
  Prog := TProgramStore.Create;
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(Prog, Vars);
  Interp.CaptureOutput := True;

  // RUN empty program -> ?NO PROGRAM
  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestRunExecutionLoop/run_empty_ok');
  AssertTrue(Interp.OutputBuffer = '?NO PROGRAM' + ExpectedNewline, 'TestRunExecutionLoop/run_empty_output');

  // Multi-line program execution
  Prog.SetLine(10, Tokenize('LET A = 10'), '10 LET A = 10');
  Prog.SetLine(20, Tokenize('LET B = 20'), '20 LET B = 20');
  Prog.SetLine(30, Tokenize('PRINT A + B'), '30 PRINT A + B');

  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestRunExecutionLoop/run_multiline_ok');
  AssertTrue(Interp.OutputBuffer = '30' + ExpectedNewline, 'TestRunExecutionLoop/run_multiline_output');
  AssertTrue(Vars.Get('A') = 10, 'TestRunExecutionLoop/run_var_a');
  AssertTrue(Vars.Get('B') = 20, 'TestRunExecutionLoop/run_var_b');

  // LIST command via interpreter
  Interp.ClearOutputBuffer;
  Toks := Tokenize('LIST');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestRunExecutionLoop/list_ok');
  AssertContains('10 LET A = 10', Interp.OutputBuffer, 'TestRunExecutionLoop/list_line10');
  AssertContains('20 LET B = 20', Interp.OutputBuffer, 'TestRunExecutionLoop/list_line20');
  AssertContains('30 PRINT A + B', Interp.OutputBuffer, 'TestRunExecutionLoop/list_line30');

  // Interruption handling
  SetInterrupted(True);
  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestRunExecutionLoop/interrupted_ok');
  AssertTrue(Interp.Halted, 'TestRunExecutionLoop/interrupted_halted');

  Interp.Free;
  Prog.Free;
  Vars.Free;
end;

procedure TestExecGotoBranching;
var
  Interp: TInterpreter;
  Prog: TProgramStore;
  Vars: TVariableStore;
  Toks: TTokenArray;
  Res: TExecResult;
  ExpectedNewline: string;
begin
  writeln('=== RUN TestExecGotoBranching');
  ExpectedNewline := LineEnding;
  Prog := TProgramStore.Create;
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(Prog, Vars);
  Interp.CaptureOutput := True;

  // Unconditional jump forward skipping line 20
  Prog.SetLine(10, Tokenize('GOTO 30'), '10 GOTO 30');
  Prog.SetLine(20, Tokenize('PRINT "SKIPPED"'), '20 PRINT "SKIPPED"');
  Prog.SetLine(30, Tokenize('PRINT "TARGET"'), '30 PRINT "TARGET"');

  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecGotoBranching/forward_goto_ok');
  AssertTrue(Interp.OutputBuffer = 'TARGET' + ExpectedNewline, 'TestExecGotoBranching/forward_goto_output');

  // GOTO non-existent line produces syntax error and halts
  Prog.Clear;
  Prog.SetLine(10, Tokenize('GOTO 999'), '10 GOTO 999');
  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erSyntaxError, 'TestExecGotoBranching/invalid_target_error');
  AssertContains('?SYNTAX ERROR', Interp.OutputBuffer, 'TestExecGotoBranching/invalid_target_msg');
  AssertTrue(Interp.Halted, 'TestExecGotoBranching/invalid_target_halted');

  Interp.Free;
  Prog.Free;
  Vars.Free;
end;

procedure TestExecGosubReturn;
var
  Interp: TInterpreter;
  Prog: TProgramStore;
  Vars: TVariableStore;
  Toks: TTokenArray;
  Res: TExecResult;
  ExpectedNewline: string;
begin
  writeln('=== RUN TestExecGosubReturn');
  ExpectedNewline := LineEnding;
  Prog := TProgramStore.Create;
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(Prog, Vars);
  Interp.CaptureOutput := True;

  // Simple subroutine call and return
  Prog.SetLine(10, Tokenize('GOSUB 100'), '10 GOSUB 100');
  Prog.SetLine(20, Tokenize('PRINT "AFTER"'), '20 PRINT "AFTER"');
  Prog.SetLine(30, Tokenize('GOTO 200'), '30 GOTO 200');
  Prog.SetLine(100, Tokenize('PRINT "SUB"'), '100 PRINT "SUB"');
  Prog.SetLine(110, Tokenize('RETURN'), '110 RETURN');
  Prog.SetLine(200, Tokenize('PRINT "END"'), '200 PRINT "END"');

  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecGosubReturn/simple_gosub_ok');
  AssertTrue(Interp.OutputBuffer = 'SUB' + ExpectedNewline + 'AFTER' + ExpectedNewline + 'END' + ExpectedNewline, 'TestExecGosubReturn/simple_gosub_output');

  // Nested subroutine call
  Prog.Clear;
  Prog.SetLine(10, Tokenize('GOSUB 100'), '10 GOSUB 100');
  Prog.SetLine(20, Tokenize('GOTO 300'), '20 GOTO 300');
  Prog.SetLine(100, Tokenize('GOSUB 200'), '100 GOSUB 200');
  Prog.SetLine(110, Tokenize('PRINT "SUB1"'), '110 PRINT "SUB1"');
  Prog.SetLine(120, Tokenize('RETURN'), '120 RETURN');
  Prog.SetLine(200, Tokenize('PRINT "SUB2"'), '200 PRINT "SUB2"');
  Prog.SetLine(210, Tokenize('RETURN'), '210 RETURN');
  Prog.SetLine(300, Tokenize('PRINT "MAIN"'), '300 PRINT "MAIN"');

  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecGosubReturn/nested_gosub_ok');
  AssertTrue(Interp.OutputBuffer = 'SUB2' + ExpectedNewline + 'SUB1' + ExpectedNewline + 'MAIN' + ExpectedNewline, 'TestExecGosubReturn/nested_gosub_output');

  // RETURN without GOSUB underflow error
  Prog.Clear;
  Prog.SetLine(10, Tokenize('RETURN'), '10 RETURN');
  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erSyntaxError, 'TestExecGosubReturn/return_underflow_error');
  AssertContains('?SYNTAX ERROR', Interp.OutputBuffer, 'TestExecGosubReturn/return_underflow_msg');
  AssertTrue(Interp.Halted, 'TestExecGosubReturn/return_underflow_halted');

  Interp.Free;
  Prog.Free;
  Vars.Free;
end;

procedure TestExecIfThenBranching;
var
  Interp: TInterpreter;
  Prog: TProgramStore;
  Vars: TVariableStore;
  Toks: TTokenArray;
  Res: TExecResult;
  ExpectedNewline: string;
begin
  writeln('=== RUN TestExecIfThenBranching');
  ExpectedNewline := LineEnding;
  Prog := TProgramStore.Create;
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(Prog, Vars);
  Interp.CaptureOutput := True;

  // IF condition true jump to line number
  Prog.SetLine(10, Tokenize('IF 10 > 5 THEN 30'), '10 IF 10 > 5 THEN 30');
  Prog.SetLine(20, Tokenize('PRINT "NOT TAKEN"'), '20 PRINT "NOT TAKEN"');
  Prog.SetLine(30, Tokenize('PRINT "TAKEN"'), '30 PRINT "TAKEN"');

  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecIfThenBranching/if_true_goto_ok');
  AssertTrue(Interp.OutputBuffer = 'TAKEN' + ExpectedNewline, 'TestExecIfThenBranching/if_true_goto_output');

  // IF condition false does not jump
  Prog.Clear;
  Prog.SetLine(10, Tokenize('IF 5 > 10 THEN 30'), '10 IF 5 > 10 THEN 30');
  Prog.SetLine(20, Tokenize('PRINT "NOT TAKEN"'), '20 PRINT "NOT TAKEN"');
  Prog.SetLine(30, Tokenize('PRINT "TAKEN"'), '30 PRINT "TAKEN"');

  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecIfThenBranching/if_false_ok');
  AssertTrue(Interp.OutputBuffer = 'NOT TAKEN' + ExpectedNewline + 'TAKEN' + ExpectedNewline, 'TestExecIfThenBranching/if_false_output');

  // IF condition true executes statement
  Prog.Clear;
  Prog.SetLine(10, Tokenize('IF 1 = 1 THEN PRINT "EQUAL"'), '10 IF 1 = 1 THEN PRINT "EQUAL"');
  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecIfThenBranching/if_stmt_ok');
  AssertTrue(Interp.OutputBuffer = 'EQUAL' + ExpectedNewline, 'TestExecIfThenBranching/if_stmt_output');

  // IF syntax error: missing THEN
  Interp.ClearOutputBuffer;
  Toks := Tokenize('IF 10 > 5 PRINT 1');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erSyntaxError, 'TestExecIfThenBranching/missing_then_error');
  AssertContains('?SYNTAX ERROR', Interp.OutputBuffer, 'TestExecIfThenBranching/missing_then_msg');

  Interp.Free;
  Prog.Free;
  Vars.Free;
end;

procedure TestExecEndAndExit;
var
  Interp: TInterpreter;
  Prog: TProgramStore;
  Vars: TVariableStore;
  Toks: TTokenArray;
  Res: TExecResult;
  ExpectedNewline: string;
begin
  writeln('=== RUN TestExecEndAndExit');
  ExpectedNewline := LineEnding;
  Prog := TProgramStore.Create;
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(Prog, Vars);
  Interp.CaptureOutput := True;

  // END stops execution
  Prog.SetLine(10, Tokenize('PRINT "BEFORE"'), '10 PRINT "BEFORE"');
  Prog.SetLine(20, Tokenize('END'), '20 END');
  Prog.SetLine(30, Tokenize('PRINT "AFTER"'), '30 PRINT "AFTER"');

  Interp.ClearOutputBuffer;
  Toks := Tokenize('RUN');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erOk, 'TestExecEndAndExit/end_stmt_ok');
  AssertTrue(Interp.OutputBuffer = 'BEFORE' + ExpectedNewline, 'TestExecEndAndExit/end_stmt_output');
  AssertTrue(Interp.Halted, 'TestExecEndAndExit/end_stmt_halted');
  AssertTrue(not Interp.ExitRequested, 'TestExecEndAndExit/end_stmt_not_exit_requested');

  // EXIT command requests process termination
  Interp.ClearOutputBuffer;
  Toks := Tokenize('EXIT');
  Res := Interp.ExecuteStatement(Toks);
  AssertTrue(Res = erStop, 'TestExecEndAndExit/exit_cmd_stop');
  AssertTrue(Interp.ExitRequested, 'TestExecEndAndExit/exit_cmd_requested');
  AssertTrue(Interp.Halted, 'TestExecEndAndExit/exit_cmd_halted');

  Interp.Free;
  Prog.Free;
  Vars.Free;
end;

begin
  writeln('Running Free Pascal unit tests...');
  TestCLIArgumentDispatch;
  TestConsoleIOHelpers;
  TestFoldCase;
  TestReadLine;
  TestSignalInterruptedFlag;
  TestREPLStart;
  TestTokenDataStructures;
  TestLexerPunctuation;
  TestLexerKeywordsAndVars;
  TestLexerLiteralsAndOperators;
  TestTokenDetokenizer;
  TestProgramStoreDataStructures;
  TestProgramStoreInsertionAndReplacement;
  TestProgramStoreLineDeletion;
  TestProgramStoreTraversal;
  TestProgramStoreListingAndMemory;
  TestVariableStoreContainer;
  TestVariableGetSetOperations;
  TestMul16AndArithmetic;
  TestDiv16AndMod16;
  TestExpressionFactorParser;
  TestExpressionTermParser;
  TestAdditiveExpressionParser;
  TestRelationalExpressionEvaluator;
  TestStatementDispatcherSkeleton;
  TestExecPrintFormatting;
  TestExecLetStatements;
  TestExecNewRemFree;
  TestRunExecutionLoop;
  TestExecGotoBranching;
  TestExecGosubReturn;
  TestExecIfThenBranching;
  TestExecEndAndExit;

  writeln('');
  writeln('Test Results: ', PassedTests, ' passed, ', FailedTests, ' failed, ', TotalTests, ' total.');
  if FailedTests > 0 then
    Halt(1);
end.
