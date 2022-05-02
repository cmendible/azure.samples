var daprClient = new DaprClientBuilder().Build();
int runnersCount = 500;
Runner[] runners = new Runner[runnersCount];
for (var i = 1; i <= runnersCount; i++)
{
    runners[i] = new Runner(i, daprClient);
}
Parallel.ForEach(runners, runner => runner.Start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();