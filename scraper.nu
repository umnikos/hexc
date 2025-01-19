#!/usr/bin/env nu
def get_data [url: string] {
  let page = (http get $url)
  # let page = open --raw test.txt
  let data = $page 
    | str replace --all "\n" "" 
    | str replace --all --regex "='([^']*?)'" '="$1"'
    | parse --regex '<div id="[^"]*?@[^"]*?:([^"]*?)"[^>]*?>.*?<h4[^>]*?>([^<\(]*?)(\(.*?\))?<.*?data-string="([^"]*?)".*?data-start="([^"]*?)".*?data-per-world="?([^"]*?)"?\s*>.*?<p>(.*?)</p>'
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

let urls = [
  [modname url];
  # [oreironaut "https://oneironaut.hexxy.media/v/0.2.0/1.0/en_us/#patterns"]
  # [hexgloop "https://hexgloop.hexxy.media/v/latest/main/en_us/"] # 63
  [hexcasting "https://hexcasting.hexxy.media/v/0.11.2/1.0/en_us/#patterns/readwrite@hexcasting:local"] # 181
  [hexal "https://talia-12.github.io/Hexal/"] # 89
  [hexcassettes "https://miyucomics.github.io/hexcassettes/v/1.1.3/1.0.0/en_us/"] # 7 (100%)
  [hexcellular "https://hexcellular.hexxy.media/v/1.0.3/1.0.0/en_us/"] # 3 (100%)
  [hexdebug "https://hexdebug.hexxy.media/v/0.2.2+1.20.1/1.0/en_us/"] # 4 (100%)
  [hexical "https://hexical.hexxy.media/v/1.5.0/1.0.0/en_us/"] # 194
  [hextweaks "https://walksanatora.github.io/HexTweaks/"] # 15
]

let full_data = $urls | each {get_data $in.url} | flatten
$full_data | explore
echo ($full_data | length)
