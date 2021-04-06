#ifdef VERTEX
    varying vec2 texcoord;

    void main() {
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    varying vec2 texcoord;

    void main() {
        vec3 color = texture2D(gcolor, texcoord).rgb;

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1.0); //gcolor
    }
#endif