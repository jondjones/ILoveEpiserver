
# Partial Router

## Partial Router

```csharp
    public class BlogPartialRouter : IPartialRouter<BlogHomePage, CategoryPage>
    {
        public Injected<IContentLoader> contentLoader;

        private BlogRepository _blogRepository;

        private CategoryRepository _categoryRepository;

        private ContentReference _blogPage;

        public BlogPartialRouter(CategoryRepository categoryRepository, BlogRepository blogRepository, ContentReference blogPage)
        {
            _categoryRepository = categoryRepository;
            _blogRepository = blogRepository;
            _blogPage = blogPage;
        }

        public object RoutePartial(BlogHomePage blogHomePage, SegmentContext segmentContext)
        {
            var categoryPageSegment = TryGetCategoryPageSegment(segmentContext);

            var blogPageSegment = TryGetBlogPageSegment(segmentContext);

            if (!string.IsNullOrEmpty(blogPageSegment))
            {
                return _blogRepository.GetBlogPageByRoute(blogPageSegment.ToLower());
            }

            var categoryPage = _categoryRepository.GetCategoryPageByRoute(categoryPageSegment.ToLower());

            if (categoryPage != null)
            {
                segmentContext.RoutedContentLink = categoryPage.ContentLink;
            }

            return categoryPage;
        }

        private static string TryGetBlogPageSegment(SegmentContext segmentContext)
        {
            var segment = segmentContext.GetNextValue(segmentContext.RemainingPath);
            var blogSegment = segment.Next;
            segmentContext.RemainingPath = segment.Remaining;

            return blogSegment;
        }

        private static string TryGetCategoryPageSegment(SegmentContext segmentContext)
        {
            var segment = segmentContext.GetNextValue(segmentContext.RemainingPath);
            var categorySegment = segment.Next;
            segmentContext.RemainingPath = segment.Remaining;

            return categorySegment;
        }

        public PartialRouteData GetPartialVirtualPath(CategoryPage categoryPage, string language, RouteValueDictionary routeValues, RequestContext requestContext)
        {
            return new PartialRouteData()
            {
                BasePathRoot = _blogPage,
                PartialVirtualPath = String.Format("{0}/{1}/",
                    categoryPage.Name,
                    HttpUtility.UrlPathEncode(categoryPage.Name))
            };
        }

    }
```

### Initialization Module 

```csharp
[InitializableModule]
public class DataInitialization : IInitializableModule
{
    Injected<IEpiServerDependencies> epiServerDependencies;

    public void Initialize(InitializationEngine context)
    {
        var dependency = epiServerDependencies.Service;

        var blogRouter = new BlogPartialRouter(new CategoryRepository(dependency), new BlogRepository(dependency), new ContentReference(39));
        RouteTable.Routes.RegisterPartialRouter<BlogHomePage, CategoryPage>(blogRouter);
    }
        
    public void Uninitialize(InitializationEngine context)
    {
    }
    
    public void Preload(string[] parameters)
    {
    }
}
```