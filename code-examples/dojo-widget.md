# Dojo Widget

```csharp
[EditorDescriptorRegistration(
    TargetType = typeof(String),
    UIHint = ResourceDefinitions.UiHints.CustomProperty)]
public class DojoPropertyDescriptor : EditorDescriptor
{
    public DojoPropertyDescriptor()
    {
        ClientEditingClass = "jondjones.CustomProperty.DojoProperty";
    }
}
```

## ClientResources/Scripts/CustomProperty/DojoProperty.js

```csharp
define([
    "dojo/_base/declare",
    "dijit/_Widget",
    "dijit/_TemplatedMixin",
    'dojo/text!./templates/DojoProperty.html',
],
function (
    declare,
    _Widget,
    _TemplatedMixin,
    template
) {
    return declare("jondjones.CustomProperty.DojoProperty", [
        _Widget,
        _TemplatedMixin], {
            templateString: template
        }
        );
});
```

## Module.config

```xml
<?xml version="1.0" encoding="utf-8" ?>
<module>
  <assemblies>
    <add assembly="JonDJones.Com" />
  </assemblies>

  <dojoModules>
    <add name="jondjones" path="Scripts" />
  </dojoModules>
</module>
```
## ClientResources/Scripts/CustomProperty/templates/DojoProperty.html

```html
    <div>My Widget</div>
```



---
[:arrow_left: BACK](../README.md)