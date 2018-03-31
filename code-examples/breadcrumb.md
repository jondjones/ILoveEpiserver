# Breadcrumb

## The Code

```csharp

        public static BreadcrumbViewModel CreateBreadcrumbViewModel(PageData currentPage, IContentRepository ContentRepository)
        {
            var viewModel = new BreadcrumbViewModel();

            var list = new List<Breadcrumb>();

            var pageRootId = EPiServer.Web.SiteDefinition.Current.RootPage.ID;

            var parents = ContentRepository.GetAncestors(currentPage.PageLink).Where(x => x.ParentLink.ID >= pageRootId).Reverse().
                    ToList();

            list.AddRange(parents.OfType<PageData>().Select(p => new Breadcrumb { Text = p.Name, Url = p.LinkURL, IsCurrent = false }));
            list.Add(new Breadcrumb { Text = currentPage.Name, Url = currentPage.LinkURL, IsCurrent = true });

            viewModel.Breadcrumb = list;
            viewModel.HideBreadcrumb = currentPage.HideBreadcrumb;

            return viewModel;
        }
```

## The View

```html
@model JonDJones.Com.EpiBreadcrumbs.Models.ViewModels.Common.BreadcrumbViewModel

@if (!Model.HideBreadcrumb)
{
    <div>
        <div>
            <ul itemprop="breadcrumb">
                <li>You are:</li>
                @foreach (var item in @Model.Breadcrumb)
                {
                    if (item.IsCurrent)
                    {
                        <li class="current">
                            @item.Text
                        </li>
                    }
                    else
                    {
                        <li>
                            <a href="@Url.PageUrl(@item.Url)">
                                @item.Text
                            </a>
                        </li>
                    }
                }
            </ul>
        </div>
    </div>
}
```

## View Models

ViewModel 

```csharp
public class BreadcrumbViewModel
{
    public List<Breadcrumb> Breadcrumb { get; set; }

    public bool HideBreadcrumb { get; set; }
}
```

Model to Store Breadcrumb Data  

```csharp
    public class Breadcrumb : IHyperlink
    {
        public bool IsCurrent { get; set; }

        public string Url { get; set; }

        public string Text  { get; set; }

        public string LinkTarget  { get; set; }
    }
```

---
[:arrow_left: BACK](../README.md)