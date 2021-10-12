/*
  Cut surface into slices, using "discard" keyword.
*/
Shader "Examples/SurfaceSlices"
{
    Properties
    {
        _SliceScale ("SliceScale", Vector) = (0,4,0,0)
        _SlicePhase ("Phase", Range(0,1)) = 0.7
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
        };

        uniform float4 _SliceScale;
        uniform float _SlicePhase;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Color by a fun normal plaid
            o.Albedo = frac(8.0f*o.Normal+0.5f); // c.rgb;
            
            // Cut slices based on world space position:
            float slice=IN.worldPos.x*_SliceScale.x
                + IN.worldPos.y*_SliceScale.y
                + IN.worldPos.z*_SliceScale.z
                + _SlicePhase;
            if (frac(slice)>0.5f)
                discard;
            
            // Metallic and smoothness are constants
            o.Metallic = 0.0f;
            o.Smoothness = 0.5f;
            o.Alpha = 0.5f;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
