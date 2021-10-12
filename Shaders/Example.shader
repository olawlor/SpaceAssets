/*
  Cut surface into slices, using "discard" keyword.
*/
Shader "Examples/Example"
{
    Properties
    {
        _SliceScale ("SliceScale", Vector) = (0,4,0,0)
        _SlicePhase ("Phase", Range(0,1)) = 0.7
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        // Add instancing support for this shader.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
        
        


        struct Input
        {
            float3 worldPos; // world position
        };

        uniform float4 _SliceScale;
        uniform float _SlicePhase;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Color by a fun normal plaid
            o.Albedo = float4(1,0,0,1);
            
            // Metallic and smoothness are constants
            o.Metallic = 0.0f;
            o.Smoothness = 0.5f;
            o.Alpha = 0.5f;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
