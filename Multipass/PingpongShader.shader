/*
 Pingpong a texture back and forth
*/
Shader "SpaceAssets/PingpongShader"
{
    Properties
    {
        _MainTex ("Old Texture", 2D) = "white" {}
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if (_Time.g<0.5f) //<- silly hack to make startup work
                {
                    return float4(0,1,0,1); // initial conditions
                }
                
                // Read the old value
                float miplod=3.0; // mipmap level of detail: 0 = full res, 1 = half res, etc.
                float4 old = tex2Dlod(_MainTex, float4(i.uv,0,miplod));
                
                float r=length(i.uv);
                float dotRadius=0.5+0.3*cos(_Time.g);
                if (r<dotRadius)
                    return float4(1,0,0,1);
                else
                    return old*0.999; // scale down (toward black)
            }
            ENDCG
        }
    }
}
