shader_type canvas_item;

// Required in Godot 4.x to access background for inversion
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform bool center_enabled = true;
uniform bool legs_enabled = true;
uniform bool inverted = false;

// Replaces color_id with a direct color picker
uniform vec4 crosshair_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);

uniform float center_radius : hint_range(0.0, 0.1) = 0.002;
uniform float width : hint_range(0.0, 0.1) = 0.003;
uniform float len : hint_range(0.0, 0.5) = 0.03;
uniform float spacing : hint_range(0.0, 0.1) = 0.008;
uniform float spread : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    // Aspect ratio correction
    float a = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    vec2 UVa = vec2(UV.x / a, UV.y);
    vec2 center = vec2(0.5 / a, 0.5);

    // Shape logic
    float point = step(distance(UVa, center), center_radius);

    float h = step(center.x - len - spacing * spread, UVa.x) - step(center.x - spacing * spread, UVa.x);
    h += step(center.x + spacing * spread, UVa.x) - step(center.x + len + spacing * spread, UVa.x);
    h *= step(center.y - width, UVa.y) - step(center.y + width, UVa.y);
    
    float v = step(center.y - len - spacing * spread, UVa.y) - step(center.y - spacing * spread, UVa.y);
    v += step(center.y + spacing * spread, UVa.y) - step(center.y + len + spacing * spread, UVa.y);
    v *= step(center.x - width, UVa.x) - step(center.x + width, UVa.x);

    float mask = (h + v) * float(legs_enabled) + point * float(center_enabled);

    if (!inverted) {
        // Uses the direct color chosen in the Inspector
        COLOR = crosshair_color * mask;
    } else {
        // High-contrast color inversion logic
        vec3 screen_rgb = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
        vec3 inverted_rgb = (cos(screen_rgb * 3.1415926534) + 1.0) / 2.0;
        COLOR = vec4(inverted_rgb, 1.0) * mask;
    }
}
