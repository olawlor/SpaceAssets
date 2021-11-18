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
        
        _CoolingFactor ("Cooling Factor",range(-0.01,0.01)) = 0.005
        
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
                    if (_SimType==0 || _SimType==1) { // combustion
                        
                        return float4(0,0,1,0); // oxygen
                    }
                }
                
                float2 uv = i.uv;
                
                // Use flow velocity to figure out where our value came from (upwind)
                float4 V = tex2Dlod(_FlowTex, float4(uv,0,_VelocityLOD)) - middleGrayFlow;
                float2 pixelLOD0 = _FlowTex_TexelSize.xy; 
                float4 upwind = float4(uv - pixelLOD0*_AdvectionSpeed*V.xy,0,0); 
                
                float4 NC = tex2D(_CombustionTex,upwind);
                
                if (_SimType==0 || _SimType==1)
                { // run combustion physics!
                
                    // Inject hot fuel at the base
                    float wide=0.05;
                    float left=0.5-wide;
                    float right=0.5+wide;
                    if (i.uv.y<0.1 && i.uv.x>left && i.uv.x<right)
                    { // Emit hot fuel
                        if (_SimType==0) 
                            return float4(1,1,0.1,0); // hot fuel
                        else
                        {
                            if (i.uv.y<0.02 && i.uv.x>right-0.002) 
                                return float4(1,0,0,0); // tiny spark
                            return float4(0,1,0,0); // not hot
                        }
                    }
                
                    // Fire triangle!
                    float activation=0.02; // minimum activation energy needed
                    float burn = NC.r * NC.g * NC.b - activation;
                    if (burn>0) {
                        NC.g -= burn;
                        NC.b -= burn;
                        NC.r += 10.0*burn; // fire hot
                    }
                    
                    NC.r *= (1.0-_CoolingFactor); // lose heat (via radiative transfer?)
                }
                
                return NC; // write out raw color (can get huge)
            }
            ENDCG
        }
    }
}
