// For Physics Mod support: https://github.com/haubna/PhysicsMod/blob/main/oceans.glsl

// just some basic consts for the wave function based on afl_ext's shader https://www.shadertoy.com/view/Xdlczl
// the overall shape must stay consistent because it is also computed on the CPU side
// to offset entities (though a custom CPU integration of your shader is possible by
// contacting me on my discord server https://discord.gg/VsNs9xP)

// this is the surface detail from the physics options, ranges from 13 to 48 (yeah I know weird)
// uniform int physics_iterationsNormal;
// used to offset the 0 point of wave meshes to keep the wave function consistent even
// though the mesh totally changes
uniform vec2 physics_waveOffset;
// used for offsetting the local position to fetch the right pixel of the waviness texture
uniform ivec2 physics_textureOffset;
// time in seconds that can go faster dependent on weather conditions (affected by weather strength
// multiplier in ocean settings
uniform float physics_gameTime;
// base value is 13 and gets multiplied by wave height in ocean settings
uniform float physics_oceanHeight;
// basic texture to determine how shallow/far away from the shore the water is
uniform sampler2D physics_waviness;
// basic scale for the horizontal size of the waves
uniform float physics_oceanWaveHorizontalScale;
// used to offset the model to know the ripple position
// uniform vec3 physics_modelOffset;
// used for offsetting the ripple texture
// uniform float physics_rippleRange;
// controlling how much foam generates on the ocean
// uniform float physics_foamAmount;
// controlling the opacity of the foam
// uniform float physics_foamOpacity;
// texture containing the ripples (basic bump map)
// uniform sampler2D physics_ripples;
// foam noise
// uniform sampler3D physics_foam;
// just the generic minecraft lightmap, you can remove this and use the one supplied by Optifine/Iris
// uniform sampler2D physics_lightmap;

float physics_waveHeight(in vec2 position, in float factor){
    float iter = 0.0;
    float frequency = PHYSICS_FREQUENCY;
    float speed = PHYSICS_SPEED;
    float weight = 1.0;
    float height = 0.0;
    float waveSum = 0.0;
    float modifiedTime = physics_gameTime * PHYSICS_TIME_MULTIPLICATOR;
    
    for(int i = 0; i < PHYSICS_ITERATIONS_OFFSET; i++){
        vec2 direction = vec2(sin(iter), cos(iter));

        float x = dot(direction, position) * frequency + modifiedTime * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);

        vec2 force = result * weight * direction;
        
        position -= force * PHYSICS_DRAG_MULT;
        height += wave * weight;
        iter += PHYSICS_ITER_INC;
        waveSum += weight;
        weight *= PHYSICS_WEIGHT;
        frequency *= PHYSICS_FREQUENCY_MULT;
        speed *= PHYSICS_SPEED_MULT;
    }
    
    return height / waveSum * physics_oceanHeight * factor - physics_oceanHeight * factor * 0.5;
}

/*
// VERTEX STAGE
void main(){
    // pass this to the fragment shader to fetch the texture there for per fragment normals
    physics_localPosition = (gl_Vertex.xz - physics_waveOffset) * PHYSICS_XZ_SCALE * physics_oceanWaveHorizontalScale;

    // basic texture to determine how shallow/far away from the shore the water is
    physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

    // transform gl_Vertex (since it is the raw mesh, i.e. not transformed yet)
    vertexPos.y += physics_waveHeight(physics_localPosition, physics_localWaviness);
    
    // now use finalPosition instead of gl_Vertex
}
*/