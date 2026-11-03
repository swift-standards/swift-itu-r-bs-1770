import ISO_9899
import ITU_R_BS_1770
import Testing

@Suite struct `Programme Tests` {
    static func sine(decibels: Double, hertz: Double = 997, phase: Double = 0, seconds: Double, rate: Double = 48_000) -> [Float] {
        let amplitude = ISO_9899.Math.pow(10, decibels / 20)
        return (0..<Int(seconds * rate)).map { index in
            Float(amplitude * ISO_9899.Math.sin(2 * Double.pi * hertz * Double(index) / rate + phase))
        }
    }

    static func stereo(_ samples: [Float], rate: Double = 48_000) -> ITU_R_BS_1770.Programme {
        ITU_R_BS_1770.Programme(channels: [samples, samples], rate: rate)
    }

    @Test func `the K-weighting reproduces the recommendation's 48 kHz coefficients`() {
        let shelf = ITU_R_BS_1770.Biquad.shelf(at: 48_000)
        let pass = ITU_R_BS_1770.Biquad.highPass(at: 48_000)
        let table = (
            shelf: (b: [1.53512485958697, -2.69169618940638, 1.19839281085285], a: [-1.69065929318241, 0.73248077421585]),
            pass: (b: [1.0, -2.0, 1.0], a: [-1.99004745483398, 0.99007225036621])
        )
        for (value, expected) in zip(shelf.b + shelf.a + pass.b + pass.a, table.shelf.b + table.shelf.a + table.pass.b + table.pass.a) {
            #expect(abs(value - expected) < 1e-7, "\(value) against \(expected)")
        }
    }

    @Test func `a stereo 997 Hz sine at -23 dBFS measures -23 LUFS, at 48 and at 44.1 kHz`() {
        for rate in [48_000.0, 44_100] {
            let loudness = Self.stereo(Self.sine(decibels: -23, seconds: 5, rate: rate), rate: rate).loudness
            #expect(abs(loudness - -23) < 0.05, "\(rate): \(loudness)")
        }
    }

    @Test func `silence and a tail 25 dB down are gated out, and silence alone measures minus infinity`() {
        let tone = Self.sine(decibels: -20, seconds: 5)
        let quiet = Self.sine(decibels: -45, seconds: 5)
        let silence = [Float](repeating: 0, count: tone.count)
        let alone = Self.stereo(tone).loudness
        // 47 blocks lie wholly in the tone and three straddle its end, holding 3/4, 1/2 and 1/4 of
        // its power; all 50 pass both gates, and every block after them fails one.
        let straddled = alone + 10 * ISO_9899.Math.log10(48.5 / 50)
        #expect(abs(Self.stereo(tone + silence).loudness - straddled) < 0.001)
        #expect(abs(Self.stereo(tone + quiet).loudness - straddled) < 0.001)
        #expect(Self.stereo(silence).loudness == -.infinity)
    }

    @Test func `a quarter-rate sine sampled 45 degrees off its crest reads 3 dB higher as a true peak`() {
        let samples = Self.sine(decibels: 0, hertz: 12_000, phase: Double.pi / 4, seconds: 1)
        let programme = ITU_R_BS_1770.Programme(channels: [samples], rate: 48_000)
        let sampled = 20 * ISO_9899.Math.log10(Double(samples.map { abs($0) }.max() ?? 0))
        #expect(abs(sampled - -3.01) < 0.01, "\(sampled)")
        #expect(abs(programme.peak) < 0.1, "\(programme.peak)")
    }
}
