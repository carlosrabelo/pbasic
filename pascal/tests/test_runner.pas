program test_runner;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Process;

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
    Proc.Options := [poWaitOnExit, poUsePipes];
    Proc.Execute;

    // Read Output
    while Proc.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
        MemStreamOut.Write(Buffer, BytesRead);
    end;

    // Read Stderr
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

    Result := Proc.ExitStatus;
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

begin
  writeln('Running Free Pascal unit tests...');
  TestCLIArgumentDispatch;

  writeln('');
  writeln('Test Results: ', PassedTests, ' passed, ', FailedTests, ' failed, ', TotalTests, ' total.');
  if FailedTests > 0 then
    Halt(1);
end.
