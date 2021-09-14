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
                mom.ApplyTorque(hit.point, transform.right, Time.deltaTime);  
        }      
    }
}
