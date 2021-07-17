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
    uniform sampler2D depthtex1;
    uniform sampler2D gcolor;
    uniform sampler2D colortex1;
    uniform sampler2D colortex2;
    uniform sampler2D colortex3;
    uniform sampler2D colortex4;

    #ifdef PREVIOUS_FRAME
        // Reflections
        uniform sampler2D colortex5;
    #endif

    #include "/lib/globalVars/gameUniforms.glsl"
    #include "/lib/globalVars/matUniforms.glsl"
    #include "/lib/globalVars/posUniforms.glsl"
    #include "/lib/globalVars/screenUniforms.glsl"
    #include "/lib/globalVars/timeUniforms.glsl"
    #include "/lib/globalVars/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"
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

        #ifdef PREVIOUS_FRAME
            // Get previous frame buffer
            vec3 reflectBuffer = 1.0 / (1.0 - texture2D(colortex5, posVector.screenPos.xy).rgb) - 1.0;
        #endif

        vec2 masks4 = texture2D(colortex4, posVector.screenPos.xy).xy;
        bool cloudMask = masks4.y == 0;
        bool skyMask = posVector.screenPos.z == 1;

        // If the object is transparent render lighting sperately
        if(posVector.viewPos.z - toView(texture2D(depthtex1, posVector.screenPos.xy).r) > 0.01){
            // Get sky color
            vec3 skyRender = getSkyRender(posVector.eyePlayerPos, skyCol, lightCol, 1.0, 1.0, skyMask);

            if(cloudMask) sceneCol = complexShadingDeferred(material, posVector, sceneCol, dither);

            // Fog calculation
            sceneCol = getFogRender(posVector.eyePlayerPos, sceneCol, skyRender, posVector.worldPos.y / 256.0, cloudMask, skyMask);
        }

        #ifdef PREVIOUS_FRAME
            // Assign after main lighting calculation
            reflectBuffer = sceneCol;
        #endif

    /* DRAWBUFFERS:024 */
        gl_FragData[0] = vec4(sceneCol, 1); //gcolor
        // Clear buffer before downscaling
        gl_FragData[1] = vec4(0); //colortex2
        gl_FragData[2] = vec4(masks4.x, getGodRays(posVector.feetPlayerPos, posVector.worldPos.y / 128.0, dither.x)); //colortex4
        #ifdef PREVIOUS_FRAME
        /* DRAWBUFFERS:0245 */
            gl_FragData[3] = vec4(reflectBuffer / (1.0 + reflectBuffer), 1); //colortex5
        #endif
    }
#endif