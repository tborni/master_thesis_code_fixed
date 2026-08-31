#!/usr/bin/env python3
"""Shared writer for the LayerNorm N-sweep fit-parameters file.

Both plot scripts in this experiment fit a model and record its parameters:
``plot_resources.py`` fits an affine ``LUT = m*N + n`` and ``plot_accuracy.py``
fits a power law ``log(RMSRE) = r*log(N) + n``. Rather than each keeping its own
little file, they share a single human-readable summary::

    data/fit_parameters.txt

organised into ``[section]`` blocks, one per fitting script. Because the two
scripts run independently (and in either order, or one alone), this module writes
each section with an *idempotent upsert*: :func:`update_section` reads the current
file, replaces just the named section (or appends it if absent), and writes the
file back, leaving every other section and the file header untouched. A fresh run
therefore always reflects the latest fit for that script without clobbering the
other's, and repeated runs converge to the same file.

Keeping the formatting here (rather than in each script) means the on-disk lines
and the scripts' stdout never drift apart: each script formats its fit with the
helpers below and passes the same strings to both ``print`` and this writer.
"""

from __future__ import annotations

from pathlib import Path

# File-level title, always kept as the first line(s) of the file. Regenerated on
# every write so it stays put regardless of which section is being updated.
FILE_HEADER = (
    "# LayerNorm N-sweep fit parameters\n"
    "# Least-squares fits (numpy.polyfit). One [section] per fitting script;\n"
    "# each is regenerated in place on that script's run.\n"
)

# A section begins with a line of exactly "[name]".
_SECTION_PREFIX = "["


def _signed(value: float) -> str:
    """Format ``value`` as a ``"+ x"`` / ``"- x"`` term for an ``a*x <sign> b``.

    Keeps the sign out of the magnitude so a negative intercept reads as
    ``... + N - 16.7508`` rather than the awkward ``... + N + -16.7508``.
    """
    return f"- {abs(value):.6g}" if value < 0 else f"+ {value:.6g}"


def format_affine_line(name: str, var: str, m: float, intercept: float, r_squared: float) -> str:
    """Render an affine fit ``name = m*var + n`` as a single report line.

    ``var`` is the independent-variable symbol (e.g. ``"N"``). The number format
    matches the sibling SIMD_sweep report so the two experiments read alike.
    """
    return f"{name} = {m:.6g} * {var} {_signed(intercept)}   (R^2 = {r_squared:.6f})"


def format_powerlaw_line(name: str, var: str, r: float, intercept: float, r_squared: float) -> str:
    """Render a log-log power-law fit as a single report line.

    Fits ``log(name) = r*log(var) + n``; equivalently ``name = exp(n) * var**r``.
    Both forms are shown so the exponent ``r`` and the recovered prefactor are
    directly readable. ``r_squared`` is the coefficient of determination of the
    fit in log-log space.
    """
    prefactor = pow(2.718281828459045, intercept)
    return (
        f"log({name}) = {r:.6g} * log({var}) {_signed(intercept)}   (R^2 = {r_squared:.6f})"
        f"   [i.e. {name} = {prefactor:.6g} * {var}^{r:.6g}]"
    )


def _split_sections(text: str) -> tuple[list[str], dict[str, list[str]], list[str]]:
    """Split existing file ``text`` into (header, sections, order).

    ``header`` is the run of leading comment/blank lines before the first
    ``[section]``. ``sections`` maps section name -> its body lines (the lines
    after the ``[name]`` header up to the next section or EOF, trailing blanks
    trimmed). ``order`` records the section names in first-seen order so a rewrite
    preserves their arrangement.
    """
    header: list[str] = []
    sections: dict[str, list[str]] = {}
    order: list[str] = []
    current: str | None = None

    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith(_SECTION_PREFIX) and stripped.endswith("]"):
            current = stripped[1:-1]
            if current not in sections:
                sections[current] = []
                order.append(current)
            continue
        if current is None:
            header.append(line)
        else:
            sections[current].append(line)

    # Trim trailing blank lines from each section body.
    for name in sections:
        while sections[name] and not sections[name][-1].strip():
            sections[name].pop()
    return header, sections, order


def update_section(path: Path, section: str, body_lines: list[str]) -> None:
    """Idempotently write ``[section]`` with ``body_lines`` into ``path``.

    Any existing section of the same name is replaced in place; a new section is
    appended after the others. All other sections and the file header are
    preserved, so the two plot scripts can each own their section of a single
    shared file without overwriting one another. The canonical file header is
    (re)applied on every write.
    """
    existing = path.read_text(encoding="utf-8") if path.is_file() else ""
    _header, sections, order = _split_sections(existing)

    sections[section] = list(body_lines)
    if section not in order:
        order.append(section)

    parts = [FILE_HEADER.rstrip("\n")]
    for name in order:
        block = "\n".join([f"[{name}]", *sections[name]])
        parts.append(block)

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n\n".join(parts) + "\n", encoding="utf-8")
    print(f"Updated [{section}] in {path}")
