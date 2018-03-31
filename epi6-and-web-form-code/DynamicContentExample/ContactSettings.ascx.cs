using System;
using EPiServer.DynamicContent;

namespace DynamicContent
{
    public partial class ContactSettings : DynamicContentEditControl
    {
        private static readonly log4net.ILog Logger = log4net.LogManager.GetLogger
            (System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public Guid PageId { get; set; }

        private const string PropertyName = "ListId";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                try
                {
                    object data = null;

                    if (Content.Properties[PropertyName] != null)
                    {
                        data = Content.Properties[PropertyName].Value;
                        PageId = Guid.Parse(data.ToString());
                    }

                    if (data == null || string.IsNullOrEmpty(data.ToString()))
                    {
                        PageId = Guid.NewGuid();
                    }
                }
                catch (Exception ex)
                {
                    Logger.Error(ex);
                }
            }
        }
        
        public override void PrepareForSave()
        {
            Content.Properties[PropertyName].Value = PageId.ToString();
        }
    }
}