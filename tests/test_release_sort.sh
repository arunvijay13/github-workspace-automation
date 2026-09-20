#!/bin/bash
set -Eeuo pipefail
sort_release_branches(){
  awk '{
    b=$0; split(b,p,"-"); split(p[3],v,".");
    major=v[1]; minor=v[2]; if(minor=="") minor=0;
    printf "%010d %010d %010d %s\n",p[1],major,minor,b
  }' | sort -k1,1nr -k2,2nr -k3,3nr | awk '{print $4}'
}
result="$(printf '%s\n' 2026-release-7.1 2026-release-7.10 2026-release-7.2 2026-release-8.0 | sort_release_branches | head -n1)"
[[ "$result" == "2026-release-8.0" ]]
echo "test_release_sort.sh: PASS"
