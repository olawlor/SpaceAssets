/*
 Combustion-enabled Incompressible Navier-Stokes simulation
*/
Shader "SpaceAssets/FlowCombustion"
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
            float _BouyancyFactor; 
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
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
                float4 N = float4(0,0,0,-divergenceTarget); // New value for center pixel
                for (float lod=8.0;lod>=0.0;lod-=1.0)
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
                    float4 L = tex2Dlod(_FlowTex, upwind + float4(-pixel.x,0,0,0)) - middleGray;
                    float4 R = tex2Dlod(_FlowTex, upwind + float4(+pixel.x,0,0,0)) - middleGray;
                    float4 T = tex2Dlod(_FlowTex, upwind + float4(0,+pixel.y,0,0)) - middleGray;
                    float4 B = tex2Dlod(_FlowTex, upwind + float4(0,-pixel.y,0,0)) - middleGray;
                    
                    N.x += -_VelFactor*(R.a-L.a);
                    N.y += -_VelFactor*(T.a-B.a);
                    N.a += -_PressureFactor*(
                        +R.x-L.x
                        +T.y-B.y
                    );
                }
                
                // Keep the overall average velocity near zero (avoids weird wind gusts)
                float4 avg = tex2Dlod(_FlowTex, float4(0.5,0.5,0,100.0)) - middleGray;
                float avgBlend=0.1;
                N.xy -= avgBlend*avg;
                
                return N;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 middleGray=float4(0.5,0.5,0.0,0);
                if (_Time.g<0.2f) 
                { // Make a start value:
                    if (_SimType==0) { // shear flow
                        return middleGray;
                    }
                }
                
                float2 uv = i.uv;
                
                // Use our velocity to figure out where our value came from (upwind)
                float4 V = tex2Dlod(_FlowTex, float4(uv,0,_VelocityLOD)) - middleGray;
                float2 pixelLOD0 = _FlowTex_TexelSize.xy; 
                float4 upwind = float4(uv - pixelLOD0*_AdvectionSpeed*V.xy,0,0); 
                float4 C = tex2Dlod(_FlowTex, upwind) - middleGray; // my old value (Center)
                
                // Adjust velocities and pseudopressure at this pixel
                float4 N=solvePseudopressure(0,upwind,pixelLOD0,middleGray);
                N.xyz+=C.xyz; // inertia on velocity field
                
                if (_SimType==0)
                { /*
                Combustion:
                    Flow: 
                        red & green: navier-stokes fluid flow velocity
                        blue: temperature of fluid
                        alpha: incompressible navier-stokes pseudopressure
                    Combustion: 
                        red: heat
                        green: fuel
                        blue: oxygen
                */
                    float4 C=tex2D(_CombustionTex,uv);
                    N.b=C.r; // copy over from combustion texture
                    N.y+=_BouyancyFactor*N.b; 
                    
                    if (uv.y<0.01 || uv.x>0.99) // bottom or right edge
                    {
                        N.xy=0.0; // don't flow
                    }
                }
                return N + middleGray; // write out raw color (can get huge)
                //return clamp(N + middleGray,0,1); // clamp the color
            }
            ENDCG
        }
    }
}
