extern float curvature;
extern float chromatic_aberration;

vec2 curve(vec2 uv) {
    uv = (uv - 0.5) * 2.0;
    uv.x *= 1.0 + pow(abs(uv.y) / curvature, 2.0);
    uv.y *= 1.0 + pow(abs(uv.x) / curvature, 2.0);
    uv = (uv / 2.0) + 0.5;
    return uv;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = curve(texture_coords);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    float r = Texel(texture, uv + vec2(chromatic_aberration, 0.0)).r;
    float g = Texel(texture, uv).g;
    float b = Texel(texture, uv - vec2(chromatic_aberration, 0.0)).b;
    vec3 base_col = vec3(r, g, b);

    float vig = (16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
    vig = pow(vig, 0.25);

    vec3 final_color = base_col * vig;
    return vec4(final_color, 1.0) * color;
}
