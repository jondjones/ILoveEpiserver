<%@ Page Language="c#" Codebehind="VppListingPlugin.aspx.cs" AutoEventWireup="False" Inherits="AdminPages.VppListingPlugin" Title="Vpp Listing Plugin" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title>Logged In Users</title>
    
    <style>
        th, td
        {
            border: 1px solid black;
            padding: 10px;
        }
    </style>
    
</head>
<body>
    
      <form id="Form1" runat="server">
       
       <asp:ListView ID="vppContents" runat="server" SelectMethod="GetVppContents" ItemType="AdminPages.VppFiles">
            <LayoutTemplate>
                
                <table>
                    <tr>
                        <th>VPP Location</th>
                        <th>Virtual File Path</th>
                    </tr> 
                    <tr runat="server" id="itemPlaceholder" />
                </table>

            </LayoutTemplate>
            <ItemTemplate>
                <tr>
                    <td><%# Item.VppPath %></td>
                    <td><%# Item.VirtualPath %></td>
                </tr>
            </ItemTemplate>
           
        </asp:ListView>

    </form>

</body>
</html>