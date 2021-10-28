/*
  "Pingpong" swap two textures back and forth:
    read from A and render into B
    vice versa
    repeat
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PingpongTextures : MonoBehaviour
{
    public bool stop=false; // set to true to pause the camera
    public bool singleStep=false; // set to true to render one frame and stop
    
    public RenderTexture A; // texture to read from / render to
    public RenderTexture B; // another, or null and we will copy A at Start.
    
    public Material readMaterial; // src
    public Camera writeToCamera; // dst
    public Material showMaterial; // src
    
    void RenderSetup(RenderTexture src,RenderTexture dst)
    {
        if (readMaterial) readMaterial.SetTexture("_MainTex",src);
        if (writeToCamera) writeToCamera.SetTargetBuffers(dst.colorBuffer,dst.depthBuffer);
        if (showMaterial) showMaterial.SetTexture("_MainTex",dst);
    }
    
    public bool phase; // false: A->B.  true: B->A
    
    // Start is called before the first frame update
    void Start()
    {
        if (!A) return;
        if (!B) B=new RenderTexture(A); // make a copy of the A texture
        RenderSetup(A,B);
        if (writeToCamera) writeToCamera.enabled=false; //<- meaning we call .Render
    }
   
    // Might want to use Camera.onPreRender here.
    //  See: https://docs.unity3d.com/ScriptReference/Camera-onPreRender.html
    public void FixedUpdate()
    {
        if (!A) return;

        if (!stop || singleStep) {
            if (phase==false)
                RenderSetup(A,B); // A -render-> B
            else
                RenderSetup(B,A); // B -render-> A
            phase=!phase;
            
            if (writeToCamera) writeToCamera.Render();
        }
        singleStep=false;
    }
}
