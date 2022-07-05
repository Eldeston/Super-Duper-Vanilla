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

    // SSAO without normals fix for beacon
    const vec4 colortex1ClearColor = vec4(0, 0, 0, 1);

    uniform sampler2D colortex2;

    #ifdef SSAO
        uniform sampler2D depthtex0;
        uniform sampler2D colortex1;

        /* Matrix uniforms */
        // View matrix uniforms
        uniform mat4 gbufferModelView;

        // Projection matrix uniforms
        uniform mat4 gbufferProjection;
        uniform mat4 gbufferProjectionInverse;
        
        #if ANTI_ALIASING >= 2
            // Get frame time
            uniform float frameTimeCounter;
        #endif

        #include "/lib/utility/convertViewSpace.glsl"
        #include "/lib/utility/convertScreenSpace.glsl"
        #include "/lib/utility/noiseFunctions.glsl"

        #include "/lib/lighting/SSAO.glsl"
    #endif

    void main(){
        #ifdef SSAO
            // Screen texel coordinates
            ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

            // Declare and get positions
            float depth = texelFetch(depthtex0, screenTexelCoord, 0).x;
            
            // Do SSAO
            float ambientOcclusion = 1.0;
            // Check if sky and player hand
            if(depth > 0.56 && depth != 1){
                vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;

                // Check if normal has a direction
                if(normal.x + normal.y + normal.z != 0)
                    ambientOcclusion = getSSAO(toView(vec3(screenCoord, depth)), mat3(gbufferModelView) * normal);
            }
            
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(texelFetch(colortex2, screenTexelCoord, 0).rgb, ambientOcclusion); // colortex2
        #else
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(texelFetch(colortex2, ivec2(gl_FragCoord.xy), 0).rgb, 1); // colortex2
        #endif
    }
#endif