#ifdef VERTEX
    varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

    void main() {
        gl_Position = ftransform();
        starData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
    }
#endif

#ifdef FRAGMENT
    uniform float viewHeight;
    uniform float viewWidth;
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjectionInverse;
    uniform vec3 fogColor;
    uniform vec3 skyColor;

    varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

    float fogify(float x, float w) {
        return w / (x * x + w);
    }

    vec3 calcSkyColor(vec3 pos) {
        float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
        return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 0.25));
    }

    void main() {
        vec3 color;
        if (starData.a > 0.5) {
            color = starData.rgb;
        }
        else {
            vec4 pos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
            pos = gbufferProjectionInverse * pos;
            color = calcSkyColor(normalize(pos.xyz));
        }

    /* DRAWBUFFERS:034 */
        gl_FragData[0] = vec4(color, 1.0); //gcolor
        gl_FragData[1] = vec4(0.0, 1.0, 0.0, 1.0); //colortex3
        gl_FragData[2] = vec4(0.0, 0.0, 1.0, 1.0); //colortex3
    }
#endif