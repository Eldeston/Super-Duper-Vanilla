varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;
    uniform sampler2D colortex3;

    #ifdef WORLD_LIGHT
        uniform sampler2D colortex4;

        uniform float shdFade;

        #include "/lib/universalVars.glsl"

        #if defined VOL_LIGHT && defined SHD_ENABLE
            vec3 getVolLightBoxBlur(vec2 pixSize){
                // Apply simple box blur
                return (texture2D(colortex4, screenCoord - pixSize).rgb + texture2D(colortex4, screenCoord + pixSize).rgb +
                    texture2D(colortex4, screenCoord - vec2(pixSize.x, -pixSize.y)).rgb + texture2D(colortex4, screenCoord + vec2(pixSize.x, -pixSize.y)).rgb) * 0.25;
            }
        #endif
    #endif
    
    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    float getSpectral(vec2 pixSize){
        // Do a simple blur
        float totalDepth = texture2D(colortex3, screenCoord + pixSize).z + texture2D(colortex3, screenCoord - pixSize).z +
            texture2D(colortex3, screenCoord + vec2(pixSize.x, -pixSize.y)).z + texture2D(colortex3, screenCoord - vec2(pixSize.x, -pixSize.y)).z;

        // Get the difference between the blurred samples and original
        return abs(totalDepth * 0.25 - texture2D(colortex3, screenCoord).z);
    }

    void main(){
        // Get pixel size
        vec2 pixSize = 1.0 / vec2(viewWidth, viewHeight);
        // Spectral effect
        vec3 sceneCol = texture2D(gcolor, screenCoord).rgb + getSpectral(pixSize) * EMISSIVE_INTENSITY;

        #ifdef WORLD_LIGHT
            // Get light color
            vec3 lightCol = pow(LIGHT_COL_DATA_BLOCK, vec3(GAMMA));

            #if defined VOL_LIGHT && defined SHD_ENABLE
                sceneCol += getVolLightBoxBlur(pixSize) * lightCol * (min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater)) * shdFade);
            #else
                sceneCol += (isEyeInWater == 1 ? lightCol * fogColor : lightCol) * (texture2D(colortex4, screenCoord, 1.0).r * min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater)) * shdFade);
            #endif

        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(sceneCol, 1); // gcolor
        #else
        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(sceneCol, 1); // gcolor
        #endif
    }
#endif