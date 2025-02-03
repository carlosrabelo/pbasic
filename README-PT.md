# PBasic

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Interpretador PBasic multi-arquitetura (MIPS/Z80/M6502) escrito em assembly. A versão MIPS roda nos simuladores SPIM e MARS; as versões Z80 e M6502 estão em desenvolvimento para testar a plataforma de emuladores [MOJAVE](https://github.com/carlosrabelo/mojave).

## Destaques

- Dialeto PBasic com suporte a LET, PRINT, IF/THEN, LIST, NEW, EXIT, REM, INPUT, RUN, END e FREE
- Avaliador de expressões com análise de descida recursiva (+, -, *, /, parênteses, menos unário)
- 26 variáveis (A-Z) armazenadas como inteiros de 32 bits
- Área de programa de 52 KB com armazenamento de linhas tokenizadas como uma lista encadeada
- Função FREE relata a memória disponível (como comando ou em expressões)
- I/O via chamadas de sistema (syscalls) padrão do SPIM/MARS (modo `mapped_io` para entrada interativa)

## Visão Geral

O PBasic começou em 2014 como um projeto de paixão durante a minha faculdade de Ciência da Computação.

O projeto agora está se expandindo para além do MIPS: as versões para **Z80** e **M6502** estão em desenvolvimento. Estas novas implementações compartilham o mesmo dialeto PBasic e servem como casos de teste reais para o [MOJAVE](https://github.com/carlosrabelo/mojave), um framework multi-plataforma de emuladores. Originalmente escrito em assembly MIPS para rodar no simulador MARS, criei o projeto como uma forma de demonstrar aos meus colegas de classe que a linguagem assembly MIPS poderia ser usada para construir softwares práticos e funcionais — como um interpretador BASIC completo —, indo além de simples exercícios acadêmicos.

## Pré-requisitos

- **spim** — simulador MIPS; instale com `sudo apt install spim`
- **mars** — MIPS Assembler and Runtime Simulator (opcional, baixe de [missouristate.edu/MARS](https://courses.missouristate.edu/KenVollmar/MARS/))

## Instalação

### Compilar a partir do código-fonte

```bash
git clone https://github.com/carlosrabelo/pbasic.git
cd pbasic
make build
```

## Uso

### Compilar e executar

```bash
make run                    # usa spim
make run EMULATOR=mars      # usa MARS
```

### Apenas compilar

```bash
make build
```

Isso concatena todos os módulos assembly MIPS em um único arquivo fonte:

```bash
# Rodar o código assembly MIPS no simulador SPIM
spim -mapped_io -file bin/mips/pbasic.s

# Rodar o código assembly MIPS no simulador MARS
java -jar MARS.jar bin/mips/pbasic.s
```

### Exemplo de sessão

```
PBasic

> 10 LET A=42
> 20 PRINT A
> 30 PRINT A*2+10
> RUN
42
94
> PRINT FREE
53160
> LIST
10 LET A=42
20 PRINT A
30 PRINT A*2+10
> NEW
OK
```

## Estrutura do Projeto

```
src/mips/           # Fontes em assembly MIPS
src/z80/            # Fontes em assembly Z80 (em desenvolvimento)
src/m6502/          # Fontes em assembly M6502 (em desenvolvimento)
demos/              # Programas BASIC de demonstração e testes
bin/mips/           # Código fonte MIPS compilado (ignorado no git)
bin/z80/            # Código fonte Z80 compilado (ignorado no git)
bin/m6502/          # Código fonte M6502 compilado (ignorado no git)
Makefile            # Orquestrador de build
.make/              # Scripts auxiliares de build
```

## Desenvolvimento

```bash
make help              # Mostra os alvos disponíveis
make build             # Compila todas as plataformas
make build-mips        # Concatena os fontes MIPS
make build-z80         # Monta os fontes Z80 em .bin
make build-m6502       # Monta os fontes M6502 em .bin
make run               # Compila e executa MIPS no SPIM/MARS
make run-mips          # Compila e executa MIPS no SPIM/MARS
make clean             # Remove os artefatos de build
```

## Licença

Este projeto está licenciado sob a Licença MIT — veja [LICENSE](LICENSE) para detalhes.
