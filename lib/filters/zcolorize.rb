require 'nokogiri'

class ZColorize < Nanoc3::Filters::ColorizeSyntax
  identifier :zcolorize

  def run content, params = {}
    syntax = params[:syntax] || :html
    case syntax
    when :html
      klass = Nokogiri::HTML
    when :xml, :xhtml
      klass = Nokogiri::XML
    else
      raise RuntimeError, "unknown syntax: #{syntax.inspect} (expected :html or :xml)"
    end

    # Colorize
    doc = klass.fragment(super)
    doc.css('pre > code').each do |element|
      element.parent.replace("<div class=\"highlight\">" + element.parent.to_s + "</div>")
    end

    method = "to_#{syntax}".to_sym
    doc.send(method, :encoding => 'UTF-8')
  end
end
