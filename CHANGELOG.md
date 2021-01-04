# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- `statebot_init()` will source `~/.statebot-rc` if it exists.

There is one use-case I know of for this: My own state-machines generally only implement `perform_transitions()`, but sometimes I want to do something else after transitions, but without modifying the original script.

So I define `on_transitions()` in `~/.statebot-rc` and use STATEBOT_NAME to know which Statebot sourced it.

## [2.3.1] - 2020-12-30
### Added
- Installation helper
- Cloud Connect :: Ability to reset

### Changed
- Small code police

## [2.3.0] - 2020-12-30
### Added
- Cloud Connect :: A few more debugging messages

### Changed
- Changed license from ISC to the legally identical MIT, since it's more recognisable
- Cloud Connect :: Refactored with a bent towards easier config
- Cloud Connect :: Update README with a Quick Start
- Cloud Connect :: BT-Wifi plugin now tested
- Rerun :: Small refactor for readability


## [2.2.4] - 2020-06-20
### Changed
- Cloud Connect :: FON plugin now defunct

### Added
- Cloud Connect :: Added 3 other plugins for BTWi-fi

## [2.2.3] - 2020-06-14
### Added
- Cloud Connect :: Allow 'export' overrides
- Cloud Connect :: 'rebooting' state

## [2.2.2] - 2020-06-14
### Added
- Cloud Connect :: Add credits

## [2.2.1] - 2020-06-13
### Changed
- Code-style tweaks
- Remove superfluous dump() function

## [2.2.0] - 2020-06-13
### Fixed
- 'statebot_inspect' was showing all transitions, but not all states in a chart. The first one was being lopped-off, and white-space could sneak-in too

### Added
- Regression test for the above

## [2.1.6 to 2.1.8] - 2020-06-13
### Fixed
- Cloud Connect :: bt-fon plugin required tweaking
- Cloud Connect :: Remove superfluous imports after refactor

### Changed
- Cloud Connect :: Break-out bt-fon helpers + api

### Added
- Cloud Connect :: Use the above for new bt-openzone plugin (untested!)

## [2.1.5] - 2020-06-11
### Fixed
- Fix for some THEN-callbacks not passing all arguments in all shells

## [2.1.4] - 2020-06-11
### Fixed
- Broke perform_transitions() THEN-callback on last commit

### Added
- Test for the above issue

## [2.1.3] - 2020-06-11
### Fixed
- Update version number

## [2.1.2] - 2020-06-11
### Fixed
- perform_transitions() THEN-callbacks not running in some shells
- Improve portability of Rerun example
- More styling/linting

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
