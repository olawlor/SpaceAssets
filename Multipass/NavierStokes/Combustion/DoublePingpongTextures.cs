/*
  "Pingpong" swap two textures back and forth:
    read from A and render into B
    vice versa
    repeat
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DoublePingpongTextures : MonoBehaviour
{
    public bool stop=false; // set to true to pause the camera
    public bool singleStep=false; // set to true to render one frame and stop
    public int substeps=10; // <- higher for more physics per timestep
    
    public RenderTexture AF; // texture to read from / render to
    RenderTexture BF; // we will copy A at Start.
    public RenderTexture AC; // texture to read from / render to
    RenderTexture BC; // we will copy A at Start.
    
    public Material readMaterialF; // src
    public Material readMaterialC; // src
    public Camera writeToCameraF; // dst
    public Camera writeToCameraC; // dst
    
    void RenderSetup(RenderTexture srcF,RenderTexture srcC,RenderTexture dstF,RenderTexture dstC)
    {
        if (readMaterialF) {
            readMaterialF.SetTexture("_FlowTex",srcF);
            readMaterialF.SetTexture("_CombustionTex",srcC);
        }
        if (readMaterialC) {
            readMaterialC.SetTexture("_FlowTex",srcF);
            readMaterialC.SetTexture("_CombustionTex",srcC);
        }
        if (writeToCameraF) writeToCameraF.SetTargetBuffers(dstF.colorBuffer,dstF.depthBuffer);
        if (writeToCameraC) writeToCameraC.SetTargetBuffers(dstC.colorBuffer,dstC.depthBuffer);
    }
    
    public bool phase; // false: A->B.  true: B->A
    
    // Start is called before the first frame update
    void Start()
    {
        BF=new RenderTexture(AF); // make a copy of the AF texture
        BC=new RenderTexture(AC); // make a copy of the AC texture
        RenderSetup(AF,AC,BF,BC);
        if (writeToCameraF) writeToCameraF.enabled=false; //<- meaning we call .Render
        if (writeToCameraC) writeToCameraC.enabled=false; //<- meaning we call .Render
    }
   
    // Might want to use Camera.onPreRender here.
    //  See: https://docs.unity3d.com/ScriptReference/Camera-onPreRender.html
    public void FixedUpdate()
    {
        for (int substep=0;substep<substeps;substep++)
        if (!stop || singleStep) {
            if (phase==false)
                RenderSetup(AF,AC,BF,BC); // A -render-> B
            else
                RenderSetup(BF,BC,AF,AC); // B -render-> A
            phase=!phase;
            
            if (writeToCameraC) writeToCameraC.Render();
            if (writeToCameraF) writeToCameraF.Render();
        }
        singleStep=false;
    }
}
