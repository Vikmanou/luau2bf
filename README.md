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

### Supported features

- Variables and multiple assignment
- Arithmetic operators: `+`, `-`, `*`, `/`, `%`, unary `-`
- Compound assignment: `+=`, `-=`, `*=`, `/=`, `%=`
- Comparison operators: `==`, `~=`, `<`, `>`, `<=`, `>=`
- Logical operators: `and`, `or`, `not`
- Boolean literals: `true`, `false`
- Control flow: `if` / `elseif` / `else`, `while`, numeric `for`, `repeat...until`, `break`
- Output: `print(...)` — multiple arguments, tab-separated, followed by a newline
- String literals as `print()` arguments and compile-time `..` concatenation
- Math builtins: `math.max`, `math.min`

## How It Works

The compiler runs in two phases:

```
Luau source
    │
    ▼  @std/syntax  (Lute built-in parser)
Parse           Builds a typed AST from Luau source
    │
    ▼  compiler/
Generate        Walks the AST, folds constants inline, emits Brainfuck
    │
    ▼
Brainfuck
```

Parsing is handled by Lute's `@std/syntax` standard library — there is no custom lexer or parser in this project.

**Constant folding** happens inline during code generation. Expressions where both operands are numeric literals are evaluated at compile time (`3 + 2` → `5`).
Identity rules are also applied (`n * 1` → `n`, `0 * n` → `0`, etc.).

### Tape layout

Variables are allocated to consecutive cells starting at cell 0, in declaration order.

## Running the tests (AI built this workflow)

https://lute.luau.org/guide/writing-tests/
```sh
lute test
```

## Limitations

- **Values are unsigned bytes.** All variables wrap silently at 255 / 0.
- **No tables.** Table constructors, indexing, and `#` are not supported.
- **No user-defined functions.** Closures and `return` are not supported.
- **Not all standard libraries are available.** `string`, `table`, etc. are not available.

## Why?

I started this project around 3 years ago for a fun challenge on [codeguessing](https://codeguessing.gay/). Most prompts on this website allow you to use any language, but I got bored of the standard Lua and decided to go with what other people were doing. They seemed to be using esoteric languages, so the best introduction to this would obviously be Brainfuck. It actually was not as simple as I thought to make this. I picked this back up years later and finished it, even though some features are still missing.

## AI usage

- Generation of test cases in `tests/`.
- GitHub Copilot inline suggestions.
