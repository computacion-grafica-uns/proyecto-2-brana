Shader "OrenNayarOuwerkerk"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Roughness("Roughness", float) = 0.5
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

                // TODO: semantics?
                float3 worldNormal: WORLDNORMAL;
                float4 worldPosition: WORLDPOS;
                float3 viewDirection: VIEWDIR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

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
            float4 _DiffuseColor;

            fixed4 frag (v2f i) : SV_Target
            {
                _Roughness = saturate(_Roughness);

                fixed4 col = tex2D(_MainTex, i.uv);

                float4 diffuseColor = _DiffuseColor; // float4(0.4, 0.4, 0.4, 1.0);

                float3 viewDirection = normalize(_WorldSpaceCameraPos  - i.worldPosition);
                float3 lightDirection = normalize(_WorldSpaceLightPos0 - i.worldPosition); // from worldPos to lightPos
                float3 viewDir = normalize(i.viewDirection);
                float3 n = normalize(i.worldNormal);
                
                float roughnessSqr = _Roughness * _Roughness;
                float3 o_n_fraction = roughnessSqr / (roughnessSqr + float3(0.33, 0.13, 0.09));
                float3 oren_nayar = float3(1, 0, 0) + float3(-0.5, 0.17, 0.45) * o_n_fraction;
                float cos_ndotl = saturate(dot(n, lightDirection));
                float cos_ndotv = saturate(dot(n, viewDir));
                float oren_nayar_s = saturate(dot(lightDirection, viewDir)) - cos_ndotl * cos_ndotv;
                oren_nayar_s /= lerp(max(cos_ndotl, cos_ndotv), 1, step(oren_nayar_s, 0));

                // extra specular term:
                float3 halfAngleVector = normalize(lightDirection + viewDirection);
                float3 reflectVector = reflect(-lightDirection, n);
                    // rougness and specular:
                _Roughness = clamp(_Roughness, 0.05, 0.85);
                float specularComponent = pow( max( dot(viewDirection, reflectVector), 0.0 ), 64.0 * ( _Roughness) ); // more specular the less rough it is
                if (_Roughness > 0.6) { /* somehow reduce the specularness */ specularComponent /= (_Roughness * 10); }
                // I'm overthinking it - add another parameter and let there be unrealistic combinations e.g. very rough yet sharp specular

                //lighting and final diffuse
                float attenuation = 1.0;
                float3 lightingModel = specularComponent + diffuseColor * cos_ndotl * (oren_nayar.x + diffuseColor * oren_nayar.y + oren_nayar.z * oren_nayar_s);
                float3 attenColor = attenuation * _LightColor0.rgb;
                float4 finalDiffuse = float4(lightingModel * attenColor,1);

                return finalDiffuse;
            }
            ENDCG
        }
    }
}
