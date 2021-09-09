using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AngularMomentumSpinner : MonoBehaviour
{
    public Vector3 Torque;  // Newton-meters
    public Vector3 AngularMomentum; // = Inertia * AngularVelocity
    public Vector3 AngularVelocity;  // radians/second
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        float dt=Time.deltaTime; // seconds
        
        // compute net Torque this timestep
        
        AngularMomentum += Torque * dt;
        AngularVelocity = AngularMomentum; // FIXME: apply inverse of inertia matrix here
        
        Vector3 Axis = AngularVelocity.normalized; // spin axis
        float angleRad = AngularVelocity.magnitude * dt; // radians
        float angleDeg = angleRad * Mathf.Rad2Deg;
        Quaternion step = Quaternion.AngleAxis(angleDeg,Axis);

        transform.rotation = step * transform.rotation;
        // (or use the fancy Quaternion derivative directly)
    }
}
