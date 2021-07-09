#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec2 lmCoord;
INOUT vec2 texCoord;

INOUT vec3 norm;

INOUT vec4 glcolor;

#ifdef VERTEX
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	    norm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    void main(){
	    // Declare materials
	    matPBR materials;

        materials.albedo_t = vec4(glcolor.rgb, 1);
        // Assign normals
        materials.normal_m = norm;

        #if WHITE_MODE == 1
            materials.albedo_t.rgb = vec3(1);
        #elif WHITE_MODE == 2
            materials.albedo_t.rgb = vec3(0);
        #endif

        materials.metallic_m = 0.0;
        materials.ss_m = 1.0;
        materials.emissive_m = 1.0;
        materials.roughness_m = 1.0;

        materials.albedo_t.rgb = pow(materials.albedo_t.rgb, vec3(GAMMA));

        // Apply vanilla AO
        materials.ambient_m = 1.0;
        materials.light_m = lmCoord;

        vec4 sceneCol = materials.albedo_t + materials.albedo_t * materials.emissive_m;

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(materials.normal_m * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = materials.albedo_t; //colortex2
        gl_FragData[3] = vec4(materials.metallic_m, materials.emissive_m, materials.roughness_m, 1); //colortex3
    }
#endif