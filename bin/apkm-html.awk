#!/usr/bin/awk -f

#
# Converts markdown to HTML
#
# Implemented the basic syntax without nesting (list within list etc).
#
# See: https://www.markdownguide.org/cheat-sheet/
#

function blank() {
    return buf == "";
}

function ready() {
    return (peek() == "root" || peek() == "blockquote" || peek() == "li")
}

function empty() {
    return idx == 0
}

function peek() {
    return stk[idx]
}

function peek_attr() {
    return stk_attr[idx]
}

function push(tag, key1, val1, key2, val2,    keyval1, keyval2) {

    if (key1 != "") {
        keyval1 = " " key1 "='" val1 "'";
    }

    if (key2 != "") {
        keyval2 = " " key2 "='" val2 "'";
    }

    stk[++idx] = tag
    stk_attr[idx] = keyval1 keyval2
    
    open_tag()
}

function pop() {
    close_tag();
    return unpush();
}

function unpush(    tag) {
    tag = peek();
    if (!empty()) {
        delete stk_attr[idx]
        delete stk[idx--]
    }
    return tag
}

function print_buf() {

    buf = styles(buf);
    buf = images(buf);
    buf = links(buf);

    if (buf != "") {
        print buf;
    }
    buf = "";
}

function append(str, sep) {

    if (peek() == "pre" || peek() == "code") {
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

function open_tag(    tag, attr) {

    id++
    print_buf();

    if (peek() == "pre") {
        printf "<%s id='%s'>", "pre", id;
        printf "%s", buttons(id);
        return;
    }
    
    if (peek() == "code") {
        printf "<%s id='%s'>", "pre", id;
        printf "%s", buttons(id);
        return;
    }
    
    printf "<%s%s>\n", peek(), peek_attr();
}

function close_tag() {

    print_buf();
    
    if (peek() == "code") {
        printf "</%s>", "pre";
        return;
    }
    
    if (peek() == "pre") {
        printf "</%s>", "pre";
        return;
    }
    
    printf "</%s>\n", peek();
}

function buttons(id,    style, clipboard, wordwrap) {
    style = "float: right; font-size: 1.3rem;"
    clipboard = "<button onclick='wordwrap(" id ")' title='Toggle word-wrap' style='" style "'>⏎</button>"
    wordwrap = "<button onclick='clipboard(" id ")' title='Copy to clipboard' style='" style "'>📋</button>"
    return clipboard wordwrap;
}

function make_tag(tag, text, key1, val1, key2, val2,    keyval1, keyval2) {

        if (key1 != "") {
            keyval1 = " " key1 "='" val1 "'";
        }
        
        if (key2 != "") {
            keyval2 = " " key2 "='" val2 "'";
        }
        
        if (text == "") {
            return "<" tag keyval1 keyval2 " />";
        } else {
            return "<" tag keyval1 keyval2 " >" text "</" tag ">";
        }
}

function em(buf) {

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

function code(buf) {

    while (buf ~ "`[^`]+`") {
        buf = apply_style(buf, "`", 1, "code");
    }
    
    return buf;
}

function superfix(buf) {

    while (buf ~ "\\^[^\\^]+\\^") {
        buf = apply_style(buf, "\\^", 1, "sup");
    }
    
    return buf;
}

function subfix(buf) {

    while (buf ~ "~[^~]+~") {
        buf = apply_style(buf, "~", 1, "sub");
    }
    
    return buf;
}

function strike(buf) {

    while (buf ~ "~~[^~]+~~") {
        buf = apply_style(buf, "~~", 2, "del");
    }
    
    return buf;
}

function ins(buf) {

    while (buf ~ "\\+\\+[^\\+]+\\+\\+") {
        buf = apply_style(buf, "\\+\\+", 2, "ins");
    }
    
    return buf;
}

function mark(buf) {

    while (buf ~ "==[^=]+==") {
        buf = apply_style(buf, "==", 2, "mark");
    }
    
    return buf;
}

function styles(buf) {

    buf = strong(buf);
    buf = em(buf);
    buf = code(buf);
    buf = strike(buf);
    buf = ins(buf);
    buf = mark(buf);
    buf = superfix(buf);
    buf = subfix(buf);
    
    return buf;
}

# one style at a time
function apply_style(str, char, len, tag,    out, found) {
    
    regex = char "[^" char "]+" char
    
    if (match(str, regex) > 0) {
    
        found = substr(str, RSTART + len,   RLENGTH - 2*len);
        
        out = out substr(str, 1, RSTART - 1);
        out = out make_tag(tag, found);
        out = out substr(str, RSTART + RLENGTH);
        
        return out;
    }
    
    return str;
}

function links(buf) {

    regex = "\\[[^]]+\\]\\([^)]*\\)"
    while (buf ~ regex) {
        buf = apply_link(buf, regex);
    }
    
    return buf;
}

# one link at a time
# ![label](http://example.com)
# <a href="http://example.com">label</a>
function apply_link(str, regex,    out, found, arr, href, label) {
    
    if (match(str, regex) > 0) {
    
        found = substr(str, RSTART + len,   RLENGTH - 2*len);
        
        split(found, arr, "\\]\\(");
        label = substr(arr[1], 2);
        href = substr(arr[2], 1, length(arr[2]) - 1);
        
        out = out substr(str, 1, RSTART - 1);
        out = out make_tag("a", label, "href", href);
        out = out substr(str, RSTART + RLENGTH);
        
        return out;
    }
    
    return str;
}

function images(buf) {

    regex = "!\\[[^]]+\\]\\([^)]*\\)"
    while (buf ~ regex) {
        buf = apply_image(buf, regex);
    }
    
    return buf;
}

# one image at a time
# ![a label](image.png)
# <img src="image.png" alt="a label" />
function apply_image(str, regex,    out, found, arr, href, label) {
    
    if (match(str, regex) > 0) {
    
        found = substr(str, RSTART + len,   RLENGTH - 2*len);
        
        split(found, arr, "\\]\\(");
        label = substr(arr[1], 3);
        href = substr(arr[2], 1, length(arr[2]) - 1);
        
        out = out substr(str, 1, RSTART - 1);
        out = out make_tag("img", "", "src", href, "alt", label);
        out = out substr(str, RSTART + RLENGTH);
        
        return out;
    }
    
    return str;
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
    print "    a, a:visited { color: var(--black); }";
    print "    a:hover, a:focus, a:active { color: var(--light-blue); }";
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

function print_footer() {
    print "</body>"
    print "</html>"
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
    while (!empty() && peek() != tag) {
        pop();
    }
}

function level(tag,   i, n) {
    n = 0;
    for (i = idx; i > 0; i--) {
        if (stk[i] == tag) {
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

    if (peek() != "code") {
        pop_until("root");
        next;
    }
}

#===========================================
# CONTAINER ELEMENTS
#===========================================

$0 ~ blockquote_prefix {

    if (peek() == "li") {
        $0 = remove_indent($0);
    }

    lv = level("blockquote");
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

function process_list_item(tag, prefix) {

    lv = level(tag) - 1;
    cp = count_indent($0);
    
    $0 = remove_prefix($0, prefix);

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
        
        push(tag);
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
    process_list_item("ul", ul_prefix);
}

$0 ~ ol_prefix {
    process_list_item("ol", ol_prefix);
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

peek() == "li" {
    $0 = remove_indent($0);
}

/^[ ]{4}/ && peek() != "code" && peek() != "li" {

    if (peek() != "pre") {
        push("pre");
    }

    sub("^[ ]{4}", "", $0);
    append($0);
    next;
}

/^```/ {

    if (peek() != "code") {
        push("code");
        next;
    }
    
    pop();
    next;
}

function rewind() {
    # revert
    $0 = buf
    buf = ""
    unpush();
}

/^===+/ {

    # <h1>
    if (peek() == "p") {
        rewind();
        push("h1");
        append($0)
        pop();
    }
    
    next;
}

/^---+/ && peek() != "table" {

    # <hr> or <h2>
    if (peek() == "p") {
        rewind();
        push("h2");
        append($0)
        pop();
    } else {
        print make_tag("hr");
    }
    
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

/\|[ ]?/ {
    
    if (peek() != "table") {
    
        push("table");
        push("tr");
        
        n = split($0, arr, /\|/);
        for(i = 0; i < n; i++) {
            push("th");
            append(arr[i]);
            pop();
        }
        pop();
        next;
    }
    
    if (peek() == "table") {
    
        if ($0 ~ /[ ]*---/) {
            next;
        }
    
        push("tr");
        
        n = split($0, arr, /\|/);
        for(i = 0; i < n; i++) {
            push("td");
            append(arr[i]);
            pop();
        }
        pop();
        next;
    }
}

/^.+/ && peek() == "li" {
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
    print_footer();
}
