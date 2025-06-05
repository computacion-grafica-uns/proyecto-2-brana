Shader "BlinnPhongNoTexture" {
    Properties{
        _PointLightPos("Point Light Pos", Vector) = (1.0, 1.0, 1.0)
        _PointLightIntensity("Point Light Intensity", Vector) = (1.0, 1.0, 1.0)
        _CameraPos("Camera Position", Vector) = (1,1,0)

        _AmbientLightColor("Ambient Light Color", Color) = (0,0,0,0)

        _Ka("Material Ka", Color) = (0,0,0,0)
        _Kd("Material Kd", Color) = (0,0,0,0)
        _Ks("Material Ks", Color) = (0,0,0,0)
        _SpecularExponent("Specular Exponent", Float) = 128.0
    }

        SubShader{
            Tags {"Queue" = "Transparent" "RenderType" = "Transparent"}
            Blend SrcAlpha OneMinusSrcAlpha

            Pass {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                struct vertex_in {
                    float4 vertex: POSITION;
                    float3 normal: NORMAL;
                    float2 uv: TEXCOORD0;
                };

                struct v2f {
                    float2 uv: TEXCOORD0;
                    float4 vertex: SV_POSITION;
                    float3 normal: NORMAL;
                    float3 worldNormal: WORLD_NORMAL;
                    float4 worldPosition : WORLD_POS;
                };

                float3 _Ka, _Kd, _Ks;
                float3 _AmbientLightColor;
                float _SpecularExponent;

                float3 _PointLightPos;
                float3 _PointLightIntensity;
                float3 _CameraLookAt;
                float3 _CameraPos;

                v2f vert(vertex_in v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    o.normal = v.normal;
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target {
                    // float4 LightPos = either _PointLightPos or unity's world light 0
                    // then I can quickly debug

                    float3 distanceToLight = length(_PointLightPos - i.worldPosition);
                    float attenuationFactor_quadratic = 1 / (1 + 0.14 * distanceToLight + 0.07 * distanceToLight * distanceToLight);
                    float attenuationFactor = 1 / (1 + 0.14 * distanceToLight); // linear attenuation

                    float3 normal = normalize(i.worldNormal);
                    float3 viewDirection = normalize(_CameraPos - i.worldPosition);
                    float3 lightDirection = normalize(_PointLightPos - i.worldPosition);
                    float3 reflectVector = reflect(-lightDirection, normal);
                    float3 halfAngleVector = normalize(lightDirection + viewDirection);

                    float3 ambient = _AmbientLightColor * _Ka.rgb;

                    float diffuseFactor = max(dot(lightDirection, normal), 0.0);
                    float3 diffuse = attenuationFactor * _PointLightIntensity * diffuseFactor * _Kd;

                    float phong = pow(max(dot(viewDirection, reflectVector), 0.0), _SpecularExponent);
                    float blinn_phong = pow(max(dot(viewDirection, halfAngleVector), 0.0), _SpecularExponent);
                    float3 specular = attenuationFactor * _PointLightIntensity * _Ks.rgb * phong;

                    return half4(ambient + diffuse + specular, 1);
                }

                ENDCG
            }
        }
}
