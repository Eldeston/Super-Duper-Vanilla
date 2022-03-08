#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/structs.glsl"

varying vec2 lmCoord;
varying vec2 texCoord;

varying vec3 norm;

varying vec4 glcolor;

// View matrix uniforms
uniform mat4 gbufferModelViewInverse;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Lightmap fix for mods
        lmCoord = saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) * 1.06667);

	    norm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
        
	    gl_Position = ftransform();

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #if ANTI_ALIASING == 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    #include "/lib/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"
    
    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	    posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;
        posVector.feetPlayerPos = posVector.eyePlayerPos + gbufferModelViewInverse[3].xyz;

	    // Declare materials
	    matPBR material;

        material.albedo = texture2D(texture, texCoord);

        // Alpha test, discard immediately
        if(material.albedo.a <= ALPHA_THRESHOLD) discard;
        
        // Assign normals
        material.normal = norm;

        #if WHITE_MODE == 0
            material.albedo.rgb *= glcolor.rgb;
        #elif WHITE_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo.rgb = glcolor.rgb;
        #endif

        material.albedo.rgb = pow(material.albedo.rgb, vec3(GAMMA));

        material.metallic = 0.0;
        material.ss = 1.0;
        material.emissive = 0.0;
        material.smoothness = 0.0;
        material.parallaxShd = 1.0;

        // Apply vanilla AO
        material.ambient = 1.0;
        material.light = lmCoord;

        #if ANTI_ALIASING == 2
            vec4 sceneCol = complexShadingGbuffers(material, posVector, toRandPerFrame(getRand1(gl_FragCoord.xy * 0.03125), frameTimeCounter));
        #else
            vec4 sceneCol = complexShadingGbuffers(material, posVector, getRand1(gl_FragCoord.xy * 0.03125));
        #endif

    /* DRAWBUFFERS:03 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(0, 0, 0, 1); //colortex3
    }
#endif