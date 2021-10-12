// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

/*
 Draw a tiny section of the Aurora Borealis into a cube.
*/
Shader "Examples/AuroraDemo"
{
    Properties
    {
        _Footprint ("Aurora Curtain Footprint", 2D) = "white" {}
        _Vertical ("Vertical Deposition", 2D) = "white" {}
        _AuroraScale ("Scale to Aurora coords", vector) = (1,1,1,1)
        _AuroraStart ("Origin of Aurora coords", vector) = (0.5,0.5,0.5,1)
        
    }
    SubShader
    {
        //Cull Front //<- draw back faces only
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members world)
#pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 world : TEXCOORD1; 
            };

            float4 _AuroraScale;
            float4 _AuroraStart;
            sampler2D _Footprint;
            sampler2D _Vertical;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.world = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 world = i.world.xzy * _AuroraScale - _AuroraStart;
                fixed4 xy_footprint = tex2D(_Footprint, world.xy);
                fixed4 z_deposition = tex2D(_Vertical, world.z);
                
                return //float4(frac(world),1); 
                     xy_footprint+z_deposition;
            }
            ENDCG
        }
    }
}
