flat varying int blockId;

varying vec2 texCoord;

varying vec3 worldPos;
varying vec3 glcolor;

// Get frame time
uniform float frameTimeCounter;

#ifdef VERTEX
    // Position uniforms
    uniform vec3 cameraPosition;
    
    #if TIMELAPSE_MODE == 2
        uniform float animationFrameTime;

        float newFrameTimeCounter = animationFrameTime;
    #else
        float newFrameTimeCounter = frameTimeCounter;
    #endif

    uniform mat4 shadowModelView;
    uniform mat4 shadowModelViewInverse;
    uniform mat4 shadowProjection;
    uniform mat4 shadowProjectionInverse;

    #include "/lib/lighting/shdDistort.glsl"

    #include "/lib/vertex/vertexAnimations.glsl"

    attribute vec2 mc_midTexCoord;
    attribute vec4 mc_Entity;

    void main(){
        vec4 vertexPos = shadowModelViewInverse * (shadowProjectionInverse * ftransform());
        worldPos = vertexPos.xyz + cameraPosition;

        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        blockId = int(mc_Entity.x);
        
        #ifdef ANIMATE
            getVertexAnimations(vertexPos.xyz, worldPos, texCoord, mc_midTexCoord, mc_Entity.x, (gl_TextureMatrix[1] * gl_MultiTexCoord1).y);
        #endif

        #ifdef WORLD_CURVATURE
            vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
        #endif

        gl_Position = shadowProjection * (shadowModelView * vertexPos);

        gl_Position.xyz = distort(gl_Position.xyz);

        glcolor = gl_Color.rgb;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D tex;
    
    #if UNDERWATER_CAUSTICS != 0 && defined SHD_COL
        #if UNDERWATER_CAUSTICS == 1
            uniform int isEyeInWater;
        #endif

        #if TIMELAPSE_MODE != 0
            uniform float animationFrameTime;

            float newFrameTimeCounter = animationFrameTime;
        #else
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

                shdAlbedo.rgb = pow(shdAlbedo.rgb * glcolor, vec3(GAMMA));
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
#endif