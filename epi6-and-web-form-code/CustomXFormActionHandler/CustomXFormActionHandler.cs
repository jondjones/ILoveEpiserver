using System;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Net.Mime;
using System.Text;
using System.Web.Mvc;
using System.Xml.Linq;
using EPiServer;
using EPiServer.Core;
using EPiServer.ServiceLocation;
using EPiServer.Web.Mvc.XForms;
using EPiServer.XForms;
using EPiServer.XForms.Util;
using EPiServer.Data.Dynamic;

namespace Example
{
    public class CustomXFormActionHandler : XFormPageUnknownActionHandler
    {
        public new ActionResult HandleAction(Controller controller)
        {
            XForm xForm = this.GetXForm(controller);
            if (xForm == null)
            {
                return null;
            }

            var xFormPostedData = this.GetXFormPostedData(controller, this.ActionName);

            // This part reads in specific elements and adds in basic custom validation
            var formName = xFormPostedData.XFormFragments.FirstOrDefault(f => f.Reference == "formName");
            var elementInForm = xFormPostedData.XFormFragments.FirstOrDefault(f => f.Reference == "elementInForm");

            if (formName == null || elementInForm == null || string.IsNullOrEmpty(elementInForm.Value))
            {
                controller.ModelState.AddModelError("elementInForm", "Value must be entered");
            }

            if (controller.ModelState.IsValid && ProcessXFormAction(controller, xFormPostedData))
            {
                return InvokeSuccessAction(xForm, xFormPostedData, controller);
            }

            return InvokeFailedAction(xForm, xFormPostedData, controller);
        }

        protected override bool ProcessXFormAction(System.Web.Mvc.Controller controller, EPiServer.XForms.Util.XFormPostedData post)
        {
            var xFormData = new XFormPageHelper().GetXFormData(controller, post);
            var xform = XForm.CreateInstance(xFormData.FormId);

            if (xform != null && xFormData.GetValue("formName").Equals("Yes", StringComparison.OrdinalIgnoreCase))
            {
                var from = post.SelectedSubmit.Sender;
                var to = post.SelectedSubmit.Receiver;
                PerformCustomAction(xFormData, post.SelectedSubmit.Subject, to, from);
             }

            return base.ProcessXFormAction(controller, post);
        }

        private void PerformCustomAction(XFormData data, string subject, string to, string from)
        {
            var doc = new XDocument(new XDeclaration("1.0", "UTF-8", "yes"));
            XNamespace xsi = "http://www.w3.org/2001/XMLSchema-instance";

            // This part uses the xform data to create a custom email with the data as an attachment
            var import = new XElement("Import", new XAttribute(XNamespace.Xmlns + "xsi", xsi));
            import.Add(new XElement("ElementInForm", data.GetValue("elementInForm")));
            doc.Add(import);

            var mailMessage = new MailMessage
            {
                BodyEncoding = Encoding.UTF8,
                SubjectEncoding = Encoding.UTF8,
                IsBodyHtml = false,
                Body = import.ToString(),
                Subject = subject,
            };

            mailMessage.From = new MailAddress(from);
            mailMessage.To.Add(to);

            var customXml = new MemoryStream();
            doc.Save(customXml);
            customXml.Position = 0;

            Attachment xml = new Attachment(customXml, "example.xml", MediaTypeNames.Text.Xml);
            mailMessage.Attachments.Add(xml);
            new SmtpClient().Send(mailMessage);
        }
    }
}