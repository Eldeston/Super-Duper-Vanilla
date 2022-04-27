#ifdef VERTEX
    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #if ANTI_ALIASING == 2
        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
    #endif

    const mat4 viewScale = mat4(
        0.99609375, 0, 0, 0,
        0, 0.99609375, 0, 0,
        0, 0, 0.99609375, 0,
        0, 0, 0, 1
    );

    void main(){
        #ifdef WORLD_CURVATURE
            // Feet player pos
            vec4 linePosStart = gbufferModelViewInverse * (gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0));
            vec4 linePosEnd = gbufferModelViewInverse * (gl_ModelViewMatrix * vec4(gl_Vertex.xyz + gl_Normal.xyz, 1.0));

            linePosStart.y -= dot(linePosStart.xz, linePosStart.xz) / WORLD_CURVATURE_SIZE;
            linePosEnd.y -= dot(linePosEnd.xz, linePosEnd.xz) / WORLD_CURVATURE_SIZE;
            
            linePosStart = gbufferModelView * linePosStart;
            linePosEnd = gbufferModelView * linePosEnd;
        #else
            // Feet player pos
            vec4 linePosStart = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
            vec4 linePosEnd = gl_ModelViewMatrix * vec4(gl_Vertex.xyz + gl_Normal.xyz, 1.0);
        #endif

        linePosStart = gl_ProjectionMatrix * viewScale * linePosStart;
        linePosEnd = gl_ProjectionMatrix * viewScale * linePosEnd;

        vec3 ndc1 = linePosStart.xyz / linePosStart.w;
        vec3 ndc2 = linePosEnd.xyz / linePosEnd.w;

        vec2 lineScreenDirection = normalize((ndc2.xy - ndc1.xy) * vec2(viewWidth, viewHeight));
        vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) / vec2(viewWidth, viewHeight);

        if(lineOffset.x < 0.0) lineOffset *= -1.0;

        if(gl_VertexID % 2 == 0) gl_Position = vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);
        else gl_Position = vec4((ndc1 - vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

#ifdef FRAGMENT
    void main(){
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(0, 0, 0, 1); //gcolor
    }
#endif