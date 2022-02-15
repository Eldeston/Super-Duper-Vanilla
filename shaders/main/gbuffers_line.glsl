#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/structs.glsl"

varying vec4 glcolor;

#ifdef VERTEX
    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #if ANTI_ALIASING == 2
        #include "/lib/utility/taaJitter.glsl"
    #endif

    const float VIEW_SHRINK = 1.0 - (1.0 / 256.0);
    const mat4 VIEW_SCALE = mat4(
        VIEW_SHRINK, 0.0, 0.0, 0.0,
        0.0, VIEW_SHRINK, 0.0, 0.0,
        0.0, 0.0, VIEW_SHRINK, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    void main() {
        vec4 linePosStart = gl_ProjectionMatrix * VIEW_SCALE * gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
        vec4 linePosEnd = gl_ProjectionMatrix * VIEW_SCALE * gl_ModelViewMatrix * vec4(gl_Vertex.xyz + gl_Normal.xyz, 1.0);

        vec3 ndc1 = linePosStart.xyz / linePosStart.w;
        vec3 ndc2 = linePosEnd.xyz / linePosEnd.w;

        vec2 ScreenSize = vec2(viewWidth, viewHeight);
        vec2 lineScreenDirection = normalize((ndc2.xy - ndc1.xy) * ScreenSize);
        vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) / ScreenSize;

        if(lineOffset.x < 0.0) lineOffset *= -1.0;

        if(gl_VertexID % 2 == 0) gl_Position = vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);
        else gl_Position = vec4((ndc1 - vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    void main(){
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = glcolor; //gcolor
    }
#endif