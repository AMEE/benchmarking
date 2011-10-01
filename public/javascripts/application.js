// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ajaxSend(function(event, request, settings) {
  if (typeof(AUTH_TOKEN) == "undefined") return;
  // settings.data is a serialized string like "foo=bar&baz=boink" (or null)
  settings.data = settings.data || "";
  settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(AUTH_TOKEN);
});

function renderLoadingGif(wrappedSet) {
  var template = $('.ajaxloader');
  wrappedSet.each(function(){
    $(this).html(template.clone().attr('class',null).css({display: 'inline'}));
  });
};

$(document).ready(function(){
  $('#contentarea').hide().fadeIn('slow');

  $("input[type='submit']").mouseenter(function() {
    $(this).css('cursor','pointer');
    }, function() {
    $(this).css('cursor','auto');
  });
});
