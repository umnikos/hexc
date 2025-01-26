#!/usr/bin/env nu
def get_data [url: string] {
  let page = (http get $url)
  # let page = open --raw test.txt
  let data = $page 
    | str replace --all "\n" "" 
    | str replace --all --regex "='([^']*?)'" '="$1"'
    | str replace --all --regex '</p>[^<>]*?(</div>[^<>]*?)?(<br />[^<>]*?)?<p>' ' '
    | parse --regex '<div id="[^"]*?@[^"]*?:([^"]*?)"[^>]*?>.*?<h4[^>]*?>([^<\(]*?) ?(?:\((.*?)\))?<.*?data-string="([^"]*?)".*?data-start="([^"]*?)".*?data-per-world="?([^"]*?)"?\s*>.*?<p>(.*?)</p>'
    | rename name fullname signature pattern direction perworld description
    | update fullname {str replace --all '&#39;' "'"}
    | update direction {str upcase}
    | update perworld {into bool}
    | update description {
      $in
      | str replace --all --regex '<span[^>]*?>([^<]*?)</span>' '$1'
      | str replace --all --regex '<a[^>]*?>([^<]*?)</a>' '$1'
      | str replace --all '&#39;' "'"    
      | str replace --all --regex '<[/]?i>' '*'
      | str replace --all '&#34;' '"'
    }
  return $data
}

let urls = [
  [modname url];
  # [hexgloop "https://hexgloop.hexxy.media/v/latest/main/en_us/"] # 63
  [hex "https://hexcasting.hexxy.media/v/0.11.2/1.0/en_us/#patterns/readwrite@hexcasting:local"] # 181
  [hexal "https://talia-12.github.io/Hexal/"] # 89
  [hexcassettes "https://miyucomics.github.io/hexcassettes/v/1.1.3/1.0.0/en_us/"] # 7 (100%)
  [hexcellular "https://hexcellular.hexxy.media/v/1.0.3/1.0.0/en_us/"] # 3 (100%)
  [hexdebug "https://hexdebug.hexxy.media/v/0.2.2+1.20.1/1.0/en_us/"] # 4 (100%)
  [hexical "https://hexical.hexxy.media/v/1.5.0/1.0.0/en_us/"] # 194
  [hextweaks "https://walksanatora.github.io/HexTweaks/"] # 15
  [oneironaut "https://oneironaut.hexxy.media/v/0.4.0/1.0/en_us/#patterns"] # 33
  [complexhex "https://complexhex.hexxy.media/v/latest/main/en_us/"]
]

let full_data = $urls | each {|req| get_data $req.url | insert mod $req.modname | move mod --before name} | flatten
$full_data | save -f symbols.json
