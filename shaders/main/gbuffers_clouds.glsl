/*
================================ /// Super Duper Vanilla v1.3.6 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.6 /// ================================
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

        #ifdef WORLD_LIGHT
            flat out float vertexNLZ;

            #ifdef SHADOW_MAPPING
                flat out float vertexNLX;
                flat out float vertexNLY;

                out vec3 vertexShdPos;
            #endif
        #endif

        uniform mat4 gbufferModelViewInverse;

        #ifdef DOUBLE_LAYERED_CLOUDS
            uniform mat4 gbufferModelView;
        #endif

        #ifdef WORLD_LIGHT
            uniform mat4 shadowModelView;

            #ifdef SHADOW_MAPPING
                uniform mat4 shadowProjection;
            #endif
        #endif

        #if ANTI_ALIASING == 2
            uniform int frameMod;

            uniform float pixelWidth;
            uniform float pixelHeight;

            #include "/lib/utility/taaJitter.glsl"
        #endif

        #ifdef DOUBLE_LAYERED_CLOUDS
            // Set the amount of instances, we'll use 2 for now for performance
            const int countInstances = 2;

            uniform int instanceId;
        #endif

        void main(){
            // Get buffer texture coordinates
            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

            // Get vertex view position
            vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

            #if defined SHADOW_MAPPING && defined WORLD_LIGHT || defined DOUBLE_LAYERED_CLOUDS
                // Get vertex feet player position
                vec3 vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;
            #endif

            #ifdef DOUBLE_LAYERED_CLOUDS
                // May need to work on this to add more than 2 clouds in the future.
                if(instanceId == 1){
                    // If second instance, invert texture coordinates.
                    texCoord = -texCoord;
                    // Increase cloud height for the second instance.
                    vertexFeetPlayerPos.y += SECOND_CLOUD_HEIGHT;
                }

                // Convert back to vertex view position
                vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;
            #endif

            #ifdef WORLD_LIGHT
                vec3 vertexNormal = mat3(gbufferModelViewInverse) * fastNormalize(gl_NormalMatrix * gl_Normal);

                vertexNLZ = dot(vertexNormal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));

                #ifdef SHADOW_MAPPING
                    // Since we already have vertexNLZ, we just need NLX and NLY to complete the shadow normal
                    vertexNLX = dot(vertexNormal, vec3(shadowModelView[0].x, shadowModelView[1].x, shadowModelView[2].x));
                    vertexNLY = dot(vertexNormal, vec3(shadowModelView[0].y, shadowModelView[1].y, shadowModelView[2].y));

                    // Calculate shadow pos in vertex
                    vertexShdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexFeetPlayerPos + shadowModelView[3].xyz);
                    vertexShdPos.z += shadowProjection[3].z;
                    vertexShdPos.z = vertexShdPos.z * 0.1 + 0.5;
                #endif
            #endif

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
    #if defined FORCE_DISABLE_CLOUDS || defined STORY_MODE_CLOUDS
        void main(){
            discard; return;
        }
    #else
        /* RENDERTARGETS: 0,3 */
        layout(location = 0) out vec4 sceneColOut; // gcolor
        layout(location = 1) out vec3 materialDataOut; // colortex3

        in vec2 texCoord;

        #ifdef WORLD_LIGHT
            flat in float vertexNLZ;

            #ifdef SHADOW_MAPPING
                flat in float vertexNLX;
                flat in float vertexNLY;

                in vec3 vertexShdPos;
            #endif
        #endif

        uniform float nightVision;

        uniform sampler2D tex;

        #ifdef IS_IRIS
            uniform float lightningFlash;
        #endif

        #ifdef DYNAMIC_CLOUDS
            uniform float fragmentFrameTime;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
        #endif

        #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
            uniform float frameFract;
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

            #ifdef SHADOW_MAPPING
                #ifdef SHADOW_FILTER
                    #include "/lib/utility/noiseFunctions.glsl"
                #endif

                #include "/lib/lighting/shdMapping.glsl"
            #endif
        #endif

        #include "/lib/lighting/basicShadingForward.glsl"

        void main(){
            // Get albedo alpha
            float albedoAlpha = textureLod(tex, texCoord, 0).a;

            #ifdef DYNAMIC_CLOUDS
                float fade = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);
                float albedoAlpha2 = textureLod(tex, 0.5 - texCoord, 0).a;

                #ifdef FORCE_DISABLE_WEATHER
                    albedoAlpha = mix(albedoAlpha, albedoAlpha2, fade);
                #else
                    albedoAlpha = mix(mix(albedoAlpha, albedoAlpha2, fade), max(albedoAlpha, albedoAlpha2), rainStrength);
                #endif
            #endif

            // Alpha test, discard and return immediately
            if(albedoAlpha < ALPHA_THRESHOLD){ discard; return; }

            #if COLOR_MODE == 2
                vec4 albedo = vec4(0, 0, 0, albedoAlpha);
            #else
                vec4 albedo = vec4(1, 1, 1, albedoAlpha);
            #endif

            // Apply simple shading
            sceneColOut = vec4(basicShadingForward(albedo), albedo.a);

            // Write material data
            materialDataOut = vec3(0);
        }
    #endif
#endif