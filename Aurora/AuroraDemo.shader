/*
 Draw a volume rendered aurora borealis into a cube.
*/
Shader "Examples/AuroraDemo"
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 world : TEXCOORD1; 
            };

            float4 _VolumeScale;
            float4 _VolumeStart;
            sampler2D _Footprint;
            sampler2D _Vertical;

            v2f vert (appdata v)
            {
                v2f o;
                o.world = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
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
                float steps=512; //<- equal to resolution of footprint texture
                float stepsize=1.0/steps;
                float limit=min(1.73f,length(toCamera)); // end of t loop (diagonal of cube, worst case)
                
                for (float t=0;t<limit;t+=stepsize) // step along the ray toward the camera
                {
                    float3 vol=rayStart+t*rayDir; // where are we along the ray
                    
                    // look up the aurora here
                    fixed4 footprint  = tex2Dlod(_Footprint, float4(vol.xz,0,0));
                    fixed4 deposition = tex2Dlod(_Vertical, float4(0.9,vol.y,0,0));
                    float4 aurora = footprint*deposition; 
                    sum += aurora;
                    
                    //if (max(max(vol.x,vol.y),vol.z)>1.0f) limit=0.0f; //<- exited cube + face
                    //if (min(min(vol.x,vol.y),vol.z)<0.0f) limit=0.0f; //<- exited cube - face
                }
                
                float exposure=40.0f*stepsize; //<- set camera exposure (t-relative)
                
                return 
                    exposure*sum; // totaled up aurora intensity
                    //float4(rayStart,1); // ray start point
                    //float4(frac(dir),1); // ray direction
            }
            ENDCG
        }
    }
}
