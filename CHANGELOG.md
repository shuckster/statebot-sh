# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.1] - 2020-06-10
### Fixed
- Styling/linting

### Added
- Test for statebot_emit persist option


## [2.1.0] - 2020-06-09
### Changed
- Update shebang back to `#!/bin/sh` with the help of shellcheck.
  Still not completely POSIX thanks to the use of `local`, but
  that doesn't seem to be a huge deal...?

## [2.0.0] - 2020-06-09
### Changed
- Invert exit-codes of case_statebot to permit direct usage in
  if-statements without confusion. Anything using case_statebot
  will need to be updated, so this is a breaking-change

### Added
- case_statebot tests

## [1.0.2] - 2020-06-08
### Fixed
- statebot_reset updates CURRENT_STATE for cases where you want to
  continue execution after calling it. Previously it only updated
  the CSV database entry
- statebot_enter won't fire THEN-callbacks if unnecessary
- Linting tweaks via ShellCheck

### Changed
- Tweak demo.sh, put it in /examples

### Added
- New example: Rerun!
- Some basic tests

## [1.0.1] - 2020-05-16
### Changed
- Update shebang: `#!/bin/bash` is more portable that `#!/bin/sh`

## [1.0.0] - 2020-04-20
### Added
- Statebot-sh :)
