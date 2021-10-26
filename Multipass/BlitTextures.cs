/*
  Copy two textures back and forth:
    read from A and render into B
    this script blits B into A
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlitTextures : MonoBehaviour
{
    public RenderTexture A;
    public RenderTexture B;
    
    // FIXME: this might do the wrong thing if Unity calls it in the wrong order.
    void Update()
    {
        Graphics.Blit(B,A);
    }
}
