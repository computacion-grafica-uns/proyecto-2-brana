Shader "OrenNayarTextured"
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
        _SecondaryTex("Overlay", 2D) = "white" {}
        _BlendFactor("Texture Blend Factor", Float) = 0.5
        _Roughness("Roughness", float) = 0.5
        _Specular("Specular", float) = 0.0
        _DiffuseColor("Diffuse Color", Color) = (0.4, 0.4, 0.4, 1.0)
        _SpecularColor("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
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

                struct appdata
                {
                    float4 vertex: POSITION;
                    float2 uv: TEXCOORD0;
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

                float _Roughness;
                float _Specular;
                float4 _DiffuseColor;
                float4 _SpecularColor;
                float3 _CameraPos;

                float4 _PointLightPos;
                float4 _PointLightColor;
                half4 computePointLight(float4 diffuseColor, float roughness, float specular,
                                        float4 lightPos, float4 lightColor, float4 worldPosition, float3 n, float3 viewDirection) {
                    float3 distanceToLight = length(lightPos - worldPosition);
                    float attenuationFactor_quadratic = 1 / (1 + 0.14 * distanceToLight + 0.07 * distanceToLight * distanceToLight);
                    float attenuationFactor = 1 / (1 + 0.14 * distanceToLight); // linear attenuation

                    float3 lightDirection = normalize(lightPos - worldPosition);

                    float roughnessSqr = roughness * roughness;
                    float3 roughnessFraction = roughnessSqr / (roughnessSqr + float3(0.33, 0.13, 0.09));
                    float3 oren_nayar = float3(1, 0, 0) + float3(-0.5, 0.17, 0.45) * roughnessFraction;
                    float cos_ndotl = max(dot(n, lightDirection), 0.0);
                    float cos_ndotv = max(dot(n, viewDirection), 0.0);
                    float oren_nayar_s = max(dot(lightDirection, viewDirection), 0.0) - cos_ndotl * cos_ndotv;
                    oren_nayar_s /= lerp(max(cos_ndotl, cos_ndotv), 1, step(oren_nayar_s, 0));

                    // extra specular term:
                    float3 halfAngleVector = normalize(lightDirection + viewDirection);
                    float3 reflectVector = reflect(-lightDirection, n);

                    float specularComponent = pow(max(dot(viewDirection, reflectVector), 0.0), 64.0 * _Specular);
                    if (_Specular == 0) { specularComponent = 0; }

                    float attenuation = 1.0;
                    float3 lightingModel = specularComponent +
                        diffuseColor * cos_ndotl *
                        (oren_nayar.x + oren_nayar.y * diffuseColor + oren_nayar.z * oren_nayar_s);
                    float3 attenColor = attenuation * lightColor;
                    float4 finalDiffuse = float4(lightingModel * attenColor, 1);

                    return finalDiffuse;
                }

                float3 _DirectionalLightDir;
                float4 _DirectionalLightColor;
                half4 computeDirectionalLight(float4 diffuseColor, float roughness, float specular,
                                              float3 lightDir, float4 lightColor, float4 worldPosition, float3 n, float3 viewDirection) {
                    float3 lightDirection = normalize(-lightDir); // visualize the vector as a free vector at the origin. it's the same vector at every point. make it point backwards at the source, and then normalize

                    float roughnessSqr = roughness * roughness;
                    float3 roughnessFraction = roughnessSqr / (roughnessSqr + float3(0.33, 0.13, 0.09));
                    float3 oren_nayar = float3(1, 0, 0) + float3(-0.5, 0.17, 0.45) * roughnessFraction;
                    float cos_ndotl = max(dot(n, lightDirection), 0.0);
                    float cos_ndotv = max(dot(n, viewDirection), 0.0);
                    float oren_nayar_s = max(dot(lightDirection, viewDirection), 0.0) - cos_ndotl * cos_ndotv;
                    oren_nayar_s /= lerp(max(cos_ndotl, cos_ndotv), 1, step(oren_nayar_s, 0));

                    // extra specular term:
                    float3 halfAngleVector = normalize(lightDirection + viewDirection);
                    float3 reflectVector = reflect(-lightDirection, n);

                    float specularComponent = pow(max(dot(viewDirection, reflectVector), 0.0), 64.0 * _Specular);
                    if (_Specular == 0) { specularComponent = 0; }

                    float3 lightingModel = specularComponent +
                        diffuseColor * cos_ndotl *
                        (oren_nayar.x + oren_nayar.y * diffuseColor + oren_nayar.z * oren_nayar_s);
                    float4 finalDiffuse = float4(lightingModel * lightColor, 1);

                    return finalDiffuse;
                }

                float4 _SpotLightPos;
                float3 _SpotLightDirection;
                float4 _SpotLightColor;
                float _SpotLightInner;
                float _SpotLightOuter;
                #define DEG2RAD (0.0174533)
                half4 computeSpotLight(float4 diffuseColor, float roughness, float specular, float4 spotLightPos, float3 spotLightDir, float4 spotLightColor, float innerAngle, float outerAngle,
                    float4 worldPosition, float3 n, float3 viewDirection) {
                    float3 distanceToLight = length(spotLightPos - worldPosition);
                    float attenuationFactor_quadratic = 1 / (1 + 0.14 * distanceToLight + 0.07 * distanceToLight * distanceToLight);
                    float attenuationFactor = 1 / (1 + 0.14 * distanceToLight); // linear attenuation

                    float3 vectorTowardsLight = normalize(spotLightPos - worldPosition);

                    float roughnessSqr = roughness * roughness;
                    float3 roughnessFraction = roughnessSqr / (roughnessSqr + float3(0.33, 0.13, 0.09));
                    float3 oren_nayar = float3(1, 0, 0) + float3(-0.5, 0.17, 0.45) * roughnessFraction;
                    float cos_ndotl = max(dot(n, vectorTowardsLight), 0.0);
                    float cos_ndotv = max(dot(n, viewDirection), 0.0);
                    float oren_nayar_s = max(dot(vectorTowardsLight, viewDirection), 0.0) - cos_ndotl * cos_ndotv;
                    oren_nayar_s /= lerp(max(cos_ndotl, cos_ndotv), 1, step(oren_nayar_s, 0));

                    // extra specular term:
                    float3 halfAngleVector = normalize(vectorTowardsLight + viewDirection);
                    float3 reflectVector = reflect(-vectorTowardsLight, n);

                    float specularComponent = pow(max(dot(viewDirection, reflectVector), 0.0), 64.0 * _Specular);
                    if (_Specular == 0) { specularComponent = 0; }

                    float3 lightingModel = specularComponent +
                        diffuseColor * cos_ndotl *
                        (oren_nayar.x + oren_nayar.y * diffuseColor + oren_nayar.z * oren_nayar_s);
                    float3 attenColor = attenuationFactor * spotLightColor;
                    float4 finalDiffuse = float4(lightingModel * attenColor, 1);

                    innerAngle = cos(innerAngle * DEG2RAD);
                    outerAngle = cos(outerAngle * DEG2RAD);
                    float theta = dot(vectorTowardsLight, normalize(-spotLightDir));
                    float epsilon = innerAngle - outerAngle;
                    float intensity = clamp((theta - outerAngle) / epsilon, 0.0, 1.0);

                    finalDiffuse *= intensity;

                    return finalDiffuse;
                }

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _SecondaryTex;
                float4 _SecondaryTex_ST;
                float _BlendFactor;

                fixed4 frag(v2f i) : SV_Target
                {
                    _Roughness = clamp(_Roughness, 0.01, 0.97);
                    _Specular = clamp(_Specular, 0.0, 4096.0);

                    float2 scaledUV = TRANSFORM_TEX(i.uv, _MainTex);
                    float4 mainColor = tex2D(_MainTex, scaledUV);
                    float2 scaledUV_overlay = TRANSFORM_TEX(i.uv, _SecondaryTex);
                    float4 overlayColor = tex2D(_SecondaryTex, scaledUV);

                    float4 diffuseColor = lerp(mainColor, overlayColor, _BlendFactor);

                    float3 viewDirection = normalize(_CameraPos - i.worldPosition);
                    float3 n = normalize(i.worldNormal);

                    half3 pointLightContribution = computePointLight(diffuseColor, _Roughness, _Specular, _PointLightPos, _PointLightColor, i.worldPosition, n, viewDirection);
                    half3 directionalLightContribution = computeDirectionalLight(diffuseColor, _Roughness, _Specular, _DirectionalLightDir, _DirectionalLightColor, i.worldPosition, n, viewDirection);
                    half3 spotLightContribution = computeSpotLight(diffuseColor, _Roughness, _Specular, _SpotLightPos, _SpotLightDirection, _SpotLightColor, _SpotLightInner, _SpotLightOuter, i.worldPosition, n, viewDirection);

                    return half4(pointLightContribution + spotLightContribution + directionalLightContribution, 1.0);
                }
                ENDCG
            }
        }
}
