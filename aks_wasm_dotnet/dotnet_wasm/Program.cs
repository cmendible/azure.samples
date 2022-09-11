using System.Runtime.InteropServices;

Console.WriteLine($"Content-Type: text/html");
Console.WriteLine();
Console.WriteLine($"<head><title>Hello from C#</title></head>");
Console.WriteLine($"<body>");
Console.WriteLine($"<h1>Hello from C#</h1>");
Console.WriteLine($"<p>Current time (UTC): {DateTime.UtcNow.ToLongTimeString()}</p>");
Console.WriteLine($"<p>Current architecture: {RuntimeInformation.OSArchitecture}</p>");
Console.WriteLine($"</body>");