# The CHANGELOG.md section of -v version=x.y.z, wrapped lines joined:
# GitHub renders every newline in release notes as a line break.
/^## \[/ {
  if (found) exit
  found = index($0, "## [" version "] - ") == 1
  next
}
!found || (!started && $0 == "") { next }
/^  / { sub(/^ +/, ""); line = line " " $0; next }
{ if (started) print line; line = $0; started = 1 }
END { if (line != "") print line }
