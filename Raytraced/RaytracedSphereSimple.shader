/*
 Draw a simple raytraced sphere effect.
*/
Shader "SpaceAssets/RaytracedSphereSimple"
{
    Properties
    {
        _VolumeStart ("Origin of volume in world", vector) = (0,0,0,1)
        _VolumeScale ("Scale to volume coords", vector) = (1,1,1,1)
        _radius ("Sphere Radius", range(0,4)) = 1.0
        
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
            float _radius;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.world = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            // Return object coordinates from world coordinates.
            float3 ObjectFromWorld(float3 world) 
            {
                float3 obj = (world - _VolumeStart) * _VolumeScale;
                return obj;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rayStart = ObjectFromWorld(_WorldSpaceCameraPos); // start at the camera
                float3 target = ObjectFromWorld(i.world); // shoot ray towards proxy geometry
                float3 rayDir = normalize(target - rayStart); // ray direction
                
                float3 C = rayStart; // short name for ray start point
                float3 D = rayDir; // short name for ray direction
                
                float r = _radius; 
                float c = dot(C,C)-r*r;
                float b = 2*dot(C,D);
                float a = dot(D,D);

                float determinant = b*b - 4*a*c;
                if (determinant<0) discard; // ray missed sphere
                float t = (-b -sqrt(determinant))/(2*a);
                if (t<0) discard; // ray hits behind the camera

                float3 hit = rayStart + t*rayDir; // compute hit location
                
                return 
                    float4(frac(4*hit),1); // ray-sphere hit point
                    //float4(rayStart,1); // ray start point
                    //float4(frac(rayDir),1); // ray direction
                    //float4(frac(vol),1);  // volume coordinates
                    //footprint+deposition;
            }
            ENDCG
        }
    }
}
