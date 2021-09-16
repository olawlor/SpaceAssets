/*
 Fire laser down the +X axis, if it hits something with a
 MomentumSpinner attached, apply torque and emit a red particle effect.
*/
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FireLaser : MonoBehaviour
{

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
        RaycastHit hit;
        if (!Physics.Raycast(
            transform.position,
            transform.right,out hit)) return; // missed us
        
        Collider c = hit.collider;
        GameObject obj = c.gameObject;
        MomentumSpinner mom = obj.GetComponent<MomentumSpinner>();
        if (mom) {
            Vector3 direction=transform.right;
            mom.ApplyTorque(hit.point, direction, Time.deltaTime);  
            Vector3 flyDir=hit.normal; // fly out of the surface
            flyDir+=Random.insideUnitSphere*0.3f; // spray shrapnel around some
            EmitParticle.Now(hit.point,flyDir*10.0f,new Color(1.0f,0.3f,0.2f,1.0f));
            //Debug.Log(hit.point);
        }  else {
            //Debug.Log("Laser hit an unknown object type"+obj);
        }
    }
}
