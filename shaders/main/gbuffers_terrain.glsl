#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/gameUniforms.glsl"
#include "/lib/globalVars/matUniforms.glsl"
#include "/lib/globalVars/posUniforms.glsl"
#include "/lib/globalVars/screenUniforms.glsl"
#include "/lib/globalVars/texUniforms.glsl"
#include "/lib/globalVars/timeUniforms.glsl"
#include "/lib/globalVars/universalVars.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/utility/spaceConvert.glsl"
#include "/lib/utility/texFunctions.glsl"

#include "/lib/atmospherics/sky.glsl"

#include "/lib/lighting/shdMapping.glsl"
#include "/lib/lighting/GGX.glsl"

#include "/lib/lighting/PBR.glsl"

#include "/lib/vertex/vertexWave.glsl"

#include "/lib/lighting/complexShadingForward.glsl"

#include "/lib/assemblers/posAssembler.glsl"

INOUT float blockId;

INOUT vec2 lmCoord;
INOUT vec2 texCoord;

INOUT vec3 norm;

INOUT vec4 glcolor;

INOUT mat3 TBN;

#ifdef VERTEX
    attribute vec2 mc_midTexCoord;

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        blockId = mc_Entity.x;

        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	    vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * sign(at_tangent.w));

	    norm = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(tangent, binormal, norm);

        #ifdef ANIMATE
            vec3 worldPos = vertexPos.xyz + cameraPosition;
	        getWave(vertexPos.xyz, worldPos, texCoord, mc_midTexCoord, mc_Entity.x, lmCoord.y);
        #endif
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    void main(){
        vec4 albedo = texture2D(texture, texCoord);

        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 dither = getRand3(screenPos.xy, 8);

        // Declare and get positions
        positionVectors posVector;
	    getPosVectors(posVector, screenPos);

	    // Declare materials
	    matPBR materials;

        int rBlockId = int(blockId + 0.5);
        materials.normal_m = norm;

        #ifdef DEFAULT_MAT
            getPBR(materials, albedo, rBlockId);
        #else
            getPBR(materials, TBN, texCoord);
        #endif

        albedo.rgb = pow(albedo.rgb, vec3(GAMMA));

        // If lava
        if(rBlockId == 10010){
            materials.emissive_m = 1.0;
            materials.roughness_m = 1.0;
            materials.ambient_m = 1.0;
        }

        #ifndef WHITE_MODE
            albedo.rgb *= glcolor.rgb;
        #else
            #ifdef WHITE_MODE_F
                albedo.rgb = glcolor.rgb;
            #else
                albedo.rgb = vec3(1);
            #endif
        #endif

        // Apply vanilla AO
        materials.ambient_m *= glcolor.a;
        // Transfor final normals to player space
        materials.normal_m = mat3(gbufferModelViewInverse) * materials.normal_m;
        materials.albedo_t = albedo;
        materials.light_m = lmCoord;

        vec4 sceneCol = complexShadingGbuffers(materials, posVector, dither);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(materials.normal_m * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = materials.albedo_t; //colortex2
        gl_FragData[3] = vec4(materials.metallic_m, materials.emissive_m, materials.roughness_m, 1); //colortex3
    }
#endif