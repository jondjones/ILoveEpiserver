using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Web.Security;
using EPiServer;
using EPiServer.ClientScript;
using EPiServer.Personalization;
using EPiServer.PlugIn;

namespace Templates.Admin
{
    [GuiPlugIn(DisplayName = "Profile Editor", Description = "Edit Users Profile Information", Area = PlugInArea.AdminMenu,
        Url = "~/ProfileEditor.aspx")]
    public partial class ProfileEditor : SimplePage
    {
        public bool DisplayImagesOnly { get; set; }

        public ProfileEditor()
        {
            DisplayImagesOnly = true;
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            SetupControl();
            PopulateUserProfiles();
        }

        public IEnumerable<MembershipUser> PopulateUserProfiles()
        {
            var members = new List<MembershipUser>();

            var usersInRole = Roles.GetUsersInRole("WebEditors"); 
            members.AddRange(usersInRole.Select(Membership.GetUser));

            return members;
        }

        private void SetupControl()
        {
            submitButton.Attributes.Add("onclick", string.Format("OpenFileDialog('{0}', {1})", tbFilePath.ClientID, DisplayImagesOnly.ToString().ToLower()));

            ClientScriptUtility.RegisterClientScriptFile(Page, UriSupport.ResolveUrlFromUtilBySettings("javascript/episerverscriptmanager.js"));
            ClientScriptUtility.RegisterClientScriptFile(Page, UriSupport.ResolveUrlFromUIBySettings("javascript/system.js"));
        }

        protected void RefreshImage(object sender, EventArgs e)
        {
            var userName = userPicker.SelectedValue;
            var userProfile = EPiServerProfile.Get(userName);

            var imageUrl = userProfile.GetPropertyValue("ProfileImage").ToString();

            if (string.IsNullOrEmpty(imageUrl))
            {
                tbFilePath.Text = string.Empty;
                profileImagePreview.Visible = false;
            }
            else
            {
                tbFilePath.Text = imageUrl;
                profileImagePreview.ImageUrl = imageUrl;
                profileImagePreview.Visible = true;
            }
        }

        protected void UpdateProfileImage(object sender, EventArgs e)
        {
            var userName = userPicker.SelectedValue;

            var selectedProfile = EPiServerProfile.Get(userName);
            var imageUrl = GetFilePath();

            if (!string.IsNullOrEmpty(imageUrl))
            {
                selectedProfile.SetPropertyValue("ProfileImage", imageUrl);
                selectedProfile.Save();
            }
        }

        private string GetFilePath()
        {
            var controlPostBackValue = tbFilePath.ClientID.Replace('_', '$');
            var filepath = !string.IsNullOrEmpty(Request.Form[controlPostBackValue]) ? Request.Form[controlPostBackValue] : tbFilePath.Text;

            return filepath;
        }
    }
}
