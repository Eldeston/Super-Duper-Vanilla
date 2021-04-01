#ifdef VERTEX
    varying vec2 texcoord;
    varying vec4 glcolor;

    void main() {
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    varying vec2 texcoord;
    varying vec4 glcolor;

    void main() {
        vec4 color = texture2D(texture, texcoord) * glcolor;

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = color; //gcolor
    }
#endif