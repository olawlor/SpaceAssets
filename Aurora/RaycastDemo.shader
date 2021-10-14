/*
 Draw a simple raycast effect.
*/
Shader "Examples/RaycastDemo"
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
                
                float4 color=float4(0,0,0,1);
                // Searchlight effect: are we looking down +Z direction?
                if (rayDir.z<-0.99) color=float4(1,1,1,1);
                
                return 
                    color; // totaled up aurora intensity
                    //float4(rayStart,1); // ray start point
                    //float4(frac(rayDir),1); // ray direction
                    //float4(frac(vol),1);  // volume coordinates
                    //footprint+deposition;
            }
            ENDCG
        }
    }
}
