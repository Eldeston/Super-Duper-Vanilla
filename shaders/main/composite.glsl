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

    // Get night vision
    uniform float nightVision;

    #include "/lib/universalVars.glsl"

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

    float getSpectral(ivec2 iUv){
        // Do a simple blur
        float totalDepth = texelFetch(colortex3, iUv + 1, 0).z + texelFetch(colortex3, iUv - 1, 0).z +
            texelFetch(colortex3, iUv + ivec2(1, -1), 0).z + texelFetch(colortex3, iUv - ivec2(1, -1), 0).z;

        // Get the difference between the blurred samples and original
        return abs(totalDepth * 0.25 - texelFetch(colortex3, iUv, 0).z);
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

        // Declare and get materials
        vec3 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xyz;

        // Get sRGB light color
        #ifdef WORLD_LIGHT
            vec3 lightCol = pow(LIGHT_COL_DATA_BLOCK, vec3(GAMMA));
        #else
            vec3 lightCol = vec3(0);
        #endif

        // If the object is a transparent render separate lighting
        if(texelFetch(depthtex1, screenTexelCoord, 0).x > screenPos.z){
            // Get linear sky color
            vec3 skyCol = pow(SKY_COL_DATA_BLOCK, vec3(GAMMA));

            // Apply deffered shading
            sceneCol = complexShadingDeferred(sceneCol, skyCol, lightCol, screenPos, viewPos, eyePlayerPos, texelFetch(colortex1, screenTexelCoord, 0).rgb * 2.0 - 1.0, texelFetch(colortex2, screenTexelCoord, 0).rgb, matRaw0.x, matRaw0.y, dither);

            // Fog and sky calculation
            sceneCol = getFogRender(eyePlayerPos, sceneCol, getSkyRender(vec3(0), skyCol, lightCol, normalize(eyePlayerPos), false, false), feetPlayerPos.y + cameraPosition.y, false);
        }

        // Apply spectral effect
        sceneCol += getSpectral(screenTexelCoord) * EMISSIVE_INTENSITY;

        #ifdef WORLD_LIGHT
            // Apply volumetric light
            sceneCol += getGodRays(feetPlayerPos, lightCol, dither.x) * min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater) * shdFade);
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif