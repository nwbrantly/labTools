# labTools

A MATLAB framework for biomechanics and sensorimotor adaptation
research developed by the [Sensorimotor Learning (SML) Laboratory][sml]
at the University of Pittsburgh. labTools provides hierarchical data
containers and processing pipelines for analyzing human gait — from raw
motion capture (Vicon Nexus C3D files) and force plate recordings
through stride-indexed adaptation metrics and group statistics.

[sml]: https://www.engineering.pitt.edu/subsites/Labs/sml/

---

## Table of Contents

1. [Requirements](#requirements)
2. [Getting Started](#getting-started)
3. [Repository Layout](#repository-layout)
4. [Data Pipeline Overview](#data-pipeline-overview)
5. [Key Classes](#key-classes)
6. [Working with Your Data](#working-with-your-data)
7. [Example Scripts](#example-scripts)
8. [Generating Documentation](#generating-documentation)
9. [Reporting Bugs](#reporting-bugs)

---

## Requirements

- **MATLAB R2021a or later** (tested through current release)
- [Biomechanics Toolkit (BTK)][btk] — required to read `.c3d` files
- A Vicon Nexus motion capture system is assumed for data collection,
  but the processing pipeline can be adapted to other sources

[btk]: https://biomechanical-toolkit.github.io/

---

## Getting Started

1. Clone or download this repository and add it to your MATLAB path:

   ```matlab
   addpath(genpath('/path/to/labTools'));
   ```

2. Install BTK and add it to your MATLAB path as well.

3. To import a motion capture session, run:

   ```matlab
   c3d2mat
   ```

   A GUI (`GetInfoGUI`) will open and prompt you for participant
   demographics, experiment metadata, C3D file locations,
   trial/condition assignments, and EMG channel labels.

4. After the import completes you will find two `.mat` files in your
   output directory:
   - `*RAW.mat` — raw trial data (`experimentData` object)
   - `*params.mat` — stride-indexed adaptation metrics
     (`adaptationData` object)

---

## Repository Layout

```
labTools/
├── classes/
│   ├── dataStructs/       % High-level data containers
│   │   ├── @experimentData/
│   │   ├── @adaptationData/
│   │   ├── @groupAdaptationData/
│   │   └── @studyData/
│   ├── labTS/             % Time series classes
│   │   ├── @labTimeSeries/
│   │   ├── @orientedLabTimeSeries/
│   │   ├── @parameterSeries/
│   │   └── @processedEMGTimeSeries/
│   └── synergies/         % EMG synergy analysis classes
├── fun/
│   ├── parameterCalculation/  % Stride-level biomechanical parameters
│   ├── eventExtraction/       % Heel-strike / toe-off detection
│   ├── biomechAnalysis/       % COM, COP, joint torques
│   ├── EMGanalysis/           % EMG filtering and envelope extraction
│   ├── plotting/              % Visualization utilities
│   ├── eventReview/           % Event validation helpers
│   ├── +dataMotion/           % Namespace: marker/segment utilities
│   ├── +Hreflex/              % Namespace: H-reflex analysis
│   └── +utils/                % Namespace: general utilities
├── gui/
│   ├── importc3d/             % c3d2mat and GetInfoGUI (primary entry point)
│   ├── createStudy/           % uiCreateStudy — experiment setup
│   └── eventReview/           % ReviewEventsGUI — event validation
├── ExpDetails/                % Experiment description files (auto-populate GUI)
├── example/                   % Example and validation scripts
└── doc/                       % Generated HTML documentation (via m2html)
```

---

## Data Pipeline Overview

```
Raw files (C3D / datalog)
  └─► rawTrialData         per-trial: markers, EMG, GRF, belt speed, H-reflex
        └─► processedLabData   adds gait events, limb angles, processed EMG
              └─► strideData         continuous data split into strides
                    └─► adaptationData     stride-indexed parameters
                          └─► groupAdaptationData  group statistics
                                └─► studyData      multi-group comparisons
```

The pipeline is orchestrated by `c3d2mat` → `loadSubject` →
`experimentData.process()`. After the initial run, you can reload the
saved `*expData.mat` and recompute without re-parsing C3D files:

| Method | What it does |
|---|---|
| `recomputeEvents` | Re-detects gait events only |
| `recomputeParameters` | Recomputes parameters from existing processed data |
| `flushAndRecomputeParameters` | Full reprocessing from already-loaded data |

`experimentData` is a value class — always capture the return:
`expData = expData.recomputeParameters()`

---

## Key Classes

### `experimentData`
Top-level session container. Holds experiment metadata, subject data,
and an array of `labData` trial objects. Provides `process()`,
`recomputeEvents()`, `recomputeParameters()`, and `makeDataObj()`.

### `adaptationData`
Stride-indexed parameter storage. Key methods:

- `removeBias` / `removeBiasV4` — baseline subtraction by trial type
- `getParamInCond`, `getParamInTrial` — parameter retrieval
- `getEarlyLateData_v2`, `getEpochData` — epoch extraction
- `addNewParameter`, `removeBadStrides` — data manipulation
- Static plotting: `plotAvgTimeCourse`, `plotGroupedSubjectsBars`,
  `createGroupAdaptData`

### `groupAdaptationData` / `studyData`
Group- and study-level aggregation and statistics.

### `labTimeSeries` / `orientedLabTimeSeries`
Time series containers extending MATLAB's `timeseries`. Channels are
identified by string labels (e.g., `'LANKx'`, `'LANKy'`) rather than
numeric indices. `orientedLabTimeSeries` adds 3D transformation
support for marker and force data.

### `parameterSeries`
Stride-indexed parameter storage (one scalar value per stride),
produced by `calcParameters`.

---

## Working with Your Data

### Gait Event Detection
Event detection strategy depends on trial type:
- **OG / NIM trials** — limb angles (`getEventsFromAngles`)
- **TM trials with GRF** — vertical forces (`getEventsFromForces`);
  kinematic events are also stored for diagnostics
- **TM trials without GRF** — toe/heel marker kinematics
  (`getEventsFromToeAndHeel`)

Use `gui/eventReview/ReviewEventsGUI` to visually inspect and correct
detected events.

### Stride-Level Parameters
`calcParameters` computes temporal, spatial, EMG, force, H-reflex,
and perceptual parameters for each stride. Force parameters
(`computeForceParameters`) include ~43 labels covering AP braking and
propulsion, bilateral symmetry, impulse, vertical and mediolateral
peaks, and treadmill incline angle.

### EMG Analysis
Raw EMG is processed through amplitude extraction and optional spike
removal. EMG normalization parameters are appended automatically when
normalization data are present. Synergy analysis is available through
the classes in `classes/synergies/`.

### Group Analysis
Use `adaptationData.createGroupAdaptData` to aggregate across
participants, then `groupAdaptationData` and `studyData` for
group-level statistics and plotting.

---

## Example Scripts

The `example/` directory contains working scripts that serve as both
usage examples and manual integration tests:

| Script | Purpose |
|---|---|
| `exRecomputeParams.m` | Recompute parameters from a saved session |
| `labTSmanipulation.m` | Demonstrate `labTimeSeries` operations |
| `testMarkerHealthCheck.m` | Validate marker data integrity |

---

## Generating Documentation

With [m2html][m2html] on your MATLAB path, run:

```matlab
m2html('mfiles', 'labTools', 'htmldir', 'doc/html', ...
    'recursive', 'on', 'globalHypertextLinks', 'on')
```

HTML documentation is written to `doc/html/`.

[m2html]: https://www.artefact.tk/software/matlab/m2html/

---

## Reporting Bugs

To help us reproduce and fix a bug as quickly as possible, please open
a [GitHub issue][issues] and include all of the following:

1. **Steps to reproduce** — a clear, numbered sequence of actions that
   another person on a different computer can follow to observe the
   same behavior.
2. **Expected behavior** — describe what the code should do.
3. **Actual behavior** — describe what the code actually does,
   including any error messages or warnings printed to the MATLAB
   Command Window (copy the full text, not just the last line).
4. **MATLAB version and OS** — output of `version` and your operating
   system (e.g., Windows 11, macOS 14).
5. **labTools version** — the Git commit hash (`git rev-parse HEAD`)
   or the tag/branch you are using.
6. **Screenshots or figures** — attach any plots or Command Window
   screenshots that illustrate the problem.
7. **Data** — if the bug occurs only with a specific dataset, attach
   the data file or provide a link to it on your shared server. If
   the data cannot be shared publicly, note that in the issue and a
   maintainer will contact you directly.

[issues]: https://github.com/PittSMLlab/labTools/issues

> **Tip:** The more precisely you can isolate the problem — ideally to
> a short script that triggers the error with minimal data — the faster
> it can be resolved.
