/*
 Draw a more complicated raytraced sphere with shading and lighting.
 
 Note that the Unity Standard Surface Shader makes it very hard to emit world-space normals,
 so we calculate lighting ourselves here.
*/
Shader "SpaceAssets/RaytracedSphereLit"
{
    Properties
    {
        _Albedo ("Sphere Color", color) = (1,0,0,1)
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

            float3 _Albedo;
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
            // Return world coordinates from our raytracing object coordinates
            float3 WorldFromObject(float3 object) 
            {
                return (object / _VolumeScale) + _VolumeStart;
            }
            float3 WorldNormalFromObject(float3 objectNormal) 
            {
                return objectNormal / _VolumeScale;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rayStart = ObjectFromWorld(_WorldSpaceCameraPos); // start at the camera
                float3 target = ObjectFromWorld(i.world); // shoot ray towards proxy geometry
                float3 rayDir = normalize(target - rayStart); // ray direction
                
                float3 C = rayStart; // short name for ray start point
                float3 D = rayDir; // short name for ray direction
                
                float r = _radius; 
                float c = dot(C,C) - r*r;
                float b = 2*dot(C,D);
                float a = dot(D,D);

                float determinant = b*b - 4*a*c;
                if (determinant<0) discard; // ray missed sphere
                float t = (-b -sqrt(determinant))/(2*a);
                if (t<0) discard; // ray hits behind the camera

                float3 hit = rayStart + t*rayDir; // compute ray-sphere hit location
                float3 normal = normalize(hit); // surface normal (==position for a sphere)
                
                // Project back to world coordinates
                float3 worldHit = WorldFromObject(hit);
                float3 worldNormal = normalize(WorldNormalFromObject(normal));
                
                // Crude lighting calculation
                float specular = 0;
                float3 toLight = normalize(_WorldSpaceLightPos0.xyz);
                float lighting = dot(toLight, worldNormal);
                if (lighting<0) lighting=0;
                else {
                    // Facing the light, add specular
                    float3 toCamera = normalize(_WorldSpaceCameraPos - worldHit); // point toward camera
                    float3 halfway = normalize(toCamera + toLight); // Blinn's "halfway vector" for specular
                    float phongExponent = 100; // Phong's (hacky) exponent for specular reflection
                    specular = pow(dot(worldNormal,halfway),phongExponent);
                }
                lighting += 0.4; // approximate ambient lighting (sky/floor/etc)
                float3 diffuse = _Albedo * lighting;
                
                float3 color = diffuse + specular;
                
                return 
                    float4(color,1); // ray-sphere hit point
                    //float4(worldNormal,1); // surface normal
                    //float4(frac(4*worldHit),1); // surface hit point
                    //float4(rayStart,1); // ray start point
                    //float4(frac(rayDir),1); // ray direction
                    //float4(frac(vol),1);  // volume coordinates
                    //footprint+deposition;
            }
            ENDCG
        }
    }
}
