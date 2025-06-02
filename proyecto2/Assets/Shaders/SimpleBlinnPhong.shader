Shader "SimpleBlinnPhong"
{
    Properties {
        [NoScaleOffset] _MainTex("Texture", 2D) = "" {}

        _PointLightPos("Point Light Pos", Vector) = (1.0, 1.0, 1.0)
        _PointLightIntensity("Point Light Intensity", Vector) = (1.0, 1.0, 1.0)
        _CameraPos("Camera Position", Vector) = (1,1,0)
        _CameraLookAt("Camera Look At", Vector) = (-0.2315317, -0.01178938, 0.06181386)

        _AmbientLightIntensity("Light Intensity (ambient)", Color) = (0,0,0,0)
        _DiffuseLightColor("Light Intensity (ambient)", Color) = (0,0,0,0)
        _SpecularLightColor("Light Intensity (ambient)", Color) = (0,0,0,0)

        _Ka("Material Ka", Color) = (0,0,0,0)
        _Kd("Material Kd", Color) = (0,0,0,0)
        _Ks("Material Ks", Color) = (0,0,0,0)
        _SpecularExponent("Specular Exponent", Float) = 128.0
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
                float3 viewDirection: VIEW_DIR;
                float4 worldPosition : WORLD_POS;
            };

            sampler2D _MainTex;
            float3 _Ka, _Kd, _Ks;
            float3 _AmbientLightIntensity, _DiffuseLightColor, _SpecularLightColor;
            float _SpecularExponent;

            float3 _PointLightPos;
            float3 _PointLightIntensity;
            float3 _CameraLookAt;
            float3 _CameraPos;

            v2f vert (vertex_in v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 baseColor = tex2D(_MainTex, i.uv);

                // float4 LightPos = either _PointLightPos or unity's world light 0
                // then I can quickly debug

                float3 distanceToLight = length(_PointLightPos - i.worldPosition);
                // made up constants: a = 0.1, b = 0.2, c = 0.3
                float attenuationFactor_quadratic = 1 / (0.1 + 0.2 * distanceToLight + 0.3 * distanceToLight * distanceToLight);
                float attenuationFactor = 1 / (0.1 + 0.2 * distanceToLight); // linear attenuation

                float3 normal = normalize(i.worldNormal);
                float3 viewDirection = normalize(_CameraPos - i.worldPosition);
                float3 lightDirection = normalize(_PointLightPos - i.worldPosition);
                float3 reflectVector = reflect(-lightDirection, normal);
                float3 halfAngleVector = normalize(lightDirection + viewDirection);

                float3 ambient = _AmbientLightIntensity * _Ka.rgb;

                float diffuseComponent = max(dot(lightDirection, normal), 0.0);

                float3 srcColor = (baseColor == float4(0,0,0,0) ? _Kd : baseColor); // _Kd only if no baseColor?
                float3 diffuse = attenuationFactor * _PointLightIntensity * diffuseComponent * srcColor;

                float phong = pow(max( dot(viewDirection, reflectVector), 0.0), _SpecularExponent);
                float blinn_phong = pow(max( dot(viewDirection, halfAngleVector), 0.0), _SpecularExponent);
                float3 specular = attenuationFactor * _PointLightIntensity * _Ks.rgb * phong;

                return half4(ambient + diffuse + specular, 1);
            }

            ENDCG
        }
    }
}
