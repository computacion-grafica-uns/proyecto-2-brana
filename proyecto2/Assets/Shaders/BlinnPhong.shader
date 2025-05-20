Shader "BlinnPhong"
{
    Properties {
        [NoScaleOffset] _MainTex("Texture", 2D) = "" {}
        _PointLightPos("Point Light Pos", Vector) = (1.0, 1.0, 1.0)
    }

    SubShader {
        // TODO: research what OneMinusSrcAlpha does
        Tags {"Queue"="Transparent" "RenderType"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            struct vertex_in {
                float4 vertex: POSITION;
                float3 normal: NORMAL; 
                float2 uv: TEXCOORD0;
            };

            struct v2f {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
                float3 normal: NORMAL;
                float3 viewDirection: float3;
            };

            sampler2D _MainTex;

            v2f vert (vertex_in v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // o.normal = mul(transpose(unity_WorldToObject), v.normal.xyz);
                o.normal = mul(UNITY_MATRIX_IT_MV, v.normal.xyz);

                o.viewDirection = _WorldSpaceCameraPos - o.vertex;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // float3 baseColor = tex2D(_MainTex, i.uv);
                float3 baseColor = float3(.6,0,0);

                float ambientStrength = 0.05;
                float3 ambientColor = ambientStrength * baseColor;

                float3 pointLightPos = float3(0, 2, 2);
                float3 lightDirection = pointLightPos - i.vertex;
                float3 n = normalize(i.normal);
                float diffuseComponent = max(dot(lightDirection, n), 0.0);
                float3 diffuseColor = diffuseComponent * baseColor;

                // +++++++++++++++++++++

                // float3 viewDirection = ...;
                // float3 viewDirection = float3(2, 2, 0);
                float3 viewDirection = i.viewDirection;

                float3 reflectDirection = lightDirection - (2.0 * dot(n, lightDirection) * n);
                float3 halfAngleVector = normalize(lightDirection + viewDirection);
                float specularExponent = 8.0;
                float specularComponent = pow( 
                    max(
                        dot(viewDirection, reflectDirection),
                        0.0
                    ),
                    specularExponent
                );
                float3 specularColor = float3(0.3, 0.3, 0.3) * specularComponent;
                return half4(ambientColor + diffuseColor + specularColor, 1.0);

                // return half4(ambientColor + diffuseColor, 1.0);
            }
            ENDCG
        }
    }
}