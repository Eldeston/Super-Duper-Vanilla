/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: Bloom blur 2nd pass

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef BLOOM
        noperspective out vec2 texCoord;
    #endif

    void main(){
        #ifdef BLOOM
            // Get buffer texture coordinates
            texCoord = gl_MultiTexCoord0.xy;
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 bloomColOut; // colortex0

    #ifdef BLOOM
        noperspective in vec2 texCoord;

        uniform float bloomPixelWidth;
        uniform float bloomPixelHeight;

        uniform sampler2D colortex0;

        vec3 getBloomTile(in vec2 coords, in float invScale){
            // Remap to bloom tile texture coordinates
            vec2 baseCoord = texCoord * invScale + coords;

            // Pixel size
            vec2 pixelSize = vec2(bloomPixelWidth, bloomPixelHeight);

            vec2 topRightCorner = baseCoord + pixelSize;
            vec2 bottomLeftCorner = baseCoord - pixelSize;

            // Apply box blur all tiles
            return (textureLod(colortex0, bottomLeftCorner, 0).rgb + textureLod(colortex0, topRightCorner, 0).rgb +
                textureLod(colortex0, vec2(bottomLeftCorner.x, topRightCorner.y), 0).rgb + textureLod(colortex0, vec2(topRightCorner.x, bottomLeftCorner.y), 0).rgb) * 0.25;
        }

        // 9‑tap tent filter
        // vec3 getBloomTile(in vec2 coords, in float invScale){
        //     // Remap to bloom tile texture coordinates
        //     vec2 baseCoord = texCoord * invScale + coords;

        //     // Bloom pixel size
        //     vec2 pixelOffSet = vec2(bloomPixelWidth, bloomPixelHeight) * 2.0;

        //     // Axial neighbors
        //     vec3 bloomCol0 = textureLod(colortex0, vec2(baseCoord.x + pixelOffSet.x, baseCoord.y), 0).rgb;
        //     bloomCol0 += textureLod(colortex0, vec2(baseCoord.x - pixelOffSet.x, baseCoord.y), 0).rgb;
        //     bloomCol0 += textureLod(colortex0, vec2(baseCoord.x, baseCoord.y + pixelOffSet.y), 0).rgb;
        //     bloomCol0 += textureLod(colortex0, vec2(baseCoord.x, baseCoord.y - pixelOffSet.y), 0).rgb;

        //     vec2 topRight = baseCoord + pixelOffSet * 0.5;
        //     vec2 bottomLeft = baseCoord - pixelOffSet * 0.5;

        //     // Diagonals
        //     vec3 bloomCol1 = textureLod(colortex0, topRight, 0).rgb;
        //     bloomCol1 += textureLod(colortex0, bottomLeft, 0).rgb;
        //     bloomCol1 += textureLod(colortex0, vec2(topRight.x, bottomLeft.y), 0).rgb;
        //     bloomCol1 += textureLod(colortex0, vec2(bottomLeft.x, topRight.y), 0).rgb;

        //     return (bloomCol0 + bloomCol1 * 2.0) / 12.0;
        // }
    #endif

    void main(){
        #ifdef BLOOM
            // Uncompress the HDR colors and upscale
            vec3 bloomCol = getBloomTile(vec2(0, 0), 0.5);
            bloomCol += getBloomTile(vec2(0, 0.5078125), 0.25);
            bloomCol += getBloomTile(vec2(0.2578125, 0.5078125), 0.125);
            bloomCol += getBloomTile(vec2(0.390625, 0.5078125), 0.0625);
            bloomCol += getBloomTile(vec2(0.4609375, 0.5078125), 0.03125);

            // Average the total samples (1 / 5 bloom tiles multiplied by 1 / 4 samples used for the box blur)
            bloomCol *= 0.2;

            float bloomLuma = sumOf(bloomCol);
            // Apply bloom by tonemapped luma and BLOOM_STRENGTH
            bloomColOut = bloomCol * ((BLOOM_STRENGTH * bloomLuma) / (3.0 + bloomLuma));
        #else
            bloomColOut = vec3(0);
        #endif
    }
#endif