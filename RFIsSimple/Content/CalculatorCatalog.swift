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
                aliases: ["rms", "vrms", "volts", "voltage", "impedance", "50 ohm", "75 ohm",
                          "dbmv", "dbuv", "peak to peak", "vpp"],
                status: .available,
                formula: Formula(
                    expression: "P = V² / Z\nV = √(P · Z)\nV_pp = 2·√2 · V_rms",
                    variables: [
                        VariableDefinition(symbol: "P", meaning: "Power, W"),
                        VariableDefinition(symbol: "V", meaning: "RMS voltage across Z"),
                        VariableDefinition(symbol: "Z", meaning: "System impedance, Ω"),
                        VariableDefinition(symbol: "V_pp", meaning: "Peak-to-peak, sine wave only")
                    ],
                    spokenDescription: "Power equals voltage squared divided by impedance. Voltage equals the square root of power times impedance. Peak to peak is two root two times the RMS value for a sine wave."
                ),
                practicalNote: "In 50 Ω, 0 dBm is 223 mV RMS or 632 mV peak-to-peak — worth memorising for scope work. The peak figures assume a sine wave; a modulated signal has a higher crest factor.",
                commonMistake: "Comparing a level measured in 50 Ω with one taken through a high-impedance probe.",
                relatedArticles: [.voltagePowerImpedance, .impedanceBasics, .decibels]
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
                aliases: ["fspl", "friis", "path loss", "free space loss", "spreading loss", "32.45"],
                status: .available,
                formula: Formula(
                    expression: "FSPL(dB) = 20·log₁₀( 4·π·d / λ )\n= 20·log₁₀(d_km) + 20·log₁₀(f_MHz) + 32.45",
                    variables: [
                        VariableDefinition(symbol: "d", meaning: "Distance between antennas"),
                        VariableDefinition(symbol: "λ", meaning: "Wavelength at the carrier"),
                        VariableDefinition(symbol: "f", meaning: "Frequency")
                    ],
                    spokenDescription: "Free space path loss in decibels equals twenty times the log of four pi times the distance divided by the wavelength."
                ),
                practicalNote: "Doubling either the distance or the frequency costs 6 dB. This is the floor, not the answer: obstruction, rain and multipath all add on top of it.",
                commonMistake: "Reading the frequency term as absorption by air — it comes from the receiving antenna's aperture shrinking, not from anything in the path.",
                relatedArticles: [.freeSpacePathLoss, .linkBudget, .fresnelZone, .effectiveAperture]
            )

        case .linkBudget:
            return CalculatorDescriptor(
                id: self,
                title: "Link Budget",
                purpose: "Add up gains and losses along a path to find received power and margin.",
                systemImage: "list.bullet.rectangle",
                category: .propagation,
                aliases: ["link margin", "received power", "rx power", "budget", "fade margin"],
                status: .available,
                formula: Formula(
                    expression: "P_rx = P_tx − L_tx + G_tx − L_path + G_rx − L_rx\nMargin = P_rx − Sensitivity",
                    variables: [
                        VariableDefinition(symbol: "P_tx", meaning: "Transmit power, dBm"),
                        VariableDefinition(symbol: "L", meaning: "Feed and path losses, dB"),
                        VariableDefinition(symbol: "G", meaning: "Antenna gains, dBi"),
                        VariableDefinition(symbol: "P_rx", meaning: "Power at the receiver, dBm")
                    ],
                    spokenDescription: "Received power equals transmit power minus transmit losses plus transmit antenna gain minus path loss plus receive antenna gain minus receive losses. Margin is received power minus sensitivity."
                ),
                practicalNote: "The margin is the point of the exercise: a link that closes with nothing spare will not stay up. Fixed links usually carry 10 to 20 dB for weather, ageing and pointing error.",
                commonMistake: "Leaving out the feedline loss at one end, which is often several dB by itself.",
                relatedArticles: [.linkBudget, .freeSpacePathLoss, .receiverSensitivity, .eirpAndErp]
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
                status: .available,
                formula: Formula(
                    expression: "N = k·T·B\nN(dBm) = −174 + 10·log₁₀(B)   at 290 K\nFloor = N(dBm) + NF",
                    variables: [
                        VariableDefinition(symbol: "k", meaning: "Boltzmann constant, 1.380649e−23 J/K"),
                        VariableDefinition(symbol: "T", meaning: "Temperature, K"),
                        VariableDefinition(symbol: "B", meaning: "Equivalent noise bandwidth, Hz"),
                        VariableDefinition(symbol: "NF", meaning: "Receiver noise figure, dB")
                    ],
                    spokenDescription: "Noise power equals Boltzmann's constant times temperature times bandwidth. At 290 kelvin the density is minus one hundred and seventy four dBm per hertz."
                ),
                practicalNote: "Widening the bandwidth by ten times costs 10 dB of noise floor. The temperature is the system noise temperature at the reference point, which is 290 K by convention rather than by measurement.",
                commonMistake: "Use noise bandwidth, which may not be identical to channel bandwidth or analyser RBW.",
                relatedArticles: [.thermalNoise, .noiseFigure, .receiverSensitivity, .displayedAverageNoiseLevel]
            )

        case .receiverSensitivity:
            return CalculatorDescriptor(
                id: self,
                title: "Receiver Sensitivity",
                purpose: "Smallest signal a receiver can use, from bandwidth, noise figure and required SNR.",
                systemImage: "antenna.radiowaves.left.and.right.slash",
                category: .signalsAndPower,
                aliases: ["sensitivity", "mds", "minimum detectable signal", "snr", "demodulation threshold"],
                status: .available,
                formula: Formula(
                    expression: "S(dBm) = −174 + 10·log₁₀(B) + NF + SNR",
                    variables: [
                        VariableDefinition(symbol: "B", meaning: "Noise bandwidth, Hz"),
                        VariableDefinition(symbol: "NF", meaning: "Receiver noise figure, dB"),
                        VariableDefinition(symbol: "SNR", meaning: "Signal-to-noise the demodulator needs, dB")
                    ],
                    spokenDescription: "Sensitivity in dBm equals minus one hundred and seventy four, plus ten log of the bandwidth, plus noise figure, plus the required signal to noise ratio."
                ),
                practicalNote: "Halving the bandwidth buys 3 dB, and so does removing 3 dB of noise figure. The required SNR comes from the modulation and coding, not from the radio hardware.",
                commonMistake: "Comparing two datasheet sensitivities measured at different bandwidths or error-rate criteria.",
                relatedArticles: [.receiverSensitivity, .thermalNoise, .noiseFigure, .linkBudget]
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
                purpose: "Total gain and noise figure of a chain of stages, with each stage's contribution.",
                systemImage: "rectangle.stack",
                category: .rfSystems,
                aliases: ["friis", "cascade", "noise figure", "nf", "lineup", "chain", "cascaded", "lna"],
                status: .available,
                formula: Formula(
                    expression: "G_total = Σ Gₙ(dB)\nF = F₁ + (F₂−1)/G₁ + (F₃−1)/(G₁·G₂) + …\nNF = 10·log₁₀(F)",
                    variables: [
                        VariableDefinition(symbol: "Gₙ", meaning: "Stage gain, dB — negative for a loss"),
                        VariableDefinition(symbol: "F", meaning: "Noise factor, linear — not dB"),
                        VariableDefinition(symbol: "NF", meaning: "Noise figure, dB")
                    ],
                    spokenDescription: "Total gain is the sum of the stage gains in decibels. Total noise factor equals the first stage noise factor, plus each later stage's noise factor minus one, divided by the gain ahead of it."
                ),
                practicalNote: "The first stage dominates: put the low-noise amplifier at the front and its gain suppresses everything behind it. The contribution list shows exactly how much each stage is costing you.",
                commonMistake: "Adding noise figures in decibels — the cascade only works in linear noise factor, which is why stage order changes the answer.",
                relatedArticles: [.noiseFigure, .cascadedGain, .noiseTemperature, .thermalNoise]
            )

        case .eirp:
            return CalculatorDescriptor(
                id: self,
                title: "EIRP / ERP",
                purpose: "Radiated power from transmitter power, feed losses and antenna gain.",
                systemImage: "antenna.radiowaves.left.and.right",
                category: .signalsAndPower,
                aliases: ["eirp", "erp", "dbi", "dbd", "radiated power", "effective radiated power"],
                status: .available,
                formula: Formula(
                    expression: "EIRP = P_tx − L_feed + G(dBi)\nERP = EIRP − 2.15 dB\nG(dBi) = G(dBd) + 2.15",
                    variables: [
                        VariableDefinition(symbol: "P_tx", meaning: "Transmitter output, dBm"),
                        VariableDefinition(symbol: "L_feed", meaning: "Feedline and connector loss, dB"),
                        VariableDefinition(symbol: "G", meaning: "Antenna gain, dBi or dBd")
                    ],
                    spokenDescription: "EIRP equals transmitter power minus feed loss plus antenna gain in dBi. ERP is EIRP minus two point one five decibels."
                ),
                practicalNote: "EIRP is what regulatory limits are written against, and where feedline loss quietly eats transmitter power. Switch the gain reference rather than converting by hand.",
                commonMistake: "Mixing dBi and dBd in one calculation, which shifts the answer by 2.15 dB.",
                relatedArticles: [.eirpAndErp, .antennaGain, .cableAndConnectorLoss, .linkBudget]
            )

        case .effectiveAperture:
            return CalculatorDescriptor(
                id: self,
                title: "Effective Antenna Aperture",
                purpose: "Capture area of an antenna at a given frequency and gain.",
                systemImage: "circle.dashed",
                category: .antennas,
                aliases: ["aperture", "effective area", "capture area", "ae", "antenna area"],
                status: .available,
                formula: Formula(
                    expression: "A_e = G · λ² / (4π)",
                    variables: [
                        VariableDefinition(symbol: "A_e", meaning: "Effective aperture, m²"),
                        VariableDefinition(symbol: "G", meaning: "Gain as a linear ratio, from dBi"),
                        VariableDefinition(symbol: "λ", meaning: "Wavelength, m")
                    ],
                    spokenDescription: "Effective aperture equals gain times wavelength squared, divided by four pi."
                ),
                practicalNote: "Aperture is how much signal an antenna intercepts, and it shrinks with frequency for a fixed gain — which is exactly why free-space path loss rises with frequency. Compare the equivalent circle diameter against the real antenna as a sanity check.",
                commonMistake: "Treating aperture as physical size, which it only approaches for large dishes.",
                relatedArticles: [.effectiveAperture, .antennaGain, .freeSpacePathLoss]
            )

        case .farFieldDistance:
            return CalculatorDescriptor(
                id: self,
                title: "Far-Field Distance",
                purpose: "Where the reactive, radiating and far-field regions of an antenna begin.",
                systemImage: "scope",
                category: .antennas,
                aliases: ["far field", "near field", "fraunhofer", "rayleigh", "2d2/lambda", "measurement distance"],
                status: .available,
                formula: Formula(
                    expression: "R_reactive = 0.62·√(D³/λ)\nR_far = 2·D² / λ",
                    variables: [
                        VariableDefinition(symbol: "D", meaning: "Largest antenna dimension, m"),
                        VariableDefinition(symbol: "λ", meaning: "Wavelength, m"),
                        VariableDefinition(symbol: "R", meaning: "Distance from the antenna, m")
                    ],
                    spokenDescription: "The reactive near field ends at zero point six two times the square root of D cubed over lambda. The far field begins at twice D squared over lambda."
                ),
                practicalNote: "Gain and pattern figures only mean what the datasheet says when measured in the far field. Antenna geometry and the criterion chosen both move the practical boundary, so the conservative distance shown here is the one to measure at.",
                commonMistake: "Applying 2D²/λ to an antenna smaller than a wavelength, where it gives a distance far too short.",
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
