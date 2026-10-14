"""extract_curious.py KitClaude.rbxm out.rbxm: the pieces of your kit the Curious Door uses, in a Folder "CuriousKit".

    SkullDoor       DOORS' skeleton door (its skull lock, its leaf, its sparkles, its sound): the Infirmary's Wax_Door
    SkullDoorFrame  the frame round it (the Infirmary's DoorFrame)
    Chest           DOORS' locked chest (ChestBoxLocked: its lid, its lock, its animations)
    Padlock         DOORS' padlock of the stairwell's lockpick door
    SkeletonKey     DOORS' skeleton key (Jeff's shop's)
    Key             DOORS' key (the asset pack's)
    GoldPile        DOORS' gold
    CuriousLight    the Curious Light's sparkles and light (the kit's)
    CuriousGlow     the Curious Light of the Rooms' secret (its sparkles, its light, its shimmer)

Every property is copied exactly as the kit has it (the raw values, column by column), except the few types that
cannot be carried on their own: those go back to their defaults. Left out: scripts, remotes, saved animations
(AnimSaves) and bindable events."""
import struct
import sys

import lz4.block
import zstandard


def u32(v): return struct.pack("<I", v)
def rstr(b): return u32(len(b)) + b


def words(b, p, n, width=4):
    raw = b[p:p + n * width]
    return [int.from_bytes(bytes(raw[k * n + i] for k in range(width)), "big") for i in range(n)], p + n * width


def interleave(ws, width=4):
    raw = [w.to_bytes(width, "big") for w in ws]
    return bytes(raw[i][k] for k in range(width) for i in range(len(raw)))


def untransform(x):
    v = (x >> 1) ^ (-(x & 1) & 0xFFFFFFFF)
    return v - (1 << 32) if v & 0x80000000 else v


def transform(x): return ((x << 1) ^ (x >> 31)) & 0xFFFFFFFF


def read_refs(b, p, n):
    ws, p = words(b, p, n)
    out, acc = [], 0
    for w in ws:
        acc += untransform(w)
        out.append(acc)
    return out, p


def write_refs(refs):
    out, last = [], 0
    for r in refs:
        out.append(transform(r - last))
        last = r
    return interleave(out)


def read_str(b, p):
    n = struct.unpack_from("<I", b, p)[0]
    return b[p + 4:p + 4 + n], p + 4 + n


COLUMNS = {0x03: 1, 0x04: 1, 0x0B: 1, 0x12: 1, 0x06: 2, 0x0D: 2, 0x07: 4, 0x18: 4, 0x0C: 3, 0x0E: 3}
FIXED = {0x05: 8, 0x08: 24, 0x09: 1, 0x0A: 1, 0x14: 6, 0x17: 8, 0x02: 1}
SKIP = {0x19, 0x1C, 0x1E, 0x1F, 0x21, 0x22}


def split(t, b, p, n):
    """Per-instance cells for a column of n values, or None when the type is not carried."""
    if t in SKIP:
        return None
    if t in (0x01, 0x1D):
        out = []
        for _ in range(n):
            s, p = read_str(b, p)
            out.append(s)
        return out
    if t in FIXED:
        w = FIXED[t]
        return [b[p + i * w:p + (i + 1) * w] for i in range(n)]
    if t in COLUMNS:
        cols = []
        for _ in range(COLUMNS[t]):
            ws, p = words(b, p, n)
            cols.append(ws)
        return list(zip(*cols))
    if t == 0x10:
        rots = []
        for _ in range(n):
            if b[p] == 0:
                rots.append(b[p:p + 37]); p += 37
            else:
                rots.append(b[p:p + 1]); p += 1
        cols = []
        for _ in range(3):
            ws, p = words(b, p, n)
            cols.append(ws)
        return list(zip(rots, *cols))
    if t == 0x15 or t == 0x16:
        size = 12 if t == 0x15 else 20
        out = []
        for _ in range(n):
            k = struct.unpack_from("<I", b, p)[0]
            out.append(b[p:p + 4 + k * size]); p += 4 + k * size
        return out
    if t == 0x1A:
        return [(b[p + i], b[p + n + i], b[p + 2 * n + i]) for i in range(n)]
    if t == 0x1B:
        ws, p = words(b, p, n, 8)
        return ws
    if t == 0x13:
        refs, p = read_refs(b, p, n)
        return refs
    if t == 0x20:
        out = []
        for _ in range(n):
            start = p
            _, p = read_str(b, p)
            p += 3
            _, p = read_str(b, p)
            out.append(b[start:p])
        return out
    return None


def join(t, cells, remap):
    if t in (0x01, 0x1D):
        return b"".join(rstr(c) for c in cells)
    if t in FIXED or t in (0x15, 0x16, 0x20):
        return b"".join(cells)
    if t in COLUMNS:
        return b"".join(interleave([c[k] for c in cells]) for k in range(COLUMNS[t]))
    if t == 0x10:
        return b"".join(c[0] for c in cells) + b"".join(interleave([c[k] for c in cells]) for k in (1, 2, 3))
    if t == 0x1A:
        return bytes(c[0] for c in cells) + bytes(c[1] for c in cells) + bytes(c[2] for c in cells)
    if t == 0x1B:
        return interleave(cells, 8)
    if t == 0x13:
        return write_refs([remap.get(r, -1) for r in cells])
    raise ValueError(t)


def chunk(name, raw, compress=True):
    head = name.encode().ljust(4, b"\x00")
    if not compress:
        return head + u32(0) + u32(len(raw)) + u32(0) + raw
    packed = lz4.block.compress(raw, store_size=False)
    return head + u32(len(packed)) + u32(len(raw)) + u32(0) + packed


ROOTS = {2912: "SkullDoor", 3039: "SkullDoorFrame", 85809: "Chest", 94689: "Padlock", 9922: "SkeletonKey", 85043: "Key",
         10993: "GoldPile", 95243: "CuriousLight", 94048: "CuriousGlow"}
LEAVE = ("Script", "LocalScript", "ModuleScript", "RemoteEvent", "RemoteFunction", "BindableEvent", "KeyframeSequence")


def main(src, out):

    data = open(src, "rb").read()
    assert data[:8] == b"<roblox!"
    zd = zstandard.ZstdDecompressor()
    classes, cls_of, props, parent, order = {}, {}, {}, {}, []
    pos = 32
    while pos < len(data):
        name = data[pos:pos + 4].rstrip(b"\x00").decode()
        clen, ulen, _ = struct.unpack_from("<III", data, pos + 4)
        body = data[pos + 16:pos + 16 + (clen or ulen)]
        pos += 16 + (clen or ulen)
        if clen:
            body = zd.decompress(body, max_output_size=ulen) if body[:4] == b"\x28\xb5\x2f\xfd" else lz4.block.decompress(body, uncompressed_size=ulen)
        if name == "END":
            break
        if name == "INST":
            cid = struct.unpack_from("<i", body, 0)[0]
            cname, p = read_str(body, 4)
            p += 1
            n = struct.unpack_from("<I", body, p)[0]
            refs, _ = read_refs(body, p + 4, n)
            classes[cid] = (cname.decode(), refs)
            for r in refs:
                cls_of[r] = cname.decode()
                props[r] = {}
                order.append(r)
        elif name == "PROP":
            cid = struct.unpack_from("<i", body, 0)[0]
            pname, p = read_str(body, 4)
            t = body[p]
            cname, refs = classes[cid]
            cells = split(t, body, p + 1, len(refs))
            if cells is not None:
                for r, c in zip(refs, cells):
                    props[r][pname.decode()] = (t, c)
        elif name == "PRNT":
            n = struct.unpack_from("<I", body, 1)[0]
            kids, p = read_refs(body, 5, n)
            pars, _ = read_refs(body, p, n)
            parent.update(zip(kids, pars))

    def name_of(r): return props[r].get("Name", (1, b""))[1].decode("utf-8", "replace")
    def path_of(r):
        parts = []
        while r != -1 and r in cls_of:
            parts.append(name_of(r))
            r = parent.get(r, -1)
        return ".".join(reversed(parts))
    roots = list(ROOTS)
    for r, nm in ROOTS.items():
        print(r, path_of(r), "->", nm)
        props[r]["Name"] = (0x01, nm.encode())
    children = {}
    for r in order:
        children.setdefault(parent.get(r, -1), []).append(r)

    keep, newparent, newclass = [], {}, {}
    def walk(r, par):
        cname, nm = cls_of[r], name_of(r)
        if cname in LEAVE or nm == "AnimSaves":
            return
        keep.append(r)
        newparent[r] = par
        for c in children.get(r, []):
            walk(c, r)
    # the Folder that holds them: a Folder of the kit's, renamed
    folder = next(r for r in order if cls_of[r] == "Folder" and parent.get(r, -1) in cls_of)
    top = max(order) + 1
    cls_of[top] = "Folder"
    props[top] = dict(props[folder])
    props[top]["Name"] = (0x01, b"CuriousKit")
    keep.append(top)
    newparent[top] = -1
    for root in roots:
        walk(root, top)
    remap = {r: i for i, r in enumerate(keep)}
    cname_of = {r: newclass.get(r, cls_of[r]) for r in keep}
    names = sorted(set(cname_of.values()))
    blob = b"<roblox!\x89\xff\r\n\x1a\n" + struct.pack("<H", 0) + struct.pack("<ii", len(names), len(keep)) + b"\x00" * 8
    blob += chunk("META", u32(1) + rstr(b"ExplicitAutoJoints") + rstr(b"true"))
    members = {c: [r for r in keep if cname_of[r] == c] for c in names}
    for cid, c in enumerate(names):
        blob += chunk("INST", struct.pack("<i", cid) + rstr(c.encode()) + b"\x00" + u32(len(members[c])) + write_refs([remap[r] for r in members[c]]))
    skipped = set()
    for cid, c in enumerate(names):
        rs = members[c]
        common = set(props[rs[0]])
        for r in rs[1:]:
            common &= set(props[r])
        for r in rs:
            skipped |= set((c, k) for k in props[r]) - set((c, k) for k in common)
        for pname in sorted(common):
            types = {props[r][pname][0] for r in rs}
            assert len(types) == 1, (c, pname, types)
            t = types.pop()
            blob += chunk("PROP", struct.pack("<i", cid) + rstr(pname.encode()) + bytes([t]) + join(t, [props[r][pname][1] for r in rs], remap))
    blob += chunk("PRNT", b"\x00" + u32(len(keep)) + write_refs([remap[r] for r in keep]) + write_refs([remap.get(newparent[r], -1) for r in keep]))
    blob += chunk("END", b"</roblox>", compress=False)
    open(out, "wb").write(blob)
    print("instances:", len(keep), "classes:", len(names), "bytes:", len(blob))
    if skipped:
        print("not on every instance of its class (left out):", sorted(skipped))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
