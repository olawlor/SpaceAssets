/*
 Debug tool: show one channel from a texture
   0=R, 1=G, 2=B, 3=A
*/
Shader "SpaceAssets/ShowTexChannel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ColorChannel ("Color Channel RGBA 0123",int) = 0
        _ColorScale ("Color Scale",range(0,10)) = 1
        _ColorBias ("Color Bias",range(-1,1)) = 0
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
            float4 _MainTex_ST;
            
            float _ColorChannel;
            float _ColorScale, _ColorBias;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 C = tex2D(_MainTex, i.uv);
                float v = 0;
                if (_ColorChannel==0) v=C.r;
                if (_ColorChannel==1) v=C.g;
                if (_ColorChannel==2) v=C.b;
                if (_ColorChannel==3) v=C.a;
                
                v=_ColorBias + v*_ColorScale;
                
                return float4(v,v,v,1);
            }
            ENDCG
        }
    }
}
