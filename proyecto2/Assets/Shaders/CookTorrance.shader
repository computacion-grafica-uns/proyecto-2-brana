Shader "CookTorrance"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            
            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
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

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);

                o.viewDirection = WorldSpaceViewDir(v.vertex); // from vertex pos to camera pos
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                float4 _AmbientLightColor = float4(1.0, 1.0, 1.0, 1.0);
                float4 _PointLightColor = float4(1.0, 1.0, 1.0, 1.0);
                float _Kd = 1.0;
                float PI = 3.14159265359;

                fixed4 baseColor = tex2D(_MainTex, i.uv * (4.0 * (1.38966 / 0.8)));

                float3 n = normalize(i.worldNormal);
                float3 viewDirection = normalize(_WorldSpaceCameraPos - i.worldPosition);
                float3 lightDirection = normalize(_WorldSpaceLightPos0 - i.worldPosition); // from worldPos to lightPos
                // float3 lightDirection = normalize(_PointLightPos - i.worldPosition);
                float3 halfAngleVector = normalize(lightDirection + viewDirection);

                float3 distanceToLight = length(_WorldSpaceLightPos0 - i.worldPosition);

                // made up constants: a = 0.1, b = 0.2, c = 0.3
                float attenuationFactor_quadratic = 1 / (0.1 + 0.2 * distanceToLight + 0.3 * distanceToLight * distanceToLight);
                float attenuationFactor = 1 / (0.1 + 0.2 * distanceToLight); // linear attenuation

                // ambient 
                float3 ambientColor = 0.05 * _AmbientLightColor;

                // Diffuse part
                float diffuseComponent = max( dot(lightDirection, n), 0.0);
                float3 diffuseColor = attenuationFactor * float3(_Kd, _Kd, _Kd) * baseColor * diffuseComponent;

                float roughness = 0.5; // move to property

                // Cook-Torrance specular
                float cos_normalToHalfAngle = max(0, dot(n, halfAngleVector));
		        float cos_normalToViewDir = max(0, dot(n, viewDirection));
		        float cos_lightToHalfAngle = max(0, dot(lightDirection, halfAngleVector));
                float cos_normalToLightdir =  max(0, dot(n, lightDirection));
                float Rs = 0.0;

                if (cos_normalToLightdir > 0) {
                    // Fresnel/Schlick (F)
                    float pi_reciprocal = 1 / PI;
                    float n1 = 1.0, n2 = 1.333;
                    float Schlick_R0 = ((n1 - n2) / (n1 + n2)) * ((n1 - n2) / (n1 + n2));
                    float Schlick_cos = max(dot(lightDirection, halfAngleVector), 0.0);
                    float F = Schlick_R0 + (1.0 - Schlick_R0) * pow(1.0 - cos_lightToHalfAngle, 5.0);

                    // Normal distribution via Beckmann (D)
                    float roughness_squared = roughness * roughness;
                    float NdotH_squared = cos_normalToHalfAngle * cos_normalToHalfAngle;
		            float r1 = 1.0 / (4.0 * roughness_squared * pow(cos_normalToHalfAngle, 4.0));
		            float r2 = (NdotH_squared - 1.0) / (roughness_squared * NdotH_squared);
		            float D = r1 * exp(r2);

                    // visible microfacets (G)
		            float g1 = (2.0 * cos_normalToHalfAngle * cos_normalToViewDir) / cos_lightToHalfAngle;
		            float g2 = (2.0 * cos_normalToHalfAngle * cos_normalToLightdir) / cos_lightToHalfAngle;
		            float G = min(1.0, min(g1, g2));

                    Rs = (F*D*G) / (PI * cos_normalToLightdir * cos_normalToViewDir);
                }

                
                float3 finalSpecular = baseColor * _PointLightColor * cos_normalToLightdir +
                                     _PointLightColor * Rs * float4(1.0, 1.0, 1.0, 1.0);

                return half4(diffuseColor + finalSpecular, 1.0);
            }
            ENDCG
        }
    }
}