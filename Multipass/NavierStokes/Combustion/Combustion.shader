/*
 Compute combustion in a texture
*/
Shader "SpaceAssets/Combustion"
{
    Properties
    {
        _FlowTex ("Navier-Stokes flow", 2D) = "white" {}
        _CombustionTex ("Combustion", 2D) = "white" {}
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

            sampler2D _FlowTex;
            sampler2D _CombustionTex;
            float4 _FlowTex_TexelSize; // magic Unity var, gives pixel size of texture
           
            
            float _SimType; // select which code to run
            float _AdvectionSpeed,_VelocityLOD;  // advection parameters
            float _VelFactor, _PressureFactor; // pseudopressure parameters
            float _BouyancyFactor, _CoolingFactor, _SharpenFactor; 
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            

            float4 frag (v2f i) : SV_Target
            {
                float4 middleGrayFlow=float4(0.5,0.5,0.0,0);
                if (_Time.g<0.2f) 
                { // Make a start value:
                    if (_SimType==0) { // combustion
                        
                        return float4(0,0,1,0); // oxygen
                    }
                }
                
                float2 uv = i.uv;
                
                // Use flow velocity to figure out where our value came from (upwind)
                float4 V = tex2Dlod(_FlowTex, float4(uv,0,_VelocityLOD)) - middleGrayFlow;
                float2 pixelLOD0 = _FlowTex_TexelSize.xy; 
                float4 upwind = float4(uv - pixelLOD0*_AdvectionSpeed*V.xy,0,0); 
                
                float4 NC = tex2D(_CombustionTex,upwind);
                
                if (_SimType==0)
                { // run combustion physics!
                
                        float wide=0.1;
                        if (i.uv.y<0.1 && i.uv.x>0.5-wide && i.uv.x<0.5+wide)
                            return float4(1,1,0.1,0); // hot fuel
                
                    // Fire triangle!
                    float burn = NC.r * NC.g * NC.b;
                    NC.g -= burn;
                    NC.b -= burn;
                    NC.r += 10.0*burn; // fire hot
                
                    NC.r *= 0.995; // lose heat (via radiative transfer?)
                }
                
                return NC; // write out raw color (can get huge)
            }
            ENDCG
        }
    }
}