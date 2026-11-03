# swift-itu-r-bs-1770

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of ITU-R BS.1770, the measurement of programme loudness and true-peak level.

## Overview

Integrated loudness in LUFS with K-weighting at any sample rate and both gates, and true peak in dBTP through four-times oversampling. Foundation-free; the mathematics comes from ISO 9899.

```swift
import ITU_R_BS_1770

let programme = ITU_R_BS_1770.Programme(channels: [left, right], rate: 48_000)
programme.loudness  // LUFS
programme.peak      // dBTP
```

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-itu-r-bs-1770.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "ITU-R BS.1770", package: "swift-itu-r-bs-1770")
    ]
)
```

## License

This package is licensed under the Apache License 2.0. See [LICENSE.md](LICENSE.md) for details.
