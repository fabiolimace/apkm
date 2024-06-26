#!/usr/bin/awk -f

#
# Converts markdown to HTML
#
# Implemented the basic syntax without nesting (list within list etc).
#
# See:
# 
# * https://spec.commonmark.org
# * https://markdown-it.github.io
# * https://www.javatpoint.com/markdown
# * https://www.markdownguide.org/cheat-sheet
# * https://www.markdownguide.org/extended-syntax
# * https://pandoc.org/MANUAL.html#pandocs-markdown
# * https://www.dotcms.com/docs/latest/markdown-syntax
# * https://www.codecademy.com/resources/docs/markdown
# * https://daringfireball.net/projects/markdown/syntax
# * https://quarto.org/docs/authoring/markdown-basics.html
# * https://docs.github.com/en/get-started/writing-on-github
# * https://fuchsia.dev/fuchsia-src/contribute/docs/markdown
# * https://www.ibm.com/docs/en/SSYKAV?topic=train-how-do-use-markdown
# * https://www.knowledgehut.com/blog/web-development/what-is-markdown
# * https://www.ionos.com/digitalguide/websites/web-development/markdown/
# * https://learn.microsoft.com/en-us/contribute/content/markdown-reference
# * https://developer.mozilla.org/en-US/docs/MDN/Writing_guidelines/Howto/Markdown_in_MDN
# * https://confluence.atlassian.com/bitbucketserver/markdown-syntax-guide-776639995.html
# * https://learn.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance?view=azure-devops
# * https://medium.com/analytics-vidhya/the-ultimate-markdown-guide-for-jupyter-notebook-d5e5abf728fd

function ready() {
    return at("root") || at("blockquote") || at("li");
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

function push(tag, attr) {

    ++id;
    ++idx;

    stk[idx] = tag;
    stk_attr[idx] = attr;
    
    open_tag(id);
    
    # close <br> and <hr>
    if (at("br") || at("hr")) {
        pop();
    }
    
    return id;
}

function pop() {
    if (empty()) {
        return "";
    }
    
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

    if (at("pre") || at("code")) {
        buf = escapes(buf);
    } else {
        # the order matters
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
        
        if (str ~ /^[^ ]+[ ][ ]+$/) {
            str = str "<br />"
        }
    }

    if (buf == "") {
        buf = str;
    } else {
        buf=buf sep str;
    }
}

function open_tag(id) {

    write();
    
    if (at("br") || at("hr")) {
        printf "<%s />\n", peek();
        return;
    }

    if (at("pre") || at("code")) {
        open_pre(id, peek_attr_value("title"));
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
    
    if (at("br") || at("hr")) {
        # do nothing.
        # already closed.
        return;
    }
    
    if (at("pre") || at("code")) {
        close_pre();
        return;
    }
    
    printf "</%s>\n", peek();
}

function peek_attr_value(key,    found) {
    attr = " " peek_attr();
    if (match(attr, "[ ]" key "='[^']*'") > 0) {
        found = substr(attr, RSTART, RLENGTH);
        match(found, "='[^']*'");
        return substr(found, RSTART + 2, RLENGTH - 3);
    }
    return "";
}

function open_pre(id, title) {
    printf "<pre>";
    printf "<div class='pre-head'>";
    printf "<span>%s</span>", title;
    printf "%s", buttons(id);
    printf "</div>";
    printf "<div class='pre-body' id='%s'>", id;
    return;
}

function close_pre() {
    printf "</div>";
    printf "</pre>";
    return;
}

function buttons(id,    style, clipboard, wordwrap) {
    collapse = "<button onclick='collapse(" id ")' title='Toggle collapse' class='pre-button'>↕</button>";
    clipboard = "<button onclick='wordwrap(" id ")' title='Toggle word-wrap' class='pre-button'>⏎</button>";
    wordwrap = "<button onclick='clipboard(" id ")' title='Copy to clipboard' class='pre-button'>📋</button>";
    return clipboard collapse wordwrap;
}

function make(tag, text, attr) {
        
        if (text == "") {
            return "<" tag " " attr "/>";
        } else {
            return "<" tag " " attr ">" text "</" tag ">";
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

# '<...>'
function escapes(buf) {

    regex = "<[^<>]+>"
    while (buf ~ regex) {
        buf = apply_escape(buf, regex);
    }
    
    return buf;
}

function apply_escape(buf, regex,    out, found, arr) {
    
    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART + 1, RLENGTH - 2);
        
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

    regex = "<(http|ftp|[^@ ]+@)[^<> ]+>"
    while (buf ~ regex) {
        buf = apply_diamond(buf, regex);
    }
    
    return buf;
}

function apply_diamond(buf, regex,    out, found, arr) {
    
    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART + 1, RLENGTH - 2);
        
        if (found ~ /^(http|ftp)/) {
            push_link(id++, found);
            out = out substr(buf, 1, RSTART - 1);
            out = out make("a", found, "href='" found "'");
            out = out substr(buf, RSTART + RLENGTH);
            return out;
        } else if (found ~ /^[^@ ]+@/) {
            push_link(id++, "mailto:" found);
            out = out substr(buf, 1, RSTART - 1);
            out = out make("a", found, "href='mailto:" found "'");
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
function apply_link(buf, regex,    out, found, href, title, text, rstart, rlength) {
    
    text = ""
    href = ""
    title = ""
    
    if (match(buf, regex) > 0) {
    
        found = substr(buf, RSTART, RLENGTH);
        
        rstart = RSTART
        rlength = RLENGTH
        
        if (match(found, "\\[[^]]+\\]") > 0) {
            text = substr(found, RSTART + 1, RLENGTH - 2);
        }
        
        if (match(found, "\\]\\([^ ]+([ ]+\"[^\"]*\")?\\)") > 0) {
            href = substr(found, RSTART + 2, RLENGTH - 3);
        }
        
        if (match(href, "([ ]\"[^\"]*\")") > 0) {
            title = substr(href, RSTART + 2, RLENGTH - 3);
            href = substr(href, 1, RSTART - 1);
        }
        
        out = out substr(buf, 1, rstart - 1);
        out = out make("a", text, "href='" href "' title='" title "'");
        out = out substr(buf, rstart + rlength);
        
        push_link(id++, href, title, text);
        
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
        
        if (match(found, "\\]\\([^ ]+([ ]+\"[^\"]*\")?\\)") > 0) {
            src = substr(found, RSTART + 2, RLENGTH - 3);
        }
        
        if (match(src, "([ ]\"[^\"]*\")") > 0) {
            title = substr(src, RSTART + 2, RLENGTH - 3);
            src = substr(src, 1, RSTART - 1);
        }
        
        out = out substr(buf, 1, rstart - 1);
        out = out make("img", "", "alt='" alt "' src='" src "' title='" title "'");
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
        out = out make("a", "<sup>[" found "]<sup>", "href='#foot-" found "'");
        out = out substr(buf, RSTART + RLENGTH);
        
        return out;
    }
    
    return buf;
}

# TODO: harmonize variable names for reference-style links and footnotes.
function reflinks(buf) {

    regex = "\\[[^]]+\\][ ]?\\[[^]]+\\]"
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
        
        split(found, arr, "\\][ ]?\\[");
        label = substr(arr[1], 2);
        id = substr(arr[2], 1, length(arr[2]) - 1);
        
        out = out substr(buf, 1, RSTART - 1);
        out = out make("a", label, "href='#link-" id "'");
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
    print "    h1 { font-size: 2.0rem; }";
    print "    h2 { font-size: 1.5rem; }";
    print "    h3 { font-size: 1.2rem; }";
    print "    h4 { font-size: 1.2rem; }";
    print "    h5 { font-size: 0.8rem; }";
    print "    h6 { font-size: 0.8rem; }";
    print "    h1, h2 {";
    print "        padding-bottom: 0.5rem;";
    print "        border-bottom: 2px solid var(--gray);";
    print "    }";
    print "    h1, h2, h3, h4, h5, h6 {";
    print "        line-height: 1.4;";
    print "        font-style: normal;";
    print "        font-weight: bold;";
    print "        margin: 1.4rem 0 .5rem;";
    print "    }";
    print "    h3, h5 {";
    print "        font-weight: bold;";
    print "        font-style: normal;";
    print "    }";
    print "    h4, h6 {";
    print "        font-weight: normal;";
    print "        font-style: italic;";
    print "    }";
    print "    pre {";
    print "        overflow-x:auto;";
    print "        line-height: 1.5;";
    print "        border-radius: .4rem;";
    print "        font-family: monospace;";
    print "        background-color: var(--gray);";
    print "        border: 1px solid var(--dark-gray);";
    print "    }";
    print "    div.pre-head {";
    print "        height: 1.5rem;";
    print "        padding: 1rem;";
    print "        font-weight: bold;";
    print "        padding-top: 0.5rem;";
    print "        padding-bottom: 0.5rem;";
    print "        border-bottom: 1px solid var(--dark-gray);";
    print "    }";
    print "    div.pre-body {";
    print "        padding: 1rem;";
    print "    }";
    print "    button.pre-button {";
    print "        font-size: 100%; float: right;";
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
    print "    dt { font-weight: bold; }";
    print "    hr { border: 1px solid var(--dark-gray); }";
    print "    img { height: auto; max-width: 100%; }";
    print "    table { border-collapse: collapse; margin-bottom: 1.3rem; }";
    print "    th { padding: .7rem; border-bottom: 1px solid var(--black);}";
    print "    td { padding: .7rem; border-bottom: 1px solid var(--gray);}";
    print "</style>";
    
    print "<script>";
    print "    function clipboard(id) {";
    print "        var element = document.getElementById(id);";
    print "        navigator.clipboard.writeText(element.textContent);";
    print "    }";
    print "    function wordwrap(id) {";
    print "        var element = document.getElementById(id);";
    print "        if (element.style.whiteSpace != 'pre-wrap') {";
    print "            element.style.whiteSpace = 'pre-wrap';";
    print "        } else {";
    print "            element.style.whiteSpace = 'pre';";
    print "        }";
    print "    }";
    print "    function collapse(id) {";
    print "        var element = document.getElementById(id);";
    print "        if (element.style.display != 'none') {";
    print "            element.style.display = 'none';";
    print "        } else {";
    print "            element.style.display = 'block';";
    print "        }";
    print "    }";
    print "</script>"

    print "</head>";
    print "<body>";
}

function print_footer (    i, ref, href, title, text) {
    
    print "<footer>";
    
    if (link_count > 0 || footnote_count > 0) {
        print "<hr>";
    }
    
    if (link_count > 0) {
        print "<h6>LINKS</h6>";
        print "<ol>";
        for (i = 1; i <= link_count; i++) {
        
            ref = link_ref[i];
            href = link_href[i];
            title = link_title[i];
            
            if (title == "") {
                title = href;
            }
            
            print make("li", title " <a href='" href "' id='link-" ref "'>&#x1F517;</a>");
            
        }
        print "</ol>";
    }
    
    if (footnote_count > 0) {
        print "<h6>FOOTNOTES</h6>";
        print "<ol>";
        for (i = 1; i <= footnote_count; i++) {
        
            ref = footnote_ref[i];
            text = footnote_text[i];
            
            print make("li", text " <a href='#foot-" ref "' id='link-" ref "'>&#x1F517;</a>");
            
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
    
    blank = -1; # prepare to signal blank line
    
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
        if (stk[i] == "blockquote") break;
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

#===========================================
# TABULATIONS
#===========================================

{
    gsub("\t", "    ", $0); # replace tabas with 4 spaces
}

#===========================================
# BLANK LINES
#===========================================

# Blank line flag states:
#  0: not signaling blank line
# -1: preparing to signal blank line
#  1: signaling blank line

blank == 1 {
    blank = 0;
}

blank == -1 {
    blank = 1;
}

/^[ ]*$/ {
    if (!at("code")) {
        blank = -1;
        pop_p();
        pop_blockquote();
        next;
    }
}

#===========================================
# BLOCKQUOTE
#===========================================

function pop_blockquote() {

    if (!at("blockquote")) return;

    lv = level_blockquote();
    cp = count_prefix($0, blockquote_prefix);
    
    n = lv - cp;
    while (n-- > 0) {
        if (at("blockquote")) pop();
    }
}

$0 !~ blockquote_prefix {
    pop_blockquote();
}

$0 ~ blockquote_prefix {

    lv = level_blockquote();
    cp = count_prefix($0, blockquote_prefix);
    
    $0 = remove_prefix($0, blockquote_prefix);
    
    if (cp > lv) {
        n = cp - lv;
        while (n-- > 0) {
            pop_p();
            push("blockquote");
        }
    } else {
        n = lv - cp;
        while (n-- > 0) {
            pop();
        }
    }
    
    if ($0 ~ /^$/) {
        pop_until("blockquote");
    }
}

#===========================================
# LIST ITENS
#===========================================

function pop_p() {
    if (!ready()) pop();
}

function pop_list () {

    if (!at("li")) return;

    lv = level_list();
    cp = count_indent($0);
    
    n = lv - cp;
    while (n-- > 0) {
        if (stk[idx-1] == "li") pop();
        if (at("li")) pop();
        if (at("ol") || at("ul")) pop();
    }
}

function remove_list_indent (line) {

    n = level_list();
    while (n > 0) {
        sub(/^[ ]{4}/, "", line);
        n--;
    }
    
    return line;
}

$0 !~ ul_prefix && $0 !~ ol_prefix {

    temp = remove_list_indent($0);
    
    if (blank > 0) {
        pop_list();
    }
    
    $0 = temp;
}

function list_start(line) {
    sub("^[ ]+", "", line);
    match(line, "^[[:digit:]]+");
    return substr(line, RSTART, RLENGTH);
}

function push_li(tag, start) {

    if (tag == "ol") {
        if (start == "") {
            if (!at("ul") && !at("ol")) push(tag);
        } else {
            if (!at("ul") && !at("ol")) push(tag, "start='" start "'");
        }
    } else {
        if (!at("ul") && !at("ol")) push(tag);
    }
    
    push("li");
}

function parse_list_item(tag, prefix, start) {
    
    lv = level_list();
    cp = count_indent($0) + 1;
    
    $0 = remove_prefix($0, prefix);

    if (cp == lv) {
    
        pop_p();
        if (at("li")) pop();
        push_li(tag);
        append($0);
        
    } else if (cp > lv) {
        
        # add levels
        n = (cp - 1) - lv;
        while (n-- > 0) {
            push_li(tag);
        }
        
        push_li(tag, start);
        append($0);
        
    } else if (cp < lv) {
    
        # del levels
        n = lv - cp;
        while (n-- > 0) {
            pop_p();
            if (at("li")) pop();
            if (at("ol") || at("ul")) pop();
        }
        
        if (at("li")) pop();
        push_li(tag);
        append($0);
    }
}

$0 ~ ul_prefix {
    parse_list_item("ul", ul_prefix);
    next;
}

$0 ~ ol_prefix {

    # the user specifies
    # the starting number
    start = list_start($0);

    parse_list_item("ol", ol_prefix, start);
    next;
}

#===========================================
# CODE BLOCKS
#===========================================

/^```/ {

    if (!at("code")) {
    
        sub(/^`+/, "");
        title = $0;
        
        push("code", "title='" title "'");
        next;
    }
    
    pop();
    next;
}

at("code") {
    append($0);
    next;
}

/^[ ]{4}/ {

    if (!at("pre")) {
        push("pre");
    }

    sub("^[ ]{4}", "", $0);
    append($0);
    next;
}

#===========================================
# HEADING
#===========================================

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
    pop_p();
    next;
}

/^---+/ && at("p") {

    # <h2>
    $0 = undo();
    push("h2");
    append($0);
    pop_p();
    next;
}

/^[\x23]+[ ]+/ {
    
    match($0, "\x23+")
    n = RLENGTH > 6 ? 6 : RLENGTH
    
    # remove leading hashes
    $0 = substr($0, n + 1)
    # remove leading spaces
    sub(/^[ ]+/, "")

    pop_p();
    push("h" n);
    append($0);
    next;
}


#===========================================
# HORIZONTAL RULER
#===========================================

/^[*_-]{3,}[ ]*$/ {
    pop_p();
    push("hr");
    next;
}

#===========================================
# DEFINITION LIST
#===========================================

/^:/ {

    dd = substr($0, 2);
    
    if (at("p")) {
        dt = undo();
        push("dl");
        push("dt");
        append(dt);
        pop_p();
        push("dd");
        append(dd);
        next;
    }
    if (at("dd")) {
        pop_p();
        push("dd");
        append(dd);
        next;
    }
}

#===========================================
# TABLE
#===========================================

function set_table_aligns(line,    arr, regex, found, l, r, n) {

    delete table_aligns;
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
                push("td", "style='text-align:" table_aligns[i] ";'");
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

#===========================================
# FOOTNOTE
#===========================================

function push_footnote(ref, text) {
    footnote_count++
    footnote_ref[footnote_count] = ref;
    footnote_text[footnote_count] = styles(text);
}

/^[ ]*\[\^[^]]+\][:]/ {

    # ^[id]: note
    if (match($0, /\[\^[^]]+\][:]/) > 0) {
        
        ref = substr($0, RSTART + 2, RLENGTH - 4);
        text = substr($0, RSTART + RLENGTH);
        
        push_footnote(ref, text);
    }
    next;
}

#===========================================
# (REFERENCE STYLE) LINK
#===========================================

function push_link(ref, href, title, text) {
    link_count++;
    link_ref[link_count] = ref;
    link_href[link_count] = href;
    link_title[link_count] = title;
    link_text[link_count] = text;
}

/^[ ]*\[[^]]+\][:]/ {

    # ^[ref]: href
    # ^[ref]: href "title"
    # ^[ref]: href 'title'
    # ^[ref]: href (title)
    # ^[ref]: <href> "title"
    # ^[ref]: <href> 'title'
    # ^[ref]: <href> (title)
    if (match($0, /\[[^]]+\][:]/) > 0) {
        
        ref = substr($0, RSTART + 1, RLENGTH - 3);
        href = substr($0, RSTART + RLENGTH);
        
        if (match(href, "[ ](\"[^\"]*\"|'[^']*'|\\([^\\)]*\\))") > 0) {
            title = substr(href, RSTART + 2, RLENGTH - 3);
            href = substr(href, 1, RSTART - 1)
            
            # remove '<' '>'.
            if (match(href, "<[^>]+>") > 0) {
                href = substr(href, RSTART + 1, RLENGTH - 2);
            }
        }
        
        # remove leading spaces
        sub("^[ ]*", "", href);
        
        push_link(ref, href, title, title);
    }
    next;
}

#===========================================
# PARAGRAPH
#===========================================

/^.+$/ {
    if (ready()) {
        if (at("li")) {
            if (blank == 1) {
                push("p");
            }
        } else {
            push("p");
        }
    }
    append($0);
    next;
}

#===========================================
# THE END
#===========================================

END {

    pop_p();
    pop_list();
    pop_blockquote();
    
    print_footer();
}

