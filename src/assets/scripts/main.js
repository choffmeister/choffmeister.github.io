/*eslint-env node,browser*/
$(document).ready(function () {
  var mail = atob('ZWQucmV0c2llbWZmb2hjQGxpYW0=').split('').reverse().join('');

  $('span.choffmeister-mail').each(function () {
    $(this).text(mail);
  });

  $('a.choffmeister-mail').each(function () {
    $(this).attr('href', 'mailto:' + mail);
    $(this).text(mail);
  });
});
