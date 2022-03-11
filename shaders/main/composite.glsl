#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/structs.glsl"

varying vec2 screenCoord;

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
    
    #if defined STORY_MODE_CLOUDS && !defined FORCE_DISABLE_CLOUDS
        uniform sampler2D colortex4;
    #endif

    /* Matrix uniforms */
    // View matrix uniforms
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    // Projection matrix uniforms
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferProjectionInverse;

    // Shadow view matrix uniforms
    uniform mat4 shadowModelView;

    #if defined WORLD_LIGHT && defined SHD_ENABLE
        // Shadow projection matrix uniforms
        uniform mat4 shadowProjection;
    #endif

    /* Position uniforms */
    uniform vec3 cameraPosition;

    #ifdef PREVIOUS_FRAME
        // Previous reflections
        uniform sampler2D colortex5;
        const bool colortex5Clear = false;

        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;

        uniform vec3 previousCameraPosition;

        #include "/lib/utility/convertPrevScreenSpace.glsl"
    #endif

    /* Time uniforms */
    // Get frame time
    uniform float frameTimeCounter;

    uniform float blindness;
    uniform float far;

    #include "/lib/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/convertScreenSpace.glsl"
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

        vec3 sceneCol = texture2D(gcolor, screenCoord).rgb;

        #if ANTI_ALIASING == 2
            vec3 dither = toRandPerFrame(getRand3(gl_FragCoord.xy * 0.03125), frameTimeCounter);
        #else
            vec3 dither = getRand3(gl_FragCoord.xy * 0.03125);
        #endif

        // If not sky, don't calculate lighting
        if(posVector.screenPos.z != 1){
            // If the object is transparent render lighting sperately
            if(texture2D(depthtex1, screenCoord).x > posVector.screenPos.z){
                // Declare and get materials
                matPBR material;
                material.albedo = texture2D(colortex2, screenCoord);
                material.normal = texture2D(colortex1, screenCoord).rgb * 2.0 - 1.0;

                vec2 matRaw0 = texture2D(colortex3, screenCoord).xy;
                material.metallic = matRaw0.x; material.smoothness = matRaw0.y;

                sceneCol = complexShadingDeferred(material, posVector, sceneCol, dither);

                // Get sky color
                vec3 skyRender = getSkyRender(vec3(0), normalize(posVector.eyePlayerPos), false);

                // Fog calculation
                sceneCol = getFogRender(posVector.eyePlayerPos, sceneCol, skyRender, posVector.feetPlayerPos.y + cameraPosition.y, false);
            }
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); //gcolor

        #ifdef WORLD_LIGHT
        /* DRAWBUFFERS:04 */
            gl_FragData[1] = vec4(getGodRays(posVector.feetPlayerPos, dither.x), 1); //colortex4
            
            #ifdef PREVIOUS_FRAME
            /* DRAWBUFFERS:045 */
                gl_FragData[2] = vec4(sceneCol, 1); //colortex5
            #endif
        #else
            #ifdef PREVIOUS_FRAME
            /* DRAWBUFFERS:05 */
                gl_FragData[1] = vec4(sceneCol, 1); //colortex5
            #endif
        #endif
    }
#endif