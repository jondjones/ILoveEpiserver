namespace DatabaseSetup
{
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Reflection;

    using DbUp;
    using DbUp.Helpers;

    using Microsoft.SqlServer.Management.Common;
    using Microsoft.SqlServer.Management.Smo;

    class Program
    {
        static void Main(string[] args)
        {
            var sqlServerName = @".\SQLEXPRESS";
            var databaseName = @"Epi";
            var connectionString = $@"Data Source={sqlServerName};Initial Catalog={databaseName};Integrated Security=False;User ID=USERNAME;Password=PASSWORD;MultipleActiveResultSets=True";

            try
            {
                Console.Write(sqlServerName);

                var connection = new ServerConnection(sqlServerName);
                var server = new Server(connection);
                TryDeleteDatabase(server, databaseName);
                EnsureDatabase.For.SqlDatabase(connectionString);

                var path = Path.GetFullPath(Path.Combine(Path.GetDirectoryName(Directory.GetCurrentDirectory()), "..\\..\\"));

                // Delete Database
                RunFreshSqlScript(connectionString, $@"{path}\DatabaseSetup\Scripts");

                var assembly = Assembly.LoadFrom("EPiServer.dll");
                var version = $"{assembly.GetName().Version.Major}.{assembly.GetName().Version.Minor}.{assembly.GetName().Version.Build}";

                // Install Epi tables
                RunFreshSqlScript(connectionString, $@"{path}\packages\EPiServer.CMS.Core.{version}\tools\");

                ExecuteCommand($@"{path}\EPiUpdatePackage\update.bat {path}\TSC.Website");
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }

        private static void TryDeleteDatabase(Server server, string databaseName)
        {
            try
            {
                if (server.Databases[databaseName] != null)
                {
                    server.KillDatabase(databaseName);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }

        private static void ExecuteCommand(string command)
        {
            var processInfo = new ProcessStartInfo("cmd.exe", "/c " + command);
            processInfo.CreateNoWindow = true;
            processInfo.UseShellExecute = false;
            processInfo.RedirectStandardError = true;
            processInfo.RedirectStandardOutput = true;

            var process = Process.Start(processInfo);

            process.OutputDataReceived += (object sender, DataReceivedEventArgs e) => Console.WriteLine("output>>" + e.Data);
            process.BeginOutputReadLine();

            process.ErrorDataReceived += (object sender, DataReceivedEventArgs e) => Console.WriteLine("error>>" + e.Data);
            process.BeginErrorReadLine();

            process.WaitForExit();

            Console.WriteLine("ExitCode: {0}", process.ExitCode);
            process.Close();
        }

        private static void RunFreshSqlScript(string connectionString, string scriptPath)
        {
            try
            {
                var upgrader = DeployChanges.To.SqlDatabase(connectionString)
                    .WithScriptsFromFileSystem(scriptPath)
                    .LogToConsole()
                    .WithTransaction()
                    .JournalTo(new NullJournal())
                    .Build();
                var result = upgrader.PerformUpgrade();
                Console.Write(result.Successful);
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }
    }
}
