examplePrograms = [
    [
        "add.wanda", 
        "$ 4 5 +\n"
    ], 
    [
        "fact.wanda", 
        "$\n: 0 $ fact -> $ 1 ;\n: $ fact -> $ dup 1 - fact * ;\n5 fact\n"
    ], 
    [
        "mod5.wanda", 
        "$\n: $ mod5 -> $ 5 - dup sgn cont5 ;\n: 1 $ cont5 -> $ mod5 ;\n: 0 $ cont5 -> $ pop 0 ;\n: -1 $ cont5 -> $ 5 + ;\n27 mod5 30 mod5 31 mod5\n"
    ], 
    [
        "perim.wanda", 
        "$\n: $ perim -> $ + 2 * ;\n4 10 perim\n"
    ], 
    [
        "sink.wanda", 
        ") 1 2 3 4 5 $ 99 sink\n"
    ]
];
