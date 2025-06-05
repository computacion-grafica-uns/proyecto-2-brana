using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;
using static UnityEngine.UI.Image;
using System.Collections.Generic;

// TODO: remove fps camera - Scene A doesn't need it
public class SceneA_Script : MonoBehaviour
{
    GameObject orbitalCameraGO;
    GameObject firstPersonCameraGO;
    OrbitalCamera orbital; // should probably call it OrbitalCameraController?
    GameObject fullViewPoint;
    GameObject currentCamera;

    void Start()
    {
        fullViewPoint = new GameObject("Orbital Camera - full scene view point");
        fullViewPoint.transform.position = new Vector3(4, 2, 0);

        GameObject center = new GameObject("Scene Center");
        center.transform.position = new Vector3(1, 0, 0);

        Debug.Log("SceneA_Script::Start()");
        orbitalCameraGO = GameObject.Find("OrbitalCamera");
        firstPersonCameraGO = GameObject.Find("FPSCamera");
        orbitalCameraGO.SetActive(true);
        firstPersonCameraGO.SetActive(false);
        currentCamera = orbitalCameraGO;


        currentCamera.transform.position = new Vector3(4, 2, 0); 
        orbital = new OrbitalCamera(orbitalCameraGO, center.transform);

        /* currentCamera.transform.position = new Vector3(4, 2, 0);
        Debug.Log("Pre: " + currentCamera.transform.up);
        currentCamera.transform.LookAt(new Vector3(1,0,0));
        Debug.Log("Pos: " + currentCamera.transform.up); */

        // GameObject[] sceneObjects = SceneManager.GetActiveScene().GetRootGameObjects();
        GameObject[] sceneObjects = UnityEngine.Object.FindObjectsOfType<GameObject>();
        Debug.Log(sceneObjects.Length + " Scene Objects: " + sceneObjects);
        sceneMaterials = new List<Material>();
        foreach(GameObject go in sceneObjects) {
            if (go.activeInHierarchy && go.GetComponent<MeshRenderer>() != null && go.GetComponent<MeshRenderer>().material != null) {
                Debug.Log("Found " + go.GetComponent<MeshRenderer>().material);
                sceneMaterials.Add(go.GetComponent<MeshRenderer>().material);
            }
        }
        
    }

    List<Material> sceneMaterials;

    void SwapCameras()
    {
        orbitalCameraGO.SetActive( !orbitalCameraGO.activeInHierarchy );
        firstPersonCameraGO.SetActive( !firstPersonCameraGO.activeInHierarchy );
    }

    void Update() {
        orbital.Update(); // TODO: change so it calls the current camera controller's Update() instead

        if (Input.GetKeyDown(KeyCode.Q)) {
            SwitchScenes();
        }

        if (Input.GetKeyDown(KeyCode.R)) {
            orbital.CenterOn(fullViewPoint);
        }

        if (Input.GetKeyDown(KeyCode.E)) {
            SwapCameras();
        }

        if (Input.GetMouseButtonDown(0)) {
            RaycastHit hit;
            Camera c = currentCamera.GetComponent<Camera>();
            Ray ray = c.ScreenPointToRay(Input.mousePosition);
            // Debug.Log(ray);

            bool didHit = Physics.Raycast(ray, out hit);
            if (didHit) {
                GameObject hitObject = hit.collider.gameObject;
                Debug.Log("Hit " + hitObject.name);
                orbital.CenterOn(hitObject);
                hitObject.transform.localScale = hitObject.transform.localScale + new Vector3(0.1f, 0.1f, 0.1f);
            }
        }

        foreach(Material mat in sceneMaterials) {
            // all materials will have
            // * _PointLightPos, _PointLightColor
            // * _DirectionalLightDir, _DirectionalLightColor
            // * _SpotLightPos, _SpotLightDirection, _SpotLightColor
            // I can disable them by setting _*Color to (0,0,0,0) or moving them really far away

            mat.SetVector("_SpotLightPos", currentCamera.transform.position);
            mat.SetVector("_SpotLightDirection", currentCamera.transform.forward.normalized); // for example
            mat.SetVector("_CameraPos", currentCamera.transform.position);
        }
    }

    void SwitchScenes()
    {
        SceneManager.UnloadSceneAsync("SceneA");
        SceneManager.LoadScene("SceneB");
    }
}
