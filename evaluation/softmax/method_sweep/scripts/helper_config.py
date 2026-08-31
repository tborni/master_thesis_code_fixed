"""Shared configuration and helpers for the softmax method-sweep Pareto analysis.

The analysis extracts the Pareto-optimal exp and rec component implementations,
combines them into softmax implementations for a SIMD sweep, and plots the
resulting fronts.  The input layout is *combined*:

    data/{exp,rec}/<Label>_combined.csv   params, LUT, DSP, RMSRE all in ONE
                                          file per method
    data/resources_SIMD.csv               total softmax resources vs. SIMD

So there is no accuracy<->resource inner join: each method's RMSRE, LUT and DSP
already live together in one *combined* CSV.  ``step1_components.py`` reads those
directly.

This module centralises every tunable constant and every piece of logic reused
across the pipeline steps, so the Pareto/domination definition is guaranteed
identical in step 1 and step 2 and the SIMD sweep is a one-line change.

Method-file shapes
------------------
Unlike the reference (whose swept components are all parametric), the combined
data here contains three *kinds* of method file, and the user asked for all of
them to be fed through the pipeline:

* ``parametric`` -- keyed by integer approximation parameters shared with the
  accuracy report (address widths, word width, newton steps).  Bipartite,
  Lookup, Splitting.
* ``positional`` -- no swept parameters; the file holds a single ``LUT,DSP,RMSRE``
  row (exp Bit-hacking).  Resolved positionally, asserted unique.
* ``categorical`` -- keyed by non-numeric configuration columns
  (``DSP_USAGE``/``BRAM_USAGE``); IP core.  Kept as string-valued params.

Which points survive is governed by ``filter.toml`` (see ``load_filter``): six
inclusive metric bounds plus a per-method ``y``/``n`` include flag, applied
uniformly to every kind during component extraction.  With the default
``rmsre_min = 1e-7`` floor, IP core's measured RMSRE (~2.7e-8) sits below it, so
those rows drop out like any other numerically-perfect point -- still read and
reported, just not carried onto the front.

Design notes
------------
* We depend only on the stdlib (``csv``, ``math``, ``tomllib``); the plot uses
  ``matplotlib``.  The data volume is tiny so a DataFrame engine buys us nothing.
* Every implementation is reduced to a small record::

      { 'method': <str>, 'params': {<param>: <value>, ...},
        'rmsre': <float>, 'lut': <int>, 'dsp': <int> }

  For combined files the join is trivial (one row already carries all four), so
  ``params`` values are kept as *strings* -- integer for the parametric methods,
  free-form for the categorical ones -- and are used only for provenance/labels,
  never numerically, downstream.
"""

from __future__ import annotations

import csv
import os
import tomllib
from typing import Dict, Iterable, List, Sequence, Set, Tuple

# --------------------------------------------------------------------------- #
# Paths
# --------------------------------------------------------------------------- #
# This module lives in <project>/scripts, so the project root is one level up.
SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPTS_DIR)

DATA_DIR = os.path.join(ROOT, "data")
# Combined per-method component CSVs (params + LUT + DSP + RMSRE together) live
# in the exp/ and rec/ subfolders of data/.
EXP_DATA_DIR = os.path.join(DATA_DIR, "exp")
REC_DATA_DIR = os.path.join(DATA_DIR, "rec")

# Generated CSVs (exp.csv, rec.csv, softmax_SIMD_<v>.csv) are written to their
# own subfolder so they stay clearly separated from the raw inputs in data/.
OUTPUT_DIR = os.path.join(DATA_DIR, "generated")
# Figures are written to two parallel trees with identical structure:
#   images/          - each diagram auto-scales its own axes
#   images_aligned/  - all diagrams share one common x- and y-range (the global
#                      extent across every SIMD value), so plots are comparable
IMAGES_DIR = os.path.join(ROOT, "images")
IMAGES_ALIGNED_DIR = os.path.join(ROOT, "images_aligned")


def _images_root(aligned: bool) -> str:
    return IMAGES_ALIGNED_DIR if aligned else IMAGES_DIR


# The exp/rec component fronts are SIMD-independent (step 1 does not use SIMD),
# so they live in data/generated/ and are computed once.
EXP_CSV = os.path.join(OUTPUT_DIR, "exp.csv")
REC_CSV = os.path.join(OUTPUT_DIR, "rec.csv")

# Everything below is produced per SIMD value:
#   data/generated/softmax_SIMD_<v>.csv                        (step 2)
#   images/SIMD_<v>/{dsp_only,method_dsp}/{diagram,pareto,full_pareto}.png (step 3)
# The two image modes are:
#   dsp_only/   - DSP determines colour AND marker; single DSP legend
#   method_dsp/ - DSP = colour, (exp,rec) method pair = marker; two legends
IMAGE_MODES = ["dsp_only", "method_dsp"]
FIGURE_NAMES = ["diagram.png", "pareto.png", "full_pareto.png"]


def simd_tag(simd: int) -> str:
    """Folder name for one SIMD value, e.g. 4 -> 'SIMD_4'."""
    return f"SIMD_{simd}"


def softmax_csv(simd: int) -> str:
    """Path to the per-SIMD softmax CSV (step 2 output), e.g.
    data/generated/softmax_SIMD_4.csv."""
    return os.path.join(OUTPUT_DIR, f"softmax_{simd_tag(simd)}.csv")


def image_dir(simd: int, mode: str, aligned: bool = False) -> str:
    """Path to <root>/SIMD_<v>/<mode>/ for one SIMD value and encoding mode.

    ``aligned`` selects the images_aligned/ tree instead of images/.
    """
    return os.path.join(_images_root(aligned), simd_tag(simd), mode)


def image_paths(simd: int, mode: str, aligned: bool = False):
    """Return {figure_name: absolute_path} for one SIMD value and encoding mode."""
    d = image_dir(simd, mode, aligned)
    return {name: os.path.join(d, name) for name in FIGURE_NAMES}


# Total-softmax resources as a function of SIMD (the base build), used by step 2
# to recover the "everything else" skeleton.  data/resources_SIMD.csv columns:
# N, SIMD, ..., LUT, DSP, ...
SIMD_SWEEP_CSV = os.path.join(DATA_DIR, "resources_SIMD.csv")

# --------------------------------------------------------------------------- #
# Tunable constants
# --------------------------------------------------------------------------- #
# SIMD sweep: step 2 runs once per value here, each re-selecting the
# Base(softmax) row from resources_SIMD.csv and rescaling the per-lane Exp
# resources.  Every value must exist in data/resources_SIMD.csv (which provides
# 1, 2, 4, 8, 16, 32, 64).  We mirror the reference sweep of 1, 2, 4.
SIMD_SWEEP = [1, 2, 4]

# Residual RMSRE contribution of everything in the softmax datapath that is
# neither the exp nor the reciprocal approximation (quantisation of the
# subtract/normalise stages, etc.).  Combined in quadrature.
RMSRE_OTHER: float = 1.918e-7

# Weight on the exp-component variance in the softmax RMSRE model:
#   RMSRE(softmax)^2 = B_EXP * RMSRE(exp)^2 + RMSRE(rec)^2 + RMSRE(other)^2
# B_EXP > 1 amplifies the exp error's contribution relative to the rec error,
# reflecting that the exp approximation error propagates into the softmax output
# with a slightly larger effective gain.  Matches combine_accuracy.py's B_EXP.
RMSRE_B_EXP: float = 1.0456234249238079

# NOTE: the "numerically perfect" RMSRE floor that used to live here as
# RMSRE_MIN is now filter.toml's [bounds].rmsre_min (default 1e-7), applied by
# step 1 together with the LUT/DSP bounds and the method include/exclude flags.
# See load_filter() below.

# --------------------------------------------------------------------------- #
# Method schemas
# --------------------------------------------------------------------------- #
# For each method we record:
#   family : "exp" or "rec"           - which softmax operand it implements
#   label  : human-readable name kept in the output / plot legend
#   file   : combined CSV basename under data/<family>/
#   kind   : "parametric" | "positional" | "categorical"
#   keys   : the ordered columns that uniquely identify an implementation within
#            that file (empty for the single-row positional method)
#
# Every combined file additionally carries LUT, DSP, RMSRE columns, which is why
# there is no separate resource file to join against.
#
# ``kind`` controls how a row's key is built and, for the base-case lookup in
# step 2, how a base config is matched:
#   parametric  -> integer-valued keys (address widths, word width, ...)
#   positional  -> no keys; the file must contain exactly one row
#   categorical -> string-valued keys (e.g. DSP_USAGE=Full)
METHODS: Dict[str, dict] = {
    # ---- Exp implementations -------------------------------------------- #
    "exp_bipartite": {
        "family": "exp", "label": "Bipartite", "file": "Bipartite_combined.csv",
        "kind": "parametric",
        "keys": ("ADDR_WIDTH_0", "ADDR_WIDTH_1", "ADDR_WIDTH_2", "WORD_WIDTH"),
    },
    "exp_lookup": {
        "family": "exp", "label": "Lookup", "file": "Lookup_combined.csv",
        "kind": "parametric",
        "keys": ("ADDR_WIDTH", "WORD_WIDTH"),
    },
    "exp_splitting": {
        "family": "exp", "label": "Splitting", "file": "Splitting_combined.csv",
        "kind": "parametric",
        "keys": ("ADDR_WIDTH_0", "ADDR_WIDTH_1", "ADDR_WIDTH_2", "WORD_WIDTH"),
    },
    "exp_bit_hacking": {
        "family": "exp", "label": "Bit-hacking", "file": "Bit-hacking_combined.csv",
        "kind": "positional",
        "keys": (),
    },
    "exp_ip_core": {
        "family": "exp", "label": "IP core", "file": "IP core_combined.csv",
        "kind": "categorical",
        "keys": ("DSP_USAGE", "BRAM_USAGE"),
    },
    # ---- Rec implementations -------------------------------------------- #
    "rec_bipartite": {
        "family": "rec", "label": "Bipartite", "file": "Bipartite_combined.csv",
        "kind": "parametric",
        "keys": ("NUM_NEWTON_STEPS", "ADDR_WIDTH_0", "ADDR_WIDTH_1", "ADDR_WIDTH_2", "WORD_WIDTH"),
    },
    "rec_lookup": {
        "family": "rec", "label": "Lookup", "file": "Lookup_combined.csv",
        "kind": "parametric",
        "keys": ("NUM_NEWTON_STEPS", "ADDR_WIDTH", "WORD_WIDTH"),
    },
    "rec_ip_core": {
        "family": "rec", "label": "IP core", "file": "IP core_combined.csv",
        "kind": "categorical",
        "keys": ("DSP_USAGE",),
    },
}

# Preserve declaration order (exp first, then rec) so component extraction and
# reports read in a stable, intuitive order.
EXP_METHODS = [m for m, spec in METHODS.items() if spec["family"] == "exp"]
REC_METHODS = [m for m, spec in METHODS.items() if spec["family"] == "rec"]


def method_file(method: str) -> str:
    """Absolute path to a method's combined CSV under data/<family>/."""
    spec = METHODS[method]
    base = EXP_DATA_DIR if spec["family"] == "exp" else REC_DATA_DIR
    return os.path.join(base, spec["file"])


def methods_of_family(family: str) -> List[str]:
    """The METHODS keys of one family, in declaration order."""
    return EXP_METHODS if family == "exp" else REC_METHODS


def labels_of_family(family: str) -> List[str]:
    """The human-readable labels of one family, in declaration order."""
    return [METHODS[m]["label"] for m in methods_of_family(family)]


# --------------------------------------------------------------------------- #
# filter.toml  (which component points feed the pipeline)
# --------------------------------------------------------------------------- #
# The filter is read here (single source of truth) and applied by step 1 during
# component extraction, so a point that fails a bound or belongs to an excluded
# method is gone before the exp/rec fronts, the softmax combination and the
# plots.  Two parts:
#
#   [bounds]        six INCLUSIVE metric bounds (lut/dsp/rmsre _min/_max)
#   [methods.exp]   per-method "y"/"n" flags; "y" includes, anything else
#   [methods.rec]   excludes.  exp and rec list their own method sets.
#
# Defaults (used when the file, a section, or a key is absent) are permissive
# except rmsre_min, which keeps the original 1e-7 "numerically perfect" floor.
FILTER_PATH = os.path.join(ROOT, "filter.toml")

BOUND_KEYS = ("lut_min", "lut_max", "dsp_min", "dsp_max", "rmsre_min", "rmsre_max")

# rmsre_min defaults to the historical floor (drops IP core at ~2.7e-8); all
# other bounds default wide open so nothing else is filtered unless asked.
DEFAULT_BOUNDS: Dict[str, float] = {
    "lut_min": 0.0, "lut_max": float("inf"),
    "dsp_min": 0.0, "dsp_max": float("inf"),
    "rmsre_min": 1e-7, "rmsre_max": float("inf"),
}

# A method flag equal to this (case-insensitive) means "include"; any other
# value means "exclude".  One-letter toggle: y <-> n.
_INCLUDE_FLAG = "y"


class FilterError(Exception):
    """Raised on a malformed filter.toml (unknown/missing method, bad bound)."""


def _parse_bounds(raw: dict) -> Dict[str, float]:
    bounds = dict(DEFAULT_BOUNDS)
    for key, value in raw.items():
        if key not in DEFAULT_BOUNDS:
            raise FilterError(
                f"unknown bound '{key}' in {os.path.basename(FILTER_PATH)}; "
                f"valid bounds are {list(BOUND_KEYS)}."
            )
        try:
            bounds[key] = float(value)
        except (TypeError, ValueError):
            raise FilterError(
                f"bound '{key}' in {os.path.basename(FILTER_PATH)} is not a "
                f"number: {value!r}."
            )
    return bounds


def _parse_family_methods(raw_methods: dict, family: str) -> Set[str]:
    """Resolve one family's [methods.<family>] y/n table to included labels.

    Every known label for the family must appear exactly once (so a typo or an
    omission is caught, not silently treated as excluded), and no unknown label
    may appear.  Returns the set of INCLUDED labels.
    """
    known = labels_of_family(family)
    table = raw_methods.get(family)
    if table is None:
        # Section absent -> include every method of this family (permissive).
        return set(known)
    if not isinstance(table, dict):
        raise FilterError(
            f"[methods.{family}] must be a table of <label> = \"y\"/\"n\", "
            f"got {type(table).__name__}."
        )

    known_set = set(known)
    seen = set(table)
    unknown = seen - known_set
    if unknown:
        raise FilterError(
            f"[methods.{family}] has unknown method(s) {sorted(unknown)}; "
            f"valid methods are {known}."
        )
    missing = known_set - seen
    if missing:
        raise FilterError(
            f"[methods.{family}] is missing flag(s) for {sorted(missing)}; "
            f"every method needs an explicit \"y\"/\"n\" (found {sorted(seen)})."
        )

    included = {
        label for label, flag in table.items()
        if str(flag).strip().lower() == _INCLUDE_FLAG
    }
    return included


def load_filter():
    """Read filter.toml -> (bounds, included_labels).

    ``bounds`` is the full six-key inclusive-bounds dict (defaults fill any gap).
    ``included_labels`` maps family -> set of included method LABELS.  A missing
    file yields permissive defaults (all methods, only the rmsre_min floor).
    """
    if not os.path.exists(FILTER_PATH):
        return dict(DEFAULT_BOUNDS), {
            "exp": set(labels_of_family("exp")),
            "rec": set(labels_of_family("rec")),
        }

    with open(FILTER_PATH, "rb") as fh:
        cfg = tomllib.load(fh)

    bounds = _parse_bounds(cfg.get("bounds", {}))
    raw_methods = cfg.get("methods", {})
    included = {
        "exp": _parse_family_methods(raw_methods, "exp"),
        "rec": _parse_family_methods(raw_methods, "rec"),
    }
    return bounds, included


def method_included(method: str, included_labels: Dict[str, Set[str]]) -> bool:
    """True if ``method`` (a METHODS key) is included by the filter."""
    spec = METHODS[method]
    return spec["label"] in included_labels[spec["family"]]


def passes_bounds(rmsre: float, lut: int, dsp: int, bounds: Dict[str, float]) -> bool:
    """True if a point lies inside every INCLUSIVE metric bound."""
    return (
        bounds["lut_min"] <= lut <= bounds["lut_max"]
        and bounds["dsp_min"] <= dsp <= bounds["dsp_max"]
        and bounds["rmsre_min"] <= rmsre <= bounds["rmsre_max"]
    )


# --------------------------------------------------------------------------- #
# Plot style
# --------------------------------------------------------------------------- #
# Colour encodes DSP.  The palette is chosen per DSP-count so the ends are
# anchored and extra hues fill the middle, going low->high DSP:
#   orange, blue  ... always anchor the low end
#   green,  red   ... always anchor the high end
#   yellow, then purple fill the middle for 5 and 6 values
# i.e. the template is [orange, blue, (yellow), (purple), green, red].
_ORANGE, _BLUE, _YELLOW, _PURPLE, _GREEN, _RED = (
    "#E69F00", "#0072B2", "#F0E442", "#a97bd4", "#018763", "#ed4546")
DSP_COLORS = {
    1: [_ORANGE],
    2: [_ORANGE, _BLUE],
    3: [_ORANGE, _BLUE, _YELLOW],
    4: [_ORANGE, _BLUE, _GREEN, _YELLOW],
    5: [_ORANGE, _BLUE, _RED, _GREEN, _YELLOW],
    6: [_ORANGE, _BLUE, _RED, _PURPLE, _GREEN, _YELLOW],
}
MAX_DSP_COLORS = max(DSP_COLORS)


def dsp_palette(n: int):
    """Ordered colour list (low->high DSP) for ``n`` distinct DSP values."""
    return DSP_COLORS[n]


# In dsp_only mode the marker is tied to the DSP *colour* (not its position), so
# a given colour always draws the same shape regardless of how many DSP values a
# plot has.  This matches the 6-value (SIMD=4) assignment.
DSP_MARKER_FOR_COLOR = {
    _ORANGE: "o",   # circle
    _BLUE:   "^",   # triangle up
    _RED:    "s",   # square
    _PURPLE: "D",   # diamond
    _GREEN:  "v",   # triangle down
    _YELLOW: "P",   # plus (filled)
}

# Shape encodes the (exp method, rec method) pair: the i-th pair (in sorted
# order) gets PAIR_MARKERS[i].  Clearly-distinct, well-filling shapes chosen for
# separability when points overlap.
PAIR_MARKERS = ["o", "^", "s", "D", "v", "P", "X", "*", "<", ">", "h", "p"]


def softmax_methods(method_str: str) -> Tuple[str, str]:
    """Recover (exp_label, rec_label) from a softmax method string.

    The step-2 combiner writes ``"exp:<exp_method>+rec:<rec_method>"``; we map
    those back to the human-readable method labels (e.g. "Splitting", "Lookup").
    """
    exp_part, rec_part = method_str.split("+")
    exp_method = exp_part.split(":", 1)[1]
    rec_method = rec_part.split(":", 1)[1]
    return METHODS[exp_method]["label"], METHODS[rec_method]["label"]


# --------------------------------------------------------------------------- #
# Base cases (subtracted out of the SIMD sweep to recover the "everything else"
# softmax skeleton).  These are matched against the *combined* method files.
#
# The base softmax build instantiates exactly one Rec base block and ``SIMD``
# Exp base blocks, so:
#     Base(softmax) = resources_SIMD(SIMD) - 1*Rec_base - SIMD*Exp_base
#
# Rec base: Bipartite, NUM_NEWTON_STEPS=1, AW0=3, AW1=AW2=4, WW=14  (user choice)
# Exp base: Splitting,  AW0=AW1=AW2=6, WW=22
# Both are parametric methods, so their ``match`` keys are integers.
# --------------------------------------------------------------------------- #
REC_BASE = {
    "method": "rec_bipartite",
    "match": {"NUM_NEWTON_STEPS": 1, "ADDR_WIDTH_0": 3, "ADDR_WIDTH_1": 4, "ADDR_WIDTH_2": 4, "WORD_WIDTH": 14},
}
EXP_BASE = {
    "method": "exp_splitting",
    "match": {"ADDR_WIDTH_0": 6, "ADDR_WIDTH_1": 6, "ADDR_WIDTH_2": 6, "WORD_WIDTH": 22},
}

# Column names used across the tidy output files.
OUT_FIELDS = ["method", "params", "rmsre", "lut", "dsp"]


# --------------------------------------------------------------------------- #
# Generic IO helpers
# --------------------------------------------------------------------------- #
def read_csv_dicts(path: str, required: Sequence[str] = ()) -> List[dict]:
    """Read a CSV into a list of ``dict`` rows (all values as raw strings).

    Fails with a clear, file-named message on the edits a human is most likely
    to make by hand: a missing/empty file, or a header that is missing a column
    the pipeline needs (renamed/deleted).  This keeps a bad data edit loud and
    actionable instead of surfacing as a bare ``KeyError`` deep in the run.
    """
    if not os.path.exists(path):
        raise SystemExit(f"ERROR: input file not found: {path}")
    with open(path, newline="") as fh:
        reader = csv.DictReader(fh)
        header = reader.fieldnames
        if not header:
            raise SystemExit(f"ERROR: {path} is empty or has no header row.")
        missing = [c for c in required if c not in header]
        if missing:
            raise SystemExit(
                f"ERROR: {path} is missing required column(s) {missing}. "
                f"Found columns: {list(header)}."
            )
        return list(reader)


def params_to_str(params: Dict[str, object]) -> str:
    """Serialise a parameter dict to a stable ``k=v;k=v`` string for the CSVs.

    Values are written verbatim (integers for parametric methods, free-form
    strings such as ``Full`` for categorical ones), so any method kind
    round-trips through :func:`str_to_params` unchanged.
    """
    return ";".join(f"{k}={params[k]}" for k in params)


def str_to_params(s: str) -> Dict[str, str]:
    """Inverse of :func:`params_to_str`.

    Values are returned as strings (not coerced to ``int``) so categorical
    parameters round-trip.  Downstream code uses ``params`` only for
    provenance/labels, never numerically, so no coercion is required.
    """
    if not s:
        return {}
    out: Dict[str, str] = {}
    for tok in s.split(";"):
        k, v = tok.split("=", 1)
        out[k] = v
    return out


def write_components(path: str, records: Sequence[dict]) -> None:
    """Write component records (exp.csv / rec.csv / softmax_*.csv) in a tidy,
    stable order."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # Deterministic ordering: by rmsre then lut then dsp.
    rows = sorted(records, key=lambda r: (r["rmsre"], r["lut"], r["dsp"]))
    with open(path, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(OUT_FIELDS)
        for r in rows:
            w.writerow([r["method"], params_to_str(r["params"]),
                        f"{r['rmsre']:.6e}", r["lut"], r["dsp"]])


def read_components(path: str) -> List[dict]:
    """Read back an exp.csv / rec.csv / softmax_*.csv produced by
    :func:`write_components`."""
    out = []
    for row in read_csv_dicts(path):
        out.append({
            "method": row["method"],
            "params": str_to_params(row["params"]),
            "rmsre": float(row["rmsre"]),
            "lut": int(row["lut"]),
            "dsp": int(row["dsp"]),
        })
    return out


# --------------------------------------------------------------------------- #
# Pareto logic
# --------------------------------------------------------------------------- #
# Objective vector = (rmsre, lut, dsp).  "Better means smaller in at least one";
# a point is dominated iff some other point is <= in every objective and < in at
# least one.  Points with an identical objective triple are de-duplicated so we
# do not keep exact-duplicate rows on the front.

OBJECTIVES = ("rmsre", "lut", "dsp")


def _obj(record: dict) -> Tuple[float, float, float]:
    return (record["rmsre"], float(record["lut"]), float(record["dsp"]))


def dominates(a: Tuple[float, ...], b: Tuple[float, ...]) -> bool:
    """True if objective-vector ``a`` dominates ``b`` (a<=b all dims, a<b once)."""
    le_all = all(x <= y for x, y in zip(a, b))
    lt_any = any(x < y for x, y in zip(a, b))
    return le_all and lt_any


def pareto_front(records: Iterable[dict]) -> List[dict]:
    """Return the non-dominated subset of ``records``.

    Exact-duplicate objective triples collapse to a single representative (the
    first encountered in the stable input order), so the front never carries
    redundant identical points.
    """
    recs = list(records)
    objs = [_obj(r) for r in recs]

    # Collapse exact duplicates first: keep the first index for each triple.
    seen: Dict[Tuple[float, float, float], int] = {}
    unique_idx: List[int] = []
    for i, o in enumerate(objs):
        if o not in seen:
            seen[o] = i
            unique_idx.append(i)

    keep: List[dict] = []
    for i in unique_idx:
        oi = objs[i]
        dominated = False
        for j in unique_idx:
            if j == i:
                continue
            if objs[j] == oi:
                continue  # duplicates already collapsed
            if dominates(objs[j], oi):
                dominated = True
                break
        if not dominated:
            keep.append(recs[i])
    return keep
