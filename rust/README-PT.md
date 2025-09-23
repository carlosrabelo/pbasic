# PBasic (Rust)

Interpretador PicoBasic implementado em Rust edição 2021.

## Destaques

- Implementado em Rust padrão seguindo convenções idiomáticas de módulos
- Zero dependências externas em tempo de execução
- Prompt REPL interativo com case folding e modo imediato
- Gerenciamento de memória de programa armazenado com números de linha de 1 a 65535
- Aritmética de inteiros de 32 bits com semântica de divisão clássica de 16 bits
- Suíte abrangente de testes unitários e testes de regressão automatizados

## Pré-requisitos

- **Rust** — Rust 1.70+ / edição 2021 (`rustc`, `cargo`)
- **Make** — GNU Make 4.0+

## Instalação

### Compilação a partir do código-fonte

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
./bin/pbasic programa.bas
```

## Estrutura do Projeto

```
src/                 # Código-fonte Rust (main.rs, lib.rs, módulos)
bin/                 # Binários compilados
.make/               # Scripts de automação
Makefile             # Makefile do componente
Cargo.toml           # Manifesto do pacote Cargo
```

## Desenvolvimento

```bash
make build           # Compila o binário em bin/pbasic
make test            # Executa a suíte de testes unitários Rust
make quality         # Executa formatação e verificações do clippy
make clean           # Remove artefatos de compilação
```

## Licença

Este projeto está licenciado sob a Licença MIT — consulte [../LICENSE](../LICENSE) para obter detalhes.
