extern vec2 screen_size;
extern float pixel_size;
extern float matrix_grid;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 pixel_coord = floor(screen_coords / pixel_size) * pixel_size;
    vec2 uv = pixel_coord / screen_size;
    vec4 base_col = Texel(texture, uv);

    vec2 sub_uv = fract(screen_coords / pixel_size);
    float grid = 1.0;
    if (sub_uv.x < 0.12 || sub_uv.y < 0.12) {
        grid = 1.0 - (matrix_grid * 0.45);
    }

    return vec4(base_col.rgb * grid, base_col.a) * color;
}
