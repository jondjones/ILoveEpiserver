# Scheduled Task Example

```csharp
    [ScheduledPlugIn(DisplayName = "Page Importer", SortIndex = 9999)]
    public class PageImporter : JobBase
    {
        private static readonly ILog Logger = LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType);

        internal Injected<IContentRepository> ContentRepository { get; set; }

        private int processedPages;

        private int failedPages;

        private long duration;

        public PageImporter()
        {
            IsStoppable = true;

            processedPages = 0;
            failedPages = 0;
        }

        public override string Execute()
        {
            var timer = Stopwatch.StartNew();

            if (CreateDummyPage(Guid.NewGuid().ToString()))
            {
                processedPages = processedPages + 1;
            }

            timer.Stop();
            duration = timer.ElapsedMilliseconds;

            return ToString();
        }

        private bool CreateDummyPage(string pageName)
        {
            var existingContentPage =
                ContentRepository.Service.GetChildren<ContentPage>(
                ContentReference.RootPage)
                    .FirstOrDefault(x => x.PageName == pageName);

            if (existingContentPage != null)
                return AddFailedPage(pageName);

            var contentPage =
                ContentRepository.Service.GetDefault<ContentPage>
                (ContentReference.RootPage);

            contentPage.Name = pageName;

            var contentReference = ContentRepository.Service.Save(contentPage, SaveAction.Publish, AccessLevel.NoAccess);

            if (contentReference == null)
                return AddFailedPage(pageName);

            return true;
        }

        private bool AddFailedPage(string pageName)
        {
            Logger.Error(string.Format("Failed to add page {0}", pageName));
            failedPages = failedPages + 1;
            return false;
        }

        public override string ToString()
        {
            var logMesssage = failedPages > 0
                                  ? string.Format(
                                      "Please check the logs to see the {0} pages that failed.",
                                      failedPages)
                                  : string.Empty;

            return string.Format(
                "{0} have been created in {1}ms on {2}. {3}",
                processedPages,
                duration,
                Environment.MachineName,
                logMesssage);
        }
    }
```

---
[:arrow_left: BACK](../README.md)