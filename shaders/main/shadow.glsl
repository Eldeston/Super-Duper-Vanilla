/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out int blockId;

        out vec2 texCoord;

        out vec3 worldPos;
        out vec3 glColor;

        // View matrix uniforms
        uniform mat4 shadowModelView;
        uniform mat4 shadowModelViewInverse;

        // Position uniforms
        uniform vec3 cameraPosition;
        
        #if TIMELAPSE_MODE == 2
            // Get smoothed frame time
            uniform float animationFrameTime;

            float newFrameTimeCounter = animationFrameTime;
        #else
            // Get frame time
            uniform float frameTimeCounter;

            float newFrameTimeCounter = frameTimeCounter;
        #endif

        #include "/lib/lighting/shdDistort.glsl"

        #include "/lib/vertex/vertexAnimations.glsl"

        attribute vec2 mc_midTexCoord;
        attribute vec4 mc_Entity;

        void main(){
            // Feet player pos
            vec4 vertexPos = shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
            // World pos
            worldPos = vertexPos.xyz + cameraPosition;

            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
            blockId = int(mc_Entity.x);
            
            #ifdef ANIMATE
                getVertexAnimations(vertexPos.xyz, worldPos, texCoord, mc_midTexCoord, mc_Entity.x, (gl_TextureMatrix[1] * gl_MultiTexCoord1).y);
            #endif

            #ifdef WORLD_CURVATURE
                vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
            #endif

            // Shadow clip pos
            gl_Position = gl_ProjectionMatrix * (shadowModelView * vertexPos);

            gl_Position.xyz = distort(gl_Position.xyz);

            glColor = gl_Color.rgb;
        }
    #else
        void main(){
            gl_Position = vec4(0);
        }
    #endif
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    #ifdef WORLD_LIGHT
        flat in int blockId;

        in vec2 texCoord;

        in vec3 worldPos;
        in vec3 glColor;

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
                    #if UNDERWATER_CAUSTICS == 2
                        if(blockId == 10000) shdAlbedo.rgb *= squared(0.128 + getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 4.0;
                    #elif UNDERWATER_CAUSTICS == 1
                        if(isEyeInWater == 1 && blockId == 10000) shdAlbedo.rgb *= squared(0.128 + getCellNoise(worldPos.xz / WATER_TILE_SIZE)) * 4.0;
                    #endif

                    shdAlbedo.rgb = toLinear(shdAlbedo.rgb * glColor);
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