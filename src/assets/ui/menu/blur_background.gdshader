shader_type canvas_item;

uniform float blur_strength : hint_range(0.0, 6.0) = 2.5;

void fragment() {
    vec2 px = TEXTURE_PIXEL_SIZE * blur_strength;
    vec4 col = texture(TEXTURE, UV) * 0.2;
    col += texture(TEXTURE, UV + vec2(px.x, 0.0)) * 0.15;
    col += texture(TEXTURE, UV - vec2(px.x, 0.0)) * 0.15;
    col += texture(TEXTURE, UV + vec2(0.0, px.y)) * 0.15;
    col += texture(TEXTURE, UV - vec2(0.0, px.y)) * 0.15;
    col += texture(TEXTURE, UV + px) * 0.1;
    col += texture(TEXTURE, UV - px) * 0.1;
    col += texture(TEXTURE, UV + vec2(px.x, -px.y)) * 0.075;
    col += texture(TEXTURE, UV + vec2(-px.x, px.y)) * 0.075;
    COLOR = col;
}
