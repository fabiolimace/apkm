#!/usr/bin/awk -f

#
# Converts markdown to HTML
#
# Implemented the basic syntax without nesting (list within list etc).
#
# See: https://www.markdownguide.org/cheat-sheet/
#

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

function pop(    tag) {
    tag = peek();
    if (!empty()) {
        close_tag();
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

function append(    str) {
    if (buf == "") {
        if (str ~ "\n") {
            str = substr(str, 2);
        }
        buf = str;
    } else {
        buf=buf " " str;
    }
}

function open_tag() {
    printf "<%s %s>\n", peek(), peek_attr();
}

function close_tag() {
    print_buf();
    printf "</%s>\n", peek()
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

function styles(buf) {

    buf = strong(buf);
    buf = em(buf);
    buf = code(buf);
    
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
    print ":root {\n";
    print "  --gray: #efefef;\n";
    print "  --black: #444;\n";
    print "  --dark-gray: #aaaaaa;\n";
    print "  --light-gray: #fafafa;\n";
    print "  --light-blue: #0969da;\n";
    print "  --light-yellow: #fafaaa;\n";
    print "}\n";
    print "html {\n";
    print "  font-size: 16px;\n";
    print "  max-width: 100%;\n";
    print "}\n";
    print "body {\n";
    print "  padding: 1rem;\n";
    print "  margin: 0 auto;\n";
    print "  max-width: 50rem;\n";
    print "  line-height: 1.8;\n";
    print "  font-family: sans-serif;\n";
    print "  color: var(--black);\n";
    print "}\n";
    print "p {\n";
    print "  font-size: 1rem;\n";
    print "  margin-bottom: 1.3rem;\n";
    print "}\n";
    print "a, a:visited { color: var(--black); }\n";
    print "a:hover, a:focus, a:active { color: var(--light-blue); }\n";
    print "h1 { font-size: 3rem; }\n";
    print "h2 { font-size: 2.1rem; }\n";
    print "h3 { font-size: 1.6rem; }\n";
    print "h4 { font-size: 1.4rem; }\n";
    print "h5 { font-size: 1.2rem; }\n";
    print "h6{ font-size: 1rem; }\n";
    print "h1, h2, h3 {\n";
    print "  padding-bottom: 0.5rem;\n";
    print "  border-bottom: 2px solid var(--gray);\n";
    print "}\n";
    print "h1, h2, h3, h4, h5, h6 {\n";
    print "  line-height: 1.4;\n";
    print "  font-weight: inherit;\n";
    print "  margin: 1.4rem 0 .5rem;\n";
    print "}\n";
    print "pre {\n";
    print "  padding: 1rem;\n";
    print "  overflow-x:auto;\n";
    print "  line-height: 1.5;\n";
    print "  border-radius: .4rem;\n";
    print "  font-family: monospace;\n";
    print "  border: 1px solid var(--dark-gray);\n";
    print "  background-color: var(--gray);\n";
    print "}\n";
    print "code {\n";
    print "  padding: 0.3rem;\n";
    print "  border-radius: .2rem;\n";
    print "  font-family: monospace;\n";
    print "  background-color: var(--gray);\n";
    print "}\n";
    print "mark {\n";
    print "  padding: 0.3rem;\n";
    print "  border-radius: .2rem;\n";
    print "  background-color: var(--light-yellow);\n";
    print "}\n";
    print "blockquote {\n";
    print "  margin: 1.5rem;\n";
    print "  padding: 1rem;\n";
    print "  border-radius: .4rem;\n";
    print "  background-color: var(--light-gray);\n";
    print "  border-left: 12px solid var(--gray);\n";
    print "}\n";
    print "hr { border: 2px solid var(--gray); }\n";
    print "img { height: auto; max-width: 100%; }\n";
    print "table { border-collapse: collapse; margin-bottom: 1.3rem; }\n";
    print "th { padding: .7rem; border-bottom: 1px solid var(--black);}\n";
    print "td { padding: .7rem; border-bottom: 1px solid var(--gray);}\n";
    print "</style>";
    
    print "<script>";
    print "function clipboard(id) {";
    print "  // Get the text field";
    print "  var copyText = document.getElementById(id);";
    print "  // Copy the text inside the text field, without the icon";
    print "  var textContent = copyText.textContent.replace('📋', '')";
    print "  navigator.clipboard.writeText(textContent);";
    print "}";
    print "</script>"
    
    print "</head>";
    print "<body>";
}

function print_footer() {
    print "</body>"
    print "</html>"
}

BEGIN {

    id=0;
    
    buf=""

    idx=0
    stk[0]="root";
    stk_attr[0]="";
    
    print_header();
}


/^[ ]*$/ {
    
    while (!empty()) {
        pop();
    }
    
    next;
}

/^===*[ ]*/ {

    # <h1>
    if (peek() == "p") {
        $0 = buf
        buf = ""
        pop();
        push("h1");
        append($0)
        pop();
    }
    
    next;
}

/^---*[ ]*/ {

    # <hr>
    if (empty()) {
        print make_tag("hr");
    }

    # <h2>
    if (peek() == "p") {
        $0 = buf
        buf = ""
        pop();
        push("h2");
        append($0)
        pop();
    }
    
    next;
}

/^\x23+[ ]+/ {

    match($0, "\x23+")
    n = RLENGTH > 6 ? 6 : RLENGTH

    if (empty()) {
    
        # remove leading hashes
        $0 = substr($0, n + 1)
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("h" n)
    }
    
    if (peek() == "h" n) {
        append($0)
    }
    next;
}

/^>[ ]+/ {

    if (empty()) {
    
        # remove leading hashes
        $0 = substr($0, 2)
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("blockquote")
    }
    
    if (peek() == "blockquote") {
        append($0)
    }
    
    next;
}

/^[ ]{4}[ ]*/ {

    if (empty()) {
    
        id++;
        
        push("pre", "id", id)
        
        button="<button onclick='clipboard(" id ")' title='Copy to clipboard' style='float: right;'>📋</button>";
        append("\n" button);
    }
    
    if (peek() == "pre") {
        
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        append("\n" $0)
    }
    
    next;
}

/^[ ]*\*[ ]+/ {

    if (peek() == "li") {
        pop();
    }
    
    if (peek() == "ul") {
    
        # remove leading spaces
        sub(/^[ ]+/, "")
        # remove leading star
        $0 = substr($0, index($0, " "))
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("li");
        
        append($0);
    }
    
    if (empty()) {
    
        # remove leading spaces
        sub(/^[ ]+/, "")
        # remove leading star
        $0 = substr($0, index($0, " "))
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("ul");
        push("li");
        
        append($0);
    }
    
    next;
}

/^[ ]*[[:digit:]]+\.[ ]+/ {

    if (peek() == "li") {
        pop();
    }
    
    if (peek() == "ol") {
    
        # remove leading spaces
        sub(/^[ ]+/, "")
        # remove leading star
        $0 = substr($0, index($0, " "))
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("li");
        
        append($0);
    }
    
    if (empty()) {
    
        # remove leading spaces
        sub(/^[ ]+/, "")
        # remove leading star
        $0 = substr($0, index($0, " "))
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("ol");
        push("li");
        
        append($0);
    }
    
    next;
}

/^.+/ {
    if (empty()) {
        push("p")
    }
    
    if (!empty()) {
        append($0)
    }
}

END {
    print_footer();
}
