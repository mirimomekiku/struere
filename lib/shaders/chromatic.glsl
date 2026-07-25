extern float chromatic_strength;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    float offset = chromatic_strength;

    float r = Texel(texture, uv + vec2(offset, 0.0)).r;
    float g = Texel(texture, uv).g;
    float b = Texel(texture, uv - vec2(offset, 0.0)).b;
    float a = Texel(texture, uv).a;

    return vec4(r, g, b, a) * color;
}
