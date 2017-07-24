<%@ Page Language="C#" AutoEventWireup="true" Inherits="System.Web.UI.Page" %>
<%@ Import Namespace="System.Collections.Generic" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Write(
            "<!DOCTYPE html>" +
            "<html xmlns=\"http://www.w3.org/1999/xhtml\">" +
            "<head><title></title></head>"
        );
        Response.Write(
            "<body>" +
            "<table border=\"1\">" +
            "<tr><th>KEY</th><th>VALUE</th><th>MULTIPLE VALUES</th></tr>"
        );
        try
        {
            NameValueCollection variables = Request.ServerVariables;
            String[] keys = variables.AllKeys;
            for (var i = 0; i < keys.Length; i++)
            {
                String[] values = variables.GetValues(keys[i]);
                for (var j = 0; j < values.Length; j++)
                {
                    var row = string.Format("<tr><td>{0}</td><td>{1}</td><td>{2}</td></tr>", keys[i], values.Length > 0 ? Server.HtmlEncode(values[j]) : "N/A", values.Length > 1 ? "Y" : "N");
                    Response.Write(row);
                }
            }
        }
        catch (Exception ex)
        {
            Response.Write(ex.Message);
        }
        Response.Write(
            "</table>" +
            "</body>" +
            "</html>"
        );
    }
</script>
