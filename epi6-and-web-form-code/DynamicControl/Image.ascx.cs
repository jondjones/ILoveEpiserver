using System;
using EPiServer.DynamicContent;
using EPiServer.SpecializedProperties;
using EPiServer.Web.PropertyControls.PropertySettings;

namespace Jondjones.com.Example
{
    [DynamicContentPlugIn(  
        DisplayName = "Image Control",
        Description = "Displays correctly formatted images with a caption.",
        ViewUrl = "~//Image.ascx"),]
    public partial class ImageDisplay : EPiServer.UserControlBase
    {
        private static readonly log4net.ILog Logger = log4net.LogManager.GetLogger
            (System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public PropertyImageUrl ImageUrl { get; set; }

        public AlignmentList ImageAlignment { get; set; }

        public string ImageCaption { get; set; }

        public string Width { get; set; }

        public string Height { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                if (ImageUrl != null)
                {
                    fig.Visible = true;

                    imageToDisplay.ImageUrl = ImageUrl.Value.ToString();

                    if (!string.IsNullOrEmpty(ImageCaption))
                    {
                        figcaption.Visible = true;
                        FigureCaption.Text = ImageCaption;
                    }
                }

                fig.Attributes.Add("class", ImageAlignment.Value as string);

            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }
        }
    }
}