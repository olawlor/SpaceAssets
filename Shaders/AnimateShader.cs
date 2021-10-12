/*
 Set one shader's material property as a function of time.
 
 See: 
   https://docs.unity3d.com/ScriptReference/Material.SetFloat.html
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimateShader : MonoBehaviour
{
    public string propertyName="_SlicePhase";
    public float timeScale=0.5f;
    public float timeStart=0.0f;

    private Material mat;
    
    // Start is called before the first frame update
    void Start()
    {
        mat=gameObject.GetComponent<Renderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        mat.SetFloat(propertyName,Time.time*timeScale+timeStart);
    }
}

