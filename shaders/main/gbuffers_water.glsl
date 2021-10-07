#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/gameUniforms.glsl"
#include "/lib/globalVars/timeUniforms.glsl"

INOUT float blockId;

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

    attribute vec2 mcidTexCoord;

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

        #ifdef ANIMATE
            vec3 worldPos = vertexPos.xyz + cameraPosition;
	        getWave(vertexPos.xyz, worldPos, texCoord, mcidTexCoord, mc_Entity.x, lmCoord.y);
        #endif

        #if DEFAULT_MAT != 2 && defined AUTO_GEN_NORM
            vec2 texSize = abs(texCoord - mcidTexCoord.xy);
            minTexCoord = mcidTexCoord.xy - texSize;
            maxTexCoord = mcidTexCoord.xy + texSize;
            texCoord = step(mcidTexCoord.xy, texCoord);
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

    uniform sampler2D depthtex1;
    
    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/spaceConvert.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/fog.glsl"
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
        getPBR(material, posVector, TBN, glcolor.rgb, texCoord, rBlockId);

        vec4 sceneCol = vec4(0);

        if(material.albedo.a > 0.00001){
            // If water
            if(rBlockId == 10034){
                material.albedo.rgb *= WATER_BRIGHTNESS;

                #ifdef WATER_NORM
                    #if !(defined END || defined NETHER)
                        vec4 waterData = H2NWater(posVector.worldPos.xz * (1.0 - TBN[2].y) + posVector.worldPos.xz * TBN[2].y);
                        material.normal = normalize(TBN * waterData.xyz);

                        material.albedo.rgb *= squared(1.0 - waterData.w);
                    #endif

                    /* Water color and foam */
                    #ifdef AUTO_GEN_NORM
                        vec3 flatWater = texture2D(texture, mix(minTexCoord, maxTexCoord, texCoord)).rgb;
                    #else
                        vec3 flatWater = texture2D(texture, texCoord).rgb;
                    #endif

                    float waterDepth = distance(toView(posVector.screenPos.z), toView(texture2D(depthtex1, posVector.screenPos.xy).x));

                    #ifdef STYLIZED_WATER_ABSORPTION
                        vec3 waterColor = exp(-waterDepth * vec3(1, 0.48, 0.24));
                        material.albedo.rgb = material.albedo.rgb * (1.0 - waterColor) + flatWater * waterColor;
                    #endif

                    float waterAlpha = exp(-waterDepth * 0.015);
                    material.albedo.a = mix(sqrt(material.albedo.a), material.albedo.a, waterAlpha);

                    #ifdef WATER_FOAM
                        float foam = min(1.0, exp(-(waterDepth - 0.128) * 10.0));
                        material.albedo = material.albedo * (1.0 - foam) + foam;
                    #endif
                #endif
            }

            material.albedo.rgb = pow(material.albedo.rgb, vec3(GAMMA));
            
            // Apply vanilla AO
            material.ambient *= glcolor.a;
            material.light = lmCoord;

            #ifdef ENVIRO_MAT
                if(rBlockId != 10034) enviroPBR(material, posVector, TBN[2]);
            #endif

            sceneCol = complexShadingGbuffers(material, posVector, dither);
        } else discard;

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
        gl_FragData[3] = vec4(material.metallic, material.emissive, material.smoothness, 1); //colortex3
    }
#endif