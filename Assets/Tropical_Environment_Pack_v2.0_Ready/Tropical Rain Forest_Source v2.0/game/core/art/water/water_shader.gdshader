shader_type spatial;

uniform sampler2D water_noise;

uniform float frequency : hint_range(0,2) = 1.0;
uniform float wave_height : hint_range(0, 100) = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX.y += cos(VERTEX.x*10.0*wave_height+TIME*frequency)*wave_height;
	VERTEX.y += sin(VERTEX.z*10.0*wave_height+TIME*frequency)*wave_height;
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	vec3 color = vec3(0.0,0.0,0.75);
	color += texture(water_noise, UV).rgb*0.25;
	ALBEDO = color;
	ALPHA = 0.9;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
