shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 highlight_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float intensity : hint_range(0, 1) = 0.0;
uniform float outline_width : hint_range(0, 0.3) = 0.1; // Controlled by script

void vertex() {
    // Expand the mesh slightly along its normals to create the border
    VERTEX += NORMAL * outline_width;
}

void fragment() {
    ALBEDO = highlight_color.rgb;
    ALPHA = intensity;
}