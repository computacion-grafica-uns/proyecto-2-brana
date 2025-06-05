using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;
using static UnityEngine.UI.Image;
using System.Collections.Generic;

public class SceneB_script : MonoBehaviour
{
    GameObject orbitalCameraGO;
    GameObject firstPersonCameraGO;
    OrbitalCamera orbital; // should probably call it OrbitalCameraController?
    GameObject fullViewPoint;
    GameObject currentCamera;

    GameObject pointLight, directionalLight;
    GameObject[] mainObjects;
    List<Material> sceneMaterials;
    int focusedObject = 0;

    void Start()
    {
        fullViewPoint = new GameObject("Orbital Camera - full scene view point");
        fullViewPoint.transform.position = new Vector3(4, 2, 0);

        GameObject center = new GameObject("Scene Center");
        center.transform.position = new Vector3(1, 0, 0);

        Debug.Log("SceneB_Script::Start()");
        orbitalCameraGO = GameObject.Find("OrbitalCamera");
        firstPersonCameraGO = GameObject.Find("FPSCamera");
        orbitalCameraGO.SetActive(true);
        firstPersonCameraGO.SetActive(false);
        currentCamera = orbitalCameraGO;

        currentCamera.transform.position = new Vector3(15, 6, -4);
        orbital = new OrbitalCamera(orbitalCameraGO, center.transform);

        GameObject[] sceneObjects = UnityEngine.Object.FindObjectsOfType<GameObject>();
        Debug.Log("[Scene B] " + sceneObjects.Length + " Scene Objects: " + sceneObjects);
        sceneMaterials = new List<Material>();
        foreach (GameObject go in sceneObjects)
        {
            if (go.activeInHierarchy && go.GetComponent<MeshRenderer>() != null && go.GetComponent<MeshRenderer>().material != null)
            {
                Debug.Log("Found " + go.GetComponent<MeshRenderer>().material);
                sceneMaterials.Add(go.GetComponent<MeshRenderer>().material);
            }
        }

        mainObjects = GameObject.FindGameObjectsWithTag("SceneObject");
        pointLight = GameObject.FindGameObjectsWithTag("ScenePointLight")[0];
        directionalLight = GameObject.FindGameObjectsWithTag("SceneDirectionalLight")[0];

        mannequinArm = GameObject.FindGameObjectsWithTag("ForearmArmature")[0];
    }

    GameObject mannequinArm;

    void SwapCameras()
    {
        orbitalCameraGO.SetActive(!orbitalCameraGO.activeInHierarchy);
        firstPersonCameraGO.SetActive(!firstPersonCameraGO.activeInHierarchy);
    }

    void SwitchFocus()
    {
        if (mainObjects.Length > 0) { // there has to be at least one
            orbital.CenterOn(mainObjects[focusedObject]);
            focusedObject++;
            if (focusedObject >= mainObjects.Length) { focusedObject = 0; }
        }
    }

    void Update()
    {
        orbital.Update(); // TODO: change so it calls the current camera controller's Update() instead

        if (Input.GetKeyDown(KeyCode.F))
        {
            SwitchFocus();
        }

        if (Input.GetKeyDown(KeyCode.Q))
        {
            SwitchScenes();
        }

        if (Input.GetKeyDown(KeyCode.R))
        {
            orbital.CenterOn(fullViewPoint);
        }

        if (Input.GetKeyDown(KeyCode.E))
        {
            SwapCameras();
        }

        /*
        // 1,2,3 to disable and enable each light
        if (Input.GetKeyDown(KeyCode.1)) {
            foreach (Material mat in sceneMaterials)
            {
                mat.Set...
            }
        }
        */

        if (Input.GetMouseButtonDown(0))
        {
            RaycastHit hit;
            Camera c = currentCamera.GetComponent<Camera>();
            Ray ray = c.ScreenPointToRay(Input.mousePosition);
            // Debug.Log(ray);

            bool didHit = Physics.Raycast(ray, out hit);
            if (didHit)
            {
                GameObject hitObject = hit.collider.gameObject;
                Debug.Log("Hit " + hitObject.name);
                orbital.CenterOn(hitObject);
                // hitObject.transform.localScale = hitObject.transform.localScale + new Vector3(0.1f, 0.1f, 0.1f);
            }
        }

        foreach (Material mat in sceneMaterials)
        {
            // all materials will have
            // * _PointLightPos, _PointLightColor
            // * _DirectionalLightDir, _DirectionalLightColor
            // * _SpotLightPos, _SpotLightDirection, _SpotLightColor
            // I can disable them by setting _*Color to (0,0,0,0) or moving them really far away

            mat.SetVector("_DirectionalLightDir", -directionalLight.transform.position); // vector from its position to the origin
            mat.SetVector("_PointLightPos", pointLight.transform.position);

            // Make the camera hold a flashlight
            mat.SetVector("_SpotLightPos", currentCamera.transform.position);
            mat.SetVector("_SpotLightDirection", currentCamera.transform.forward.normalized);
            mat.SetVector("_CameraPos", currentCamera.transform.position);
        }

        mannequinArm.transform.rotation = Quaternion.Slerp(armTo, armFrom, armT);
        armT += dir * Time.deltaTime;
        if (armT > 1.0f || armT < 0.0f) { dir *= -1; }
        Debug.LogWarning(armT);

    }

    Quaternion armTo = new Quaternion(-0.0249267649f, -0.0938767791f, 0.00675223535f, 0.995248795f);
    Quaternion armFrom = new Quaternion(0.0544426553f, -0.0222741198f, -0.0790993497f, 0.995129704f);
    float armT = 0.0f;
    float dir = 1.0f;

    void SwitchScenes()
    {
        SceneManager.UnloadSceneAsync("SceneB");
        SceneManager.LoadScene("SceneA");
    }
}
