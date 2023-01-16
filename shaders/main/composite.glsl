/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: Transparent complex shading and volumetric lighting

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

    uniform sampler2D gcolor;
    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;
    
    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Declare and get positions
        vec3 screenPos = vec3(texCoord, texelFetch(depthtex0, screenTexelCoord, 0).x);

        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        // If the object is a transparent render separate lighting
        if(texelFetch(depthtex1, screenTexelCoord, 0).x > screenPos.z){
            
        }

        // Clamp scene color to prevent negative/NaN values
        sceneCol = max(sceneCol, vec3(0));

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif