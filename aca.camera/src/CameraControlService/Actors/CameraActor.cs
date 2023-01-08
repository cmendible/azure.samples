namespace CameraControlService.Actors;

public class CameraActor : Actor, ICameraActor, IRemindable
{
    private readonly DaprClient daprClient;

    public CameraActor(ActorHost host, DaprClient daprClient) : base(host)
    {
        this.daprClient = daprClient;
    }

    public async Task RegisterMotionAsync(CameraMotionDetected msg)
    {
        try
        {
            await UnregisterReminderAsync("CameraOffline");

            var cameraState = new CameraState(msg.CameraId, msg.Timestamp, msg.Timestamp);
            await this.StateManager.SetStateAsync("CameraState", cameraState);

            await RegisterReminderAsync("CameraOffline", null,
                TimeSpan.FromSeconds(120), TimeSpan.FromSeconds(120));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error in RegisterMotion");
        }
    }

    public async Task ReceiveReminderAsync(string reminderName, byte[] state, TimeSpan dueTime, TimeSpan period)
    {
        if (reminderName == "CameraOffline")
        {
            await UnregisterReminderAsync("CameraOffline");

            var cameraState = await this.StateManager.GetStateAsync<CameraState>("CameraState");

            Logger.LogInformation($"Camera with Id: {cameraState.CameraId} is offline");
        }
    }
}