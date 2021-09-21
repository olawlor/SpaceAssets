/*
 Add to a particle system to make particles that chase a target point.
 Computes an accleration that makes the particles orbit the point.
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleChaseOrbit : MonoBehaviour
{
    public GameObject targetObject;
    public Vector3 targetPoint;
    
    // This is our ParticleSystem component.
    private ParticleSystem system;
    private int nParticles=0;
    private ParticleSystem.Particle[] particles;
    
    // Start is called before the first frame update
    void Start()
    {
        system=gameObject.GetComponent<ParticleSystem>();
        nParticles=system.main.maxParticles;
        
        // Preallocate our particles array (for speed)
        particles = new ParticleSystem.Particle[nParticles];
    }

    // Update is called once per frame
    void Update()
    {
        // Update the target position
        if (targetObject) targetPoint = targetObject.transform.position;
        
        // Loop over our particles
        int n = system.GetParticles(particles);
        for (int i=0;i<n;i++) {
            float dt = Time.deltaTime;
            Vector3 P = particles[i].position;
            Vector3 V = particles[i].velocity;
            
            float toward = 0.1f; // acceleration rate, in m/s^2 per meter of separation
            Vector3 A = toward * (targetPoint - P);
            V += A*dt;
            
            float slowdown = 0.3f;
            V *= (1.0f - slowdown*dt); // bleed off excess velocity
            
            particles[i].velocity = V;
        }
        system.SetParticles(particles,n);
        Debug.Log("Updated "+n+" particles");
    }
}
