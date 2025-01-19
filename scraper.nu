#!/usr/bin/env nu
def get_data [url: string] {
  let page = (http get $url)
  let data = $page 
    | str replace --all "\n" "" 
    | parse --regex '<div id="[^"]*?@[^"]*?:([^"]*?)" class=""><h4 class="pattern-title">([^<\(]*?)(\(.*?\))<.*?data-string="([^"]*?)".*?data-start="([^"]*?)".*?data-per-world="([^"]*?)".*?<p>(.*?)</p>'
    | rename name fullname signature pattern direction per-world description
    | update fullname {str replace --all '&#39;' "'"}
    | update direction {str upcase}
    | update per-world {into bool}
    | update description {
      $in
      | str replace --all --regex '<span[^>]*?>([^<]*?)</span>' '$1'
      | str replace --all --regex '<a[^>]*?>([^<]*?)</a>' '$1'
      | str replace --all '&#39;' "'"    
      | str replace --all --regex '<[/]?i>' '*'
    }
  return $data
}

get_data "https://hexcasting.hexxy.media/v/0.11.2/1.0/en_us/#patterns/readwrite@hexcasting:local" | explore
