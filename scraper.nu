#!/usr/bin/env nu
let page = (http get "https://hexcasting.hexxy.media/v/0.11.2/1.0/en_us/#patterns/readwrite@hexcasting:local")
let data = $page | str replace --all "\n" "" | parse --regex '<div id="[^"]*?@[^"]*?:([^"]*?)" class=""><h4 class="pattern-title">([^<\(]*?)(\(.*?\))<.*?data-string="([^"]*?)".*?data-start="([^"]*?)".*?<p>(.*?)</p>'
# todo: include the per_world boolean in the data
# todo: clean up the data with more regex
let data = $data | update capture1 {str replace --all '&#39;' "'"}
$data | explore
