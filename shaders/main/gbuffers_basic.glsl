#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 lmCoord;
varying vec2 texCoord;

varying vec3 norm;
varying vec3 glcolor;

// View matrix uniforms
uniform mat4 gbufferModelViewInverse;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif
    
    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Lightmap fix for mods
        lmCoord = saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) * 1.06667);

	    norm = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);
        
	    #ifdef WORLD_CURVATURE
            // Feet player pos
            vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

            vertexPos.y -= lengthSquared(vertexPos.xz) / WORLD_CURVATURE_SIZE;
            
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color.rgb;
    }
#endif

#ifdef FRAGMENT
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
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"

    #include "/lib/lighting/simpleShadingForward.glsl"

    void main(){
        // Declare and get positions
        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 feetPlayerPos = mat3(gbufferModelViewInverse) * toView(screenPos) + gbufferModelViewInverse[3].xyz;

	    // Declare materials
        vec4 albedo = vec4(glcolor, 1);

        #if WHITE_MODE == 1
            albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            albedo.rgb = vec3(0);
        #endif

        albedo.rgb = pow(albedo.rgb, vec3(GAMMA));

        #if ANTI_ALIASING == 2
            vec4 sceneCol = simpleShadingGbuffers(albedo, feetPlayerPos, norm, lmCoord, 1.0, toRandPerFrame(getRand1(gl_FragCoord.xy * 0.03125), frameTimeCounter));
        #else
            vec4 sceneCol = simpleShadingGbuffers(albedo, feetPlayerPos, norm, lmCoord, 1.0, getRand1(gl_FragCoord.xy * 0.03125));
        #endif

    /* DRAWBUFFERS:03 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(0, 0, 0, 1); //colortex3
    }
#endif