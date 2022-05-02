namespace RaceControlService.Actors;

public class RunnerActor : Actor, IRunnerActor, IRemindable
{
    private readonly DaprClient daprClient;

    public RunnerActor(ActorHost host, DaprClient daprClient) : base(host)
    {
        this.daprClient = daprClient;
    }

    public async Task RegisterStartAsync(RunnerRegistered msg)
    {
        try
        {
            var runnerState = new RunnerState(msg.BibNumber, msg.Timestamp);
            await this.StateManager.SetStateAsync("RunnerState", runnerState);

            await RegisterReminderAsync("RunnerDidNotFinish", null,
                TimeSpan.FromSeconds(120), TimeSpan.FromSeconds(120));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error in RegisterStart");
        }
    }

    public async Task RegisterHalfAsync(RunnerRegistered msg)
    {
        try
        {
            var runnerState = await this.StateManager.GetStateAsync<RunnerState>("RunnerState");
            runnerState = runnerState with { HalfTimestamp = msg.Timestamp };
            await this.StateManager.SetStateAsync("RunnerState", runnerState);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error in RegisterHalf");
        }
    }

    public async Task RegisterFinisherAsync(RunnerRegistered msg)
    {
        try
        {
            await UnregisterReminderAsync("RunnerDidNotFinish");

            var runnerState = await this.StateManager.GetStateAsync<RunnerState>("RunnerState");
            runnerState = runnerState with { FinishTimestamp = msg.Timestamp };
            await this.StateManager.SetStateAsync("RunnerState", runnerState);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error in RegisterFinish");
        }
    }

    public async Task ReceiveReminderAsync(string reminderName, byte[] state, TimeSpan dueTime, TimeSpan period)
    {
        if (reminderName == "RunnerDidNotFinish")
        {
            await UnregisterReminderAsync("RunnerDidNotFinish");

            var runnerState = await this.StateManager.GetStateAsync<RunnerState>("RunnerState");

            Logger.LogInformation($"Runner with bib number: {runnerState.BibNumber} did not finish the race.");
        }
    }
}