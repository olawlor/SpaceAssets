/*
 Shallow water wave equation simulation
*/
Shader "SpaceAssets/ShallowWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SimType ("Simulation Type",int) = 0
        _VelFactor ("Velocity Factor",range(-1,1)) = 1
        _HeightFactor ("Height Factor",range(-1,1)) = 1
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
                
                float2 pixel = float2(1.0/512.0, 1.0/512.0);
                float2 uv = i.uv;
                float4 area = tex2Dlod(_MainTex, float4(uv,0,_DiffuseLOD))-middleGray; 
                
                /*
                  Neighboring pixels: Left, Right, Top, Bottom, Center
                       T
                    L  C  R
                       B
                */
                float4 V = tex2D(_MainTex, uv) - middleGray;
                uv.xy -= pixel*_AdvectionSpeed*V.xy; 
                float4 C = tex2D(_MainTex, uv) - middleGray; // my old values (Center)
                float4 L = tex2D(_MainTex, uv + float2(-pixel.x,0)) - middleGray;
                float4 R = tex2D(_MainTex, uv + float2(+pixel.x,0)) - middleGray;
                float4 T = tex2D(_MainTex, uv + float2(0,+pixel.y)) - middleGray;
                float4 B = tex2D(_MainTex, uv + float2(0,-pixel.y)) - middleGray;
                
                float4 N = C; // New value for center pixel
                
                if (_SimType==0) 
                { // Shallow Water wave equation
                    N.x += -_VelFactor*(R.z-L.z);
                    N.y += -_VelFactor*(T.z-B.z);
                    N.z += -_HeightFactor*(
                        +R.x-L.x
                        +T.y-B.y
                    );
                    
                    /*
                    // Advection via differential equation
                    float2 gradVx=float2(R.x-L.x,T.x-B.x);
                    float2 gradVy=float2(R.y-L.y,T.y-B.y);
                    float2 V=float2(N.x,N.y);
                    float2 VgV=float2(dot(V,gradVx),dot(V,gradVy));
                    N.xy-=_AdvectionSpeed*VgV;
                    */
                    
                    float4 area = 0.25f * (L+R+T+B); // nearby pixel average
                    
                    // lerp in area average (for stability)
                    N = _BlurFactor*area + (1.0-_BlurFactor)*N;
                    
                    // return N + middleGray; // write out raw color
                    return clamp(N + middleGray,0,1); // clamp the color
                }
                else {
                    return float4(0,0,1,1); // blue == code not found
                }
            }
            ENDCG
        }
    }
}
