using System.Web.UI.WebControls;
using EPiServer.Web.PropertyControls;

namespace Jondjones.com.Example
{
    public class AlignmentControl : PropertyStringControl
    {
        private DropDownList _alignmentControl;

        public override void CreateEditControls()
        {
            _alignmentControl = new DropDownList();

            // Could change to dynamically add these, in this example it's always static
            _alignmentControl.Items.Add(new ListItem("Right Align", "img-right01"));
            _alignmentControl.Items.Add(new ListItem("Left Align", "img-left01"));
 
            ApplyControlAttributes(_alignmentControl);
            Controls.Add(_alignmentControl);
            SetupEditControls();
        }

        protected override void SetupEditControls()
        {
            if (!string.IsNullOrEmpty((string)AlignmentList.Value))
            {
                _alignmentControl.SelectedIndex = _alignmentControl.Items.IndexOf(_alignmentControl.Items.FindByValue((string)AlignmentList.Value));
            }
        }

        public override void ApplyEditChanges()
        {
            AlignmentList.Value = _alignmentControl.SelectedItem.Value;
        }

        public AlignmentList AlignmentList
        {
            get
            {
                return PropertyData as AlignmentList;
            }
        }
    }
}