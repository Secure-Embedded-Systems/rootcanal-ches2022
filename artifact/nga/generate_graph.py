import argparse
import networkx as nx

DEBUG = False

KEYWORDS = ['module', 'endmodule', 'input', 'output', 'wire', 'reg']
CONNECT = ['assign']

# library specific:
LIBRARY_GATES_KW = 'sky130_fd_sc_hd__'
INPUT_NAME_STARTERS = ('A', 'B', 'C', 'D', 'COUT', 'SUM', 'S', 'RESET', 'TE')
OUTPUT_NAME_STARTERS = ('Q', 'X', 'Y', 'Z')

# design specific:
MAIN_MODULE = 'skivav'


def read_statement(netlist_f): # finds one statement (ending with a semicolon)
                                # doesn't support multi-line comments!
    words = []
    eof = False
    full_statement = ""

    while True:
        line = netlist_f.readline()
        full_statement = full_statement + line

        words_new = []
        if not line: 
            eof = True
            break  # EOF

        if(not line.strip()): # skip empty lines
            continue

        words_new.append(line.strip().replace('\\','').replace('] [','][').replace('(', ' ').replace(')', ' ').split())

        if (not words_new): # skip empty lines
            continue

        flatwords_new = [ item for elem in words_new for item in elem]
        if DEBUG:
            print("flatwords_new: {}".format(flatwords_new))
        if flatwords_new[0].startswith('//') or flatwords_new[0].startswith('/*'): # comments
            break

        words.extend(flatwords_new) # add the new words

        if (words[-1].endswith(';')) or (words[-1].endswith('endmodule')):
            break

    return words, netlist_f, eof, full_statement


def assess_gates(statement, gate_counts, gate_connections, gate_names, gate_name_outp): # generate a dictionray showing connection between nets
    
    if DEBUG:
        print('assess_gates')


    if statement[0] in gate_counts.keys():
        gate_counts[statement[0]] = gate_counts[statement[0]] + 1
    else:
        gate_counts[statement[0]] = 1


    outputs = []
    for i_word,word in enumerate(statement): # find output name
        if word.startswith('.'):
            if word[1:].startswith(OUTPUT_NAME_STARTERS):
                outputs.append(statement[i_word+1])
            elif word[1:].startswith(INPUT_NAME_STARTERS):
                continue
            else:
                print('ERROR: gate pin not supported: {}\n'.format(word))

    if not statement[1] in gate_name_outp.keys():
        gate_name_outp[statement[1]] = []
    for outp in outputs:
        gate_name_outp[statement[1]].append(outp)

    for i_word,word in enumerate(statement): # make input-output connections
        if word.startswith('.'):
            if word[1:].startswith(INPUT_NAME_STARTERS):
                if statement[i_word+1] not in gate_connections.keys():
                    gate_connections[statement[i_word+1]] = []
                for out in outputs:
                    gate_names[(statement[i_word+1], out)] = statement[1]
                    gate_connections[statement[i_word+1]].append(out)
                    if DEBUG:
                        print('added {} to {}'.format(out,statement[i_word+1]))

    return gate_connections, gate_names, gate_counts, gate_name_outp



def assess_statement(statement, gate_counts, gate_connections, gate_names, alias_connections, gate_name_outp): # calling the correct assessment function on current statement

    if statement[0].startswith(LIBRARY_GATES_KW):
        gate_connections, gate_names, gate_counts, gate_name_outp = assess_gates(statement, gate_counts, gate_connections, gate_names, gate_name_outp)
    elif statement[0] in KEYWORDS:
        #tmp assess_keywords(statement)
        pass
    elif statement[0] in CONNECT:
        # tmp alias_connections = assess_connects(statement, alias_connections)
        pass
    else:
        print('WARNING: unidentified statement found: {}'.format(statement))

    return gate_connections, gate_names, alias_connections, gate_counts, gate_name_outp


def generate_graph (gate_connections, gate_names):
    # Create directed graph
    netlist_directedgraph = nx.DiGraph(gate_connections)

    if DEBUG:
        print('gate_names:')
        print(gate_names)
    
    nx.set_edge_attributes(netlist_directedgraph, gate_names, 'gate_name')

    return netlist_directedgraph


def main_gen_graph (netlist):

    # data structures:
    #   gate_connections: shows input-output pairs for gates --> used for generating the graph
    #   gate_name_outp: dictionary of gate names and their output(s) names --> used for applying gate correlation to their output correlation
    # 
    # The network shows the gates as edges connecting input to outputs (nodes)
    # each gate's output (node)

    gate_connections = {}
    gate_names = {}
    gate_name_outp = {}

    gate_counts = {}

    alias_connections = {}
    
    with open(netlist) as netlist_f:
        eof = False

        while not eof:
            statement, netlist_f, eof, _ = read_statement(netlist_f)

            if (not statement):
                continue

            if statement[0]=='module': # skip all modules except for the MAIN_MODULE
                if statement[1]!=MAIN_MODULE:
                    while statement[0]!='endmodule':
                        statement, netlist_f, eof, _ = read_statement(netlist_f)

            if DEBUG:
                print('statement: {}'.format(statement))

            gate_connections, gate_names, alias_connections, gate_counts, gate_name_outp = assess_statement(statement, gate_counts, gate_connections, gate_names, alias_connections, gate_name_outp)
    if DEBUG:
        print(gate_connections)
        print(gate_name_outp)


    netlist_directedgraph = generate_graph (gate_connections, gate_names)

    return netlist_directedgraph, gate_name_outp
