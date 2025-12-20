function comp(a1, a2, i) {
    h1 = i <= n1
    h2 = i <= n2
    t1 = h1 ? a1[i] : ""
    t2 = h2 ? a2[i] : ""

    if (eq && h1 && h2 && t1 == t2) {
        common = common t1
    } else {
        eq = 0
        if (h1) diff1 = diff1 t1
        if (h2) diff2 = diff2 t2
    }
}

BEGIN {
    expac = "/usr/bin/expac -S \"%r %n\" -"

    l_repo = 0
    l_pkg = 0
    l_v1 = 0
    l_v2 = 0

    colors[""] = 37
    colors["core"] = 33
    colors["extra"] = 32
    colors["multilib"] = 36
}

{
    pkgs[NR] = $1
    v1_arr[NR] = $2
    v2_arr[NR] = $4

    if (length($1) > l_pkg) { l_pkg = length($1) }
    if (length($2) > l_v1) { l_v1 = length($2) }
    if (length($4) > l_v2) { l_v2 = length($4) }

    print $1 |& expac
}

END {
    if (NR == 0) exit

    close(expac, "to")
    while ((expac |& getline) > 0) {
        repo_map[$2] = $1
        if (length($1) > l_repo) { l_repo = length($1) }
    }
    close(expac)

    l_pkgname = l_repo + length("/") + l_pkg

    for (j = 1; j <= NR; j++) {
        p = pkgs[j]
        r = p in repo_map ? repo_map[p] : "local"
        sort_proxy[j] = r "/" p SUBSEP j
    }

    n = asort(sort_proxy)

    for (i = 1; i <= n; i++) {
        split(sort_proxy[i], parts, SUBSEP)
        orig_idx = parts[2]

        pkg = pkgs[orig_idx]
        v1 = v1_arr[orig_idx]
        v2 = v2_arr[orig_idx]
        repo = pkg in repo_map ? repo_map[pkg] : "local"
        color = repo in colors ? colors[repo] : colors[""]

        eq = 1
        common = ""
        diff1 = ""
        diff2 = ""

        n1 = split(v1, arr1, /[-.:]/, sep1)
        n2 = split(v2, arr2, /[-.:]/, sep2)

        comp(sep1, sep2, 0)
        for (k = 1; k <= (n1 > n2 ? n1 : n2); k++) {
            comp(arr1, arr2, k)
            comp(sep1, sep2, k)
        }

        printf "\033[1;35m%*d\033[0m  ", length(NR), (n - i + 1)
        printf "\033[1;%sm%s\033[0m\033[1m/%-*s\033[0m  ", color, repo, (l_pkgname - length(repo) - 1), pkg
        printf "%*s\033[31m%s\033[0m  ", (l_v1 - length(diff1)), common, diff1
        printf "%*s\033[32m%s\033[0m\n", (l_v2 - length(diff2)), common, diff2
    }
}
