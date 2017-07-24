using System.IO;
using System.Reflection;
using System.Web.Hosting;

namespace DevTools.AspNet
{
    public class EmbeddedResourceVirtualFile : VirtualFile
    {
        private readonly string _resourceName;

        public EmbeddedResourceVirtualFile(string virtualPath, string resourceName)
            : base(virtualPath)
        {
            _resourceName = resourceName;
        }

        public override Stream Open()
        {
            return Assembly.GetExecutingAssembly().GetManifestResourceStream(_resourceName);
        }
    }
}
