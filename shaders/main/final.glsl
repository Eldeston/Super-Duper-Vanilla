varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    /* Buffer settings */

    /*
    const int gcolorFormat = R11F_G11F_B10F;
    const int colortex1Format = RGB16;
    const int colortex2Format = RGBA8;
    const int colortex3Format = RGB8;
    const int colortex4Format = RGB16F;
    const int colortex5Format = R11F_G11F_B10F;
    const int colortex6Format = RGBA16F;
    const int colortex7Format = RGB8;
    */

    // For Optifine to detect
    #ifdef SHARPEN_FILTER
    #endif

    #if (ANTI_ALIASING != 0 && defined SHARPEN_FILTER) || defined CHROMATIC_ABERRATION || defined RETRO_FILTER
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #if ANTI_ALIASING != 0 && defined SHARPEN_FILTER
        #include "/lib/post/sharpenFilter.glsl"
    #endif

    uniform sampler2D gcolor;

    void main(){
        #ifdef RETRO_FILTER
            vec2 retroResolution = vec2(viewWidth, viewHeight) * 0.5;
            vec2 retroCoord = floor(texCoord * retroResolution) / retroResolution;

            #define texCoord retroCoord
        #endif

        #ifdef CHROMATIC_ABERRATION
            vec2 chromaStrength = ABERRATION_PIX_SIZE / vec2(viewWidth, viewHeight);

            vec3 color = vec3(texture2D(gcolor, mix(texCoord, vec2(0.5), chromaStrength)).r,
                texture2D(gcolor, texCoord).g,
                texture2D(gcolor, mix(texCoord, vec2(0.5), -chromaStrength)).b);
        #else
            vec3 color = texture2D(gcolor, texCoord).rgb;
        #endif

        #if ANTI_ALIASING != 0 && defined SHARPEN_FILTER
            color = sharpenFilter(gcolor, color, texCoord);
        #endif

        gl_FragColor = vec4(color, 1);
    }
#endif