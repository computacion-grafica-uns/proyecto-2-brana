Shader "BlinnPhong"
{
    Properties {
        [NoScaleOffset] _MainTex("Texture", 2D) = "" {}
        _PointLightPos("Point Light Pos", Vector) = (1.0, 1.0, 1.0)
        _PointLightIntensity("Point Light Intensity", Vector) = (1.0, 1.0, 1.0)
        _CameraPos("Camera Position", Vector) = (1,1,0)
        _CameraLookAt("Camera Look At", Vector) = (-0.2315317, -0.01178938, 0.06181386)

        // TODO: float3
        _Ka("Material Ka", Float) = 0.05
        _Kd("Material Kd", Float) = 0.1
        _Ks("Material Ks", Float) = 0.1
        _SpecularExponent("Specular Exponent", Float) = 1024.0
        _AmbientLightColor("Ambient light color", Color) = (1,1,1,1)
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

                float3 worldNormal: WORLD_NORMAL;
                float3 viewDirection: VIEW_DIR;
                float4 worldPosition : WORLD_POS;
            };

            sampler2D _MainTex;
            float _Ka; float _Kd; float _Ks;
            float _SpecularExponent;
            float3 _PointLightPos;

            float3 _AmbientLightColor;

            v2f vert (vertex_in v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);

                // See docs: https://docs.unity3d.com/Manual/SL-BuiltinFunctions.html
                // float3 WorldSpaceViewDir (float4 v) - Returns world space direction (not normalized) from given object space vertex position towards the camera.
                // "from object space vertex position" means v.vertex, not o.worldPosition
                o.viewDirection = WorldSpaceViewDir(v.vertex); // from vertex pos to camera pos
                return o;
            }

            float3 _PointLightIntensity;
            float3 _CameraPos;

            fixed4 frag (v2f i) : SV_Target {
                // I need an aspect ratio of the polygon size, not of the whole object. then I can scale textures without stretching
                float3 baseColor = tex2D(_MainTex, i.uv * (4.0 * (1.38966 / 0.8)));

                float3 distanceToLight = length(_WorldSpaceLightPos0 - i.worldPosition);

                // made up constants: a = 0.1, b = 0.2, c = 0.3
                float attenuationFactor_quadratic = 1 / (0.1 + 0.2 * distanceToLight + 0.3 * distanceToLight * distanceToLight);
                float attenuationFactor = 1 / (0.1 + 0.2 * distanceToLight); // linear attenuation

                // ambient 
                float3 ambientColor = _Ka * _AmbientLightColor * baseColor;

                // Diffuse reflection
                float3 lightDirection = normalize(_WorldSpaceLightPos0 - i.worldPosition); // from worldPos to lightPos
                float3 n = normalize(i.worldNormal);
                float diffuseComponent = max( dot(lightDirection, n), 0.0);
                float3 diffuseColor = attenuationFactor * _PointLightIntensity * float3(_Kd, _Kd, _Kd) * baseColor * diffuseComponent;

                // Specular reflection
                float3 viewDirection = normalize(_CameraPos - i.worldPosition); // normalize(i.viewDirection);
                float3 halfAngleVector = normalize(lightDirection + viewDirection);
                float3 reflectVector = reflect(lightDirection, n);
                float specularComponent_Blinn = pow( max( dot(viewDirection, halfAngleVector), 0.0 ), _SpecularExponent );
                float specularComponent = pow( max( dot(viewDirection, reflectVector), 0.0 ), _SpecularExponent / 2 );

                float3 specularColor = attenuationFactor * _PointLightIntensity * float3(_Ks, _Ks, _Ks) * specularComponent;

                half4 finalColor = half4(ambientColor + diffuseColor + specularColor, 1.0);
                return finalColor;
            }
            ENDCG
        }
    }
}