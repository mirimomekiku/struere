// Palette Limiting & Bayer 4x4 Dithering Shader
extern int palette_mode; // 0: GameBoy, 1: Cyberpunk, 2: NES, 3: CGA, 4: Mono, 5: Vaporwave
extern float dither_strength;

const mat4 bayer4x4 = mat4(
     0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
    12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
     3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
    15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
);

vec3 get_closest_color(vec3 c, int mode) {
    if (mode == 0) { // GameBoy Green
        vec3 p[4];
        p[0] = vec3(0.06, 0.22, 0.06);
        p[1] = vec3(0.19, 0.38, 0.19);
        p[2] = vec3(0.54, 0.67, 0.06);
        p[3] = vec3(0.61, 0.73, 0.06);
        float best = 999.0;
        vec3 res = p[0];
        for (int i=0; i<4; i++) {
            float d = distance(c, p[i]);
            if (d < best) { best = d; res = p[i]; }
        }
        return res;
    } else if (mode == 1) { // Cyberpunk Neon
        vec3 p[4];
        p[0] = vec3(0.05, 0.02, 0.15);
        p[1] = vec3(0.85, 0.05, 0.45);
        p[2] = vec3(0.00, 0.85, 0.95);
        p[3] = vec3(0.95, 0.90, 0.20);
        float best = 999.0;
        vec3 res = p[0];
        for (int i=0; i<4; i++) {
            float d = distance(c, p[i]);
            if (d < best) { best = d; res = p[i]; }
        }
        return res;
    } else if (mode == 2) { // NES Classic
        vec3 p[4];
        p[0] = vec3(0.00, 0.00, 0.00);
        p[1] = vec3(0.87, 0.23, 0.23);
        p[2] = vec3(0.95, 0.82, 0.25);
        p[3] = vec3(1.00, 1.00, 1.00);
        float best = 999.0;
        vec3 res = p[0];
        for (int i=0; i<4; i++) {
            float d = distance(c, p[i]);
            if (d < best) { best = d; res = p[i]; }
        }
        return res;
    } else if (mode == 3) { // CGA Mode 1
        vec3 p[4];
        p[0] = vec3(0.0, 0.0, 0.0);
        p[1] = vec3(0.33, 1.0, 1.0);
        p[2] = vec3(1.0, 0.33, 1.0);
        p[3] = vec3(1.0, 1.0, 1.0);
        float best = 999.0;
        vec3 res = p[0];
        for (int i=0; i<4; i++) {
            float d = distance(c, p[i]);
            if (d < best) { best = d; res = p[i]; }
        }
        return res;
    } else if (mode == 4) { // Monochromatic Ink
        float lum = dot(c, vec3(0.299, 0.587, 0.114));
        return vec3(step(0.5, lum));
    } else { // Vaporwave
        vec3 p[4];
        p[0] = vec3(0.12, 0.05, 0.24);
        p[1] = vec3(0.48, 0.18, 0.58);
        p[2] = vec3(1.00, 0.44, 0.70);
        p[3] = vec3(0.40, 0.92, 0.88);
        float best = 999.0;
        vec3 res = p[0];
        for (int i=0; i<4; i++) {
            float d = distance(c, p[i]);
            if (d < best) { best = d; res = p[i]; }
        }
        return res;
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
