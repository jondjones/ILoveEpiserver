using EPiServer.Core;
using EPiServer.PlugIn;

namespace Example
{
    [PageDefinitionTypePlugIn(DisplayName = "Category Checkbox List")]
    public class PropertyCategoryCheckBoxList : PropertyMultipleValue
    {
        public override IPropertyControl CreatePropertyControl()
        {
            return new PropertyCategoryCheckBoxListControl();
        }
    }
}