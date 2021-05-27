#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"
#include "/lib/lighting/shdDistort.glsl"
#include "/lib/conversion.glsl"

#include "/lib/atmospherics/fog.glsl"
#include "/lib/atmospherics/sky.glsl"

#include "/lib/lighting/GGX.glsl"
#include "/lib/lighting/shdMapping.glsl"

#include "/lib/raymarching/rayTracer.glsl"
#include "/lib/raymarching/volLighting.glsl"

#include "/lib/lighting/SSGI.glsl"
#include "/lib/lighting/SSR.glsl"

#include "/lib/lighting/complexLighting.glsl"

#include "/lib/varAssembler.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        // Declare and get positions
        positionVectors posVector;
	    getPosVectors(posVector, texcoord);

	    // Declare and get materials
	    matPBR materials;
	    getMaterial(materials, texcoord);

        // Transform the color back to HDR
        vec3 reflectBuffer = 1.0 / (1.0 - texture2D(colortex5, texcoord).rgb) - 1.0;
        vec3 finalCol = texture2D(colortex8, texcoord).rgb;

        // If the object is opaque render lighting sperately
        if(materials.alpha_m == 1){
            vec3 dither = getRand3(texcoord, 8);
            float mask = float(posVector.screenPos.z == 1);
            
            // Get sky color
            vec3 skyRender = getSkyRender(posVector.eyePlayerPos, mask, skyCol, lightCol);

            // Apply lighting
            finalCol = complexLighting(materials, posVector, dither);
            finalCol *= 1.0 - mask; // Mask out the sky

            // Apply atmospherics
            finalCol = getFog(posVector, finalCol, skyRender);
        }

    /* DRAWBUFFERS:5 */
        // Apparently I have to transform it to 0-1 range then back to HDR with the reflection buffer due to an annoying bug...
        gl_FragData[0] = vec4(finalCol / (finalCol + 1.0), 1); //colortex5
    }
#endif