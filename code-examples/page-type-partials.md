
# Rendering Pagetypes as partials

## Controller Code

```csharp
[TemplateDescriptor(TemplateTypeCategory = TemplateTypeCategories.MvcPartialController)]
public class ContentPagePartialController : PageController<ContentPage>
{
    public ActionResult Index(ContentPage  currentPage)
    {
        return PartialView("/Views/Partials/ContentPage/index.cshtml", currentPage);
    }
}
```
## Views/Partials/ContentPage/index.cshtml

```html
@model JonDJones.Com.Models.Pages.ContentPage

Partial View for @Model.PageTitle
```

---
[:arrow_left: BACK](../README.md)
```