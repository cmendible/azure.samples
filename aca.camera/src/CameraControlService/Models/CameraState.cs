namespace CameraControlService.Models;

public record struct CameraState
{
    public int CameraId { get; init; }
    public DateTime? LastSeenAt { get; init; }
    public DateTime? MotionDetectedAt { get; init; }

    public CameraState(int cameraId, DateTime? lastSeenAt, DateTime? motionDetectedAt = null)
    {
        this.CameraId = cameraId;
        this.LastSeenAt = lastSeenAt;
        this.MotionDetectedAt = motionDetectedAt;
    }
}