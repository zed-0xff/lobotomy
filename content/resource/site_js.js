// Persnikity Pygmentize

var MetaPygmentize = {
  
  process: function() {
    this.convert('nb', 'n',   ['id','name']);
    this.convert('nb', 'c1',  ['self']);
    this.convert('n',  'nb',  ['new']);
    this.convert('o',  'k',   ['*','&','+','/','=']);
    this.convert('nx', 'k',   ['$','$$']);
    this.convert('k',  'kjs', ['this']);
    this.convert('kp', 'sr',  ['public','private','protected']);
  },
  
  arrayInclude: function(array, obj) {
    var i = array.length;
    while (i--) {
      if (array[i] === obj) { return true; }
    }
    return false;
  },
  
  convert: function(fromClass, toClass, texts) {
    var spans = $('div.highlight span.' + fromClass);
    spans.each(function(s){
      var span = $(s);
      var text = span.text();
      var target = MetaPygmentize.arrayInclude(texts,text);
      if (target) { span.attr('class',toClass); };
    });
  }
  
}

// MetaSkills Namespace

var MetaSkills = {
  
  appendContentForAppleTvNavigation: function() {
    $('#page nav a').append('<span></span>');
  }
  
};


// Document Loads

$(document).ready(function(){
  MetaSkills.appendContentForAppleTvNavigation();
  MetaPygmentize.process();
})


