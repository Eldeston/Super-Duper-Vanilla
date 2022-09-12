/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out int blockId;

        flat out vec3 vertexColor;

        out vec2 texCoord;

        out vec3 worldPos;

        // View matrix uniforms
        uniform mat4 shadowModelView;
        uniform mat4 shadowModelViewInverse;
        
        #if TIMELAPSE_MODE == 2
            // Get smoothed frame time
            uniform float animationFrameTime;

            float newFrameTimeCounter = animationFrameTime;
        #else
            // Get frame time
            uniform float frameTimeCounter;

            float newFrameTimeCounter = frameTimeCounter;
        #endif

        // Position uniforms
        uniform vec3 cameraPosition;

        #include "/lib/lighting/shdDistort.glsl"

        #include "/lib/vertex/vertexAnimations.glsl"

        attribute vec2 mc_midTexCoord;
        attribute vec4 mc_Entity;

        void main(){
            // Get block id
            blockId = int(mc_Entity.x);
            // Get texture coordinates
            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
            // Get vertex color
            vertexColor = gl_Color.rgb;

            // Get vertex position (feet player pos)
            vec4 vertexPos = shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
            // Get world position
            worldPos = vertexPos.xyz + cameraPosition;
            
            #ifdef ANIMATE
                getVertexAnimations(vertexPos.xyz, worldPos, texCoord, mc_midTexCoord, mc_Entity.x, (gl_TextureMatrix[1] * gl_MultiTexCoord1).y);
            #endif

            #ifdef WORLD_CURVATURE
                vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
            #endif

            // Shadow clip pos
            gl_Position = gl_ProjectionMatrix * (shadowModelView * vertexPos);

            // Apply shadow distortion
            gl_Position.xyz = distort(gl_Position.xyz);
        }
    #else
        void main(){
            gl_Position = vec4(-10);
        }
    #endif
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    #ifdef WORLD_LIGHT
        flat in int blockId;

        flat in vec3 vertexColor;

        in vec2 texCoord;

        in vec3 worldPos;

        uniform sampler2D tex;
        
        #if UNDERWATER_CAUSTICS != 0 && defined SHD_COL
            #if UNDERWATER_CAUSTICS == 1
                uniform int isEyeInWater;
            #endif

            #if TIMELAPSE_MODE != 0
                // Get smoothed frame time
                uniform float animationFrameTime;

                float newFrameTimeCounter = animationFrameTime;
            #else
                // Get frame time
                uniform float frameTimeCounter;

                float newFrameTimeCounter = frameTimeCounter;
            #endif

            #include "/lib/utility/noiseFunctions.glsl"
            #include "/lib/surface/water.glsl"
        #endif

        void main(){
            #ifdef SHD_COL
                vec4 shdAlbedo = texture2D(tex, texCoord);

                // Alpha test, discard immediately
                if(shdAlbedo.a <= ALPHA_THRESHOLD) discard;

                // If the object is not opaque, proceed with shadow coloring and caustics
                if(shdAlbedo.a != 1){
                    if(blockId == 10000){
                        #ifdef WATER_FLAT
                            #if UNDERWATER_CAUSTICS == 2
                                shdAlbedo.rgb = vec3(squared(0.128 + getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 3.2);
                            #elif UNDERWATER_CAUSTICS == 1
                                shdAlbedo.rgb = vec3(0.8);
                                if(isEyeInWater == 1) shdAlbedo.rgb *= squared(0.128 + getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 4.0;
                            #endif
                        #else
                            #if UNDERWATER_CAUSTICS == 2
                                shdAlbedo.rgb *= squared(0.128 + getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 4.0;
                            #elif UNDERWATER_CAUSTICS == 1
                                if(isEyeInWater == 1) shdAlbedo.rgb *= squared(0.128 + getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 4.0;
                            #endif
                        #endif
                    }

                    shdAlbedo.rgb = toLinear(shdAlbedo.rgb * vertexColor);

                    // To give white colored glass some proper shadows except water
                    if(blockId != 10000) shdAlbedo.rgb *= 1.0 - shdAlbedo.a;
                // If the object is fully opaque, set to black. This fixes "color leaking" filtered shadows
                } else shdAlbedo.rgb = vec3(0);

            /* DRAWBUFFERS:0 */
                gl_FragData[0] = shdAlbedo;
            #else
                float shdAlbedoAlpha = texture2D(tex, texCoord).a;

                // Alpha test, discard immediately
                if(shdAlbedoAlpha <= ALPHA_THRESHOLD) discard;

            /* DRAWBUFFERS:0 */
                gl_FragData[0] = vec4(0, 0, 0, shdAlbedoAlpha);
            #endif
        }
    #else
        void main(){
            discard;
        }
    #endif
#endif