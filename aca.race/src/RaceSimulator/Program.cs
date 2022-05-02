var daprClient = new DaprClientBuilder().Build();
var runnersCount = 50;
var runners = new Runner[runnersCount];
for (var i = 0; i < runnersCount; i++)
{
    var bibNumber = i + 1;
    runners[i] = new Runner(bibNumber, daprClient);
}
Parallel.ForEach(runners, runner => runner.Start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();