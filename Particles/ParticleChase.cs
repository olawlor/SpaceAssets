/*
 Add to a particle system to make particles that chase a target point.
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleChase : MonoBehaviour
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
            float blend = 0.5f * Time.deltaTime;
            particles[i].position = blend*targetPoint + (1.0f-blend)*particles[i].position;
        }
        system.SetParticles(particles,n);
        Debug.Log("Updated "+n+" particles");
    }
}
