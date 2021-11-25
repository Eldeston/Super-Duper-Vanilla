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
    uniform sampler2D depthtex0;
    uniform sampler2D gcolor;
    uniform sampler2D colortex1;
    uniform sampler2D colortex2;
    uniform sampler2D colortex3;

    #ifdef PREVIOUS_FRAME
        // Previous reflections
        uniform sampler2D colortex5;
        const bool colortex5Clear = false;
    #endif

    /* Matrix uniforms */
    // View matrix uniforms
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferPreviousModelView;

    // Projection matrix uniforms
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferPreviousProjection;

    // Shadow view matrix uniforms
    uniform mat4 shadowModelView;
    uniform mat4 shadowModelViewInverse;

    // Shadow projection matrix uniforms
    uniform mat4 shadowProjection;
    uniform mat4 shadowProjectionInverse;

    /* Position uniforms */
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;

    /* Screen uniforms */
    uniform float viewWidth;
    uniform float viewHeight;

    /* Time uniforms */
    // Get frame time
    uniform int frameCounter;

    uniform float frameTime;
    uniform float frameTimeCounter;

    // Get world time
    uniform float day;
    uniform float night;
    uniform float dawnDusk;
    uniform float twilight;

    /* Game uniforms */
    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float blindness;
    uniform float rainStrength;
    uniform float far;

    uniform ivec2 eyeBrightnessSmooth;

    uniform vec3 fogColor;
    
    #include "/lib/globalVars/universalVars.glsl"

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

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = toScreenSpacePos(screenCoord);
        posVector.clipPos = posVector.screenPos * 2.0 - 1.0;
        posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;
        posVector.feetPlayerPos = posVector.eyePlayerPos + gbufferModelViewInverse[3].xyz;
        posVector.worldPos = posVector.feetPlayerPos + cameraPosition;

        vec3 sceneCol = texture2D(gcolor, posVector.screenPos.xy).rgb;

        // Render lighting
        bool skyMask = posVector.screenPos.z == 1;

        // Get sky color
        vec3 skyRender = getSkyRender(posVector.eyePlayerPos, true, skyMask, skyMask);

        // Vanilla sun and moon texture
        #if defined USE_SUN_MOON && defined VANILLA_SUN_MOON
            if(skyMask) skyRender += texture2D(colortex2, posVector.screenPos.xy).rgb * PI;
        #endif

        // If not sky, don't calculate lighting
        if(!skyMask){
            // Declare and get materials
            matPBR material;
            getPBR(material, posVector.screenPos.xy);

            #ifdef TEMPORAL_ACCUMULATION
                vec3 dither = toRandPerFrame(getRand3(posVector.screenPos.xy, 8));
            #else
                vec3 dither = getRand3(posVector.screenPos.xy, 8);
            #endif

            sceneCol = complexShadingDeferred(material, posVector, sceneCol, dither);

            #ifdef OUTLINES
                /* Outline calculation */
                sceneCol *= 1.0 + getOutline(depthtex0, posVector.screenPos, OUTLINE_PIX_SIZE) * (OUTLINE_BRIGHTNESS - 1.0);
            #endif
        }

        // Fog calculation
        sceneCol = getFogRender(posVector.eyePlayerPos, sceneCol, skyRender, posVector.worldPos.y, false, skyMask);

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