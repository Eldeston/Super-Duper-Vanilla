#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

varying vec3 norm;

varying vec4 glcolor;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif
    
    uniform mat4 gbufferModelViewInverse;

    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	    norm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
        
	    #ifdef WORLD_CURVATURE
            // Feet player pos
            vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

            vertexPos.y -= lengthSquared(vertexPos.xz) / WORLD_CURVATURE_SIZE;
            
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    void main(){
        vec4 albedo = texture2D(texture, texCoord);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

        #if WHITE_MODE == 0
            albedo.rgb *= glcolor.rgb;
        #elif WHITE_MODE == 1
            albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            albedo.rgb = glcolor.rgb;
        #endif

        float emissive = getLuminance(albedo.rgb);
        albedo.rgb = pow(albedo.rgb, vec3(GAMMA));

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(albedo.rgb * (1.0 + emissive * EMISSIVE_INTENSITY), 1); //gcolor
    }
#endif