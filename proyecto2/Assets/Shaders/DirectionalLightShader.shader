Shader "DirectionalLightShader"
{
    Properties {
        [NoScaleOffset] _MainTex("Texture", 2D) = "" {}
        _DirLightDirection("Directional Light Direction", Vector) = (0, 1, 0, 1)
        _DirLightColor("Directional Light Color", Color) = (1,1,1,1)
    }

    SubShader {
        // TODO: research what OneMinusSrcAlpha does
        Tags {"Queue"="Transparent" "RenderType"="Transparent"}
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

            sampler2D _MainTex;
            float3 _DirLightDirection;
            float3 _DirLightColor; // rgb

            float _RedComponent;
            v2f vert (vertex_in v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.normal = v.normal;
                // o.worldNormal = mul(transpose(unity_WorldToObject), v.normal.xyz); // TODO: which matrices to use?
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 baseColor = tex2D(_MainTex, i.uv);
                float L1 = normalize(_DirLightDirection);
                float NdotL1 = max(0, dot(i.worldNormal, L1));
                
                half4 finalColor = half4(NdotL1 * baseColor, 1.0);
                return finalColor;
            }
            ENDCG
        }
    }
}