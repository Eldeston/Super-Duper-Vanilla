/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: Solid screen space ambient occlusion

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;
        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    in vec2 texCoord;

    // SSAO without normals fix for beacon
    const vec4 colortex1ClearColor = vec4(0, 0, 0, 1);

    uniform sampler2D colortex2;

    #ifdef SSAO
        uniform float near;

        uniform mat4 gbufferModelView;

        uniform mat4 gbufferProjection;
        uniform mat4 gbufferProjectionInverse;

        uniform sampler2D colortex1;

        uniform sampler2D depthtex0;

        #if ANTI_ALIASING >= 2
            uniform float frameTimeCounter;
        #endif

        #include "/lib/utility/convertViewSpace.glsl"
        #include "/lib/utility/convertScreenSpace.glsl"
        #include "/lib/utility/noiseFunctions.glsl"

        #include "/lib/lighting/SSAO.glsl"
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Albedo color
        vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;

        #ifdef SSAO
            // Declare and get positions
            float depth = texelFetch(depthtex0, screenTexelCoord, 0).x;
            
            // Do SSAO
            float ambientOcclusion = 0.25;
            // Check if sky and player hand
            if(depth > 0.56 && depth != 1){
                vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;

                // Check if normal has a direction
                if(normal.x + normal.y + normal.z != 0)
                    ambientOcclusion = getSSAO(vec3(texCoord, depth), mat3(gbufferModelView) * normal);
            }
            
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(albedo, ambientOcclusion); // colortex2
        #else
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(albedo, 1); // colortex2
        #endif
    }
#endif