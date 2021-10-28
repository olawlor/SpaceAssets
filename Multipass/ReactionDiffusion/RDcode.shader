/*
 Reaction-Diffusion shader code
*/
Shader "SpaceAssets/RDcode"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SimType ("Simulation Type",int) = 0
        _A ("Parameter A",range(-1,1)) = 0
        _B ("Parameter B",range(-1,1)) = 0
        _C ("Parameter C",range(-1,1)) = 1
        _D ("Diffusion",range(0,6)) = 2.5
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
            float _A, _B, _C; // parameters for code
            float _D; // diffusion amount

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                if (_Time.g<0.5f) return float4(0,0,0,0); // start value
                
                float2 pixel = float2(1.0/1024.0, 1.0/1024.0);
                float blur = _D; // <- raise up this many mipmap levels (for diffusion)
                float2 uv = i.uv;
                float4 area = tex2Dlod(_MainTex, float4(uv,0,blur)); 
                
                float4 me = tex2D(_MainTex, i.uv); // my old values
                
                if (_SimType==0) 
                { // falling asleep looking patterns
                    float2 center=float2(0.5,0.5);
                    float2 uv = (i.uv-center)*(1.001-_A)+center; // scale to zoom
                    float4 scaled = tex2Dlod(_MainTex, float4(uv,0,blur)); // center value
                    return frac(scaled-0.001+_B);
                }
                else if (_SimType==1) 
                { // tree growth and attack by fire
                    float growing = 0.05*(0.01+_A);
                    me.g += growing;
                    
                    if (me.g>0.9 && area.r>0.15) {
                        me.g=0.0; // trees burn
                        me.r=1.0; // fire hot!
                    }
                    me.r*=0.90; // otherwise attacker gets weaker
                    return me;
                }
                else if (_SimType==2) 
                { // tree growth and attack by bugs
                    float growing = me.g*(0.01+_A);
                    
                    float bugs = (me.r*0.9+area.r*0.1)/10.0;
                    me.g += growing;
                    me.g *=(1.0-5.0*bugs); // trees get eaten by bugs
                    bugs*=4.0*me.g; // bugs survive by eating trees
                    
                    me.r=bugs*10.0;
                    
                    if (me.g>1.0) me.g=1.0;
                    if (me.r>1.0) me.r=1.0;
                    if (me.r<0.0) me.r=0.0;
                    
                    return me;
                }
                else if (_SimType==3) 
                { // ice solidification (work in progress)
                    float cooling = 0.01+_A;
                    me.r -= cooling;
                    
                    // Look for nearby ice:
                    float4 nbor1 = tex2D(_MainTex, uv + float2(-2*pixel.x,pixel.y));
                    float4 nbor2 = tex2D(_MainTex, uv + float2(0,2*pixel.y));
                    float4 nbor3 = tex2D(_MainTex, uv + float2(+2*pixel.x,pixel.y));
                    float4 nbor4 = tex2D(_MainTex, uv + float2(-2*pixel.x,-pixel.y));
                    float4 nbor5 = tex2D(_MainTex, uv + float2(0,-2*pixel.y));
                    float4 nbor6 = tex2D(_MainTex, uv + float2(+2*pixel.x,-pixel.y));
                    
                    float icy = nbor1.b+nbor2.b+nbor3.b+nbor4.b+nbor5.b+nbor6.b;
                    if (icy>=1.0 && me.b<1.0 && me.r<0.5) // we can freeze!
                    {
                        me.b+=0.1; // add some cold
                        me.r+=1.0*_C; // release heat of fusion (warms area)
                    }
                    return me;
                }
                else {
                    return float4(0,0,1,1); // blue == code not found
                }
            }
            ENDCG
        }
    }
}
