/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: Auto exposure calculation
/// Side comment: The world's tiniest auto exposure program on a 1x1 buffer maximizing the crap out of optimization because why the hell not

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    void main(){
        // I was told it's gonna yoink out the extra triangle somewhere else and use one big triangle
        gl_Position = vec4(vec2((gl_VertexID << 1) & 2, gl_VertexID & 2) * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    #ifdef AUTO_EXPOSURE
        /* RENDERTARGETS: 7 */
        layout(location = 0) out float temporalDataOut; // colortex7

        uniform float frameTime;

        uniform sampler2D colortex4;
        uniform sampler2D colortex7;
    #endif

    void main(){
        #ifdef AUTO_EXPOSURE
            // Accumulate current luminance
            float frameTimeExposure = AUTO_EXPOSURE_SPEED * frameTime;
            frameTimeExposure /= (1.0 + frameTimeExposure);

            // Get center pixel current average scene luminance and mix previous and current pixel...
            float centerPixLuminance = sumOf(textureLod(colortex4, vec2(0.5), 8).rgb);

            // Simulating the exposure adjust after being applied
            const float invMinimumExposure = 1.0 / MINIMUM_EXPOSURE;
            float prevPixLuminance = texelFetch(colortex7, ivec2(0), 0).r;
            centerPixLuminance *= min(inversesqrt(prevPixLuminance), invMinimumExposure);

            temporalDataOut = mix(prevPixLuminance, centerPixLuminance, frameTimeExposure);
        #endif
    }
#endif