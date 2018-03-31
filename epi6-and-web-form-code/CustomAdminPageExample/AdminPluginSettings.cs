using System;
using System.Data;
using EPiServer.PlugIn;

namespace Example
{
    public class AdminPluginSettings
    {
        private DataSet customDataSet;

        private const string Key = "Example";

        private static readonly log4net.ILog Logger = log4net.LogManager.GetLogger
            (System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public AdminPluginSettings()
        {
            customDataSet = new DataSet();
            customDataSet.Tables.Add(new DataTable());
            customDataSet.Tables[0].Columns.Add(new DataColumn(Key, typeof(string)));
        }

        public string LoadData()
        {
            var returnValue = string.Empty;

            try
            {
                PlugInSettings.Populate(typeof(AdminPluginSettings), customDataSet);
                returnValue = customDataSet.Tables[0].Rows[0][Key].ToString();
            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }

            return returnValue;
        }

        public void SaveData(string stringToSave)
        {
            try
            {
                var newRow = customDataSet.Tables[0].NewRow();
                newRow[Key] = stringToSave;
                customDataSet.Tables[0].Rows.Add(newRow);

                // Stores your data in EPI no need to worry about config files or custom database calls
                PlugInSettings.Save(typeof(AdminPluginSettings), customDataSet);
            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }
        }
    }
}
