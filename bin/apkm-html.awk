#!/usr/bin/awk -f

#
# Converts markdown to HTML
#
# Implemented the basic syntax without nesting (list within list etc).
#
# See:
# 
# * https://markdown-it.github.io
# * https://www.markdownguide.org/cheat-sheet
# * https://www.markdownguide.org/extended-syntax
#

function ready() {
    return at("root") || at("blockquote") || at("li");
}

function blank() {
    return buf == "";
}

function empty() {
    return idx == 0
}

function at(tag) {
    return peek() == tag ? 1 : 0;
}

function peek() {
    return stk[idx];
}

function peek_attr() {
    return stk_attr[idx];
}

function push(tag, attr1, val1, attr2, val2,    pair1, pair2) {

    if (attr1 != "") {
        pair1 = " " attr1 "='" val1 "'";
    }

    if (attr2 != "") {
        pair2 = " " attr2 "='" val2 "'";
    }

    stk[++idx] = tag;
    stk_attr[idx] = pair1 pair2;
    
    open_tag();
}

function pop() {
    close_tag();
    return unpush();
}

function unpush(    tag) {
    tag = peek();
    if (!empty()) {
        delete stk_attr[idx];
        delete stk[idx--];
    }
    return tag;
}

function write() {

    if (!at("pre") && !at("code")) {
        # the order matters
        buf = elements(buf);
        buf = diamonds(buf);
        buf = footnotes(buf);
        buf = images(buf);
        buf = links(buf);
        buf = reflinks(buf);
        buf = styles(buf);
    }

    if (buf != "") {
        print buf;
    }
    buf = "";
}

function append(str, sep) {

    if (at("pre") || at("code")) {
        if (sep == "") sep = "\n";
    } else {
        if (sep == "") sep = " ";
    }
    
    if (str ~ /[ ][ ]+$/) {
        str = str "<br />"
    }

    if (buf == "") {
        buf = str;
    } else {
        buf=buf sep str;
    }
}

function open_tag() {

    ++id;
    write();

    if (at("pre")) {
        printf "<%s id='%s'>", "pre", id;
        printf "%s", buttons(id);
        return;
    }
    
    if (at("code")) {
        printf "<%s id='%s'>", "pre", id;
        printf "%s", buttons(id);
        return;
    }
    
    if (at("h1") || at("h2") || at("h3")) {
        printf "<%s id='%s' %s>\n", peek(), id, peek_attr();
        return;
    }
    
    printf "<%s %s>\n", peek(), peek_attr();
}

function close_tag() {

    write();
    
    if (at("code")) {
        printf "</%s>", "pre";
        return;
    }
    
    if (at("pre")) {
        printf "</%s>", "pre";
        return;
    }
    
    printf "</%s>\n", peek();
}

function buttons(id,    style, clipboard, wordwrap) {
    style = "float: right; font-size: 1.3rem;";
    clipboard = "<button onclick='wordwrap(" id ")' title='Toggle word-wrap' style='" style "'>⏎</button>";
    wordwrap = "<button onclick='clipboard(" id ")' title='Copy to clipboard' style='" style "'>📋</button>";
    return clipboard wordwrap;
}

function make(tag, text, attr1, val1, attr2, val2, attr3, val3,    pair1, pair2, pair3) {

        if (attr1 != "") {
            pair1 = " " attr1 "='" val1 "'";
        }
        
        if (attr2 != "") {
            pair2 = " " attr2 "='" val2 "'";
        }
        
        if (attr3 != "") {
            pair3 = " " attr3 "='" val3 "'";
        }
        
        if (text == "") {
            return "<" tag pair1 pair2 pair3 " />";
        } else {
            return "<" tag pair1 pair2 pair3 " >" text "</" tag ">";
        }
}

function emphasis(buf) {

    while (buf ~ "_[^_]+_") {
        buf = apply_style(buf, "_", 1, "em");
    }

    while (buf ~ "\\*[^\\*]+\\*") {
        buf = apply_style(buf, "\\*", 1, "em");
    }
    
    return buf;
}

function strong(buf) {

    while (buf ~ "__[^_]+__") {
        buf = apply_style(buf, "__", 2, "strong");
    }
    
    while (buf ~ "\\*\\*[^\\*]+\\*\\*") {
        buf = apply_style(buf, "\\*\\*", 2, "strong");
    }
    
    return buf;
}

function snippet(buf) {

    while (buf ~ "`[^`]+`") {
        buf = apply_style(buf, "`", 1, "code");
    }
    
    return buf;
}

function superscript(buf) {

    while (buf ~ "\\^[^\\^]+\\^") {
        buf = apply_style(buf, "\\^", 1, "sup");
    }
    
    return buf;
}

function subscript(buf) {

    while (buf ~ "~[^~]+~") {
        buf = apply_style(buf, "~", 1, "sub");
    }
    
    return buf;
}

function deleted(buf) {

    while (buf ~ "~~[^~]+~~") {
        buf = apply_style(buf, "~~", 2, "del");
    }
    
    return buf;
}

function inserted(buf) {

    while (buf ~ "\\+\\+[^\\+]+\\+\\+") {
        buf = apply_style(buf, "\\+\\+", 2, "ins");
    }
    
    return buf;
}

function highlighted(buf) {

    while (buf ~ "==[^=]+==") {
        buf = apply_style(buf, "==", 2, "mark");
    }
    
    return buf;
}

function formula(buf) {

    while (buf ~ "\\$\\$[^\\$]+\\$\\$") {
        buf = apply_style(buf, "\\$\\$", 2, "code");
    }
    
    while (buf ~ "\\$[^\\$]+\\$") {
        buf = apply_style(buf, "\\$", 1, "code");
    }
    
    return buf;
}

function styles(buf) {

    buf = strong(buf);
    buf = emphasis(buf);
    buf = snippet(buf);
    buf = deleted(buf);
    buf = inserted(buf);
    buf = highlighted(buf);
    buf = superscript(buf);
    buf = subscript(buf);
    buf = formula(buf);
    
    return buf;
}

# one style at a time
function apply_style(buf, mark, len, tag,    out, found) {

    regex = mark "[^" mark "]+" mark
    
    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART + len, RLENGTH - 2*len);
        
        out = out substr(buf, 1, RSTART - 1);
        out = out make(tag, found);
        out = out substr(buf, RSTART + RLENGTH);
        
        return out;
    }
    
    return buf;
}

# escaped
# \'<...>'
function elements(buf) {

    regex = "\\\\<[^<>]+>"
    while (buf ~ regex) {
        buf = apply_elements(buf, regex);
        break;
    }
    
    return buf;
}

function apply_elements(buf, regex,    out, found, arr) {
    
    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART + 2, RLENGTH - 3);
        
        out = out substr(buf, 1, RSTART - 1);
        out = out "&lt;" found "&gt;"
        out = out substr(buf, RSTART + RLENGTH);
        return out;
    }
    
    return buf;
}

# <http...>
# <email@...>
function diamonds(buf) {

    regex = "<(http[^ ]|[^@ ]+@)[^<> ]+>"
    while (buf ~ regex) {
        buf = apply_diamonds(buf, regex);
    }
    
    return buf;
}

function apply_diamonds(buf, regex,    out, found, arr) {
    
    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART + 1, RLENGTH - 2);
        
        if (found ~ /https?/) {
            out = out substr(buf, 1, RSTART - 1);
            out = out make("a", found, "href", found);
            out = out substr(buf, RSTART + RLENGTH);
            return out;
        } else if (found ~ /@/) {
            out = out substr(buf, 1, RSTART - 1);
            out = out make("a", found, "href", "mailto:" found);
            out = out substr(buf, RSTART + RLENGTH);
            return out;
        } else {
            out = out substr(buf, 1, RSTART - 1);
            out = out "&lt;" found "&gt";
            out = out substr(buf, RSTART + RLENGTH);
            return out;
        }
    }
    
    return buf;
}

function links(buf) {

    # the only differende of [img] is the leading "!"
    regex = "\\[[^]]+\\]\\([^)]*([ ]\"[^\"]*\")*\\)"
    while (buf ~ regex) {
        buf = apply_link(buf, regex);
    }
    
    return buf;
}

# one link at a time
# [label](href "title")
# <a href="href" title="title">lable</a>
function apply_link(buf, regex,    out, found, href, title, label, rstart, rlength) {
    
    label = ""
    href = ""
    title = ""
    
    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART, RLENGTH);
        
        rstart = RSTART
        rlength = RLENGTH
        
        if (match(found, "\\[[^]]+\\]") > 0) {
            label = substr(found, RSTART + 1, RLENGTH - 2);
        }
        
        if (match(found, "\\([^)]*([ ]\"[^\"]*\")*\\)") > 0) {
            href = substr(found, RSTART + 1, RLENGTH - 2);
        }
        
        if (match(href, "([ ]\"[^\"]*\")") > 0) {
            title = substr(href, RSTART + 2, RLENGTH - 3);
            href = substr(href, 1, RSTART - 1);
        }
        
        out = out substr(buf, 1, rstart - 1);
        out = out make("a", label, "href", href, "title", title);
        out = out substr(buf, rstart + rlength);
        
        return out;
    }
    
    return buf;
}

function images(buf) {

    regex = "!\\[[^]]+\\]\\([^)]*([ ]\"[^\"]*\")*\\)"
    while (buf ~ regex) {
        buf = apply_image(buf, regex);
    }
    
    return buf;
}

# one image at a time
# ![alt](src "title")
# <img alt="alt" src="src" title="title" />
function apply_image(buf, regex,    out, found, src, title, alt, rstart, rlength) {
    
    alt = ""
    src = ""
    title = ""
        
    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART, RLENGTH);
        
        rstart = RSTART
        rlength = RLENGTH
        
        if (match(found, "\\[[^]]+\\]") > 0) {
            alt = substr(found, RSTART + 1, RLENGTH - 2);
        }
        
        if (match(found, "\\([^)]*([ ]\"[^\"]*\")*\\)") > 0) {
            src = substr(found, RSTART + 1, RLENGTH - 2);
        }
        
        if (match(src, "([ ]\"[^\"]*\")") > 0) {
            title = substr(src, RSTART + 2, RLENGTH - 3);
            src = substr(src, 1, RSTART - 1);
        }
        
        out = out substr(buf, 1, rstart - 1);
        out = out make("img", "", "alt", alt, "src", src, "title", title);
        out = out substr(buf, rstart + rlength);
        
        return out;
    }
    
    return buf;
}

function footnotes(buf) {

    regex = "\\[\\^[^]]+\\]"
    while (buf ~ regex) {
        buf = apply_footnote(buf, regex);
    }
    
    return buf;
}

# one footnote at a time
# ^[href]
# <a href="#href"><sup>[href]<sup></a>
function apply_footnote(buf, regex,    out, found) {

    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART + 2, RLENGTH - 3);
        
        out = out substr(buf, 1, RSTART - 1);
        out = out make("a", "<sup>[" found "]<sup>", "href", "#footnote-" found);
        out = out substr(buf, RSTART + RLENGTH);
        
        return out;
    }
    
    return buf;
}

# TODO: harmonize variable names for reference-style links and footnotes.
function reflinks(buf) {

    regex = "\\[[^]]+\\]\\[[^]]+\\]"
    while (buf ~ regex) {
        buf = apply_reflink(buf, regex);
    }
    
    return buf;
}

# one link at a time
# ^[label][id]
# <a href="#id">label</a>
function apply_reflink(buf, regex,    out, found, arr) {

    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART, RLENGTH);
        
        split(found, arr, "\\]\\[");
        label = substr(arr[1], 2);
        id = substr(arr[2], 1, length(arr[2]) - 1);
        
        out = out substr(buf, 1, RSTART - 1);
        out = out make("a", label, "href", "#footnote-" id);
        out = out substr(buf, RSTART + RLENGTH);
        
        return out;
    }
    
    return buf;
}

function print_header() {

    print "<!DOCTYPE html>";
    print "<html>";
    print "<head>";
    print "<title></title>";
    
    print "<style>";
    print "    :root {";
    print "        --gray: #efefef;";
    print "        --black: #444;";
    print "        --dark-gray: #aaaaaa;";
    print "        --light-gray: #fafafa;";
    print "        --dark-blue: #0000ff;";
    print "        --light-blue: #0969da;";
    print "        --light-yellow: #fafaaa;";
    print "    }";
    print "    html {";
    print "        font-size: 16px;";
    print "        max-width: 100%;";
    print "    }";
    print "    body {";
    print "        padding: 1rem;";
    print "        margin: 0 auto;";
    print "        max-width: 50rem;";
    print "        line-height: 1.8;";
    print "        font-family: sans-serif;";
    print "        color: var(--black);";
    print "    }";
    print "    p {";
    print "        font-size: 1rem;";
    print "        margin-bottom: 1.3rem;";
    print "    }";
    print "    a, a:visited { color: var(--light-blue); }";
    print "    a:hover, a:focus, a:active { color: var(--dark-blue); }";
    print "    h1 { font-size: 2.4rem; }";
    print "    h2 { font-size: 1.8rem; }";
    print "    h3 { font-size: 1.4rem; }";
    print "    h4 { font-size: 1.3rem; }";
    print "    h5 { font-size: 1.2rem; }";
    print "    h6 { font-size: 1.1rem; }";
    print "    h1, h2, h3 {";
    print "        padding-bottom: 0.5rem;";
    print "        border-bottom: 2px solid var(--gray);";
    print "    }";
    print "    h1, h2, h3, h4, h5, h6 {";
    print "        line-height: 1.4;";
    print "        font-weight: inherit;";
    print "        margin: 1.4rem 0 .5rem;";
    print "    }";
    print "    pre {";
    print "        padding: 1rem;";
    print "        overflow-x:auto;";
    print "        line-height: 1.5;";
    print "        border-radius: .4rem;";
    print "        font-family: monospace;";
    print "        background-color: var(--gray);";
    print "        border: 1px solid var(--dark-gray);";
    print "    }";
    print "    code {";
    print "        padding: 0.3rem;";
    print "        border-radius: .2rem;";
    print "        font-family: monospace;";
    print "        background-color: var(--gray);";
    print "    }";
    print "    mark {";
    print "        padding: 0.3rem;";
    print "        border-radius: .2rem;";
    print "        background-color: var(--light-yellow);";
    print "    }";
    print "    blockquote {";
    print "        margin: 1.5rem;";
    print "        padding: 1rem;";
    print "        border-radius: .4rem;";
    print "        background-color: var(--light-gray);";
    print "        border: 1px solid var(--dark-gray);";
    print "        border-left: 12px solid var(--dark-gray);";
    print "    }";
    print "    hr { border: 1px solid var(--gray); }";
    print "    img { height: auto; max-width: 100%; }";
    print "    table { border-collapse: collapse; margin-bottom: 1.3rem; }";
    print "    th { padding: .7rem; border-bottom: 1px solid var(--black);}";
    print "    td { padding: .7rem; border-bottom: 1px solid var(--gray);}";
    print "</style>";
    
    print "<script>";
    print "    function clipboard(id) {";
    print "        var copyText = document.getElementById(id);";
    print "        var textContent = copyText.textContent.replace(/[📋⏎]/g, '')";
    print "        navigator.clipboard.writeText(textContent);";
    print "    }";
    print "    function wordwrap(id) {";
    print "        var wordWrap = document.getElementById(id);";
    print "        if (wordWrap.style.whiteSpace != 'pre-wrap') {";
    print "            wordWrap.style.whiteSpace = 'pre-wrap';";
    print "        } else {";
    print "            wordWrap.style.whiteSpace = 'pre';";
    print "        }";
    print "    }";
    print "</script>"

    print "</head>";
    print "<body>";
}

function print_footer (    i, id, href, note, title) {

    print "<footer>";
    print "<hr>";
    
    if (link_count > 0) {
        print "<h6>LINKS</h6>";
        print "<ol>";
        for (i = 1; i <= link_count; i++) {
        
            id = link_id[i];
            href = link_href[i];
            title = link_title[i];
            
            print make("li", title " <a href='" href "'>&#x1F517;</a>", "id", "link-" id, "title", title);
            
        }
        print "</ol>";
    }
    
    if (footnote_count > 0) {
        print "<h6>FOOTNOTES</h6>";
        print "<ol>";
        for (i = 1; i <= footnote_count; i++) {
        
            href = footnote_id[i];
            note = footnote_text[i];
            
            print make("li", note " <a href='#footnote-" href "'>&#x1F517;</a>", "id", "footnote-" href);
            
        }
        print "</ol>";
    }
    
    print "</footer>";
    print "</body>";
    print "</html>";
}

BEGIN {

    buf=""

    idx=0
    stk[0]="root";
    stk_attr[0]="";

    blockquote_prefix = "^[ ]*>[ ]?";
    ul_prefix = "^([ ]{4})*[ ]{0,3}[*+-][ ]"
    ol_prefix = "^([ ]{4})*[ ]{0,3}[[:digit:]]+\\.[ ]"
    
    print_header();
}

function pop_until(tag) {
    while (!empty() && !at(tag)) {
        pop();
    }
}

function level_blockquote(   i, n) {
    n = 0;
    for (i = idx; i > 0; i--) {
        if (stk[i] == "blockquote") {
            n++;
        }
    }
    return n;
}

function level_list(   i, n) {
    n = 0;
    for (i = idx; i > 0; i--) {
        if (stk[i] == "ul" || stk[i] == "ol") {
            n++;
        }
    }
    return n;
}

function count_indent(line) {
    return count_prefix(line, "^[ ]{4}");
}

function count_prefix(line, prefix,    n) {
    n=0
    while (sub(prefix, "", line)) {
        n++;
    }
    return n;
}

function remove_indent(line) {
    return remove_prefix(line, "^[ ]{4}");
}

function remove_prefix(line, prefix) {

    # remove leading quote marks
    while (line ~ prefix) {
        sub(prefix, "", line);
    };
    
    return line;
}

/^$/ {

    if (!at("code")) {
        pop_until("root");
        next;
    }
}

#===========================================
# CONTAINER ELEMENTS
#===========================================

$0 ~ blockquote_prefix {

    if (at("li")) {
        $0 = remove_indent($0);
    }

    lv = level_blockquote();
    cp = count_prefix($0, blockquote_prefix);
    
    $0 = remove_prefix($0, blockquote_prefix);
    
    if (cp >= lv) {
        n = cp - lv;
        while (n-- > 0) {
            push("blockquote")
        }
    } else {
        n = lv - cp;
        while (n-- > 0) {
            pop()
        }
    }
    
    if ($0 ~ /^$/) {
        pop_until("blockquote");
    }
}

function list_start(line,    n) {
    sub("^[ ]+", "", line);
    match(line, "^[[:digit:]]+");
    if (RSTART == 0) {
        return 0;
    }
    return substr(line, RSTART, RLENGTH);
}

function parse_list_item(tag, prefix, start) {

    lv = level_list() - 1;
    cp = count_indent($0);
    
    $0 = remove_prefix($0, prefix);
    
    start = start != "" ? start : 1;

    if (cp == lv) {
        pop();
        push("li");
    } else if (cp > lv) {
        
        # add levels
        n = cp - lv - 1;
        while (n-- > 0) {
            push(tag);
            push("li");
        }
        
        if (tag == "ol") {
            push(tag, "start", start);
        } else {
            push(tag);
        }
        push("li");
        
    } else if (cp < lv) {
    
        # rem levels
        n = lv - cp;
        while (n-- > 0) {
            pop();
            pop();
        }
        
        pop();
        push("li");
    }
}

$0 ~ ul_prefix {
    parse_list_item("ul", ul_prefix);
}

$0 ~ ol_prefix {

    # the user specifies
    # the starting number
    start = list_start($0);

    parse_list_item("ol", ol_prefix, start);
}

#===========================================
# SIMPLE ELEMENTS
#===========================================

{
    gsub("\t", "    ", $0); # replace tabas with 4 spaces
}

/^$/ {
    next;
}

at("li") {
    $0 = remove_indent($0);
}

/^[ ]{4}/ && !at("code") && !at("li") {

    if (!at("pre")) {
        push("pre");
    }

    sub("^[ ]{4}", "", $0);
    append($0);
    next;
}

/^```/ {

    if (!at("code")) {
        push("code");
        next;
    }
    
    pop();
    next;
}

# undo last push
function undo(    tmp) {
    tmp = buf;
    buf = "";
    unpush();
    return tmp;
}

/^===+/ && at("p") {

    # <h1>
    $0 = undo();
    push("h1");
    append($0);
    pop();
    next;
}

/^---+/ && at("p") {

    # <h2>
    $0 = undo();
    push("h2");
    append($0);
    pop();
    next;
}

/^[*_-]{3,}[ ]*$/ {

    # <hr>
    print make("hr");
    next;
}

/^[\x23]+[ ]+/ {

    match($0, "\x23+")
    n = RLENGTH > 6 ? 6 : RLENGTH
    
    # remove leading hashes
    $0 = substr($0, n + 1)
    # remove leading spaces
    sub(/^[ ]+/, "")
    
    push("h" n);
    append($0);
    next;
}

function set_table_aligns(line,    arr, regex, found, l, r, n) {

    regex = "(:--[-]+:|:--[-]+|--[-]+:)";

    delete arr; # starts from 2
    n = split(line, arr, /\|/);
    for(i = 2; i < n; i++) {
    
        if (match(arr[i], regex) > 0) {
        
            found = substr(arr[i], RSTART, RLENGTH);
            
            l = substr(found, 1, 1);
            r = substr(found, RLENGTH, 1);
            
            if (l == ":" && r == ":") {
                table_aligns[i] = "center";
            } else if (l == ":" && r == "-") {
                table_aligns[i] = "left";
            } else if (l == "-" && r == ":") {
                table_aligns[i] = "right";
            } else {
                table_aligns[i] = "l:" l " r: " r;
            }
        }
    }
}

/^[ ]*\|.*\|[ ]*/ {
    
    if (!at("table")) {
    
        push("table");
        push("tr");
        
        delete arr; # starts from 2
        n = split($0, arr, /\|/);
        for(i = 2; i < n; i++) {
            push("th");
            append(arr[i]);
            pop();
        }
        pop();
        next;
    }
    
    if (at("table")) {
    
        if ($0 ~ /^[ ]*\|[ ]*([:]?--[-]+[:]?)[ ]*\|[ ]*/) {
            set_table_aligns($0);
            next;
        }
    
        push("tr");
        
        delete arr; # starts from 2
        n = split($0, arr, /\|/);
        for(i = 2; i < n; i++) {
        
            if (table_aligns[i] != "") {
                push("td", "style", "text-align: " table_aligns[i] ";");
            } else {
                push("td");
            }
            append(arr[i]);
            pop();
            
        }
        pop();
        next;
    }
}

/^[ ]*\[\^[^]]+\][:]/ {

    # ^[id]: note
    if (match($0, /\[\^[^]]+\][:]/) > 0) {
        
        footnote_count++
        footnote_id[footnote_count] = substr($0, RSTART + 2, RLENGTH - 4);
        footnote_text[footnote_count] = substr($0, RSTART + RLENGTH);
    }
    next;
}

/^[ ]*\[[^]]+\][:]/ {

    # ^[id]: href
    # ^[id]: href "title"
    # ^[id]: href 'title'
    # ^[id]: href (title)
    # ^[id]: <href> "title"
    # ^[id]: <href> 'title'
    # ^[id]: <href> ("title")
    if (match($0, /\[[^]]+\][:]/) > 0) {
        
        link_count++
        link_id[link_count] = substr($0, RSTART + 1, RLENGTH - 3);
        link_href[link_count] = substr($0, RSTART + RLENGTH);
        
        if (match(link_href[link_count], "[ ](\"[^\"]*\"|'[^']*'|\\([^\\)]*\\))") > 0) {
            link_title[link_count] = substr(link_href[link_count], RSTART + 2, RLENGTH - 3);
            link_href[link_count] = substr(link_href[link_count], 1, RSTART - 1)
            
            # remove '<' '>'.
            if (match(link_href[link_count], "<[^>]+>") > 0) {
                link_href[link_count] = substr(link_href[link_count], RSTART + 1, RLENGTH - 2);
            }
        }
        
        # remove leading spaces
        sub("^[ ]*", "", link_href[link_count]);
            
        if (link_title[link_count] == "") {
            link_title[link_count] = "&lt;" link_href[link_count] "&gt;";
        }
    }
    next;
}

/^.+/ && at("li") {
    if (!blank() && $0 != "") {
        push("p");
        append($0);
        pop();
        next;
    }
    append($0);
    next;
}

/^.+/ {
    if (ready()) {
        push("p");
    }
    append($0);
}

END {
    pop_until("root");
    print_footer();
}
