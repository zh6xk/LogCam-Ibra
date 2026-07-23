#include <metal_stdlib>
using namespace metal;

kernel void zebraOverlay(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]])
{
    float4 color = inTexture.read(gid);
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    if (luminance > 0.95) {
        bool stripe = ((gid.x + gid.y) % 8) < 4;
        if (stripe) {
            color.rgb = float3(1.0, 1.0, 1.0) - color.rgb;
        }
    }
    outTexture.write(color, gid);
}
