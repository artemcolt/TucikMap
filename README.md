# TucikMap

A prototype vector-tile map engine built with Swift and Metal. This project renders interactive maps using vector tiles (currently sourced from Mapbox) in a custom Metal-based renderer. It's still in early development, but it supports basic globe views, zooming, and labeling.

## Features
- Vector tile rendering with Metal for high-performance graphics.
- Interactive map controls (zoom, pan, pitch).
- Support for Mapbox tile sources (requires your own access token).
- SwiftUI integration for easy embedding in iOS/macOS apps.
- Debug options like grid overlay (disabled by default).

## Screenshots
<img src="https://raw.githubusercontent.com/artemcolt/TucikMap/refs/heads/main/Screenshots/IMG_2615.PNG" alt="Global View" width="300">  
*Global continent view with labels.*
<img src="https://raw.githubusercontent.com/artemcolt/TucikMap/refs/heads/main/Screenshots/IMG_2617.PNG" alt="City Zoom" width="300">  
*Zoomed into Lower Manhattan, New York.*
<img src="https://raw.githubusercontent.com/artemcolt/TucikMap/refs/heads/main/Screenshots/IMG_2616.PNG" alt="Regional View" width="300">  
*Northeastern US and Canada region.*


## Getting Started
1. Clone the repo: `git clone https://github.com/artemcolt/TucikMap.git`
2. Open in Xcode.
3. Replace the Mapbox token in `ContentView.swift` with your own (get one at [mapbox.com](https://mapbox.com)).
4. Build and run on iOS simulator or device.

## Usage
The core view is `TucikMapView`, configurable via `MapSettings`. See `ContentView.swift` for an example.

## Contributing
This is a prototype—pull requests welcome for bug fixes, features, or optimizations! Focus areas: improved tile caching, more map styles, or better performance.

## License
MIT License. See [LICENSE](https://github.com/artemcolt/TucikMap/blob/main/LICENSE.md) for details.
