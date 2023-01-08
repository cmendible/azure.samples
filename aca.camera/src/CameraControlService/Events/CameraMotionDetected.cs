namespace CameraControlService.Events;

public record struct CameraMotionDetected(int CameraId, DateTime Timestamp);
