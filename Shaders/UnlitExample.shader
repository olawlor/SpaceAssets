/*
  Simple example unlit shader, suitable for extending for visual effects.
  Dr. Orion Lawlor, lawlor@alaska.edu, 2021-10-06 (Public Domain)
*/
Shader "Examples/UnlitExample"
{
    Properties
    {
        _Lightness ("Lightness", Range(-1,2)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // Unity will give your vertex shader this data from each mesh vertex
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            // Your vertex shader returns this info to your fragment shader
            struct v2f
            {
                float4 vertex : SV_POSITION; // onscreen coordinates
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };
            
            // This is your vertex shader, which runs at each mesh vertex
            v2f vert (appdata v)
            {
                v2f f;
                f.uv = v.uv; // copy over texture coords
                f.vertex = UnityObjectToClipPos(v.vertex);
                
                //f.normal = normalize(mul(float4(v.normal,0),unity_WorldToObject).xyz); //<- normal in world space
                f.normal = v.normal; //<- normal in object space
                
                return f;
            }
            
            // These are material properties you can change
            uniform float _Lightness;
            
            // This is your fragment shader, which runs at each pixel.
            float4 frag (v2f f) : SV_Target
            {
                float4 color = float4(0,1,0,1); //<- green (RGBA color channels)
                
                return color;
            }
            ENDCG
        }
    }
}

