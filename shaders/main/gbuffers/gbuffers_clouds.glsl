/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and dynamic clouds

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #if defined FORCE_DISABLE_CLOUDS || CLOUD_TYPE != 0
        void main(){
            gl_Position = vec4(-10);
        }
    #else
        out float cloudGradient;

        uniform vec3 cameraPosition;

        uniform mat4 gbufferModelViewInverse;

        #if ANTI_ALIASING == 2
            uniform int frameMod;

            uniform float pixelWidth;
            uniform float pixelHeight;

            #include "/lib/utility/taaJitter.glsl"
        #endif

        void main(){
            // Get vertex view position
            vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
            // Get vertex feet player position
            vec3 vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

            // Cloud gradiante' *spanish accent*
            cloudGradient = saturate((196.5 - vertexFeetPlayerPos.y - cameraPosition.y) * 0.25);

            // Convert to clip position and output as final position
            // gl_Position = gl_ProjectionMatrix * vertexViewPos;
            gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexViewPos;
            gl_Position.z += gl_ProjectionMatrix[3].z;

            gl_Position.w = -vertexViewPos.z;

            #if ANTI_ALIASING == 2
                gl_Position.xy += jitterPos(gl_Position.w);
            #endif
        }
    #endif
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    #if defined FORCE_DISABLE_CLOUDS || CLOUD_TYPE != 0
        void main(){
            discard; return;
        }
    #else
        /* RENDERTARGETS: 4 */
        layout(location = 0) out vec3 sceneColOut; // colortex4

        in float cloudGradient;

        uniform float nightVision;
        uniform float lightningFlash;

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
            uniform float twilightPhase;
        #endif

        #if defined WORLD_VANILLA_FOG_COLOR || !defined FORCE_DISABLE_WEATHER
            uniform vec3 fogColor;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
            uniform float weatherFade;
            #if WORLD_ID == 0
                #ifndef THUNDER_STRENGTH_DECLARED
                    #define THUNDER_STRENGTH_DECLARED
                    uniform float thunderStrength;
                #endif
            #endif
        #endif

        void main(){
            // Apply simple shading
            #ifndef FORCE_DISABLE_WEATHER
                #if WORLD_ID == 0
                    float effectiveWeatherFade = clamp(max(weatherFade, thunderStrength), 0.0, 1.0);
                #else
                    float effectiveWeatherFade = weatherFade;
                #endif
                #ifdef DYNAMIC_WEATHER
                    if(effectiveWeatherFade <= 0.001){ discard; return; }
                #endif
                vec3 weatherSky = vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722)));
                vec3 cloudBaseSky = mix(toLinear(SKY_COLOR_DATA_BLOCK), weatherSky * 0.35, effectiveWeatherFade);
                vec3 cloudDirectLight = toLinear(LIGHT_COLOR_DATA_BLOCK0) * ((1.0 - effectiveWeatherFade) * squared(cloudGradient));
                sceneColOut = (toLinear(nightVision * 0.5 + AMBIENT_LIGHTING) + lightningFlash) + cloudBaseSky + cloudDirectLight;
            #else
                sceneColOut = (toLinear(nightVision * 0.5 + AMBIENT_LIGHTING) + lightningFlash) + toLinear(SKY_COLOR_DATA_BLOCK) + toLinear(LIGHT_COLOR_DATA_BLOCK0) * squared(cloudGradient);
            #endif

            #if defined CLOUD_LIGHTNING_GLOW && !defined EPILEPSY_SAFETY
                vec3 internalGlow = vec3(0.72, 0.85, 1.0) * (lightningFlash * (0.85 + cloudGradient * 1.35) * (1.25 * CLOUD_LIGHTNING_GLOW));
                sceneColOut += internalGlow;
            #endif
        }
    #endif
#endif