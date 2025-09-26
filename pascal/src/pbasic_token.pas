unit pbasic_token;

{$mode objfpc}{$H+}

interface

type
  TTokenType = (
    ttIllegal,
    ttEOF,
    ttEOL,

    // Literals and Identifiers
    ttNumber,
    ttString,
    ttIdent,

    // Keywords
    ttLet,
    ttGoto,
    ttGosub,
    ttPrint,
    ttIf,
    ttInput,
    ttReturn,
    ttEnd,
    ttList,
    ttRun,
    ttNew,
    ttExit,
    ttRem,
    ttThen,

    // Built-in functions
    ttFree,
    ttRnd,
    ttAbs,

    // Operators
    ttPlus,
    ttMinus,
    ttStar,
    ttSlash,
    ttEq,
    ttNotEq,
    ttLt,
    ttLtEq,
    ttGt,
    ttGtEq,

    // Delimiters
    ttOpenParen,
    ttCloseParen,
    ttComma,
    ttSemicolon,
    ttColon
  );

  TToken = record
    TokenType: TTokenType;
    Literal: string;
    NumberVal: LongInt;
    VarName: Char;
  end;

  TTokenArray = array of TToken;

function CreateToken(AType: TTokenType; const ALiteral: string = ''): TToken;
function CreateNumberToken(AVal: LongInt; const ALiteral: string): TToken;
function CreateStringToken(const AStr: string): TToken;
function CreateIdentToken(AVar: Char): TToken;
function TokenTypeToString(AType: TTokenType): string;

implementation

uses
  SysUtils;

function CreateToken(AType: TTokenType; const ALiteral: string): TToken;
begin
  Result.TokenType := AType;
  Result.Literal := ALiteral;
  Result.NumberVal := 0;
  Result.VarName := #0;
end;

function CreateNumberToken(AVal: LongInt; const ALiteral: string): TToken;
begin
  Result.TokenType := ttNumber;
  Result.Literal := ALiteral;
  Result.NumberVal := AVal;
  Result.VarName := #0;
end;

function CreateStringToken(const AStr: string): TToken;
begin
  Result.TokenType := ttString;
  Result.Literal := AStr;
  Result.NumberVal := 0;
  Result.VarName := #0;
end;

function CreateIdentToken(AVar: Char): TToken;
begin
  Result.TokenType := ttIdent;
  Result.Literal := AVar;
  Result.NumberVal := 0;
  Result.VarName := AVar;
end;

function TokenTypeToString(AType: TTokenType): string;
begin
  case AType of
    ttIllegal: Result := 'ILLEGAL';
    ttEOF: Result := 'EOF';
    ttEOL: Result := 'EOL';
    ttNumber: Result := 'NUMBER';
    ttString: Result := 'STRING';
    ttIdent: Result := 'IDENT';
    ttLet: Result := 'LET';
    ttGoto: Result := 'GOTO';
    ttGosub: Result := 'GOSUB';
    ttPrint: Result := 'PRINT';
    ttIf: Result := 'IF';
    ttInput: Result := 'INPUT';
    ttReturn: Result := 'RETURN';
    ttEnd: Result := 'END';
    ttList: Result := 'LIST';
    ttRun: Result := 'RUN';
    ttNew: Result := 'NEW';
    ttExit: Result := 'EXIT';
    ttRem: Result := 'REM';
    ttThen: Result := 'THEN';
    ttFree: Result := 'FREE';
    ttRnd: Result := 'RND';
    ttAbs: Result := 'ABS';
    ttPlus: Result := '+';
    ttMinus: Result := '-';
    ttStar: Result := '*';
    ttSlash: Result := '/';
    ttEq: Result := '=';
    ttNotEq: Result := '<>';
    ttLt: Result := '<';
    ttLtEq: Result := '<=';
    ttGt: Result := '>';
    ttGtEq: Result := '>=';
    ttOpenParen: Result := '(';
    ttCloseParen: Result := ')';
    ttComma: Result := ',';
    ttSemicolon: Result := ';';
    ttColon: Result := ':';
  else
    Result := 'UNKNOWN';
  end;
end;

end.
