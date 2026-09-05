import Foundation

/// The calculator catalogue.
///
/// Each descriptor is produced by an exhaustive `switch`, so the compiler — not
/// a test, and not a runtime lookup that could return `nil` — guarantees every
/// calculator in `CalculatorID` has content.
extension CalculatorID {
    var descriptor: CalculatorDescriptor {
        switch self {
        case .powerConverter:
            return CalculatorDescriptor(
                id: self,
                title: "Power Converter",
                purpose: "Convert a power level between dBm, dBW, watts, milliwatts and microwatts.",
                systemImage: "bolt.horizontal.fill",
                category: .signalsAndPower,
                aliases: ["dbm", "dbw", "watt", "watts", "milliwatt", "microwatt", "mw", "uw",
                          "dbm to watts", "watts to dbm", "power conversion", "dbm w"],
                status: .available,
                formula: Formula(
                    expression: "P(dBm) = 10·log₁₀( P / 1 mW )\nP(dBW) = P(dBm) − 30",
                    variables: [
                        VariableDefinition(symbol: "P", meaning: "Power, linear"),
                        VariableDefinition(symbol: "dBm", meaning: "Power referred to 1 mW"),
                        VariableDefinition(symbol: "dBW", meaning: "Power referred to 1 W")
                    ],
                    spokenDescription: "Power in dBm equals ten times the base ten logarithm of the power divided by one milliwatt. Power in dBW is thirty decibels below the same value in dBm."
                ),
                practicalNote: "Every 3 dB is a factor of two in power and every 10 dB a factor of ten, so 23 dBm is 200 mW. Zero power has no dB equivalent, which is why 0 W shows a dash rather than a number.",
                commonMistake: "dBm is an absolute power and dB is a ratio: two 3 dBm signals combined are not 6 dBm, but 3 dBm through a 3 dB attenuator is 0 dBm.",
                relatedArticles: [.dbmAndDbw, .decibels, .powerConversion]
            )

        case .voltagePowerImpedance:
            return CalculatorDescriptor(
                id: self,
                title: "Voltage / Power / Impedance",
                purpose: "Move between RMS voltage and power for a chosen system impedance.",
                systemImage: "bolt.circle",
                category: .signalsAndPower,
                aliases: ["rms", "vrms", "volts", "voltage", "impedance", "50 ohm", "75 ohm", "dbmv", "dbuv"],
                status: .planned,
                formula: nil,
                practicalNote: "Voltage and power only track each other once the impedance is fixed, so the impedance selector is part of the answer.",
                commonMistake: nil,
                relatedArticles: [.voltagePowerImpedance, .impedanceBasics]
            )

        case .wavelength:
            return CalculatorDescriptor(
                id: self,
                title: "Frequency / Period / Wavelength",
                purpose: "Enter any one of frequency, period or wavelength and get the other two.",
                systemImage: "waveform.path",
                category: .fundamentals,
                aliases: ["lambda", "wavelength", "period", "frequency", "velocity factor",
                          "quarter wave", "half wave", "vf", "electrical length"],
                status: .available,
                formula: Formula(
                    expression: "λ = v / f\nT = 1 / f\nv = VF · c",
                    variables: [
                        VariableDefinition(symbol: "λ", meaning: "Wavelength, m"),
                        VariableDefinition(symbol: "f", meaning: "Frequency, Hz"),
                        VariableDefinition(symbol: "T", meaning: "Period, s"),
                        VariableDefinition(symbol: "v", meaning: "Propagation velocity, m/s"),
                        VariableDefinition(symbol: "VF", meaning: "Velocity factor, 1 in vacuum"),
                        VariableDefinition(symbol: "c", meaning: "299 792 458 m/s")
                    ],
                    spokenDescription: "Wavelength equals propagation velocity divided by frequency. Period equals one divided by frequency. Propagation velocity equals the velocity factor times the speed of light."
                ),
                practicalNote: "The quarter-wavelength figure is the one most often needed in practice — stub lengths, whip antennas and matching sections are all cut from it. Inside a cable the wave travels slower, so set the velocity factor before measuring a physical length.",
                commonMistake: "A length cut from the free-space wavelength is too long for coax: at a velocity factor of 0.66 the cable is a third shorter.",
                relatedArticles: [.frequencyPeriodWavelength, .electricalLength, .spectrumBands]
            )

        case .freeSpacePathLoss:
            return CalculatorDescriptor(
                id: self,
                title: "Free-Space Path Loss",
                purpose: "Loss between two isotropic antennas with nothing in the way.",
                systemImage: "dot.radiowaves.left.and.right",
                category: .propagation,
                aliases: ["fspl", "friis", "path loss", "free space loss", "spreading loss"],
                status: .planned,
                formula: nil,
                practicalNote: "Free-space loss is the floor, not the answer: real paths add obstruction, rain and multipath on top.",
                commonMistake: nil,
                relatedArticles: [.freeSpacePathLoss, .linkBudget, .fresnelZone]
            )

        case .linkBudget:
            return CalculatorDescriptor(
                id: self,
                title: "Link Budget",
                purpose: "Add up gains and losses along a path to find received power and margin.",
                systemImage: "list.bullet.rectangle",
                category: .propagation,
                aliases: ["link margin", "received power", "rx power", "budget", "fade margin"],
                status: .planned,
                formula: nil,
                practicalNote: "A link budget is bookkeeping in decibels; the margin at the end is what tells you whether the link survives a bad day.",
                commonMistake: nil,
                relatedArticles: [.linkBudget, .freeSpacePathLoss, .receiverSensitivity]
            )

        case .thermalNoise:
            return CalculatorDescriptor(
                id: self,
                title: "Thermal Noise",
                purpose: "Noise power in a given bandwidth, and the receiver noise floor above it.",
                systemImage: "thermometer.medium",
                category: .signalsAndPower,
                aliases: ["ktb", "noise floor", "thermal noise", "-174 dbm/hz", "174",
                          "johnson noise", "nyquist noise", "noise power"],
                status: .planned,
                formula: nil,
                practicalNote: "At room temperature the noise density is about -174 dBm/Hz; everything else in a noise budget is measured against it.",
                commonMistake: nil,
                relatedArticles: [.thermalNoise, .noiseFigure, .receiverSensitivity]
            )

        case .receiverSensitivity:
            return CalculatorDescriptor(
                id: self,
                title: "Receiver Sensitivity",
                purpose: "Smallest signal a receiver can use, from bandwidth, noise figure and required SNR.",
                systemImage: "antenna.radiowaves.left.and.right.slash",
                category: .signalsAndPower,
                aliases: ["sensitivity", "mds", "minimum detectable signal", "snr", "demodulation threshold"],
                status: .planned,
                formula: nil,
                practicalNote: "Sensitivity is only meaningful alongside the bandwidth and the SNR the demodulator actually needs.",
                commonMistake: nil,
                relatedArticles: [.receiverSensitivity, .thermalNoise, .noiseFigure]
            )

        case .reflectionConverter:
            return CalculatorDescriptor(
                id: self,
                title: "Reflection Converter",
                purpose: "Enter VSWR, return loss, |Γ|, reflected power or mismatch loss and get the rest.",
                systemImage: "arrow.uturn.backward",
                category: .reflectionAndLines,
                aliases: ["vswr", "swr", "return loss", "rl", "s11", "reflection", "gamma", "rho",
                          "mismatch loss", "reflected power", "vswr to return loss"],
                status: .available,
                formula: Formula(
                    expression: "|Γ| = (VSWR − 1) / (VSWR + 1)\nRL = −20·log₁₀|Γ|\nML = −10·log₁₀(1 − |Γ|²)",
                    variables: [
                        VariableDefinition(symbol: "Γ", meaning: "Reflection coefficient magnitude"),
                        VariableDefinition(symbol: "VSWR", meaning: "Voltage standing wave ratio"),
                        VariableDefinition(symbol: "RL", meaning: "Return loss, dB"),
                        VariableDefinition(symbol: "ML", meaning: "Mismatch loss, dB")
                    ],
                    spokenDescription: "The reflection coefficient magnitude equals VSWR minus one, divided by VSWR plus one. Return loss in decibels equals minus twenty times the log of gamma. Mismatch loss equals minus ten times the log of one minus gamma squared."
                ),
                practicalNote: "Mismatch loss is usually the number that matters: VSWR 2:1 sounds alarming but costs only 0.5 dB of delivered power. A perfect match has infinite return loss, shown here as a dash.",
                commonMistake: "Return loss is positive by convention while S11 in dB is negative — an S11 of -20 dB is 20 dB of return loss, not -20 dB.",
                relatedArticles: [.vswr, .returnLoss, .reflectionCoefficient, .mismatchLoss]
            )

        case .cascadedGainNoiseFigure:
            return CalculatorDescriptor(
                id: self,
                title: "Cascaded Gain & Noise Figure",
                purpose: "Total gain and noise figure of a chain of stages, stage by stage.",
                systemImage: "rectangle.stack",
                category: .rfSystems,
                aliases: ["friis", "cascade", "noise figure", "nf", "lineup", "chain", "cascaded"],
                status: .planned,
                formula: nil,
                practicalNote: "The first stage dominates the noise figure of a chain, which is why the low-noise amplifier goes at the front.",
                commonMistake: nil,
                relatedArticles: [.noiseFigure, .cascadedGain, .noiseTemperature]
            )

        case .eirp:
            return CalculatorDescriptor(
                id: self,
                title: "EIRP / ERP",
                purpose: "Radiated power from transmitter power, feed losses and antenna gain.",
                systemImage: "antenna.radiowaves.left.and.right",
                category: .signalsAndPower,
                aliases: ["eirp", "erp", "dbi", "dbd", "radiated power", "effective radiated power"],
                status: .planned,
                formula: nil,
                practicalNote: "EIRP is what regulators and link budgets care about, and it is where feedline loss quietly eats transmitter power.",
                commonMistake: nil,
                relatedArticles: [.eirpAndErp, .antennaGain, .cableAndConnectorLoss]
            )

        case .effectiveAperture:
            return CalculatorDescriptor(
                id: self,
                title: "Effective Antenna Aperture",
                purpose: "Capture area of an antenna at a given frequency and gain.",
                systemImage: "circle.dashed",
                category: .antennas,
                aliases: ["aperture", "effective area", "capture area", "ae", "antenna area"],
                status: .planned,
                formula: nil,
                practicalNote: "Aperture is how much signal an antenna intercepts, and it shrinks with frequency for a fixed gain.",
                commonMistake: nil,
                relatedArticles: [.effectiveAperture, .antennaGain]
            )

        case .farFieldDistance:
            return CalculatorDescriptor(
                id: self,
                title: "Far-Field Distance",
                purpose: "Where the reactive, radiating and far-field regions of an antenna begin.",
                systemImage: "scope",
                category: .antennas,
                aliases: ["far field", "near field", "fraunhofer", "rayleigh", "2d2/lambda", "measurement distance"],
                status: .planned,
                formula: nil,
                practicalNote: "Gain patterns only mean what the datasheet says once you are measuring in the far field.",
                commonMistake: nil,
                relatedArticles: [.nearAndFarField, .antennaGain, .effectiveAperture]
            )
        }
    }
}

/// Access to the catalogue as a whole.
enum CalculatorCatalog {
    /// Every calculator, in declaration order.
    static let all: [CalculatorDescriptor] = CalculatorID.allCases.map(\.descriptor)

    static func inCategory(_ category: RFCategory) -> [CalculatorDescriptor] {
        all.filter { $0.category == category }
    }

    static var alphabetical: [CalculatorDescriptor] {
        all.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    static var available: [CalculatorDescriptor] {
        all.filter(\.isAvailable)
    }

    /// Shown on the Home screen (spec §8).
    static let quickCalculations: [CalculatorID] = [
        .powerConverter,
        .wavelength,
        .reflectionConverter,
        .freeSpacePathLoss
    ]
}
