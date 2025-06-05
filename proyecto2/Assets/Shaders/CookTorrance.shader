Shader "CookTorrance"
{
    Properties
    {
        _PointLightPos("Point Light Pos", Vector) = (2.0, 3.0, 1.0, 1.0)
        _PointLightColor("Point Light Color", Color) = (1.0, 1.0, 1.0, 1.0)

        _DirectionalLightDir("Directional Light Direction", Vector) = (1, -1, 1)
        _DirectionalLightColor("Directional Light Color", Color) = (1.0, 1.0, 1.0, 1.0)

        _SpotLightPos("Spotlight Position", Vector) = (-5, 3, -4)
        _SpotLightDirection("Spotlight Direction", Vector) = (0, -1, 0)
        _SpotLightColor("Spotlight Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpotLightInner("Spotlight Inner Angle", Float) = 12.5
        _SpotLightOuter("Spotlight Outer Angle", Float) = 15.0


        _CameraPos("Camera Position", Vector) = (3,3,0)

        _AmbientLightColor("Ambient Light Color", Color) = (0,0,0,0)

        _DiffuseColor("Diffuse Color", Color) = (0,0,0,0)
        _Roughness("Roughness", Range(0, 1)) = 0.5
        _Metallic("Metallic", Range(0, 1)) = 0.5
        [Toggle] _Dielectric("Dieletric?", Float) = 1.0
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

            #include "UnityCG.cginc"
            
            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
                float3 normal: NORMAL;
                float3 worldNormal: WORLD_NORMAL;
                float4 worldPosition : WORLD_POS;
            };

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float3 _CameraPos;
            float3 _AmbientLightColor;
            float _Roughness, _Metallic;
            float4 _DiffuseColor;

            float4 _PointLightPos;
            float4 _PointLightColor;

            fixed4 frag (v2f i) : SV_Target {
                float PI = 3.14159265359;

                fixed4 baseColor = _DiffuseColor;

                float3 n = normalize(i.worldNormal);
                float3 viewDirection = normalize(_CameraPos - i.worldPosition);
                float3 lightDirection = normalize(_PointLightPos - i.worldPosition); // from worldPos to lightPos
                // float3 lightDirection = normalize(_PointLightPos - i.worldPosition);
                float3 halfAngleVector = normalize(lightDirection + viewDirection);

                float3 distanceToLight = length(_PointLightPos - i.worldPosition);
                float attenuationFactor_quadratic = 1 / (1 + 0.14 * distanceToLight + 0.07 * distanceToLight * distanceToLight);
                float attenuationFactor = 1 / (1 + 0.14 * distanceToLight); // linear attenuation

                // attenuationFactor = 1.0; // undo attenuation for now

                // ambient 
                float3 ambientColor = 0.5 * _AmbientLightColor;

                // Diffuse part
                float diffuseComponent = max( dot(lightDirection, n), 0.0);
                float3 diffuseColor = attenuationFactor * baseColor * diffuseComponent;

                float roughness = _Roughness;

                // Cook-Torrance specular
                float cos_normalToHalfAngle = max(0, dot(n, halfAngleVector));
		        float cos_normalToViewDir = max(0, dot(n, viewDirection));
		        float cos_lightToHalfAngle = max(0, dot(lightDirection, halfAngleVector));
                float cos_normalToLightdir =  max(0, dot(n, lightDirection));
                float Rs = 0.0;

                if (cos_normalToLightdir > 0) {
                    // Fresnel/Schlick (F)
                    float pi_reciprocal = 1 / PI;
                    float n1 = 1.0, n2 = 1.333; // test IOR values - air into water
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
                                     _PointLightColor * Rs * 10*_Metallic;

                return half4(ambientColor + diffuseColor + finalSpecular, 1.0);
            }
            ENDCG
        }
    }
}