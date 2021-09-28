/*
  Emit particles in a jet, for spinning habitat
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HabParticleJet : MonoBehaviour
{
    public GameObject fountainObject; // where particles are flying from
    public float upVelocity = 5.0f; // upward initial velocity m/s
    
    public GameObject habObject; // hack to calculate starting velocity
    public float spinVelocity = 10.0f; // tangent velocity in meters/sec (from SpinCalc)
    
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
        bool emitWinner=(emissionRate*Time.deltaTime)>Random.Range(0.0f,1.0f); // lottery style
        if (!system || !emitWinner) return; // no particle to emit
        
        // Figure out where to emit particles:
        Vector3 P = fountainObject.transform.position;
        
        // Figure out the particles' initial velocity:
        Vector3 V = -habObject.transform.forward * spinVelocity;
        V += fountainObject.transform.up * upVelocity;
        
        // Emit a particle
        ParticleSystem.EmitParams settings = new ParticleSystem.EmitParams();

        P -= Time.deltaTime*V; // <- seems needed to keep jet and particles aligned?
        
        settings.position=P; // position relative to the particleSystem
        settings.velocity=V; // initial velocity
        
        system.Emit(settings,1);
    }
}
