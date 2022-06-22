/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    out vec2 screenCoord;

    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    in vec2 screenCoord;

    #if ANTI_ALIASING >= 2 || defined PREVIOUS_FRAME || defined AUTO_EXPOSURE
        // Disable buffer clear if TAA, previous frame reflections, or auto exposure is on
        const bool colortex5Clear = false;
    #endif
    
    // Sky silhoutte fix
    const vec4 gcolorClearColor = vec4(0, 0, 0, 1);

    uniform sampler2D depthtex0;
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

    /* Position uniforms */
    uniform vec3 cameraPosition;

    #ifdef PREVIOUS_FRAME
        // Previous reflections
        uniform sampler2D colortex5;

        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;

        uniform vec3 previousCameraPosition;

        #include "/lib/utility/convertPrevScreenSpace.glsl"
    #endif

    #if defined SSAO || ANTI_ALIASING == 3
        /* Screen uniforms */
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #ifdef SSAO
        float getSSAOBoxBlur(ivec2 iUv){
            // Apply simple box blur
            return (texelFetch(colortex2, iUv - 1, 0).a + texelFetch(colortex2, iUv + 1, 0).a +
                texelFetch(colortex2, iUv - ivec2(1, -1), 0).a + texelFetch(colortex2, iUv + ivec2(1, -1), 0).a) * 0.25;
        }
    #endif

    #if ANTI_ALIASING == 3
        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;
    #endif

    /* Time uniforms */
    // Get frame time
    uniform float frameTimeCounter;

    // Get is eye in water
    uniform int isEyeInWater;

    // Get night vision
    uniform float nightVision;

    #include "/lib/universalVars.glsl"

    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/convertScreenSpace.glsl"
    #include "/lib/utility/noiseFunctions.glsl"
    #include "/lib/rayTracing/rayTracer.glsl"

    #include "/lib/atmospherics/fog.glsl"
    #include "/lib/atmospherics/sky.glsl"

    #include "/lib/lighting/GGX.glsl"
    #include "/lib/lighting/SSR.glsl"
    #include "/lib/lighting/SSGI.glsl"

    #include "/lib/post/outline.glsl"

    #include "/lib/lighting/complexShadingDeferred.glsl"

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Declare and get positions
        vec3 screenPos = vec3(screenCoord, texelFetch(depthtex0, screenTexelCoord, 0).x);
        
        // Get sky mask
        bool skyMask = screenPos.z == 1;

        // Jitter the sky only
        #if ANTI_ALIASING == 3
            if(skyMask) screenPos.xy += jitterPos(-0.5);
        #endif
        
        vec3 viewPos = toView(screenPos);
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

        // Get view distance
        float viewDist = length(viewPos);
        // Get normalized eyePlayerPos
        vec3 nEyePlayerPos = eyePlayerPos / viewDist;
        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        // Get sRGB light color
        #ifdef WORLD_LIGHT
            vec3 sRGBLightCol = LIGHT_COL_DATA_BLOCK;
            vec3 lightCol = pow(sRGBLightCol, vec3(GAMMA));
        #else
            vec3 sRGBLightCol = vec3(0);
            vec3 lightCol = vec3(0);
        #endif
        // Get linear sky color
        vec3 skyCol = pow(SKY_COL_DATA_BLOCK, vec3(GAMMA));

        // If sky, don't calculate lighting
        if(!skyMask){
            #if ANTI_ALIASING >= 2
                vec3 dither = toRandPerFrame(getRand3(screenTexelCoord & 255), frameTimeCounter);
            #else
                vec3 dither = getRand3(screenTexelCoord & 255);
            #endif

            // Declare and get materials
            vec2 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xy;
            vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).rgb * 2.0 - 1.0;
            vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;

            // Apply deffered shading
            sceneCol = complexShadingDeferred(sceneCol, skyCol, lightCol, screenPos, viewPos, nEyePlayerPos, normal, albedo, matRaw0.x, matRaw0.y, dither);

            #ifdef SSAO
                // Apply ambient occlusion with simple blur
                sceneCol *= getSSAOBoxBlur(screenTexelCoord);
            #endif

            #if OUTLINES != 0
                // Outline calculation
                sceneCol *= 1.0 + getOutline(screenTexelCoord, viewPos.z, OUTLINE_PIX_SIZE) * (OUTLINE_BRIGHTNESS - 1.0);
            #endif
        }

        // Fog and sky calculation
        // Get skyCol as our fogCol. If sky, then do full sky render. Otherwise, do basic sky render.
        if(skyMask) sceneCol = getSkyRender(sceneCol, skyCol, sRGBLightCol, lightCol, nEyePlayerPos, true) * exp(-far * blindness * 0.375);
        else sceneCol = getFogRender(sceneCol, getSkyRender(skyCol, lightCol, nEyePlayerPos, false, false), viewDist, nEyePlayerPos.y, eyePlayerPos.y + gbufferModelViewInverse[3].y + cameraPosition.y);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif