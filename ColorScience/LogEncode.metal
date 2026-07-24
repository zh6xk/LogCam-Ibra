#include <metal_stdlib>
using namespace metal;

float rec709_to_linear(float c) {
    return (c < 0.081) ? (c / 4.5) : pow((c + 0.099) / 1.099, 1.0 / 0.45);
}

kernel void sLog3Encode(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);
    float3 logColor;

    for (int i = 0; i < 3; i++) {
        // Dekode Rec.709 gamma bawaan kamera ke linear light
        float t = rec709_to_linear(color[i]);
        
        // S-Log3 Encode
        if (t >= 0.01125) {
            logColor[i] = (420.0 + log10((t + 0.01) / 0.19) * 261.5) / 1023.0;
        } else {
            logColor[i] = (t * (171.2102946929 - 95.0) / 0.01125 + 95.0) / 1023.0;
        }
    }

    outTexture.write(float4(logColor, color.a), gid);
}
