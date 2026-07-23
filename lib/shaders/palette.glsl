// Palette Limiting & Bayer 4x4 Dithering Shader — 12 palettes (modes 0–11)
extern int palette_mode;
extern float dither_strength;

const mat4 bayer4x4 = mat4(
     0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
    12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
     3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
    15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
);

vec3 nearest4(vec3 c, vec3 p0, vec3 p1, vec3 p2, vec3 p3) {
    float d0 = distance(c, p0);
    float d1 = distance(c, p1);
    float d2 = distance(c, p2);
    float d3 = distance(c, p3);
    float best = min(min(d0,d1),min(d2,d3));
    if (best == d0) return p0;
    if (best == d1) return p1;
    if (best == d2) return p2;
    return p3;
}

vec3 get_closest_color(vec3 c, int mode) {
    if (mode == 0) {
        // GameBoy Green — classic 4-shade pea-soup green
        return nearest4(c,
            vec3(0.06, 0.22, 0.06),
            vec3(0.19, 0.38, 0.19),
            vec3(0.54, 0.67, 0.06),
            vec3(0.61, 0.73, 0.06)
        );
    } else if (mode == 1) {
        // Cyberpunk Neon — deep void + hot pink + cyan + acid yellow
        return nearest4(c,
            vec3(0.05, 0.02, 0.15),
            vec3(0.85, 0.05, 0.45),
            vec3(0.00, 0.85, 0.95),
            vec3(0.95, 0.90, 0.20)
        );
    } else if (mode == 2) {
        // NES Classic — black, red, gold, white
        return nearest4(c,
            vec3(0.00, 0.00, 0.00),
            vec3(0.87, 0.23, 0.23),
            vec3(0.95, 0.82, 0.25),
            vec3(1.00, 1.00, 1.00)
        );
    } else if (mode == 3) {
        // CGA Mode 1 — black, cyan, magenta, white
        return nearest4(c,
            vec3(0.00, 0.00, 0.00),
            vec3(0.33, 1.00, 1.00),
            vec3(1.00, 0.33, 1.00),
            vec3(1.00, 1.00, 1.00)
        );
    } else if (mode == 4) {
        // Monochromatic Ink — pure 1-bit black & white
        float lum = dot(c, vec3(0.299, 0.587, 0.114));
        return vec3(step(0.5, lum));
    } else if (mode == 5) {
        // Vaporwave — deep purple, violet, bubblegum pink, aqua
        return nearest4(c,
            vec3(0.12, 0.05, 0.24),
            vec3(0.48, 0.18, 0.58),
            vec3(1.00, 0.44, 0.70),
            vec3(0.40, 0.92, 0.88)
        );
    } else if (mode == 6) {
        // GameBoy Pocket — cool grey 4-shade
        return nearest4(c,
            vec3(0.05, 0.06, 0.07),
            vec3(0.30, 0.33, 0.35),
            vec3(0.63, 0.66, 0.65),
            vec3(0.88, 0.90, 0.88)
        );
    } else if (mode == 7) {
        // Amber LCD — warm amber phosphor on near-black
        return nearest4(c,
            vec3(0.06, 0.04, 0.00),
            vec3(0.45, 0.22, 0.00),
            vec3(0.82, 0.52, 0.00),
            vec3(1.00, 0.82, 0.15)
        );
    } else if (mode == 8) {
        // Sega Master System — black, blue, red, white (SMS palette subset)
        return nearest4(c,
            vec3(0.00, 0.00, 0.00),
            vec3(0.00, 0.27, 0.80),
            vec3(0.87, 0.07, 0.07),
            vec3(0.93, 0.93, 0.93)
        );
    } else if (mode == 9) {
        // ZX Spectrum — black, bright red, bright yellow, white
        return nearest4(c,
            vec3(0.00, 0.00, 0.00),
            vec3(1.00, 0.07, 0.07),
            vec3(1.00, 1.00, 0.00),
            vec3(1.00, 1.00, 1.00)
        );
    } else if (mode == 10) {
        // Famicom Disk — pastel lavender, salmon, mint, cream
        return nearest4(c,
            vec3(0.24, 0.14, 0.42),
            vec3(0.84, 0.42, 0.52),
            vec3(0.40, 0.82, 0.72),
            vec3(0.96, 0.90, 0.80)
        );
    } else {
        // Arctic Ice (mode 11) — midnight navy, steel, ice blue, snow white
        return nearest4(c,
            vec3(0.04, 0.08, 0.20),
            vec3(0.22, 0.40, 0.62),
            vec3(0.55, 0.78, 0.95),
            vec3(0.90, 0.96, 1.00)
        );
    }
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex = Texel(texture, texture_coords);
    if (tex.a == 0.0) return vec4(0.0);

    int x = int(mod(screen_coords.x, 4.0));
    int y = int(mod(screen_coords.y, 4.0));
    float dither = (bayer4x4[x][y] - 0.5) * dither_strength;

    vec3 rgb = clamp(tex.rgb + dither, 0.0, 1.0);
    vec3 pal_rgb = get_closest_color(rgb, palette_mode);

    return vec4(pal_rgb, tex.a * color.a);
}
