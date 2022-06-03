varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
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

    #if defined SSAO || defined OUTLINES || ANTI_ALIASING == 3
        /* Screen uniforms */
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #ifdef SSAO
        float getSSAOBoxBlur(vec2 pixSize){
            // Apply simple box blur
            return (texture2D(colortex2, screenCoord - pixSize).a + texture2D(colortex2, screenCoord + pixSize).a +
                texture2D(colortex2, screenCoord - vec2(pixSize.x, -pixSize.y)).a + texture2D(colortex2, screenCoord + vec2(pixSize.x, -pixSize.y)).a) * 0.25;
        }
    #endif

    #if ANTI_ALIASING == 3
        #include "/lib/utility/taaJitter.glsl"
    #endif

    /* Time uniforms */
    // Get frame time
    uniform float frameTimeCounter;
    
    #include "/lib/universalVars.glsl"

    // Get is eye in water
    uniform int isEyeInWater;

    // Get night vision
    uniform float nightVision;

    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/convertScreenSpace.glsl"
    #include "/lib/utility/noiseFunctions.glsl"
    #include "/lib/rayTracing/rayTracer.glsl"

    #include "/lib/atmospherics/fog.glsl"
    #include "/lib/atmospherics/sky.glsl"

    #include "/lib/lighting/GGX.glsl"
    #include "/lib/lighting/SSR.glsl"
    #include "/lib/lighting/SSGI.glsl"

    #ifdef OUTLINES
        #include "/lib/post/outline.glsl"
    #endif

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
        vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

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

            // Apply deffered shading
            sceneCol = complexShadingDeferred(sceneCol, skyCol, lightCol, screenPos, viewPos, eyePlayerPos, texelFetch(colortex1, screenTexelCoord, 0).rgb * 2.0 - 1.0, texelFetch(colortex2, screenTexelCoord, 0).rgb, matRaw0.x, matRaw0.y, dither);

            #ifdef SSAO
                // Apply ambient occlusion with simple blur
                sceneCol *= getSSAOBoxBlur(1.0 / vec2(viewWidth, viewHeight));
            #endif

            #ifdef OUTLINES
                // Outline calculation
                sceneCol *= 1.0 + getOutline(screenPos, viewPos.z, OUTLINE_PIX_SIZE) * (OUTLINE_BRIGHTNESS - 1.0);
            #endif
        }

        // Fog and sky calculation
        sceneCol = getFogRender(eyePlayerPos, sceneCol, getSkyRender(sceneCol, skyCol, sRGBLightCol, lightCol, normalize(eyePlayerPos), skyMask, true), feetPlayerPos.y + cameraPosition.y, skyMask);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif