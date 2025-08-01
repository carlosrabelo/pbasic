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

Inicie o interpretador sem argumentos:

```bash
./cpp/bin/pbasic
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

Execute um arquivo fonte BASIC diretamente:

```bash
./cpp/bin/pbasic program.bas
```

## Estrutura do Projeto

```
cpp/                 # C++20 implementation and Catch2 test suite
go/                  # Go implementation and test suite
rust/                # Rust implementation and test suite
Makefile             # Root orchestrator Makefile
LICENSE              # MIT License
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
