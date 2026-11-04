# swift-itu-r-bs-1770

Use this package when you need the integrated loudness of a piece of audio in LUFS, or its true peak in dBTP, as ITU-R BS.1770 defines them. Start from `ITU_R_BS_1770.Programme`, with one sample array per channel. Use `ITU_R_BS_1770.Biquad` only if you want the K-weighting filters on their own.

## Laws

- Samples are linear, with full scale at 1.0.
- The K-weighting is derived for any sample rate. At 48 kHz it reproduces the coefficients the recommendation tabulates.
- Loudness is measured over 400 ms blocks that overlap by 75 %. A partial block at the end is not measured. Blocks below -70 LUFS are dropped, then blocks more than 10 LU below the loudness of the rest are dropped.
- Silence, and a programme shorter than one block, measure negative infinity.
- Every channel weighs 1.0 unless you pass weights. Surround channels need 1.41 from the caller.
- True peak is the highest absolute value over all channels after four times oversampling. It is never below the highest sample, and silence measures negative infinity.
- `ITU_R_BS_1770.Programme.loudness` and `ITU_R_BS_1770.Programme.peak` are computed again on every access. Nothing is cached.
- `ITU_R_BS_1770.Biquad.filtered(_:)` starts from zero history on every call.
