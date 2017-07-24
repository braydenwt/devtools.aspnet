<%@ Page Language="C#" AutoEventWireup="true" ViewStateMode="Disabled" Inherits="System.Web.UI.Page" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Reflection" %>
<%@ Import Namespace="System.Collections.Concurrent" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style>
        body {
            font-family: Arial;
        }
    </style>
</head>
<body>
    <div>
        <asp:Literal ID="currentTime" runat="server"></asp:Literal>
        <br />
        <asp:Literal ID="startup" runat="server"></asp:Literal>
    </div>
    <div>
        <asp:Literal ID="details" runat="server"></asp:Literal>
    </div>
    <script type="text/javascript">
        function getParameterByName(name) {
            name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
            var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
                results = regex.exec(location.search);
            return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
        }
        document.addEventListener("DOMContentLoaded", function (event) {
            var sortables = document.querySelectorAll('th[data-sortby]');
            sortables.forEach(function (elem) {
                var sortBy = elem.getAttribute('data-sortby');
                elem.onclick = function (event) {
                    event.preventDefault();
                    var tag = getParameterByName("tag");
                    window.location.href = window.location.pathname + "?tag=" + tag + "&sortby=" + sortBy;
                };
            });
        })
    </script>
</body>
</html>
<script runat="server">

    private static string QUERYSTRING_KEY_TOKEN = "tag";
    private static string QUERYSTRING_KEY_SORTBY = "sortby";
    private static ConcurrentDictionary<string, AssemblyStatus> assemblyStatusCache = new ConcurrentDictionary<string, AssemblyStatus>(StringComparer.OrdinalIgnoreCase);

    protected void Page_Load(object sender, EventArgs e)
    {
        startup.Text = string.Format("<span>Start time:</span><span>{0}</span>", System.Diagnostics.Process.GetCurrentProcess().StartTime.ToString("o"));
        currentTime.Text = string.Format("<span>Current time:</span><span>{0}</span>", DateTime.Now.ToString("o"));

        var assemblyFolder = AppDomain.CurrentDomain.RelativeSearchPath;
        if (string.IsNullOrWhiteSpace(assemblyFolder))
        {
            assemblyFolder = AppDomain.CurrentDomain.BaseDirectory;
        }

        StringBuilder body = new StringBuilder();
        body.AppendFormat("<tr><th data-sortby=\"name\"><a href=\"\">{0}</a></th><th>{1}</th><th data-sortby=\"build\"><a href=\"\">{2}</a></th><th data-sortby=\"write\"><a href=\"\">{3}</a></th></tr>",
            "Name",
            "Version",
            "Last Build Time",
            "Last Write Time");

        var rows = Directory.GetFiles(assemblyFolder, "*.dll")
                                .Select(file => GetStatus(file));

        // ugly
        var sortBy = GetSortByFromRequest(this.Context.Request).ToLowerInvariant();
        if (sortBy == "name")
            rows = rows.OrderBy(row => row.Name);
        else if (sortBy == "build")
            rows = rows.OrderBy(row => row.LastBuildTime);
        else if (sortBy == "write")
            rows = rows.OrderBy(row => row.LastWriteTime);

        var rowsHtml = rows.Select(row => row.ToTableRowHtml()).ToArray();

        StringBuilder sb = new StringBuilder(string.Format("<table border=\"1\">{0}</table>", body.Append(string.Concat(rowsHtml))));

        this.details.Text = sb.ToString();
    }

    private static AssemblyStatus GetStatus(string file)
    {
        return assemblyStatusCache.GetOrAdd(file, GetStatusCore);
    }

    private static AssemblyStatus GetStatusCore(string file)
    {
        try
        {
            var fileInfo = new FileInfo(file);
            var assembly = Assembly.Load(Path.GetFileNameWithoutExtension(file));
            var version = assembly.GetName().Version;
            var lastLinkTime = GetBuildDateTime(file);

            return new AssemblyStatus() { Name = fileInfo.Name, Version = version, LastBuildTime = lastLinkTime, LastWriteTime = fileInfo.LastWriteTime };
        }
        catch
        {
            // Squash any exceptions
        }

        return new AssemblyStatus() { Name = file };
    }

    #region Gets the build date and time (by reading the COFF header)

    /// <summary>
    /// http://msdn.microsoft.com/en-us/library/ms680313 
    /// </summary>
    private struct _IMAGE_FILE_HEADER
    {
        public ushort Machine;
        public ushort NumberOfSections;
        public uint TimeDateStamp;
        public uint PointerToSymbolTable;
        public uint NumberOfSymbols;
        public ushort SizeOfOptionalHeader;
        public ushort Characteristics;
    };

    private static DateTime GetBuildDateTime(string assemblyFile)
    {
        var buffer = new byte[Math.Max(System.Runtime.InteropServices.Marshal.SizeOf(typeof(_IMAGE_FILE_HEADER)), 4)];
        using (var fileStream = new FileStream(assemblyFile, FileMode.Open, FileAccess.Read))
        {
            fileStream.Position = 0x3C;
            fileStream.Read(buffer, 0, 4);
            fileStream.Position = BitConverter.ToUInt32(buffer, 0); // COFF header offset
            fileStream.Read(buffer, 0, 4); // "PE\0\0"
            fileStream.Read(buffer, 0, buffer.Length);
        }
        var pinnedBuffer = System.Runtime.InteropServices.GCHandle.Alloc(buffer, System.Runtime.InteropServices.GCHandleType.Pinned);
        try
        {
            var coffHeader = (_IMAGE_FILE_HEADER)System.Runtime.InteropServices.Marshal.PtrToStructure(pinnedBuffer.AddrOfPinnedObject(), typeof(_IMAGE_FILE_HEADER));

            return TimeZone.CurrentTimeZone.ToLocalTime(new DateTime(1970, 1, 1) + new TimeSpan(coffHeader.TimeDateStamp * TimeSpan.TicksPerSecond));
        }
        finally
        {
            pinnedBuffer.Free();
        }
    }

    #endregion

    private static string GetSortByFromRequest(HttpRequest request)
    {
        if (request.QueryString.AllKeys.Contains(QUERYSTRING_KEY_SORTBY, StringComparer.InvariantCultureIgnoreCase))
        {
            return request.QueryString[QUERYSTRING_KEY_SORTBY];
        }

        return string.Empty;
    }

    private class AssemblyStatus
    {
        public string Name { get; set; }

        public Version Version { get; set; }

        public DateTime LastBuildTime { get; set; }

        public DateTime LastWriteTime { get; set; }

        public string ToTableRowHtml()
        {
            return string.Format("<tr><td>{0}</td><td>{1}</td><td>{2:o}</td><td>{3:o}</td></tr>", Name, Version, LastBuildTime, LastWriteTime);
        }
    }
</script>
