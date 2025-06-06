Shader "CookTorranceProcedural"
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
        _MainTex("Texture", 2D) = "white" {}
        _AmbientLightColor("Ambient Light Color", Color) = (0,0,0,0)

        _DiffuseColor("Diffuse Color", Color) = (0,0,0,0)
        _Roughness("Roughness", Range(0, 1)) = 0.5
        _Metallic("Metallic", Range(0, 1)) = 0.5
        [Toggle] _Dielectric("Dieletric?", Float) = 1.0

        _offsetX("OffsetX",Float) = 0.0
        _offsetY("OffsetY",Float) = 0.0
        _octaves("Octaves",Int) = 7
        _lacunarity("Lacunarity", Range(1.0 , 5.0)) = 2
        _gain("Gain", Range(0.0 , 1.0)) = 0.5
        _value("Value", Range(-2.0 , 2.0)) = 0.0
        _amplitude("Amplitude", Range(0.0 , 10.0)) = 1.5
        _frequency("Frequency", Range(0.0 , 16.0)) = 2.0
        _power("Power", Range(0.1 , 5.0)) = 1.0
        _scale("Scale", Float) = 1.0
    }
        SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define PI (3.14159265359f)

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
            half4 computePointLight(float4 diffuseColor, float4 lightPos, float4 lightColor, float4 worldPosition, float3 n, float3 viewDirection) {
                float3 distanceToLight = length(lightPos - worldPosition);
                float attenuationFactor_quadratic = 1 / (1 + 0.14 * distanceToLight + 0.07 * distanceToLight * distanceToLight);
                float attenuationFactor = 1 / (1 + 0.14 * distanceToLight); // linear attenuation

                float3 lightDirection = normalize(lightPos - worldPosition); // from worldPos to lightPos
                float3 halfAngleVector = normalize(lightDirection + viewDirection);

                // Diffuse part
                float diffuseFactor = max(dot(lightDirection, n), 0.0);
                float3 diffuseComponent = attenuationFactor * diffuseColor * diffuseFactor;

                float roughness = _Roughness;

                // Cook-Torrance specular
                float cos_normalToHalfAngle = max(0, dot(n, halfAngleVector));
                float cos_normalToViewDir = max(0, dot(n, viewDirection));
                float cos_lightToHalfAngle = max(0, dot(lightDirection, halfAngleVector));
                float cos_normalToLightdir = max(0, dot(n, lightDirection));
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

                    Rs = (F * D * G) / (PI * cos_normalToLightdir * cos_normalToViewDir);
                }

                float3 finalSpecular = diffuseColor * lightColor * cos_normalToLightdir +
                    lightColor * Rs * 10 * _Metallic;

                return half4(diffuseComponent + finalSpecular, 1.0);
            }

            float3 _DirectionalLightDir;
            float4 _DirectionalLightColor;
            half4 computeDirectionalLight(float4 diffuseColor, float3 lightDir, float4 lightColor, float4 worldPosition, float3 n, float3 viewDirection) {
                float attenuationFactor = 1; // 0.1?
                float3 lightDirection = normalize(-lightDir);

                float3 halfAngleVector = normalize(lightDirection + viewDirection);

                // Diffuse part
                float diffuseFactor = max(dot(lightDirection, n), 0.0);
                float3 diffuseComponent = attenuationFactor * diffuseColor * diffuseFactor;

                float roughness = _Roughness;

                // Cook-Torrance specular
                float cos_normalToHalfAngle = max(0, dot(n, halfAngleVector));
                float cos_normalToViewDir = max(0, dot(n, viewDirection));
                float cos_lightToHalfAngle = max(0, dot(lightDirection, halfAngleVector));
                float cos_normalToLightdir = max(0, dot(n, lightDirection));
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

                    Rs = (F * D * G) / (PI * cos_normalToLightdir * cos_normalToViewDir);
                }

                float3 finalSpecular = diffuseColor * lightColor * cos_normalToLightdir +
                    lightColor * Rs * 10 * _Metallic;

                return half4(diffuseComponent + finalSpecular, 1.0);
            }

            float4 _SpotLightPos;
            float3 _SpotLightDirection;
            float4 _SpotLightColor;
            float _SpotLightInner;
            float _SpotLightOuter;
            #define DEG2RAD (0.0174533)
            half4 computeSpotLight(float4 diffuseColor, float4 spotLightPos, float3 spotLightDir, float4 spotLightColor, float innerAngle, float outerAngle,
                float4 worldPosition, float3 n, float3 viewDirection) {
                float3 distanceToLight = length(spotLightPos - worldPosition);
                float attenuationFactor_quadratic = 1 / (1 + 0.14 * distanceToLight + 0.07 * distanceToLight * distanceToLight);
                float attenuationFactor = 1 / (1 + 0.14 * distanceToLight); // linear attenuation

                float3 vectorTowardsLight = normalize(spotLightPos - worldPosition);
                float3 lightDirection = vectorTowardsLight;
                float3 halfAngleVector = normalize(vectorTowardsLight + viewDirection);

                // Diffuse part
                float diffuseFactor = max(dot(lightDirection, n), 0.0);
                float3 diffuseComponent = attenuationFactor * diffuseColor * diffuseFactor;

                float roughness = _Roughness;

                // Cook-Torrance specular
                float cos_normalToHalfAngle = max(0, dot(n, halfAngleVector));
                float cos_normalToViewDir = max(0, dot(n, viewDirection));
                float cos_lightToHalfAngle = max(0, dot(lightDirection, halfAngleVector));
                float cos_normalToLightdir = max(0, dot(n, lightDirection));
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

                    Rs = (F * D * G) / (PI * cos_normalToLightdir * cos_normalToViewDir);
                }

                float3 finalSpecular = diffuseColor * spotLightColor * cos_normalToLightdir +
                    spotLightColor * Rs * 10 * _Metallic;

                // Compute spot light-specific parameters for soft edges
                innerAngle = cos(innerAngle * DEG2RAD);
                outerAngle = cos(outerAngle * DEG2RAD);
                float theta = dot(vectorTowardsLight, normalize(-spotLightDir));
                float epsilon = innerAngle - outerAngle;
                float intensity = clamp((theta - outerAngle) / epsilon, 0.0, 1.0);

                diffuseComponent *= intensity;
                finalSpecular *= intensity;

                return half4(diffuseComponent + finalSpecular, 1.0);
            }

            float _octaves, _lacunarity, _gain, _value, _amplitude, _frequency, _offsetX, _offsetY, _power, _scale;
            float fbm(float2 p)
            {
                p = p * _scale + float2(_offsetX, _offsetY);
                for (int i = 0; i < _octaves; i++)
                {
                    float2 i = floor(p * _frequency);
                    float2 f = frac(p * _frequency);
                    float2 t = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
                    float2 a = i + float2(0.0, 0.0);
                    float2 b = i + float2(1.0, 0.0);
                    float2 c = i + float2(0.0, 1.0);
                    float2 d = i + float2(1.0, 1.0);
                    a = -1.0 + 2.0 * frac(sin(float2(dot(a, float2(127.1, 311.7)), dot(a, float2(269.5, 183.3)))) * 43758.5453123);
                    b = -1.0 + 2.0 * frac(sin(float2(dot(b, float2(127.1, 311.7)), dot(b, float2(269.5, 183.3)))) * 43758.5453123);
                    c = -1.0 + 2.0 * frac(sin(float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)))) * 43758.5453123);
                    d = -1.0 + 2.0 * frac(sin(float2(dot(d, float2(127.1, 311.7)), dot(d, float2(269.5, 183.3)))) * 43758.5453123);
                    float A = dot(a, f - float2(0.0, 0.0));
                    float B = dot(b, f - float2(1.0, 0.0));
                    float C = dot(c, f - float2(0.0, 1.0));
                    float D = dot(d, f - float2(1.0, 1.0));
                    float noise = (lerp(lerp(A, B, t.x), lerp(C, D, t.x), t.y));
                    _value += _amplitude * noise;
                    _frequency *= _lacunarity;
                    _amplitude *= _gain;
                }
                _value = clamp(_value, -1.0, 1.0);
                return pow(_value * 0.5 + 0.5, _power);
            }

            float turbulence(float2 xy, float size)
            {
                float value = 0.0, initialSize = size;

                while (size >= 1)
                {
                    value += fbm(xy / size) * size;
                    size /= 2.0;
                }

                return (128.0 * value / initialSize) / 255.0;
            }

            fixed4 frag(v2f i) : SV_Target{
                    float3 normal = normalize(i.worldNormal);
                    float3 viewDirection = normalize(_CameraPos - i.worldPosition);

                    float xPeriod = 35.0; //defines repetition of marble lines in x direction
                    float yPeriod = 30.0; //defines repetition of marble lines in y direction
                    float turbPower = 1.0; //makes twists
                    float turbSize = 8.0; //initial size of the turbulence

                    // float xyValue = i.uv.x * xPeriod + i.uv.y * yPeriod + turbPower * fbm(i.uv.xy)/10;
                    float xyValue = i.uv.x * xPeriod + i.uv.y * yPeriod + turbPower * turbulence(i.uv.xy, turbSize);
                    float sineValue = abs(sin(xyValue * 3.14159));
                    float4 DiffuseColor = float4(sineValue, sineValue, sineValue, 1.0);

                    float3 ambient = _AmbientLightColor * 0.05;

                    half4 pointLightContribution = computePointLight(DiffuseColor, _PointLightPos, _PointLightColor, i.worldPosition, normal, viewDirection);
                    half4 directionalLightContribution = computeDirectionalLight(DiffuseColor, _DirectionalLightDir, _DirectionalLightColor, i.worldPosition, normal, viewDirection);
                    half4 spotLightContribution = computeSpotLight(DiffuseColor, _SpotLightPos, _SpotLightDirection, _SpotLightColor, _SpotLightInner, _SpotLightOuter,
                        i.worldPosition, normal, viewDirection);

                    return half4(ambient + pointLightContribution + spotLightContribution + directionalLightContribution, 1);
            }
            ENDCG
        }
    }
}