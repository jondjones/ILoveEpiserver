using System;
using System.Collections.Generic;
using System.Text;
using System.Web.Hosting;
using EPiServer;
using EPiServer.Configuration;
using EPiServer.PlugIn;
using System.Linq;
using EPiServer.Web.Hosting;

namespace AdminPages
{
    [GuiPlugIn(
        DisplayName = "VPP Viewer",
        Description = "Add, edit or delete a location", 
        Area = PlugInArea.AdminMenu,
        Url = "**TO UPDATE TO THE LOCTION OF THE ASPX PAGE IN YOUR WEBROOT")]
    public partial class VppListingPlugin : SimplePage
    {
        private static readonly log4net.ILog Logger = log4net.LogManager.GetLogger
            (System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public IQueryable<VppFiles> GetVppContents()
        {
            var files = new List<VppFiles>();

            try
            {
                var provider = (VirtualPathUnifiedProvider)VirtualPathHandler.GetProvider("SiteGlobalFiles"); ;
                var vppFolder = provider.VirtualPathRoot;

                if (HostingEnvironment.VirtualPathProvider.DirectoryExists(vppFolder))
                {
                    var root = HostingEnvironment.VirtualPathProvider.GetDirectory(vppFolder) as UnifiedDirectory;
                    foreach (UnifiedDirectory subDirectory in root.Directories)
                    {
                        files.AddRange(ParseFiles(subDirectory));
                    }
                }
                else
                {
                    throw new ArgumentException("The VPP folder specified does not exist");
                }
            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }

            return files.AsQueryable();
        }


        private List<VppFiles> ParseFiles(UnifiedDirectory directory)
        {
            var vppFiles = new List<VppFiles>();

            try
            {
                foreach (UnifiedFile file in directory.Files)
                {

                    var vppFile = new VppFiles
                        {
                            VirtualPath = file.VirtualPath,
                            VppPath = file.LocalPath
                        };
                    vppFiles.Add(vppFile);
                }

            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }

            return vppFiles;
        }
    }

    public class VppFiles
    {
        public string VppPath { get; set; }

        public string VirtualPath { get; set; }
    }
}