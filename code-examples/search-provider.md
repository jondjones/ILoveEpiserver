# Search Provider

```csharp
[SearchProvider]
public class InternalPageSearchProvider : PageSearchProvider
{
    public InternalPageSearchProvider(LocalizationService localizationService,
            SiteDefinitionResolver siteDefinitionResolver,
            PageTypeRepository contentTypeRepository,
            IContentRepository contentRepository,
            ILanguageBranchRepository languageBranchRepository,
            SearchHandler searchHandler,
            ContentSearchHandler contentSearchHandler,
            SearchIndexConfig searchIndexConfig)
            : base(localizationService, siteDefinitionResolver, contentTypeRepository, contentRepository, languageBranchRepository, searchHandler, contentSearchHandler, searchIndexConfig)
    {
    }

    public override IEnumerable<SearchResult> Search(Query query)
    {
        query.MaxResults = 20;
        if (query.SearchQuery.Contains("country:"))
        {
            query.SearchQuery = query.SearchQuery.Replace("country:", string.Empty);
                query.SearchRoots = new[] { "33" };
        }

        return base.Search(query);
    }
}
```

---
[:arrow_left: BACK](../README.md)
```