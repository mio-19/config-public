#!/usr/bin/env python3
import json
import re
import sys


def safe_nix_id(s):
    """确保 Nix 属性名符合规范"""
    if re.match(r"^[a-zA-Z_][a-zA-Z0-9_-]*$", s):
        return s
    return f'"{s}"'


def resolve_ref(ref, nodes, root_key):
    """解析 flake.lock 中的路径式引用"""
    if isinstance(ref, str):
        return ref
    if isinstance(ref, list):
        curr = root_key
        for step in ref:
            curr_node = nodes.get(curr, {})
            curr_inputs = curr_node.get("inputs", {})
            if step not in curr_inputs:
                return None
            next_ref = curr_inputs[step]
            if isinstance(next_ref, str):
                curr = next_ref
            elif isinstance(next_ref, list):
                curr = resolve_ref(next_ref, nodes, root_key)
        return curr
    return None


def is_flake_false(node):
    orig = node.get("original", {})
    return orig.get("flake") is False


def build_url(node):
    """还原 Nix 识别的 URL"""
    orig = node.get("original", {})
    t = orig.get("type")

    if not t:
        orig = node.get("locked", {})
        t = orig.get("type")

    if not t:
        return '""'

    if t in ("github", "gitlab", "sourcehut"):
        host = orig.get("host")
        owner = orig.get("owner", "")
        repo = orig.get("repo", "")

        base = (
            f"gitlab:{host}/{owner}/{repo}"
            if t == "gitlab" and host
            else f"{t}:{owner}/{repo}"
        )
        ref = orig.get("ref")
        rev = orig.get("rev")

        if ref:
            base += f"/{ref}"
        elif rev and "original" not in node:
            base += f"/{rev}"

        if "dir" in orig:
            base += f"?dir={orig['dir']}"
        return f'"{base}"'

    elif t == "git":
        url = orig.get("url", "")
        base = (
            url if url.startswith("git://") or url.startswith("git+") else f"git+{url}"
        )
        if "ref" in orig:
            base += f"?ref={orig['ref']}"
        if "dir" in orig:
            base += f"&dir={orig['dir']}" if "?" in base else f"?dir={orig['dir']}"
        return f'"{base}"'

    elif t == "path":
        p = orig.get("path", "")
        return f'"path:{p}"' if not p.startswith("path:") else f'"{p}"'

    elif t == "tarball":
        return f'"{orig.get("url", "")}"'

    elif "url" in orig:
        return f'"{orig["url"]}"'

    return '""'


def get_follows(node_key, nodes, root_key, top_level_names, memo):
    """递归计算当前节点需要向外抛出的 follows 路径，支持穿透隐式依赖"""
    if node_key in memo:
        return memo[node_key]

    memo[node_key] = []  # 防御性防止死循环
    node = nodes.get(node_key, {})
    follows_list = []

    for local_name, child_ref in node.get("inputs", {}).items():
        child_key = resolve_ref(child_ref, nodes, root_key)
        if not child_key:
            continue

        # 如果这个子依赖也是一个顶层依赖，直接 follow
        if local_name in top_level_names:
            follows_list.append(([local_name], local_name))
        else:
            # 如果这个子依赖不提取，则往下穿透，寻找其内部是否有需要 follow 的顶层依赖
            child_follows = get_follows(
                child_key, nodes, root_key, top_level_names, memo
            )
            for sub_path, target in child_follows:
                follows_list.append(([local_name] + sub_path, target))

    memo[node_key] = follows_list
    return follows_list


def main():
    input_data = sys.stdin.read()
    if not input_data.strip():
        return

    try:
        lock_data = json.loads(input_data)
    except json.JSONDecodeError:
        sys.stderr.write("Error: Invalid JSON format from stdin.\n")
        sys.exit(1)

    nodes = lock_data.get("nodes", {})
    root_key = lock_data.get("root", "root")

    # 1. 广度优先遍历(BFS)，找到所有可达的 Node，并统计每个 `local_name` 的全局使用频率
    reachable_nodes = set()
    queue = [root_key]
    while queue:
        curr = queue.pop(0)
        if curr in reachable_nodes:
            continue
        reachable_nodes.add(curr)

        node = nodes.get(curr, {})
        for child_ref in node.get("inputs", {}).values():
            child_key = resolve_ref(child_ref, nodes, root_key)
            if child_key:
                queue.append(child_key)

    name_counts = {}
    for r_key in reachable_nodes:
        node = nodes.get(r_key, {})
        for local_name, child_ref in node.get("inputs", {}).items():
            if resolve_ref(child_ref, nodes, root_key):
                name_counts[local_name] = name_counts.get(local_name, 0) + 1

    # 2. 决定哪些名字应当提取到顶层 (所有的 root inputs 加上 全局被复用 >= 2 次的名字)
    top_level_names = set()
    root_inputs = nodes.get(root_key, {}).get("inputs", {})
    for name in root_inputs:
        if resolve_ref(root_inputs[name], nodes, root_key):
            top_level_names.add(name)

    for name, count in name_counts.items():
        if count > 1:
            top_level_names.add(name)

    # 3. 再进行一次 BFS，为所有 top_level_names 分配对应的 lock node (采用最近原则)
    global_inputs = {}
    queue = [(root_key, 0)]
    visited_nodes = set()

    while queue:
        curr_key, depth = queue.pop(0)
        if curr_key in visited_nodes:
            continue
        visited_nodes.add(curr_key)

        node = nodes.get(curr_key, {})
        for local_name, child_ref in node.get("inputs", {}).items():
            child_key = resolve_ref(child_ref, nodes, root_key)
            if not child_key:
                continue

            # 只有初次遇到且被标记为顶层的名字，才注册进 global_inputs
            if local_name in top_level_names and local_name not in global_inputs:
                global_inputs[local_name] = {
                    "node_key": child_key,
                    "depth": depth + 1,
                    "follows": [],
                }

            queue.append((child_key, depth + 1))

    # 4. 递归收集所有顶层模块需要的穿透 follows
    memo = {}
    for name, info in global_inputs.items():
        info["follows"] = get_follows(
            info["node_key"], nodes, root_key, top_level_names, memo
        )

    # ---------------- 5. 输出 Nix 格式 ----------------
    out = ["{"]
    current_depth = -1

    # 按照深度和名称排序
    sorted_items = sorted(global_inputs.items(), key=lambda x: (x[1]["depth"], x[0]))

    for name, info in sorted_items:
        depth = info["depth"]
        if depth != current_depth:
            if depth == 1:
                out.append("  # direct deps")
            elif depth == 2:
                out.append("  # shared indirect deps (depth 2)")
            else:
                out.append(f"  # shared indirect deps (depth {depth})")
            current_depth = depth

        node_key = info["node_key"]
        node = nodes.get(node_key, {})
        url_str = build_url(node)
        follows = info["follows"]
        is_flake = not is_flake_false(node)

        safe_name = safe_nix_id(name)

        if not follows and is_flake:
            out.append(f"  {safe_name}.url = {url_str};")
        else:
            out.append(f"  {safe_name} = {{")
            out.append(f"    url = {url_str};")
            if not is_flake:
                out.append("    flake = false;")

            # 按字母顺序打印 follows 避免混乱
            for path, tgt in sorted(follows, key=lambda x: (".".join(x[0]), x[1])):
                safe_path = ".".join(f"inputs.{safe_nix_id(p)}" for p in path)
                out.append(f'    {safe_path}.follows = "{tgt}";')
            out.append("  };")

    out.append("}")
    print("\n".join(out))


if __name__ == "__main__":
    main()
