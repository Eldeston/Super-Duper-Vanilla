/* Unused, needs to be worked on */

uniform float celestialCosX;
uniform float celestialSinX;

// World space to celestial space
vec3 getCelestialPos(in vec3 eyePlayerPos, in float sinAxisX, in float cosAxisX){
    // vec3 celestialPos = eyePlayerPos.zyx;
    // celestialPos.xy = celestialRotationZ * celestialPos.xy;
    // celestialPos.yz = mat2(cosAxisX, sinAxisX, -sinAxisX, cosAxisX) * celestialPos.yz;

    // vec3 celestialPos = mat3(shadowModelView) * nEyePlayerPos;

    vec2 zCoord = vec2(
        eyePlayerPos.z * celestialCosZ - eyePlayerPos.y * celestialSinZ,
        eyePlayerPos.z * celestialSinZ + eyePlayerPos.y * celestialCosZ
        // dot(eyePlayerPos.zy, vec2(celestialCosZ, -celestialSinZ)),
        // dot(eyePlayerPos.zy, vec2(celestialSinZ, celestialCosZ))
    );

    vec2 xCoord = vec2(
        zCoord.y * cosAxisX - eyePlayerPos.x * sinAxisX,
        zCoord.y * sinAxisX + eyePlayerPos.x * cosAxisX
        // dot(vec2(zCoord.y, eyePlayerPos.x), vec2(cosAxisX, -sinAxisX)),
        // dot(vec2(zCoord.y, eyePlayerPos.x), vec2(sinAxisX, cosAxisX))
    );

    return vec3(zCoord.x, xCoord);
}

// getCelestialPos(vertexShadowFeetPlayerPos.xyz, celestialSinX, celestialCosX)

/*
mat3(
    0, -celestialSinX, celestialCosX,
    -celestialSinZ, celestialCosZ * celestialCosX, celestialCosZ * celestialSinX,
    celestialCosZ, celestialSinZ * celestialCosX, celestialSinZ * celestialSinX
)
*/

/*
mat3(
    0, 0, 0
    0, 0,    cos(z) * cos(x), sin(z) * -cos(x)
    -sin(z), cos(z) * cos(x), cos(z) * -cos(x)
)

mat3(
    cos(z) , -sin(z) * cos(x) ,  sin(z) * sin(x)
    sin(z) ,  cos(z) * cos(x) , -cos(z) * sin(x)
    0      ,  sin(x)          ,  cos(x)
)

vec3(-sin(Z),
    cos(Z) * cos(X),
    cos(Z) * -sin(X)
)
*/