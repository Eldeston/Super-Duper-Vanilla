/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    flat out mat3 TBN;

    out vec2 lmCoord;
    out vec2 texCoord;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;
        out vec2 vTexCoord;
    #endif

    out vec3 vertexColor;

    out vec4 vertexPos;

    // View matrix uniforms
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        attribute vec4 mc_midTexCoord;
    #endif

    attribute vec4 at_tangent;

    void main(){
        // Get texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        // Lightmap fix for mods
        #ifdef WORLD_SKYLIGHT
            lmCoord = vec2(saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).x - 0.03125) * 1.06667), WORLD_SKYLIGHT);
        #else
            lmCoord = saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) * 1.06667);
        #endif

        // Calculate TBN matrix
        vec3 tangent = normalize(at_tangent.xyz);
        vec3 normal = normalize(gl_Normal);

	    TBN = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * mat3(tangent, cross(tangent, normal), normal));

        // Feet player pos
        vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif
        
	    #ifdef WORLD_CURVATURE
            vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
            
            // Clip pos
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        vertexColor = gl_Color.rgb;
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    flat in mat3 TBN;

    in vec2 lmCoord;
    in vec2 texCoord;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;
        in vec2 vTexCoord;
    #endif

    in vec3 vertexColor;

    in vec4 vertexPos;

    // Get albedo texture
    uniform sampler2D texture;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif

    // Get entity id
    uniform int blockEntityId;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    // Get frame time
    uniform float frameTimeCounter;

    #if TIMELAPSE_MODE != 0
        uniform float animationFrameTime;

        float newFrameTimeCounter = animationFrameTime;
    #else
        float newFrameTimeCounter = frameTimeCounter;
    #endif

    #include "/lib/universalVars.glsl"

    // Get is eye in water
    uniform int isEyeInWater;

    // Get night vision
    uniform float nightVision;

    // Derivatives
    vec2 dcdx = dFdx(texCoord);
    vec2 dcdy = dFdy(texCoord);
    
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/PBR/structPBR.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/defaultPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // End portal
        if(blockEntityId == 10016){
            // End star uv
            vec2 screenPos = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

            vec2 endStarOffset = vec2(0, newFrameTimeCounter * 0.01);
            float endStarField = texture2D(texture, (screenPos.yx + endStarOffset) * 0.5).r;
            endStarField += texture2D(texture, screenPos + endStarOffset).r;
            endStarField += texture2D(texture, (endStarOffset - screenPos) * 2.0).r;
            
            vec2 endStarCoord1 = screenPos * rot2D(0.78539816);
            endStarField += texture2D(texture, endStarCoord1.yx + endStarOffset).r;
            endStarField += texture2D(texture, (endStarCoord1 + endStarOffset) * 2.0).r;
            endStarField += texture2D(texture, (endStarOffset - endStarCoord1) * 4.0).r;

            vec3 endPortalAlbedo = toLinear((endStarField + 0.1) * (getRand3(ivec2(screenPos * 128.0) & 255) * 0.5 + 0.5) * vertexColor.rgb);
            
            gl_FragData[0] = vec4(endPortalAlbedo * EMISSIVE_INTENSITY * EMISSIVE_INTENSITY, 1); // gcolor

            // End portal fix
            gl_FragData[1] = vec4(TBN[2], 1); // colortex1
            gl_FragData[3] = vec4(0, 0, 0, 1); // colortex3

            return; // Return immediately, no need for lighting calculation
        }

	    // Declare materials
	    structPBR material;
        getPBR(material, blockEntityId);
        
        material.albedo.rgb = toLinear(material.albedo.rgb);

        vec4 sceneCol = complexShadingGbuffers(material);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(material.normal, 1); // colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); // colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); // colortex3
    }
#endif