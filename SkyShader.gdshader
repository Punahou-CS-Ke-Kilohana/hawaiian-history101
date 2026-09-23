shader_type sky;

uniform vec3 skyColor : source_color;
uniform vec3 horizonColor : source_color;
uniform sampler2D skyTexture : filter_linear, repeat_enable;

void sky() {
	//vec3 dir =EYEDIR;
	//vec2 uv = vec2(atan(dir.x,-dir.z)/(2.0 * PI) + 0.5, acos(dir.y)/PI);
	float col = clamp(EYEDIR.y / 0.05, 0.0, 1.0);
	vec3 finalColor = mix(horizonColor,skyColor,col);
	COLOR = texture(skyTexture,SKY_COORDS).rgb;
}
