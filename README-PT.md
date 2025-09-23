# PBasic

Interpretador BASIC de inteiros determinístico implementado em modernas linguagens de programação.

## Destaques

- Execução simples e determinística de BASIC inteiro modelada segundo interpretadores clássicos de microcomputadores
- Suporte a 26 variáveis de letra única com precisão de inteiros sinalizados de 32 bits
- Armazenamento ordenado de programas com linhas numeradas de 1 a 65535
- REPL interativo e execução de scripts em lote não interativa
- Comandos essenciais de controle de fluxo incluindo GOTO, GOSUB, RETURN e IF...THEN
- Primitivas aritméticas inteiras com semântica de divisão e módulo não sinalizados de 16 bits
- Funções embutidas RND, ABS e FREE para números pseudoaleatórios e monitoramento de memória
- Implementações consistentes em múltiplas linguagens compartilhando a mesma semântica de sintaxe e suítes de testes

## Pré-requisitos

- **GCC / Clang** — compilador C++20 necessário para o componente C++ (`g++` 11+ ou `clang++` 13+)
- **Go** — Go 1.24+ necessário para o componente Go
- **Rust** — Rust 1.70+ (`cargo`) necessário para o componente Rust
- **Make** — GNU Make 4.0+ para automação de compilação

## Instalação

### Compilar a partir do Código-Fonte

Clone o repositório e compile os componentes:

```bash
git clone https://github.com/carlosrabelo/pbasic.git
cd pbasic
make build
```

## Uso

### REPL Interativo

Inicie o interpretador de qualquer implementação sem argumentos:

```bash
# C++
./cpp/bin/pbasic

# Go
./go/bin/pbasic

# Rust
./rust/bin/pbasic
```

Sessão de exemplo:

```basic
> 10 PRINT "HELLO, WORLD!"
> 20 END
> RUN
HELLO, WORLD!
> EXIT
```

### Execução de Script em Lote

Execute um script demo compartilhado ou qualquer arquivo `.bas` diretamente com qualquer implementação:

```bash
# Executar demonstração hello world
./cpp/bin/pbasic demos/01_hello.bas
./go/bin/pbasic demos/01_hello.bas
./rust/bin/pbasic demos/01_hello.bas
```

O diretório `demos/` contém programas de exemplo padronizados:
- `demos/01_hello.bas` — Saída, laços de repetição com variáveis e iteração
- `demos/02_math.bas` — Aritmética sinalizada de 32 bits, divisão e módulo
- `demos/03_guess.bas` — Jogo interativo de adivinhação de números (`INPUT`, `RND`)
- `demos/99_test.bas` — Suíte completa de testes de regressão automatizados

## Estrutura do Projeto

```
cpp/                 # Implementação em C++20 e suíte de testes Catch2
go/                  # Implementação em Go e suíte de testes
rust/                # Implementação em Rust e suíte de testes
demos/               # Scripts BASIC de demonstração compartilhados
Makefile             # Makefile orquestrador raiz
LICENSE              # Licença MIT
```

## Desenvolvimento

```bash
make build           # Compile all components
make test            # Run tests across all components
make quality         # Run formatting and static analysis checks
make clean           # Remove build artifacts
```

## Licença

Este projeto está licenciado sob a Licença MIT — consulte [LICENSE](LICENSE) para obter detalhes.
