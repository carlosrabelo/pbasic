program test_runner;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Process, pbasic_repl, pbasic_signals;

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

begin
  writeln('Running Free Pascal unit tests...');
  TestCLIArgumentDispatch;
  TestConsoleIOHelpers;
  TestFoldCase;
  TestReadLine;
  TestSignalInterruptedFlag;
  TestREPLStart;

  writeln('');
  writeln('Test Results: ', PassedTests, ' passed, ', FailedTests, ' failed, ', TotalTests, ' total.');
  if FailedTests > 0 then
    Halt(1);
end.
