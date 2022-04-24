varying vec2 lmCoord;
varying vec2 texCoord;

#ifdef PARALLAX_OCCLUSION
    varying vec2 vTexCoordScale;
    varying vec2 vTexCoordPos;
    varying vec2 vTexCoord;
#endif

varying vec3 glcolor;

varying mat3 TBN;

// View matrix uniforms
uniform mat4 gbufferModelViewInverse;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    #ifdef PARALLAX_OCCLUSION
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

        // Get TBN matrix
        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(gbufferModelViewInverse) * mat3(tangent, cross(tangent, normal), normal);

        #ifdef PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        gl_Position = ftransform();

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color.rgb;
    }
#endif

#ifdef FRAGMENT
    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif
    
    // Get entity id
    uniform int entityId;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #if ANTI_ALIASING == 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    uniform vec4 entityColor;
    
    #include "/lib/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/lighting/PBR.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"
    
    void main(){
        // Declare and get positions
        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * toView(screenPos);
        vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

	    // Declare materials
	    matPBR material;
        getPBR(material, eyePlayerPos, entityId);

        material.albedo.rgb = mix(material.albedo.rgb, entityColor.rgb, entityColor.a);

        material.albedo.rgb = pow(material.albedo.rgb, vec3(GAMMA));

        vec4 sceneCol = complexShadingGbuffers(material, eyePlayerPos, feetPlayerPos);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); //colortex3
    }
#endif