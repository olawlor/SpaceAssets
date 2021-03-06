/*
 Compute gas giant atmospheric chemistry in a texture
*/
Shader "SpaceAssets/GasGiantChemistry"
{
    Properties
    {
        _FlowTex ("Navier-Stokes flow", 2D) = "white" {}
        _CombustionTex ("Combustion", 2D) = "white" {}
        _SimType ("Simulation Type",int) = 0
        
        _AdvectionSpeed ("Advection speed (pixels/timestep)",range(0,3)) = 1
        _VelocityLOD ("Advection velocity LOD",range(0,2)) = 0.3
        
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

            sampler2D _FlowTex;
            sampler2D _CombustionTex;
            float4 _FlowTex_TexelSize; // magic Unity var, gives pixel size of texture
            float4 _CombustionTex_TexelSize; // magic Unity var, gives pixel size of texture
            
            float _SimType; // select which code to run
            float _AdvectionSpeed,_VelocityLOD;  // advection parameters
            float _SharpenFactor; 
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            float4 blend(float4 oldColor,float4 newColor, float howmuch)
            {
                return oldColor*(1.0-howmuch) + newColor*howmuch;
            }
            

            float4 frag (v2f i) : SV_Target
            {
                float4 middleGrayFlow=float4(0.5,0.5,0.0,0);
                if (_Time.g<0.2f) 
                { // Make a start value:
                    if (_SimType==0) { // big polka dot
                        if (length(i.uv-float2(0.5,0.5))<0.2)
                            return float4(1,0,0,0); 
                        
                        return float4(0.9,0.7,0,0);  // yellow jupiter-y background
                    }
                }
                
                float2 uv = i.uv;
                
                // Use flow velocity to figure out where our value came from (upwind)
                float4 V = tex2Dlod(_FlowTex, float4(uv,0,_VelocityLOD)) - middleGrayFlow;
                float2 pixelLOD0 = _FlowTex_TexelSize.xy; 
                float4 upwind = float4(uv - pixelLOD0*_AdvectionSpeed*V.xy,0,0); 
                
                float4 NC = tex2D(_CombustionTex,upwind);
                
                // Fight diffusion by sharpening just slightly
                float2 pixel = _CombustionTex_TexelSize;
                float4 L = tex2D(_CombustionTex,upwind+float2(-pixel.x,0));
                float4 R = tex2D(_CombustionTex,upwind+float2(+pixel.x,0));
                float4 B = tex2D(_CombustionTex,upwind+float2(0,-pixel.x));
                float4 T = tex2D(_CombustionTex,upwind+float2(0,+pixel.x));
                float4 neighborAverage = (L+R+T+B)*0.25;
                NC = blend(NC,neighborAverage,-_SharpenFactor);
                
                /* Atomospheric chemistry!
                    red: red-brown tholins with long UV exposure
                    blue: happens near poles
                */
                float lat=(uv.y-0.5)*180; // degrees
                float stripes=8.8; // in 90 degrees of latitude, this many cycles
                float alternating=clamp(3.0*cos((lat*stripes/90.0)*3.1415),-1.0,+1.0);
                
                if (alternating>0.0) { // upwelling
                    float4 upwellingColor=0.9*float4(1,1,1,1);
                    NC = blend(NC, upwellingColor, 0.0005*alternating); // gets lighter near upwelling
                }
                
                float4 tholinColor=float4(0.7,0.2,0.0,1.0);
                NC = blend(NC, tholinColor, 0.0005); // aging red in the sun
                
                float poles = abs(lat)/90.0; // 0 at equator, 1 at poles
                float4 poleColor = float4(0,0.5,1,1);
                NC = blend(NC, poleColor, 0.0005*poles*poles); // cyan blue near poles
                
                
                return NC;
                //return clamp(NC,0,1); // write out raw color (can get huge)
            }
            ENDCG
        }
    }
}
