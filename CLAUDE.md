# CLAUDE.md — labTools Repository Instructions

## Repository Overview
labTools is a MATLAB framework for biomechanics and sensorimotor
adaptation research. It provides hierarchical data containers and
processing pipelines for analyzing human gait — from raw motion
capture (C3D/Vicon Nexus) and force plate data through stride-indexed
adaptation metrics and group statistics.

## How to Run Code
No build system. All workflows are MATLAB-based:

- **Data import**: `gui/importc3d/c3d2mat` (primary entry point)
- **Study setup**: `gui/createStudy/uiCreateStudy`
- **Gait event review**: `gui/eventReview/ReviewEventsGUI`
- **Example workflows**: `example/` scripts
- **Docs**: `m2html('mfiles','labTools','htmldir','doc/html','recursive','on','globalHypertextLinks','on')`

No automated tests. Scripts in `example/` (e.g.,
`testMarkerHealthCheck.m`) serve as manual integration tests.

## Architecture

### Data Pipeline
```
Raw files (C3D / datalog)
  → rawTrialData         (markerData, EMGData, GRFData, beltSpeedData)
  → processedLabData     (gaitEvents, angleData, procEMGData)
  → strideData           (continuous data split into strides)
  → adaptationData       (stride-indexed parameters)
  → groupAdaptationData  (group statistics)
  → studyData            (multi-group comparisons)
```

### Entry Point & User Input
The primary entry point is the `c3d2mat` script. It first calls
`GetInfoGUI` (paired with `GetInfoGUI.fig`) to present the user with a
GUI for specifying all experimental session parameters before any data
processing begins. `GetInfoGUI` collects participant demographics,
experiment metadata, C3D file locations, trial/condition assignments,
and EMG channel labels. Experiment description files stored in the
`ExpDetails/` directory are used to auto-populate condition fields.

### Data Loading Pipeline
After collecting user inputs, `c3d2mat` calls `loadSubject`, which
calls `getTrialMetaData` to build per-trial metadata and file path
lists, then calls `loadTrials` to read each C3D file via the
Biomechanics Toolkit (BTK). `loadTrials` processes ground reaction
forces (GRF), synchronizes and sorts EMG channels across one or two
acquisition PCs, processes accelerometer data, and packages everything
into a `rawTrialData` object (a subclass of `labData`) for each trial.

### Processing Pipeline
`loadSubject` instantiates a `rawExpData` (`experimentData`) object
from the loaded trials, saves it as `*RAW.mat`, then calls
`rawExpData.process()`, which iterates over each trial and calls
`labData.process()` on it. `labData.process()` performs the following
steps for each trial in order:

1. Process raw EMG (amplitude extraction, optional spike removal)
2. Interpolate missing marker data (placeholder — not yet implemented)
3. Compute limb angles (`calcLimbAngles`)
4. Detect gait events from kinematics or forces (`getEvents`)
5. Estimate belt speeds from foot markers if `beltSpeedReadData` is
   absent (`getBeltSpeedsFromFootMarkers`)
6. Compute COP, COM, and joint torques (`computeTorques`,
   `computeCOPAlt`)
7. Construct a `processedTrialData` object
8. Compute stride-by-stride adaptation parameters (`calcParameters`),
   including temporal, spatial, raw EMG, processed EMG, and force
   parameter classes

After processing, `loadSubject` calls `experimentData.makeDataObj()`
to create and save an `adaptationData` object (`*params.mat`). If EMG
data is present, EMG normalization parameters are also appended before
the final save.

### Post-Processing (Recompute Workflows)
After the initial `c3d2mat` run, users can load the saved
`experimentData` MAT file and recompute without re-parsing C3D files
using the following `experimentData` methods:

- `recomputeEvents` — redetects gait events only
- `recomputeParameters` — recomputes adaptation parameters from
  existing processed trial data, optionally for a subset of parameter
  classes or a specific event detection method
- `flushAndRecomputeParameters` — fully reprocesses all parameters
  from scratch (equivalent to re-running the processing pipeline on
  already-loaded data)

**Important:** `experimentData` is a value class. All three methods
return a modified copy; you must capture the return value or the
recomputed parameters are silently discarded:
`expData = expData.recomputeParameters()`

### Class Hierarchy

**Data containers** (`classes/dataStructs/`):
- `experimentData` — session container; `metaData`, `subData`, `data`
  (cell array of labData). Value class — recompute methods return a
  copy: `expData = expData.recomputeParameters()`
- `adaptationData` — stride-indexed params; key methods: `removeBias`,
  `getParamInCond`, `getEarlyLateData_v2`, `getEpochData`,
  `addNewParameter`, `removeBadStrides`, `plotAvgTimeCourse`
- `groupAdaptationData` / `studyData` — group/study-level analysis

**Time series** (`classes/labTS/`):
- `labTimeSeries` — extends `timeseries`; uniform sampling, label access
- `orientedLabTimeSeries` — 3D vector data; adds `orientationInfo`
- `parameterSeries` — one scalar per stride, from `calcParameters`
- `processedEMGTimeSeries` — filtered EMG with envelopes

**Synergy analysis** (`classes/synergies/`):
`Synergy` → `SynergySet` → `SynergySetCollection` →
`ClusteredSynergySetCollection`

### Key Patterns

- **Label-based access**: Time series channels are identified by
  string labels (e.g., `'LANKx'`, `'LANKy'`, `'LANKz'`), not
  numeric indices. Marker labels follow `BODYPART` convention; 3D
  components use `x/y/z` suffixes.
- **Stride as the unit of analysis**: The framework is built around
  stride-indexed data. `strideData` objects split continuous trials;
  `parameterSeries` stores one scalar per stride.
- **Classes vs. functions**: Classes (in `classes/`) handle data
  container logic. Domain algorithms live as plain functions in
  `fun/`. GUIs handle I/O.
- **Composition**: Data containers hold time series objects; e.g.,
  `rawTrialData` composes `orientedLabTimeSeries` for markers and
  forces.
- **Backward compatibility**: Classes use `loadobj` to handle
  deprecated or renamed fields when loading older `.mat` files.

### `fun/` Subdirectory Guide

| Directory | Purpose |
|---|---|
| `parameterCalculation/` | Stride-level biomechanical parameters |
| `eventExtraction/` | Gait event detection (HS, TO) |
| `biomechAnalysis/` | COM/COP, joint torques |
| `EMGanalysis/` | EMG filtering and envelope extraction |
| `plotting/` | Visualization utilities |
| `eventReview/` | Event validation helpers |
| `+dataMotion/`, `+Hreflex/`, `+utils/` | Namespace packages |

### Key Functions

#### `getEvents` (called from `labData.process`)
Detects heel-strike (HS) and toe-off (TO) gait events for both legs
and packages them into a sparse `labTimeSeries` with 12–15 labeled
columns. Event detection strategy depends on trial type:
- **OG / NIM trials** — defaults to limb angles
  (`getEventsFromAngles`)
- **TM trials with GRF data** — defaults to vertical forces
  (`getEventsFromForces`); kinematic events are also computed and
  resampled to the GRF frame rate for storage alongside force events
- **TM trials without GRF data** — falls back to toe/heel marker
  kinematics (`getEventsFromToeAndHeel`)

The output always contains `LHS`, `RHS`, `LTO`, `RTO` (primary events
used by `calcParameters`), plus `forceLHS/RHS/LTO/RTO` and
`kinLHS/RHS/LTO/RTO` (labeled copies for diagnostics). When
`perceptualFlag == 1`, three additional columns are appended:
`percStartCue`, `percEndCue`, and `percEndRamp`, derived by aligning
audio cue times from the synchronized datlog to RTO events.

#### `computeForceParameters` (called from `calcParameters`)
Computes stride-by-stride anterior-posterior (AP) GRF parameters for
treadmill trials from low-pass-filtered (20 Hz) GRF data. Before
computing parameters, AP force offsets are estimated per leg (median
force during contralateral swing) and subtracted. The core per-stride
computation is performed by `ComputeLegForceParameters` for each leg
separately over its stance phase window (SHS→STO for slow leg,
FHS→FTO2 for fast leg). Output parameters (~43 labels) include average
and peak braking/propulsion forces, bilateral symmetry and ratio
metrics, summed impulses, vertical and medial-lateral force means and
peaks, and treadmill incline angle. Parameters are skipped (NaN) for
OG/NIM trials and for strides with missing event times or near-zero
force variance.

### Full Call Chain

```
c3d2mat
 ├── GetInfoGUI                    % Collect user session inputs
 └── loadSubject
      ├── determineRefLeg          % Resolve fast/slow leg from info
      ├── getTrialMetaData         % Build per-trial metadata & file lists
      ├── loadTrials               % Load C3D data into rawTrialData
      │    ├── btkReadAcquisition  % Read C3D via BTK (external)
      │    ├── [GRF processing]    % Parse & label force/moment channels
      │    ├── [EMG processing]    % Sync channels across two PCs
      │    ├── [ACC processing]    % Extract & downsample accel. data
      │    └── rawTrialData(...)   % Construct per-trial data object
      ├── SyncDatalog              % Sync data logs (if present)
      ├── experimentData(...)      % Instantiate session-level object
      │    └── [save *RAW.mat]
      ├── experimentData.process   % Process all raw trial data
      │    └── labData.process     % Called per trial
      │         ├── processEMG
      │         ├── calcLimbAngles
      │         ├── getEvents
      │         ├── getBeltSpeedsFromFootMarkers
      │         ├── computeTorques / computeCOPAlt
      │         ├── processedTrialData(...)
      │         └── calcParameters % Stride-by-stride params
      │              ├── computeTemporalParameters
      │              ├── computeSpatialParameters
      │              ├── computeEMGParameters
      │              ├── computeForceParameters
      │              ├── computeHreflexParameters
      │              └── computePercParameters
      ├── appendEMGNormParameters  % Append EMG norms (if present)
      ├── populateNewParamBackToExpData
      ├── [save *expData.mat]
      └── experimentData.makeDataObj
           └── [save *params.mat (adaptationData)]

% --- Post-processing (after loading saved experimentData) ---
experimentData.recomputeEvents
experimentData.recomputeParameters
     └── calcParameters
experimentData.flushAndRecomputeParameters
     └── labData.process
```

---

## MATLAB Version Compatibility
All code must be compatible with MATLAB R2021a through the current
release. Do not use language features, functions, or syntaxes
introduced after R2021a without an explicit compatibility note.
Similarly, do not use functions removed before R2021a. A common
example in older lab code: `findstr` was removed in R2014b and must
be replaced with `strfind`.

## Code Style Requirements
- Wrap lines at 76 characters (the MATLAB editor default)
- Use spaces around `=` and binary comparison operators (`~=`, `==`,
  `<`, `>`, `<=`, `>=`)
- Do not use brackets around a single output argument: write
  `out = func()` not `[out] = func()`
- Suffix no-argument method calls with `()` to distinguish them from
  property access: write `obj.method()` not `obj.method`
- Include a MATLAB `arguments` block immediately after the documentation
  comment for all functions that accept inputs; declare input sizes,
  types, and default values there rather than using `nargin` checks.
  Place multiline validators on the line(s) following the argument name,
  indented to align with the argument name:
  ```matlab
  options.Colors (:,3) double ...
      {mustBeInRange(options.Colors, 0, 1)} = []
  ```
- Use camelCase or PascalCase for all variable, function, and script
  file names (not underscore-separated). Choose names that make their
  purpose clear without a comment — prefer `participantCount` over `n`,
  `knotLocations` over `kl`. Abbreviations are acceptable when they are
  unambiguous in context (e.g., `tbl`, `fig`, `lme`, `pval`).
- Do not use `i` or `j` as loop index variables (reserved for the
  imaginary unit in MATLAB). For stride loops use `st`; for generic
  enumeration use `ii`, `jj`, or `kk`. When iterating over a named
  collection and a terse abbreviation adds unambiguous clarity, prefer
  it over `ii`: `mscl` (muscles), `mrkr` (markers), `lbl` (labels),
  `fld` (fields), `tr` (trials), `con` (conditions), `fp` (force
  plates), `fi` (files). Use `ii` when no short name adds clarity or
  when a terse name would introduce ambiguity.
- Do not indent the base level of code inside functions, as the MATLAB
  IDE autoformatter removes this indentation
- Align `=` signs within a group of closely related assignments to make
  differences between variable names visually apparent:
  ```matlab
  minSpacing  = max(1, round(options.MinSpacing));
  optimizeFor = upper(options.OptimizeFor);
  maxEvals    = round(options.MaxEvals);
  ```
  Apply this within a logical group; do not force alignment across
  unrelated statements separated by blank lines.
- Write decimal numbers with an explicit leading zero: use `0.5`
  not `.5`.
- Use modern NaN-omitting aggregation functions rather than the
  deprecated `nan*` family: write `mean(x, 'omitnan')` instead of
  `nanmean(x)`, and equivalently for `median`, `std`, and `sum`.
  For `min` and `max`, the `'omitnan'` flag requires an explicit
  empty placeholder for the second argument:
  `min(x, [], 'omitnan')` / `max(x, [], 'omitnan')`. Writing
  `min(x, 'omitnan')` invokes the element-wise two-array form and
  returns an array, not a scalar.

## Documentation Comments
Every function requires a standard doc block after the definition line.

**H1 line** — the first comment line, on the line immediately after
`function`. No space between `%` and the function name; the name is
in ALL CAPS, followed by a brief one-line description. This is the
only place in a comment block where there is no space after `%`:
```matlab
%MYFUNCTION Compute stride-by-stride parameters from GRF data.
```

**Description** — follows the H1 line with exactly one blank comment
line (`%`) between them. No section header. Use paragraph
indentation: the first line of each paragraph is indented three
spaces after `%`; all continuation lines in the same paragraph use
one space after `%`:
```matlab
%
%   First sentence of description, indented.
% Continuation lines use one space after %.
%
%   A second paragraph, again indented on its first line.
% Continuation lines use one space here too.
```

**Inputs / Outputs** — labeled section headers (`% Inputs:`,
`% Outputs:`), with each argument indented three spaces:
```matlab
% Inputs:
%   argName - description of the argument
%
% Outputs:
%   out - description of the output
```

**Examples** (optional) — include after Outputs when it would
clarify how the function is used within the labTools pipeline.

**Toolbox Dependencies** — list any required MATLAB toolboxes;
state `None` if only core MATLAB is required.

**See Also** — function names must be ALL CAPS so that MATLAB
renders them as clickable hyperlinks in the Command Window:
```matlab
% See also RELATEDFUNCTION, ANOTHERFUNCTION.
```

Do not include a `Syntax` section — it redundantly restates the
function definition and adds no information.

## Code Organization
- Use `%%` section headers to divide every script and function into
  named logical phases. The header text should name the phase, not
  describe the code:
  ```matlab
  %% Validate Input Arguments
  %% Fit Zero-Knot Linear Mixed-Effects Model (ML)
  %% Prepare Output Data Structure
  ```
- Separate sections with a single blank line before the `%%` header.
  Separate logically distinct groups of statements within a section
  with a single blank line.
- Maintain consistent whitespace and indentation throughout.
- In the 'Labels and Descriptions' `aux` block found in parameter
  computation functions, keep each parameter name and its description
  on a single line regardless of length — this block is exempt from
  the 76-character line-wrap rule

### Writing Comments
Write comments to help a future reader (including yourself) understand
purposes and decisions that are not obvious from the code itself.

**Write a comment when:**
- Starting a new `%%` section — the header *is* the comment; make it
  descriptive (see section header guidance above).
- A group of statements implements a non-obvious algorithm or
  multi-step procedure — add a short block comment above the group
  summarizing what it does and, if non-obvious, why that approach
  was chosen.
- A single line encodes a domain-specific rule, constraint, or
  formula — add an end-of-line comment explaining its meaning:
  ```matlab
  bias = mean(stepAsym(end-39:end));  % mean of last 40 non-bad strides
  pval = results.pValue(2);           % LRT p-value (second row = complex model)
  ```
- A value is a magic number whose meaning would not be obvious to
  a reader unfamiliar with the study protocol:
  ```matlab
  numBase = 40;   % strides used to estimate baseline bias
  alpha   = 0.05; % significance threshold for likelihood ratio test
  ```
- A decision could reasonably have been made differently — explain
  why this choice was made:
  ```matlab
  % must use ML (not REML) for valid likelihood ratio test
  lme = fitlme(tbl, formula, 'FitMethod', 'ML');
  ```

**Omit a comment when:**
- The identifier names already make the purpose completely clear.
  `participantIDs = unique(tbl.Participant)` needs no comment.
- The comment would merely restate the code in English
  (`% increment counter` above `ii = ii + 1`).

**Special prefixes:**
- `% TODO:` — known incomplete work or a known limitation to
  revisit later.
- `% NOTE:` — an important caveat, subtle invariant, or
  non-obvious constraint that future editors must not accidentally
  remove.

### Comment Preservation

When editing existing files, preserve all of the following:

- **Step-labeling comments** — short inline or block comments that
  label distinct steps in a multi-step algorithm (e.g., `% round to
  integer and canonicalize by sorting for the cache key`). These are
  navigation aids for readers of complex code.
- **WHY comments** — comments explaining a non-obvious decision, a
  hidden constraint, or a subtle invariant (e.g., `% must use ML for
  valid likelihood ratio test`).
- **Commented-out code** — alternative implementations or temporarily
  disabled code that the author hasn't decided to delete (e.g., an
  `% alternatively:` block). These represent work in progress.
- **End-of-line clarifications** — inline comments on assignment lines
  that clarify units, roles, or non-obvious behavior (e.g.,
  `% Lower bound`, `% safety limit to prevent infinite loops`).

Remove only comments that redundantly restate what the adjacent code
already makes obvious from its identifier names alone.
