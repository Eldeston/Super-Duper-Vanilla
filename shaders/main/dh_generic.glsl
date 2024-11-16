/*
================================ /// Super Duper Vanilla v1.3.7 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.7 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec3 vertexColor;

    uniform mat4 dhProjection;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    void main(){
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

	    #ifdef WORLD_CURVATURE
            // Get vertex eye player position
            vec3 vertexEyePlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos;
            
            // Get vertex feet player position
            vec2 vertexFeetPlayerPosXZ = vertexEyePlayerPos.xz + gbufferModelViewInverse[3].xz;

            // Apply curvature distortion
            vertexEyePlayerPos.y -= lengthSquared(vertexFeetPlayerPosXZ) * worldCurvatureInv;
            
            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexEyePlayerPos;
        #endif

        // Convert to clip position and output as final position
        // gl_Position = dhProjection * vertexViewPos;
        gl_Position.xyz = getMatScale(mat3(dhProjection)) * vertexViewPos;
        gl_Position.z += dhProjection[3].z;

        gl_Position.w = -vertexViewPos.z;

        gl_Position = ftransform();

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // gcolor
    layout(location = 1) out vec4 normalDataOut; // colortex1
    layout(location = 2) out vec4 albedoDataOut; // colortex2
    layout(location = 3) out vec4 materialDataOut; // colortex3

    in vec3 vertexColor;

    uniform sampler2D depthtex0;

    void main(){
        // Fix for Distant Horizons translucents rendering over real geometry
        if(texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x != 1.0){ discard; return; }

        // Apply simple shading
        sceneColOut = vec4(vertexColor * EMISSIVE_INTENSITY, 1);

        // Write buffer datas
        normalDataOut = vec4(0, 0, 1, 1);
        albedoDataOut = vec4(vertexColor, 1);
        materialDataOut = vec4(0, 0, 0, 1);
    }
#endif