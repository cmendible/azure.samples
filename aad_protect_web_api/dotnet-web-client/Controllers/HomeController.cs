using System.Diagnostics;
using System.Net.Http.Headers;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Identity.Abstractions;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.Resource;
using sample.Models;

namespace sample.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private IDownstreamWebApi _downstreamApi;
    private const string ServiceName = "protected-api";

    public HomeController(ILogger<HomeController> logger, IDownstreamWebApi downstreamApi)
    {
        _logger = logger;
        _downstreamApi = downstreamApi;
    }

    public IActionResult Index()
    {
        return View();
    }

    [AuthorizeForScopes(ScopeKeySection = "DownstreamApi:Scopes")]
    public async Task<IActionResult> Privacy()
    {
        var value = await _downstreamApi.CallWebApiForUserAsync(
             ServiceName,
             options =>
             {
                 options.HttpMethod = HttpMethod.Get;
                 options.RelativePath = "protected";
             });

        value.EnsureSuccessStatusCode();

        Console.WriteLine(await value.Content.ReadAsStringAsync());

        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
