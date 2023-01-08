namespace CameraControlService.Actors;

public interface ICameraActor : IActor
{
    public Task RegisterMotionAsync(CameraMotionDetected msg);
}
