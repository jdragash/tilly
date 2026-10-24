#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Value noise in 0...1, smooth between lattice points. The seed shifts the lattice, so each seed
// is its own drawing.
static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float valueNoise(float2 p, float seed) {
    p += seed * 17.3;
    float2 i = floor(p);
    float2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + float2(1, 0));
    float c = hash21(i + float2(0, 1));
    float d = hash21(i + float2(1, 1));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/// A fill's alpha varied across it, so a wash blooms where the colour pooled: the alpha moves
/// within `strength` of 1, never above it.
[[ stitchable ]] half4 bloom(float2 position, half4 color, float frequency, float strength, float seed) {
    float n = 0.65 * valueNoise(position * frequency, seed) + 0.35 * valueNoise(position * frequency * 2.1, seed + 3.0);
    // A touch of noise on top, so the slow gradient doesn't band into contour lines.
    float dither = (hash21(position * 1.7) - 0.5) * 0.02;
    float factor = clamp(1.0 - strength / 2.0 + strength * n + dither, 0.0, 1.0);
    return color * half(factor);
}

/// Moves each pixel a little by noise, so a symbol's clean line wobbles as if drawn by hand. Like the
/// prototype's displacement filter it moves a pixel by `amount × (noise − 0.5)`: at most half of
/// `amount`, and usually a fraction of that.
[[ stitchable ]] float2 roughen(float2 position, float frequency, float amount, float seed) {
    float2 p = position * frequency;
    float nx = (valueNoise(p, seed) + 0.5 * valueNoise(p * 2.0, seed + 5.0)) / 1.5;
    float ny = (valueNoise(p + 31.7, seed + 9.0) + 0.5 * valueNoise(p * 2.0 + 31.7, seed + 14.0)) / 1.5;
    return position + float2(nx - 0.5, ny - 0.5) * amount;
}
