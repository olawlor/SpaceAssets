/*
 Combustion-enabled Incompressible Navier-Stokes simulation
*/
Shader "SpaceAssets/FlowGasGiant"
{
    Properties
    {
        _FlowTex ("Flow", 2D) = "white" {}
        _CombustionTex ("Combustion", 2D) = "white" {}
        _SimType ("Simulation Type",int) = 0
        
        _AdvectionSpeed ("Advection speed (pixels/timestep)",range(0,3)) = 1
        _VelocityLOD ("Advection velocity LOD",range(0,2)) = 0.3
        
        _VelFactor ("Pseudopressure to Velocity",range(-1,1)) = 0.03
        _PressureFactor ("Pseudopressure from Velocity",range(-1,1)) = 1.0
        
        _BouyancyFactor ("Bouyancy Factor",range(-0.01,0.01)) = 0.001
        _FireExpands ("Fire Expands",range(-1,1)) = 0.1
        
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

            sampler2D _FlowTex;
            float4 _FlowTex_TexelSize; // magic Unity var, gives pixel size of texture
            
            sampler2D _CombustionTex;
            
            float _SimType; // select which code to run
            float _AdvectionSpeed,_VelocityLOD;  // advection parameters
            float _VelFactor, _PressureFactor; // pseudopressure parameters
            float _BouyancyFactor, _FireExpands; 
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            /* Convert 2D texture coordinates to float4 used by tex2Dlod. 
                 frac() is used to make the texture coordinates repeat.
            */
            float4 makeLOD(float2 uv,float lod) {
                return float4(frac(uv),0.0,lod);
            }
            
            /* Incompressible Navier-Stokes: return adjusted 
              fluid velocity (xy channels) and divergence (alpha channel)
              to make the flow field have this divergence.
            */
            float4 solvePseudopressure(float divergenceTarget, float2 uv,float2 pixelLOD0, float4 middleGray)
            {
                /*
                  Loop over mipmap levels, and fix our velocity divergence at each one.
                */
                float4 N = float4(0,0,0,divergenceTarget); // New value for center pixel
                for (float lod=7.0;lod>=0.0;lod-=1.0)
                {
                    /*
                      Read neighboring pixels: Left, Right, Top, Bottom, Center
                           T
                        L  C  R
                           B
                    */
                    float scale=pow(2,lod); // lod==0 -> 1 pixel, lod==3 -> 8 pixel, etc
                    float4 upwind = float4(uv,0,lod); // < set the mipmap LOD we read
                    float2 pixel = pixelLOD0*scale; //<- how far we move in the mipmap
                    float4 L = tex2Dlod(_FlowTex, makeLOD(uv + float4(-pixel.x,0,0,0),lod)) - middleGray;
                    float4 R = tex2Dlod(_FlowTex, makeLOD(uv + float4(+pixel.x,0,0,0),lod)) - middleGray;
                    float4 T = tex2Dlod(_FlowTex, makeLOD(uv + float4(0,+pixel.y,0,0),lod)) - middleGray;
                    float4 B = tex2Dlod(_FlowTex, makeLOD(uv + float4(0,-pixel.y,0,0),lod)) - middleGray;
                    
                    N.x += -_VelFactor*(R.b-L.b);
                    N.y += -_VelFactor*(T.b-B.b);
                    N.b += -_PressureFactor*(
                        +R.x-L.x
                        +T.y-B.y
                    );
                }
                
                /*
                // Keep the overall average velocity near zero (avoids weird wind gusts)
                float4 avg = tex2Dlod(_FlowTex, float4(0.5,0.5,0,100.0)) - middleGray;
                float avgBlend=0.1;
                N.xy -= avgBlend*avg;
                */
                
                return N;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 middleGray=float4(0.5,0.5,0.5,0.5);
                
                float2 uv = i.uv;
                
                // Use our velocity to figure out where our value came from (upwind)
                float4 V = tex2Dlod(_FlowTex, float4(uv,0,_VelocityLOD)) - middleGray;
                float2 pixelLOD0 = _FlowTex_TexelSize.xy; 
                float4 upwind = float4(uv - pixelLOD0*_AdvectionSpeed*V.xy,0,0); 
                float4 C = tex2Dlod(_FlowTex, upwind) - middleGray; // my old value (Center)
                
                float divergence=0; //<- target expansion rate
                
                // Adjust velocities and pseudopressure at this pixel
                float4 N=solvePseudopressure(divergence,upwind,pixelLOD0,middleGray);
                N.xy+=C.xy; // inertia on velocity field
                
                if (_SimType==0) {
                    // Horizontal deep convection bands drive surface flow
                    float lat=(uv.y-0.5)*180; // degrees
                    float stripes=8.5; // in 90 degrees of latitude, this many cycles
                    float alternating=clamp(10.0*cos((lat*stripes/90.0)*3.1415),-1.0,+1.0);
                    float poles = abs(lat)/90.0; // 0 at equator, 1 at poles
                    alternating *= 1.0-0.5*poles; // less motion at the poles -> less turbulence
                    
                    // Set the target velocity
                    float targetX = 0.3*alternating;
                    float targetY = 0.0; 
                    
                    if (_Time.g<0.2f) 
                    { // Make the starting velocity the deep value:
                        return float4(targetX,targetY,0,0)+middleGray;
                    }
                    
                    float blend = 0.001; //  fraction of deep convection velocity to blend in
                    N.x = blend*targetX + (1.0-blend)*N.x; 
                    blend*=10.0; // Y is more strongly coupled to deep flow
                    N.y = blend*targetY + (1.0-blend)*N.y;
                    
                    if (_Time.g<3.0 && length(uv-float2(0.3,0.4))<0.01) N.xy=0.001; //<- break symmetry, tiny dot
                } else {
                    if (_Time.g<0.2f) 
                    { // Make the starting velocity zero
                        if (length(i.uv-float2(0.5,0.5))<0.2)
                            return float4(0.5,1.0,0,0)+middleGray; 
                        return middleGray;
                    }
                    if (_SimType==2) {
                        
                    }
                }
                
                return N + middleGray; // write out raw color (can get huge)
                //return clamp(N + middleGray,0,1); // clamp the color
            }
            ENDCG
        }
    }
}
