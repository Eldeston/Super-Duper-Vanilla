varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #if defined PREVIOUS_FRAME || ANTI_ALIASING >= 2
        uniform sampler2D colortex5;
    #endif

    #if (defined VOL_LIGHT && defined SHD_ENABLE && defined WORLD_LIGHT) || ANTI_ALIASING >= 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #ifdef WORLD_LIGHT
        uniform sampler2D colortex4;

        uniform float shdFade;

        #include "/lib/universalVars.glsl"

        // Get is eye in water
        uniform int isEyeInWater;

        #if defined VOL_LIGHT && defined SHD_ENABLE
            vec3 getVolLightBoxBlur(vec2 pixSize){
                // Apply simple box blur
                return (texture2D(colortex4, screenCoord - pixSize).rgb + texture2D(colortex4, screenCoord + pixSize).rgb +
                    texture2D(colortex4, screenCoord - vec2(pixSize.x, -pixSize.y)).rgb + texture2D(colortex4, screenCoord + vec2(pixSize.x, -pixSize.y)).rgb) * 0.25;
            }
        #endif
    #endif

    #if ANTI_ALIASING >= 2
        uniform sampler2D depthtex0;

        /* Matrix uniforms */
        // View matrix uniforms
        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferPreviousModelView;

        // Projection matrix uniforms
        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferPreviousProjection;

        /* Position uniforms */
        uniform vec3 cameraPosition;
        uniform vec3 previousCameraPosition;

        #include "/lib/utility/convertPrevScreenSpace.glsl"

        #include "/lib/antialiasing/taa.glsl"
    #endif

    void main(){
        // Get scene color, clamp to 0
        vec3 sceneCol = texture2D(gcolor, screenCoord).rgb;

        #ifdef WORLD_LIGHT
            #if defined VOL_LIGHT && defined SHD_ENABLE
                vec3 volLight = getVolLightBoxBlur(1.0 / vec2(viewWidth, viewHeight)) * pow(LIGHT_COL_DATA_BLOCK, vec3(GAMMA)) * (min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater)) * shdFade);
            #else
                vec3 volLight = pow(isEyeInWater == 1 ? LIGHT_COL_DATA_BLOCK * fogColor : LIGHT_COL_DATA_BLOCK, vec3(GAMMA)) * (texture2D(colortex4, screenCoord).r * min(1.0, VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater)) * shdFade);
            #endif
        #endif

        #if ANTI_ALIASING >= 2
            #ifdef WORLD_LIGHT
                sceneCol = textureTAA(sceneCol, volLight, screenCoord, vec2(viewWidth, viewHeight));
            #else
                sceneCol = textureTAA(sceneCol, vec3(0), screenCoord, vec2(viewWidth, viewHeight));
            #endif
        #else
            sceneCol += volLight;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor

        #if ANTI_ALIASING >= 2 || defined PREVIOUS_FRAME
        /* DRAWBUFFERS:05 */
            #ifdef AUTO_EXPOSURE
                gl_FragData[1] = vec4(sceneCol, texelFetch(colortex5, ivec2(0), 0).a); //colortex5
            #else
                gl_FragData[1] = vec4(sceneCol, 1); //colortex5
            #endif
        #endif
    }
#endif