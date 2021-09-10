/*
 Keyboard-based object rotation using Euler angles.

 Works fairly OK until you rotate by 90 degrees, then
 you get control inversion or gimbal lock.

 Orion Lawlor, lawlor@alaska.edu, 2021-09-07 (Public Domain)
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KeyboardRotateEuler : MonoBehaviour
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
        
        // pitch (nose up and down)
        if (Input.GetKey(KeyCode.W)) angles.z += rate*dt;
        if (Input.GetKey(KeyCode.S)) angles.z -= rate*dt;
        
        // yaw (nose left and right)
        if (Input.GetKey(KeyCode.A)) angles.y -= rate*dt;
        if (Input.GetKey(KeyCode.D)) angles.y += rate*dt;
        
        // roll (rotate around the nose)
        if (Input.GetKey(KeyCode.Q)) angles.x += rate*dt;
        if (Input.GetKey(KeyCode.E)) angles.x -= rate*dt;
        
        transform.localEulerAngles=angles;
    }
}
