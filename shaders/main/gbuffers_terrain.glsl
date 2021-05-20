#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

#include "/lib/vertexWave.glsl"
#include "/lib/PBR.glsl"

INOUT float blockId;

INOUT vec2 lmcoord;
INOUT vec2 texcoord;

INOUT vec3 norm;
INOUT vec3 worldPos;

INOUT vec4 glcolor;

INOUT mat3 TBN;

#ifdef VERTEX
    attribute vec2 mc_midTexCoord;

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
        vec4 vertexPos = gl_ModelViewMatrix * gl_Vertex;
        vec3 camPos = (gbufferModelViewInverse)[3].xyz + cameraPosition;

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        blockId = mc_Entity.x;

        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	    vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * sign(at_tangent.w));

	    norm = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(tangent, binormal, norm);

        // Viewpos
        vertexPos = gbufferModelViewInverse * vertexPos;
        worldPos = vertexPos.xyz + camPos;

	    getWave(vertexPos.xyz, vertexPos.xyz + cameraPosition, texcoord, mc_midTexCoord, mc_Entity.x);

	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D lightmap;
    uniform sampler2D texture;

    void main(){
        vec4 color = texture2D(texture, texcoord);

        // Declare positions
        positionVectors posVector;

	    // Declare materials
	    matPBR materials;

        float maxCol = maxC(color.rgb); float satCol = rgb2hsv(color).y;
        int rBlockId = int(blockId + 0.5);

        #ifdef DEFAULT_MAT
            materials.metallic_m = (rBlockId >= 10008 && rBlockId <= 10010) || rBlockId == 10015 ? 0.75 : 0.0;
            materials.ss_m = (rBlockId >= 10001 && rBlockId <= 10004) || rBlockId == 10007 || rBlockId == 10011 || rBlockId == 10013 ? sqrt(maxCol) * 0.8 : 0.0;
            materials.emissive_m = rBlockId == 10005 || rBlockId == 10006 ? maxCol
                : rBlockId == 10014 ? satCol : 0.0;
            materials.roughness_m = (rBlockId >= 10008 && rBlockId <= 10010) || rBlockId == 10015 ? 0.2 * maxCol : 1.0;
            materials.normal_m = norm;
            materials.ambient_m = 1.0;
        #else
            // If water
            if(rBlockId == 10008){
                materials.normal_m = norm;
            } else {
                getPBR(materials, TBN, texcoord);
            }
        #endif
        materials.normal_m = mat3(gbufferModelViewInverse) * materials.normal_m;

        if(rBlockId == 10008){
            vec2 waterUv = worldPos.xz * (1.0 - materials.normal_m.y) + worldPos.xz * materials.normal_m.y;
            vec4 waterData = H2NWater(waterUv);
            waterData.w = waterData.w;

            vec3 waterNorm = normalize(TBN * waterData.xyz);
		    materials.normal_m = mat3(gbufferModelViewInverse) * waterNorm;
            materials.metallic_m = 0.99;
            materials.ss_m = 0.0;
            materials.emissive_m = 0.0;
            materials.roughness_m = 0.0;
            materials.ambient_m = 1.0;
            color = vec4(color.rgb, 0.5);
        }

        vec4 nGlcolor = glcolor * (1.0 - materials.emissive_m) + sqrt(sqrt(glcolor)) * materials.emissive_m;

        #ifndef WHITE_MODE
            color.rgb *= nGlcolor.rgb;
        #else
            #ifdef WHITE_MODE_F
                color.rgb = nGlcolor.rgb;
            #else
                color.rgb = vec3(1);
            #endif
        #endif

    /* DRAWBUFFERS:01234 */
        gl_FragData[0] = color; //gcolor
        gl_FragData[1] = vec4(materials.normal_m * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(lmcoord, materials.ss_m, 1); //colortex2
        gl_FragData[3] = vec4(materials.metallic_m, materials.emissive_m, max(materials.roughness_m, 0.025), 1); //colortex3
        gl_FragData[4] = vec4(materials.ambient_m, 0, 1, 1); //colortex4
    }
#endif