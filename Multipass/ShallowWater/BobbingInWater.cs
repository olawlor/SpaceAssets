/*
 Smoothly change color of object, like it's "bobbing up and down" in water.
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BobbingInWater : MonoBehaviour
{
    public float bobPeriod=2.0f; // seconds in bobbing period
    
    private Renderer render;
    
    // Start is called before the first frame update
    void Start()
    {
        render=GetComponent<Renderer>();
    }

    // Update is called once per frame
    void Update()
    {
        if (render) {
            float bright=0.5f + 0.5f*Mathf.Sin(Time.time/bobPeriod*6.28f);
            render.material.color=new Color(0.5f,0.5f,bright);
        }
    }
}
