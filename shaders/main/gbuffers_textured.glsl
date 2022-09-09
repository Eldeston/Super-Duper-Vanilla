/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out mat3 shdVertexView;
    #endif

    flat out vec3 vertexColor;
    flat out vec3 vertexNormal;

    out vec2 lmCoord;
    out vec2 texCoord;

    out vec4 feetPlayerPos;

    // View matrix uniforms
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;
    #endif

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    void main(){
        // Get texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Get vertex normal (view space)
        vertexNormal = normalize(gl_NormalMatrix * gl_Normal);
        
        // Get feet player pos
        feetPlayerPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        #ifdef WORLD_LIGHT
            // Shadow light view matrix
            shdVertexView = mat3(shadowModelView) * mat3(gbufferModelViewInverse);
        #endif

        // Lightmap fix for mods
        #ifdef WORLD_SKYLIGHT
            lmCoord = vec2(saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).x - 0.03125) * 1.06667), WORLD_SKYLIGHT);
        #else
            lmCoord = saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) * 1.06667);
        #endif
        
	    #ifdef WORLD_CURVATURE
            feetPlayerPos.y -= dot(feetPlayerPos.xz, feetPlayerPos.xz) / WORLD_CURVATURE_SIZE;
            
            // Clip pos
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * feetPlayerPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    #ifdef WORLD_LIGHT
        flat in mat3 shdVertexView;
    #endif

    flat in vec3 vertexColor;
    flat in vec3 vertexNormal;

    in vec2 lmCoord;
    in vec2 texCoord;

    in vec4 feetPlayerPos;

    // Get albedo texture
    uniform sampler2D texture;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif

    // Get current render stage
    uniform int renderStage;

    // Get is eye in water
    uniform int isEyeInWater;

    // Get night vision
    uniform float nightVision;

    #if ANTI_ALIASING >= 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    // Get atlas size
    uniform ivec2 atlasSize;

    #include "/lib/universalVars.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/shdDistort.glsl"

    #include "/lib/lighting/simpleShadingForward.glsl"

    void main(){
        // Get albedo
        vec4 albedo = texture2D(texture, texCoord);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

        // World border fix + emissives
        if(renderStage == MC_RENDER_STAGE_WORLD_BORDER){
            gl_FragData[0] = vec4(vec3(0.125, 0.25, 0.5) * EMISSIVE_INTENSITY, albedo.a); // gcolor
            return; // Return immediately, no need for lighting calculation
        }

        // Particle emissives
        if((vertexColor.r * 0.5 > vertexColor.g + vertexColor.b || (vertexColor.r + vertexColor.b > vertexColor.g * 2.0 && abs(vertexColor.r - vertexColor.b) < 0.2) || ((albedo.r + albedo.g + albedo.b > 1.6 || (vertexColor.r != vertexColor.g && vertexColor.g != vertexColor.b)) && lmCoord.x == 1)) && atlasSize.x <= 1024 && atlasSize.x > 0){
            gl_FragData[0] = vec4(toLinear(albedo.rgb * vertexColor) * EMISSIVE_INTENSITY, albedo.a); // gcolor
            return; // Return immediately, no need for lighting calculation
        }

        #if WHITE_MODE == 0
            albedo.rgb *= vertexColor;
        #elif WHITE_MODE == 1
            albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            albedo.rgb = vertexColor;
        #endif

        albedo.rgb = toLinear(albedo.rgb);

        vec4 sceneCol = simpleShadingGbuffers(albedo);

    /* DRAWBUFFERS:03 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(0, 0, 0, 1); // colortex3
    }
#endif