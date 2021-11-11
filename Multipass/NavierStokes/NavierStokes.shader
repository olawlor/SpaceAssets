/*
 Incompressible Navier-Stokes simulation
*/
Shader "SpaceAssets/NavierStokes"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SimType ("Simulation Type",int) = 0
        
        _AdvectionSpeed ("Advection speed (pixels/timestep)",range(0,3)) = 1
        _VelocityLOD ("Advection velocity LOD",range(0,2)) = 0.3
        
        _VelFactor ("Pseudopressure to Velocity",range(-1,1)) = 0.03
        _PressureFactor ("Pseudopressure from Velocity",range(-1,1)) = 1.0
        
        _BouyancyFactor ("Bouyancy Factor",range(-0.01,0.01)) = 0.001
        _CoolingFactor ("Cooling Factor",range(-0.01,0.01)) = 0.002
        _SharpenFactor ("Sharpening Factor",range(-0.1,0.1)) = 0.01
        
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

            sampler2D _MainTex;
            float4 _MainTex_TexelSize; // magic Unity var, gives pixel size of texture
            float4 _MainTex_ST;
            
            float _SimType; // select which code to run
            float _AdvectionSpeed,_VelocityLOD;  // advection parameters
            float _VelFactor, _PressureFactor; // pseudopressure parameters
            float _BouyancyFactor, _CoolingFactor, _SharpenFactor; 
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
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
                    float4 L = tex2Dlod(_MainTex, upwind + float4(-pixel.x,0,0,0)) - middleGray;
                    float4 R = tex2Dlod(_MainTex, upwind + float4(+pixel.x,0,0,0)) - middleGray;
                    float4 T = tex2Dlod(_MainTex, upwind + float4(0,+pixel.y,0,0)) - middleGray;
                    float4 B = tex2Dlod(_MainTex, upwind + float4(0,-pixel.y,0,0)) - middleGray;
                    
                    N.x += -_VelFactor*(R.a-L.a);
                    N.y += -_VelFactor*(T.a-B.a);
                    N.a += -_PressureFactor*(
                        +R.x-L.x
                        +T.y-B.y
                    );
                }
                return N;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 middleGray=float4(0.5,0.5,0.0,0);
                if (_Time.g<0.2f) 
                { // Make a start value:
                    if (_SimType==2) { // oil on top, water on bottom
                        if (i.uv.y>0.5) {
                            return float4(0,0,1,0) + middleGray;
                        }
                        else return middleGray;
                    }
                    if (_SimType==1) { // hot gas on bottom
                        if (length(i.uv-float2(0.5,0.21))<0.2) {
                            return float4(0,0.1,1,0) + middleGray;
                        }
                        else return middleGray;
                    }
                    if (_SimType==0) { // shear flow
                        float sign=(i.uv.y<0.5)?1.0:-1.0;
                        float4 booking=float4(sign*0.5,0,0,0);
                        return booking + middleGray; 
                    }
                }
                
                float2 uv = i.uv;
                
                // Use our velocity to figure out where our value came from (upwind)
                float4 V = tex2Dlod(_MainTex, float4(uv,0,_VelocityLOD)) - middleGray;
                float2 pixelLOD0 = _MainTex_TexelSize.xy; 
                float4 upwind = float4(uv - pixelLOD0*_AdvectionSpeed*V.xy,0,0); 
                float4 C = tex2Dlod(_MainTex, upwind) - middleGray; // my old value (Center)
                
                // Adjust velocities and pseudopressure at this pixel
                float4 N=solvePseudopressure(0,upwind,pixelLOD0,middleGray);
                N.xyz+=C.xyz; // inertia on velocity field
                
                if (_SimType==2)
                { // oil and water simulation
                    float tilt = 0.2*sin(_Time.y*0.3); // gravity tilt angle, in radians
                    float up = 10.0*_BouyancyFactor*(N.b-0.5); // oil rises, water sinks
                    N.x += tilt*up;
                    N.y += up;
                    
                    N.b = clamp((N.b-0.5)*(1.0+_SharpenFactor)+0.5,0,1); // fight diffusion
                    
                    float edge=1.0/100.0;
                    if (uv.x<edge || uv.x>1.0-edge || uv.y<edge || uv.y>1.0-edge)
                    { // on the edge, don't let fluid flow
                        N.xy=0;
                    }
                }
                
                if (_SimType==1)
                { // blue-hot bouyant fluid
                    N.y += _BouyancyFactor*N.b; // hot rises
                    N.b *= 1.0-_CoolingFactor; // cools off
                    N.b = clamp((N.b-0.5)*(1.0+_SharpenFactor)+0.5,0,1); // fight diffusion
                }
                
                if (_SimType==0) 
                {  // Simple fluids demo               
                    // Add a moving central sphere:
                    float2 center=float2(0.5+0.3*sin(_Time.y),0.5); // moving
                    float2 sphereUV=uv-center;
                    if (length(sphereUV)<0.05) {
                        float sign=(sphereUV.x>0)?+1.0:-1.0;
                        N.y+=sign*0.01; // spinning force
                    }
                    // For long-term stability, dial back the velocities just a bit:
                    N.xy *= 0.9999;
                    N.b=N.a*10.0; // show alpha divergence (for debugging)
                }
                
                return N + middleGray; // write out raw color (can get huge)
                //return clamp(N + middleGray,0,1); // clamp the color
            }
            ENDCG
        }
    }
}
