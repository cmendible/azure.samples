namespace RaceSimulator.Events;

public record struct RunnerRegistered(int BibNumber, CheckPoint CheckPoint, DateTime Timestamp);

public enum CheckPoint { 
    Start,
    HalfMarathon,
    Marathon
}

