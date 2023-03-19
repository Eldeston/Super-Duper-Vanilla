/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: Buffer settings, retro filter, chromatic aberration, and sharpen filter

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

    /* Buffer settings */

    /*
    const int gcolorFormat = R11F_G11F_B10F;
    const int colortex1Format = RGB16_SNORM;
    const int colortex2Format = RGBA8;
    const int colortex3Format = RGB8;
    const int colortex4Format = R11F_G11F_B10F;
    const int colortex5Format = RGBA16F;
    */

    uniform sampler2D colortex3;

    // For Optifine to detect
    #ifdef SHARPEN_FILTER
    #endif

    #if ANTI_ALIASING >= 2 || defined PREVIOUS_FRAME || defined AUTO_EXPOSURE
        // Disable buffer clear if TAA, previous frame reflections, or auto exposure is on
        const bool colortex5Clear = false;
    #endif

    #if (ANTI_ALIASING != 0 && defined SHARPEN_FILTER) || defined CHROMATIC_ABERRATION || defined RETRO_FILTER
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #if ANTI_ALIASING != 0 && defined SHARPEN_FILTER
        // https://www.shadertoy.com/view/lslGRr
        vec3 sharpenFilter(in vec3 color, in vec2 uv, in vec2 pixelSize){
            vec2 topRightCorner = uv + pixelSize;
            vec2 bottomLeftCorner = uv - pixelSize;

            vec3 blur = textureLod(colortex3, bottomLeftCorner, 0).rgb + textureLod(colortex3, topRightCorner, 0).rgb +
                textureLod(colortex3, vec2(bottomLeftCorner.x, topRightCorner.y), 0).rgb + textureLod(colortex3, vec2(topRightCorner.x, bottomLeftCorner.y), 0).rgb;
            
            return color * 2.0 - blur * 0.25;
        }
    #endif

    void main(){
        #if defined CHROMATIC_ABERRATION || (ANTI_ALIASING != 0 && defined SHARPEN_FILTER)
            vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);
        #endif

        #ifdef RETRO_FILTER
            const float renderScale = 0.5 / MC_RENDER_QUALITY;
            vec2 retroResolution = vec2(viewWidth, viewHeight) * renderScale;
            vec2 retroCoord = floor(texCoord * retroResolution) / retroResolution;

            #define texCoord retroCoord
        #endif

        #ifdef CHROMATIC_ABERRATION
            vec2 chromaStrength = ((texCoord - 0.5) * ABERRATION_PIX_SIZE) * pixelSize;

            vec3 sceneCol = vec3(textureLod(colortex3, texCoord - chromaStrength, 0).r,
                textureLod(colortex3, texCoord, 0).g,
                textureLod(colortex3, texCoord + chromaStrength, 0).b);
        #else
            vec3 sceneCol = textureLod(colortex3, texCoord, 0).rgb;
        #endif

        #if ANTI_ALIASING != 0 && defined SHARPEN_FILTER
            sceneCol = sharpenFilter(sceneCol, texCoord, pixelSize);
        #endif

        // Output final result
        gl_FragColor = vec4(sceneCol, 1);
    }
#endif