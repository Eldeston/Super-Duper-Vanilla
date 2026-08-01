const uint volumetricCloudSteps = uint(VOLUMETRIC_CLOUD_STEPS);

const float volumetricCenterDepth = VOLUMETRIC_CLOUD_DEPTH * 0.5;
const float volumetricCloudHeight = 195.0 + volumetricCenterDepth;

// This took me a while to finally understand how this all works
vec2 volumetricClouds(in vec3 nFeetPlayerPos, in vec3 cameraPos, in float feetPlayerDist, in float dither, in bool isSky){
    // Minimum cloud distance, if terrain, caps distance to the minimum cloud distance
    float cloudFar = isSky ? volumetricCloudFar : min(volumetricCloudFar, feetPlayerDist);
    float invCloudFarSqrd = 1.0 / squared(volumetricCloudFar);

    // Sets the bounding box vertically
    float lowerBoundDist = (-VOLUMETRIC_CLOUD_DEPTH - cameraPos.y) / nFeetPlayerPos.y;
    float higherBoundDist = -cameraPos.y / nFeetPlayerPos.y;

    // Finds the nearest and furthest plane
    float nearestPlane = max(min(lowerBoundDist, higherBoundDist), 0.0);
	float furthestPlane = min(cloudFar, max(lowerBoundDist, higherBoundDist));

    // If the clouds are outside the bounding box, return nothing
    if(furthestPlane < 0) return vec2(0);

    // Get distance inside the cloud
    float distInsideCloud = furthestPlane - nearestPlane;

    // Calculate cloud steps that dynamically increase with distance
    uint dynamicVolumetricCloudSteps = min(uint(distInsideCloud), volumetricCloudSteps);
    float volumetricCloudStepsInverse = 1.0 / dynamicVolumetricCloudSteps;

    // Multiply by volumetricCloudStepsInverse to get the step size and scale with distance
    vec3 endPos = nFeetPlayerPos * (distInsideCloud * volumetricCloudStepsInverse);

    // Camera position as its start position
    vec3 startPos = cameraPos + nFeetPlayerPos * nearestPlane + endPos * dither;

    // To store the cloud data for 2 cloud layers
    vec2 clouds = vec2(0);

    // LESSS GOOOOO RAT RACING!!!11!!11!!11!!
    for(uint i = 0u; i < dynamicVolumetricCloudSteps; i++){
        // Get cloud fog
        float cloudFog = 1.0 - lengthSquared(startPos - cameraPos) * invCloudFarSqrd;

        // Get cloud texture
        vec2 cloudData = texelFetch(colortex0, ivec2(startPos.xz * 0.0625) & 255, 0).xy;

        // Apply cloud gradiante'
        // Check if ray is inside a cloud
        if(cloudData.x > 0.5) clouds.x = max(clouds.x, -startPos.y * cloudFog);
        if(cloudData.y > 0.5) clouds.y = max(clouds.y, -startPos.y * cloudFog);

        // Continue tracing
        startPos += endPos;
    }

    // Otherwise, return nothing
    return clouds;
}