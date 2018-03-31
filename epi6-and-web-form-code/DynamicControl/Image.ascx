<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Image.ascx.cs" Inherits="Jondjones.com.Example.ImageDisplay" %>

    <figure id="fig" runat="server" Visible="False">
        
        <asp:Image runat="server" ID="imageToDisplay" />

        <figcaption runat="server" id="figcaption" Visible="False">

            <asp:Literal runat="server" ID="FigureCaption" />
            
        </figcaption>

    </figure>





