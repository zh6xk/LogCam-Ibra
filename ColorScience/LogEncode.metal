#include <metal_stdlib>
using namespace metal;

// Konversi Rec.709 Linear ke S-Gamut3.Cine Linear
// S-Gamut3.Cine jauh lebih luas, jadi warna Rec.709 akan otomatis terdesaturasi (flat)
float3 rec709_to_sgamut3cine(float3 rgb) {
    float r = rgb.r * 0.7629 + rgb.g * 0.1706 + rgb.b * 0.0665;
    float g = rgb.r * 0.0818 + rgb.g * 0.8872 + rgb.b * 0.0310;
    float b = rgb.r * 0.0354 + rgb.g * -0.0772 + rgb.b * 1.0418;
    return float3(r, g, b);
}

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
    
    // 1. Decode to linear
    float3 linearColor;
    linearColor.r = rec709_to_linear(color.r);
    linearColor.g = rec709_to_linear(color.g);
    linearColor.b = rec709_to_linear(color.b);
    
    // 2. Exposure Compensation
    // Auto-exposure iPhone terlalu terang untuk standar Log. 
    // Turunkan ~0.75 stop (x 0.6) agar middle-gray jatuh persis di 41% IRE S-Log3.
    linearColor *= 0.6;

    // 3. Konversi Gamut (Bikin warna jadi pudar/abu-abu khas cine)
    linearColor = rec709_to_sgamut3cine(linearColor);

    // 4. Encode ke S-Log3
    float3 logColor;
    for (int i = 0; i < 3; i++) {
        float t = linearColor[i];
        if (t >= 0.01125) {
            logColor[i] = (420.0 + log10((t + 0.01) / 0.19) * 261.5) / 1023.0;
        } else {
            logColor[i] = (t * (171.2102946929 - 95.0) / 0.01125 + 95.0) / 1023.0;
        }
    }

    outTexture.write(float4(logColor, color.a), gid);
}
