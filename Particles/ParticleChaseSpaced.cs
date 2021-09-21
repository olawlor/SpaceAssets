/*
 Add to a particle system to make particles that chase a target point.
 Don't allow other particles to get too close.
 
 CAUTION: This is O(n^2) for n particles, so it gets CPU-bound 
 with only a few hundred particles!
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleChaseSpaced : MonoBehaviour
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
            
            // Check if somebody else is too close to us, push away if so
            for (int j=0;j<n;j++) if (i!=j) {
                Vector3 R = P - particles[j].position;
                float tooClose = 10.0f;
                float close = R.magnitude; // distance between particles
                if (close < tooClose) {
                    // push back
                    float anger = 5.0f * (tooClose - close ) / tooClose;
                    Vector3 push = R.normalized * anger;
                    V += push*dt;
                }
            }
            
            particles[i].velocity = V;
        }
        system.SetParticles(particles,n);
        Debug.Log("Updated "+n+" particles");
    }
}
