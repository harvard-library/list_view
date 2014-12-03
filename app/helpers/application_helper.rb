module ApplicationHelper
  def glyphicon(name, at_end = true)
    output = ''
    output << "&nbsp;" if at_end
    output << "<span class=\"glyphicon glyphicon-#{name}\"></span>"
    raw output
  end
end
