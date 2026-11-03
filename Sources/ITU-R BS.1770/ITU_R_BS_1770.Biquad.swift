import ISO_9899

extension ITU_R_BS_1770 {
    /// A second-order filter: `b` are the feed-forward and `a` the feedback coefficients, `a0` = 1.
    public struct Biquad: Sendable, Hashable {
        public let b: [Double]
        public let a: [Double]

        public init(b: [Double], a: [Double]) {
            self.b = b
            self.a = a
        }
    }
}

extension ITU_R_BS_1770.Biquad {
    /// The K-weighting's first stage, a high shelf that models the head, at `rate` samples per second.
    ///
    /// BS.1770 tabulates the coefficients for 48 kHz only. These are the analogue prototype behind
    /// that table, warped by the bilinear transform, so they reproduce the table at 48 kHz and hold
    /// at every other rate.
    public static func shelf(at rate: Double) -> Self {
        let k = ISO_9899.Math.tan(Double.pi * 1681.974450955533 / rate)
        let q = 0.7071752369554196
        let high = ISO_9899.Math.pow(10, 3.999843853973347 / 20)
        let band = ISO_9899.Math.pow(high, 0.4996667741545416)
        let a0 = 1 + k / q + k * k
        return Self(
            b: [(high + band * k / q + k * k) / a0, 2 * (k * k - high) / a0, (high - band * k / q + k * k) / a0],
            a: [2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]
        )
    }

    /// The K-weighting's second stage, the revised low-frequency B-curve high pass.
    public static func highPass(at rate: Double) -> Self {
        let k = ISO_9899.Math.tan(Double.pi * 38.13547087602444 / rate)
        let q = 0.5003270373238773
        let a0 = 1 + k / q + k * k
        return Self(b: [1, -2, 1], a: [2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0])
    }

    public func filtered(_ input: [Double]) -> [Double] {
        var (x1, x2, y1, y2) = (0.0, 0.0, 0.0, 0.0)
        return input.map { x in
            let y = b[0] * x + b[1] * x1 + b[2] * x2 - a[0] * y1 - a[1] * y2
            (x2, x1, y2, y1) = (x1, x, y1, y)
            return y
        }
    }
}
