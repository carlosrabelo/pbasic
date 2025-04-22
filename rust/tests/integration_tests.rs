use pbasic::interpreter::Interpreter;
use pbasic::repl::{run_file_with_interp, run_loop_with_interp};
use std::io::Cursor;

#[test]
fn test_integration_hello_loop() {
    let mut interp = Interpreter::new();
    let mut out = Vec::new();

    let code = "10 LET A = 1\n20 PRINT \"COUNT:\", A\n30 LET A = A + 1\n40 IF A <= 3 THEN GOTO 20\n50 END\n";
    let mut cursor = Cursor::new(code);
    run_file_with_interp(&mut cursor, &mut out, &mut interp).unwrap();

    let out_str = String::from_utf8(out).unwrap();
    assert!(out_str.contains("COUNT:        1"));
    assert!(out_str.contains("COUNT:        2"));
    assert!(out_str.contains("COUNT:        3"));
    assert!(!out_str.contains("COUNT:        4"));
}

#[test]
fn test_integration_gosub_return() {
    let mut interp = Interpreter::new();
    let mut out = Vec::new();

    let code = "10 PRINT \"START\"\n20 GOSUB 100\n30 PRINT \"BACK\"\n40 END\n100 PRINT \"SUBROUTINE\"\n110 RETURN\n";
    let mut cursor = Cursor::new(code);
    run_file_with_interp(&mut cursor, &mut out, &mut interp).unwrap();

    let out_str = String::from_utf8(out).unwrap();
    let lines: Vec<&str> = out_str.lines().collect();
    assert_eq!(lines, vec!["START", "SUBROUTINE", "BACK"]);
}

#[test]
fn test_integration_math_and_functions() {
    let mut interp = Interpreter::new();
    let mut out = Vec::new();

    let code = "10 LET X = -42\n20 LET Y = ABS(X)\n30 PRINT \"ABS:\", Y\n40 PRINT \"FREE:\", FREE\n50 END\n";
    let mut cursor = Cursor::new(code);
    run_file_with_interp(&mut cursor, &mut out, &mut interp).unwrap();

    let out_str = String::from_utf8(out).unwrap();
    assert!(out_str.contains("ABS:        42"));
    assert!(out_str.contains("FREE:        "));
}

#[test]
fn test_integration_repl_immediate_and_list() {
    let mut interp = Interpreter::new();
    let mut out = Vec::new();

    let commands = "LET A = 10\nPRINT A * 5\n10 PRINT \"STORED LINE\"\nLIST\nEXIT\n";
    let mut cursor = Cursor::new(commands);
    run_loop_with_interp(&mut cursor, &mut out, &mut interp).unwrap();

    let out_str = String::from_utf8(out).unwrap();
    assert!(out_str.contains("50"));
    assert!(out_str.contains("10 PRINT \"STORED LINE\""));
}

#[test]
fn test_integration_program_reset_with_new() {
    let mut interp = Interpreter::new();
    let mut out = Vec::new();

    let commands = "10 PRINT 100\n20 PRINT 200\nNEW\nLIST\n";
    let mut cursor = Cursor::new(commands);
    run_loop_with_interp(&mut cursor, &mut out, &mut interp).unwrap();

    let out_str = String::from_utf8(out).unwrap();
    assert!(!out_str.contains("10 PRINT 100"));
}

#[test]
fn test_integration_cli_binary() {
    let bin_path = env!("CARGO_BIN_EXE_pbasic");
    let _output = std::process::Command::new(bin_path)
        .arg("--version")
        .output();

    // Invoking binary with nonexistent file exits with code 1
    let fail_output = std::process::Command::new(bin_path)
        .arg("nonexistent_script_12345.bas")
        .output()
        .expect("Failed to execute binary");

    assert_eq!(fail_output.status.code(), Some(1));
    let stderr = String::from_utf8_lossy(&fail_output.stderr);
    assert!(stderr.contains("Cannot open file: nonexistent_script_12345.bas"));
}
