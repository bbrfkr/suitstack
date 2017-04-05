def blockinfile(insertafter,block,marker,content)
  marker_start = "### #{ marker } START ###\n"
  marker_end = "###  #{ marker } END  ###\n"
  insertafter += "\n"
  if not (content =~ /#{ Regexp.escape(marker_start + block + marker_end) }/)
    content.gsub!(/#{ Regexp.escape(marker_start) }.*#{ Regexp.escape(marker_end)}/m, "")
    content.gsub!(insertafter, insertafter + marker_start + block + marker_end)
  end
end
