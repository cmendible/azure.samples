var daprClient = new DaprClientBuilder().Build();
var camerasCount = 1000;
var cameras = new Camera[camerasCount];
for (var i = 0; i < camerasCount; i++)
{
    var id = i + 1;
    cameras[i] = new Camera(id, daprClient);
}
Parallel.ForEach(cameras, camera => camera.Start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();