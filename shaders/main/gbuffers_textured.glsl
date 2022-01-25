#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec2 lmCoord;
INOUT vec2 texCoord;

INOUT vec3 norm;

INOUT vec4 glcolor;

// View matrix uniforms
uniform mat4 gbufferModelViewInverse;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	    norm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
        
	    gl_Position = ftransform();

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    // Shadow view matrix uniforms
    uniform mat4 shadowModelView;

    // Shadow projection matrix uniforms
    uniform mat4 shadowProjection;

    /* Position uniforms */
    uniform vec3 cameraPosition;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #if ANTI_ALIASING == 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    // Get world time
    uniform float day;
    uniform float dawnDusk;
    uniform float twilight;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float rainStrength;

    uniform ivec2 eyeBrightnessSmooth;

    uniform vec3 fogColor;

    #include "/lib/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	    posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;
        posVector.feetPlayerPos = posVector.eyePlayerPos + gbufferModelViewInverse[3].xyz;
        posVector.lightPos = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
        // vec3(0, 0, 1) * mat3(shadowModelView)
        // shadowLightPosition is broken in the End
        // mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz
	
		#ifdef SHD_ENABLE
			posVector.shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * posVector.feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
		#endif

	    // Declare materials
	    matPBR material;

        material.albedo = texture2D(texture, texCoord);
        // Assign normals
        material.normal = norm;

        #if WHITE_MODE == 0
            material.albedo.rgb *= glcolor.rgb;
        #elif WHITE_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo.rgb = glcolor.rgb;
        #endif

        vec4 sceneCol = vec4(0);

        if(material.albedo.a > 0.00001){
            material.albedo.rgb = pow(material.albedo.rgb, vec3(GAMMA));

            material.metallic = 0.0;
            material.ss = 1.0;
            material.emissive = 0.0;
            material.smoothness = 0.0;

            // Apply vanilla AO
            material.ambient = 1.0;
            material.light = lmCoord;

            #if ANTI_ALIASING == 2
                sceneCol = complexShadingGbuffers(material, posVector, toRandPerFrame(getRand1(posVector.screenPos.xy, 8), frameTimeCounter));
            #else
                sceneCol = complexShadingGbuffers(material, posVector, getRand1(posVector.screenPos.xy, 8));
            #endif
        } else discard;

    /* DRAWBUFFERS:012 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
    }
#endif