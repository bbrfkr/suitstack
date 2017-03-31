def blockinfile(insertafter,block,marker,content)
  marker_start = "### #{ marker } START ###\n"
  marker_end = "###  #{ marker } END  ###\n"
  insertafter += "\n"
  content.gsub!(/#{ Regexp.escape(insertafter) }#{ Regexp.escape(marker_start) }.*#{ Regexp.escape(marker_end)}/m, insertafter)
  content.gsub!(insertafter, insertafter + marker_start + block + marker_end)
end
