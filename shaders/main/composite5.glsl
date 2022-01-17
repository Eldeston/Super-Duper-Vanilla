#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #ifdef DOF
        const bool gcolorMipmapEnabled = true;

        const float centerDepthHalflife = 1.0;

        uniform sampler2D depthtex1;

        uniform mat4 gbufferProjectionInverse;
        
        uniform float centerDepthSmooth;
        uniform float viewWidth;
        uniform float viewHeight;

        float toView(float depth){
            return gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * (depth * 2.0 - 1.0) + gbufferProjectionInverse[3].w);
        }

        #include "/lib/utility/noiseFunctions.glsl"
    #endif

    void main(){
        #ifdef DOF
            float depth = min(1.0, abs(toView(texture2D(depthtex1, texcoord).r) - toView(centerDepthSmooth)) / FOCAL_RANGE);
            float dither = getRand1(texcoord, 8) * PI2;
            vec2 randVec = (vec2(sin(dither), cos(dither)) * depth) / (vec2(viewWidth, viewHeight) / exp2(DOF_LOD));
            
            vec3 color = texture2D(gcolor, texcoord + randVec).rgb;
            color = (color + texture2D(gcolor, texcoord - randVec).rgb) * 0.5;
        #else
            vec3 color = texture2D(gcolor, texcoord).rgb;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor
    }
#endif