# PBasic (C++)

Interpretador PicoBasic implementado em C++20.

## Destaques

- Implementado em ISO C++20 com arquitetura modular
- Execução rápida sem dependências externas de tempo de execução
- Prompt REPL interativo com case folding e modo direto
- Gerenciamento de memória de programa armazenado com suporte a linhas 1 a 65535
- Aritmética inteira de 32 bits com semântica clássica de divisão de 16 bits
- Infraestrutura de testes unitários com Catch2

## Pré-requisitos

- **GCC / Clang** — compilador C++20 (`g++` 11+ ou `clang++` 13+)
- **Make** — GNU Make 4.0+

## Instalação

### Compilar a partir do Código-Fonte

```bash
make build
```

## Uso

### REPL Interativo

```bash
./bin/pbasic
```

### Execução de Arquivo em Lote

```bash
./bin/pbasic program.bas
```

## Estrutura do Projeto

```
src/                 # C++20 source code (main.cpp, core/)
tests/               # Catch2 test suites
lib/                 # Vendored third-party headers (Catch2)
bin/                 # Compiled binaries
.make/               # Automation scripts
Makefile             # Component Makefile
```

## Desenvolvimento

```bash
make setup           # Download test dependencies (Catch2)
make build           # Compile binary to bin/pbasic
make test            # Build and run Catch2 test suite
make quality         # Run format checks and test suite
make clean           # Remove build artifacts
```

## Licença

Este projeto está licenciado sob a Licença MIT — consulte [../LICENSE](../LICENSE) para obter detalhes.
