#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/matUniforms.glsl"

INOUT float blockId;

INOUT vec2 lmCoord;
INOUT vec2 texCoord;

INOUT vec4 glcolor;

INOUT mat3 TBN;

#ifdef VERTEX
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
	    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(gbufferModelViewInverse) * mat3(tangent, binormal, normal);
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    #include "/lib/globalVars/gameUniforms.glsl"
    #include "/lib/globalVars/posUniforms.glsl"
    #include "/lib/globalVars/screenUniforms.glsl"
    #include "/lib/globalVars/timeUniforms.glsl"
    #include "/lib/globalVars/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/sky.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/lighting/PBR.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    #include "/lib/assemblers/posAssembler.glsl"
    
    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 dither = getRand3(posVector.screenPos.xy, 8);
	    getPosVectors(posVector);

	    // Declare materials
	    matPBR material;

        int rBlockId = int(blockId + 0.5);
        material.normal_m = TBN[2];
        material.albedo_t = texture2D(texture, texCoord);

        #if WHITE_MODE == 0
            material.albedo_t.rgb *= glcolor.rgb;
        #elif WHITE_MODE == 1
            material.albedo_t.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo_t.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo_t.rgb = glcolor.rgb;
        #endif

        #ifdef DEFAULT_MAT
            getPBR(material, rBlockId);
        #else
            getPBR(material, TBN, texCoord);
        #endif

        // If player
        if(rBlockId == 0) material.ambient_m = 1.0;

        // If water
        if(rBlockId == 10014){
            material.metallic_m = 0.5;
            material.roughness_m = 0.028;
            material.ambient_m = 1.0;
        }

        // If lava
        if(rBlockId == 10010){
            material.emissive_m = 1.0;
            material.roughness_m = 1.0;
            material.ambient_m = 1.0;
        }

        material.albedo_t.rgb = mix(material.albedo_t.rgb, entityColor.rgb, entityColor.a);

        material.albedo_t.rgb = pow(material.albedo_t.rgb, vec3(GAMMA));

        // Apply vanilla AO
        material.ambient_m *= glcolor.a;
        material.light_m = lmCoord;

        vec4 sceneCol = complexShadingGbuffers(material, posVector, dither);

        // Lightning
        if(rBlockId == 10101){
            material.metallic_m = 0.0;
            material.emissive_m = 1.0;
            material.roughness_m = 1.0;
            sceneCol = vec4(vec3(2), 1);
        }

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal_m * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo_t.rgb, 1); //colortex2
        gl_FragData[3] = vec4(material.metallic_m, material.emissive_m, material.roughness_m, 1); //colortex3
    }
#endif