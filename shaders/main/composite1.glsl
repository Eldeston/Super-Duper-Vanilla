varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
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
            #include "/lib/utility/texFunctions.glsl"
        #endif
    #endif
    
    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #include "/lib/post/spectral.glsl"

    void main(){
        // Spectral
        float spectralOutline = getSpectral(colortex3, texCoord, 2.0);
        vec3 sceneCol = texture2D(gcolor, texCoord).rgb * (1.0 - spectralOutline) + spectralOutline * EMISSIVE_INTENSITY * 0.5;

        #ifdef WORLD_LIGHT
            #if defined VOL_LIGHT && defined SHD_ENABLE
                sceneCol += texture2DBox(colortex4, texCoord, vec2(viewWidth, viewHeight)).rgb * lightCol * (min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater)) * shdFade);
            #else
                sceneCol += texture2D(colortex4, texCoord, 1.5).rgb * lightCol * (min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater)) * shdFade) * (isEyeInWater == 1 ? fogColor : vec3(1));
            #endif

        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(sceneCol, 1); // gcolor
        #else
        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(sceneCol, 1); // gcolor
        #endif
    }
#endif