using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;
using static UnityEngine.UI.Image;

public class SceneA_Script : MonoBehaviour
{
    GameObject orbitalCameraGO;
    GameObject firstPersonCameraGO;
    OrbitalCamera orbital; // should probably call it OrbitalCameraController?
    GameObject origin;
    GameObject currentCamera;

    void Start()
    {
        origin = new GameObject();
        origin.transform.position = new Vector3(0, 0, 0);

        Debug.Log("SceneA_Script::Start()");
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

        orbital.CenterOn(origin);
    }

    void SwapCameras()
    {
        orbitalCameraGO.SetActive( !orbitalCameraGO.activeInHierarchy );
        firstPersonCameraGO.SetActive( !firstPersonCameraGO.activeInHierarchy );
    }

    void Update() {
        orbital.Update(); // TODO: change so it calls the current camera controller's Update() instead

        if (Input.GetKeyDown(KeyCode.A)) {
            orbital.CenterOn(origin);
        }

        if (Input.GetKeyDown(KeyCode.S))
        {
            SwapCameras();
        }

        if (Input.GetMouseButtonDown(0)) {
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
    }
}
