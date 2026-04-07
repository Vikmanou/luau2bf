# luau2bf
A compiler that translates Luau source code into Brainfuck. The compiler itself is written entirely in Luau, making this a self-contained project.

## Prerequisites

Install [Lute](https://github.com/luau-lang/lute).

## Usage

Compile a `.luau` file to Brainfuck:

```sh
lute compile.luau input.luau
```

This writes `input.bf` next to the source file and prints the output size:

```
Compiled input.luau -> input.bf (1234 characters)
```

## Example

```lua
-- factorial.luau
local n = 5
local acc = 1
while n > 0 do
    acc = acc * n
    n = n - 1
end
print(acc)
```

```sh
$ lute compile.luau factorial.luau
Compiled factorial.luau -> factorial.bf (491 characters)
```

The resulting `.bf` file runs on any standard Brainfuck interpreter:

## Language Support

### Current built-in functions

- Variables
- Arithmetic operators: `+`, `-`, `*`, `/`, `%`, unary `-`
- Comparison operators: `==`, `~=`, `<`, `>`, `<=`, `>=`
- Logical operators: `and`, `or`, `not`
- Boolean literals: `true`, `false`
- Control flow: `if` / `elseif` / `else`, `while`, numeric `for`
- Output: `print(expr)`

## How It Works

The compiler runs in three phases:

```
Luau source
    │
    ▼  lexer/
Tokenize        Scans characters into a flat token stream
    │
    ▼  parser/
Parse           Builds an Abstract Syntax Tree (AST) from the token stream
    │
    ▼  codegen/
Generate        Walks the AST and emits Brainfuck instructions
    │
    ▼
Brainfuck
```

### Tape layout

Variables are allocated to consecutive cells starting at cell 0, in declaration order.

## Running the tests (AI built this workflow)

```sh
lute test.luau
```

Each file under `tests/` declares its expected output on the first line:

```lua
-- expected: 120\n
```

The runner compiles each file, executes the Brainfuck output through the built-in interpreter, and diffs the result.

## Limitations

- **Values are unsigned bytes.** All variables wrap silently at 255 / 0.
- **No strings.** String literals and `..` concatenation are not supported.
- **No tables.** Table constructors, indexing, and `#` are not supported.
- **No user-defined functions.** Closures and `return` are not supported.
- **`print` takes one integer argument.** Multiple arguments are not supported.
- **Numeric `for` always steps by 1.** A custom step expression is not supported.
- **No standard library.** `math`, `string`, `table`, etc. are not available.

## Why?

I started this project around 3 years ago for a fun challenge on [codeguessing](https://codeguessing.gay/). Most prompts on this website allow you to use any language, but I got bored of the standard Lua and decided to go with what other people were doing. They seemed to be using esoteric languages, so the best introduction to this would obviously be Brainfuck. It actually was not as simple as I thought to make this. I picked this back up years later and finished it, even though some features are still missing.

## AI usage

- Generation of test cases in `tests/`.
- Statements and expressions in `codegen/stmts/` and `codegen/exprs/`.
- GitHub Copilot inline suggestions.
