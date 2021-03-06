#ifndef GLTF_MOBILE_COMMON_INCLUDED
#define GLTF_MOBILE_COMMON_INCLUDED

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardBRDF.cginc"

#ifdef ALPHA_MASK_ON
half _Cutoff;
#endif

fixed4 _Color;
fixed4 _MainTex_ST;
sampler2D _MainTex;

half _Metallic;
half _Roughness;
sampler2D _MetallicRoughnessMap;

half _OcclusionStrength;
sampler2D _OcclusionMap;

fixed3 _EmissionColor;
sampler2D _EmissionMap;

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    float3 ndotl : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float3 viewDir : TEXCOORD3;
};

v2f gltf_mobile_vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);

    o.normal = normalize(UnityObjectToWorldNormal(v.normal));
    o.ndotl = DotClamped(o.normal, _WorldSpaceLightPos0.xyz);

    float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);

    return o;
}

fixed4 gltf_mobile_frag (v2f i) : SV_Target
{
    #ifdef ALPHA_MASK_ON
    float4 color = tex2D(_MainTex, i.uv) * _Color;
    clip(color.a - _Cutoff);
    float3 albedo = color.rgb;
    #else
    float3 albedo = tex2D(_MainTex, i.uv) * _Color;
    #endif

    float3 metallicRoughness = tex2D(_MetallicRoughnessMap, i.uv);
    float metallic = metallicRoughness.b * _Metallic;
    float3 specularTint;
    float oneMinusReflectivity;
    albedo = DiffuseAndSpecularFromMetallic(
        albedo, metallic, specularTint, oneMinusReflectivity
    );

    fixed4 occlusion = tex2D(_OcclusionMap, i.uv).r * _OcclusionStrength;
    fixed4 emmission = fixed4(tex2D(_EmissionMap, i.uv).rgb * _EmissionColor, 1.0);

    UnityLight light;
    light.color = _LightColor0.rgb;
    light.dir = _WorldSpaceLightPos0.xyz;
    light.ndotl = i.ndotl;

    UnityIndirect indirectLight;
    indirectLight.diffuse = fixed4(0.04, 0.04, 0.04, 1);
    indirectLight.specular = 0;

    float smoothness = metallicRoughness.g * (1 - _Roughness);

    float3 diffuse = BRDF3_Unity_PBS(
        albedo, specularTint,
        oneMinusReflectivity, smoothness,
        i.normal, i.viewDir,
        light, indirectLight
    );

    return float4(diffuse, 1) * occlusion + emmission;
}
#endif // GLTF_MOBILE_COMMON_INCLUDED