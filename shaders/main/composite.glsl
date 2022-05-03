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

    #include "/lib/universalVars.glsl"

    // Get night vision
    uniform float nightVision;

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/convertScreenSpace.glsl"
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
        vec3 screenPos = vec3(screenCoord, texture2D(depthtex0, screenCoord).x);
        vec3 viewPos = toView(screenPos);
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

        // Get scene color
        vec3 sceneCol = texture2D(gcolor, screenCoord).rgb;

        #if ANTI_ALIASING == 2
            vec3 dither = toRandPerFrame(getRand3(gl_FragCoord.xy * 0.03125), frameTimeCounter);
        #else
            vec3 dither = getRand3(gl_FragCoord.xy * 0.03125);
        #endif

        // If the object is a transparent render separate lighting
        if(texture2D(depthtex1, screenCoord).x > screenPos.z){
            // Declare and get materials
            vec2 matRaw0 = texture2D(colortex3, screenCoord).xy;

            // Apply deffered shading
            sceneCol = complexShadingDeferred(screenPos, viewPos, eyePlayerPos, texture2D(colortex1, screenCoord).rgb * 2.0 - 1.0, texture2D(colortex2, screenCoord).rgb, sceneCol, matRaw0.x, matRaw0.y, dither);

            // Fog and sky calculation
            sceneCol = getFogRender(eyePlayerPos, sceneCol, getSkyRender(vec3(0), normalize(eyePlayerPos), false), feetPlayerPos.y + cameraPosition.y, false);
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor

        #ifdef WORLD_LIGHT
        /* DRAWBUFFERS:04 */
            gl_FragData[1] = vec4(getGodRays(feetPlayerPos, dither.x), 1); //colortex4
            
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