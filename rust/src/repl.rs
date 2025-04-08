//! Console I/O and REPL module.

use std::fs::File;
use std::io::{self, BufRead, Write};

/// Emits a string to standard output without newline.
pub fn print_str(s: &str) {
    print!("{}", s);
}

/// Emits signed 32-bit integer in decimal format without leading or trailing spaces.
pub fn print_number(val: i32) {
    print!("{}", val);
}

/// Emits a newline character.
pub fn print_crlf() {
    println!();
}

/// Emits the "OK" confirmation prompt followed by newline.
pub fn print_ok() {
    println!("OK");
}

/// Writes a string to the given writer without newline.
pub fn write_str<W: Write>(w: &mut W, s: &str) -> io::Result<()> {
    write!(w, "{}", s)
}

/// Writes signed 32-bit integer in decimal format to the given writer.
pub fn write_number<W: Write>(w: &mut W, val: i32) -> io::Result<()> {
    write!(w, "{}", val)
}

/// Writes a newline character to the given writer.
pub fn write_crlf<W: Write>(w: &mut W) -> io::Result<()> {
    writeln!(w)
}

/// Writes the "OK" confirmation followed by newline to the given writer.
pub fn write_ok<W: Write>(w: &mut W) -> io::Result<()> {
    writeln!(w, "OK")
}

/// Folds ASCII lowercase letters to uppercase outside double quotes (`"..."`).
pub fn fold_case(line: &str) -> String {
    let mut result = String::with_capacity(line.len());
    let mut in_quote = false;

    for ch in line.chars() {
        if ch == '"' {
            in_quote = !in_quote;
            result.push(ch);
        } else if in_quote {
            result.push(ch);
        } else {
            result.push(ch.to_ascii_uppercase());
        }
    }

    result
}

/// Reads a line from reader, strips trailing newline/CRLF, and applies case folding.
/// Returns Ok(None) on EOF.
pub fn read_line<R: BufRead>(reader: &mut R) -> io::Result<Option<String>> {
    let mut line = String::new();
    let bytes_read = reader.read_line(&mut line)?;
    if bytes_read == 0 {
        return Ok(None);
    }

    if line.ends_with('\n') {
        line.pop();
        if line.ends_with('\r') {
            line.pop();
        }
    } else if line.ends_with('\r') {
        line.pop();
    }

    Ok(Some(fold_case(&line)))
}

/// Dispatches execution based on command line arguments.
///
/// If no file argument is provided, enters interactive REPL mode.
/// If a file argument is provided, executes the script in batch mode.
pub fn run_cli(args: &[String]) -> i32 {
    if args.len() <= 1 {
        run();
        0
    } else {
        let path = &args[1];
        let file = match File::open(path) {
            Ok(f) => f,
            Err(_) => {
                eprintln!("Cannot open file: {}", path);
                return 1;
            }
        };
        let reader = io::BufReader::new(file);
        run_file(reader);
        0
    }
}

pub fn run() {
    print!("{}", crate::banner());
    let stdin = io::stdin();
    let stdout = io::stdout();
    let mut reader = stdin.lock();
    let mut writer = stdout.lock();
    let _ = run_loop(&mut reader, &mut writer);
}

pub fn run_file<R: BufRead>(_reader: R) {
    // Stored program loading and execution will be integrated in subsequent tasks
}

pub fn run_loop<R: BufRead, W: Write>(_reader: &mut R, _writer: &mut W) -> io::Result<()> {
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn test_console_output_helpers() {
        let mut buf = Vec::new();
        write_str(&mut buf, "HELLO").unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "HELLO");

        buf.clear();
        write_number(&mut buf, 0).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "0");

        buf.clear();
        write_number(&mut buf, 12345).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "12345");

        buf.clear();
        write_number(&mut buf, -6789).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "-6789");

        buf.clear();
        write_crlf(&mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "\n");

        buf.clear();
        write_ok(&mut buf).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "OK\n");
    }

    #[test]
    fn test_fold_case() {
        assert_eq!(fold_case("print \"hello world\""), "PRINT \"hello world\"");
        assert_eq!(
            fold_case("10 let a = 5 : rem \"don't touch lowercase\""),
            "10 LET A = 5 : REM \"don't touch lowercase\""
        );
        assert_eq!(fold_case("goto 100"), "GOTO 100");
    }

    #[test]
    fn test_read_line() {
        let input = "10 print \"hi\"\r\n20 goto 10\n";
        let mut cursor = std::io::Cursor::new(input);

        let line1 = read_line(&mut cursor).unwrap();
        assert_eq!(line1, Some("10 PRINT \"hi\"".to_string()));

        let line2 = read_line(&mut cursor).unwrap();
        assert_eq!(line2, Some("20 GOTO 10".to_string()));

        let line3 = read_line(&mut cursor).unwrap();
        assert_eq!(line3, None);
    }

    #[test]
    fn test_cli_existing_file() {
        let temp_dir = std::env::temp_dir();
        let test_file = temp_dir.join("pbasic_test_existing.bas");
        {
            let mut f = File::create(&test_file).unwrap();
            writeln!(f, "10 PRINT \"HI\"").unwrap();
        }
        let args = vec![
            "pbasic".to_string(),
            test_file.to_str().unwrap().to_string(),
        ];
        let code = run_cli(&args);
        let _ = std::fs::remove_file(&test_file);
        assert_eq!(code, 0);
    }
}
