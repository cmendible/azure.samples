public class Runner
{
    DaprClient daprClient;
    private Random rnd;
    private int bibNumber;
    private int minStartDelayInMS = 50;
    private int maxStartDelayInMS = 5000;
    private int minHalfDelayInS = 30;
    private int maxHalfDelayInS = 60;

    public Runner(int bibNumber, DaprClient daprClient)
    {
        rnd = new Random();
        this.bibNumber = bibNumber;
        this.daprClient = daprClient;
    }

    public Task Start()
    {
        while (true)
        {
            Console.WriteLine($"Starting simulation for runner: {bibNumber}");

            try
            {
                var startDelay = TimeSpan.FromMilliseconds(rnd.Next(minStartDelayInMS, maxStartDelayInMS) + rnd.NextDouble());
                Task.Delay(startDelay).Wait();

                Task.Run(async () =>
                {
                    Console.WriteLine($"Runner {bibNumber} started the race.");
                    var runnerRegistered = new RunnerRegistered
                    {
                        CheckPoint = CheckPoint.Start,
                        BibNumber = bibNumber,
                        Timestamp = DateTime.Now
                    };
                    await daprClient.PublishEventAsync("pubsub", "race-control", runnerRegistered);

                    var halfDelay = TimeSpan.FromSeconds(rnd.Next(minHalfDelayInS, maxHalfDelayInS) + rnd.NextDouble());
                    Task.Delay(halfDelay).Wait();
                    Console.WriteLine($"Runner {bibNumber} is half way.");
                    runnerRegistered = runnerRegistered with { CheckPoint = CheckPoint.HalfMarathon, Timestamp = DateTime.Now };
                    await daprClient.PublishEventAsync("pubsub", "race-control", runnerRegistered);

                    var finishDelay = TimeSpan.FromSeconds(rnd.Next(minHalfDelayInS, maxHalfDelayInS) + rnd.NextDouble());
                    Task.Delay(finishDelay).Wait();
                    Console.WriteLine($"Runner {bibNumber} is a finisher!!!");
                    runnerRegistered = runnerRegistered with { CheckPoint = CheckPoint.Marathon, Timestamp = DateTime.Now };
                    await daprClient.PublishEventAsync("pubsub", "race-control", runnerRegistered);

                }).Wait();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Runner {bibNumber} exception: {ex.Message}");
            }
            Console.WriteLine($"Finished simulation for runner: {bibNumber}.");
        }
    }
}