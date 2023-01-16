/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: Solid complex shading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    in vec2 texCoord;
    
    // Sky silhoutte fix
    const vec4 gcolorClearColor = vec4(0, 0, 0, 1);

    uniform sampler2D gcolor;
    uniform sampler2D colortex2;
    
    uniform sampler2D depthtex0;

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

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Declare and get positions
        vec3 screenPos = vec3(texCoord, texelFetch(depthtex0, screenTexelCoord, 0).x);
        
        // Get sky mask
        bool skyMask = screenPos.z == 1;

        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        // If sky, do full sky render
        if(skyMask){
            
        }
        // Else, calculate reflection and fog
        else{
            #ifdef SSAO
                // Apply ambient occlusion with simple blur
                sceneCol *= getSSAOBoxBlur(screenTexelCoord);
            #endif
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif