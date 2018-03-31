# Lowercase Url Module

```csharp
using System;
using EPiServer;
using EPiServer.Framework;
using EPiServer.Framework.Initialization;

namespace Modules
{
    [ModuleDependency(typeof(EPiServer.Web.InitializationModule))]
    public class LowercaseUrlModule : IInitializableModule
    {
        public void Initialize(InitializationEngine context)
        {
            DataFactory.Instance.SavingPage += SavingPage;
        }

        private void SavingPage(object sender, PageEventArgs e)
        {
            try
            {
                e.Page.URLSegment = e.Page.URLSegment.ToLowerInvariant();
            }
            catch (Exception ex)
            {
                // If there's a problem don't prevent the page being saved
            }
        }

        public void Uninitialize(InitializationEngine context)
        {
            DataFactory.Instance.SavingPage -= SavingPage;
        }

        public void Preload(string[] parameters)
        {
        }
    }
}
```

---
[:arrow_left: BACK](../README.md)