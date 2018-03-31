# Content Import With JSON

## The Importer

```csharp
using EPiServer.BaseLibrary.Scheduling;
using EPiServer.Core;
using EPiServer.Logging.Compatibility;
using EPiServer.PlugIn;
using EPiServer.ServiceLocation;
using JonDJones.com.Core.Helpers;
using JonDJones.com.Core.Repositories;
using JonDJones.Com.Core;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Web.Configuration;

namespace JonDJones.com.Core.ScheduledTasks
{
    [ScheduledPlugIn(DisplayName = "Content Page Importer", SortIndex = 100)]
    public class ContentPageImporter : JobBase
    {
        private static readonly ILog Logger = LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType);

        private int processedNodes;

        private int failedNodes;

        public ContentPageImporter()
        {
            processedNodes = 0;
            failedNodes = 0;
        }

        private long Duration { get; set; }

        public override string Execute()
        {
            var timer = Stopwatch.StartNew();

            var epiServerDependencies = ServiceLocator.Current.GetInstance<IContentRepository>();
            var fileDirectory = FileHelper.GetImportDirectoryPath();
            var jsonFiles = FileHelper.GetFiles(fileDirectory);

            if (jsonFiles.Any())
            {
                ProcessFiles(epiServerDependencies, jsonFiles);
            }
            else
                return "No files to process";

            timer.Stop();
            Duration = timer.ElapsedMilliseconds;

            return ToString();
        }

        private void ProcessFiles(IEpiServerDependencies epiServerDependencies, List<string> jsonFiles)
        {
            foreach (var jsonFile in jsonFiles)
            {
                using (var streamReader = new StreamReader(jsonFile))
                {
                    var json = streamReader.ReadToEnd();

                    ContentPageData contentPageData;

                    var settings = new JsonSerializerSettings
                    {
                        NullValueHandling = NullValueHandling.Ignore
                    };

                    try
                    {
                        contentPageData = JsonConvert.DeserializeObject<ContentPageData>(json, settings);
                    }
                    catch (JsonSerializationException ex)
                    {
                        Logger.Error(string.Format("Invalid Json file {0}", jsonFile), ex);
                        failedNodes = failedNodes + 1;
                        continue;
                    }
                    catch (JsonReaderException ex)
                    {
                        Logger.Error(string.Format("Invalid Json format within {0}", jsonFile), ex);
                        failedNodes = failedNodes + 1;
                        continue;
                    }

                    contentPageData.ParentContentReference = ContentReference.RootPage;

                    var contentPageRepository = new ContentPageRepository(epiServerDependencies);
                    var contentPageReference = contentPageRepository.CreateContentPage(contentPageData);

                    if (contentPageReference == null)
                    {
                        Logger.ErrorFormat("Unable to get create blog page {0} ", contentPageData.PageName);
                        failedNodes = failedNodes + 1;
                        continue;
                    }

                    processedNodes = processedNodes + 1;
                }
            }
        }

        public override string ToString()
        {
            return string.Format(
                "Imported {0} pages successfully in {1}ms on. {2} page(s) failed to import.",
                processedNodes,
                Duration,
                failedNodes);
        }
    }
}
```

##

```csharp
public class ContentPageRepository
{
    private IContentRepository _epiServerDependencies;

    public ContentPageRepository(IEpiServerDependencies epiServerDependencies)
    {
        _epiServerDependencies = epiServerDependencies;
    }

    public ContentPage CreateContentPage(ContentPageData contentPageData)
    {
        var existingPage = _epiServerDependencies
                                    .GetChildren<ContentPage>(ContentReference.RootPage)
                                    .FirstOrDefault(x => x.PageTitle == contentPageData.PageName);

        if (existingPage != null)
            return existingPage;

        var newPage = _epiServerDependencies.GetDefault<ContentPage>(contentPageData.ParentContentReference);

        newPage.PageTitle = contentPageData.PageName;
        newPage.Name = contentPageData.PageName;

        newPage.SeoTitle = contentPageData.SeoTitle;
        newPage.Keywords = contentPageData.Keywords;

        return Save(newPage) != null ? newPage : null;
    }

    public ContentReference Save(ContentPage contentPage,
                                     SaveAction saveAction = SaveAction.Publish,
                                     AccessLevel accessLevel = AccessLevel.NoAccess)
    {
        if (contentPage == null)
            return null;

        return _epiServerDependencies.Save(contentPage, saveAction, accessLevel);
    }
}


---
[:arrow_left: BACK](../README.md)
```