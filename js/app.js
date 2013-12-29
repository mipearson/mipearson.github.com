/* http://timkadlec.com/2013/01/windows-phone-8-and-device-width/ */
if (navigator.userAgent.match(/IEMobile\/10\.0/)) {
  var msViewportStyle = document.createElement("style");
  msViewportStyle.appendChild(
    document.createTextNode(
      "@-ms-viewport{width:auto!important}"
    )
  );
  document.getElementsByTagName("head")[0].
    appendChild(msViewportStyle);
}

