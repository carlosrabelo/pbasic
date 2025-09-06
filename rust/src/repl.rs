//! Console I/O and REPL module.

use std::fs::File;
use std::io::{self, BufRead, Write};

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
    fn test_cli_missing_file() {
        let args = vec![
            "pbasic".to_string(),
            "nonexistent_pbasic_test_12345.bas".to_string(),
        ];
        let code = run_cli(&args);
        assert_eq!(code, 1);
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
