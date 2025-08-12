const uint rayTraceSteps = uint(RAYTRACER_STEPS);
const uint rayTraceBiSteps = uint(RAYTRACER_BISTEPS);

// Raytracer steps inverse
const float rayTracerStepsInv = 1.0 / RAYTRACER_STEPS;

// This raytracer is stupid fast I swear...
// Based from Belmu's raytracer https://github.com/BelmuTM/NobleRT
// Basically an upgrade to Shadax's raytracer https://github.com/Shadax-stack/MinecraftSSR
vec3 rayTraceScene(in vec3 screenPos, in vec3 viewPos, in vec3 rayDir, in float dither){
	// No longer needed as it now uses a depth limit
	// Technically it could still be used for performance reasons
	// Fix for the blob when player is near a surface. From Bálint#1673
	if(rayDir.z > -viewPos.z) return vec3(0);

	// From Lipesto the goat
	// Clip the rayDir by near and far planes
    // float zLimit = (rayDir.z < 0.0 ? viewPos.z + far * 4.0 : -viewPos.z - near) / rayDir.z;

	// Get screenspace rayDir
	vec3 screenRayDir = getScreenPos(gbufferProjection, viewPos - rayDir * viewPos.z) - screenPos;
	screenRayDir *= minOf((sign(screenRayDir.xy) - screenPos.xy) / screenRayDir.xy) * rayTracerStepsInv;
	// screenRayDir = fastNormalize(screenRayDir) * rayTracerStepsInv;
	screenRayDir.xy *= vec2(viewWidth, viewHeight);

	// Apply dithering
	vec3 screenRayPos = vec3(gl_FragCoord.xy, screenPos.z) + screenRayDir * dither;

	for(uint i = 0u; i < rayTraceSteps; i++){
		// If current pos is out of bounds, exit immediately
		if(screenRayPos.x < 0 || screenRayPos.y < 0 || screenRayPos.x > viewWidth || screenRayPos.y > viewHeight) return vec3(0);

		// Get current texture depth
		float currDepth = texelFetch(depthtex0, ivec2(screenRayPos.xy), 0).x;

		// If hand return immediately
		if(currDepth <= 0.56) return vec3(0);

		// Check intersection
		bool intersection = currDepth <= screenRayPos.z;

		// If intersection
		if(intersection){
			// If sky return immediately
			if(currDepth == 1) return vec3(0);

			// Integrated binary refinement
			#if RAYTRACER_BISTEPS != 0
				for(uint i = 0u; i < rayTraceBiSteps; i++){
					// Continue refinement
					screenRayDir *= 0.5;
					screenRayPos += intersection ? -screenRayDir : screenRayDir;

					// Get current texture depth
					currDepth = texelFetch(depthtex0, ivec2(screenRayPos.xy), 0).x;
					// Check intersection
					intersection = currDepth <= screenRayPos.z;
				}
			#endif

			// Return final results
			return vec3(screenRayPos.xy, 1);
		}

		// We continue ray tracing
		screenRayPos += screenRayDir;
	}

	return vec3(0);
}