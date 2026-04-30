# TESTING.md — labTools Regression Testing Guide

## Overview

labTools has no automated test suite. This guide describes a
regression-testing workflow based on comparing the final pipeline
output — the `*params.mat` file (an `adaptationData` object with
stride-by-stride parameters) — before and after a code change.

**Core idea:** process a reference dataset once with known-good code
and save the output as the reference `params.mat`. After any code
change, reprocess the same dataset and compare the two files with
`compareAdaptationData`. Parameters that changed beyond floating-point
noise are flagged explicitly.

---

## Prerequisites

### 1. Reference data files
Keep one short reference session (ideally < 5 trials, < 500 strides)
on a shared drive or local path. You need two files:
- `*expData.mat` — the processed `experimentData` object
- `*params.mat` — the reference `adaptationData` output

To create the reference `params.mat` from scratch:
```matlab
% Process the session using current (known-good) code:
c3d2mat           % OR: loadSubject (if *info.mat already exists)

% The *params.mat file is saved automatically by loadSubject.
% Record its path — this is your reference.
```

### 2. labTools on path
```matlab
addpath(genpath('path/to/labTools'))
```

---

## Test Matrix

Choose the test based on what code was changed:

| What changed | Command to run | Notes |
|---|---|---|
| Parameter calculation (`fun/parameterCalculation/`) | `expData.recomputeParameters()` | Fastest; recalculates from existing processed data |
| One parameter class only (e.g., force) | `expData.recomputeParameters('force')` | Scope-limited recompute |
| Gait event detection (`fun/eventExtraction/`) | `expData.recomputeEvents()` then `expData.recomputeParameters()` | Events change → parameters change downstream |
| Raw processing (filters, torques, EMG) | `expData.flushAndRecomputeParameters(eventClass)` | Full reprocessing; `eventClass`: `''` default, `'kin'`, or `'force'` |
| Class definitions or full pipeline logic | Re-run `loadSubject` (or `c3d2mat` if `*info.mat` is absent) | Most complete test |
| Multiple areas | Run the most comprehensive command for the deepest change | When in doubt, use `flushAndRecomputeParameters` |

---

## Step-by-Step Workflow

### Step 1: Load the reference `experimentData`
```matlab
load('path/to/Sub01expData.mat', 'expData')
```

### Step 2: Run the appropriate recompute command
```matlab
% Option A — parameter calculation only:
expData.recomputeParameters()

% Option B — one parameter class only:
expData.recomputeParameters('force')

% Option C — events + parameters:
expData.recomputeEvents()
expData.recomputeParameters()

% Option D — full flush:
expData.flushAndRecomputeParameters()
```

### Step 3: Build the new `adaptationData`
```matlab
newAdaptData = expData.makeDataObj()
% Capture the return value — pass it directly to compareAdaptationData.
% No filename argument means the object is not saved to disk; that is
% intentional for regression testing. Pass a filename string to save:
%   expData.makeDataObj('Sub01')  % saves Sub01params.mat
```

### Step 4: Compare against the reference
```matlab
compareAdaptationData( ...
    'path/to/reference/Sub01params.mat', ...
    newAdaptData, ...
    RefName='reference', NewName='after change')
```

### Step 5: Interpret the output (see section below)

---

## Interpreting `compareAdaptationData` Output

```
TRIALS
  Reference : [1 2 3 4 5]
  New       : [1 2 3 4 5]
  Common: 5  |  Ref-only: 0  |  New-only: 0
```
- Ref-only or New-only trials indicate a processing scope difference,
  not a parameter change. Only common trials are compared.

```
PARAMETER LABELS
  Common: 43  |  Ref-only: 0  |  New-only: 2
  New-only labels: harmonicRatio_AP, harmonicRatio_ML
```
- New-only labels are new parameters added in this change — expected
  when adding a feature.
- Ref-only labels indicate parameters that were removed or renamed.

```
STRIDE ALIGNMENT
  Matched pairs   : 2431
  Unmatched (ref) : 0  |  Unmatched (new): 0
```
- Unmatched strides arise when gait event detection changed, producing
  different stride boundaries. A small number is often acceptable;
  a large number warrants investigation.

```
PARAMETER DIFFERENCES  (RelTol=1e-9, AbsTol=1e-12)
  Unchanged  : 41
  Roundoff   :  0
  Changed    :  2
  ---
  stepLengthAsym     relDiff=3.41e-04  absDiff=1.20e-03  NaN=0
  strideTime         relDiff=2.10e-05  absDiff=4.01e-05  NaN=0
```

**Classification:**
- **Unchanged** — values are identical (within floating-point noise).
- **Roundoff only** — non-zero differences but below `RelTol=1e-9`.
  Expected when harmless refactoring touches intermediate
  floating-point operations.
- **Changed** — differences exceed tolerance. Investigate whether
  this is intentional (new feature or bug fix) or a regression.
- **NaN > 0** — strides where one object has NaN and the other does
  not. Indicates a change in bad-stride detection logic.

### Adjusting tolerance
For loose comparisons (e.g., after platform migration):
```matlab
compareAdaptationData(ref, new, RelTol=1e-6)
```
For tighter checks:
```matlab
compareAdaptationData(ref, new, RelTol=1e-12, AbsTol=1e-15)
```

---

## Skipping the GUI When `*info.mat` Exists

If the `GetInfoGUI` dialog has already been completed for the
reference session, the `*info.mat` file is saved in the session
folder. You can skip the GUI and run the loader directly:
```matlab
% Equivalent to the non-GUI portion of c3d2mat:
loadSubject('path/to/session/Sub01info.mat')
```
This saves substantial time during iterative testing.

---

## Test Data Recommendations

- **Size** — keep the reference session short (< 5 trials, < 500
  strides). The comparison runs in seconds; a full c3d2mat run on
  a minimal session takes 1–2 minutes.
- **Coverage** — choose a session that includes TM, OG, and
  adaptation trials so that all parameter classes (temporal, spatial,
  force, EMG if applicable) are exercised.
- **Storage** — store reference files outside the repo (they can be
  large). Note the path in a shared lab document.
- **Updating the reference** — after an intentional, validated change,
  regenerate the reference `params.mat` using the new code and record
  the regeneration date.

---

## See Also

- `fun/misc/compareAdaptationData.m` — comparison function
- `example/testPipelineRecompute.m` — template script
- `CLAUDE.md` — repository architecture overview
