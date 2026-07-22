// Horizontal CRT Scanlines Shader
extern float scanline_count;
extern float scanline_intensity;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex = Texel(texture, texture_coords);
    float scanline = sin(texture_coords.y * scanline_count * 3.14159 * 2.0);
    scanline = (scanline + 1.0) * 0.5;
    scanline = 1.0 - (scanline * scanline_intensity);
    return vec4(tex.rgb * scanline, tex.a) * color;
}
