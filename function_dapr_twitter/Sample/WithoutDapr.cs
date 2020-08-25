namespace Function.SampleCoupledToAzure
{
    using Microsoft.Azure.WebJobs;
    using Microsoft.Extensions.Logging;

    public class MyPoco
    {
        public MyPoco() { }

        public string PartitionKey { get; set; }

        public string RowKey { get; set; }

        public string Text { get; set; }
    }

    public class QueueTriggerTableInput
    {
        [FunctionName("QueueTrigger_TableInput")]
        public void Run(
          [QueueTrigger("table-items")] string input,
          [Table("MyTable", "MyPartition", "{queueTrigger}")] MyPoco poco,
          ILogger log)
        {
            log.LogInformation($"PK={poco.PartitionKey}, RK={poco.RowKey}, Text={poco.Text}");
        }
    }
}