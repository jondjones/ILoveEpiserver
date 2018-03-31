# Admin Section

## Controller

```csharp
public class AdminPageController : Controller
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

        routes.MapRoute(
                "AdminPage",
                "AdminPage",
                new { controller = "AdminPage", action = "index" }
            );
    }
}
```

## menu Provider

```csharp

using EPiServer;
using EPiServer.Security;
using EPiServer.Shell.Navigation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Routing;

[MenuProvider]
public class MenuProvider : IMenuProvider
{
    public IEnumerable<MenuItem> GetMenuItems()
    {
        var mainAdminMenu = new SectionMenuItem("Admin", "/global/admin");
        mainAdminMenu.IsAvailable = ((RequestContext request) => PrincipalInfo.Current.HasPathAccess(UriSupport.Combine("/Facebook", "")));

        var firstMenuItem = new UrlMenuItem("Main", "/global/admin/main", "/AdminPage/");
        firstMenuItem.IsAvailable = ((RequestContext request) => true);
        firstMenuItem.SortIndex = 100;
           
        return new MenuItem[]
        {
            mainAdminMenu,
            firstMenuItem
        };
    }
}
```

---
[:arrow_left: BACK](../README.md)