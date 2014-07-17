require 'labwiki/plugin/gimi/gimi'

LabWiki::PluginManager.register :gimi, {
  version: LabWiki.plugin_version([1, 0, 'pre'], __FILE__),
  selector: lambda do ||
  end,
  on_session_init: lambda do
    LabWiki::Gimi.instance.on_session_init
  end,
  on_session_close: lambda do
  end,
  widgets: [],
  renderers: {},
  resources: File.join(File.dirname(__FILE__), 'resource'),
  #config_ru: File.join(File.dirname(__FILE__), 'config.ru'),
  #global_js: 'js/experiment_global.js'
}
