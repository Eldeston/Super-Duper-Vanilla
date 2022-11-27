/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    flat out vec4 vertexColor;

    out vec2 texCoord;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
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
        vertexColor = gl_Color;
        
	    #ifdef WORLD_CURVATURE
            // Get vertex position (feet player pos)
            vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

            vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
            
            // Clip pos
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
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
    flat in vec4 vertexColor;

    in vec2 texCoord;

    // Get albedo texture
    uniform sampler2D tex;

    void main(){
        vec4 albedo = texture(tex, texCoord) * vertexColor;

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

        #if WHITE_MODE == 1
            albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            albedo.rgb = vertexColor.rgb;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(toLinear(albedo.rgb) * EMISSIVE_INTENSITY, albedo.a); // gcolor
    }
#endif