/*
  Emit particles in a jet, for spinning habitat.
  
  Works in hab-local coordinates, which requires 
  coriolis terms to be added to the physics.
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CoriolisParticleJet : MonoBehaviour
{
    public GameObject fountainObject; // where particles are flying from
    public float upVelocity = 5.0f; // upward initial velocity m/s
    
    public Vector3 spinRate = new Vector3(20,0,0); // degrees/sec spin rates on each axis
    public Vector3 spinCenter = new Vector3(0,0,0); // a point on the axis of rotation
    
    public float emissionRate=20.0f; // particles/sec emission (on average)
    
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
    // Apply rotating-frame forces to existing particles
        float dt=Time.deltaTime;
        Vector3 W = spinRate*Mathf.Deg2Rad; // spin rate in radians/sec
        int n = system.GetParticles(particles);
        for (int i=0;i<n;i++) {
            Vector3 R = particles[i].position - spinCenter; // in local coords
            Vector3 V = particles[i].velocity; // in local coords
            
            // See https://en.wikipedia.org/wiki/Coriolis_force#Formula
            Vector3 coriolis = 2.0f * Vector3.Cross(V,W); //<- flipped to get right-handed cross product
            Vector3 centrifugal = Vector3.Cross(Vector3.Cross(W,R),W);
            
            Vector3 A = coriolis + centrifugal;
            V += A*dt;
            
            particles[i].velocity = V;
        }
        system.SetParticles(particles,n);
    
    // Consider emitting a particle:
        bool emitWinner=(emissionRate*Time.deltaTime)>Random.Range(0.0f,1.0f); // lottery style
        if (emitWinner) createParticle();
    }
    
    // Add a particle to our system
    void createParticle()
    {
        // Figure out where to emit particles:
        Vector3 P = fountainObject.transform.localPosition;
        
        // Figure out the particles' initial local velocity
        Vector3 fountainUp = transform.InverseTransformDirection(fountainObject.transform.up);
        Vector3 V = fountainUp * upVelocity;
        
        // Emit a particle
        ParticleSystem.EmitParams settings = new ParticleSystem.EmitParams();

        settings.position=P; // position relative to the particleSystem
        settings.velocity=V; // initial velocity
        
        system.Emit(settings,1);
    }
}
