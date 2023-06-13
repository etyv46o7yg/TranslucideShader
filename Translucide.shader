// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "JellyOldsurface"
{
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        _BumpMap("Normal (Normal)", 2D) = "bump" {}
        _Color("Main Color", Color) = (1,1,1,1)
        _OccludedColor("Occluded Color", Color) = (1,1,1,1)
        _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
        _Shininess("Shininess", Range(0.03, 1)) = 0.078125

            //_Thickness = Thickness texture (invert normals, bake AO).
            //_Power = "Sharpness" of translucent glow.
            //_Distortion = Subsurface distortion, shifts surface normal, effectively a refractive index.
            //_Scale = Multiplier for translucent glow - should be per-light, really.
            //_SubColor = Subsurface colour.
            _Thickness("Thickness (R)", 2D) = "bump" {}
            _Power("Subsurface Power", Float) = 1.0
            _Distortion("Subsurface Distortion", Float) = 0.0
            _Scale("Subsurface Scale", Float) = 0.5
            _SubColor("Subsurface Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
        SubShader
            {
            Pass
                {
                Tags { "Queue" = "Geometry+1" }
                ZTest Greater
                ZWrite Off

                CGPROGRAM
                #pragma vertex vert          
                #pragma fragment frag
                #pragma fragmentoption ARB_precision_hint_fastest

                half4 _OccludedColor;


                float4 vert(float4 pos : POSITION) : SV_POSITION
                    {
                    float4 viewPos = UnityObjectToClipPos(pos);
                    return viewPos;
                    }

                    half4 frag(float4 pos : SV_POSITION) : COLOR
                    {
                    return _OccludedColor;
                    }
                ENDCG
                }

            Tags { "RenderType" = "Opaque" }
            LOD 200

            CGPROGRAM
            #pragma surface surf Translucent
            #pragma exclude_renderers flash

            sampler2D _MainTex, _BumpMap, _Thickness;
            float _Scale, _Power, _Distortion;
            fixed4 _Color, _SubColor;
            half _Shininess;

            struct Input 
                {
                float2 uv_MainTex;
                };

            void surf(Input IN, inout SurfaceOutput o) 
                {
                fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
                o.Albedo = tex.rgb * _Color.rgb;
                o.Alpha = tex2D(_Thickness, IN.uv_MainTex).r;
                o.Gloss = tex.a;
                o.Specular = _Shininess;
                o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
                }

            inline fixed4 LightingTranslucent(SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten)
            {
                // You can remove these two lines,
                // to save some instructions. They're just
                // here for visual fidelity.
                viewDir = normalize(viewDir);
                lightDir = normalize(lightDir);

                // Translucency.
                half3 transLightDir = lightDir + s.Normal * _Distortion;
                float transDot = pow(max(0, dot(viewDir, -transLightDir)), _Power) * _Scale;
                fixed3 transLight = (atten * 2) * (transDot)*s.Alpha * _SubColor.rgb;
                fixed3 transAlbedo = s.Albedo * _LightColor0.rgb * transLight;

                half3 transLightDir2 = lightDir;
                float transDot2 = pow(max(0, dot(viewDir, transLightDir2)), _Power) * _Scale;
                fixed3 transLight2 = (atten * 2) * (transDot2)*s.Alpha * _SubColor.rgb;
                fixed3 transAlbedo2 = s.Albedo * _LightColor0.rgb * transLight2;

                // Regular BlinnPhong.
                half3 h = normalize(lightDir + viewDir);
                fixed diff = max(0, dot(s.Normal, lightDir));
                float nh = max(0, dot(s.Normal, h));
                float spec = pow(nh, s.Specular * 128.0) * s.Gloss;
                fixed3 diffAlbedo = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);

                // Add the two together.
                fixed4 c;
                c.rgb = diffAlbedo + transAlbedo + transAlbedo2;

                c.a = _LightColor0.a * _SpecColor.a * spec * atten;
                return c;
            }

            ENDCG
            }
                FallBack "Bumped Diffuse"
}