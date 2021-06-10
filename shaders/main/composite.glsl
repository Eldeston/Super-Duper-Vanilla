#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/gameUniforms.glsl"
#include "/lib/globalVars/matUniforms.glsl"
#include "/lib/globalVars/posUniforms.glsl"
#include "/lib/globalVars/screenUniforms.glsl"
#include "/lib/globalVars/texUniforms.glsl"
#include "/lib/globalVars/timeUniforms.glsl"
#include "/lib/globalVars/universalVars.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/utility/spaceConvert.glsl"
#include "/lib/utility/texFunctions.glsl"
#include "/lib/rayTracing/rayTracer.glsl"

#include "/lib/atmospherics/fog.glsl"
#include "/lib/atmospherics/sky.glsl"

#include "/lib/lighting/shdMapping.glsl"
#include "/lib/lighting/GGX.glsl"
#include "/lib/lighting/SSR.glsl"
#include "/lib/lighting/SSGI.glsl"
#include "/lib/rayTracing/volLight.glsl"
#include "/lib/post/outline.glsl"

#include "/lib/lighting/complexShading.glsl"

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

        // If the object is transparent render lighting sperately
        if(materials.alpha_m != 1){
            vec3 dither = getRand3(texcoord, 8);
            float mask = float(posVector.screenPos.z == 1);
            float cloudMask = texture2D(colortex4, texcoord).g;

            // Get sky color
            vec3 skyRender = getSkyRender(posVector.eyePlayerPos, skyCol, lightCol, mask, 1.0, dither.r);

            // Apply lighting
            materials.albedo_t = complexShading(materials, posVector, dither);
            materials.albedo_t = materials.albedo_t * (1.0 - mask) + skyRender * mask; // Mask out the sky

            #ifdef OUTLINES
                /* Outline calculation */
                materials.albedo_t *= 1.0 + getOutline(depthtex0, texcoord, OUTLINE_PIX_SIZE) * (OUTLINE_BRIGHTNESS - 1.0);
            #endif

            // Apply atmospherics
            if(mask != 1) materials.albedo_t = getFog(posVector.eyePlayerPos, materials.albedo_t, skyRender, posVector.worldPos.y, cloudMask);
            reflectBuffer = materials.albedo_t; // Assign current scene color WITHOUT the godrays...
            
            #ifdef VOL_LIGHT
                materials.albedo_t += getGodRays(posVector.feetPlayerPos, posVector.worldPos.y, dither.y) * lightCol;
            #endif
        }

    /* DRAWBUFFERS:05 */
        gl_FragData[0] = vec4(materials.albedo_t, 1); //gcolor
        // Apparently I have to transform it to 0-1 range then back to HDR with the reflection buffer due to an annoying bug...
        gl_FragData[1] = vec4(reflectBuffer / (reflectBuffer + 1.0), 1); //colortex5
    }
#endif