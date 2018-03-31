# Custom Content Area


## Extending The Content Area Renderer

```csharp
using EPiServer;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.ServiceLocation;
using EPiServer.Web;
using EPiServer.Web.Mvc;
using EPiServer.Web.Mvc.Html;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace EpiCustomContentAreas.Business
{
    [ServiceConfiguration(typeof(CustomContentAreaRenderer), Lifecycle = ServiceInstanceScope.Unique)]
    public class CustomContentAreaRenderer : ContentAreaRenderer
    {
        private readonly ContentFragmentAttributeAssembler _attributeAssembler;
        private readonly IContentRenderer _contentRenderer;
        private readonly IContentRepository _contentRepository;
        private readonly TemplateResolver _templateResolver;

        public CustomContentAreaRenderer(IContentRenderer contentRenderer, TemplateResolver templateResolver, ContentFragmentAttributeAssembler attributeAssembler)
            : base(contentRenderer, templateResolver, attributeAssembler)
        {
            _contentRenderer = contentRenderer;
            _templateResolver = templateResolver;
            _attributeAssembler = attributeAssembler;
        }

        public CustomContentAreaRenderer(IContentRenderer contentRenderer, TemplateResolver templateResolver, ContentFragmentAttributeAssembler attributeAssembler, IContentRepository contentRepository)
            : base(contentRenderer, templateResolver, attributeAssembler, contentRepository)
        {
            _contentRenderer = contentRenderer;
            _templateResolver = templateResolver;
            _attributeAssembler = attributeAssembler;
            _contentRepository = contentRepository;
        }

        protected override void RenderContentAreaItem(HtmlHelper htmlHelper, ContentAreaItem contentAreaItem, string templateTag, string htmlTag, string cssClass)
        {
            var dictionary = new Dictionary<string, object>();
            dictionary["childrencustomtagname"] = htmlTag;
            dictionary["childrencssclass"] = cssClass;
            dictionary["tag"] = templateTag;

            dictionary = contentAreaItem.RenderSettings.Concat(
                (
                from r in dictionary
                where !contentAreaItem.RenderSettings.ContainsKey(r.Key)
                select r
                )
            ).ToDictionary(r => r.Key, r => r.Value);

            htmlHelper.ViewBag.RenderSettings = dictionary;
            var content = contentAreaItem.GetContent(_contentRepository);

            if (content != null)
            {
                using (new ContentAreaContext(htmlHelper.ViewContext.RequestContext, content.ContentLink))
                {
                    var templateModel = ResolveTemplate(htmlHelper, content, templateTag);
                    if ((templateModel != null) || IsInEditMode(htmlHelper))
                    {
                        if (IsInEditMode(htmlHelper))
                        {
                            var tagBuilder = new TagBuilder(htmlTag);
                            AddNonEmptyCssClass(tagBuilder, cssClass);
                            tagBuilder.MergeAttributes<string, string>(
                                _attributeAssembler.GetAttributes(
                                    contentAreaItem, IsInEditMode(htmlHelper), (bool)(templateModel != null)));
                            BeforeRenderContentAreaItemStartTag(tagBuilder, contentAreaItem);
                            htmlHelper.ViewContext.Writer.Write(tagBuilder.ToString(TagRenderMode.StartTag));
                            htmlHelper.RenderContentData(content, true, templateModel, _contentRenderer);
                            htmlHelper.ViewContext.Writer.Write(tagBuilder.ToString(TagRenderMode.EndTag));
                        }
                        else
                        {
                            htmlHelper.RenderContentData(content, true, templateModel, _contentRenderer);
                        }
                    }
                }
            }
        }

        private void RenderEditorView()
        {
        }

        protected override bool ShouldRenderWrappingElement(HtmlHelper htmlHelper)
        {
            return false;
        }

    }
}
```

## Content Area Extenion Method

```csharp
namespace EpiCustomContentAreas.Business
{
    public static class ContentAreaExtensions
    {
        internal static Injected<CustomContentAreaRenderer> _customContentAreaRenderer;

        public static void RenderCustomContentArea(this HtmlHelper htmlHelper, ContentArea contentArea)
        {
            _customContentAreaRenderer.Service.Render(htmlHelper, contentArea);
        }
    }
}
```

## Overrding the Default COntent Area HTML In Views/Shared/DisplayTemplates

This snippet allows Episerver to use our new code, rather than default to the built-in version.

```javascript
@model EPiServer.Core.ContentArea
@using EpiCustomContentAreas.Business;


@{
    Html.RenderCustomContentArea(Model);
}
```

---
[:arrow_left: BACK](../README.md)