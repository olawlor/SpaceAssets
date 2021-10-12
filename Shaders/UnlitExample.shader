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
                
                f.normal = normalize(mul(float4(v.normal,0),unity_WorldToObject).xyz); //<- normal in world space
                //f.normal = v.normal; //<- normal in object space
                
                return f;
            }
            
            // These are material properties you can change
            uniform float _Lightness;
            
            // This is your fragment shader, which runs at each pixel.
            float4 frag (v2f f) : SV_Target
            {
                float4 color = float4(0,0,0,1); // RGBA
                
                //color.rg = frac(f.vertex.xy/100.0f);
                //color.b = frac(f.vertex.z*1000.0f);
                
                //if (f.vertex.y > 100.0f)
                //    color = float4(0,0,1,1); // blue
                
                //color.rgb = f.normal;
                
                /*
                // Example heavy calculation (lots of sin calls)
                int counter=0;
                float sum=0.0f;
                for (counter=0;counter<1000;counter++)
                    sum += sin(f.vertex.z*counter*f.normal.x);
                
                color.r = sum*0.001f;
                */
                
                // Red and green from texture coordinates,
                //  blue from surface normal:
                color.rg = frac(f.uv.xy*2.0f);
                color.b = frac(0.5+8.0f *_Lightness* f.normal.y*f.normal.x);
                
                
                return color;
            }
            ENDCG
        }
    }
}


