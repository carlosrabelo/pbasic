# PBasic (Free Pascal)

Interpretador PicoBasic implementado em Free Pascal.

## Destaques

- Implementado em Free Pascal moderno seguindo convenções do Object Pascal
- Zero dependências externas em tempo de execução
- Prompt REPL interativo com case folding e modo imediato
- Gerenciamento de memória de programa armazenado com números de linha de 1 a 65535
- Aritmética de inteiros de 32 bits com semântica de divisão clássica de 16 bits
- Suíte abrangente de testes unitários e testes de regressão automatizados

## Pré-requisitos

- **Free Pascal** — Free Pascal 3.2+ (`fpc`)
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
src/                 # Unidades de código-fonte Free Pascal (main.pas, pbasic_*.pas)
bin/                 # Binários compilados
tests/               # Executor de testes unitários
.make/               # Scripts de automação
Makefile             # Makefile do componente
```

## Desenvolvimento

```bash
make build           # Compila o binário em bin/pbasic
make test            # Executa a suíte de testes unitários Free Pascal
make quality         # Executa verificações do compilador e suíte de testes
make clean           # Remove artefatos de compilação
```

## Licença

Este projeto está licenciado sob a Licença MIT — consulte [../LICENSE](../LICENSE) para obter detalhes.
