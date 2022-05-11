varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    /* Buffer settings */

    /*
    const int gcolorFormat = R11F_G11F_B10F;
    const int colortex1Format = RGB16;
    const int colortex2Format = RGBA8;
    const int colortex3Format = RGB8;
    const int colortex4Format = R11F_G11F_B10F;
    const int colortex5Format = R11F_G11F_B10F;
    const int colortex6Format = RGBA16F;
    const int colortex7Format = RGB8;
    */

    uniform sampler2D gcolor;

    // For Optifine to detect
    #ifdef SHARPEN_FILTER
    #endif

    #if (ANTI_ALIASING != 0 && defined SHARPEN_FILTER) || defined CHROMATIC_ABERRATION || defined RETRO_FILTER
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #if ANTI_ALIASING != 0 && defined SHARPEN_FILTER
        // https://www.shadertoy.com/view/lslGRr
        vec3 sharpenFilter(vec3 color, vec2 texCoord){
            vec2 pixSize = 1.0 / vec2(viewWidth, viewHeight);

            vec3 blur = texture2D(gcolor, texCoord + pixSize).rgb + texture2D(gcolor, texCoord - pixSize).rgb +
                texture2D(gcolor, texCoord + vec2(pixSize.x, -pixSize.y)).rgb + texture2D(gcolor, texCoord - vec2(pixSize.x, -pixSize.y)).rgb;
            
            return (color - blur * 0.25) + color;
        }
    #endif

    void main(){
        #ifdef RETRO_FILTER
            vec2 retroResolution = vec2(viewWidth, viewHeight) * 0.5;
            vec2 retroCoord = floor(screenCoord * retroResolution) / retroResolution;

            #define screenCoord retroCoord
        #endif

        #ifdef CHROMATIC_ABERRATION
            vec2 chromaStrength = ((screenCoord - 0.5) * ABERRATION_PIX_SIZE) / vec2(viewWidth, viewHeight);

            vec3 color = vec3(texture2D(gcolor, screenCoord - chromaStrength).r,
                texture2D(gcolor, screenCoord).g,
                texture2D(gcolor, screenCoord + chromaStrength).b);
        #else
            vec3 color = texture2D(gcolor, screenCoord).rgb;
        #endif

        #if ANTI_ALIASING != 0 && defined SHARPEN_FILTER
            color = sharpenFilter(color, screenCoord);
        #endif

        gl_FragColor = vec4(color, 1);
    }
#endif