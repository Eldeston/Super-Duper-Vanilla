#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D colortex2;

    #ifdef SSAO
        uniform sampler2D depthtex0;
        uniform sampler2D colortex1;

        /* Matrix uniforms */
        // View matrix uniforms
        uniform mat4 gbufferModelView;

        // Projection matrix uniforms
        uniform mat4 gbufferProjection;
        uniform mat4 gbufferProjectionInverse;
        
        #if ANTI_ALIASING == 2
            // Get frame time
            uniform float frameTimeCounter;
        #endif

        #include "/lib/utility/convertViewSpace.glsl"
        #include "/lib/utility/convertScreenSpace.glsl"
        #include "/lib/utility/noiseFunctions.glsl"

        #include "/lib/lighting/ambientOcclusion.glsl"
    #endif

    void main(){
        #ifdef SSAO
            vec2 scaledSreenPos = texCoord;
            float padding = 0.5 + 0.005;

            float ambientOcclusion = 1.0;

            if(abs(scaledSreenPos.x - 0.5) < padding && abs(scaledSreenPos.y - 0.5) < padding){
                // Declare and get positions
                vec3 screenPos = vec3(scaledSreenPos, texture2D(depthtex0, scaledSreenPos).x);

                // If not sky, don't calculate lighting
                if(screenPos.z != 1 && screenPos.z > 0.56){
                    vec3 viewPos = toView(screenPos);
                    vec3 normal = texture2D(colortex1, scaledSreenPos).xyz * 2.0 - 1.0;

                    #if ANTI_ALIASING == 2
                        vec3 dither = toRandPerFrame(getRand3(gl_FragCoord.xy * 0.03125), frameTimeCounter);
                    #else
                        vec3 dither = getRand3(gl_FragCoord.xy * 0.03125);
                    #endif

                    ambientOcclusion = getAmbientOcclusion(viewPos, mat3(gbufferModelView) * normal, dither);
                }
            }
            
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(texture2D(colortex2, texCoord).rgb, ambientOcclusion); // colortex2
        #else
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(texture2D(colortex2, texCoord).rgb, 1); // colortex2
        #endif
    }
#endif