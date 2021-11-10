/*
 Incompressible Navier-Stokes simulation
*/
Shader "SpaceAssets/NavierStokes"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SimType ("Simulation Type",int) = 0
        _VelFactor ("Velocity Factor",range(-1,1)) = 0.03
        _PressureFactor ("Pressure Factor",range(-1,1)) = 1.0
        _AdvectionSpeed ("Advection speed",range(0,3)) = 1
        _VelocityLOD ("Advection velocity LOD",range(0,2)) = 0.3
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
            float4 _MainTex_ST;
            
            float _SimType; // select code to run
            float _VelFactor, _PressureFactor; // parameters for code
            float _AdvectionSpeed;
            float _VelocityLOD; 

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 middleGray=float4(0.5,0.5,0.5,0);
                if (_Time.g<0.5f) 
                { // Make a start value:
                    float sign=(i.uv.y<0.5)?1.0:-1.0;
                    float4 booking=float4(sign*0.5,0,0,0);
                    return booking + middleGray; 
                }
                
                float2 uv = i.uv;
                
                float4 V = tex2Dlod(_MainTex, float4(uv,0,_VelocityLOD)) - middleGray;
                
                // Use our velocity to figure out where our value came from (upwind)
                float2 pixelLOD0 = float2(1.0/512.0, 1.0/512.0); 
                float4 upwind = float4(uv - pixelLOD0*_AdvectionSpeed*V.xy,0,0); 
                float4 C = tex2Dlod(_MainTex, upwind) - middleGray; // my old value (Center)
                
                /*
                  Loop over mipmap levels, and fix our velocity divergence at each one.
                */
                float4 N = float4(C.x,C.y,0,C.a); // New value for center pixel
                for (float lod=8.0;lod>=0.0;lod-=1.0)
                {
                    /*
                      Read neighboring pixels: Left, Right, Top, Bottom, Center
                           T
                        L  C  R
                           B
                    */
                    float scale=pow(2,lod); // lod==0 -> 1 pixel, lod==3 -> 8 pixel, etc
                    upwind.a=lod; // < the mipmap LOD we read
                    float2 pixel = pixelLOD0*scale; //<- how far we move in the mipmap
                    float4 L = tex2Dlod(_MainTex, upwind + float4(-pixel.x,0,0,0)) - middleGray;
                    float4 R = tex2Dlod(_MainTex, upwind + float4(+pixel.x,0,0,0)) - middleGray;
                    float4 T = tex2Dlod(_MainTex, upwind + float4(0,+pixel.y,0,0)) - middleGray;
                    float4 B = tex2Dlod(_MainTex, upwind + float4(0,-pixel.y,0,0)) - middleGray;
                    
                    N.x += -_VelFactor*(R.b-L.b);
                    N.y += -_VelFactor*(T.b-B.b);
                    N.b += -_PressureFactor*(
                        +R.x-L.x
                        +T.y-B.y
                    );
                }
                
                // Add a moving central sphere:
                float2 center=float2(0.5+0.3*sin(_Time.y),0.5); // moving
                float2 sphereUV=uv-center;
                if (length(sphereUV)<0.05) {
                    float sign=(sphereUV.x>0)?+1.0:-1.0;
                    N.y+=sign*0.01; // spinning force
                }
                
                /*
                // Drop in an occasional checkerboard
                float occasional = sin(_Time.y);
                if (occasional>0.99) {
                    float2 checker=frac(uv*8)-float2(0.5,0.5);
                    float sign=(checker.x*checker.y>0)?+1.0:-1.0;
                    N.x+=sign*0.001;  // tracer lines
                }
                */
                
                // For long-term stability, dial back the velocities just a bit:
                N.xy *= 0.9999;
                
                return N + middleGray; // write out raw color (can get huge)
                //return clamp(N + middleGray,0,1); // clamp the color
            }
            ENDCG
        }
    }
}
