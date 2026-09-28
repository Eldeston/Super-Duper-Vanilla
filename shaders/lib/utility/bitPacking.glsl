// --------------- Bit Packing & Compression Library ---------------- //
// High-performance packing and encoding routines for buffers and varyings

// Octahedral wrap helper for negative Z hemisphere
vec2 octWrap(in vec2 v){
	return (1.0 - abs(v.yx)) * (step(0.0, v.xy) * 2.0 - 1.0);
}

// Encodes a normalized 3D vector into a 2D octahedral representation in [-1.0, 1.0]
vec2 encodeOctNormal(in vec3 n){
	n /= (abs(n.x) + abs(n.y) + abs(n.z));
	return n.z >= 0.0 ? n.xy : octWrap(n.xy);
}

// Decodes a 2D octahedral vector in [-1.0, 1.0] into a normalized 3D vector
vec3 decodeOctNormal(in vec2 f){
	vec3 n = vec3(f.xy, 1.0 - abs(f.x) - abs(f.y));
	if(n.z < 0.0) n.xy = octWrap(n.xy);
	return fastNormalize(n);
}

// Encodes a normalized 3D vector into [0.0, 1.0] octahedral coordinates
vec2 encodeOctNormalUnorm(in vec3 n){
	return encodeOctNormal(n) * 0.5 + 0.5;
}

// Decodes a 2D octahedral vector in [0.0, 1.0] into a normalized 3D vector
vec3 decodeOctNormalUnorm(in vec2 f){
	return decodeOctNormal(f * 2.0 - 1.0);
}

// Packs two 8-bit UNORM [0.0, 1.0] values into a single 16-bit float
float packUnorm2x8(in vec2 v){
	return dot(floor(saturate(v) * 255.0 + 0.5), vec2(1.0, 256.0)) * (1.0 / 65535.0);
}

// Unpacks a 16-bit float into two 8-bit UNORM [0.0, 1.0] values
vec2 unpackUnorm2x8(in float p){
	float val = floor(p * 65535.0 + 0.5);
	return vec2(mod(val, 256.0), floor(val * (1.0 / 256.0))) * (1.0 / 255.0);
}

// Packs four 8-bit UNORM [0.0, 1.0] values into a 32-bit unsigned integer
uint packUnorm4x8(in vec4 v){
	uvec4 u = uvec4(round(saturate(v) * 255.0));
	return u.x | (u.y << 8u) | (u.z << 16u) | (u.w << 24u);
}

// Unpacks a 32-bit unsigned integer into four 8-bit UNORM [0.0, 1.0] values
vec4 unpackUnorm4x8(in uint p){
	return vec4(uvec4(p & 0xFFu, (p >> 8u) & 0xFFu, (p >> 16u) & 0xFFu, (p >> 24u) & 0xFFu)) * (1.0 / 255.0);
}

// Packs two 16-bit UNORM [0.0, 1.0] values into a 32-bit unsigned integer
uint packUnorm2x16(in vec2 v){
	uvec2 u = uvec2(round(saturate(v) * 65535.0));
	return u.x | (u.y << 16u);
}

// Unpacks a 32-bit unsigned integer into two 16-bit UNORM [0.0, 1.0] values
vec2 unpackUnorm2x16(in uint p){
	return vec2(uvec2(p & 0xFFFFu, (p >> 16u) & 0xFFFFu)) * (1.0 / 65535.0);
}

// Packs 16-level Minecraft lightmap (block light, sky light) into a single 8-bit UNORM float
float packLightmap(in vec2 lm){
	return dot(floor(saturate(lm) * 15.0 + 0.5), vec2(1.0, 16.0)) * (1.0 / 255.0);
}

// Unpacks a single 8-bit UNORM float into 16-level Minecraft lightmap coordinates
vec2 unpackLightmap(in float p){
	float val = floor(p * 255.0 + 0.5);
	return vec2(mod(val, 16.0), floor(val * (1.0 / 16.0))) * (1.0 / 15.0);
}

// Packs metallic, smoothness, and a 4-bit material mask into a single 32-bit unsigned integer
uint packMaterialData(in float metallic, in float smoothness, in float mask){
	uint m = uint(round(saturate(metallic) * 255.0));
	uint s = uint(round(saturate(smoothness) * 255.0));
	uint f = uint(round(saturate(mask) * 15.0));
	return m | (s << 8u) | (f << 16u);
}

// Unpacks a 32-bit integer into metallic, smoothness, and material mask
void unpackMaterialData(in uint p, out float metallic, out float smoothness, out float mask){
	metallic = float(p & 0xFFu) * (1.0 / 255.0);
	smoothness = float((p >> 8u) & 0xFFu) * (1.0 / 255.0);
	mask = float((p >> 16u) & 0x0Fu) * (1.0 / 15.0);
}
