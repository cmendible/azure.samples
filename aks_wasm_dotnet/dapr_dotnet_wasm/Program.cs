using WapcGuest;

namespace dapr_dotnet_wasm
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var wapc = new Wapc();
            wapc.RegisterFunction("rewrite", rewrite);
        }

        static byte[] rewrite(byte[] payload)
        {
            // Echo the payload back to the caller
            return payload;
        }
    }
}