#!/usr/bin/env python3
"""Independent reference implementation of every RF is Simple calculator.

This exists to catch the class of bug a hand-written test cannot: one where the
test and the code make the *same* mistake, because the same person wrote both.

Every relationship here is deliberately formulated differently from the Swift:

  * power        — 10**(x/10) directly, rather than through a unit protocol
  * path loss    — the 20log10(d_km) + 20log10(f_MHz) + 32.4478 form, rather
                   than the SI 4*pi*d/lambda form
  * reflection   — solved through reflected power ratios rather than through
                   the VSWR identity
  * cascade      — an explicit running product, rather than a single pass
  * sensitivity  — kTB computed in watts and converted, rather than in dB

Agreement to nine significant digits between two different formulations is
strong evidence that both are right.

Usage:
    python3 reference_model.py --check          # self-check against known values
    python3 reference_model.py --emit-swift     # write test vectors for Swift
"""

from __future__ import annotations

import argparse
import json
import math
import sys

C = 299_792_458.0          # speed of light, m/s (exact)
K_B = 1.380_649e-23        # Boltzmann constant, J/K (exact)
T0 = 290.0                 # standard noise temperature, K
DIPOLE_GAIN_DBI = 2.15

# --------------------------------------------------------------------------
# Calculators
# --------------------------------------------------------------------------


def power_conversion(value: float, unit: str) -> dict:
    """dBm / dBW / W / mW / uW, all routed through watts."""
    to_watts = {
        "dBm": lambda v: 10 ** ((v - 30) / 10),
        "dBW": lambda v: 10 ** (v / 10),
        "W": lambda v: v,
        "mW": lambda v: v / 1e3,
        "uW": lambda v: v / 1e6,
    }
    watts = to_watts[unit](value)
    out = {"watts": watts, "milliwatts": watts * 1e3, "microwatts": watts * 1e6}
    if watts > 0:
        out["dBm"] = 10 * math.log10(watts * 1e3)   # note: /1mW, not -30
        out["dBW"] = 10 * math.log10(watts)
    return out


def voltage_power_impedance(quantity: str, value: float, z: float) -> dict:
    if quantity == "power":
        watts = value
        volts = math.sqrt(value * z)
    else:
        volts = value
        watts = value * value / z
    out = {
        "watts": watts,
        "rmsVolts": volts,
        "peakVolts": volts * math.sqrt(2),
        "peakToPeakVolts": volts * 2 * math.sqrt(2),
    }
    if watts > 0:
        out["dBm"] = 10 * math.log10(watts) + 30
    if volts > 0:
        out["dBmV"] = 20 * math.log10(volts * 1e3)
        out["dBuV"] = 20 * math.log10(volts * 1e6)
    return out


def wave(quantity: str, value: float, vf: float = 1.0) -> dict:
    """Frequency / period / wavelength, solved via the period each time."""
    v = C * vf
    if quantity == "frequency":
        period = 1.0 / value
    elif quantity == "period":
        period = value
    else:  # wavelength
        period = value / v
    frequency = 1.0 / period
    wavelength = v * period
    return {
        "frequencyHz": frequency,
        "periodSeconds": period,
        "wavelengthMetres": wavelength,
        "quarterWavelengthMetres": wavelength / 4,
        "velocity": v,
    }


def free_space_path_loss(frequency_hz: float, distance_m: float) -> dict:
    """The 32.4478 constant form, in km and MHz."""
    d_km = distance_m / 1000.0
    f_mhz = frequency_hz / 1e6
    constant = 20 * math.log10(4 * math.pi * 1e9 / C)   # = 32.4477...
    loss = 20 * math.log10(d_km) + 20 * math.log10(f_mhz) + constant
    return {
        "lossDB": loss,
        "wavelengthMetres": C / frequency_hz,
        "minimumValidDistanceMetres": (C / frequency_hz) / (4 * math.pi),
    }


def link_budget(ptx, ltx, gtx, lpath, grx, lrx, sensitivity=None) -> dict:
    """Accumulated as a running total rather than one expression."""
    level = ptx
    level -= ltx
    level += gtx
    eirp = level
    level -= lpath
    level += grx
    level -= lrx
    out = {"receivedPowerDBm": level, "eirpDBm": eirp}
    if sensitivity is not None:
        out["marginDB"] = level - sensitivity
    return out


def radiated_power(ptx: float, feed_loss: float, gain: float, reference: str) -> dict:
    gain_dbi = gain + (DIPOLE_GAIN_DBI if reference == "dBd" else 0.0)
    eirp = ptx - feed_loss + gain_dbi
    return {
        "eirpDBm": eirp,
        "erpDBm": eirp - DIPOLE_GAIN_DBI,
        "antennaGainDBi": gain_dbi,
        "eirpWatts": 10 ** ((eirp - 30) / 10),
    }


def thermal_noise(bandwidth_hz: float, temperature_k: float = T0, nf_db=None) -> dict:
    """Computed in watts first, then converted — the opposite order to the app."""
    noise_watts = K_B * temperature_k * bandwidth_hz
    density_watts = K_B * temperature_k
    out = {
        "noiseDBm": 10 * math.log10(noise_watts / 1e-3),
        "densityDBmPerHz": 10 * math.log10(density_watts / 1e-3),
    }
    if nf_db is not None:
        out["floorDBm"] = out["noiseDBm"] + nf_db
    return out


def sensitivity(bandwidth_hz: float, nf_db: float, snr_db: float,
                temperature_k: float = T0) -> dict:
    noise = thermal_noise(bandwidth_hz, temperature_k, nf_db)
    floor = noise["floorDBm"]
    return {
        "sensitivityDBm": floor + snr_db,
        "noiseFloorDBm": floor,
        "thermalNoiseDBm": noise["noiseDBm"],
        "equivalentNoiseTemperature": T0 * (10 ** (nf_db / 10) - 1),
    }


def reflection(quantity: str, value: float) -> dict:
    """Solved through the reflected *power* ratio rather than through VSWR."""
    if quantity == "vswr":
        gamma = (value - 1) / (value + 1)
    elif quantity == "returnLoss":
        gamma = math.sqrt(10 ** (-value / 10))          # via power, not 10**(-RL/20)
    elif quantity == "reflectionCoefficient":
        gamma = value
    elif quantity == "reflectedPower":
        gamma = math.sqrt(value / 100)
    else:  # mismatchLoss
        gamma = math.sqrt(1 - 10 ** (-value / 10))

    reflected_fraction = gamma ** 2
    transmitted_fraction = 1 - reflected_fraction
    out = {
        "gamma": gamma,
        "reflectedPowerPercent": reflected_fraction * 100,
        "transmittedPowerPercent": transmitted_fraction * 100,
    }
    if gamma < 1:
        out["vswr"] = (1 + gamma) / (1 - gamma)
        out["mismatchLossDB"] = -10 * math.log10(transmitted_fraction)
    if gamma > 0:
        out["returnLossDB"] = -10 * math.log10(reflected_fraction)   # power form
    return out


def cascade(stages: list[tuple[float, float]]) -> dict:
    """Friis, accumulated stage by stage with an explicit running product."""
    total_gain_db = 0.0
    running_gain = 1.0
    excess = 0.0
    terms = []
    for gain_db, nf_db in stages:
        f = 10 ** (nf_db / 10)
        term = (f - 1) / running_gain
        terms.append(term)
        excess += term
        total_gain_db += gain_db
        running_gain *= 10 ** (gain_db / 10)
    total_f = 1 + excess
    return {
        "totalGainDB": total_gain_db,
        "totalNoiseFigureDB": 10 * math.log10(total_f),
        "equivalentNoiseTemperature": T0 * (total_f - 1),
        "shares": [t / excess * 100 for t in terms] if excess else [],
    }


def effective_aperture(frequency_hz: float, gain_dbi: float) -> dict:
    wavelength = C / frequency_hz
    aperture = (10 ** (gain_dbi / 10)) * wavelength ** 2 / (4 * math.pi)
    return {
        "apertureSquareMetres": aperture,
        "apertureSquareCentimetres": aperture * 1e4,
        "wavelengthMetres": wavelength,
        "equivalentCircleDiameterMetres": math.sqrt(4 * aperture / math.pi),
    }


def field_regions(frequency_hz: float, dimension_m: float) -> dict:
    wavelength = C / frequency_hz
    return {
        "reactiveBoundaryMetres": 0.62 * math.sqrt(dimension_m ** 3 / wavelength),
        "fraunhoferBoundaryMetres": 2 * dimension_m ** 2 / wavelength,
        "smallAntennaBoundaryMetres": wavelength / (2 * math.pi),
        "wavelengthMetres": wavelength,
        "practicalFarFieldMetres": max(
            2 * dimension_m ** 2 / wavelength,
            3 * wavelength,
            0.62 * math.sqrt(dimension_m ** 3 / wavelength),
        ),
    }


# --------------------------------------------------------------------------
# Self-check against values from published tables
# --------------------------------------------------------------------------

KNOWN_VALUES = [
    ("0 dBm is 1 mW", power_conversion(0, "dBm")["watts"], 1e-3, 1e-12),
    ("30 dBm is 1 W", power_conversion(30, "dBm")["watts"], 1.0, 1e-12),
    ("1 W is 30 dBm", power_conversion(1, "W")["dBm"], 30.0, 1e-12),
    ("lambda at 1 GHz", wave("frequency", 1e9)["wavelengthMetres"], 0.299792458, 1e-12),
    ("FSPL 1 km 1 GHz", free_space_path_loss(1e9, 1000)["lossDB"], 92.44778322, 1e-8),
    ("VSWR 2 return loss", reflection("vswr", 2)["returnLossDB"], 9.542425094, 1e-9),
    ("VSWR 2 mismatch loss", reflection("vswr", 2)["mismatchLossDB"], 0.511525224, 1e-9),
    ("VSWR 1.5 reflected %", reflection("vswr", 1.5)["reflectedPowerPercent"], 4.0, 1e-12),
    ("10 dB RL is VSWR 1.925", reflection("returnLoss", 10)["vswr"], 1.924950591, 1e-9),
    ("-174 dBm/Hz at 290 K", thermal_noise(1)["densityDBmPerHz"], -173.975187194, 1e-9),
    ("-114 dBm in 1 MHz", thermal_noise(1e6)["noiseDBm"], -113.975187194, 1e-9),
    ("0 dBm in 50 ohm is 223.6 mV",
     voltage_power_impedance("power", 1e-3, 50)["rmsVolts"], 0.22360679774997896, 1e-9),
    ("0 dBm in 50 ohm is 107 dBuV",
     voltage_power_impedance("power", 1e-3, 50)["dBuV"], 106.989700043, 1e-9),
    ("1.5 dB loss then 1 dB LNA is 2.5 dB",
     cascade([(-1.5, 1.5), (20, 1)])["totalNoiseFigureDB"], 2.5, 1e-9),
    ("isotropic aperture at 1 GHz",
     effective_aperture(1e9, 0)["apertureSquareMetres"], 0.007152066466270221, 1e-9),
    ("far field 1 m at 1 GHz",
     field_regions(1e9, 1)["fraunhoferBoundaryMetres"], 6.671281904, 1e-9),
    ("1 dB NF is 75 K", sensitivity(1e6, 1, 0)["equivalentNoiseTemperature"], 75.0885, 1e-4),
]


def self_check() -> int:
    failures = 0
    for name, actual, expected, tolerance in KNOWN_VALUES:
        scale = max(abs(actual), abs(expected), 1e-30)
        ok = abs(actual - expected) <= tolerance * scale
        print(f"{'PASS' if ok else 'FAIL'}  {name:38s} {actual!r}")
        if not ok:
            print(f"      expected {expected!r}")
            failures += 1
    print(f"\n{len(KNOWN_VALUES) - failures}/{len(KNOWN_VALUES)} reference values agree")
    return failures


# --------------------------------------------------------------------------
# Test vector generation
# --------------------------------------------------------------------------

def build_vectors() -> list[dict]:
    """A deterministic grid across every calculator.

    Values are chosen to span the ranges an RF engineer actually works in, and
    to sit on the awkward boundaries: zero power, a perfect match, total
    reflection, an electrically small antenna.
    """
    cases: list[dict] = []

    def add(calculator, inputs, expected, tolerance=1e-9):
        cases.append({
            "calculator": calculator,
            "inputs": inputs,
            "expected": {k: v for k, v in expected.items() if isinstance(v, (int, float))},
            "tolerance": tolerance,
        })

    # Power conversion. The unit index matches PowerUnit.allCases order in Swift:
    # 0 dBm, 1 dBW, 2 W, 3 mW, 4 uW.
    for index, (unit, values) in enumerate([
        ("dBm", [-120, -60, -30, -10, 0, 13, 30, 47, 60]),
        ("dBW", [-30, 0, 20]),
        ("W", [1e-9, 1e-3, 0.2, 1, 100, 1000]),
        ("mW", [0.001, 1, 200, 5000]),
        ("uW", [1, 1000]),
    ]):
        for v in values:
            add("power", {"value": v, "unit": index}, power_conversion(v, unit))

    # Voltage / power / impedance
    for z in [50, 75, 300]:
        for watts in [1e-6, 1e-3, 0.1, 1, 100]:
            add("voltagePower", {"quantity": 0, "value": watts, "impedance": z},
                voltage_power_impedance("power", watts, z))
        for volts in [1e-3, 0.2236, 1, 10]:
            add("voltagePower", {"quantity": 1, "value": volts, "impedance": z},
                voltage_power_impedance("voltage", volts, z))

    # Frequency / period / wavelength
    for f in [1.0, 1e3, 13.56e6, 100e6, 433.92e6, 2.4e9, 5.8e9, 77e9]:
        for vf in [1.0, 0.66, 0.85]:
            add("wave", {"quantity": 0, "value": f, "velocityFactor": vf}, wave("frequency", f, vf))
    for t in [1e-3, 1e-6, 1e-9]:
        add("wave", {"quantity": 1, "value": t, "velocityFactor": 1.0}, wave("period", t))
    for lam in [0.01, 0.125, 1.0, 300.0]:
        add("wave", {"quantity": 2, "value": lam, "velocityFactor": 1.0}, wave("wavelength", lam))

    # Free-space path loss
    for f in [100e6, 900e6, 2.4e9, 5.8e9, 28e9]:
        for d in [1, 10, 100, 1000, 40_000]:
            add("fspl", {"frequency": f, "distance": d}, free_space_path_loss(f, d))

    # Link budget
    for ptx in [0, 20, 30]:
        for lpath in [80, 100, 140]:
            for sens in [None, -90, -110]:
                inputs = {"ptx": ptx, "ltx": 1.5, "gtx": 6, "lpath": lpath,
                          "grx": 3, "lrx": 0.5}
                if sens is not None:
                    inputs["sensitivity"] = sens
                add("linkBudget", inputs,
                    link_budget(ptx, 1.5, 6, lpath, 3, 0.5, sens))

    # EIRP / ERP
    for ptx in [10, 30, 46]:
        for gain, ref in [(0, "dBi"), (12, "dBi"), (12, "dBd"), (-3, "dBi")]:
            add("radiatedPower",
                {"ptx": ptx, "feedLoss": 2, "gain": gain, "reference": 0 if ref == "dBi" else 1},
                radiated_power(ptx, 2, gain, ref))

    # Thermal noise
    for b in [1, 1e3, 200e3, 1e6, 20e6]:
        for t in [77, 290, 1000]:
            for nf in [None, 0, 3.5, 12]:
                inputs = {"bandwidth": b, "temperature": t}
                if nf is not None:
                    inputs["noiseFigure"] = nf
                add("thermalNoise", inputs, thermal_noise(b, t, nf))

    # Receiver sensitivity
    for b in [12.5e3, 200e3, 20e6]:
        for nf in [1, 6, 15]:
            for snr in [-3, 0, 10, 20]:
                add("sensitivity", {"bandwidth": b, "noiseFigure": nf, "snr": snr, "temperature": 290},
                    sensitivity(b, nf, snr))

    # Reflection — including both boundaries
    for v in [1.0, 1.05, 1.2, 1.5, 2.0, 3.0, 5.83, 10.0, 100.0]:
        add("reflection", {"quantity": 0, "value": v}, reflection("vswr", v))
    for v in [0.5, 3.0, 6.02, 10.0, 14.0, 20.0, 40.0]:
        add("reflection", {"quantity": 1, "value": v}, reflection("returnLoss", v))
    for v in [0.0, 0.1, 0.2, 0.3333333333333333, 0.5, 0.7071067811865476, 0.9, 1.0]:
        add("reflection", {"quantity": 2, "value": v}, reflection("reflectionCoefficient", v))
    for v in [0.0, 1.0, 4.0, 10.0, 50.0, 100.0]:
        add("reflection", {"quantity": 3, "value": v}, reflection("reflectedPower", v))
    for v in [0.0, 0.18, 0.51, 1.0, 3.0, 10.0]:
        add("reflection", {"quantity": 4, "value": v}, reflection("mismatchLoss", v))

    # Cascade
    chains = [
        [(20, 1)],
        [(-1.5, 1.5), (20, 1)],
        [(20, 1), (20, 10)],
        [(20, 10), (20, 1)],
        [(-3, 3), (25, 0.8), (-6, 6), (30, 8)],
        [(10, 2), (10, 2), (10, 2), (10, 2), (10, 2)],
        [(-20, 20), (40, 1.2)],
    ]
    for chain in chains:
        add("cascade",
            {"gains": [g for g, _ in chain], "noiseFigures": [n for _, n in chain]},
            cascade(chain))

    # Effective aperture
    for f in [100e6, 900e6, 2.4e9, 10e9]:
        for g in [0, 6, 12, 30]:
            add("aperture", {"frequency": f, "gain": g}, effective_aperture(f, g))

    # Field regions
    for f in [100e6, 1e9, 10e9]:
        for d in [0.05, 0.3, 1.0, 3.0]:
            add("fieldRegions", {"frequency": f, "dimension": d}, field_regions(f, d))

    return cases


SWIFT_HEADER = '''// Generated by Scripts/qa/reference_model.py — do not edit by hand.
//
// {count} test vectors produced by an independent Python implementation of
// every calculator, deliberately formulated differently from the Swift. See
// docs/QA-AGENT.md. Regenerate with:
//
//     python3 Scripts/qa/reference_model.py --emit-swift > RFIsSimpleTests/OracleVectors.swift

import Foundation

/// One case: which calculator, what went in, and what an independent
/// implementation says should come out.
struct OracleCase: Sendable {{
    let calculator: String
    let inputs: [String: Double]
    let arrayInputs: [String: [Double]]
    let expected: [String: Double]
    let tolerance: Double

    init(
        _ calculator: String,
        inputs: [String: Double] = [:],
        arrayInputs: [String: [Double]] = [:],
        expected: [String: Double],
        tolerance: Double
    ) {{
        self.calculator = calculator
        self.inputs = inputs
        self.arrayInputs = arrayInputs
        self.expected = expected
        self.tolerance = tolerance
    }}
}}

enum OracleVectors {{
    static let all: [OracleCase] = [
'''


def swift_literal(value: float) -> str:
    if value != value or value in (float("inf"), float("-inf")):
        raise ValueError(f"non-finite value in vectors: {value}")
    return repr(float(value))


def emit_swift(cases: list[dict]) -> str:
    lines = [SWIFT_HEADER.format(count=len(cases))]
    for case in cases:
        scalars = {k: v for k, v in case["inputs"].items() if not isinstance(v, list)}
        arrays = {k: v for k, v in case["inputs"].items() if isinstance(v, list)}

        parts = [f'        OracleCase("{case["calculator"]}"']
        if scalars:
            inner = ", ".join(f'"{k}": {swift_literal(v)}' for k, v in sorted(scalars.items()))
            parts.append(f"inputs: [{inner}]")
        if arrays:
            inner = ", ".join(
                f'"{k}": [{", ".join(swift_literal(x) for x in v)}]' for k, v in sorted(arrays.items())
            )
            parts.append(f"arrayInputs: [{inner}]")
        expected = ", ".join(
            f'"{k}": {swift_literal(v)}' for k, v in sorted(case["expected"].items())
        )
        parts.append(f"expected: [{expected}]")
        parts.append(f'tolerance: {case["tolerance"]!r}')
        lines.append(",\n            ".join(parts) + "),")
    lines.append("    ]\n}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify against published values")
    parser.add_argument("--emit-swift", action="store_true", help="write Swift test vectors")
    parser.add_argument("--emit-json", action="store_true", help="write JSON test vectors")
    args = parser.parse_args()

    if args.check or not (args.emit_swift or args.emit_json):
        return 1 if self_check() else 0

    cases = build_vectors()
    if args.emit_json:
        json.dump(cases, sys.stdout, indent=2)
    else:
        sys.stdout.write(emit_swift(cases))
    return 0


if __name__ == "__main__":
    sys.exit(main())
