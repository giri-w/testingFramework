using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Xsl;

namespace Demcon.ReportGeneratorLibrary
{
    public class ReportGenerator : IDisposable
    {
        static readonly string GenericReportFilename = "{0} - Device Test Record - {1}.pdf";
        static readonly string ReportArchive = "Report Archive";
        static readonly string[] TestSequenceDirs = new string[] {
            "Achter manifold en balgrestrictie",
            "Voor manifold en aflaatrestrictie",
            "Balg assembly",
            "Nano Core tests"};

        /// <summary>
        /// The full path to the directory to generate the report in.
        /// </summary>
        public string Directory { get; private set; }

        /// <summary>
        /// The full path to the intermediate HTML file.
        /// Valid after Generate().
        /// The file will be deleted upon disposal of this instance.
        /// </summary>
        public string ReportHtml { get; private set; }

        /// <summary>
        /// The full path to the generated PDF report file.
        /// Valid after Generate().
        /// </summary>
        public string ReportPdf { get; private set; }

        /// <summary>
        /// The serial number, as retrieved from the directory path.
        /// </summary>
        public string SerialNr { get; private set; }

        /// <summary>
        /// The DWO/RMA number, used as subdirectory of the serial number directory.
        /// </summary>
        public string SubNr { get; private set; }

        /// <summary>
        /// The timestamp of the report generation.
        /// Valid after Generate().
        /// </summary>
        public DateTime Timestamp { get; private set; }

        /// <summary>
        /// Creates a ReportGenerator.
        /// </summary>
        /// <param name="directory">The path to the FNN.../DWO.../ directory, where the report will be generated. The directory must exist.</param>
        public ReportGenerator(string directory)
        {
            this.Directory = System.IO.Path.GetFullPath(directory);
            if (!System.IO.Directory.Exists(this.Directory))
                throw new System.IO.DirectoryNotFoundException();

            this.SubNr = System.IO.Path.GetFileName(this.Directory);
            if (this.SubNr == null)
                throw new System.ArgumentException("Path does not contain a proper DWO/RMA number");

            this.SerialNr = System.IO.Path.GetFileName(System.IO.Path.GetDirectoryName(this.Directory));
            if (this.SerialNr == null || !this.SerialNr.StartsWith("FNN"))
                throw new System.ArgumentException("Path does not contain a proper serial number");

        }

        ~ReportGenerator()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (this.ReportHtml != null)
            {
                try
                {
                    System.IO.File.Delete(this.ReportHtml);
                    this.ReportHtml = null;
                }
                catch { }
            }
        }

        /// <summary>
        /// Returns the filename of the last generated PDF report.
        /// </summary>
        /// <returns>null when no report has been found</returns>
        public string FindLatestReport()
        {
            string[] reports = System.IO.Directory.GetFiles(this.Directory, String.Format(GenericReportFilename, this.SerialNr, "*"));
            if (reports.Length != 1)
                return null;
            else
                return reports[1];
        }

        protected void ArchiveReports()
        {
            // check if an old report already exists
            string[] reports = System.IO.Directory.GetFiles(this.Directory, String.Format(GenericReportFilename, this.SerialNr, "*"));
            if (reports.Length > 0)
            {
                // create archive directory, if not exist already
                System.IO.Directory.CreateDirectory(System.IO.Path.Combine(this.Directory, ReportArchive));

                // move all reports to the archive
                foreach (string f in reports)
                {
                    System.IO.File.Move(f, System.IO.Path.Combine(this.Directory, ReportArchive, System.IO.Path.GetFileName(f)));
                }
            }

            Clean();
        }

        protected void Clean()
        {
            // delete any left-over html files
            string[] htmlFiles = System.IO.Directory.GetFiles(this.Directory, String.Format(System.IO.Path.GetFileNameWithoutExtension(GenericReportFilename) + ".html", "*", "*"));
            foreach (string f in htmlFiles)
            {
                try
                {
                    System.IO.File.Delete(f);
                }
                catch { }
            }
        }

        protected string[] GetTestReports()
        {
            List<string> reports = new List<string>();

            foreach (string d in TestSequenceDirs)
            {
                string dir = System.IO.Path.Combine(this.Directory, d);
                if (System.IO.Directory.Exists(dir))
                {
                    var sortedFiles = new System.IO.DirectoryInfo(dir).GetFiles().Where(fi => fi.Name.EndsWith(".xml")).OrderByDescending(f => f.Name).ToList();

                    if (sortedFiles.Count > 0)
                        reports.Add(sortedFiles[0].FullName);
                }
            }

            return reports.ToArray();
        }

        protected void WriteStringToXmlStream(System.IO.Stream stream, string s)
        {
            byte[] b = UnicodeEncoding.Unicode.GetBytes(s);
            stream.Write(b, 0, b.Length);
        }

        static protected string XmlAttributeEncode(string value)
        {
            return value.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("\"", "&quot;").Replace("'", "&apos;");
        }

        protected System.IO.Stream CombineTestReports(string[] testReports)
        {
            System.IO.MemoryStream stream = new System.IO.MemoryStream();
            WriteStringToXmlStream(stream, "<?xml version=\"1.0\" encoding=\"utf-16\"?>");
            WriteStringToXmlStream(stream, "<TestReport resources=\"" +
                XmlAttributeEncode(System.IO.Path.Combine(System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), "Report")) + "\" " +
                "path=\"" + XmlAttributeEncode(this.Directory) + "\" " +
                "serialNr=\"" + XmlAttributeEncode(this.SerialNr) + "\" subNr=\"" + this.SubNr + "\" "+
                "timestamp=\"" + XmlAttributeEncode(this.Timestamp.ToString("yyyy-MM-dd HH:mm:ss", System.Globalization.DateTimeFormatInfo.InvariantInfo)) + "\">");

            foreach(string r in testReports)
                using (System.Xml.XmlReader s = new System.Xml.XmlTextReader(r))
                {
                    WriteStringToXmlStream(stream, "<TestReportSection path=\"" + r + "\">");
                    s.MoveToContent();
                    WriteStringToXmlStream(stream, s.ReadOuterXml());
                    WriteStringToXmlStream(stream, "</TestReportSection>");
                }

            WriteStringToXmlStream(stream, "</TestReport>");
            stream.Seek(0, System.IO.SeekOrigin.Begin);
            return stream;
        }

        protected void ApplyXslt(System.IO.Stream xmlStream, string htmlFile)
        {
            XslCompiledTransform transform = new XslCompiledTransform();
            transform.Load(
                System.IO.Path.Combine(System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location),
                "report", "Report.xslt"));
            using (XmlReader reader = new XmlTextReader(xmlStream))
            {
                XmlWriterSettings settings = new XmlWriterSettings();
                settings.Indent = true;
                settings.Encoding = Encoding.Unicode;
                using (XmlWriter writer = XmlWriter.Create(htmlFile, settings))
                {
                    transform.Transform(reader, writer);
                }
            }
        }

        protected void ConvertToPdf(string htmlFile, string pdfFile)
        {
            string wkhtmltopdf = System.IO.Path.Combine(System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location),
                "dep", "wkhtmltopdf.exe");

            System.Diagnostics.Process p = new System.Diagnostics.Process();
            p.StartInfo.UseShellExecute = false;
            p.StartInfo.RedirectStandardOutput = false;
            p.StartInfo.RedirectStandardError = true;
            p.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            p.StartInfo.CreateNoWindow = true;
            p.StartInfo.FileName = wkhtmltopdf;
            p.StartInfo.Arguments = "--print-media-type -B 20 -L 20 -R 20 -T 20 --header-html \"" + 
                System.IO.Path.Combine(System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), "report", "ReportHeader.html") +
                "\" --header-spacing 10 --replace timestamp \"" +
                XmlAttributeEncode(this.Timestamp.ToString("yyyy-MM-dd HH:mm:ss", System.Globalization.DateTimeFormatInfo.InvariantInfo)) +
                "\" \"" + htmlFile + "\" \"" + pdfFile + "\"";
            p.Start();

            string output = p.StandardError.ReadToEnd();
            p.WaitForExit();
            if (p.ExitCode != 0)
                throw new System.Exception("Cannot convert HTML file to PDF: " + output);
        }

        /// <summary>
        /// Generate the PDF report.
        /// </summary>
        public void Generate()
        {
            // Max 10 tries to generate a filename, then just continue and generate the report
            for (int i = 0; i < 10; i++)
            {
                this.Timestamp = DateTime.Now;
                string timestamp = this.Timestamp.ToString("yyyy-MM-dd HH.mm.ss", System.Globalization.DateTimeFormatInfo.InvariantInfo);
                this.ReportPdf = System.IO.Path.Combine(this.Directory, String.Format(GenericReportFilename, this.SerialNr, timestamp));
                this.ReportHtml = System.IO.Path.Combine(this.Directory, System.IO.Path.GetFileNameWithoutExtension(this.ReportPdf) + ".html");

                if (!System.IO.File.Exists(this.ReportPdf))
                    // ok, use this filename; it's unique
                    break;

                // Generating another report within the same second... Sleep and try again.
                System.Threading.Thread.Sleep(2000);
            }

            ArchiveReports();

            using (System.IO.Stream xmlStream = CombineTestReports(GetTestReports()))
                ApplyXslt(xmlStream, this.ReportHtml);

            ConvertToPdf(this.ReportHtml, this.ReportPdf);
        }
    }
}
