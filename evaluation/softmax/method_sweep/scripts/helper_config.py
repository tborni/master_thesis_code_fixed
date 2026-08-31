"""Shared configuration and helpers for the softmax method-sweep Pareto analysis.

This is the method-sweep counterpart of ``pareto_ref/scripts/helper_config.py``.
The analysis is identical -- extract the Pareto-optimal exp and rec component
implementations, combine them into softmax implementations for a SIMD sweep, and
plot the resulting fronts -- but the *input layout* differs:

    pareto_ref/                         this folder (method_sweep)
    -----------                         ------------------------------------
    accuracy/<method>.csv  (params,     data/{exp,rec}/<Label>_combined.csv
                            RMSRE)         (params, LUT, DSP, RMSRE all in
    resources/<method>.csv (params,        ONE combined file per method)
                            LUT, DSP)
    resources/SIMD_sweep.csv            data/resources_SIMD.csv

So there is no accuracy<->resource inner join here: each method's RMSRE, LUT and
DSP already live together in one *combined* CSV.  ``step1_components.py`` reads
those directly.

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

The RMSRE floor (``RMSRE_MIN``) is applied uniformly to every kind.  IP core's
measured RMSRE (~2.7e-8) sits *below* that floor, so those rows drop out during
component extraction exactly like any other numerically-perfect point -- they
are still read and reported, just not carried onto the front.

Design notes
------------
* We deliberately depend only on the stdlib (``csv``, ``math``); the plot uses
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
from typing import Dict, Iterable, List, Sequence, Tuple

# --------------------------------------------------------------------------- #
# Paths
# --------------------------------------------------------------------------- #
# This module lives in <project>/scripts, so the project root is one level up.
SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPTS_DIR)

DATA_DIR = os.path.join(ROOT, "data")
# Combined per-method component CSVs (params + LUT + DSP + RMSRE together).
EXP_DATA_DIR = os.path.join(DATA_DIR, "exp")
REC_DATA_DIR = os.path.join(DATA_DIR, "rec")

PROCESSED_DIR = os.path.join(ROOT, "processed_data")  # generated CSVs
# Figures are written to two parallel trees with identical structure:
#   images/          - each diagram auto-scales its own axes
#   images_aligned/  - all diagrams share one common x- and y-range (the global
#                      extent across every SIMD value), so plots are comparable
IMAGES_DIR = os.path.join(ROOT, "images")
IMAGES_ALIGNED_DIR = os.path.join(ROOT, "images_aligned")


def _images_root(aligned: bool) -> str:
    return IMAGES_ALIGNED_DIR if aligned else IMAGES_DIR


# The exp/rec component fronts are SIMD-independent (step 1 does not use SIMD),
# so they live at the top of processed_data/ and are computed once.
EXP_CSV = os.path.join(PROCESSED_DIR, "exp.csv")
REC_CSV = os.path.join(PROCESSED_DIR, "rec.csv")

# Everything below is produced per SIMD value:
#   processed_data/softmax_SIMD_<v>.csv                        (step 2)
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
    processed_data/softmax_SIMD_4.csv."""
    return os.path.join(PROCESSED_DIR, f"softmax_{simd_tag(simd)}.csv")


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
# to recover the "everything else" skeleton.  In pareto_ref this was
# resources/SIMD_sweep.csv; here it is data/resources_SIMD.csv (same columns:
# N, SIMD, ..., LUT, DSP, ...).
SIMD_SWEEP_CSV = os.path.join(DATA_DIR, "resources_SIMD.csv")

# --------------------------------------------------------------------------- #
# Tunable constants
# --------------------------------------------------------------------------- #
# SIMD sweep: step 2 runs once per value here, each re-selecting the
# Base(softmax) row from resources_SIMD.csv and rescaling the per-lane Exp
# resources.  Every value must exist in data/resources_SIMD.csv (which provides
# 1, 2, 4, 8, 16, 32, 64).  We mirror the reference sweep of 1, 2, 4.
SIMD_SWEEP = [1, 2, 4]

# Implementations whose RMSRE is at or below this floor are considered
# "numerically perfect" and dropped (they only add resources without a
# meaningful accuracy trade-off).  Strictly-greater keeps a point.  This is what
# removes the IP-core rows (RMSRE ~ 2.7e-8) from the fronts.
RMSRE_MIN: float = 1e-7

# Residual RMSRE contribution of everything in the softmax datapath that is
# neither the exp nor the reciprocal approximation (quantisation of the
# subtract/normalise stages, etc.).  Combined in quadrature.
RMSRE_OTHER: float = 1.918e-7

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
