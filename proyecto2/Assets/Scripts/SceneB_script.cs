using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;
using static UnityEngine.UI.Image;

public class SceneB_Script : MonoBehaviour
{
    // TODO: tag all new objects with SceneObject
    // Then, the requirement of centering the camera on all objects can be done
    // either by rays on MeshColliders
    // or by iterating on each SceneObject-tagged GameObject and centering the camera on it

    GameObject orbitalCameraGO;
    GameObject firstPersonCameraGO;
    OrbitalCamera orbital;
    // FirstPersonCamera fpsController;

    GameObject fullViewPoint;
    GameObject currentCamera;

    void Start()
    {
        fullViewPoint = new GameObject("Orbital Camera - full scene view point");
        fullViewPoint.transform.position = new Vector3(4, 2, 0);

        Debug.Log("SceneB_Script::Start()");
        orbitalCameraGO = GameObject.Find("OrbitalCamera");
        firstPersonCameraGO = GameObject.Find("FPSCamera");
        orbitalCameraGO.SetActive(true);
        firstPersonCameraGO.SetActive(false);
        currentCamera = orbitalCameraGO;

        Vector3 right = new Vector3(0, 0, -1);
        Vector3 pos = new Vector3(3, 4, 0);
        Vector3 lookAt = Vector3.zero;
        Vector3 forward = lookAt - pos;
        orbital = new OrbitalCamera(orbitalCameraGO, pos, lookAt, Vector3.Cross(forward, right));

        orbital.CenterOn(fullViewPoint);
    }

    void SwapCameras()
    {
        orbitalCameraGO.SetActive(!orbitalCameraGO.activeInHierarchy);
        firstPersonCameraGO.SetActive(!firstPersonCameraGO.activeInHierarchy);
    }

    void Update()
    {
        orbital.Update(); // TODO: change so it calls the current camera controller's Update() instead

        if (Input.GetKeyDown(KeyCode.A))
        {
            orbital.CenterOn(fullViewPoint);
        }

        if (Input.GetKeyDown(KeyCode.S))
        {
            SwapCameras();
        }

        /*
        if (Input.GetMouseButtonDown(0))
        {
            RaycastHit hit;
            Camera c = currentCamera.GetComponent<Camera>();
            Ray ray = c.ScreenPointToRay(Input.mousePosition);
            // Debug.Log(ray);

            bool b = Physics.Raycast(ray, out hit);
            if (b)
            {
                GameObject hitObject = hit.collider.gameObject;
                Debug.Log("Hit " + hitObject.name);
                orbital.CenterOn(hitObject);
                hitObject.transform.localScale = new Vector3(0.3f, 0.3f, 0.3f);
            }
        }
        */
    }
}
