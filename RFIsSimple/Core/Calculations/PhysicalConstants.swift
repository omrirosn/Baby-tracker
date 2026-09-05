import Foundation

/// Constants used by the calculation engine.
///
/// All values are the exact SI definitions where one exists, so results match
/// published reference tables to the digit.
enum PhysicalConstants {
    /// Speed of light in vacuum, m/s. Exact by the SI definition of the metre.
    static let speedOfLight: Double = 299_792_458.0

    /// Boltzmann constant, J/K. Exact since the 2019 SI redefinition.
    static let boltzmann: Double = 1.380_649e-23

    /// Reference temperature for noise figure and sensitivity work, K.
    /// This is the IEEE standard noise temperature, T₀.
    static let standardNoiseTemperature: Double = 290.0

    /// Impedance of free space, Ω.
    static let freeSpaceImpedance: Double = 376.730_313_412

    /// System impedance most RF equipment is built around, Ω.
    static let defaultSystemImpedance: Double = 50.0
}
