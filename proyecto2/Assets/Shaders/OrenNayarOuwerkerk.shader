Shader "OrenNayarOuwerkerk"
{
    Properties
    {
        _Roughness("Roughness", float) = 0.5
        _Specular("Specular", float) = 0.0
        _DiffuseColor("Diffuse Color", Color) = (0.4, 0.4, 0.4, 1.0)
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityLightingCommon.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                float3 worldNormal: WORLDNORMAL;
                float4 worldPosition: WORLDPOS;
                float3 viewDirection: VIEWDIR;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);

                o.viewDirection = WorldSpaceViewDir(v.vertex); // from vertex pos to camera pos
                return o;
            }

            float _Roughness;
            float _Specular;
            float4 _DiffuseColor;

            fixed4 frag (v2f i) : SV_Target
            {
                _Roughness = saturate(_Roughness);

                float4 diffuseColor = _DiffuseColor;

                float3 viewDirection = normalize(_WorldSpaceCameraPos  - i.worldPosition);
                float3 lightDirection = normalize(_WorldSpaceLightPos0 - i.worldPosition); // from worldPos to lightPos
                float3 viewDir = normalize(i.viewDirection);
                float3 n = normalize(i.worldNormal);
                
                float roughnessSqr = _Roughness * _Roughness;
                float3 roughnessFraction = roughnessSqr / (roughnessSqr + float3(0.33, 0.13, 0.09));
                float3 oren_nayar = float3(1, 0, 0) + float3(-0.5, 0.17, 0.45) * roughnessFraction;
                float cos_ndotl = max(dot(n, lightDirection), 0.0);
                float cos_ndotv = max(dot(n, viewDir), 0.0);
                float oren_nayar_s = max(dot(lightDirection, viewDir), 0.0) - cos_ndotl * cos_ndotv;
                oren_nayar_s /= lerp(max(cos_ndotl, cos_ndotv), 1, step(oren_nayar_s, 0));

                // extra specular term:
                float3 halfAngleVector = normalize(lightDirection + viewDirection);
                float3 reflectVector = reflect(-lightDirection, n);

                float specularComponent = pow( max( dot(viewDirection, reflectVector), 0.0 ), 64.0 * _Specular );
                if (_Specular == 0) { specularComponent = 0; }

                float attenuation = 1.0;
                float3 lightingModel = specularComponent +
                                       diffuseColor * cos_ndotl *
                                       (oren_nayar.x + oren_nayar.y * diffuseColor + oren_nayar.z * oren_nayar_s);
                float3 attenColor = attenuation * _LightColor0.rgb;
                float4 finalDiffuse = float4(lightingModel * attenColor,1);

                return finalDiffuse;
            }
            ENDCG
        }
    }
}
