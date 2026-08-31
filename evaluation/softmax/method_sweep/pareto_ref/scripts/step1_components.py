"""Step 1 - build the pareto-optimal Exp and Rec component sets.

For every implementation method we:
  1. read the accuracy CSV  (params -> RMSRE)
  2. read the resource CSV   (params -> LUT, DSP)
  3. inner-join on the method parameters (accuracy points without a matching
     resource row are dropped and reported - they cannot be placed on the
     Pareto front without LUT/DSP)
  4. drop points with RMSRE <= RMSRE_MIN (1e-7)
  5. combine all methods of a family, keep only the Pareto front over
     (RMSRE, LUT, DSP)

Outputs: build/exp.csv and build/rec.csv
"""

from __future__ import annotations

import sys
from typing import Dict, List, Tuple

import helper_config as C


def _int_key(row: Dict[str, str], keys: Tuple[str, ...]) -> Tuple[int, ...]:
    return tuple(int(row[k]) for k in keys)


def _index_resources(method: str) -> Dict[Tuple[int, ...], Dict[str, str]]:
    """Map parameter-key -> resource row, guarding against duplicate keys."""
    spec = C.METHODS[method]
    keys = spec["keys"]
    rows = C.read_csv_dicts(f"{C.RESOURCE_DIR}/{method}.csv",
                            required=(*keys, "LUT", "DSP"))
    index: Dict[Tuple[int, ...], Dict[str, str]] = {}
    for r in rows:
        k = _int_key(r, keys)
        if k in index:
            raise ValueError(
                f"[{method}] duplicate resource key {dict(zip(keys, k))} - "
                "cannot join unambiguously"
            )
        index[k] = r
    return index


def load_method(method: str) -> List[dict]:
    """Join accuracy+resources for one method, apply the RMSRE floor.

    Returns component records; prints a per-method report of what was dropped.
    """
    spec = C.METHODS[method]
    keys = spec["keys"]
    label = spec["label"]

    acc_rows = C.read_csv_dicts(f"{C.ACCURACY_DIR}/{method}.csv",
                                required=(*keys, "RMSRE"))
    res_index = _index_resources(method)

    records: List[dict] = []
    n_no_res = 0
    n_below = 0
    for a in acc_rows:
        k = _int_key(a, keys)
        res = res_index.get(k)
        if res is None:
            n_no_res += 1
            continue
        rmsre = float(a["RMSRE"])
        if rmsre <= C.RMSRE_MIN:
            n_below += 1
            continue
        records.append({
            "method": method,
            "params": {kk: int(a[kk]) for kk in keys},
            "rmsre": rmsre,
            "lut": int(res["LUT"]),
            "dsp": int(res["DSP"]),
        })

    print(f"  [{method:<14}] label={label:<10} "
          f"acc={len(acc_rows):>3}  joined={len(acc_rows) - n_no_res:>3}  "
          f"no_resource={n_no_res:>3}  rmsre<=1e-7={n_below:>2}  "
          f"kept={len(records):>3}")
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
