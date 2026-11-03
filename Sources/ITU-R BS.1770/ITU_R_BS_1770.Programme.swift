import ISO_9899

extension ITU_R_BS_1770 {
    /// An audio programme: one sample array per channel, all of one length, at `rate` samples per second.
    public struct Programme: Sendable, Hashable {
        public let channels: [[Float]]
        public let rate: Double
        /// The channel weights G, 1.0 for left, right and centre and 1.41 for the surrounds.
        public let weights: [Double]

        public init(channels: [[Float]], rate: Double, weights: [Double]? = nil) {
            precondition(Set(channels.map(\.count)).count <= 1, "every channel has the same length")
            self.channels = channels
            self.rate = rate
            self.weights = weights ?? channels.map { _ in 1 }
        }
    }
}

extension ITU_R_BS_1770.Programme {
    /// Integrated loudness in LUFS, BS.1770-4 annex 1 and 2.
    ///
    /// K-weighting, mean square over 400 ms blocks overlapping by 75 %, then an absolute gate at
    /// −70 LUFS and a relative gate 10 LU below the loudness of the blocks the absolute gate kept.
    /// Silence measures −∞.
    public var loudness: Double {
        let shelf = ITU_R_BS_1770.Biquad.shelf(at: rate)
        let pass = ITU_R_BS_1770.Biquad.highPass(at: rate)
        let sums = channels.map { channel in
            pass.filtered(shelf.filtered(channel.map(Double.init))).reduce(into: [0.0]) { $0.append(($0.last ?? 0) + $1 * $1) }
        }
        let block = Int((rate * 0.4).rounded())
        let step = Int((rate * 0.1).rounded())
        let count = channels.first?.count ?? 0
        guard count >= block else { return -.infinity }
        let blocks = stride(from: 0, through: count - block, by: step).map { start in
            zip(sums, weights).reduce(0.0) { $0 + $1.1 * ($1.0[start + block] - $1.0[start]) / Double(block) }
        }
        func level(_ power: Double) -> Double { power > 0 ? -0.691 + 10 * ISO_9899.Math.log10(power) : -.infinity }
        let audible = blocks.filter { level($0) > -70 }
        guard !audible.isEmpty else { return -.infinity }
        let relative = level(audible.reduce(0, +) / Double(audible.count)) - 10
        let gated = audible.filter { level($0) > relative }
        return level(gated.reduce(0, +) / Double(gated.count))
    }

    /// True peak in dBTP, BS.1770-4 annex 2: the highest absolute value after four-times oversampling.
    ///
    /// The oversampling interpolates with a 32-tap Hann-windowed sinc per phase, which
    /// reads a full-scale sine at a quarter of the sample rate within 0.1 dB of its crest.
    public var peak: Double {
        let taps = 16
        let kernel = (1...3).map { phase in
            (-taps + 1...taps).map { k -> Double in
                let t = Double(k) - Double(phase) / 4
                let window = 0.5 + 0.5 * ISO_9899.Math.cos(Double.pi * t / Double(taps))
                return (t == 0 ? 1 : ISO_9899.Math.sin(Double.pi * t) / (Double.pi * t)) * window
            }
        }
        var highest = 0.0
        for channel in channels {
            let sampled = Double(channel.map { abs($0) }.max() ?? 0)
            highest = max(highest, sampled)
            for index in channel.indices where Double(max(abs(channel[index]), abs(channel[min(index + 1, channel.endIndex - 1)]))) > sampled / 2 {
                for phase in kernel {
                    var sum = 0.0
                    for (offset, weight) in zip(-taps + 1...taps, phase) {
                        let source = index + offset
                        if channel.indices.contains(source) { sum += Double(channel[source]) * weight }
                    }
                    highest = max(highest, abs(sum))
                }
            }
        }
        return highest > 0 ? 20 * ISO_9899.Math.log10(highest) : -.infinity
    }
}
