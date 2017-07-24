using System;
using System.Linq;
using System.Reflection;
using System.Web;
using System.Web.Hosting;

namespace DevTools.AspNet
{
    public class EmbeddedResourceVirtualPathProvider : VirtualPathProvider
    {
        private string _toolsUrl;

        #region Constructors

        public EmbeddedResourceVirtualPathProvider()
        {
            _toolsUrl = ToAbsolute(Constants.DefaultToolsUrl);
        }

        public EmbeddedResourceVirtualPathProvider(string toolsUrl)
            : this()
        {
            if (!string.IsNullOrEmpty(toolsUrl))
            {
                _toolsUrl = ToAbsolute(toolsUrl);
            }
        }

        #endregion

        #region Overrides

        public override bool FileExists(string virtualPath)
        {
            if (IsEmbeddedResourcePath(virtualPath))
            {
                return !string.IsNullOrEmpty(GetEmbeddedResourceName(virtualPath));
            }

            return base.FileExists(virtualPath);
        }

        public override VirtualFile GetFile(string virtualPath)
        {
            if (IsEmbeddedResourcePath(virtualPath))
            {
                var resourceName = GetEmbeddedResourceName(virtualPath);
                return new EmbeddedResourceVirtualFile(virtualPath, resourceName);
            }

            return base.GetFile(virtualPath);
        }

        public override System.Web.Caching.CacheDependency GetCacheDependency(string virtualPath, System.Collections.IEnumerable virtualPathDependencies, DateTime utcStart)
        {
            if (IsEmbeddedResourcePath(virtualPath))
            {
                return null;
            }

            return base.GetCacheDependency(virtualPath, virtualPathDependencies, utcStart);
        }

        #endregion

        #region Private Methods

        private string GetEmbeddedResourceName(string virtualPath)
        {
            var allResourceNames = Assembly.GetExecutingAssembly().GetManifestResourceNames();

            var resourceName = ToResourceName(virtualPath);

            return allResourceNames.FirstOrDefault(rn => rn.Equals(resourceName));
        }

        private bool IsEmbeddedResourcePath(string virtualPath)
        {
            return virtualPath.StartsWith(_toolsUrl);
        }

        private string ToResourceName(string virtualPath)
        {
            return string.Format("{0}.{1}.{2}", Constants.DefaultNamespace, Constants.InternalToolsDirectory, virtualPath.Substring(_toolsUrl.Length).Replace('/', '.').TrimStart('.'));
        }

        private string ToAbsolute(string appRelativePath)
        {
            if (!VirtualPathUtility.IsAppRelative(appRelativePath))
            {
                throw new InvalidOperationException("Invalid path. Must be application relative path (starting with '~').");
            }

            return VirtualPathUtility.ToAbsolute(appRelativePath);
        }

        #endregion
    }
}
