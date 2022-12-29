/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    flat out vec3 skyCol;

    #ifdef WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 lightCol;
    #endif
    
    out vec2 screenCoord;

    #include "/lib/universalVars.glsl"

    void main(){
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        // Get sRGB light color
        #ifdef WORLD_LIGHT
            sRGBLightCol = LIGHT_COL_DATA_BLOCK;
            lightCol = toLinear(sRGBLightCol);
        #endif

        // Get linear sky color
        skyCol = toLinear(SKY_COL_DATA_BLOCK);
        
        gl_Position = ftransform();
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    flat in vec3 skyCol;

    #ifdef WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 lightCol;
    #endif

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

    #if ANTI_ALIASING == 2
        /* Screen uniforms */
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #ifdef SSAO
        float getSSAOBoxBlur(in ivec2 screenTexelCoord){
            ivec2 topRightCorner = screenTexelCoord + 1;
            ivec2 bottomLeftCorner = screenTexelCoord - 1;

            float sample0 = texelFetch(colortex2, topRightCorner, 0).a;
            float sample1 = texelFetch(colortex2, bottomLeftCorner, 0).a;
            float sample2 = texelFetch(colortex2, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).a;
            float sample3 = texelFetch(colortex2, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).a;

            float sumDepth = sample0 + sample1 + sample2 + sample3;

            return sumDepth * 0.25;
        }
    #endif

    #if ANTI_ALIASING == 2
        #include "/lib/utility/taaJitter.glsl"
    #endif

    // Get is eye in water
    uniform int isEyeInWater;

    // Get far
    uniform float far;
    // Get blindness
    uniform float blindness;
    // Get night vision
    uniform float nightVision;
    // Get darkness effect
    uniform float darknessFactor;
    // Get darkness light factor
    uniform float darknessLightFactor;

    /* Time uniforms */
    // Get frame time
    uniform float frameTimeCounter;

    #ifdef WORLD_LIGHT
        uniform float shdFade;
    #endif

    #include "/lib/universalVars.glsl"

    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/convertScreenSpace.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/GGX.glsl"
    
    #include "/lib/rayTracing/rayTracer.glsl"

    #include "/lib/atmospherics/fog.glsl"
    #include "/lib/atmospherics/sky.glsl"

    #if OUTLINES != 0
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
        #if ANTI_ALIASING == 2
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

        // If sky, do full sky render
        if(skyMask){
            sceneCol = getSkyRender(sceneCol, nEyePlayerPos, true) * exp2(-far * (blindness + darknessFactor));
        // Else, calculate reflection and fog
        }else{
            #if ANTI_ALIASING >= 2
                vec3 dither = toRandPerFrame(getRand3(screenTexelCoord & 255), frameTimeCounter);
            #else
                vec3 dither = getRand3(screenTexelCoord & 255);
            #endif

            // Declare and get materials
            vec2 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xy;
            vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;
            vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;

            // Apply deffered shading
            sceneCol = complexShadingDeferred(sceneCol, screenPos, viewPos, mat3(gbufferModelView) * normal, albedo, viewDist, matRaw0.x, matRaw0.y, dither);

            #if OUTLINES != 0
                // Outline calculation
                sceneCol *= 1.0 + getOutline(screenTexelCoord, viewPos.z, OUTLINE_PIX_SIZE) * (OUTLINE_BRIGHTNESS - 1.0);
            #endif
            
            #ifdef SSAO
                // Apply ambient occlusion with simple blur
                sceneCol *= getSSAOBoxBlur(screenTexelCoord);
            #endif

            // Do basic sky render and use it as fog color
            sceneCol = getFogRender(sceneCol, getSkyRender(nEyePlayerPos, false, false), viewDist, nEyePlayerPos.y, eyePlayerPos.y + gbufferModelViewInverse[3].y + cameraPosition.y);
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif