program test_runner;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Process, pbasic_repl, pbasic_signals, pbasic_token, pbasic_lexer, pbasic_program;

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

  writeln('');
  writeln('Test Results: ', PassedTests, ' passed, ', FailedTests, ' failed, ', TotalTests, ' total.');
  if FailedTests > 0 then
    Halt(1);
end.
