/*
 Use arrow keys to adjust the direction of a particle jet.

 Dr. Orion Lawlor, lawlor@alaska.edu, 2021-09-27 (Public Domain)
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ArrowTiltJet : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        float rate=20.0f; // degrees/sec
        float dt=Time.deltaTime; // seconds
        Vector3 angles=transform.localEulerAngles;
        
        if (Input.GetKey(KeyCode.UpArrow)) angles.z -= rate*dt;
        if (Input.GetKey(KeyCode.DownArrow)) angles.z += rate*dt;
        
        if (Input.GetKey(KeyCode.LeftArrow)) angles.x += rate*dt;
        if (Input.GetKey(KeyCode.RightArrow)) angles.x -= rate*dt;
        
        transform.localEulerAngles=angles;
    }
}
