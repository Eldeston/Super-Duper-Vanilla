/// -------------------------------- /// Lighting /// -------------------------------- ///

const int shadowMapResolution = 1024; // Shadow map resolution. Increase for more resolution at the cost of performance. [512 1024 1536 2048 2560 3072 3584 4096 4608 5120 5632 6144 6656 7168 7680 8192]
const float shadowDistance = 128.0; // Shadow distance. Increase to stretch the shadow map to farther distances in blocks. It's recommended to match this setting with your render distance and increase your shadow map resolution. [32.0 64.0 96.0 128.0 160.0 192.0 224.0 256.0 288.0 320.0 352.0 384.0 416.0 448.0 480.0 512.0 544.0 576.0 608.0 640.0 672.0 704.0 736.0 768.0 800.0 832.0 864.0 896.0 928.0 960.0 992.0 1024.0]
const float sunPathRotation = 30.0; // Light path angle. This also affects sky angle. [-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

/// -------------------------------- /// Pipeline settings /// -------------------------------- ///

// Free slightly better filtering
const bool shadowHardwareFiltering = true;
// Hardcoded to be always 1.0 for maximum optimization.
const float shadowDistanceRenderMul = 1.0;
// Renders the entity shadows at half shadowDistance. Iris only.
const float entityShadowDistanceMul = 0.5;

/// -------------------------------- /// Precalculated constants /// -------------------------------- ///

// Shadow map pixel size. Calculated as the reciprocal of the shadow map resolution.
const float shadowMapPixelSize = 1.0 / shadowMapResolution;
// Reciprocal of shadow distance.
const float shadowDistanceInv = 1.0 / shadowDistance;