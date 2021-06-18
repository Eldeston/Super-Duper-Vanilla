vec4 parallaxClouds(vec2 uv, int steps, float softness, float thickness){
    float stepSize = 1.0 / float(steps);

    vec2 endPos = uv * stepSize * thickness;

    uv.x += frameTimeCounter / 32.0;

    float density0 = 0.0;
    float density1 = 0.0;
    float density2 = 0.0;
    for(int i = 0; i < steps; i++){
        uv += endPos;
        
        float cloud0 = tex2DBilinear(colortex7, uv / 128.0, vec2(256) * softness).r;
        float cloud1 = tex2DBilinear(colortex7, (uv - 50.0) / 128.0, vec2(256) * softness).r;

        density0 += cloud0;
        density1 += cloud1;
        density2 += max(cloud0, cloud1);
    }

    float fade = smoothstep(0.4, 0.6, sin(frameTimeCounter * 0.125) * 0.5 + 0.5);
    float cloud = mix(mix(density0, density1, fade), density2, sqrt(rainStrength)) * stepSize;

    return vec4(lightCol, cloud);
}