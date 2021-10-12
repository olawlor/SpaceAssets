using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MouseSpinCamera : MonoBehaviour
{
    public float speed=1.0f; // degrees of rotation per pixel of mouse movement

    public float rotx=0.0f;
    public float roty=0.0f;

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButton(0) || Input.GetMouseButton(1)) { // left or right click to look around
            rotx += Input.GetAxis("Mouse X")*speed;
            roty += Input.GetAxis("Mouse Y")*speed;
        }
        transform.localEulerAngles=new Vector3(roty,rotx,0);
    }
}
