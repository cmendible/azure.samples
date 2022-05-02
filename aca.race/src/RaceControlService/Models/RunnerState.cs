namespace RaceControlService.Models;

public record struct RunnerState
{
    public int BibNumber { get; init; }
    public DateTime? StartTimestamp { get; init; }
    public DateTime? HalfTimestamp { get; init; }

    public DateTime? FinishTimestamp { get; init; }

    public RunnerState(int bibNumber, DateTime startTimestamp, DateTime? halfTimestamp = null, DateTime? finishTimestamp = null)
    {
        this.BibNumber = bibNumber;
        this.StartTimestamp = startTimestamp;
        this.HalfTimestamp = halfTimestamp;
        this.FinishTimestamp = finishTimestamp;
    }
}