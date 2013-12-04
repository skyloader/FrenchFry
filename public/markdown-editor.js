$(document).ready(function() {
  function markdown_to_html() {
    var markdown = $("#editor-markdown").val();
    $.post(
      "/convert",
      { "markdown" : markdown },
      function(data) { $("#editor-html").html(data.html); },
      "json"
    );
  }

  // converting markdown if enter is pressed
  $("#editor-markdown").keyup(function(e) {
    if ( e.keyCode == 13 ) {
      console.log("enter key is pressed");
      console.log(e);
      markdown_to_html();
    };
  });

  // timer to converting markdown for each 10 sec
  var timer = setInterval(function() {
    markdown_to_html();
  }, 10000);

  // force converting markdown when page is loading
  markdown_to_html();

  // fix HTML area height
  $("#editor-html").height( $('#editor-markdown').height() + 7);

  // Save article
  $("#save-article").click(function() {
    var article_text = $("#editor-markdown").val();
    $.post(
      "",
      { "article"   : article_text }
    );
  });
});
