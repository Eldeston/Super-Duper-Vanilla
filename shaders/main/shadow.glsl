#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

uniform float frameTimeCounter;

INOUT float blockId;

INOUT vec2 texcoord;

INOUT vec3 worldPos;
INOUT vec3 gcolor;

#ifdef VERTEX
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

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        blockId = mc_Entity.x;
        
        #ifdef ANIMATE
            getWave(vertexPos.xyz, worldPos, texcoord, mc_midTexCoord, mc_Entity.x, (gl_TextureMatrix[1] * gl_MultiTexCoord1).y);
        #endif

        gl_Position = shadowProjection * (shadowModelView * vertexPos);

        gl_Position.xyz = distort(gl_Position.xyz);

        #ifndef RENDER_FOLIAGE_SHD
            if(mc_Entity.x >= 10001 || mc_Entity.x <= 10004 || mc_Entity.x == 10007 || mc_Entity.x == 10008)
                gl_Position = vec4(10);
        #endif

        gcolor = gl_Color.rgb;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D tex;
    
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    void main(){
        vec4 shdColor = texture2D(tex, texcoord);
        shdColor.rgb = shdColor.rgb * gcolor;

        #ifdef UNDERWATER_CAUSTICS
            int rBlockId = int(blockId + 0.5);
            if(rBlockId == 10014){
                #ifdef INVERSE
                    float waterData = squared(getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 16.0;
                #else
                    float waterData = squared(1.0 - getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 16.0;
                #endif
                
                shdColor.rgb = shdColor.rgb / 2.0;
                shdColor.rgb = shdColor.rgb * (1.0 + waterData);
            }
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = shdColor;
    }
#endif