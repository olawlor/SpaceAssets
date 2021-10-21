/*
 Draw a more complicated raytraced sphere with shading and lighting.
 
 Note that the Unity Standard Surface Shader makes it very hard to emit world-space normals,
 so we calculate lighting ourselves here.
*/
Shader "SpaceAssets/EarthShader"
{
    Properties
    {
        _Albedo ("Sphere Color", color) = (1,0,0,1)
        _SurfaceTexture ("Surface Texture", 2D) = "green" {}
        _SurfaceAltitude ("Surface Altitude", 2D) = "black" {}
        _SurfaceGlow ("Surface Glow from Cities", 2D) = "black" {}
        glowColor ("Surface Glow Color", color) = (0.4,0.2,0.1,1)
        _SurfaceOcean ("Surface Ocean Mask", 2D) = "black" {}
        _Clouds ("Clouds", 2D) = "white" {}
        _VolumeStart ("Origin of volume in world", vector) = (0,0,0,1)
        _VolumeScale ("Scale to volume coords", vector) = (1,1,1,1)
        _radius ("Sphere Radius", range(0,4)) = 1.0
        specularExponent ("Specular Exponent", range(0,400)) = 100.0
        tilty ("Tilt for Bump Map", range(0,100)) = 1.0
        cameraSensitivity ("Overall brightness", range(0,10)) = 1.0
        
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

            sampler2D _SurfaceTexture;
            sampler2D _SurfaceAltitude;
            sampler2D _SurfaceGlow;
            float4 glowColor;
            
            sampler2D _SurfaceOcean;
            sampler2D _Clouds;
            float3 _Albedo;
            float4 _VolumeScale;
            float4 _VolumeStart;
            float _radius;
            float specularExponent;
            float tilty;
            float cameraSensitivity;
            
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
                
                float3 C = rayStart; 
                float3 D = rayDir;
                float r = _radius;
                /*
                 P = C + t * D;
                 
                 length(P) = r
                 sqrt(P.x*P.x + P.y*P.y + P.z*P.z) = r
                 
                 dot(P,P) = length(P) *length(P) = r*r
                 
                 dot(C + t * D,C + t * D) = r*r
                 dot(C,C + t * D) + dot(t * D,C + t * D) = r*r
                 dot(C,C) + t* dot(C,D) + t*dot(D,C) + t*t*dot(D,D) = r*r
                 dot(C,C)-r*r + t* 2*dot(C,D)  + t*t*dot(D,D) = 0
                 
                 This is a quadratic in t:
                 c + t*b + t*t*a = 0
                */
                float c = dot(C,C)-r*r;
                float b = 2*dot(C,D);
                float a = dot(D,D);
                // Find t via the quadratic formula:
                //   t = (-b +- sqrt(b*b - 4*a*c)) / (2*a);
                float determinant = b*b - 4*a*c;
                if (determinant<0) discard; // ray missed!
                
                float t = (-b - sqrt(determinant)) / (2*a);
                if (t<0) { // first intersection behind camera
                    t = (-b + sqrt(determinant)) / (2*a); // exit point?
                    if (t<0) discard; // intersection still behind camera
                }
                
                float3 hit = C + t*D; // hit point!
                float3 normal = normalize(hit); // for a sphere, loc == normal
                
                // Convert -1 to +1 planet coords to lat-lon texture coords
                //  (FIXME: compensate for oblateness?)
                float rad2texCoords = 1.0/(2*3.141592);
                float2 texCoords = float2(
                    atan2(hit.z,hit.x)*rad2texCoords + 0.5, 
                    atan2(hit.y,length(hit.xz))*rad2texCoords*2+0.5
                );
                float4 textureColor = tex2D(_SurfaceTexture,texCoords);
                float4 oceanMask = tex2D(_SurfaceOcean,texCoords);
                float4 glow = glowColor * tex2D(_SurfaceGlow,texCoords);
                
                // "Bump map": tilt in height changes the surface normal.
                //  Find this by looking at neighboring pixel heights.
                float height=tex2D(_SurfaceAltitude,texCoords).r;
                float2 del=float2(1.0/8192.0, 1.0/4096.0); // 1 pixel, in tex coords
                float N=tex2D(_SurfaceAltitude,texCoords+float2(0,del.y)).r;
                float tiltN=height-N; 
                float E=tex2D(_SurfaceAltitude,texCoords+float2(del.x,0)).r;
                float tiltE=height-E;
                
                const float km=1.0/6563.0; // 1/radius of earth, in km (1 = one Earth radius)
                const float altitudeMax=8.85; // height of 1.0 in altitude map (km)
                const float texturePixelSize=40075.0 / 8192.0; // size of pixel (km)
                // Actual tilt = ratio of vertical change / horizontal change
                float tiltUnits = altitudeMax/texturePixelSize;
                
                if (0) {
                    // Draw bump map colors (for debug)
                    textureColor.rgb=0.5+4*float3(tiltE,tiltN,0);
                }
                
                // Apply tilt to the normal vector, in tangent space:
                float3 east =  normalize(cross(hit,float3(0,1,0))); // on surface, facing east
                float3 north = -normalize(cross(hit,east)); // on surface, facing north
                float3 bumpedNormal=normal;
                bumpedNormal+=east*tilty*tiltUnits*tiltE;
                bumpedNormal+=north*tilty*tiltUnits*tiltN;
                bumpedNormal=normalize(bumpedNormal);
                
                
                // Load up the clouds
                float2 cloudCoords = texCoords;
                cloudCoords.x += -0.005*_Time;
                    // *sin(6.28*cloudCoords.y); // <- trade winds?
                float4 clouds = tex2D(_Clouds,cloudCoords);
                
                // Compute the lighting
                float3 toLight = normalize(_WorldSpaceLightPos0.xyz);
                float lighting = dot(bumpedNormal,toLight);
                float specular=0.0;
                if (lighting<0.0) { lighting=0.0; } // no negative light!
                else { // we are lit, try specular highlight
                    glow=0; // <- no streetlights before dusk
                
                    float3 toCamera=normalize(rayStart-hit);
                    float3 halfway = normalize((toCamera + toLight)/2);
                    float specularDot = dot(halfway,normal); // <- sphere normal, *not* bumped!
                    if (specularDot>0 ) {
                    //if (specularDot>0.99) specular=1;
                        specular = oceanMask.r * pow(specularDot,specularExponent); // phong hightlight
                    }
                }
                lighting += 0.05; // ambient light (low for a planet!)
                
                float3 color = lighting * (clouds + _Albedo * textureColor) + specular  + glow;
                
                return 
                    float4(cameraSensitivity*color,1);
                    //float4(frac(normal),1); // surface normal
                    //float4(frac(hit),1); // hit point
                    //float4(rayStart,1); // ray start point
                    //float4((rayDir),1); // ray direction
            }
            ENDCG
        }
    }
}
