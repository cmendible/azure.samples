namespace RaceControlService.Actors;

public interface IRunnerActor : IActor
{
    public Task RegisterStartAsync(RunnerRegistered msg);
    public Task RegisterHalfAsync(RunnerRegistered msg);
    public Task RegisterFinisherAsync(RunnerRegistered msg);
}
