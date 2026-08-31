"""Step 1 - build the pareto-optimal Exp and Rec component sets.

This is the method-sweep variant of ``pareto_ref``'s step 1.  The reference read
two files per method (an accuracy CSV and a resource CSV) and inner-joined them
on the method parameters.  Here each method already has ONE *combined* CSV
(``data/{exp,rec}/<Label>_combined.csv``) carrying the parameters together with
LUT, DSP and RMSRE, so there is no join: one row is one fully-specified
implementation.

For every implementation method we:
  1. read its combined CSV
  2. drop points with RMSRE <= RMSRE_MIN (1e-7)
  3. combine all methods of a family and keep only the Pareto front over
     (RMSRE, LUT, DSP)

The combined files come in three shapes (see helper_config.METHODS ``kind``):
  * parametric  - keyed by integer approximation parameters (Bipartite, Lookup,
                  Splitting)
  * positional  - a single unparameterised ``LUT,DSP,RMSRE`` row (exp
                  Bit-hacking)
  * categorical - keyed by string configuration columns such as DSP_USAGE
                  (IP core)
The RMSRE floor is applied uniformly to all three.  IP core's RMSRE (~2.7e-8)
is below the floor, so all of its rows drop here - it is still read and counted
in the per-method report, just never carried onto the front.

Within a single file duplicate keys are a data error (an ambiguous point) and
abort immediately.

Outputs: processed_data/exp.csv and processed_data/rec.csv
"""

from __future__ import annotations

import sys
from typing import Dict, List, Tuple

import helper_config as C


def _row_key(row: Dict[str, str], keys: Tuple[str, ...]) -> Tuple:
    """Identity tuple for a row.  Parametric keys are compared as ints (so
    ``08`` == ``8``); categorical keys stay strings.  Positional methods have no
    keys, so every row shares the empty key -- which is why they must be unique.
    """
    out = []
    for k in keys:
        v = row[k]
        try:
            out.append(int(v))
        except ValueError:
            out.append(v)
    return tuple(out)


def _params(row: Dict[str, str], keys: Tuple[str, ...]) -> Dict[str, str]:
    """Parameter dict kept for provenance: the key columns, values verbatim."""
    return {k: row[k] for k in keys}


def load_method(method: str) -> List[dict]:
    """Read one method's combined CSV and apply the RMSRE floor.

    Returns component records; prints a per-method report of what was dropped.
    Aborts on a duplicate identity key within the file (ambiguous point).
    """
    spec = C.METHODS[method]
    keys = spec["keys"]
    label = spec["label"]
    kind = spec["kind"]
    path = C.method_file(method)

    rows = C.read_csv_dicts(path, required=(*keys, "LUT", "DSP", "RMSRE"))

    if kind == "positional":
        # No swept parameters: the file must hold exactly one row so the
        # implementation is resolved unambiguously.
        if len(rows) != 1:
            raise SystemExit(
                f"ERROR: [{method}] expected exactly 1 row in {spec['file']} "
                f"(no swept parameters), found {len(rows)}."
            )

    records: List[dict] = []
    n_below = 0
    seen_keys: Dict[Tuple, int] = {}
    for i, r in enumerate(rows):
        key = _row_key(r, keys)
        if key in seen_keys:
            raise SystemExit(
                f"ERROR: [{method}] duplicate key {key} in {spec['file']} "
                "(ambiguous point) - cannot build the front unambiguously."
            )
        seen_keys[key] = i

        rmsre = float(r["RMSRE"])
        if rmsre <= C.RMSRE_MIN:
            n_below += 1
            continue
        records.append({
            "method": method,
            "params": _params(r, keys),
            "rmsre": rmsre,
            "lut": int(r["LUT"]),
            "dsp": int(r["DSP"]),
        })

    print(f"  [{method:<16}] label={label:<11} kind={kind:<11} "
          f"rows={len(rows):>3}  rmsre<=1e-7={n_below:>3}  kept={len(records):>3}")
    return records


def build_family(family: str, methods: List[str], out_path: str) -> List[dict]:
    print(f"[{family.upper()}] extracting components:")
    combined: List[dict] = []
    for m in methods:
        combined.extend(load_method(m))

    front = C.pareto_front(combined)
    C.write_components(out_path, front)

    dropped = len(combined) - len(front)
    print(f"[{family.upper()}] combined={len(combined)}  "
          f"pareto={len(front)}  (dropped {dropped} dominated)  -> {out_path}\n")
    return front


def main() -> None:
    build_family("exp", C.EXP_METHODS, C.EXP_CSV)
    build_family("rec", C.REC_METHODS, C.REC_CSV)


if __name__ == "__main__":
    sys.exit(main())
