#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/gameUniforms.glsl"
#include "/lib/globalVars/timeUniforms.glsl"

uniform int blockEntityId;

INOUT vec2 lmCoord;
INOUT vec2 texCoord;

#if DEFAULT_MAT != 2 && defined AUTO_GEN_NORM
    INOUT vec2 minTexCoord;
    INOUT vec2 maxTexCoord;
#endif

INOUT vec4 glcolor;

INOUT mat3 TBN;

#ifdef VERTEX
    #include "/lib/vertex/vertexWave.glsl"

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    attribute vec2 mc_midTexCoord;

    attribute vec4 at_tangent;

    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	    vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * sign(at_tangent.w));
	    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(gbufferModelViewInverse) * mat3(tangent, binormal, normal);

        #ifdef ANIMATE
            vec3 worldPos = vertexPos.xyz + cameraPosition;
	        getWave(vertexPos.xyz, worldPos, texCoord, mc_midTexCoord, float(blockEntityId), lmCoord.y);
        #endif

        #if DEFAULT_MAT != 2 && defined AUTO_GEN_NORM
            vec2 texSize = abs(texCoord - mc_midTexCoord.xy);
            minTexCoord = mc_midTexCoord.xy - texSize;
            maxTexCoord = mc_midTexCoord.xy + texSize;
            texCoord = step(mc_midTexCoord.xy, texCoord);
        #endif
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    #include "/lib/globalVars/matUniforms.glsl"
    #include "/lib/globalVars/posUniforms.glsl"
    #include "/lib/globalVars/screenUniforms.glsl"
    #include "/lib/globalVars/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/lighting/PBR.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	    posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;
        posVector.feetPlayerPos = posVector.eyePlayerPos + gbufferModelViewInverse[3].xyz;

        #ifdef END
			posVector.lightPos = shadowLightPosition;
		#else
			posVector.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz;
		#endif
	
		#ifdef SHD_ENABLE
			posVector.shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * posVector.feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
		#endif

	    // Declare materials
	    matPBR material;
        getPBR(material, posVector, TBN, glcolor.rgb, texCoord, blockEntityId);

        vec4 sceneCol = vec4(0);

        if(material.albedo.a > 0.00001){
            material.albedo.rgb = pow(material.albedo.rgb, vec3(GAMMA));

            // Apply vanilla AO
            material.ambient *= glcolor.a;
            material.light = lmCoord;

            #ifdef ENVIRO_MAT
                enviroPBR(material, posVector, TBN[2]);
            #endif

            sceneCol = complexShadingGbuffers(material, posVector, getRand1(posVector.screenPos.xy, 8));
        } else discard;

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
        gl_FragData[3] = vec4(material.metallic, material.emissive, material.smoothness, 1); //colortex3
    }
#endif