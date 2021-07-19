#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    #ifdef ROUGH_REFLECTIONS
        #ifdef PREVIOUS_FRAME
            const bool colortex5MipmapEnabled = true;
        #else
            const bool gcolorMipmapEnabled = true;
        #endif
    #endif

    #ifdef PREVIOUS_FRAME
        const bool colortex5Clear = false;
    #endif

    uniform sampler2D depthtex0;
    uniform sampler2D gcolor;
    uniform sampler2D colortex1;
    uniform sampler2D colortex2;
    uniform sampler2D colortex3;

    #ifdef PREVIOUS_FRAME
        // Reflections
        uniform sampler2D colortex5;
    #endif

    #include "/lib/globalVars/matUniforms.glsl"
    #include "/lib/globalVars/posUniforms.glsl"
    #include "/lib/globalVars/screenUniforms.glsl"
    #include "/lib/globalVars/timeUniforms.glsl"
    #include "/lib/globalVars/gameUniforms.glsl"
    #include "/lib/globalVars/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"
    #include "/lib/rayTracing/rayTracer.glsl"

    #include "/lib/atmospherics/fog.glsl"
    #include "/lib/atmospherics/sky.glsl"

    #include "/lib/lighting/GGX.glsl"
    #include "/lib/lighting/SSR.glsl"
    #include "/lib/lighting/SSGI.glsl"
    #include "/lib/post/outline.glsl"

    #include "/lib/lighting/complexShadingDeferred.glsl"

    #include "/lib/assemblers/PBRAssembler.glsl"
    #include "/lib/assemblers/posAssembler.glsl"

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = toScreenSpacePos(screenCoord);
	    getPosVectors(posVector);

	    // Declare and get materials
	    matPBR material;
	    getPBR(material, posVector.screenPos.xy);

        vec3 sceneCol = texture2D(gcolor, posVector.screenPos.xy).rgb;

        vec3 dither = getRand3(posVector.screenPos.xy, 8);
        // Render lighting
        bool skyMask = posVector.screenPos.z == 1;

        // Get sky color
        vec3 skyRender = getSkyRender(posVector.eyePlayerPos, skyCol, lightCol, 1.0, 1.0, skyMask);

        sceneCol = complexShadingDeferred(material, posVector, sceneCol, dither);

        #ifdef OUTLINES
            /* Outline calculation */
            sceneCol *= 1.0 + getOutline(depthtex0, posVector.screenPos, OUTLINE_PIX_SIZE) * (OUTLINE_BRIGHTNESS - 1.0);
        #endif

        // Fog calculation
        sceneCol = getFogRender(posVector.eyePlayerPos, sceneCol, skyRender, posVector.worldPos.y / 256.0, false, skyMask);

        #ifdef PREVIOUS_FRAME
            // Get previous frame buffer
            vec3 reflectBuffer = sceneCol;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); //gcolor

        #ifdef PREVIOUS_FRAME
        /* DRAWBUFFERS:05 */
            gl_FragData[1] = vec4(reflectBuffer / (1.0 + reflectBuffer), 1); //colortex5
        #endif
    }
#endif