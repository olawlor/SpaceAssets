/*
 Draw a volume rendered effect into a cube.
*/
Shader "Examples/VolumeDemo"
{
    Properties
    {
        _VolumeStart ("Origin of volume in world", vector) = (0,0,0,1)
        _VolumeScale ("Scale to volume coords", vector) = (1,1,1,1)
        _Footprint ("Aurora Curtain Footprint", 2D) = "white" {}
        _Vertical ("Vertical Deposition", 2D) = "white" {}
        
    }
    SubShader
    {
        Cull Front //<- draw back faces only, start from back side of volume and work toward camera
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
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

            float4 _VolumeScale;
            float4 _VolumeStart;
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
            
            // Return volume coordinates from world coordinates.
            float3 VolumeFromWorld(float3 world) 
            {
                float3 vol = (world - _VolumeStart) * _VolumeScale;
                return vol;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rayStart = VolumeFromWorld(i.world); // ray start
                float3 cam = VolumeFromWorld(_WorldSpaceCameraPos);
                float3 toCamera = cam - rayStart; // points toward camera
                float3 rayDir = normalize(toCamera); // ray direction
                
                float4 sum=0.0;
                float steps=256; // this many steps in volume
                float stepsize=1.0/steps;
                float limit=min(1.73f,length(toCamera)); // end of t loop
                for (float t=0;t<limit;t+=stepsize) // step along the ray toward the camera
                {
                    float3 vol=rayStart+t*rayDir; // where are we along the ray
                    
                    float4 volumeColor = float4(0,0,0,0); // start black
                    float r = length(vol-float3(0.5f,0.5f,0.5f));
                    if (r<0.5) // if inside a sphere...
                        volumeColor = float4(frac(vol*8.0f),0.0f); // plaid!
                    
                    sum += volumeColor; 
                    
                }
                float exposure=1.5f*stepsize; // scale colors back so they're visible
                
                return 
                    exposure*sum; // totaled up volume intensity
                    //float4(rayStart,1); // ray start point
                    //float4(frac(rayDir),1); // ray direction
            }
            ENDCG
        }
    }
}
