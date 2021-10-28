/*
 Iterated Function System style additive blending shader
*/
Shader "SpaceAssets/IFSshader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brighten ("Brighten (add)", range(0,0.1)) = 0
        _Darken ("Darken (scale down)", range(0,0.1)) = 0.01
        _Colorize ("Colorize (multiply color)", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        Cull Off
        ZTest Always //<- don't worry about Z buffer, just draw ourselves
        ZWrite Off
        LOD 100

        Pass
        {
            Blend One One     //<- this makes it additive blending
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
            float _Brighten;
            float _Darken;
            float4 _Colorize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // optional color transform here
                col = _Colorize*(_Brighten + col*(1.0f-_Darken));
                
                return col;
            }
            ENDCG
        }
    }
}
