# Adding Custom CSS Into Epi

## ClientResources/Styles/editor.css

```html
.Sleek .dijitTabPaneWrapper .epi-formsRow label[title]:after
{
    display: block;
    content: attr(title);
    font-size: 0.7em;
    font-style: italic;
}

.Sleek .epi-containerLayout .epi-formsRow .epi-formsWidgetWrapper .dijitTextBox
{
    width: 45%;
}

.Sleek .epi-containerLayout .epi-formsRow .epi-content-area-editor
{
    width: 45%;
}
```

## module.config

```xml
<?xml version="1.0" encoding="utf-8" ?>
<module>
  <clientResources>
    <add name="epi-cms.widgets.base" path="Styles/editor.css" resourceType="Style"/>
  </clientResources>
</module>
```

---
[:arrow_left: BACK](../README.md)
```