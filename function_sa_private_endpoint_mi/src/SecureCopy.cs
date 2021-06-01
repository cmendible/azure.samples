using System.IO;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace Secured.Function
{
    public static class SecureCopy
    {
        [FunctionName("SecureCopy")]
        public static void Run(
        [BlobTrigger("input/{name}", Connection = "privatecfm_STORAGE")] Stream myBlob,
        [Blob("output/{name}", FileAccess.Write, Connection = "privatecfm_STORAGE")] Stream copy,
        ILogger log)
        {
            myBlob.CopyTo(copy);
        }
    }
}
