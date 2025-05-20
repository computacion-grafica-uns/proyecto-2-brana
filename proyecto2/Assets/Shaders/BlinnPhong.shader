Shader "BlinnPhong"
{
    Properties {
        [NoScaleOffset] _MainTex("Texture", 2D) = "" {}
        _PointLightPos("Point Light Pos", Vector) = (1.0, 1.0, 1.0)
        _SpecularExponent("Specular Exponent", Float) = 1.0
        _AmbientLightStrength("Ambient light", Float) = 0.1
        _RedComponent("Red", Float) = 0.0
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
            float _AmbientLightStrength;
            float _SpecularExponent;
            float3 _PointLightPos;

            float _RedComponent;
            v2f vert (vertex_in v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = mul(transpose(unity_WorldToObject), v.normal.xyz);
                // o.normal = mul(UNITY_MATRIX_IT_MV, v.normal.xyz);

                o.viewDirection = _WorldSpaceCameraPos - o.vertex; // vector from object's vertex towards the camera's position
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 baseColor = tex2D(_MainTex, i.uv);
                // float3 baseColor = float3(153.0/255.0, 0, 0
                // float3 baseColor = float3(_RedComponent, 0, 0);

                float3 ambientColor = _AmbientLightStrength * baseColor;

                float3 lightDirection = normalize(_PointLightPos - i.vertex); // vector from vertex towards light (normalized)
                float3 n = -normalize(i.normal); // why does negating it work?
                float diffuseComponent = max(dot(lightDirection, n), 0.0);
                float3 diffuseColor = diffuseComponent * baseColor;

                // +++++++++++++++++++++

                float3 viewDirection = normalize(i.viewDirection);
                float3 halfAngleVector = normalize(lightDirection + viewDirection);
                float specularComponent = pow( 
                    max(
                        dot(viewDirection, halfAngleVector),
                        0.0
                    ),
                    _SpecularExponent
                );
                float3 specularColor = float3(0.3, 0.3, 0.3) * specularComponent;

                specularColor = float3(0,0,0); // disable for now

                return half4(ambientColor + diffuseColor + specularColor, 1.0);

                // return half4(ambientColor + diffuseColor, 1.0);
            }
            ENDCG
        }
    }
}