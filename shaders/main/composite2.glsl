#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main() {
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

        #ifdef AUTO_EXPOSURE
            // Get lod
            float lod = int(exp2(min(viewWidth, viewHeight))) - 1.0;
            
            // Get current average scene luminance...
            // Middle pixel
            float lumiCurrent = maxC(texture2D(gcolor, vec2(0.5), lod).rgb);
            // Top right pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(1), lod).rgb);
            // Top left pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(0, 1), lod).rgb);
            // Bottom right pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(1, 0), lod).rgb);
            // Bottom left pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(0), lod).rgb);

            // Previous max luminance
            float lumiPrev = texture2D(colortex6, vec2(0.5), lod).r;
            // Mix previous and current buffer...
            float finalLumi = mix(lumiCurrent / 5.0, lumiPrev, exp2(-1.0 * frameTime));

            // Calculate luminance
            float lumi = finalLumi;
            // Apply exposure
            color /= max(lumi * 2.0, 0.5);
        #endif
        color *= EXPOSURE;
        // Clamp
        color = saturate(color);
        // A simple tonemap with the help of Desmos...
        // color = mix(color, pow(color / 1.2, vec3(1.2)), color);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #ifdef AUTO_EXPOSURE
        /* DRAWBUFFERS:06 */
            gl_FragData[1] = vec4(finalLumi, 0, 0, 1); //colortex6
        #endif
    }
#endif