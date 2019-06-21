# Language Picker

Example of how to create a language picker within Episerver CMS

## View Model

```csharp
using System.Collections.Generic;

using JonDJones.Com.EpiServerLanguagePicker.Business;

using JonDJones.Com.Models.Blocks;
using EPiServer;
using EPiServer.ServiceLocation;
using EPiServer.DataAbstraction;
using System.Globalization;
using System.Web;
using System.Web.Mvc;
using System.Linq;
using System;
using EPiServer.Core;

namespace JonDJones.Com.EpiServerLanguagePicker.Models.ViewModel
{
    public class LanguagePickerBlockViewModel : BlockViewModel<LanguagePickerBlock>
    {
        private IEpiServerDependencies _epiServerDependencies;

        public LanguagePickerBlockViewModel(LanguagePickerBlock currentBlock, IEpiServerDependencies epiServerDependencies)
            : base(currentBlock, epiServerDependencies)
        {
            _epiServerDependencies = epiServerDependencies;
        }


        public IEnumerable<SelectListItem> Languages
        {
            get
            {
                var languages = new List<SelectListItem>();

                if (_epiServerDependencies.CurrentPage.PageLanguages != null)
                {
                    foreach (var langContext in ServiceLocator.Current.GetInstance<LanguageBranchRepository>().ListEnabled())
                    {
                        var culture = new CultureInfo(langContext.LanguageID);

                        var isActive = string.Equals(_epiServerDependencies.CurrentPage.Language.Name,
                                            langContext.LanguageID,
                                            StringComparison.CurrentCultureIgnoreCase)
                                        ? true
                                        : false;

                        languages.Add(new SelectListItem
                        {
                            Value = culture.Name,
                            Text = culture.NativeName,
                            Selected = isActive
                        });
                    } 
                }

                return AddDefaultValue.Concat(languages);
            }
        }

        public IEnumerable<SelectListItem> AddDefaultValue
        {
            get
            {
                return Enumerable.Repeat(new SelectListItem
                {
                    Value = CultureInfo.CurrentCulture.Name,
                    Text = "Select a country"
                }, count: 1);
            }
        }

        public string CurrentController
        {
            get
            {
                return HttpContext.Current.Request.RequestContext.RouteData.Values["controller"].ToString();
            }
        }

        public ContentReference ContentPageReference
        {
            get
            {
                return _epiServerDependencies.CurrentPage.ContentLink;
            }
        }
    }
}
```

## Views/LanguagePicker/index.cshtml

```html
@model JonDJones.Com.EpiServerLanguagePicker.Models.ViewModel.LanguagePickerBlockViewModel

@using (Html.BeginForm("SetLanguage", null, new { node = Model.ContentPageReference }, FormMethod.Post))
{
    @Html.DropDownList("selectedCountryCode", Model.Languages)
      
    <button>
        @Model.CurrentBlock.SubmitButtonText
    </button>
}
```

## Controller

```csharp
using System.Web.Mvc;
using EPiServer.Framework.DataAnnotations;
using JonDJones.Com.Models.Blocks;
using JonDJones.Com.EpiServerLanguagePicker.Models.ViewModel;

namespace JonDJones.Com.EpiServerLanguagePicker.Controllers.Blocks
{
    [TemplateDescriptor(AvailableWithoutTag = true, Default = true)]
    public class LanguagePickerController : BaseBlockController<LanguagePickerBlock>
    {
        public override ActionResult Index(LanguagePickerBlock currentBlock)
        {
            var viewModel = new LanguagePickerBlockViewModel(currentBlock, EpiServerDependencies);
            return PartialView("Index", viewModel);
        }

    }
}
```

---
[:arrow_left: BACK](../README.md)
```