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
    uniform sampler2D depthtex1;
    uniform sampler2D gcolor;
    uniform sampler2D colortex1;
    uniform sampler2D colortex2;
    uniform sampler2D colortex3;
    uniform sampler2D colortex4;
    
    #ifdef STORY_MODE_CLOUDS
        uniform sampler2D colortex7;
    #endif

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

    // Shadow projection matrix uniforms
    uniform mat4 shadowProjection;

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

    #include "/lib/universalVars.glsl"

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

    #include "/lib/lighting/complexShadingDeferred.glsl"
    
    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(screenCoord, texture2D(depthtex0, screenCoord).x);
        posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;
        posVector.feetPlayerPos = posVector.eyePlayerPos + gbufferModelViewInverse[3].xyz;
        posVector.worldPos = posVector.feetPlayerPos + cameraPosition;

        vec3 sceneCol = texture2D(gcolor, screenCoord).rgb;

        #ifdef TEMPORAL_ACCUMULATION
            vec3 dither = toRandPerFrame(getRand3(screenCoord, 8), frameTimeCounter);
        #else
            vec3 dither = getRand3(screenCoord, 8);
        #endif

        #ifdef PREVIOUS_FRAME
            // Get previous frame buffer
            vec3 reflectBuffer = 1.0 / (1.0 - texture2D(colortex5, screenCoord).rgb) - 1.0;
        #endif

        vec2 masks4 = texture2D(colortex4, screenCoord).xy;
        bool skyMask = posVector.screenPos.z == 1;

        // If not sky, don't calculate lighting
        if(!skyMask){
            // If the object is transparent render lighting sperately
            if(posVector.viewPos.z - toView(texture2D(depthtex1, screenCoord).r) > 0.01){
                // Declare and get materials
                matPBR material;
                material.albedo = texture2D(colortex2, screenCoord);
                material.normal = texture2D(colortex1, screenCoord).rgb * 2.0 - 1.0;

                vec3 matRaw0 = texture2D(colortex3, screenCoord).xyz;
                material.metallic = matRaw0.x; material.emissive = matRaw0.y; material.smoothness = matRaw0.z;

                // Get cloud mask
                bool cloudMask = masks4.y != 0;

                if(!cloudMask) sceneCol = complexShadingDeferred(material, posVector, sceneCol, dither);

                // Get sky color
                vec3 skyRender = getSkyRender(posVector.eyePlayerPos, skyMask);

                // Fog calculation
                sceneCol = getFogRender(posVector.eyePlayerPos, sceneCol, skyRender, posVector.worldPos.y, cloudMask, skyMask);

                #ifdef PREVIOUS_FRAME
                    // Assign after main lighting calculation
                    reflectBuffer = sceneCol;
                #endif
            }
        }

    /* DRAWBUFFERS:04 */
        gl_FragData[0] = vec4(sceneCol, 1); //gcolor
        gl_FragData[1] = vec4(getGodRays(posVector.feetPlayerPos, posVector.worldPos.y, dither.x), masks4.x); //colortex4
        #ifdef PREVIOUS_FRAME
        /* DRAWBUFFERS:045 */
            gl_FragData[2] = vec4(reflectBuffer / (1.0 + reflectBuffer), 1); //colortex5
        #endif
    }
#endif