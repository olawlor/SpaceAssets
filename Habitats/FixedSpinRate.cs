using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FixedSpinRate : MonoBehaviour
{
    public float spinRate; // in degrees per second
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        transform.localEulerAngles=new Vector3(Time.time*spinRate,0,0);
    }
}
