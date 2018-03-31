# Form That Posts Back To A Controller

## Controller Code

```csharp
public class FormPageController : PageController<FormPage>
{
    public ActionResult Index(FormPage currentPage)
    {
        return View("Index", currentPage);
    }

    public ActionResult Save(FormPage currentPage, ShippingAddress address)
    {
        if (currentPage.MainContentArea != null || currentPage.MainContentArea.Items.Any())
        {
            var contentLoader = ServiceLocator.Current.GetInstance<IContentLoader>();

            foreach (var item in currentPage.MainContentArea.Items)
            {
                var shippingBlock = contentLoader.Get<ShippingAddressBlock>(item.ContentLink);

                if (shippingBlock != null)
                {
                    shippingBlock.Address = address;
                }
            }
        }
        
        return null;
    }
}
```

## The View

```html
@model CustomFormWithRouting.Models.Pages.FormPage

@using (Html.BeginForm("Save", "FormPage", FormMethod.Post))
{

    <div role="main" id="main" class="main row">

        <div class="large-8 column">

            @Html.PropertyFor(x => x.MainContentArea)

        </div>
    </div>
    
    <button type="submit">Submit</button>
}
```

# The Block

```csharp
[EPiServer.DataAnnotations.ContentType(
    DisplayName = "Form Page",
    GroupName = "Form Page",
    Description = "Form Page",
    GUID = "A6A309A8-9A61-4F01-BFF6-D99E1AAA3A2A")]
public class FormPage : PageData
{
    [Display(
        Name = "Contenet Area",
        GroupName = SystemTabNames.Content,
        Order = 10)]
    public virtual ContentArea MainContentArea { get; set; }
}
```

## Model

This is the code for the model the form posts back to the controller

```csharp
public class ShippingAddress
{
    public string AddressLine1 { get; set; }

    public string AddressLine2 { get; set; }

    public string Town { get; set; }

    public string Postcode { get; set; }
}
```

## Global.acs

I think this can be skipped - just in case you get stuck

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
            "epiRoute",
            "Blocks/{controller}/{action}",
            new { action = "Index" });

            RouteTable.Routes.MapRoute("defaultRoute", "{controller}/{action}");
        }
    }
```

---
[:arrow_left: BACK](../README.md)