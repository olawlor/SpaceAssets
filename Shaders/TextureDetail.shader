/*
  Draw a texture over a surface. 
  Includes several textures, for "detail texture".
*/
Shader "Examples/TextureDetail"
{
    Properties
    {
        _Color ("Color", Color) = (0.8,0.7,0.7,1)
        
        _MainTex ("Main Albedo", 2D) = "white" {}
        _MainScale ("Main Scale", Range(0,16)) = 1.0
        
        _DetailTex ("Detail Albedo", 2D) = "white" {}
        _DetailScale ("Detail Scale", Range(0,128)) = 13.0
        _DetailWeight ("Detail Weight", Range(0,1)) = 0.4
        
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Cull Off  //<- we want back faces, because we discard some front faces
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0


        struct Input
        {
            float3 worldPos; // world position
            float2 uv_MainTex;
        };

        sampler2D _MainTex;
        float _MainScale;
        
        sampler2D _DetailTex;
        float _DetailScale;
        float _DetailWeight;
        
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            float2 uv = IN.uv_MainTex;
            float4 mainColor = tex2D (_MainTex, uv*_MainScale);
            float4 detailColor = tex2D (_DetailTex, uv*_DetailScale);
            
            float4 c = (mainColor + _DetailWeight*detailColor) * _Color;
            

            // Surface color comes from the texture:
            o.Albedo = c.rgb;
            
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
