const uint volumetricCloudSteps = uint(VOLUMETRIC_CLOUD_STEPS);
const float volumetricCloudStepsInv = 1.0 / volumetricCloudSteps;

const float volumetricDepthInverse = 1.0 / VOLUMETRIC_CLOUD_DEPTH;
const float volumetricCenterDepth = VOLUMETRIC_CLOUD_DEPTH * 0.5;
const float volumetricCloudHeight = 195.0 + volumetricCenterDepth;

// This took me a while to finally understand how this all works
vec2 volumetricClouds(in vec3 nFeetPlayerPos, in vec3 cameraPos, in float feetPlayerDist, in float dither){
    // Sets the bounding box vertically by creating an analytical slab intersected by a sphere at the camera's position
    float lowerSlabDist = (-VOLUMETRIC_CLOUD_DEPTH - cameraPos.y) / nFeetPlayerPos.y;
    float higherSlabDist = -cameraPos.y / nFeetPlayerPos.y;

    // Finds the slab entry and exit distances
    float slabNear = min(lowerSlabDist, higherSlabDist);
    float slabFar = max(lowerSlabDist, higherSlabDist);

    // Minimum cloud distance, if terrain, caps distance to the minimum cloud distance
    float sphereNear = 0.0;
    float sphereFar = min(volumetricCloudFar, feetPlayerDist);

    // Intersection of the slab and sphere here
    float marchStartDistance = max(slabNear, sphereNear);
    float marchEndDistance = min(slabFar, sphereFar);

    // Exit early when out of bounds
    if(marchEndDistance < marchStartDistance) return vec2(0);
    
    // inverse of the cloud far distance, used for fog calculation
    float invCloudFar = 1.0 / volumetricCloudFar;

    // Get distance inside the cloud
    float distInsideCloud = marchEndDistance - marchStartDistance;

    // Calculate cloud steps that dynamically increase with distance
    uint dynamicVolumetricCloudSteps = min(uint(distInsideCloud), volumetricCloudSteps);
    float volumetricCloudStepsInverse = 1.0 / dynamicVolumetricCloudSteps;

    // Multiply by volumetricCloudStepsInverse to get the step size and scale with distance
    float endDist = distInsideCloud * volumetricCloudStepsInverse;
    vec3 endPos = nFeetPlayerPos * endDist;

    // Camera position as its start position
    float startDist = marchStartDistance + endDist * dither;
    vec3 startPos = cameraPos + nFeetPlayerPos * marchStartDistance + endPos * dither;

    /*
    // Use the cloud slab length to derive one per-step delta.
    // This keeps the step size proportional to the ray length,
    // while the loop still only depends on the fixed cloud step budget.
    float stepSize = distInsideCloud * volumetricCloudStepsInv;
    vec3 endPos = nFeetPlayerPos * stepSize;
    */

    // To store the cloud data for 2 cloud layers
    vec2 clouds = vec2(0);

    // LESSS GOOOOO RAT RACING!!!11!!11!!11!!
    for(uint i = 0u; i < dynamicVolumetricCloudSteps; i++){
        // Get cloud fog
        float cloudFog = 1.0 - startDist * invCloudFar;

        // Get cloud texture
        vec2 cloudData = texelFetch(colortex0, ivec2(startPos.xz * 0.0625) & 255, 0).xy;

        // Apply cloud gradiante'
        // Check if ray is inside a cloud
        if(cloudData.x > 0.5) clouds.x = max(clouds.x, -startPos.y * cloudFog);
        if(cloudData.y > 0.5) clouds.y = max(clouds.y, -startPos.y * cloudFog);

        // Continue tracing
        startDist += endDist;
        startPos += endPos;
    }

    // Otherwise, return nothing
    return clouds;
}