using EPiServer.Core;
using EPiServer.PlugIn;
using System;

namespace Jondjones.com.Example
{
    /// <summary>
    /// Custom PropertyData implementation
    /// </summary>
    [Serializable]
    [PageDefinitionTypePlugIn(DisplayName = "Dropdown list for image alignment ")]
    public class AlignmentList : PropertyString
    {
        public override IPropertyControl CreatePropertyControl()
        {
            return new AlignmentControl();
        }

    }
}