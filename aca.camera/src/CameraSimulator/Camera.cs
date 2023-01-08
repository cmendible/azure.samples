public class Camera
{
    DaprClient daprClient;
    private Random rnd;
    private int cameraId;
    private int minStartDelayInMS = 50;
    private int maxStartDelayInMS = 100;
    private int minHalfDelayInS = 30;
    private int maxHalfDelayInS = 60;

    public Camera(int cameraId, DaprClient daprClient)
    {
        rnd = new Random();
        this.cameraId = cameraId;
        this.daprClient = daprClient;                                                                                                                                                                                                                                                                 
    }

    public Task Start()
    {
        while (true)
        {
            Console.WriteLine($"Starting simulation for camera: {cameraId}");

            try
            {
                var startDelay = TimeSpan.FromMilliseconds(rnd.Next(minStartDelayInMS, maxStartDelayInMS) + rnd.NextDouble());
                Task.Delay(startDelay).Wait();

                Task.Run(async () =>
                {
                    Console.WriteLine($"Motione detected on Camera: {cameraId}");
                    var cameraMotionDetected = new CameraMotionDetected
                    {
                        CameraId = cameraId,
                        Timestamp = DateTime.Now
                    };
                    await daprClient.PublishEventAsync("pubsub", "camera-control", cameraMotionDetected);

                    var halfDelay = TimeSpan.FromSeconds(rnd.Next(minHalfDelayInS, maxHalfDelayInS) + rnd.NextDouble());
                    Task.Delay(halfDelay).Wait();
                    Console.WriteLine($"Motione detected on Camera: {cameraId}");
                    cameraMotionDetected = cameraMotionDetected with { Timestamp = DateTime.Now };
                    await daprClient.PublishEventAsync("pubsub", "camera-control", cameraMotionDetected);

                    var finishDelay = TimeSpan.FromSeconds(rnd.Next(minHalfDelayInS, maxHalfDelayInS) + rnd.NextDouble());
                    Task.Delay(finishDelay).Wait();
                    Console.WriteLine($"Motione detected on Camera: {cameraId}");
                    cameraMotionDetected = cameraMotionDetected with { Timestamp = DateTime.Now };
                    await daprClient.PublishEventAsync("pubsub", "camera-control", cameraMotionDetected);

                }).Wait();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Camera {cameraId} exception: {ex.Message}");
            }
            Console.WriteLine($"Finished simulation for camera: {cameraId}.");
        }
    }
}