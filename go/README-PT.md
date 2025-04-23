# PBasic (Go)

Interpretador PicoBasic implementado em Go 1.24+.

## Destaques

- Implementado em Go padrão seguindo layout de pacotes `cmd/internal`
- Zero dependências externas em tempo de execução
- Prompt REPL interativo com case folding e modo imediato
- Gerenciamento de memória de programa armazenado com números de linha de 1 a 65535
- Aritmética de inteiros de 32 bits com semântica de divisão clássica de 16 bits
- Testes unitários padrão Go abrangentes e suíte de regressão automatizada

## Pré-requisitos

- **Go** — Go 1.24+ (`go`)
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
pbasic/              # Código-fonte Go (cmd/, internal/)
bin/                 # Binários compilados
.make/               # Scripts de automação
Makefile             # Makefile do componente
go.mod               # Declaração do módulo Go
```

## Desenvolvimento

```bash
make build           # Compila o binário em bin/pbasic
make test            # Executa a suíte de testes unitários Go
make quality         # Executa formatação e go vet
make clean           # Remove artefatos de compilação
```

## Licença

Este projeto está licenciado sob a Licença MIT — consulte [../LICENSE](../LICENSE) para obter detalhes.
