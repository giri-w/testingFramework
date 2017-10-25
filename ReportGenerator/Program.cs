using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ReportGenerator
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length != 1 || args[0] == "-?" || args[0] == "--help" || args[0] == "-h" || args[0] == "/?" )
            {
                System.Console.WriteLine("Usage: " + System.AppDomain.CurrentDomain.FriendlyName + " <SN\\DWO directory>");
                Environment.Exit(1);
            }
            else
            {
                try
                {
                    Demcon.ReportGeneratorLibrary.ReportGenerator r = new Demcon.ReportGeneratorLibrary.ReportGenerator(args[0]);
                    r.Generate();
                }
                catch(Exception ex)
                {
                    System.Console.WriteLine("Generating report failed: " + ex.Message);
                    Environment.Exit(2);
                }
            }
        }
    }
}
