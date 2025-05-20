Shader "BlinnPhong"
{
    Properties {
        [NoScaleOffset] _MainTex("Texture", 2D) = "" {}
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
            };

            sampler2D _MainTex;

            v2f vert (vertex_in v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = mul(transpose(unity_WorldToObject), v.normal.xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 lightDirection = float3(1, 0, 0);
                float3 ambientColor = float3(0.1, 0.1, 0.1);
                
                float3 lightDir = normalize(-lightDirection);
                float3 viewDir = normalize(- i.vertex);
                float3 n = normalize(i.normal);

                float3 radiance = ambientColor;

                fixed4 uv_color = tex2D(_MainTex, i.uv);
                // return half4(ambientColor + uv_color, 1.0);
                return uv_color;
            }
            ENDCG
        }
    }
}