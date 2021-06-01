#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"
#include "/lib/lighting/shdDistort.glsl"
#include "/lib/conversion.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

        #ifdef TEMPORAL_ACCUMULATION
            vec3 prevCol = texture2D(colortex6, texcoord).rgb;
            vec3 accumulated = mix(color, prevCol, exp2(-ACCUMILATION_SPEED * frameTime));
            color = accumulated;
        #else
            vec3 accumulated = vec3(0);
        #endif

        #ifdef AUTO_EXPOSURE
            // Get lod
            float lod = int(exp2(min(viewWidth, viewHeight))) - 1.0;
            
            // Get current average scene luminance...
            // Center pixel
            float lumiCurrent = maxC(texture2D(gcolor, vec2(0.5), lod).rgb);
            // Top right pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(1), lod).rgb);
            // Top left pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(0, 1), lod).rgb);
            // Bottom right pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(1, 0), lod).rgb);
            // Bottom left pixel
            lumiCurrent += maxC(texture2D(gcolor, vec2(0), lod).rgb);

            // Previous luminance
            float lumiPrev = texture2D(colortex6, vec2(0)).a;
            // Mix previous and current buffer...
            float finalLumi = mix(lumiCurrent / 5.0, lumiPrev, exp2(-1.0 * frameTime));

            // Apply exposure
            color /= max(finalLumi * 2.0, 0.6);
        #else
            float finalLumi = 1.0;
        #endif
        color *= EXPOSURE;
        // Tonemap and clamp
        color = saturate(color / (color * 0.2 + 1.0));

        float skyMask = float(texture2D(depthtex0, texcoord).r != 1);
        float luminance = getLuminance(color);
        float emissive = texture2D(colortex3, texcoord).g;

        #ifdef OUTLINES
            /* Outline calculation */
            float offSet = 1.0 / viewWidth;
            float depth0 = toView(texture2D(depthtex0, texcoord).x);

            float depth1 = toView(texture2D(depthtex0, texcoord - offSet).x);
            float depth2 = toView(texture2D(depthtex0, texcoord + offSet).x);

            float depth3 = toView(texture2D(depthtex0, texcoord - vec2(offSet, -offSet)).x);
            float depth4 = toView(texture2D(depthtex0, texcoord + vec2(offSet, -offSet)).x);

            float depth5 = toView(texture2D(depthtex0, texcoord - vec2(offSet, 0)).x);
            float depth6 = toView(texture2D(depthtex0, texcoord + vec2(offSet, 0)).x);

            float depth7 = toView(texture2D(depthtex0, texcoord - vec2(0, offSet)).x);
            float depth8 = toView(texture2D(depthtex0, texcoord + vec2(0, offSet)).x);

            // Calculate the differences of the offsetted depths...
            float totalDepth = depth1 + depth2 + depth3 + depth4 + depth5 + depth6 + depth7 + depth8;
            float dDepth = totalDepth - depth0 * 8.0;

            color *= 1.0 + saturate(dDepth) * (OUTLINE_BRIGHTNESS - 1.0);
        #endif

    /* DRAWBUFFERS:067 */
        gl_FragData[0] = vec4(color, 1); //gcolor
        gl_FragData[1] = vec4(accumulated, finalLumi); //colortex6
        gl_FragData[2] = vec4(color * emissive * skyMask * luminance, 1); //colortex7
    }
#endif