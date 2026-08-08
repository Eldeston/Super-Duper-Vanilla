// General cloud voxel size
const uint voxelSize = 16u;
const float voxelScale = 1.0 / voxelSize;

// My magnum opus, the ABSOLUTE Cinema, I present you...pure voxel traced DDA clouds.
vec2 voxelClouds(in vec3 nFeetPlayerPos, in vec3 camPos, in float sphereFar){
    // Create 2 analytical slabs
    float nFeetPlayerPosInvY = 1.0 / nFeetPlayerPos.y;
    float higherSlabDist = -camPos.y * nFeetPlayerPosInvY;
    float lowerSlabDist  = higherSlabDist - nFeetPlayerPosInvY * CLOUD_THICKNESS;

    // Create a slab as thick as CLOUD_THICKNESS
    float slabNear = min(lowerSlabDist, higherSlabDist);
    float slabFar = max(lowerSlabDist, higherSlabDist);

    // Intersection of the slab and sphere here
    float rayStartDistance = max(slabNear, 0.0);
    float rayEndDistance = min(slabFar, sphereFar);

    // Exit early when out of bounds
    if(rayEndDistance < rayStartDistance) return vec2(0);

    // Get distance inside the cloud
    float distInsideCloud = rayEndDistance - rayStartDistance;
    // This is for fog calculation
    float invCloudFar = 1.0 / cloudDistantFar;

    // Start position and distance in local cloud space
    float startDist = rayStartDistance;
    vec3 startPos = camPos + nFeetPlayerPos * rayStartDistance;

    // Ray in voxel space
    float voxelDist = distInsideCloud * voxelScale;
    vec2 voxelPos = startPos.xz * voxelScale;

    // DDA setup in voxel space
    vec2 stepDir = sign(nFeetPlayerPos.xz);
    vec2 nFeetPlayerPosInvXZ = 1.0 / nFeetPlayerPos.xz;
    vec2 stepSizes = stepDir * nFeetPlayerPosInvXZ;
    vec2 nextDist = (stepDir * 0.5 + 0.5 - fract(voxelPos)) * nFeetPlayerPosInvXZ;

    // Keep track of previous cloud data to complete the shells in the XZ plane
    float closestDist = 0.0;
    vec2 cloudOutput = vec2(0);

    // The loop sometimes run more than 64 iterations but it is capped
    while(closestDist < voxelDist){
        // Calculate the step's axis first, also fixes backface rendering
        uvec2 stepAxis = uvec2(equal(nextDist, vec2(closestDist)));

        // Sample cloud pixels (same texture, same indexing)
        bvec2 currCloudData = lessThan(vec2(0.5), texelFetch(colortex0, ivec2(voxelPos) & 255, 0).xy);

        // If any of the voxels is populated...shading time!
        if(currCloudData.x || currCloudData.y){
            // Convert parametric > world distance
            float currDistance = startDist + closestDist * voxelSize;
            // Local vertical shading
            float currentPosY = camPos.y + nFeetPlayerPos.y * currDistance;
            // Cloud fog
            float cloudFog = 1.0 - currDistance * invCloudFar;
            // Cloud shading
            float cloudShade = -currentPosY * cloudFog;

            // I'm so pro
            // cloudOutput = max(cloudOutput, step(0.5, currCloudData) * cloudShade);
            if(currCloudData.x) cloudOutput.x = max(cloudOutput.x, cloudShade);
            if(currCloudData.y) cloudOutput.y = max(cloudOutput.y, cloudShade);
        }

        // Find the closest voxel distance
        closestDist = minOf(nextDist);
        voxelPos += stepAxis * stepDir;
        nextDist += stepAxis * stepSizes;
    }

    // Complete the bottom plane since voxel tracing skips tracing in-between boundries (I'm so pro 2)
    if(nFeetPlayerPos.y < 0){
        // Plane coordinates
        vec3 planePos = camPos + nFeetPlayerPos * rayEndDistance;
        // Sample cloud voxel
        bvec2 currCloudData = lessThan(vec2(0.5), texelFetch(colortex0, ivec2(planePos.xz * voxelScale) & 255, 0).xy);

        // If any of the voxels is populated...shading time!
        if(currCloudData.x || currCloudData.y){
            // Fog is really easy to calculate at this point
            float cloudFog = 1.0 - rayEndDistance * invCloudFar;
            // Cloud shading
            float cloudShade = -planePos.y * cloudFog;

            // I'm so pro (3)
            // cloudOutput = max(cloudOutput, step(0.5, currCloudData) * cloudShade);
            if(currCloudData.x) cloudOutput.x = max(cloudOutput.x, cloudShade);
            if(currCloudData.y) cloudOutput.y = max(cloudOutput.y, cloudShade);
        }
    }

    return cloudOutput;
}