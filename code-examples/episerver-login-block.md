# Episerver Login Block Example


(todo) Add view model login
## Controller

```csharp
    public class LoginControlController : BaseBlockController<LoginControlBlock>
    {
        [ImportModelStateFromTempData]
        public override ActionResult Index(LoginControlBlock currentBlock)
        {
            var viewModel = new LoginControlBlockViewModel(currentBlock, BaseDependencies);
            return PartialView("Index", viewModel);
        }

        [ExportModelStateToTempData]
        public ActionResult Login(LoginModel model, ContentReference currentPage)
        {
            if (Membership.ValidateUser(model.UserName, model.Password))
            {
                FormsAuthentication.SetAuthCookie(model.UserName, model.RememberMe);
            }
            else
            {
                ModelState.AddModelError(string.Empty, "Log-in Failed");
            }

            return RedirectToAction("Index", new { node = currentPage });
        }

```

## Block 

```csharp
    [ContentType(DisplayName = "Login Control",
        Description = "Login Control",
        GUID = "797AEC21-AB32-4F89-BED3-C14DA89D5252")]
    public class LoginControlBlock : BlockData
    {
        [Ignore]
        public LoginModel LoginModel { get; set; }

        [Display(Name = "Block Name",
            GroupName = SystemTabNames.Content,
            Order = 100)]
        [Required]
        public virtual string BlockName { get; set; }

        [Display(Name = "Block Description",
            GroupName = SystemTabNames.Content,
            Order = 200)]
        [Required]
        public virtual XhtmlString BlockDescription { get; set; }

        [Display(Name = "User Name Label",
            GroupName = SystemTabNames.Content,
            Order = 300)]
        [Required]
        public virtual string UserNameLabel { get; set; }

        [Display(Name = "User Name Placeholder",
            GroupName = SystemTabNames.Content,
            Order = 400)]
        [Required]
        public virtual string UserNamePlaceholder { get; set; }

        [Display(Name = "Password Label",
            GroupName = SystemTabNames.Content,
            Order = 500)]
        [Required]
        public virtual string PasswordLabel { get; set; }

        [Display(Name = "Forgot Your Password Text",
            GroupName = SystemTabNames.Content,
            Order = 700)]
        [Required]
        public virtual string ForgotYourPasswordText { get; set; }

        [Display(Name = "Forgot Your Password Url",
            GroupName = SystemTabNames.Content,
            Order = 800)]
        [Required]
        public virtual Url ForgotYourPasswordUrl { get; set; }

        [Display(Name = "Remember Me Text",
            GroupName = SystemTabNames.Content,
            Order = 900)]
        [Required]
        public virtual string RememberMeText { get; set; }

        [Display(Name = "Sign-In Text",
            GroupName = SystemTabNames.Content,
            Order = 1000)]
        [Required]
        public virtual string SignInText { get; set; }

        [Display(Name = "Sign-In Form Url",
            GroupName = SystemTabNames.Content,
            Order = 1100)]
        [Required]
        public virtual Url SignInFormUrl { get; set; }
    }
```

## View

```html
@model GMGShop.Model.ViewModels.Blocks.LoginControlBlockViewModel

@using (Html.BeginForm("Login", "LoginControl", FormMethod.Post))
{
    @Html.AntiForgeryToken()
    @Html.Hidden("currentPage", @Model.CurrentBlock.LoginModel.CurrentPage)


    <h1>
    @Model.CurrentBlock.BlockName
   </h1>

   <div>
        @Model.CurrentBlock.BlockDescription
    </div>

    <div class="text-warning">
        @Html.ValidationSummary()
    </div>

    <div>
        @Html.Label(@Model.CurrentBlock.UserNameLabel)
        <input type="text" name="UserName" value="@Model.CurrentBlock.LoginModel.UserName" placeholder="@Model.CurrentBlock.UserNamePlaceholder">
    </div>

     <div>
           @Html.Label(@Model.CurrentBlock.PasswordLabel)
           <input type="password" name="Password" value="@Model.CurrentBlock.LoginModel.Password">
     </div>

   <div>
       <button href="@Model.CurrentBlock.SignInFormUrl">
           @Model.CurrentBlock.SignInText
       </button>
   </div>

   <div>
        <a src="@Model.ForgotPasswordUrl">
            @Model.CurrentBlock.ForgotYourPasswordText
        </a>
    </div>

    <div>

        @Html.CheckBox("RememberMe", @Model.CurrentBlock.LoginModel.RememberMe)
        @Model.CurrentBlock.RememberMeText

    </div>
}
```

---
[:arrow_left: BACK](../README.md)