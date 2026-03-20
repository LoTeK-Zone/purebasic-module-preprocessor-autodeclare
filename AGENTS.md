# Agents.md

## Purpose
## Purpose
This repository contains a PureBasic preprocessor module that scans `.pb` source files and automatically repairs `Declare`, `DeclareModule`, and `Module` declaration blocks.
The preprocessor can handle multiple modules in a single source file.
The preprocessor does not follow `(X)IncludeFile` dependencies.

The tool is not a formatter.
The tool is not a refactoring engine.
The tool only manages declaration consistency based on strict scope and signature rules.

## Project Goal
Keep procedure declarations synchronized with existing procedures in PureBasic source files.

The processor must:
- add missing declarations
- delete orphan declarations
- delete duplicate declarations
- replace wrong typed declarations indirectly by deleting the wrong one and generating the correct one
- respect scope priority rules
- preserve module separation rules
- handle `CompilerIf #PB_Compiler_IsMainFile` as its own scope

## Scope Model
The source is parsed into these scopes:
- Global
- DeclareModule
- Module
- CompilerIfMainFile

Internal meaning:
- Global = normal file-level area outside modules
- DeclareModule = declaration interface of a module
- Module = implementation block
- CompilerIfMainFile = test/main execution block guarded by `CompilerIf #PB_Compiler_IsMainFile`

## Matching Logic
A declaration/procedure match is based on:
- Name
- ModuleName
- Scope
- full typed signature

Important:
- Typed signature is part of identity
- `MyFunc()` is different from `.b MyFunc()`
- `.b MyFunc()` is different from `.s MyFunc()`

The processor must never treat these as equal.

## Core Rules

### Global
- Global Procedure + no matching Global Declare = add Global Declare
- Global Declare + matching Global Procedure = keep
- Global Declare + no matching Global Procedure = delete
- duplicate Global Declare = keep first, delete rest
- wrong typed Global Declare = delete wrong, add correct

### DeclareModule
- DeclareModule Procedure + no matching DeclareModule Declare = add DeclareModule Declare
- DeclareModule Declare + matching DeclareModule Procedure = keep
- DeclareModule Declare + no DeclareModule Procedure + matching Module Procedure with same ModuleName = keep
- DeclareModule Declare + no DeclareModule Procedure + no matching Module Procedure = delete
- duplicate DeclareModule Declare = keep first, delete rest
- wrong typed DeclareModule Declare = delete wrong, add correct in DeclareModule

### Module
- Module Procedure + no matching Module Declare + no matching DeclareModule Declare = add Module Declare
- Module Declare + matching Module Procedure + no matching DeclareModule Declare = keep
- Module Declare + matching DeclareModule Declare with same Name and ModuleName = delete
- Module Declare + no matching Module Procedure = delete
- duplicate Module Declare = keep first, delete rest
- if DeclareModule wins, delete all duplicate Module declares
- wrong typed Module Declare = delete wrong, add correct in Module

## Priority Rules
Priority order:
1. delete wrong declarations
2. delete ghost declarations
3. delete duplicate declarations
4. add missing correct declarations

Special priority:
- DeclareModule wins over Module only if a matching DeclareModule declaration already exists
- if no matching DeclareModule declaration exists, Module stays independent
- do not delete valid Module declarations only because a DeclareModule block exists somewhere else
- delete first, then generate missing correct declarations

## CompilerIf Main File Rules
`CompilerIf #PB_Compiler_IsMainFile` is treated as a separate declaration scope.

This test/main block may contain procedures that need declarations inside the same local scope.
These declarations must not be mixed into the normal global declaration block unless the project rules explicitly change later.

## Source Processing Rules
The processor works line-based and comment-aware.
Before parsing:
- trim line
- ignore commented tail after `;`
- ignore empty lines
- normalize whitespace for signature comparison
- preserve original file encoding when writing back
- preserve BOM when present

## Insert Rules
New declarations are inserted:
- after `EnableExplicit` if present in the current scope
- otherwise directly after the scope start
- with configured blank lines before and after the generated declare block

## Formatting Rules
Follow repository PureBasic rules:
- `EnableExplicit` required
- code and comments in English
- 64-bit compiler
- prefer `.q` for handles and `#PB_Any`
- outside procedures use `Define`, never `Global`
- inside procedures use `Protected`
- inside procedure share structured vars and objects with `Shared`
- ASCII only
- keep function calls on a single line

## Existing Architecture
Important internal components:
- scope scanner
- procedure/declare collector
- job builder
- duplicate delete pass
- missing declare generation pass
- orphan delete pass
- special pass where DeclareModule wins against Module
- source re-rendering with insert/delete maps
- debugging and log-file 

## Non-Goals
Do not:
- rewrite unrelated code
- rename identifiers
- reorder procedures
- reformat complete files
- change comments except where generated declaration markers are intentionally added
- invent new parsing semantics without updating the rule section first

## Test Expectations
Any change to logic must be verified with at least these cases:
- pure global procedures
- DeclareModule + Module pair
- Module without DeclareModule
- duplicate declares
- wrong typed declares
- orphan declares
- mixed module and global procedures
- `CompilerIf #PB_Compiler_IsMainFile` procedures
- UTF-8 / Unicode / ASCII input handling

## Safe Change Policy for Agents
Before changing logic:
1. identify which rule is being changed
2. update this Agents.md if behavior changes
3. keep old behavior stable unless change is explicitly intended
4. prefer minimal targeted modifications
5. preserve current scope semantics

## Suggested README Relationship
README.md explains:
- what the tool does
- why it exists
- how to run it
- example before/after
- limitations
- release/install notes

AGENTS.md explains:
- how the tool thinks
- what rules must never be broken
- how future edits must be done safely