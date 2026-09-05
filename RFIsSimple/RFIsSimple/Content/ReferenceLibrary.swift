import Foundation

/// The reference library.
///
/// Content follows the page template in spec §7: a definition, the key
/// relationship, at most three practical points, one mistake worth avoiding,
/// and links onward. Target length is 80–180 words, which the content tests
/// check.
///
/// Written as an exhaustive `switch` so the compiler guarantees every article
/// exists and every cross-link points at something real.
extension ReferenceArticleID {
    var article: ReferenceArticle {
        switch self {

        // MARK: - Fundamentals

        case .decibels:
            return ReferenceArticle(
                id: self,
                title: "Decibels",
                descriptor: "Ratios on a logarithmic scale",
                category: .fundamentals,
                definition: "A decibel expresses the ratio between two powers on a logarithmic scale. It carries no unit of its own — it only says how much larger or smaller one quantity is than another.",
                keyRelationship: Formula(
                    expression: "G(dB) = 10·log₁₀(P₂ / P₁)\nG(dB) = 20·log₁₀(V₂ / V₁)",
                    variables: [
                        VariableDefinition(symbol: "P", meaning: "Power at each point"),
                        VariableDefinition(symbol: "V", meaning: "Voltage, at equal impedance")
                    ],
                    spokenDescription: "Gain in decibels equals ten times the log of the power ratio, or twenty times the log of the voltage ratio."
                ),
                inPractice: [
                    "3 dB is a factor of two in power, 10 dB a factor of ten, 20 dB a factor of one hundred.",
                    "Gains and losses along a chain add in decibels instead of multiplying.",
                    "The 20·log form is for voltage, and only when the impedance is the same at both points."
                ],
                commonMistake: "Using 20·log₁₀ for a power ratio, which doubles the answer.",
                relatedCalculators: [.powerConverter],
                relatedArticles: [.dbmAndDbw, .gainAndLoss],
                aliases: ["db", "decibel", "log ratio", "ratio", "logarithm"]
            )

        case .dbmAndDbw:
            return ReferenceArticle(
                id: self,
                title: "dBm and dBW",
                descriptor: "Absolute power on a decibel scale",
                category: .fundamentals,
                definition: "dBm and dBW are absolute power levels, written as a ratio to a fixed reference: 1 mW for dBm and 1 W for dBW.",
                keyRelationship: Formula(
                    expression: "P(dBm) = 10·log₁₀(P / 1 mW)\nP(dBm) = P(dBW) + 30",
                    variables: [
                        VariableDefinition(symbol: "P", meaning: "Power, linear"),
                        VariableDefinition(symbol: "dBm", meaning: "Referred to 1 mW"),
                        VariableDefinition(symbol: "dBW", meaning: "Referred to 1 W")
                    ],
                    spokenDescription: "Power in dBm equals ten times the log of the power divided by one milliwatt. dBm is dBW plus thirty."
                ),
                inPractice: [
                    "0 dBm is 1 mW, 30 dBm is 1 W, and −30 dBm is 1 µW.",
                    "Because the reference is fixed, a dBm figure names one power level rather than a ratio.",
                    "A gain in dB added to a level in dBm gives dBm; subtracting two dBm levels gives dB."
                ],
                commonMistake: "Writing dB where dBm is meant — the two are not interchangeable in a link budget.",
                relatedCalculators: [.powerConverter, .eirp],
                relatedArticles: [.decibels, .powerConversion],
                aliases: ["dbm", "dbw", "absolute power", "milliwatt reference", "0 dbm"]
            )

        case .frequencyPeriodWavelength:
            return ReferenceArticle(
                id: self,
                title: "Frequency, Period & Wavelength",
                descriptor: "Three views of the same wave",
                category: .fundamentals,
                definition: "Frequency, period and wavelength describe one wave three ways. Period is the time for a single cycle; wavelength is the distance the wave travels in that time.",
                keyRelationship: Formula(
                    expression: "f = 1 / T\nλ = v / f\nv = VF · c",
                    variables: [
                        VariableDefinition(symbol: "f", meaning: "Frequency, Hz"),
                        VariableDefinition(symbol: "T", meaning: "Period, s"),
                        VariableDefinition(symbol: "λ", meaning: "Wavelength, m"),
                        VariableDefinition(symbol: "VF", meaning: "Velocity factor, 1 in vacuum")
                    ],
                    spokenDescription: "Frequency is one over the period. Wavelength is the propagation velocity divided by the frequency."
                ),
                inPractice: [
                    "In air, a 1 GHz wave is 299.8 mm long — close enough to 30 cm for mental arithmetic.",
                    "Wavelength scales inversely with frequency: double the frequency, halve the wavelength.",
                    "Inside a cable the wave slows down, so the wavelength there is shorter by the velocity factor."
                ],
                commonMistake: "Cutting a length of coax from the free-space wavelength, which comes out too long.",
                relatedCalculators: [.wavelength],
                relatedArticles: [.electricalLength, .spectrumBands],
                aliases: ["lambda", "wavelength", "period", "frequency", "hertz", "hz"]
            )

        case .impedanceBasics:
            return ReferenceArticle(
                id: self,
                title: "Impedance Basics",
                descriptor: "Why RF settles on 50 Ω",
                category: .fundamentals,
                definition: "Impedance is the ratio of voltage to current, with both a magnitude and a phase. In RF work it decides how much of a signal passes and how much comes back.",
                keyRelationship: Formula(
                    expression: "Z = R + jX",
                    variables: [
                        VariableDefinition(symbol: "R", meaning: "Resistance, Ω"),
                        VariableDefinition(symbol: "X", meaning: "Reactance, Ω")
                    ],
                    spokenDescription: "Impedance equals resistance plus j times reactance."
                ),
                inPractice: [
                    "RF systems standardise on 50 Ω; 75 Ω is used for video and broadcast distribution.",
                    "Power transfers fully when the load matches the source — anything else reflects.",
                    "Reactance changes with frequency, so a match only holds over a band."
                ],
                commonMistake: "Reading a 50 Ω label as a promise at every frequency rather than a nominal figure.",
                relatedCalculators: [.voltagePowerImpedance, .reflectionConverter],
                relatedArticles: [.characteristicImpedance, .reflectionCoefficient],
                aliases: ["impedance", "50 ohm", "75 ohm", "ohms", "reactance"]
            )

        case .spectrumBands:
            return ReferenceArticle(
                id: self,
                title: "RF Spectrum Bands",
                descriptor: "Band names and where they sit",
                category: .fundamentals,
                definition: "The radio spectrum is divided into named bands: by decade for the ITU names, and by letter for radar and satellite work.",
                keyRelationship: nil,
                inPractice: [
                    "HF is 3–30 MHz, VHF 30–300 MHz, UHF 0.3–3 GHz, SHF 3–30 GHz and EHF 30–300 GHz.",
                    "Letter bands overlap those: L is about 1–2 GHz, S 2–4, C 4–8, X 8–12 and Ku 12–18 GHz.",
                    "Widely used licence-free points sit near 433 MHz, 868/915 MHz, 2.4 GHz and 5.8 GHz."
                ],
                commonMistake: "Assuming letter-band edges are universal — radar, satellite and test equipment differ slightly.",
                relatedCalculators: [.wavelength],
                relatedArticles: [.frequencyPeriodWavelength],
                aliases: ["bands", "hf", "vhf", "uhf", "shf", "ehf", "x band", "l band", "ku band", "ism"]
            )

        // MARK: - Signals & Power

        case .powerConversion:
            return ReferenceArticle(
                id: self,
                title: "Power Conversion",
                descriptor: "Moving between watts and decibels",
                category: .signalsAndPower,
                definition: "Converting a power level between linear units and decibel units. The linear value says how much energy per second; the decibel value makes chains easy to add up.",
                keyRelationship: Formula(
                    expression: "P(W) = 10^((P(dBm) − 30) / 10)",
                    variables: [
                        VariableDefinition(symbol: "P(W)", meaning: "Power in watts"),
                        VariableDefinition(symbol: "P(dBm)", meaning: "Power referred to 1 mW")
                    ],
                    spokenDescription: "Power in watts equals ten raised to the power of dBm minus thirty, all over ten."
                ),
                inPractice: [
                    "Useful anchors: −30 dBm is 1 µW, 0 dBm is 1 mW, 30 dBm is 1 W, 60 dBm is 1 kW.",
                    "Adding 3 dB doubles the power; adding 10 dB multiplies it by ten.",
                    "Small linear numbers are far easier to read in dBm, which is why receivers are specified that way."
                ],
                commonMistake: "Treating 3 dB as exactly double in a precise budget — the true factor is 1.995.",
                relatedCalculators: [.powerConverter],
                relatedArticles: [.dbmAndDbw, .decibels],
                aliases: ["convert power", "watts to dbm", "dbm to mw", "power converter", "milliwatts"]
            )

        case .voltagePowerImpedance:
            return ReferenceArticle(
                id: self,
                title: "Voltage, Power & Impedance",
                descriptor: "RMS volts and watts in a matched system",
                category: .signalsAndPower,
                definition: "In a system of known impedance, RMS voltage and power carry the same information, so either can stand in for the other.",
                keyRelationship: Formula(
                    expression: "P = V² / Z\nV = √(P · Z)",
                    variables: [
                        VariableDefinition(symbol: "P", meaning: "Power, W"),
                        VariableDefinition(symbol: "V", meaning: "RMS voltage"),
                        VariableDefinition(symbol: "Z", meaning: "Impedance, Ω")
                    ],
                    spokenDescription: "Power equals voltage squared divided by impedance. Voltage equals the square root of power times impedance."
                ),
                inPractice: [
                    "In 50 Ω, 0 dBm is 223 mV RMS, which is 632 mV peak-to-peak on a scope.",
                    "Doubling the voltage raises the power by 6 dB, not 3 dB.",
                    "A voltage figure means nothing without the impedance it refers to."
                ],
                commonMistake: "Comparing a level measured in 50 Ω with one taken through a high-impedance probe.",
                relatedCalculators: [.voltagePowerImpedance],
                relatedArticles: [.impedanceBasics, .decibels],
                aliases: ["rms", "vrms", "volts", "voltage", "dbmv", "dbuv", "peak to peak"]
            )

        case .gainAndLoss:
            return ReferenceArticle(
                id: self,
                title: "Gain and Loss",
                descriptor: "The same ratio, both directions",
                category: .signalsAndPower,
                definition: "Gain is the ratio of output power to input power; loss is that ratio inverted. Both are quoted in decibels, and a loss is simply a negative gain.",
                keyRelationship: Formula(
                    expression: "G(dB) = P_out(dBm) − P_in(dBm)",
                    variables: [
                        VariableDefinition(symbol: "G", meaning: "Gain, dB"),
                        VariableDefinition(symbol: "P", meaning: "Level at each point, dBm")
                    ],
                    spokenDescription: "Gain in decibels equals output level in dBm minus input level in dBm."
                ),
                inPractice: [
                    "Along a chain, gains and losses add: +20 dB of amplifier after 3 dB of cable nets +17 dB.",
                    "Insertion loss is what a passive part costs, and is quoted as a positive number.",
                    "Read whether a datasheet figure is a gain or a loss before adding it to anything."
                ],
                commonMistake: "Entering an attenuator's loss as a positive gain, which moves the budget the wrong way.",
                relatedCalculators: [.linkBudget, .cascadedGainNoiseFigure],
                relatedArticles: [.decibels, .cascadedGain],
                aliases: ["gain", "loss", "attenuation", "insertion loss", "amplifier"]
            )

        case .eirpAndErp:
            return ReferenceArticle(
                id: self,
                title: "EIRP and ERP",
                descriptor: "What the antenna actually radiates",
                category: .signalsAndPower,
                definition: "EIRP is the power an isotropic radiator would need to match your transmitter and antenna in its strongest direction. ERP is the same idea referred to a half-wave dipole.",
                keyRelationship: Formula(
                    expression: "EIRP = P_tx − L_feed + G(dBi)\nERP = EIRP − 2.15 dB",
                    variables: [
                        VariableDefinition(symbol: "P_tx", meaning: "Transmitter output, dBm"),
                        VariableDefinition(symbol: "L_feed", meaning: "Feedline and connector loss, dB"),
                        VariableDefinition(symbol: "G", meaning: "Antenna gain, dBi")
                    ],
                    spokenDescription: "EIRP equals transmitter power minus feed loss plus antenna gain in dBi. ERP is EIRP minus two point one five decibels."
                ),
                inPractice: [
                    "Regulatory limits are almost always written against EIRP, not transmitter power.",
                    "Feedline and connector loss comes off before antenna gain is added.",
                    "A gain quoted in dBd is 2.15 dB smaller than the same gain in dBi."
                ],
                commonMistake: "Mixing dBi and dBd in one calculation, which shifts the result by 2.15 dB.",
                relatedCalculators: [.eirp],
                relatedArticles: [.antennaGain, .cableAndConnectorLoss],
                aliases: ["eirp", "erp", "dbi", "dbd", "radiated power", "regulatory limit"]
            )

        case .thermalNoise:
            return ReferenceArticle(
                id: self,
                title: "Thermal Noise",
                descriptor: "The floor every receiver starts from",
                category: .signalsAndPower,
                definition: "Thermal motion of charge carriers generates noise in every resistor and every receiver input. Its power depends on temperature and bandwidth, not on the resistance.",
                keyRelationship: Formula(
                    expression: "N = k·T·B\nN(dBm) = −174 + 10·log₁₀(B)",
                    variables: [
                        VariableDefinition(symbol: "k", meaning: "Boltzmann constant, 1.380649e−23 J/K"),
                        VariableDefinition(symbol: "T", meaning: "Temperature, K"),
                        VariableDefinition(symbol: "B", meaning: "Noise bandwidth, Hz")
                    ],
                    spokenDescription: "Noise power equals Boltzmann's constant times temperature times bandwidth. In dBm it is minus one hundred and seventy four plus ten log of the bandwidth."
                ),
                inPractice: [
                    "At 290 K the noise density is −174 dBm/Hz, the figure every noise budget starts from.",
                    "A 1 MHz bandwidth therefore holds −114 dBm of thermal noise before the receiver adds any.",
                    "Widening the bandwidth tenfold costs 10 dB of noise floor."
                ],
                commonMistake: "Using channel bandwidth or analyser RBW where equivalent noise bandwidth is meant.",
                relatedCalculators: [.thermalNoise, .receiverSensitivity],
                relatedArticles: [.noiseFigure, .receiverSensitivity, .displayedAverageNoiseLevel],
                aliases: ["ktb", "noise floor", "thermal noise", "-174 dbm/hz", "174", "johnson noise", "nyquist noise"]
            )

        case .receiverSensitivity:
            return ReferenceArticle(
                id: self,
                title: "Receiver Sensitivity",
                descriptor: "The smallest usable signal",
                category: .signalsAndPower,
                definition: "Sensitivity is the weakest signal a receiver can still work with: its own noise floor plus whatever signal-to-noise ratio the demodulator needs.",
                keyRelationship: Formula(
                    expression: "S(dBm) = −174 + 10·log₁₀(B) + NF + SNR",
                    variables: [
                        VariableDefinition(symbol: "B", meaning: "Noise bandwidth, Hz"),
                        VariableDefinition(symbol: "NF", meaning: "Receiver noise figure, dB"),
                        VariableDefinition(symbol: "SNR", meaning: "Required signal-to-noise ratio, dB")
                    ],
                    spokenDescription: "Sensitivity in dBm equals minus one hundred and seventy four, plus ten log of the bandwidth, plus noise figure, plus the required signal to noise ratio."
                ),
                inPractice: [
                    "Every term counts: halving the bandwidth buys 3 dB, and so does removing 3 dB of noise figure.",
                    "The required SNR comes from the modulation and coding, not from the radio hardware.",
                    "Quoted sensitivities only compare fairly at the same bandwidth and error-rate criterion."
                ],
                commonMistake: "Comparing two datasheet sensitivities measured at different bandwidths.",
                relatedCalculators: [.receiverSensitivity, .thermalNoise],
                relatedArticles: [.thermalNoise, .noiseFigure, .linkBudget],
                aliases: ["sensitivity", "mds", "minimum detectable signal", "snr", "threshold"]
            )

        // MARK: - Reflection & Transmission Lines

        case .reflectionCoefficient:
            return ReferenceArticle(
                id: self,
                title: "Reflection Coefficient",
                descriptor: "How much of the wave comes back",
                category: .reflectionAndLines,
                definition: "Γ is the ratio of the reflected wave to the incident wave at a boundary. Its magnitude runs from 0 for a perfect match to 1 for total reflection.",
                keyRelationship: Formula(
                    expression: "Γ = (Z_L − Z₀) / (Z_L + Z₀)",
                    variables: [
                        VariableDefinition(symbol: "Z_L", meaning: "Load impedance, Ω"),
                        VariableDefinition(symbol: "Z₀", meaning: "Line impedance, Ω")
                    ],
                    spokenDescription: "Gamma equals load impedance minus line impedance, divided by their sum."
                ),
                inPractice: [
                    "|Γ| = 0.1 means a tenth of the voltage returns, which is one percent of the power.",
                    "Γ is complex: its phase says where along the line the mismatch sits.",
                    "S11 is the reflection coefficient at a port, so the terms are used interchangeably."
                ],
                commonMistake: "Reading |Γ| as a power ratio — reflected power is |Γ|², not |Γ|.",
                relatedCalculators: [.reflectionConverter],
                relatedArticles: [.vswr, .returnLoss, .sParameters],
                aliases: ["gamma", "s11", "rho", "reflection", "reflection coefficient"]
            )

        case .returnLoss:
            return ReferenceArticle(
                id: self,
                title: "Return Loss",
                descriptor: "Reflection expressed in decibels",
                category: .reflectionAndLines,
                definition: "Return loss says how much weaker the reflected wave is than the incident one, in decibels. Larger is better.",
                keyRelationship: Formula(
                    expression: "RL = −20·log₁₀|Γ|   (dB)",
                    variables: [
                        VariableDefinition(symbol: "RL", meaning: "Return loss, dB, positive"),
                        VariableDefinition(symbol: "Γ", meaning: "Reflection coefficient magnitude")
                    ],
                    spokenDescription: "Return loss in decibels equals minus twenty times the log of the magnitude of gamma."
                ),
                inPractice: [
                    "10 dB of return loss sends back 10% of the power; 20 dB sends back 1%.",
                    "A perfect match has infinite return loss; total reflection gives 0 dB.",
                    "It holds the same information as VSWR, on a scale that reads more clearly near a good match."
                ],
                commonMistake: "Quoting return loss as a negative number — that figure is S11, not return loss.",
                relatedCalculators: [.reflectionConverter],
                relatedArticles: [.vswr, .reflectionCoefficient, .mismatchLoss],
                aliases: ["return loss", "rl", "s11 db", "reflection"]
            )

        case .vswr:
            return ReferenceArticle(
                id: self,
                title: "VSWR",
                descriptor: "Standing wave ratio on a mismatched line",
                category: .reflectionAndLines,
                definition: "The voltage standing wave ratio is the ratio of maximum to minimum voltage along a mismatched line. It starts at 1:1 for a perfect match and rises from there.",
                keyRelationship: Formula(
                    expression: "VSWR = (1 + |Γ|) / (1 − |Γ|)",
                    variables: [
                        VariableDefinition(symbol: "VSWR", meaning: "Voltage standing wave ratio"),
                        VariableDefinition(symbol: "Γ", meaning: "Reflection coefficient magnitude")
                    ],
                    spokenDescription: "VSWR equals one plus the magnitude of gamma, divided by one minus the magnitude of gamma."
                ),
                inPractice: [
                    "VSWR 1.5:1 reflects 4% of the power; VSWR 2:1 reflects 11%.",
                    "VSWR says how large a mismatch is, never where along the line it is.",
                    "Transmitters often fold back output power above a stated VSWR to protect the final stage."
                ],
                commonMistake: "Reading a high VSWR as heavy loss — at 2:1 only about 0.5 dB is actually lost.",
                relatedCalculators: [.reflectionConverter],
                relatedArticles: [.returnLoss, .mismatchLoss, .reflectionCoefficient],
                aliases: ["vswr", "swr", "standing wave ratio", "voltage standing wave ratio"]
            )

        case .mismatchLoss:
            return ReferenceArticle(
                id: self,
                title: "Mismatch Loss",
                descriptor: "Power that never reaches the load",
                category: .reflectionAndLines,
                definition: "Mismatch loss is the share of incident power that never reaches the load because it is reflected back toward the source.",
                keyRelationship: Formula(
                    expression: "ML = −10·log₁₀(1 − |Γ|²)   (dB)",
                    variables: [
                        VariableDefinition(symbol: "ML", meaning: "Mismatch loss, dB"),
                        VariableDefinition(symbol: "Γ", meaning: "Reflection coefficient magnitude")
                    ],
                    spokenDescription: "Mismatch loss equals minus ten times the log of one minus gamma squared."
                ),
                inPractice: [
                    "VSWR 2:1 costs 0.51 dB; VSWR 1.5:1 costs 0.18 dB.",
                    "It stays small until the match is quite poor, so chasing a perfect VSWR rarely pays.",
                    "The reflected power still goes somewhere — usually back into the amplifier."
                ],
                commonMistake: "Counting mismatch loss twice by adding it to a measured insertion loss that already includes it.",
                relatedCalculators: [.reflectionConverter],
                relatedArticles: [.vswr, .returnLoss],
                aliases: ["mismatch loss", "ml", "reflected power loss"]
            )

        case .characteristicImpedance:
            return ReferenceArticle(
                id: self,
                title: "Characteristic Impedance",
                descriptor: "What a line looks like to a travelling wave",
                category: .reflectionAndLines,
                definition: "The impedance a transmission line presents to a wave travelling along it, set by the line's geometry and dielectric rather than by its length.",
                keyRelationship: Formula(
                    expression: "Z₀ = √(L / C)",
                    variables: [
                        VariableDefinition(symbol: "L", meaning: "Inductance per unit length"),
                        VariableDefinition(symbol: "C", meaning: "Capacitance per unit length")
                    ],
                    spokenDescription: "Characteristic impedance equals the square root of inductance per unit length divided by capacitance per unit length."
                ),
                inPractice: [
                    "A line terminated in its own Z₀ shows no reflection, whatever its length.",
                    "50 Ω is a compromise between lowest loss and highest power handling for coax.",
                    "Sharp bends, crushed cable and poor connectors shift Z₀ locally and show up as reflections."
                ],
                commonMistake: "Assuming a cable is 50 Ω because of its connector — 75 Ω cable with BNC connectors is common.",
                relatedCalculators: [.reflectionConverter],
                relatedArticles: [.impedanceBasics, .electricalLength, .reflectionCoefficient],
                aliases: ["z0", "characteristic impedance", "transmission line", "coax", "microstrip"]
            )

        case .electricalLength:
            return ReferenceArticle(
                id: self,
                title: "Electrical Length",
                descriptor: "Length measured in wavelengths",
                category: .reflectionAndLines,
                definition: "The length of a line expressed in wavelengths or degrees at the frequency of interest, rather than in metres.",
                keyRelationship: Formula(
                    expression: "λ_line = VF · c / f\nθ = 360° · (l / λ_line)",
                    variables: [
                        VariableDefinition(symbol: "VF", meaning: "Velocity factor of the line"),
                        VariableDefinition(symbol: "l", meaning: "Physical length, m"),
                        VariableDefinition(symbol: "θ", meaning: "Electrical length, degrees")
                    ],
                    spokenDescription: "The wavelength in a line equals its velocity factor times the speed of light over frequency. Electrical length in degrees is three hundred and sixty times the physical length divided by that wavelength."
                ),
                inPractice: [
                    "A quarter-wave line inverts impedance, which is what makes matching sections work.",
                    "Velocity factor is around 0.66 for solid polyethylene coax and 0.8–0.88 for foam types.",
                    "The same cable is a different electrical length at every frequency."
                ],
                commonMistake: "Cutting a stub to the free-space quarter wavelength and forgetting the velocity factor.",
                relatedCalculators: [.wavelength],
                relatedArticles: [.frequencyPeriodWavelength, .characteristicImpedance],
                aliases: ["electrical length", "velocity factor", "vf", "degrees", "phase length", "stub"]
            )

        // MARK: - Antennas

        case .antennaGain:
            return ReferenceArticle(
                id: self,
                title: "Antenna Gain and Directivity",
                descriptor: "Concentration, not amplification",
                category: .antennas,
                definition: "Directivity describes how tightly an antenna concentrates radiation in one direction; gain is that directivity reduced by the antenna's own losses.",
                keyRelationship: Formula(
                    expression: "G = η · D\nG(dBi) = G(dBd) + 2.15",
                    variables: [
                        VariableDefinition(symbol: "D", meaning: "Directivity"),
                        VariableDefinition(symbol: "η", meaning: "Radiation efficiency"),
                        VariableDefinition(symbol: "dBi", meaning: "Referred to an isotropic radiator")
                    ],
                    spokenDescription: "Gain equals efficiency times directivity. Gain in dBi is gain in dBd plus two point one five."
                ),
                inPractice: [
                    "An antenna has no gain in the amplifier sense — it only redistributes the power it is given.",
                    "dBi is referred to an isotropic radiator, dBd to a half-wave dipole.",
                    "More gain means a narrower beam, so alignment and mechanical stability matter more."
                ],
                commonMistake: "Comparing a dBi figure with a dBd figure without applying the 2.15 dB offset.",
                relatedCalculators: [.eirp, .effectiveAperture],
                relatedArticles: [.radiationEfficiency, .effectiveAperture, .eirpAndErp],
                aliases: ["gain", "directivity", "dbi", "dbd", "antenna gain", "isotropic", "beamwidth"]
            )

        case .radiationEfficiency:
            return ReferenceArticle(
                id: self,
                title: "Radiation Efficiency",
                descriptor: "How much power actually leaves",
                category: .antennas,
                definition: "The fraction of the power delivered to an antenna that leaves it as radiation. The rest becomes heat in conductors, matching components and nearby materials.",
                keyRelationship: Formula(
                    expression: "η = P_radiated / P_input",
                    variables: [
                        VariableDefinition(symbol: "η", meaning: "Radiation efficiency, 0 to 1"),
                        VariableDefinition(symbol: "P", meaning: "Power, W")
                    ],
                    spokenDescription: "Radiation efficiency equals radiated power divided by input power."
                ),
                inPractice: [
                    "Small antennas are where this bites: an electrically short antenna can be a few percent efficient.",
                    "In decibels, efficiency is the gap between measured gain and directivity.",
                    "Ground planes, plastic enclosures and a nearby hand all change it."
                ],
                commonMistake: "Reading a good VSWR as good efficiency — a lossy antenna can look perfectly matched.",
                relatedCalculators: [.effectiveAperture],
                relatedArticles: [.antennaGain, .vswr],
                aliases: ["efficiency", "radiation efficiency", "eta", "antenna losses"]
            )

        case .effectiveAperture:
            return ReferenceArticle(
                id: self,
                title: "Effective Aperture",
                descriptor: "The area an antenna captures from",
                category: .antennas,
                definition: "The equivalent capture area of a receiving antenna: multiply the incident power density by it and the result is the power delivered to the receiver.",
                keyRelationship: Formula(
                    expression: "A_e = G·λ² / (4π)",
                    variables: [
                        VariableDefinition(symbol: "A_e", meaning: "Effective aperture, m²"),
                        VariableDefinition(symbol: "G", meaning: "Gain, linear"),
                        VariableDefinition(symbol: "λ", meaning: "Wavelength, m")
                    ],
                    spokenDescription: "Effective aperture equals gain times wavelength squared, divided by four pi."
                ),
                inPractice: [
                    "For a fixed gain, aperture shrinks as frequency rises — 6 dBi captures far less at 5 GHz than at 900 MHz.",
                    "Dish antennas are usually quoted with an aperture efficiency of 50–70%.",
                    "This term is what makes free-space path loss depend on frequency at all."
                ],
                commonMistake: "Treating aperture as physical size, which it only approaches for large dishes.",
                relatedCalculators: [.effectiveAperture, .freeSpacePathLoss],
                relatedArticles: [.antennaGain, .freeSpacePathLoss],
                aliases: ["aperture", "effective area", "capture area", "ae"]
            )

        case .polarisation:
            return ReferenceArticle(
                id: self,
                title: "Polarisation",
                descriptor: "Orientation of the radiated field",
                category: .antennas,
                definition: "Polarisation is the orientation of a wave's electric field: linear, vertical or horizontal, or circular when two perpendicular components sit a quarter cycle apart.",
                keyRelationship: nil,
                inPractice: [
                    "Crossed linear antennas lose 20 dB or more in practice, and infinitely in theory.",
                    "A linear antenna receiving a circular wave loses 3 dB, and the reverse is also true.",
                    "A reflection can flip the sense of a circularly polarised wave."
                ],
                commonMistake: "Blaming poor range on transmit power when the two ends are simply polarised differently.",
                relatedCalculators: [.linkBudget],
                relatedArticles: [.antennaGain, .linkBudget],
                aliases: ["polarisation", "polarization", "circular", "linear", "cross-pol", "rhcp", "lhcp"]
            )

        case .nearAndFarField:
            return ReferenceArticle(
                id: self,
                title: "Near Field and Far Field",
                descriptor: "Where the pattern becomes real",
                category: .antennas,
                definition: "Close to an antenna the fields are reactive and the pattern is still forming. Far enough away the wave is effectively planar and the pattern matches the datasheet.",
                keyRelationship: Formula(
                    expression: "R_far = 2·D² / λ",
                    variables: [
                        VariableDefinition(symbol: "D", meaning: "Largest antenna dimension, m"),
                        VariableDefinition(symbol: "λ", meaning: "Wavelength, m")
                    ],
                    spokenDescription: "The far field begins at twice the largest antenna dimension squared, divided by the wavelength."
                ),
                inPractice: [
                    "2D²/λ applies to electrically large antennas; small ones are usually taken as far field beyond about λ/2π.",
                    "Gain and pattern measurements are only valid in the far field.",
                    "Coupling between two antennas inside the near field is not the same thing as path loss."
                ],
                commonMistake: "Setting a measurement distance once and reusing it across a wide frequency band.",
                relatedCalculators: [.farFieldDistance],
                relatedArticles: [.antennaGain, .effectiveAperture],
                aliases: ["near field", "far field", "fraunhofer", "rayleigh", "2d2/lambda", "reactive near field"]
            )

        // MARK: - Propagation

        case .freeSpacePathLoss:
            return ReferenceArticle(
                id: self,
                title: "Free-Space Path Loss",
                descriptor: "Spreading loss on a clear path",
                category: .propagation,
                definition: "The loss between two isotropic antennas with a clear path and nothing in the way. It comes from the wave spreading out, not from anything absorbing it.",
                keyRelationship: Formula(
                    expression: "FSPL(dB) = 20·log₁₀(d) + 20·log₁₀(f) + 32.45",
                    variables: [
                        VariableDefinition(symbol: "d", meaning: "Distance, km"),
                        VariableDefinition(symbol: "f", meaning: "Frequency, MHz"),
                        VariableDefinition(symbol: "32.45", meaning: "Constant for km and MHz")
                    ],
                    spokenDescription: "Free space path loss in decibels equals twenty log of the distance in kilometres, plus twenty log of the frequency in megahertz, plus thirty two point four five."
                ),
                inPractice: [
                    "Doubling the distance costs 6 dB, and doubling the frequency costs another 6 dB.",
                    "Nothing is absorbed — the energy simply spreads over an ever larger sphere.",
                    "The frequency term comes from the receiving aperture shrinking, not from the air."
                ],
                commonMistake: "Using the 32.45 constant with metres or gigahertz — it is fixed to kilometres and megahertz.",
                relatedCalculators: [.freeSpacePathLoss, .linkBudget],
                relatedArticles: [.linkBudget, .effectiveAperture, .fresnelZone],
                aliases: ["fspl", "friis", "path loss", "free space loss", "spreading loss", "32.45"]
            )

        case .linkBudget:
            return ReferenceArticle(
                id: self,
                title: "Link Budget",
                descriptor: "Adding a path up in decibels",
                category: .propagation,
                definition: "A running total in decibels from transmitter output to receiver input, ending in the margin left over above the receiver's sensitivity.",
                keyRelationship: Formula(
                    expression: "P_rx = P_tx − L_tx + G_tx − L_path + G_rx − L_rx\nMargin = P_rx − Sensitivity",
                    variables: [
                        VariableDefinition(symbol: "P_tx", meaning: "Transmit power, dBm"),
                        VariableDefinition(symbol: "G", meaning: "Antenna gains, dBi"),
                        VariableDefinition(symbol: "L", meaning: "Feed and path losses, dB")
                    ],
                    spokenDescription: "Received power equals transmit power minus transmit losses plus transmit antenna gain minus path loss plus receive antenna gain minus receive losses. Margin is received power minus sensitivity."
                ),
                inPractice: [
                    "The margin is the point of the exercise: a link that closes with nothing spare will not stay up.",
                    "Fixed links usually carry 10–20 dB of margin for weather, ageing and pointing error.",
                    "Every jumper, connector and radome belongs somewhere in the budget."
                ],
                commonMistake: "Leaving out the feedline loss at one end, which is often several dB by itself.",
                relatedCalculators: [.linkBudget, .freeSpacePathLoss],
                relatedArticles: [.freeSpacePathLoss, .receiverSensitivity, .eirpAndErp],
                aliases: ["link budget", "margin", "received power", "rx power", "fade margin"]
            )

        case .fresnelZone:
            return ReferenceArticle(
                id: self,
                title: "Fresnel Zone",
                descriptor: "Clearance a path really needs",
                category: .propagation,
                definition: "The ellipsoid around a radio path that carries most of the energy. Obstructions inside it cost signal even when the line of sight itself is clear.",
                keyRelationship: Formula(
                    expression: "r₁ = 17.32·√(d / (4·f))",
                    variables: [
                        VariableDefinition(symbol: "r₁", meaning: "First zone radius at mid-path, m"),
                        VariableDefinition(symbol: "d", meaning: "Path length, km"),
                        VariableDefinition(symbol: "f", meaning: "Frequency, GHz")
                    ],
                    spokenDescription: "The first Fresnel zone radius in metres equals seventeen point three two times the square root of the path length in kilometres divided by four times the frequency in gigahertz."
                ),
                inPractice: [
                    "Keeping 60% of the first zone clear is the usual planning rule.",
                    "The zone is widest halfway along the path, which is exactly where trees and rooftops sit.",
                    "Lower frequencies have fatter zones and need more clearance."
                ],
                commonMistake: "Treating an unobstructed line of sight as sufficient clearance.",
                relatedCalculators: [.freeSpacePathLoss],
                relatedArticles: [.freeSpacePathLoss, .linkBudget],
                aliases: ["fresnel", "fresnel zone", "clearance", "obstruction", "line of sight"]
            )

        case .dopplerShift:
            return ReferenceArticle(
                id: self,
                title: "Doppler Shift",
                descriptor: "Frequency change from motion",
                category: .propagation,
                definition: "The shift in received frequency caused by relative motion between transmitter and receiver.",
                keyRelationship: Formula(
                    expression: "Δf = f · v / c",
                    variables: [
                        VariableDefinition(symbol: "Δf", meaning: "Frequency shift, Hz"),
                        VariableDefinition(symbol: "v", meaning: "Closing velocity, m/s"),
                        VariableDefinition(symbol: "f", meaning: "Carrier frequency, Hz")
                    ],
                    spokenDescription: "The Doppler shift equals the carrier frequency times the closing velocity divided by the speed of light."
                ),
                inPractice: [
                    "At 2.4 GHz, 100 km/h produces about 222 Hz of shift.",
                    "It matters most for narrowband and coherent systems, and for anything tracking satellites.",
                    "Only the component of velocity along the path counts."
                ],
                commonMistake: "Forgetting that a reflected path from a moving object can double the shift.",
                relatedCalculators: [.wavelength],
                relatedArticles: [.frequencyPeriodWavelength],
                aliases: ["doppler", "doppler shift", "frequency shift", "motion"]
            )

        case .propagationDelay:
            return ReferenceArticle(
                id: self,
                title: "Propagation Delay",
                descriptor: "Time to cross the path",
                category: .propagation,
                definition: "The time a signal takes to travel a path, whether through free space or along a cable.",
                keyRelationship: Formula(
                    expression: "t = d / (VF · c)",
                    variables: [
                        VariableDefinition(symbol: "t", meaning: "Delay, s"),
                        VariableDefinition(symbol: "d", meaning: "Distance, m"),
                        VariableDefinition(symbol: "VF", meaning: "Velocity factor, 1 in vacuum")
                    ],
                    spokenDescription: "Delay equals distance divided by the velocity factor times the speed of light."
                ),
                inPractice: [
                    "Light covers about 30 cm per nanosecond in vacuum, and roughly 20 cm/ns in typical coax.",
                    "A geostationary satellite hop adds around 240 ms of round-trip delay.",
                    "Matched cable lengths matter anywhere phase or timing is compared."
                ],
                commonMistake: "Matching two cables by physical length when their velocity factors differ.",
                relatedCalculators: [.wavelength],
                relatedArticles: [.electricalLength, .frequencyPeriodWavelength],
                aliases: ["delay", "propagation delay", "latency", "time of flight"]
            )

        // MARK: - RF Systems

        case .cascadedGain:
            return ReferenceArticle(
                id: self,
                title: "Cascaded Gain",
                descriptor: "Adding a chain up in decibels",
                category: .rfSystems,
                definition: "The total gain of a chain is the sum of the individual stage gains and losses in decibels.",
                keyRelationship: Formula(
                    expression: "G_total(dB) = G₁ + G₂ + … + Gₙ",
                    variables: [
                        VariableDefinition(symbol: "Gₙ", meaning: "Gain of stage n, dB — negative for a loss")
                    ],
                    spokenDescription: "Total gain in decibels equals the sum of the stage gains."
                ),
                inPractice: [
                    "Passive parts enter the sum as negative gains.",
                    "Track the level at every node, not only at the output — an early stage can compress first.",
                    "Stage order leaves total gain unchanged but changes noise figure and linearity."
                ],
                commonMistake: "Summing gains without checking that no stage is being driven past its P1dB.",
                relatedCalculators: [.cascadedGainNoiseFigure],
                relatedArticles: [.gainAndLoss, .noiseFigure, .p1dB],
                aliases: ["cascade", "chain", "lineup", "total gain", "cascaded gain"]
            )

        case .noiseFigure:
            return ReferenceArticle(
                id: self,
                title: "Noise Figure and the Friis Cascade",
                descriptor: "Why the first stage decides",
                category: .rfSystems,
                definition: "Noise figure is how much a stage degrades the signal-to-noise ratio passing through it, in decibels. Down a chain, the earliest stages dominate.",
                keyRelationship: Formula(
                    expression: "F = F₁ + (F₂−1)/G₁ + (F₃−1)/(G₁·G₂) + …",
                    variables: [
                        VariableDefinition(symbol: "F", meaning: "Noise factor, linear — not dB"),
                        VariableDefinition(symbol: "G", meaning: "Stage gain, linear")
                    ],
                    spokenDescription: "Total noise factor equals the first stage noise factor, plus the second minus one over the first gain, plus the third minus one over the product of the first two gains, and so on."
                ),
                inPractice: [
                    "Put the low-noise amplifier first: its gain suppresses the contribution of everything behind it.",
                    "Loss ahead of the first amplifier adds to the system noise figure dB for dB.",
                    "The Friis cascade works in linear noise factor, so convert from dB before summing."
                ],
                commonMistake: "Adding noise figures in decibels, which the cascade formula does not allow.",
                relatedCalculators: [.cascadedGainNoiseFigure, .receiverSensitivity],
                relatedArticles: [.thermalNoise, .noiseTemperature, .cascadedGain],
                aliases: ["noise figure", "nf", "friis", "noise factor", "cascaded noise figure", "lna"]
            )

        case .noiseTemperature:
            return ReferenceArticle(
                id: self,
                title: "Noise Temperature",
                descriptor: "Noise figure on a linear scale",
                category: .rfSystems,
                definition: "An equivalent input temperature that would generate the same noise as the device itself. It carries the same information as noise figure, on a scale that suits very low-noise work.",
                keyRelationship: Formula(
                    expression: "T_e = T₀·(F − 1),  T₀ = 290 K",
                    variables: [
                        VariableDefinition(symbol: "T_e", meaning: "Equivalent noise temperature, K"),
                        VariableDefinition(symbol: "F", meaning: "Noise factor, linear")
                    ],
                    spokenDescription: "Equivalent noise temperature equals two hundred and ninety kelvin times noise factor minus one."
                ),
                inPractice: [
                    "A 1 dB noise figure is about 75 K; 0.5 dB is about 35 K.",
                    "Satellite and radio-astronomy systems are specified in kelvin because tenths of a dB matter.",
                    "Temperatures add directly along a cascade when referred to the same point."
                ],
                commonMistake: "Comparing a system temperature that includes the antenna with a receiver-only figure.",
                relatedCalculators: [.cascadedGainNoiseFigure],
                relatedArticles: [.noiseFigure, .thermalNoise],
                aliases: ["noise temperature", "kelvin", "te", "system temperature", "t0"]
            )

        case .p1dB:
            return ReferenceArticle(
                id: self,
                title: "P1dB Compression",
                descriptor: "The top of the linear range",
                category: .rfSystems,
                definition: "The output level at which a stage's gain has fallen 1 dB below its small-signal value — in practice, the top of its usable linear range.",
                keyRelationship: Formula(
                    expression: "P1dB(out) = P1dB(in) + G − 1 dB",
                    variables: [
                        VariableDefinition(symbol: "P1dB", meaning: "1 dB compression point, dBm"),
                        VariableDefinition(symbol: "G", meaning: "Small-signal gain, dB")
                    ],
                    spokenDescription: "Output referred P1dB equals input referred P1dB plus gain minus one decibel."
                ),
                inPractice: [
                    "Datasheets quote P1dB input- or output-referred; check which before comparing parts.",
                    "Saturated output power sits a few dB above P1dB.",
                    "Back off well below P1dB for signals with a high peak-to-average ratio."
                ],
                commonMistake: "Designing an OFDM chain to P1dB, when its peaks compress long before the average level does.",
                relatedCalculators: [.cascadedGainNoiseFigure],
                relatedArticles: [.thirdOrderIntercept, .dynamicRange, .cascadedGain],
                aliases: ["p1db", "compression", "1 db compression", "saturation", "psat", "headroom"]
            )

        case .thirdOrderIntercept:
            return ReferenceArticle(
                id: self,
                title: "IP3 and Intermodulation",
                descriptor: "Products that land in band",
                category: .rfSystems,
                definition: "IP3 is an extrapolated level at which third-order intermodulation products would equal the wanted tones. It is a figure of merit, not a level any device actually reaches.",
                keyRelationship: Formula(
                    expression: "IMD3 (dBc) = 2·(IP3 − P_out)",
                    variables: [
                        VariableDefinition(symbol: "IP3", meaning: "Third-order intercept, dBm"),
                        VariableDefinition(symbol: "P_out", meaning: "Output level per tone, dBm")
                    ],
                    spokenDescription: "Third order distortion in decibels relative to the carrier equals twice the difference between the intercept point and the output level per tone."
                ),
                inPractice: [
                    "Third-order products fall at 2f₁−f₂ and 2f₂−f₁, right beside the wanted signals.",
                    "Every extra 1 dB of drive raises third-order products by 3 dB.",
                    "OIP3 typically sits 10–15 dB above P1dB for a well-behaved amplifier."
                ],
                commonMistake: "Quoting IP3 without saying whether it is input- or output-referred.",
                relatedCalculators: [.cascadedGainNoiseFigure],
                relatedArticles: [.p1dB, .dynamicRange],
                aliases: ["ip3", "oip3", "iip3", "imd", "intermodulation", "third order", "two tone"]
            )

        case .dynamicRange:
            return ReferenceArticle(
                id: self,
                title: "Dynamic Range",
                descriptor: "From the noise floor to compression",
                category: .rfSystems,
                definition: "The span between the smallest usable signal and the largest one a receiver can handle before distortion or compression takes over.",
                keyRelationship: Formula(
                    expression: "SFDR ≈ ⅔·(IP3 − N_floor)",
                    variables: [
                        VariableDefinition(symbol: "SFDR", meaning: "Spurious-free dynamic range, dB"),
                        VariableDefinition(symbol: "N_floor", meaning: "Noise floor, dBm")
                    ],
                    spokenDescription: "Spurious free dynamic range is roughly two thirds of the difference between the third order intercept and the noise floor."
                ),
                inPractice: [
                    "The bottom is set by noise figure and bandwidth; the top by compression and intermodulation.",
                    "Adding gain moves both ends together and does not widen the range by itself.",
                    "Attenuation ahead of the receiver trades sensitivity for headroom."
                ],
                commonMistake: "Chasing noise figure while ignoring the strong out-of-band signals that set the upper limit.",
                relatedCalculators: [.receiverSensitivity],
                relatedArticles: [.thirdOrderIntercept, .p1dB, .receiverSensitivity],
                aliases: ["dynamic range", "sfdr", "spurious free", "headroom", "blocking"]
            )

        // MARK: - Measurements

        case .resolutionBandwidth:
            return ReferenceArticle(
                id: self,
                title: "RBW and VBW",
                descriptor: "The two bandwidths on an analyser",
                category: .measurements,
                definition: "Resolution bandwidth is the filter width a spectrum analyser sweeps with. Video bandwidth smooths the detected trace afterwards.",
                keyRelationship: Formula(
                    expression: "ΔN(dB) = 10·log₁₀(RBW₂ / RBW₁)",
                    variables: [
                        VariableDefinition(symbol: "RBW", meaning: "Resolution bandwidth, Hz"),
                        VariableDefinition(symbol: "ΔN", meaning: "Change in displayed noise level, dB")
                    ],
                    spokenDescription: "The displayed noise level changes by ten times the log of the ratio of the two resolution bandwidths."
                ),
                inPractice: [
                    "Narrowing RBW tenfold lowers the displayed noise floor by 10 dB, and slows the sweep considerably.",
                    "RBW does not change the displayed level of a CW signal, only of noise-like signals.",
                    "VBW smooths the trace; it does not improve the real noise floor."
                ],
                commonMistake: "Comparing noise measurements taken at different RBW settings without normalising them.",
                relatedCalculators: [.thermalNoise],
                relatedArticles: [.displayedAverageNoiseLevel, .thermalNoise],
                aliases: ["rbw", "vbw", "resolution bandwidth", "video bandwidth", "spectrum analyser", "spectrum analyzer", "sweep"]
            )

        case .displayedAverageNoiseLevel:
            return ReferenceArticle(
                id: self,
                title: "Noise Floor and DANL",
                descriptor: "How low an analyser can see",
                category: .measurements,
                definition: "DANL is a spectrum analyser's own noise floor, normally quoted normalised to 1 Hz so it can be scaled to whatever resolution bandwidth is in use.",
                keyRelationship: Formula(
                    expression: "Floor(dBm) = DANL(dBm/Hz) + 10·log₁₀(RBW)",
                    variables: [
                        VariableDefinition(symbol: "DANL", meaning: "Displayed average noise level, dBm/Hz"),
                        VariableDefinition(symbol: "RBW", meaning: "Resolution bandwidth, Hz")
                    ],
                    spokenDescription: "The displayed noise floor equals the normalised DANL plus ten times the log of the resolution bandwidth."
                ),
                inPractice: [
                    "A signal within a few dB of the floor reads high, because signal and noise add together.",
                    "A preamplifier lowers the floor but costs headroom at the top of the range.",
                    "Input attenuation raises the displayed floor dB for dB."
                ],
                commonMistake: "Reading a level measured close to the noise floor as the true signal level.",
                relatedCalculators: [.thermalNoise],
                relatedArticles: [.resolutionBandwidth, .thermalNoise],
                aliases: ["danl", "noise floor", "displayed average noise level", "analyser noise", "analyzer noise"]
            )

        case .sParameters:
            return ReferenceArticle(
                id: self,
                title: "S-Parameters",
                descriptor: "Networks described by waves",
                category: .measurements,
                definition: "Scattering parameters describe a network by the waves reflected from and transmitted through its ports, at a stated reference impedance.",
                keyRelationship: Formula(
                    expression: "S11 = reflected / incident at port 1\nS21 = transmitted at port 2 / incident at port 1",
                    variables: [
                        VariableDefinition(symbol: "S11", meaning: "Input match"),
                        VariableDefinition(symbol: "S21", meaning: "Forward gain or insertion loss")
                    ],
                    spokenDescription: "S eleven is the ratio of reflected to incident wave at port one. S twenty one is the wave leaving port two relative to the wave entering port one."
                ),
                inPractice: [
                    "S11 is the input match and S21 is forward gain or insertion loss.",
                    "They are complex and frequency-dependent, so a single number always belongs to one frequency.",
                    "They are only valid at the reference impedance they were measured in, normally 50 Ω."
                ],
                commonMistake: "Writing S11 as a positive number, which silently turns it into a return loss.",
                relatedCalculators: [.reflectionConverter],
                relatedArticles: [.reflectionCoefficient, .returnLoss, .characteristicImpedance],
                aliases: ["s-parameters", "s parameters", "s11", "s21", "s12", "s22", "scattering", "vna", "network analyser", "network analyzer"]
            )

        case .cableAndConnectorLoss:
            return ReferenceArticle(
                id: self,
                title: "Cable and Connector Loss",
                descriptor: "What the feedline costs you",
                category: .measurements,
                definition: "Feedline loss rises with both frequency and length, and every connector and adapter in the path adds a little more.",
                keyRelationship: Formula(
                    expression: "L_total = (loss per metre × length) + Σ connector losses",
                    variables: [
                        VariableDefinition(symbol: "L_total", meaning: "Total feed loss, dB")
                    ],
                    spokenDescription: "Total feed loss equals loss per metre times length, plus the sum of the connector losses."
                ),
                inPractice: [
                    "Cable loss roughly follows the square root of frequency, so a cable rated at 1 GHz is worse at 6 GHz.",
                    "Budget around 0.1–0.3 dB for a good connector pair, and more for worn or adapted ones.",
                    "Loss before the antenna costs EIRP; loss before the receiver costs noise figure dB for dB."
                ],
                commonMistake: "Taking a cable's loss figure from the wrong frequency, where it can be double.",
                relatedCalculators: [.eirp, .linkBudget],
                relatedArticles: [.gainAndLoss, .noiseFigure, .eirpAndErp],
                aliases: ["cable loss", "feedline", "connector loss", "attenuation", "coax loss", "adapter"]
            )
        }
    }
}

/// Access to the reference library as a whole.
enum ReferenceLibrary {
    /// Every article, in declaration order.
    static let all: [ReferenceArticle] = ReferenceArticleID.allCases.map(\.article)

    static func inCategory(_ category: RFCategory) -> [ReferenceArticle] {
        all.filter { $0.category == category }
    }

    static var alphabetical: [ReferenceArticle] {
        all.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
