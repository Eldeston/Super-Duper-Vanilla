/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, and direct shading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef FORCE_DISABLE_WEATHER
        void main(){
            gl_Position = vec4(-10);
        }
    #else
        flat out float lmCoordX;

        out vec2 texCoord;

        #if ANTI_ALIASING == 2
            uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

            #include "/lib/utility/taaJitter.glsl"
        #endif

        uniform vec3 cameraPosition;
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;

        #ifdef WEATHER_ANIMATION
            uniform float rainStrength;
            uniform float vertexFrameTime;
            #include "/lib/vertex/weatherWave.glsl"
        #endif

        void main(){
            // Lightmap fix for mods
            lmCoordX = lightMapCoord(gl_MultiTexCoord1.x);
            // Get buffer texture coordinates
            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

            // Get vertex view position
            vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

            // Get vertex eye player position
            vec3 vertexEyePlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos;

            // No rain above the clouds (cloud base ~192.0):
            // Cull entire rain rendering if player is flying above clouds or if particles are above cloud altitude
            float vertexWorldPosY = vertexEyePlayerPos.y + gbufferModelViewInverse[3].y + cameraPosition.y;
            if(cameraPosition.y >= 192.0 || vertexWorldPosY >= 192.0){
                gl_Position = vec4(-10.0);
                return;
            }

            #ifdef WEATHER_ANIMATION
                // Get vertex feet player position
                vec2 vertexFeetPlayerPosXZ = vertexEyePlayerPos.xz + gbufferModelViewInverse[3].xz;
                // Get vertex world position
                vec2 vertexWorldPosXZ = vertexFeetPlayerPosXZ + cameraPosition.xz;

                // Apply weather wave animation
                if(rainStrength >= 0.005) vertexEyePlayerPos.xz = getWeatherWave(vertexEyePlayerPos, vertexWorldPosXZ);

                // Convert back to vertex view position
                vertexViewPos = mat3(gbufferModelView) * vertexEyePlayerPos;
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
    #ifdef FORCE_DISABLE_WEATHER
        void main(){
            discard; return;
        }
    #else
        /* RENDERTARGETS: 4,3 */
        layout(location = 0) out vec4 sceneColOut; // colortex4
        layout(location = 1) out vec3 weatherMatOut; // colortex3

        flat in float lmCoordX;

        in vec2 texCoord;

        uniform float nightVision;
        uniform float lightningFlash;

        uniform sampler2D gtexture;

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
        #endif

        #if defined WORLD_VANILLA_FOG_COLOR || !defined FORCE_DISABLE_WEATHER
            uniform vec3 fogColor;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
            uniform float weatherFade;
        #endif

        #ifndef CAMERA_POSITION_DECLARED
            #define CAMERA_POSITION_DECLARED
            uniform vec3 cameraPosition;
        #endif
        
        void main(){
            // No rain above the clouds
            if(cameraPosition.y >= 192.0){ discard; return; }

            // Get albedo color
            vec4 albedo = textureLod(gtexture, texCoord, 0);

            // Alpha test, discard and return immediately
            if(albedo.a < ALPHA_THRESHOLD){ discard; return; }

            // Convert to linear space
            albedo.rgb = toLinear(albedo.rgb);

            #ifndef FORCE_DISABLE_WEATHER
                vec3 skyLightDiffuse = mix(toLinear(SKY_COLOR_DATA_BLOCK), vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722))), weatherFade);
            #else
                vec3 skyLightDiffuse = toLinear(SKY_COLOR_DATA_BLOCK);
            #endif
            vec3 totalDiffuse = skyLightDiffuse + toLinear(lmCoordX * blockLightColor) + toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

            totalDiffuse += toLinear(mix(vec3(1.0), LIGHTNING_COLOR, 0.20)) * lightningFlash;

            sceneColOut = vec4(albedo.rgb * totalDiffuse, albedo.a);
            weatherMatOut = vec3(albedo.a, 0.0, 1.0);
        }
    #endif
#endif