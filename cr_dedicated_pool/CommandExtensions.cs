namespace NatyBuilder;

public static class Extensions
{
    public static void Run(this string fileName,
                           string? workingDir = null, params string[] arguments)
    {
        using (var p = new Process())
        {
            var args = p.StartInfo;
            args.UseShellExecute = false;
            args.RedirectStandardOutput = true;
            args.CreateNoWindow = true;
            args.FileName = fileName;
            if (workingDir != null) args.WorkingDirectory = workingDir;
            if (arguments != null && arguments.Any())
                args.Arguments = string.Join(" ", arguments).Trim();
            p.Start();
            while (!p.StandardOutput.EndOfStream)
            {
                Console.WriteLine(p.StandardOutput.ReadLine());
            }
        }
    }
}