const uint rayTraceSteps = uint(RAYTRACER_STEPS);
const uint rayTraceBiSteps = uint(RAYTRACER_BISTEPS);

// Raytracer steps inverse
const float rayTracerStepsInv = 1.0 / RAYTRACER_STEPS;

// This raytracer is stupid fast I swear...
// Based from Belmu's raytracer https://github.com/BelmuTM/NobleRT
// Basically an upgrade to Shadax's raytracer https://github.com/Shadax-stack/MinecraftSSR
vec3 rayTraceScene(in vec3 screenPos, in vec3 viewPos, in vec3 rayDir, in float dither){
	// Fix for the blob when player is near a surface. From Bálint#1673
	if(rayDir.z > -viewPos.z) return vec3(0);

	// Get screenspace rayDir
	vec3 screenRayDir = getScreenPos(gbufferProjection, viewPos + rayDir) - screenPos;
	screenRayDir = fastNormalize(screenRayDir) * rayTracerStepsInv;
	screenRayDir.xy *= vec2(viewWidth, viewHeight);

	// This causes holes/gaps in the reflections for some reason
	// screenRayDir *= minOf((sign(screenRayDir) - screenPos) / screenRayDir) * rayTracerStepsInv;

	// Apply dithering
	vec3 screenRayPos = vec3(gl_FragCoord.xy, screenPos.z) + screenRayDir * dither;

	for(uint i = 0u; i < rayTraceSteps; i++){
		// We raytrace here
		screenRayPos += screenRayDir;

		// If current pos is out of bounds, exit immediately
		if(screenRayPos.x < 0 || screenRayPos.y < 0 || screenRayPos.x > viewWidth || screenRayPos.y > viewHeight) return vec3(0);

		// Get current texture depth
		float currDepth = texelFetch(depthtex0, ivec2(screenRayPos.xy), 0).x;

		// If hand return immediately
		if(currDepth <= 0.56) return vec3(0);

		// Check intersection
		bool intersection = screenRayPos.z > currDepth;

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
					intersection = screenRayPos.z > currDepth;
				}
			#endif

			// Return final results
			return vec3(screenRayPos.xy, 1);
		}
	}

	return vec3(0);
}