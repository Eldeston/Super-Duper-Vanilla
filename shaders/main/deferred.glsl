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

#include "/lib/lighting/complexShadingDeferred.glsl"

#include "/lib/assemblers/PBRAssembler.glsl"
#include "/lib/assemblers/posAssembler.glsl"

INOUT vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        // Declare and get positions
        positionVectors posVector;
	    getPosVectors(posVector, screenCoord);

	    // Declare and get materials
	    matPBR materials;
	    getPBR(materials, screenCoord);

        vec3 sceneCol = texture2D(gcolor, screenCoord).rgb;

        // Render lighting
        vec3 dither = getRand3(screenCoord, 8);
        float skyMask = float(posVector.screenPos.z == 1);

        // Get sky color
        vec3 skyRender = getSkyRender(posVector.eyePlayerPos, skyCol, lightCol, skyMask, 1.0, 1.0);

        sceneCol = complexShadingDeferred(materials, posVector, sceneCol, dither);

        #ifdef OUTLINES
            /* Outline calculation */
            sceneCol *= 1.0 + getOutline(depthtex0, screenCoord, OUTLINE_PIX_SIZE) * (OUTLINE_BRIGHTNESS - 1.0);
        #endif

        // Fog calculation
        sceneCol = getFog(posVector.eyePlayerPos, sceneCol, skyRender, posVector.worldPos.y, skyMask, 0.0);

        #ifdef VOL_LIGHT
            sceneCol += getGodRays(posVector.feetPlayerPos, posVector.worldPos.y, dither.y) * lightCol;
        #endif

    /* DRAWBUFFERS:04 */
        gl_FragData[0] = vec4(sceneCol, 1); //gcolor
        gl_FragData[1] = vec4(materials.ambient_m, 0, 1, 1); //colortex4
    }
#endif