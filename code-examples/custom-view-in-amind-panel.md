# Custom View In Asset Panel

## Controller

```csharp
  [Authorize(Roles = "WebEditors, WedAdmins, Administrators")]
    public class CustomViewController : BasePageController<CustomPage>
    {
        public ActionResult Index()
        {
            return PartialView("~/Views/Widgets/CustomView/Index.cshtml");
        }
    }
```

## module.config

```xml
<?xml version="1.0" encoding="utf-8" ?>
<module>
  <dojoModules>
    <add name="jondjones" path="Scripts/widgets" />
  </dojoModules>
</module>
```

## CustomViewInAssetPane/Views/Widgets/CustomView/Index.cshtml

```html
<div>Custom View</div>
```

# Javacsript Appraoch

## ClientResources/Scripts/widgets/jondjones/CustomView.js

```csharp
define([
    "dojo/_base/declare",
    "dijit/_WidgetBase",
    "dijit/_TemplatedMixin"
], function (
    declare,
    _WidgetBase,
    _TemplatedMixin

) {
    return declare("jondjones.jondjones.CustomView",
        [_WidgetBase, _TemplatedMixin], {
            templateString: dojo.cache("/en/customview")
        });
});
```

## ClientResources/Scripts/widgets/jondjones/UserManual.js

```javascript
define([
    "dojo/_base/declare",
    "dijit/_WidgetBase",
    "dijit/_TemplatedMixin"
], function (
    declare,
    _WidgetBase,
    _TemplatedMixin

) {
    return declare("jondjones.jondjones.UserManual",
        [_WidgetBase, _TemplatedMixin], {
            templateString: dojo.cache("/Static/UserGuide/ContentEditorsUserManual.html")
        });
});
```

## Static/UserGuide/ContentEditorsUserManual.html

```csharp
<div>
    <h3>Content Editors User Manual</h3>

    <a href="./ContentPage.html">Content Page</a>
</div>
```

## Static/UserGuide/ContentPage.html

```csharp
<div>
    Information goes here
</div>
```
