Shader "BPThreeLightsProcedural" {
    Properties{
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

        _Ka("Material Ka", Color) = (0,0,0,0)
        _Kd("Material Kd", Color) = (0,0,0,0)
        _Ks("Material Ks", Color) = (0,0,0,0)
        _SpecularExponent("Specular Exponent", Float) = 128.0

        _offsetX("OffsetX",Float) = 0.0
        _offsetY("OffsetY",Float) = 0.0
        _octaves("Octaves",Int) = 7
        _lacunarity("Lacunarity", Range(1.0 , 5.0)) = 2
        _gain("Gain", Range(0.0 , 1.0)) = 0.5
        _value("Value", Range(-2.0 , 2.0)) = 0.0
        _amplitude("Amplitude", Range(0.0 , 5.0)) = 1.5
        _frequency("Frequency", Range(0.0 , 6.0)) = 2.0
        _power("Power", Range(0.1 , 5.0)) = 1.0
        _scale("Scale", Float) = 1.0
        [Toggle] _monochromatic("Monochromatic", Float) = 0
        _range("Monochromatic Range", Range(0.0 , 1.0)) = 0.5
    }

        SubShader{
            Tags {"Queue" = "Transparent" "RenderType" = "Transparent"}
            Blend SrcAlpha OneMinusSrcAlpha

            Pass {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                float PI = 3.14159265;

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

                v2f vert(vertex_in v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    o.normal = v.normal;
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                    return o;
                }

                sampler2D _MainTex;
                float3 _CameraPos;
                float3 _AmbientLightColor;
                float3 _Ka, _Kd, _Ks;
                float _SpecularExponent;

                float4 _PointLightPos;
                float4 _PointLightColor;
                half4 computePointLight(float4 diffuseColor, float4 lightPos, float4 lightColor, float4 worldPosition, float3 normal, float3 viewDirection) {
                    float3 distanceToLight = length(lightPos - worldPosition);
                    float attenuationFactor_quadratic = 1 / (1 + 0.14 * distanceToLight + 0.07 * distanceToLight * distanceToLight);
                    float attenuationFactor = 1 / (1 + 0.14 * distanceToLight); // linear attenuation

                    float3 lightDirection = normalize(lightPos - worldPosition);
                    float3 reflectVector = reflect(-lightDirection, normal);
                    float3 halfAngleVector = normalize(lightDirection + viewDirection);

                    float diffuseComponent = max(dot(lightDirection, normal), 0.0);

                    float3 diffuse = attenuationFactor * lightColor * diffuseComponent * diffuseColor;

                    float phong = pow(max(dot(viewDirection, reflectVector), 0.0), _SpecularExponent);
                    float blinn_phong = pow(max(dot(normal, halfAngleVector), 0.0), _SpecularExponent);
                    float3 specular = attenuationFactor * lightColor * _Ks.rgb * blinn_phong;

                    return half4(diffuse + specular, 1.0);
                }

                float3 _DirectionalLightDir;
                float4 _DirectionalLightColor;
                half4 computeDirectionalLight(float4 diffuseColor, float3 lightDir, float4 lightColor, float4 worldPosition, float3 normal, float3 viewDirection) {
                    float attenuationFactor = 1; // 0.1?
                    float3 lightDirection = normalize(-lightDir); // visualize the vector as a free vector at the origin. it's the same vector at every point. make it point backwards at the source, and then normalize
                    float3 reflectVector = reflect(-lightDirection, normal);
                    float3 halfAngleVector = normalize(lightDirection + viewDirection);

                    float diffuseComponent = max(dot(normal, lightDirection), 0.0);
                    float3 diffuse = attenuationFactor * lightColor * diffuseComponent * diffuseColor;

                    float phong = pow(max(dot(viewDirection, reflectVector), 0.0), _SpecularExponent);
                    float blinn_phong = pow(max(dot(normal, halfAngleVector), 0.0), _SpecularExponent);
                    float3 specular = attenuationFactor * lightColor * _Ks.rgb * blinn_phong;

                    return half4(diffuse + specular, 1.0);
                }

                float4 _SpotLightPos;
                float3 _SpotLightDirection;
                float4 _SpotLightColor;
                float _SpotLightInner;
                float _SpotLightOuter;
                #define DEG2RAD (0.0174533)
                half4 computeSpotLight(float4 diffuseColor, float4 spotLightPos, float3 spotLightDir, float4 spotLightColor, float innerAngle, float outerAngle,
                                       float4 worldPosition, float3 normal, float3 viewDirection) {
                    float3 distanceToLight = length(spotLightPos - worldPosition);
                    float attenuationFactor_quadratic = 1 / (1 + 0.14 * distanceToLight + 0.07 * distanceToLight * distanceToLight);
                    float attenuationFactor = 1 / (1 + 0.14 * distanceToLight); // linear attenuation

                    float3 vectorTowardsLight = normalize(spotLightPos - worldPosition);
                    float3 reflectVector = reflect(-vectorTowardsLight, normal);
                    float3 halfAngleVector = normalize(vectorTowardsLight + viewDirection);
                    float diffuseComponent = max(dot(vectorTowardsLight, normal), 0.0);
                    float3 diffuse = attenuationFactor * spotLightColor * diffuseComponent * diffuseColor;

                    float phong = pow(max(dot(viewDirection, reflectVector), 0.0), _SpecularExponent);
                    float blinn_phong = pow(max(dot(normal, halfAngleVector), 0.0), _SpecularExponent);
                    float3 specular = attenuationFactor * spotLightColor * _Ks.rgb * blinn_phong;

                    innerAngle = cos(innerAngle * DEG2RAD);
                    outerAngle = cos(outerAngle * DEG2RAD);
                    float theta = dot(vectorTowardsLight, normalize(-spotLightDir));
                    float epsilon = innerAngle - outerAngle;
                    float intensity = clamp((theta - outerAngle) / epsilon, 0.0, 1.0);

                    diffuse *= intensity;
                    specular *= intensity;

                    return half4(diffuse + specular, 1.0);
                }

                float _octaves, _lacunarity, _gain, _value, _amplitude, _frequency, _offsetX, _offsetY, _power, _scale, _monochromatic, _range;
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

                fixed4 frag(v2f i) : SV_Target {
                    float3 normal = normalize(i.worldNormal);
                    float3 viewDirection = normalize(_CameraPos - i.worldPosition);

                    float c = fbm(i.uv.xy);
                    float4 diffuseColor = float4(c, c, c, 1.0) * float4(_Kd, 1.0);
                    
                    float3 ambient = _AmbientLightColor * _Ka.rgb;

                    half4 pointLightContribution = computePointLight(diffuseColor, _PointLightPos, _PointLightColor, i.worldPosition, normal, viewDirection);
                    half4 spotLightContribution = computeSpotLight(diffuseColor, _SpotLightPos, _SpotLightDirection, _SpotLightColor, _SpotLightInner, _SpotLightOuter,
                                                                   i.worldPosition, normal, viewDirection);
                    half4 directionalLightContribution = computeDirectionalLight(diffuseColor, _DirectionalLightDir, _DirectionalLightColor, i.worldPosition, normal, viewDirection);

                    return half4(ambient + pointLightContribution + spotLightContribution + directionalLightContribution, 1);
                }

                ENDCG
            }
    }
}
