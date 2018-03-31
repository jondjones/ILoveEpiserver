using System;
using EPiServer.DynamicContent;
using EPiServer.PlugIn;

namespace DynamicContent
{
    
    
    [DynamicContentPlugIn(
        DisplayName = "Contact List",
        Description = "Displays a list of configurable contacts.",
        ViewUrl = "~/DynamicContent/Contact.ascx",
        Url = "~/DynamicContent/ContactSettings.ascx",
        Area = PlugInArea.DynamicContent)
    ]
    public partial class ContactList : EPiServer.UserControlBase
    {
        private static readonly log4net.ILog Logger = log4net.LogManager.GetLogger
            (System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public string ListId { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
        }

    }
}