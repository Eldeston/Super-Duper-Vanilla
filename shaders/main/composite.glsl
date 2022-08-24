/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    flat out vec3 lightCol;
    flat out vec3 skyCol;
    
    out vec2 screenCoord;

    #include "/lib/universalVars.glsl"

    void main(){
        // Get sRGB light color
        #ifdef WORLD_LIGHT
            lightCol = toLinear(LIGHT_COL_DATA_BLOCK);
        #else
            lightCol = vec3(0);
        #endif

        // Get linear sky color
        skyCol = toLinear(SKY_COL_DATA_BLOCK);

        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    flat in vec3 lightCol;
    flat in vec3 skyCol;

    in vec2 screenCoord;

    uniform sampler2D gcolor;
    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;
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

        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;

        uniform vec3 previousCameraPosition;

        #include "/lib/utility/convertPrevScreenSpace.glsl"
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;
    #endif

    /* Time uniforms */
    // Get frame time
    uniform float frameTimeCounter;

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

    #include "/lib/universalVars.glsl"

    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/convertScreenSpace.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/lighting/GGX.glsl"
    
    #include "/lib/rayTracing/rayTracer.glsl"
    #include "/lib/rayTracing/volLight.glsl"
    #include "/lib/rayTracing/SSGI.glsl"
    #include "/lib/rayTracing/SSR.glsl"

    #include "/lib/atmospherics/fog.glsl"
    #include "/lib/atmospherics/sky.glsl"

    #include "/lib/lighting/complexShadingDeferred.glsl"

    float getSpectral(ivec2 iUv){
        ivec2 topRightCorner = iUv - 1;
        ivec2 bottomLeftCorner = iUv + 1;

        float sample0 = texelFetch(colortex3, topRightCorner, 0).z;
        float sample1 = texelFetch(colortex3, bottomLeftCorner, 0).z;
        float sample2 = texelFetch(colortex3, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).z;
        float sample3 = texelFetch(colortex3, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).z;

        float sumDepth = sample0 + sample1 + sample2 + sample3;

        return abs(sumDepth * 0.25 - texelFetch(colortex3, iUv, 0).z);
    }
    
    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Declare and get positions
        vec3 screenPos = vec3(screenCoord, texelFetch(depthtex0, screenTexelCoord, 0).x);
        vec3 viewPos = toView(screenPos);
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        #if ANTI_ALIASING >= 2
            vec3 dither = toRandPerFrame(getRand3(screenTexelCoord & 255), frameTimeCounter);
        #else
            vec3 dither = getRand3(screenTexelCoord & 255);
        #endif

        // If the object is a transparent render separate lighting
        if(texelFetch(depthtex1, screenTexelCoord, 0).x > screenPos.z){
            // Get view distance
            float viewDist = length(viewPos);
            // Get normalized eyePlayerPos
            vec3 nEyePlayerPos = eyePlayerPos / viewDist;

            // Declare and get materials
            vec2 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xy;
            vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;
            vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;

            // Apply deffered shading
            sceneCol = complexShadingDeferred(sceneCol, skyCol, lightCol, screenPos, viewPos, nEyePlayerPos, normal, albedo, matRaw0.x, matRaw0.y, dither);

            sceneCol *= 1.0 - darknessLightFactor;

            // Get skyCol as our fogCol. Do basic sky render.
            vec3 fogCol = getSkyRender(skyCol, lightCol, nEyePlayerPos, false, false);
            // Fog and sky calculation
            sceneCol = getFogRender(sceneCol, fogCol, viewDist, nEyePlayerPos.y, feetPlayerPos.y + cameraPosition.y);
        }

        // Apply spectral effect
        sceneCol += getSpectral(screenTexelCoord) * EMISSIVE_INTENSITY;

        #ifdef WORLD_LIGHT
            // Apply volumetric light
            sceneCol += getGodRays(feetPlayerPos, lightCol, dither.x, screenPos.z == 1) * min(1.0, VOL_LIGHT_BRIGHTNESS + VOL_LIGHT_BRIGHTNESS * isEyeInWater) * shdFade;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(max(sceneCol, vec3(0)), 1); // gcolor
    }
#endif