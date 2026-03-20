# LoTeK PureBasic PreProcessor AutoDeclare

AutoDeclare is a PureBasic preprocessor tool that synchronizes `Declare`, `DeclareModule`, `Module`, and compiler-scope declarations with existing `Procedure` definitions inside a single `.pb` source file.

## Badges

![Language](https://img.shields.io/badge/language-PureBasic-red?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Windows-0078D6?style=flat-square&logo=windows)
![Platform](https://img.shields.io/badge/platform-Linux-FCC624?style=flat-square&logo=linux)
![Platform](https://img.shields.io/badge/platform-macOS-999999?style=flat-square&logo=apple)
![Version](https://img.shields.io/badge/version-v0.3.0-blue?style=flat-square&logo=github)
![Status](https://img.shields.io/badge/status-active-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square&logo=open-source-initiative)

## Overview

AutoDeclare is a scope-aware PureBasic declaration synchronizer.
It analyzes one source file, detects procedures and declarations, compares both sets inside their structural scope context, removes invalid declarations, and generates missing valid declarations.
The tool is intended for structured PureBasic projects with `DeclareModule`, `Module`, explicit declaration management, and compiler-guarded test or main sections.
This project was developed with the assistance of AI tools for research, coding support, and documentation.

## Purpose

`Mod_PreProcessor_Declare` analyzes a PureBasic source file and automatically:

- scans all `Procedure` definitions
- scans all `Declare` statements
- detects structural scopes
- generates missing declarations
- removes obsolete declarations
- inserts new declarations at structurally correct positions
- preserves module indentation rules

The source file is modified in place.

## Releases

### Windows x64

A precompiled **Windows x64** build is available in the **Releases** section.

- File: `LoTeK_PureBasic_PreProcessor_AutoDeclare_Win64_v0.3.0.exe`
- Platform: Windows 64-bit
- Built with: PureBasic 6.30

If you do not want to compile the tool yourself, you can download the ready-to-use executable from the latest release.

**Download:** [LoTeK_PureBasic_PreProcessor_AutoDeclare_Win64_v0.3.0.exe](https://github.com/LoTeK-Zone/purebasic-module-preprocessor-autodeclare/releases/download/v0.3.0/LoTeK_PureBasic_PreProcessor_AutoDeclare_Win64_v0.3.0.exe)

## Note on the position of generated declares

The tool inserts detected `Declare` statements at a sensible default location:

- in the global scope at the top of the file
- inside `DeclareModule`, `Module` or `CompilerIf #PB_Compiler_IsMainFile` blocks at the top of these sections
- after `EnableExplicit`, if present

Depending on the project structure, it may still be necessary to manually move generated `Declare` lines to a different location afterwards, for example below structure definitions, constants, prototypes, or other project-specific declaration sections.
This tool is intended as a practical automation aid, not as a complete replacement for project-specific code organization.

## Features

- automatic generation of missing declarations
- automatic deletion of obsolete declarations
- duplicate declaration cleanup
- typed declaration validation
- support for `DeclareModule`
- support for `Module`
- support for multiple modules in one source file
- support for compiler scope
- deterministic single-file processing
- scope-aware synchronization logic

## Core Concept

This tool performs structural scope parsing, not simple text replacement.

It builds an internal work state containing:

- all detected scopes
- all detected procedures
- all detected declarations
- scope-based transformation rules

Based on this state, it calculates which declarations must be removed and which declarations must be generated.

## Recognized Scopes

The following scopes are detected automatically:

- `Global`
- `DeclareModule`
- `Module`
- `Compiler`

`Compiler` refers to declarations and procedures inside `CompilerIf #PB_Compiler_IsMainFile`.

Everything outside recognized block scopes is treated as global file scope.

Each relevant scope stores structural metadata such as:

- start line
- end line
- whether `EnableExplicit` exists in that scope
- line number of `EnableExplicit`, if present

## Matching Model

Declarations and procedures are compared by a strict match key:

- name
- module name
- scope
- typed signature

This means:

- `MyFunc()` is different from `.b MyFunc()`
- `.b MyFunc()` is different from `.s MyFunc()`

A wrong typed declaration is treated as invalid, deleted, and regenerated correctly.

## Scope Rules

### Global

- global `Procedure` without matching global `Declare` -> add missing global `Declare`
- global `Declare` with matching global `Procedure` -> keep
- global `Declare` without matching global `Procedure` -> delete
- duplicate global `Declare` entries -> keep first, delete rest
- wrong typed global `Declare` -> delete wrong declaration, add correct declaration

### DeclareModule

- `DeclareModule` procedure without matching `DeclareModule` declaration -> add missing `DeclareModule` declaration
- `DeclareModule` declaration with matching `DeclareModule` procedure -> keep
- `DeclareModule` declaration without local `DeclareModule` procedure but with matching `Module` procedure of same module -> keep
- `DeclareModule` declaration without matching `DeclareModule` procedure and without matching `Module` procedure -> delete
- duplicate `DeclareModule` declarations -> keep first, delete rest
- wrong typed `DeclareModule` declaration -> delete wrong declaration, add correct declaration in `DeclareModule`

### Module

- `Module` procedure without matching `Module` declaration and without matching `DeclareModule` declaration -> add missing `Module` declaration
- `Module` declaration with matching `Module` procedure and no matching `DeclareModule` declaration -> keep
- `Module` declaration with matching `DeclareModule` declaration of same name and module -> delete
- `Module` declaration without matching `Module` procedure -> delete
- duplicate `Module` declarations -> keep first, delete rest
- if a matching `DeclareModule` declaration exists, `DeclareModule` wins over `Module`
- wrong typed `Module` declaration without matching `DeclareModule` declaration -> delete wrong declaration, add correct declaration in `Module`
- wrong typed `Module` declaration with matching `DeclareModule` declaration -> delete `Module` declaration

### Compiler

- compiler-scope `Procedure` without matching compiler-scope `Declare` -> add missing compiler-scope `Declare`
- compiler-scope `Declare` with matching compiler-scope `Procedure` -> keep
- compiler-scope `Declare` without matching compiler-scope `Procedure` -> delete
- duplicate compiler-scope `Declare` entries -> keep first, delete rest
- wrong typed compiler-scope `Declare` -> delete wrong declaration, add correct declaration

## Processing Rules

The processor follows this priority order:

1. delete wrong declarations
2. delete obsolete declarations
3. delete duplicate declarations
4. add missing correct declarations

Important behavior:

- `DeclareModule` only wins over `Module` if a matching `DeclareModule` declaration already exists
- if no matching `DeclareModule` declaration exists, the `Module` declaration remains independent
- declarations are not matched by name alone
- the typed signature is part of the identity
- the tool does not perform general refactoring outside declaration management

## Synchronization Logic

Internal execution flow:

1. build list of all procedures
2. build list of all declarations
3. compare both sets by scope and signature
4. calculate delete jobs and generate jobs
5. sort jobs in safe execution order
6. modify source lines
7. overwrite original file

Execution is deterministic and scope-aware.

## Indentation Behavior

Default indentation inside modules is controlled by `sModuleIndent$`.

Alternative values may use spaces, tabs, or repeated tab characters.

Indentation is automatically applied when a declaration is generated inside:

- `DeclareModule`
- `Module`

## Supported Code Structures

Supported:

- PureBasic `.pb` source files
- global procedures and declarations
- `DeclareModule`
- `Module`
- multiple modules in one file
- `CompilerIf #PB_Compiler_IsMainFile`
- typed procedure declarations
- duplicate, obsolete, and wrong declaration cleanup

Not supported:

- cross-file analysis
- `XIncludeFile` dependency tracking
- project-wide scanning
- automatic processing of included files
- DLL import declaration management
- full semantic parsing of arbitrary PureBasic syntax beyond declaration synchronization requirements

## File Processing Model

AutoDeclare processes exactly one source file at a time.

The tool does not follow `XIncludeFile` dependencies and does not scan the full project structure. Only the currently processed source file is analyzed and modified.

This behavior is intentional and keeps processing deterministic, local, and transparent.

## Repository Structure

```
.
├── src
│   └── Mod_AutoDeclare.pb
├── tests
│   └── Test_AutoDeclare.pb
├── CHANGELOG.md
├── LICENSE
├── README.md
└── AGENTS.md
```

- `src/` contains the production module
- `tests/` contains the manual test file
- `AGENTS.md` contains the internal behavior contract and maintenance rules

## Installation

<details>
<summary>Installation instructions</summary>

### PureBasic IDE Integration

Add the compiled tool as a Custom Tool inside the PureBasic IDE.

Parameters:  
%FILE

This passes the currently opened source file to the precompiler.

### Screenshot

![PureBasic IDE Custom Tool Setup](assets/img/Installation_PB_IDE_Screenshot_1.png)

Screenshot description:  

Event to trigger the Tools:
- Menu or Shortcut
- Befor Compile/Run

</details>

## Execution

The tool expects the source file path as program parameter: `ProgramParameter(0)`.

Typical execution flow:

- validate parameter
- check file existence
- load source into line list
- process scopes
- process procedures and declarations
- build synchronization diff
- apply modifications
- overwrite original file

## PureBasic IDE Integration

Add the tool as a Custom Tool inside the PureBasic IDE.

Program:
[PLACEHOLDER_EXE_PATH]

Parameters:
%FILE

Working Directory:
%PATH

This passes the currently opened file to the precompiler.

## Usage

Typical workflow:

1. pass a PureBasic source file to the tool
2. analyze existing `Procedure`, `Declare`, `DeclareModule`, `Module`, and compiler-scope blocks
3. delete invalid declarations
4. generate missing correct declarations
5. save the processed file back to disk

For manual testing, use `tests/TestFile.pb`.

The module also provides a test/debug mode so a dedicated test file can be processed instead of the IDE-supplied file parameter.

## Typical Result

After processing:

- obsolete declarations are removed
- missing declarations are generated in the correct scope
- duplicate declarations are reduced to a single valid entry
- wrong typed declarations are deleted and regenerated correctly

## Safety Notes

- the original file is overwritten
- no automatic backup is created
- version control is strongly recommended
- Git is recommended before running batch tests or structural changes

## Safety and Intent

AutoDeclare is a focused declaration repair tool.

It does not try to:

- rewrite unrelated source code
- rename procedures
- refactor module structure
- interpret full project dependencies
- act as a general formatter

Its purpose is strictly limited to keeping declaration blocks consistent with the actual procedures found in the currently processed file.

## Version

- version: `v0.3.0`
- status: core logic stable

## License

This project is licensed under the MIT License.

See the `LICENSE` file for details.