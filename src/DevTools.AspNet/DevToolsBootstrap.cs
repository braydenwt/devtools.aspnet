using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.Hosting;

namespace DevTools.AspNet
{
    public class DevToolsBootstrap
    {
        public DevToolsBootstrap()
        {
        }

        private bool _enabled;

        private string _toolsUrl;

        public DevToolsBootstrap MapUrl(string url)
        {
            return MapUrl(() => url);
        }

        public DevToolsBootstrap MapUrl(Func<string> urlMapping)
        {
            if (urlMapping != null)
            {
                _toolsUrl = urlMapping();
            }

            return this;
        }

        public void Enable()
        {
            if (!_enabled)
            {
                try
                {
                    HostingEnvironment.RegisterVirtualPathProvider(new EmbeddedResourceVirtualPathProvider(_toolsUrl));
                    _enabled = true;
                }
                catch (Exception)
                { }
            }
        }
    }
}
