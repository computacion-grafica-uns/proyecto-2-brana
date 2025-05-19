using UnityEngine;

public class FirstPersonCamera
{

}

public class OrbitalCamera
{
    Vector3 rotation; // store a V3 of Euler angles
    public Vector3 cameraPosition => lookAt + distanceFromTarget * forward;

    GameObject camera;

    Vector3 lookAt;
    Vector3 forward;
    Vector3 up;
    Vector3 right;

    float distanceFromTarget;

    float degree = 1.0f;

    public OrbitalCamera(GameObject camera, Vector3 pos, Vector3 lookAt, Vector3 up)
    {

        forward = (pos - lookAt).normalized;
        distanceFromTarget = (pos - lookAt).magnitude;
        right = Vector3.Cross(forward, up); // right, or left?
        this.up = up;
        this.lookAt = lookAt;

        this.camera = camera;
        camera.transform.LookAt(lookAt);
    }

    float positionLerpFactor;
    bool lerping = false;
    Vector3 targetPosToLerpTo;
    Vector3 startingLerpPos;
    Vector3 startingLookAt, targetLookAt;
    public void CenterOn(GameObject obj)
    {
        startingLerpPos = lookAt + distanceFromTarget * forward; // the camera's forward will be -forward, then?

        targetPosToLerpTo = obj.transform.position + distanceFromTarget * this.forward; // now recomputed with the new lookAt center
        Debug.Log("Lerping from " + startingLerpPos + " to " + targetPosToLerpTo);
        positionLerpFactor = 0.0f;
        lerping = true;

        startingLookAt = lookAt;
        targetLookAt = obj.transform.position;
        // this.lookAt = obj.transform.position;
    }

    // TODO: Clip distanceFromTarget to 0.0f+ range
    float lerpSpeed = 1.0f;
    float shiftFactor = 1.0f; // when shift is pressed
    float zoomSpeed = 4.0f;
    public void Update()
    {
        // handle input
        // This is something important to think about - in games, there's always something like a hierarchy.
        // Input comes from the OS - where do we handle it? Is it fine to let any object ask for KeyDown/KeyUp state,
        // or should it receive exactly what it needs and no more? Maybe it's more flexible to do this, but it's just
        // modulo ergonomic improvements, so there could be extra code added to make the rigid approach more flexible.
        // it's more a question of organization. I guess in a bigger team, what components needs which input might be
        // interesting to specify, or programmatically extract from the values we read from Input or from the OS
        // event loop. SDL does keycode arrays, but it's the same problem. Check OSS games to see what they do
        if (Input.GetKey(KeyCode.O)) { distanceFromTarget += shiftFactor * zoomSpeed * Time.deltaTime; this.camera.transform.position = cameraPosition; } // this will get in the way with interpolation
        if (Input.GetKey(KeyCode.P)) { distanceFromTarget -= shiftFactor * zoomSpeed * Time.deltaTime; this.camera.transform.position = cameraPosition; } // this will get in the way with interpolation

        if (Input.GetKeyDown(KeyCode.LeftShift)) { shiftFactor = 0.5f; } // TODO: Test better factors - 0.1f is too slow
        if (Input.GetKeyUp(KeyCode.LeftShift)) { shiftFactor = 1.0f; }

        // this.camera.transform.position = cameraPosition;
        if (lerping)
        {
            this.camera.transform.position = Vector3.Lerp(startingLerpPos, targetPosToLerpTo, positionLerpFactor);
            positionLerpFactor += lerpSpeed * Time.deltaTime; // lerpSpeed units per second?

            // same factor, but relative distances change e.g. it could move my camera a short distance, but the two lookAts may be far away
            this.lookAt = Vector3.Lerp(startingLookAt, targetLookAt, positionLerpFactor);
            camera.transform.LookAt(this.lookAt);

            if (positionLerpFactor >= 1.0f)
            {
                lerping = false;
            }
            Debug.LogWarning(positionLerpFactor);

            Debug.DrawLine(startingLerpPos, targetPosToLerpTo, Color.red, 1.0f);
            Debug.DrawLine(cameraPosition, lookAt, Color.red, 1.0f);
        }

        // this.forward = rotateAround(this.forward, degree * Time.deltaTime, this.up);
        // camera.transform.LookAt(lookAt);
    }

    private Vector3 rotateAround(Vector3 V, float angleInRadians, Vector3 rotationAxis)
    {
        Vector3 K = rotationAxis;
        // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
        Vector3 rotatedV = V * Mathf.Cos(angleInRadians)
                     + (Vector3.Cross(K, V) * Mathf.Sin(angleInRadians))
                     + K * (Vector3.Dot(K, V) * (1 - Mathf.Cos(angleInRadians)));
        return rotatedV;
    }


}
