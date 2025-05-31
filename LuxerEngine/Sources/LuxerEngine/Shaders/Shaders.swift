//
//  Shaders.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

let shaderSource = """
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float2 texCoord;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewProjectionMatrix;
    float4x4 normalMatrix;
};

// This must match MaterialShaderData exactly
struct Material {
    float4 baseColor;     // rgba
    float metallic;
    float roughness;
    float4 emissive;      // rgb + intensity
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
    out.position = uniforms.viewProjectionMatrix * worldPosition;
    out.worldPosition = worldPosition.xyz;
    out.worldNormal = (uniforms.normalMatrix * float4(in.normal, 0.0)).xyz;
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                             constant Material &material [[buffer(0)]],
                             texture2d<float> baseColorTexture [[texture(0)]],
                             texture2d<float> normalTexture [[texture(1)]],
                             texture2d<float> metallicRoughnessTexture [[texture(2)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    // Base color from texture or material
    float4 baseColor = material.baseColor;
    if (is_null_texture(baseColorTexture) == false) {
        baseColor *= baseColorTexture.sample(textureSampler, in.texCoord);
    }
    
    // Simple lighting calculation
    float3 normal = normalize(in.worldNormal);
    float3 lightDir = normalize(float3(1, 1, 1));
    float NdotL = max(dot(normal, lightDir), 0.0);
    
    // Combine diffuse and emissive
    float3 diffuse = baseColor.rgb * NdotL;
    float3 emissive = material.emissive.rgb * material.emissive.w;
    
    return float4(diffuse + emissive, baseColor.a);
}
"""
