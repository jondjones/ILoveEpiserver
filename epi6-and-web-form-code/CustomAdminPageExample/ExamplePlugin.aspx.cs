using System;
using EPiServer;
using EPiServer.PlugIn;
using EPiServer.Security;

namespace Example
{
    [GuiPlugIn(DisplayName = "Example", Description = "Example", Area = PlugInArea.AdminMenu,
        Url = "~/Templates/Plugins/ExamplePlugin.aspx")]
    public partial class AdminPlugin : SimplePage
    {
        public string PluginDisplayString { get; set; }

        private AdminPluginSettings _settings;

        public AdminPlugin()
        {
            _settings = new AdminPluginSettings();
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);

            if (!PrincipalInfo.HasAdminAccess)
            {
                AccessDenied();
            }
        }

        public string GetTheTime()
        {
            return _settings.LoadData();
        }

        protected void UpdateTheTime(object sender, EventArgs e)
        {
            var time = DateTime.Now.ToString("HH:MM:ss");
            _settings.SaveData(time);
        }
    }
}