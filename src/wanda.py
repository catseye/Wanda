#!/bin/env python


def parse_program(program):
    return program.split()


def load_program(filename):
    with open(filename, 'r') as f:
        c = f.read()
    return parse_program(c)


def is_number(atom):
    return isinstance(atom, str) and all([(c.isdigit() or c == '-') for c in atom])


def fmt(redex):
    return ' '.join(redex)


def find_match(rules, redex, i):
    r0 = redex[i] if i < len(redex) else None
    r1 = redex[i+1] if i+1 < len(redex) else None
    r2 = redex[i+2] if i+2 < len(redex) else None
    r3 = redex[i+3] if i+3 < len(redex) else None
    r4 = redex[i+4] if i+4 < len(redex) else None

    if r0 == "$" and r1 == ":":
        j = i + 2
        pattern = []
        replacement = []
        seen_arrow = False

        while j < len(redex) and redex[j] != ";":
           if redex[j] == "->":
               seen_arrow = True
           elif seen_arrow:
               replacement.append(redex[j])
           else:
               pattern.append(redex[j])
           j += 1

        newrule = None
        if len([s for s in pattern if s == "$"]) == 1 and len([s for s in replacement if s == "$"]) == 1:
            newrule=dict(pattern=pattern, replacement=replacement)

        return dict(
            start=i,
            stop=j,
            pattern=["$", ":", "...", ";"],
            replacement=["$"],
            newrule=newrule,
        )

    if is_number(r0) and is_number(r1) and r2 == "$":
        a = int(r0)
        b = int(r1)
        op = r3
        if op == "+":
            return dict(start=i, stop=i+3, pattern=[r0, r1, "$", "+"], replacement=[str(a + b), "$"])
        if op == "*":
            return dict(start=i, stop=i+3, pattern=[r0, r1, "$", "*"], replacement=[str(a * b), "$"])
        if op == "-":
            return dict(start=i, stop=i+3, pattern=[r0, r1, "$", "-"], replacement=[str(a - b), "$"])

    if is_number(r0) and r1 == "$":
        a = int(r0)
        op = r2
        if op == "sgn":
            sgn_a = "1" if a > 0 else ("-1" if a < 0 else "0")
            return dict(start=i, stop=i+2, pattern=[r0, "$", "sgn"], replacement=[sgn_a, "$"])
        if op == "if" and r3 and r4:
            return dict(start=i, stop=i+4, pattern=[r0, "$", "if", r3, r4], replacement=["$", r4 if r0 == "0" else r3])

    if r0 and r1 == "$" and r2 == "pop":
        return dict(start=i, stop=i+2, pattern=[r0, "$", "pop"], replacement=["$"])

    if r0 and r1 == "$" and r2 == "dup":
        return dict(start=i, stop=i+2, pattern=[r0, "$", "dup"], replacement=[r0, r0, "$"])

    if r0 and r1 == "$" and r2 and r3 == "sink":
        return dict(start=i, stop=i+3, pattern=[r0, "$", r2, "sink"], replacement=["$", r2, "sink", r0])

    if r0 == "$" and is_number(r1):
        return dict(start=i, stop=i+1, pattern=["$", r1], replacement=[r1, "$"])

    # else find first rule in rules that matches redex[i ... end]

    for rule in rules:
        pattern = rule['pattern']
        matched = True
        for p, patbit in enumerate(pattern):
            if (i + p) >= len(redex) or patbit != redex[i + p]:
                matched = False
                break

        if matched:
            return dict(start=i, stop=i+len(pattern)-1, pattern=pattern, replacement=rule['replacement'])

    return None


def run_wanda(redex, options):
    rules = []
    start_index = 0
    while start_index < len(redex):
        match_info = find_match(rules, redex, start_index)
        if match_info:
            i = match_info['start']
            j = match_info['stop']

            while i <= j:
                redex.pop(i)
                j -= 1

            pos = i
            for value in match_info['replacement']:
                redex.insert(pos, value)
                pos += 1

            defn = match_info.get('newrule')
            if defn:
                rules.insert(0, defn)

            if options.get('trace'):
                print(fmt(redex))

            start_index = 0
        else:
            start_index += 1

    return redex


def main(args):
    options = {}
    if args[0] == '--trace':
        options['trace'] = True
        args = args[1:]
    program = load_program(args[0])
    result = run_wanda(program, options)
    print(fmt(result))


if __name__ == '__main__':
    import sys
    main(sys.argv[1:])
