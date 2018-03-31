<%@ Page Language="c#" Codebehind="ExamplePlugin.aspx.cs" AutoEventWireup="False" Inherits="Example.AdminPlugin" Title="Example" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        The time is <%= GetTheTime() %>

        <asp:Button ID="Button1" runat="server" Text="Update" OnClick="UpdateTheTime" />

    </div>
    </form>
</body>
</html>