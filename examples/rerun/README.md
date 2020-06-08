# Rerun

```

  idle ->
    rotate-logs ->
    running ->
    done

  // Hitting CTRL+C will "pause" the current job
  running -> paused -> running

```

This is a shell-script that runs a single command multiple times in order to figure out how often it fails.

Failure is determined by a non-zero exit-code, and failures are only printed if they are unique.

It was written with a single use-case in mind: to repeatedly run `npm run test` to determine how reliable tests are, particularly E2E tests using Puppeteer.

## Installation

Rerun is bundled as a working example for the `Statebot-sh` library, so [download that](https://github.com/shuckster/statebot-sh) to get it. It lives in the `examples/rerun/` folder.

## Usage

You can see usage instructions by running it without any args:

```
./rerun.sh

. :
| |  Statebot :: rerun
| |  Current state: [idle]
|_|________________________________________ _ _ _  _  _


Please specify the number of iterations as the first argument

Usage:
  ./rerun.sh <run-count> <what-you-want-to-run>

Examples:
  ./rerun.sh 100 npm run test-suite
  ./rerun.sh 10 sleep 1

Resume a paused run:
  ./rerun.sh

Pausing a run is done by hitting [CTRL+C]

At the end of a run all unique failures will be printed. If you want
to see the failures before a run is finished, type:

  cat /tmp/rerun-failures.txt

Running ./rerun.sh with args will always start a new run.
```

To see an "always succeeding" example, run:

```sh
./rerun.sh 10 sleep 1
```

```sh
# ...more output above...

+---
| Done, without any failures!
|
+---
| Started at: Mon  8 Jun 2020 15:30:34 BST
|   Finished: Mon  8 Jun 2020 15:30:44 BST
| Time taken: 00h 00m 10s
|   Failures: 0 out of 10 runs
|     Unique: 0 out of 0 total failures
|
```

To see an "always failing" example, a script `fail-after-1-second.sh` is provided:

```sh
./rerun.sh 10 ./fail-after-1-second.sh
```

```sh
# ...more output above...

Running 9 of 10...
^ FAILED!
| Finished run 9 of 10:
>  Took: 00h 00m 01s
>  ~ETA: 15:27:02 (00h 00m 01s)

Running 10 of 10...
^ FAILED!
| Finished run 10 of 10:
>  Took: 00h 00m 01s

+---
| Done, printing unique failures:
|


Oh no!

|
| ^ UNIQUE FAILURE 1
|   HASH: b4b0d27dcd170a7a75cd494c8d33c5ab
+---

+---
| Started at: Mon  8 Jun 2020 15:26:51 BST
|   Finished: Mon  8 Jun 2020 15:27:02 BST
| Time taken: 00h 00m 10s
|   Failures: 10 out of 10 runs
|     Unique: 1 out of 10 total failures
|
```

## NPM specificity

To determine the uniqueness of a failure the output is stripped of things that usually change between runs, such as timestamps and durations.

This "stripping" targets NPM specifically, so lines prefixed with `npm ERR!` will be removed, and timing information in parentheses will be lopped-off the end of lines. `3 passing (1m)` becomes `3 passing`, and so on.

After this, the output is hashed using `md5sum`, and this hash is used to identify unique failures.

## Log history + run state

Rerun stores its output in `/tmp/rerun-failures.txt`. This file is copied into `history/` on subsequent runs. If a run is "paused" with CTRL+C, the current state of the run is stored in `/tmp/rerun-job.txt`

## License

Rerun is bundled with [Statebot-sh](https://github.com/shuckster/statebot-sh/) and both are [ISC licensed](./LICENSE).

<img src="../../logo-small.png" width="75" />
