/*
 Keyboard-based object rotation using Quaternion.

 Works great, giving object-relative rotation, 
 at all angles (unlike Euler). 
 
 Orion Lawlor, lawlor@alaska.edu, 2021-09-07 (Public Domain)
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KeyboardRotateQuaternion : MonoBehaviour
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
        
        Vector3 angles=new Vector3(0,0,0);
        
        // pitch (nose up and down)
        if (Input.GetKey(KeyCode.W)) angles.z -= rate*dt;
        if (Input.GetKey(KeyCode.S)) angles.z += rate*dt;
        
        // yaw (nose left and right)
        if (Input.GetKey(KeyCode.A)) angles.y -= rate*dt;
        if (Input.GetKey(KeyCode.D)) angles.y += rate*dt;
        
        // roll (rotate around the nose)
        if (Input.GetKey(KeyCode.Q)) angles.x += rate*dt;
        if (Input.GetKey(KeyCode.E)) angles.x -= rate*dt;
        
        // Apply updated angles to our quaternion rotation:
        Quaternion rot = transform.localRotation;
        rot *= Quaternion.Euler(angles.x,angles.y,angles.z);
        transform.localRotation=rot;
        
        // Apply ship-forward thrust with Z key:
        Vector3 X=transform.right; // object's X axis (in world space)
        Vector3 V=new Vector3(0,0,0);
        if (Input.GetKey(KeyCode.Z)) V=X*100.0f;
        transform.position += V*dt;        
    }
}
