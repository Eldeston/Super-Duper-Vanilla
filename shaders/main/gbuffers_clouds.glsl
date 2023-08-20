/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and dynamic clouds

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #if defined FORCE_DISABLE_CLOUDS || defined STORY_MODE_CLOUDS
        void main(){
            gl_Position = vec4(-10);
        }
    #else
        out vec2 texCoord;

        out vec4 vertexPos;

        #ifdef WORLD_LIGHT
            flat out vec3 vertexNormal;
        #endif

        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;

        #if ANTI_ALIASING == 2
            uniform int frameMod8;

            uniform float pixelWidth;
            uniform float pixelHeight;

            #include "/lib/utility/taaJitter.glsl"
        #endif

        #ifdef DOUBLE_VANILLA_CLOUDS
            // Set the amount of instances, we'll use 2 for now for performance
            const int countInstances = 2;

            uniform int instanceId;
        #endif
        
        void main(){
            // Get buffer texture coordinates
            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

            // Get vertex position (feet player pos)
            vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

            #ifdef WORLD_LIGHT
                // Get vertex normal
                vertexNormal = mat3(gbufferModelViewInverse) * fastNormalize(gl_NormalMatrix * gl_Normal);
            #endif

            #ifdef DOUBLE_VANILLA_CLOUDS
                // May need to work on this to add more than 2 clouds in the future.
                if(instanceId == 1){
                    // If second instance, invert texture coordinates.
                    texCoord = -texCoord;
                    // Increase cloud height for the second instance.
                    vertexPos.y += SECOND_CLOUD_HEIGHT;
                }

                // Convert to clip pos and output as position
                gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
            #else
                gl_Position = ftransform();
            #endif

            #if ANTI_ALIASING == 2
                gl_Position.xy += jitterPos(gl_Position.w);
            #endif
        }
    #endif
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    #if defined FORCE_DISABLE_CLOUDS || defined STORY_MODE_CLOUDS
        void main(){
            discard;
        }
    #else
        in vec2 texCoord;

        in vec4 vertexPos;

        #ifdef WORLD_LIGHT
            flat in vec3 vertexNormal;
        #endif

        uniform float nightVision;

        uniform sampler2D tex;

        #ifdef IS_IRIS
            uniform float lightningFlash;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
        #endif

        #if defined DYNAMIC_CLOUDS || ANTI_ALIASING >= 2
            uniform float frameTimeCounter;
        #endif

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
            uniform float twilightPhase;
        #endif

        #ifdef WORLD_VANILLA_FOG_COLOR
            uniform vec3 fogColor;
        #endif

        #ifdef WORLD_LIGHT
            uniform float shdFade;

            uniform mat4 shadowModelView;

            #ifdef SHADOW_MAPPING
                uniform mat4 shadowProjection;

                #ifdef SHADOW_FILTER
                    #include "/lib/utility/noiseFunctions.glsl"
                #endif

                #include "/lib/lighting/shdMapping.glsl"
                #include "/lib/lighting/shdDistort.glsl"
            #endif
        #endif

        #include "/lib/lighting/simpleShadingForward.glsl"

        void main(){
            // Get albedo alpha
            float albedoAlpha = textureLod(tex, texCoord, 0).a;

            #ifdef DYNAMIC_CLOUDS
                float fade = smootherstep(sin(frameTimeCounter * FADE_SPEED) * 0.5 + 0.5);
                float albedoAlpha2 = textureLod(tex, 0.5 - texCoord, 0).a;

                #ifdef FORCE_DISABLE_WEATHER
                    albedoAlpha = mix(albedoAlpha, albedoAlpha2, fade);
                #else
                    albedoAlpha = mix(mix(albedoAlpha, albedoAlpha2, fade), max(albedoAlpha, albedoAlpha2), rainStrength);
                #endif
            #endif

            // Alpha test, discard immediately
            if(albedoAlpha < ALPHA_THRESHOLD) discard;

            #if COLOR_MODE == 2
                vec4 albedo = vec4(0, 0, 0, albedoAlpha);
            #else
                vec4 albedo = vec4(1, 1, 1, albedoAlpha);
            #endif

            // Apply simple shading
            vec4 sceneCol = simpleShadingGbuffers(albedo);

        /* DRAWBUFFERS:03 */
            gl_FragData[0] = sceneCol; // gcolor
            gl_FragData[1] = vec4(0, 0, 0, 1); // colortex3
        }
    #endif
#endif