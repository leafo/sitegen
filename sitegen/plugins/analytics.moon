import Plugin from require "sitegen.plugin"

class AnalyticsPlugin extends Plugin
  tpl_helpers: { "analytics" }

  analytics: (page, arg) =>
    code = arg[1]
    [[<script type="text/javascript">
  if (window.location.hostname != "localhost") {
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', ']]..code..[[');

    (function() {
      var ga = document.createElement('script'); ga.async = true;
      ga.src = 'https://www.googletagmanager.com/gtag/js?id=]]..code..[[';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
  }
</script>]]

