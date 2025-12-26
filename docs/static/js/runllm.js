document.addEventListener('DOMContentLoaded', function () {
  var script = document.createElement('script');
  script.type = 'module';
  script.id = 'runllm-widget-script';

  script.src = 'https://widget.runllm.com';

  var thisScript = document.querySelector('script[src$="js/runllm.js"]');
  var brandLogo = thisScript
    ? thisScript.src.replace(/js\/runllm\.js$/, 'images/favicon.ico')
    : '/favicon.ico';

  script.setAttribute('runllm-keyboard-shortcut', 'Mod+j'); // cmd-j or ctrl-j to open the widget.
  script.setAttribute('runllm-name', 'MLflow');
  script.setAttribute('runllm-position', 'BOTTOM_RIGHT');
  script.setAttribute('runllm-assistant-id', '116');
  script.setAttribute('runllm-theme-color', '#008ED9');
  script.setAttribute('runllm-brand-logo', brandLogo);
  script.setAttribute('runllm-community-type', 'slack');
  script.setAttribute('runllm-community-url', 'https://mlflow.org/slack');
  script.setAttribute('runllm-disable-ask-a-person', 'true');

  script.async = true;
  document.head.appendChild(script);
});
