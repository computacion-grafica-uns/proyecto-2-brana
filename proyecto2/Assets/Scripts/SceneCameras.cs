using Unity.VisualScripting.FullSerializer;
using UnityEngine;

public class FirstPersonCamera
{
}

public class OrbitalCamera
{
    GameObject camera;
    float distanceFromTarget;
    Transform target;

    Vector3 right; // store?
    Vector3 up; // store?

    private Vector3 forward => (camera.transform.position - target.position).normalized;
    private Vector3 cameraPosition => target.position + distanceFromTarget * forward;

    // we only need to yaw
    public OrbitalCamera(GameObject camera, Transform target)
    {
        // when we enter, the camera's position is set
        this.camera = camera;
        this.target = target;
        this.camera.transform.LookAt(target);
        // now the camera's up and forward are set

        Debug.LogWarning("Cam pos: " + camera.transform.position);
        Debug.LogWarning("Target pos: " + target.position);

        // this.transform instead is this.camera.transform always
        // Vector3 fwd = (camera.transform.position - target.position).normalized;
        distanceFromTarget = Vector3.Distance(camera.transform.position, target.position); // this.distanceFromTarget = (camera.transform.position - target.position).magnitude;
        Debug.LogWarning("Initial distance: " + distanceFromTarget);
        this.right = -camera.transform.right; // does it matter? it does, for yaw
        // for yaw, up is the same as the camera up
        // right is -cam.right
        // because the rotation of forward and right around up is of the vectors coming out of target
        // then we recompute the camera pos from the formula

        /*
        Debug.Log(camera.transform.position);
        Debug.Log(target.position + distanceFromTarget * forward);
        if ((camera.transform.position - (target.position + distanceFromTarget * forward)).magnitude < Vector3.kEpsilon)
        {
            Debug.Log("Close enough");
        }
        */

        Debug.DrawLine(this.target.position, cameraPosition, Color.red, 5.0f);

    }

    public void CenterOn(GameObject obj) { CenterOn(obj.transform); }
    
    public void CenterOn(Transform t)
    {
        Debug.DrawLine(this.target.position, t.position, Color.blue, 5.0f);
        this.target = t;
        camera.transform.position = cameraPosition;
        // Vector3 posOnNewSphere = t.position - distanceFromTarget * (t.position - camera.transform.position).normalized;
        // camera.transform.position = posOnNewSphere;
        camera.transform.LookAt(t);
    }

    float shiftFactor = 1.0f; // when shift is pressed
    float zoomSpeed = 4.0f; // units per second
    float yawSpeed = 2.0f; // degrees per second
    public void Update()
    {
       Debug.DrawLine(this.target.position, cameraPosition, Color.red);
       if (Input.GetKey(KeyCode.O)) {
            distanceFromTarget += shiftFactor * zoomSpeed * Time.deltaTime;
            this.camera.transform.position = cameraPosition;
       }
       if (Input.GetKey(KeyCode.P)) { 
           distanceFromTarget -= shiftFactor * zoomSpeed * Time.deltaTime;
           this.camera.transform.position = cameraPosition;
       }

        if (Input.GetKey(KeyCode.A))
        {
            Yaw(yawSpeed * shiftFactor * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.D))
        {
            Yaw(-yawSpeed * shiftFactor * Time.deltaTime);
        }

        if (Input.GetKey(KeyCode.W))
        {
            Pitch(-yawSpeed * shiftFactor * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.S))
        {
            Pitch(yawSpeed * shiftFactor * Time.deltaTime);
        }

        if (Input.GetKeyDown(KeyCode.LeftShift)) { shiftFactor = 0.5f; }
       if (Input.GetKeyUp(KeyCode.LeftShift)) { shiftFactor = 1.0f; }
    }

    public void Pitch(float deg)
    {
        // rotate up and forward around right
        Vector3 currentForward = forward;
        Vector3 currentRight = -camera.transform.right;
        Vector3 currentUp = camera.transform.up;

        Vector3 newFwd = rotateAround(currentForward, deg, currentRight);
        Vector3 newUp = rotateAround(currentUp, deg, currentRight);
        camera.transform.up = newUp;
        camera.transform.position = target.position + distanceFromTarget * newFwd;
        camera.transform.LookAt(target); // wonder if it'll conflict with the computed newUp

    }

    public void Yaw(float deg)
    {
        Vector3 currentForward = forward;
        Vector3 newForward = rotateAround(currentForward, deg, camera.transform.up);
        Vector3 currentRight = -camera.transform.right;
        Vector3 newRight = rotateAround(currentRight, deg, camera.transform.up);

        Vector3 newCameraPos = target.position + distanceFromTarget * newForward;
        this.camera.transform.position = newCameraPos;
        // this.camera.transform.right = newRight;
        // maybe ignore right and so on, and call LookAt
        camera.transform.LookAt(target.position);
    }

    private Vector3 rotateAround(Vector3 V, float angleInRadians, Vector3 rotationAxis) {
        Vector3 K = rotationAxis;
        // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
        Vector3 rotatedV = V * Mathf.Cos(angleInRadians)
                     + (Vector3.Cross(K, V) * Mathf.Sin(angleInRadians))
                     + K * (Vector3.Dot(K, V) * (1 - Mathf.Cos(angleInRadians)));
        return rotatedV;
    }
}
