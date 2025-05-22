Shader "BlinnPhong"
{
    Properties {
        [NoScaleOffset] _MainTex("Texture", 2D) = "" {}
        _PointLightPos("Point Light Pos", Vector) = (1.0, 1.0, 1.0)
        _SpecularExponent("Specular Exponent", Float) = 1.0
        _AmbientLightStrength("Ambient light", Float) = 0.1
        _RedComponent("Red", Float) = 0.0
        _CameraPos("Camera Position", Vector) = (1,1,0)
        _CameraLookAt("Camera Look At", Vector) = (-0.2315317, -0.01178938, 0.06181386)
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
            float _AmbientLightStrength;
            float _SpecularExponent;
            float3 _PointLightPos;

            float _RedComponent;
            v2f vert (vertex_in v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // o.worldNormal = mul(transpose(unity_WorldToObject), v.normal.xyz);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);

                // See docs: https://docs.unity3d.com/Manual/SL-BuiltinFunctions.html
                // float3 WorldSpaceViewDir (float4 v) - Returns world space direction (not normalized) from given object space vertex position towards the camera.
                // "from object space vertex position" means v.vertex, not o.worldPosition
                o.viewDirection = WorldSpaceViewDir(v.vertex); // from vertex pos to camera pos
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // I need an aspect ratio of the polygon size, not of the whole object. then I can scale textures without stretching
                float3 baseColor = tex2D(_MainTex, i.uv * (4.0 * (1.38966 / 0.8)));
                // baseColor = float3(153.0/255.0, 0, 0);
                // baseColor = float3(_RedComponent, 0, 0);

                float3 ambientColor = _AmbientLightStrength * baseColor;

                // Diffuse reflection
                float3 lightDirection = normalize(_WorldSpaceLightPos0 - i.worldPosition); // from worldPos to lightPos
                float3 n = normalize(i.worldNormal);
                float diffuseComponent = max( dot(lightDirection, n), 0.0);
                float3 diffuseColor = diffuseComponent * baseColor;
                // diffuseColor = float3(0,0,0);

                // Specular reflection
                float3 viewDirection = normalize(i.viewDirection);
                float3 halfAngleVector = normalize(lightDirection + viewDirection);

                
                float3 reflectVector = -lightDirection - 2.0 * (dot(n, lightDirection) * n);
                // https://registry.khronos.org/OpenGL-Refpages/gl4/html/reflect.xhtml
                // float3 reflectVector = reflect(lightDirection, n);

                float specularComponent_blinn = pow( max( dot(viewDirection, halfAngleVector), 0.0 ), 512. );
                float specularComponent = pow( max( dot(viewDirection, reflectVector), 0.0 ), 8.0 );

                // what is this float3 value? specular strength? per frequency channel?
                float3 specularColor = float3(0.1, 0.1, 0.1) * specularComponent;
                // specularColor = float3(0.05, 0.05, 0.05) * specularComponent;
                // specularColor = float3(0,0,0); // disable for now

                half4 finalColor = half4(ambientColor + diffuseColor + specularColor, 1.0);
                return finalColor;
            }
            ENDCG
        }
    }
}