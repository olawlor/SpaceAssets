/*
 Show a simple fixed color, the simplest kind of simulation.
*/
Shader "SpaceAssets/SimSimple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                // sample our texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                
                float r=length(i.uv);
                float dotRadius=0.5+0.3*sin(_Time.g);
                if (r<dotRadius)
                    return float4(1,0,0,1);
                else
                    // discard;
                    return float4(0,0,1,1);
            }
            ENDCG
        }
    }
}
