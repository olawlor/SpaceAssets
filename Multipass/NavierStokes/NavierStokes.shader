/*
 Shallow water wave equation simulation
*/
Shader "SpaceAssets/NavierStokes"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SimType ("Simulation Type",int) = 0
        _VelFactor ("Velocity Factor",range(-1,5)) = 1
        _HeightFactor ("Height Factor",range(-1,5)) = 1
        _BlurFactor ("Blur Factor (for stability)",range(0,1)) = 0.7
        _AdvectionSpeed ("Advection speed",range(0,3)) = 1
        _DiffuseLOD ("Diffusion LOD",range(0,6)) = 1.5
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
            float _VelFactor, _HeightFactor, _BlurFactor; // parameters for code
            float _AdvectionSpeed;
            float _DiffuseLOD; // diffusion amount

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
                    if (i.uv.y<0.5) return float4(1,0.5,0.5,0); // red booking +x
                    return middleGray; 
                }
                
                float2 uv = i.uv;
                
                /*
                  Neighboring pixels: Left, Right, Top, Bottom, Center
                       T
                    L  C  R
                       B
                */
                float4 V = tex2D(_MainTex, uv) - middleGray;
                
                float4 N = float4(V.x,V.y,0,0); // New value for center pixel
                float4 area;
                for (float lod=9.0;lod>=0.0;lod-=1.0)
                {
                    float scale=pow(2,lod); // lod==0 -> 1 pixel, lod==3 -> 8 pixel
                    float2 pixel = scale*float2(1.0/512.0, 1.0/512.0);
                    float4 upwind = float4(uv - pixel*_AdvectionSpeed*V.xy,0,lod);  // upwind advection
                    float4 C = tex2Dlod(_MainTex, upwind) - middleGray; // my old values (Center)
                    float4 L = tex2Dlod(_MainTex, upwind + float4(-pixel.x,0,0,0)) - middleGray;
                    float4 R = tex2Dlod(_MainTex, upwind + float4(+pixel.x,0,0,0)) - middleGray;
                    float4 T = tex2Dlod(_MainTex, upwind + float4(0,+pixel.y,0,0)) - middleGray;
                    float4 B = tex2Dlod(_MainTex, upwind + float4(0,-pixel.y,0,0)) - middleGray;
                    
                    N.x += -_VelFactor*(R.z-L.z);
                    N.y += -_VelFactor*(T.z-B.z);
                    N.z += -_HeightFactor*(
                        +R.x-L.x
                        +T.y-B.y
                    );
                    
                    area = 0.25f * (L+R+T+B); // nearby pixel average
                }
                
                // lerp in area average (for stability)
                N = _BlurFactor*area + (1.0-_BlurFactor)*N;
                
                // Boundary sphere:
                float2 center=float2(0.5+0.3*sin(_Time.y),0.5);
                if (length(uv-center)<0.05) {
                    N.y+=0.01; // upward force
                }
                
                //return N + middleGray; // write out raw color
                return clamp(N + middleGray,0,1); // clamp the color
            }
            ENDCG
        }
    }
}
