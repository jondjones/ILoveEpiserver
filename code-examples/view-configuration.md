# Custom Area Widget -> Adds Debug Information

## Controller

```csharp
public class MetaDataController : Controller
{
    [Authorize(Roles = "WebEditors, WebAdmins, Administrators")]
    public ActionResult Index()
    {
        var pageRouteHelper = EPiServer.ServiceLocation.ServiceLocator.Current.GetInstance<EPiServer.Web.Routing.PageRouteHelper>();
        PageData currentPage = pageRouteHelper.Page;

        return View(currentPage);
    }
}
```

```csharp
[ServiceConfiguration(typeof(EPiServer.Shell.ViewConfiguration))]
public class ContentPageMetaDataPlugin : ViewConfiguration<ContentPage>
{
    public ContentPageMetaDataPlugin()
    {
        Key = "ContentPageMetaDataPlugin";
        Name = "Page Debugging Information";
        Description = "Page Debugging Information";
        ControllerType = "epi-cms/widget/IFrameController";
        ViewType = "/DebuggingInformation/";
        IconClass = "epi-iconForms";
    }
}
```

## Views/MetaData/index.cshtml
```html
@model EPiServer.Core.PageData

@{
        Layout = string.Empty;
}

Page Name = @Model.Name <br />
Page Id = @Model.ContentLink.ID
```

## Global.ascx

```csharp
public class EPiServerApplication : EPiServer.Global
{
    protected void Application_Start()
    {
        AreaRegistration.RegisterAllAreas();
    }

    protected override void RegisterRoutes(RouteCollection routes)
    {
        base.RegisterRoutes(routes);

        routes.MapRoute("DebuggingInformation", "DebuggingInformation",
                new { controller = "MetaData", action = "index" }
        );
    }
}
```


---
[:arrow_left: BACK](../README.md)
```