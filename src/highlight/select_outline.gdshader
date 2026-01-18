shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 highlight_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float intensity : hint_range(0, 1) = 0.0;
uniform float outline_width : hint_range(0, 0.3) = 0.1; // Controlled by script

void vertex() {
	// Push the vertices out along their normals
	// The 0.001 constant ensures the width is manageable in meters
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
	
	// Offset vertices to create the hull
	clip_position.xy += clip_normal.xy  * clip_position.w * 0.001;
	POSITION = clip_position* outline_width;
}

void fragment() {
    ALBEDO = highlight_color.rgb;
    ALPHA = intensity;
}