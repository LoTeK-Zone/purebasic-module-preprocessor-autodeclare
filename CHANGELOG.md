# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog,
and this project adheres to Semantic Versioning.

## [0.3.0] - 2026-03-20

### Added
- `README.md`
- `AGENTS.md`
- project license
- installation and usage documentation

### Changed
- simplified internal code paths
- improved debug, test workflow and logging
- updated test data
- applied general cleanup and code optimization
- consolidated repository structure for publication

### Notes
- initial public release
- This version mainly consolidates the repository structure, documentation, test handling, and release preparation.

## [0.2.0] - 2026-03-05

### Added
- extended debug capabilities for direct testing without compiling to EXE first
- dedicated standalone test file for parser and logic testing
- duplicate detection for duplicate procedure and function names

### Changed
- revised and expanded complex test data
- reorganized and refactored large parts of the codebase
- simplified parser logic for `Declare` / `Procedure` synchronization
- separated development and testing workflow more clearly from normal runtime workflow
- optimized internal code structure and processing flow

### Fixed
- improved parser stability for edge cases in module and declaration handling

## [0.1.3] - 2026-03-02

### Added
- whitespace stripping and normalization for more robust parsing

### Changed
- simplified internal options structures

## [0.1.2] - 2026-02-27

### Changed
- internal cleanup and intermediate development updates

## [0.1.1] - 2026-02-25

### Added
- BOM detection to ensure the first line is parsed reliably
- whitespace removal
- basic error handling and logging

### Fixed
- false detection in `DeclareModule` handling that caused valid `Declare` lines to be removed
- cases where generated `Declare` lines were written to incorrect positions

## [0.1.0] - 2026-02-24

### Added
- initial version
- core parser for `Declare` / `Procedure` synchronization
- module-based processing workflow
- initial project structure
- initial internal test version for source parsing
- WorkState-based processing logic