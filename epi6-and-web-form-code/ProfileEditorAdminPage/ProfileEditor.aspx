<%@ Page Language="c#" Codebehind="ProfileEditor.aspx.cs" AutoEventWireup="False" Inherits="Admin.ProfileEditor" %>
<%@ Import Namespace="EPiServer" %>


<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Profile Editor</title>
    </head>
    <body>
        

        <form id="form1" runat="server">
            
            <script type="text/javascript">
                
                function OpenFileDialog(displayTextboxId, displayImage)
                {
                    var browserselectionmode;
                    if (displayImage) {
                        browserselectionmode = 'browserselectionmode=image';
                    } else {
                        browserselectionmode = 'browserselectionmode=file';
                    }

                    var node = document.getElementById(displayTextboxId);
                    var dialogUrl = '<%= UriSupport.ResolveUrlFromUIBySettings("edit/FileManagerBrowser.aspx") %>?' + browserselectionmode + '&selectedfile=' + encodeURIComponent(node.value);

                    var linkAttributes = new Object();
                    var dialogArguments = linkAttributes;

                    var features = { width: 600, height: 412 };

                    var callbackArguments = new Object();
                    callbackArguments.value = displayTextboxId;

                    var callbackMethod = function(returnValue, callbackArgs) {
                        if (returnValue != undefined && returnValue != 0) {
                            var path = returnValue.items[0].path;
                            document.getElementById(callbackArguments.value).value = path;

                            EPi.DispatchEvent(callbackArgs, 'change');
                        } else {
                            Clear();
                        }
                    };

                    EPi.CreateDialog(
                        dialogUrl,
                        callbackMethod,
                        callbackArguments,
                        dialogArguments,
                        features);
                }

                function Clear() {
                    var textboxId = '<%= tbFilePath.ClientID %>';
                    var node = document.getElementById(textboxId);
                    node.value = '';
                }

            </script>
            
             <fieldset>
              
            <legend>
                
               Profile Editor

            </legend>
                 
              
            <div class="control-group">
                
                <asp:Label ID="userPickerLabel" runat="server" AssociatedControlID="userPicker" Text="Content Editors" CssClass="control-label" />   
                <div class="controls">
                    
                    <asp:DropDownList runat="server" ID="userPicker" AutoPostBack="True" SelectMethod="PopulateUserProfiles" DataValueField="Username" DataTextField="Username" AppendDataBoundItems="True"  OnSelectedIndexChanged="RefreshImage" >
                        <asp:ListItem Selected="True" Value="0">Select Profile</asp:ListItem>
                    </asp:DropDownList>

                </div>
                
            </div>

            <asp:Image runat="server" ID="profileImagePreview" Visible="False"/>
                   
            <div class="input-append">

                <asp:TextBox runat="server" ID="tbFilePath" ReadOnly="True" class="input-medium" />

                <input id="submitButton"
                       type="button"
                       value="..."
                       class="btn"
                       runat="server"
                    />
                <input  id="resetbutton"
                        type="button"
                        value="X"
                        class="btn btn-danger"
                        onclick=" Clear() "
                    />
            </div>
                 
            <div class="control-group">
                
                <asp:Button ID="updateProfileButton" runat="server" runat="server" OnClick="UpdateProfileImage" Text="Update Profile"/>
                
            </div>
              
          </fieldset>
       


        </form>

    </body>
</html>