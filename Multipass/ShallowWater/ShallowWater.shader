/*
 Shallow water wave equation simulation
*/
Shader "SpaceAssets/ShallowWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SimType ("Simulation Type",int) = 0
        _VelFactor ("Velocity Factor",range(-1,1)) = 0
        _HeightFactor ("Height Factor",range(-1,1)) = 0
        _BlurFactor ("Blur Factor",range(0,1)) = 0.01
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
                if (_Time.g<0.5f) return middleGray; // start value
                
                float2 pixel = float2(1.0/1024.0, 1.0/1024.0);
                float2 uv = i.uv;
                float4 area = tex2Dlod(_MainTex, float4(uv,0,_DiffuseLOD))-middleGray; 
                
                /*
                  Neighboring pixels: Left, Right, Top, Bottom, Center
                       T
                    L  C  R
                       B
                */
                float4 C = tex2D(_MainTex, uv) - middleGray; // my old values (Center)
                float4 L = tex2D(_MainTex, uv + float2(-pixel.x,0)) - middleGray;
                float4 R = tex2D(_MainTex, uv + float2(+pixel.x,0)) - middleGray;
                float4 T = tex2D(_MainTex, uv + float2(0,+pixel.y)) - middleGray;
                float4 B = tex2D(_MainTex, uv + float2(0,-pixel.y)) - middleGray;
                
                float4 N = C; // New value for center pixel
                
                if (_SimType==0) 
                { // Shallow Water wave equation
                    N.x += _VelFactor*(R.z-L.z);
                    N.y += _VelFactor*(T.z-B.z);
                    N.z += _HeightFactor*(
                        +R.x-L.x
                        +T.y-B.y
                    );
                    
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
