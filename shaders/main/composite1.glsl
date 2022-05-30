varying vec2 screenCoord;

#define WATER_REFRACTION

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #ifdef WORLD_LIGHT
        uniform sampler2D colortex4;

        uniform float shdFade;

        #include "/lib/universalVars.glsl"

        // Get is eye in water
        uniform int isEyeInWater;

        #if defined VOL_LIGHT && defined SHD_ENABLE
            /* Screen resolutions */
            uniform float viewWidth;
            uniform float viewHeight;

            vec3 getVolLightBoxBlur(vec2 pixSize){
                // Apply simple box blur
                return (texture2D(colortex4, screenCoord - pixSize).rgb + texture2D(colortex4, screenCoord + pixSize).rgb +
                    texture2D(colortex4, screenCoord - vec2(pixSize.x, -pixSize.y)).rgb + texture2D(colortex4, screenCoord + vec2(pixSize.x, -pixSize.y)).rgb) * 0.25;
            }
        #endif
    #endif

    void main(){
        // Get scene color, clamp to 0
        vec3 sceneCol = max(vec3(0), texture2D(gcolor, screenCoord).rgb);

        #ifdef WORLD_LIGHT
            #if defined VOL_LIGHT && defined SHD_ENABLE
                sceneCol += getVolLightBoxBlur(1.0 / vec2(viewWidth, viewHeight)) * pow(LIGHT_COL_DATA_BLOCK, vec3(GAMMA)) * (min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater)) * shdFade);
            #else
                sceneCol += pow(isEyeInWater == 1 ? LIGHT_COL_DATA_BLOCK * fogColor : LIGHT_COL_DATA_BLOCK, vec3(GAMMA)) * (texture2D(colortex4, screenCoord).r * min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater)) * shdFade);
            #endif
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif