using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MomentumSpinner : MonoBehaviour
{
    
    public Vector3 LaserHit; // world space location where laser is hitting
    public Vector3 LaserForce; // world space direction of force
        
    public Vector3 AngularMomentum; // Velocity * Inertia
    public Vector3 AngularVelocity; // radians/sec on each global axis

    // Start is called before the first frame update
    void Start()
    {
        
    }
    
    public void ApplyTorque(Vector3 LaserHit, Vector3 LaserForce,float dt)
    {
        Vector3 COM = transform.position; // center of mass (position)
        Vector3 Lever = LaserHit - COM; // relative vector to force (m)
        Vector3 Force = LaserForce; // Newtons of laser force
        Vector3 Torque = Vector3.Cross(Lever,Force); 
        
        AngularMomentum += Torque*dt;
    }

    // Update is called once per frame
    void Update()
    {
        float dt = Time.deltaTime;  // seconds
        
        //ShootLasers(dt);
        
        float Inertia=1000.0f; // For a general object, this is a matrix
        AngularVelocity = AngularMomentum / Inertia;
        
        Vector3 Axis = AngularVelocity.normalized; // unit vector
        float angleRad = AngularVelocity.magnitude*dt; // radians in this step
        float angleDeg = angleRad * Mathf.Rad2Deg; // degrees in this step
        Quaternion step = Quaternion.AngleAxis(angleDeg,Axis);
        
        transform.rotation = step * transform.rotation;
    }
}

