// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function renderLoadingGif(wrappedSet) {
  var template = $('.ajaxloader');
  wrappedSet.each(function(){
    $(this).html(template.clone().attr('class',null).css({display: 'inline'}));
  });
};

$(document).ready(function(){
  $('#contentarea').hide().fadeIn('slow');

  $("input[type='submit']").live('mouseenter',function() {
    $(this).css('cursor','pointer');
  }).live('mouseleave', function() {
    $(this).css('cursor','auto');
  });

  $(".selected-header").addClass('header-highlight');

  $(".header-link:not(.selected-header)").live('mouseenter',function() {
    $(this).addClass('header-highlight');
  }).live('mouseleave', function() {
    $(this).removeClass('header-highlight');
  });

});
