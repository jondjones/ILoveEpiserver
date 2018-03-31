# Mega menu

```csharp
@model JonDJones.Com.Core.Interfaces.IPageViewModel<JonDJones.Com.Core.Pages.Base.GlobalBasePage>
@using EPiServer.Web.Mvc.Html;

<ul id="sdt_menu" class="sdt_menu">

    @foreach (var menuItem in Model.Layout.Menu)
    {
        <li>
            <a href="@menuItem.Link">
                <img src="@Url.ContentUrl(menuItem.ImageUrl)" alt="" />
                <span class="sdt_active"></span>
                <span class="sdt_wrap">
                    <span class="sdt_link">@menuItem.Name</span>
                    <span class="sdt_descr">@menuItem.SubMenuTitle</span>
                </span>
            </a>

            @if(menuItem.SubMenuItems.Any())
            {
                <div class="sdt_box">

                    @foreach(var subMenuItem in menuItem.SubMenuItems)
                    {
                        <a href="@subMenuItem.Link">@subMenuItem.Name</a>
                    }
                </div>
            }
        </li>
    }
</ul>
```