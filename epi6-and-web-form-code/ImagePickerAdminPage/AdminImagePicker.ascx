<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="AdminImagePicker.ascx.cs" Inherits="UserControls.AdminImagePicker" %>
<%@ Register TagPrefix="asp" Namespace="System.Web.UI.HtmlControls" Assembly="System.Web, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" %>

<script type="text/javascript">
    function OpenFileDialog(displayTextboxId, displayImage)
    {
        var browserselectionmode;
        if (displayImage)
        {
            browserselectionmode = 'browserselectionmode=image';
        }
        else
        {
            browserselectionmode = 'browserselectionmode=file';
        }
        
        var node = document.getElementById(displayTextboxId);
        var dialogUrl = '<%=EPiServer.UriSupport.ResolveUrlFromUIBySettings("edit/FileManagerBrowser.aspx")%>?' + browserselectionmode + '&selectedfile=' + encodeURIComponent(node.value);

        var linkAttributes = new Object();
        var dialogArguments = linkAttributes;
        
        var features = { width: 600, height: 412 };
        
        var callbackArguments = new Object();
        callbackArguments.value = displayTextboxId;

        var callbackMethod = function (returnValue, callbackArgs)
        {
            if (returnValue != undefined && returnValue != 0)
            {
                var path = returnValue.items[0].path;
                document.getElementById(callbackArguments.value).value = path;

                EPi.DispatchEvent(callbackArgs, 'change');
            }
            else {
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
        node.value ='';
    }
</script>
       
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
            onclick="Clear()"
        />
</div>



    


