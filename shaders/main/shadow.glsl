#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

uniform float frameTimeCounter;

varying float blockId;

varying vec2 texCoord;

varying vec3 worldPos;
varying vec3 glcolor;

#ifdef VERTEX
    #if TIMELAPSE_MODE == 2
        uniform float animationFrameTime;

        float newFrameTimeCounter = animationFrameTime;
    #else
        float newFrameTimeCounter = frameTimeCounter;
    #endif

    uniform mat4 shadowModelView;
    uniform mat4 shadowModelViewInverse;
    uniform mat4 shadowProjection;
    uniform mat4 shadowProjectionInverse;
    
    uniform vec3 cameraPosition;

    #include "/lib/lighting/shdDistort.glsl"

    #include "/lib/vertex/vertexWave.glsl"

    attribute vec2 mc_midTexCoord;
    attribute vec4 mc_Entity;

    void main(){
        vec4 vertexPos = shadowModelViewInverse * (shadowProjectionInverse * ftransform());
        worldPos = vertexPos.xyz + cameraPosition;

        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        blockId = mc_Entity.x;
        
        #ifdef ANIMATE
            getWave(vertexPos.xyz, worldPos, texCoord, mc_midTexCoord, mc_Entity.x, (gl_TextureMatrix[1] * gl_MultiTexCoord1).y);
        #endif

        #ifdef WORLD_CURVATURE
            vertexPos.y -= lengthSquared(vertexPos.xz) / WORLD_CURVATURE_SIZE;
        #endif

        gl_Position = shadowProjection * (shadowModelView * vertexPos);

        gl_Position.xyz = distort(gl_Position.xyz);

        glcolor = gl_Color.rgb;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D tex;

    #if UNDERWATER_CAUSTICS == 1
        uniform int isEyeInWater;
    #endif
    
    #if UNDERWATER_CAUSTICS != 0
        #if TIMELAPSE_MODE != 0
            uniform float animationFrameTime;

            float newFrameTimeCounter = animationFrameTime;
        #else
            float newFrameTimeCounter = frameTimeCounter;
        #endif

        #include "/lib/utility/texFunctions.glsl"
        #include "/lib/utility/noiseFunctions.glsl"
        #include "/lib/surface/water.glsl"
    #endif

    void main(){
        vec4 shdColor = texture2D(tex, texCoord);
        shdColor.rgb = pow(shdColor.rgb * glcolor, vec3(GAMMA));

        #if UNDERWATER_CAUSTICS == 2
            if(int(blockId + 0.5) == 10001) shdColor.rgb *= vec3(cubed(0.128 + getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 16.0);
        #elif UNDERWATER_CAUSTICS == 1
            if(isEyeInWater == 1 && int(blockId + 0.5) == 10001) shdColor.rgb *= vec3(cubed(0.128 + getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 16.0);
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = shdColor;
    }
#endif