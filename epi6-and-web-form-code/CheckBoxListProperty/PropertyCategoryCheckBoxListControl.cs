using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web.UI.WebControls;
using EPiServer.DataAbstraction;
using EPiServer.Web.PropertyControls;

namespace Example
{
    public class PropertyCategoryCheckBoxListControl : PropertySelectMultipleControlBase
    {
        private static readonly log4net.ILog Logger = log4net.LogManager.GetLogger
            (System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        private List<int> CategorgyIds;

        protected override void SetupEditControls()
        {
            Category parentCategory = null;
            var definition = PageDefinition.Load(PropertyData.PageDefinitionID);

            if (!string.IsNullOrEmpty(definition.HelpText))
            {
                parentCategory = Category.Find(definition.HelpText);
            }

            if (parentCategory == null)
            {
                parentCategory = Category.Find(Name);
            }

            if (parentCategory == null)
            {
                parentCategory = Category.GetRoot();
            }

            CategorgyIds = GetCategoryIds(PropertyData.Value.ToString());

            foreach (Category  category in parentCategory.Categories)
            {
                var li = new ListItem(category.Description, category.ID.ToString(CultureInfo.InvariantCulture));
                li.Selected = CategorgyIds.Any(c => c == category.ID);
                EditControl.Items.Add(li);
            }
        }

        private List<int> GetCategoryIds(string categories)
        {
            if (string.IsNullOrEmpty(categories)) return null;

            var categoryIdList = new List<int>(); 

            try
            {
                categoryIdList.AddRange(categories.Split(',').Select(id => Convert.ToInt32(id)));
            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }

            return categoryIdList;
        }

        public override void ApplyEditChanges()
        {
            base.ApplyEditChanges();

            try
            {
                var categoryIdList = new List<string>();
                foreach (ListItem li in EditControl.Items)
                {
                    if (li.Selected)
                    {
                        var categoryId = Category.Find(Convert.ToInt32(li.Value)).ID;
                        categoryIdList.Add(categoryId.ToString());
                    }
                }

                PropertyData.Value = String.Join(",", categoryIdList);  
            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }
        }
    }
}