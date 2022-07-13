import yaml
from tqdm import tqdm
import os
import csv
import networkx as nx
from generate_graph import *
import math
import shutil

DEBUG = False
REPORT= False
aca_results_file = '../../../aca/bit1/unprotected/combinedresults-sum.yaml'
correlation_or_welcht = 'welcht'
pc_log_dir = '../../../sim/pc_log/unprotected/'
assembly_file = '../../../sim/software/unprotected/present_unprotected.dump'
FREQ = 5e7 # 50MHz
pc_log_timescale = 1e-12

TOPLEVEL = 'skivav'
MODULE = 'skivav_present_sbox_unprotected_tvla'
G_FILE = '../../../synth/skivav_sky130_50.g'
NETLIST = '../../../synth/skivav_sky130_50.v'
MODULE_NAMES = ['aes_comp_core.v', 'dual_port_BRAM_memory_subsystem.v', 'memory_arbiter.v', 
                'aes_comp_decipher_block.v', 'dual_port_BRAM.v', 'memory_interface.v',
                'aes_comp_encipher_block.v', 'execution_unit.v', 'memory_issue.v',
                'aes_comp_inv_sbox.v', 'fetch_issue.v', 'memory_receive.v',
                'aes_comp_key_mem.v', 'fifo_dma.sv', 'pipeline_register.v',
                'aes_comp_sbox.v', 'fifo.v', 'regFile.v',
                'aes_top.v', 'five_stage_bypass_unit.v', 's_axi_controller.sv',
                'ALU.v', 'five_stage_control_unit.v', 'simpleuart.v',
                'ca_prng.v', 'five_stage_core.v', 'skivav.v',
                'comp_sbox.v', 'five_stage_decode_unit.v', 'tDMA.sv',
                'controller.sv', 'five_stage_stall_unit.v', 'timer_top.v',
                'control_unit.v', 'gpio_top.v', 'decode_unit.v',
                'hazard_detection_unit.v', 'transposer.sv', 'dma_top.v',
                'iopad.v', 'writeback_unit.v', 'dual_port_BRAM_byte_en.v',
                'm_axi_controller.sv']
MODULE_NAME_PIPE_STAGE_DICT = {
    'aes_comp_core.v': 'AES Coprocessor', 
    'dual_port_BRAM_memory_subsystem.v': 'I-Mem and D-Mem in Testbench', 
    'memory_arbiter.v': 'SoC Interconnect', 
    'aes_comp_decipher_block.v': 'AES Coprocessor', 
    'dual_port_BRAM.v': 'I-Mem and D-Mem in Testbench', 
    'memory_interface.v': 'SoC Interconnect',
    'aes_comp_encipher_block.v': 'AES Coprocessor', 
    'execution_unit.v': 'Execute Stage', 
    'memory_issue.v': 'Memory Stage',
    'aes_comp_inv_sbox.v': 'AES Coprocessor', 
    'fetch_issue.v': 'Fetch Stage', 
    'memory_receive.v': 'Memory Stage',
    'aes_comp_key_mem.v': 'AES Coprocessor', 
    'fifo_dma.sv': 'T-DMA', 
    'pipeline_register.v': 'Misc. Stages',
    'aes_comp_sbox.v': 'AES Coprocessor', 
    'fifo.v': 'UART', 
    'regFile.v': 'Decode Stage',
    'aes_top.v': 'AES Coprocessor', 
    'five_stage_bypass_unit.v': 'Control Unit', 
    's_axi_controller.sv': 'T-DMA',
    'ALU.v': 'Execute Stage', 
    'five_stage_control_unit.v': 'Control Unit', 
    'simpleuart.v': 'UART',
    'ca_prng.v': 'T-DMA', 
    'five_stage_core.v': 'Processor Top Level', 
    'skivav.v': 'SoC Top Level',
    'comp_sbox.v': 'AES Coprocessor', 
    'five_stage_decode_unit.v': 'Decode Stage', 
    'tDMA.sv': 'T-DMA',
    'controller.sv': 'T-DMA', 
    'five_stage_stall_unit.v': 'Control Unit', 
    'timer_top.v': 'Timer',
    'control_unit.v': 'Control Unit', 
    'gpio_top.v': 'GPIO', 
    'decode_unit.v': 'Decode Stage',
    'hazard_detection_unit.v': 'Control Unit', 
    'transposer.sv': 'T-DMA', 
    'dma_top.v': 'T-DMA',
    'iopad.v': 'I/O Pad', 
    'writeback_unit.v': 'Write-Back Stage', 
    'dual_port_BRAM_byte_en.v': 'I-Mem and D-Mem in Testbench',
    'm_axi_controller.sv': 'T-DMA'
}
WITHIN_PROCESSOR_CORE = ['Execute Stage', 'Memory Stage', 'Fetch Stage', 'Memory Stage', 'Misc. Stages', 'Decode Stage', 'Control Unit', 'Processor Top Level', 'Write-Back Stage']
REGISTER_FILE = 'core_ID_base_decode_registers_register_file'
EXTRA_PROCESSOR_MODULES = ['mem_interface', 'aes_coprocessor', 'gpio_inst', 'timer_inst', 'uart', 'dma_top_inst', 'memory_arbiter_inst']
EXTRA_PROCESSOR_UNITS_DICT = {'mem_interface': 'SoC Interconnect', 
                            'aes_coprocessor': 'AES Coprocessor', 
                            'gpio_inst': 'GPIO', 
                            'timer_inst': 'Timer', 
                            'uart': 'UART', 
                            'dma_top_inst': 'T-DMA', 
                            'memory_arbiter_inst': 'SoC Interconnect'
                            }

CLK_PER = 1/FREQ
aca_time_scale = 0


def g_file_extract_line_numbers(G_FILE, MODULE_NAMES):
    # generates a text file for each RTL file listing line number of the mapped parts 

    if not os.path.exists('line_numbers'):
        os.makedirs('line_numbers')

    with open(G_FILE, 'r') as g_file_f:
        lines_g_file = g_file_f.readlines()

        for module in MODULE_NAMES:
            line_num_list = []

            for line_g_file in lines_g_file:
                if ('file_row_col' in line_g_file) and (module in line_g_file):
                    module_line = line_g_file[line_g_file.index('{{'):]
                    line_num = int(module_line.split()[1])
                    col_num = int(module_line.split()[2][:-2])
                    row_col = str(line_num) + ', '+ str(col_num)
                    if not row_col in line_num_list:
                        line_num_list.append(str(line_num) + ', '+ str(col_num))

            with open('./line_numbers/'+module.split('.')[0]+'_lines.txt','w') as module_line_f:
                module_line_f.write('row, column\n')
                module_line_f.write('\n'.join(line_num_list))


def read_aca_results (aca_results_file):
    # reads the ACA results file into a dictionary and sets aca_time_scale

    with open(aca_results_file, "r") as stream:
        try:
            yaml_data = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)

    aca_results = yaml_data['results']

    global aca_time_scale
    aca_time_scale = yaml_data['timescale']

    return aca_results

pipe_names = ['writeback'] # checking one stage is enough; in the returned path, we extract the first stage register
all_pipe_names = ['writeback', 'memory', 'execute', 'decode']
pipe_width = {'decode': 64, 'execute': 188, 'memory': 146, 'writeback': 103} # from the rtl file five_stage_core.v 
pipe_reg_output_stage_names = {'decode': "core_decode_pipe_output", 'execute': "core_execute_pipe_output", 
                            'memory': "core_memory_pipe_output", 'writeback': "core_writeback_pipe_output"}
pipe_reg_output_stage_dict = {"core_decode_pipe_output": "Fetch Stage",        # any gate feeding decode pipeline register is in fetch stage
                           "core_execute_pipe_output": "Decode Stage",
                           "core_memory_pipe_output": "Execute Stage",
                           "core_writeback_pipe_output": "Memory Stage"}
in_path_pipe_reg_output_stage_dict = {"core_decode_pipe_output": "Decode Stage",        # any gate feeding decode pipeline register is in fetch stage
                           "core_execute_pipe_output": "Execute Stage",
                           "core_memory_pipe_output": "Memory Stage",
                           "core_writeback_pipe_output": "Write-Back Stage"}
pipe_reg_stage_names = {'decode': "core_decode_pipe_pipe_reg_reg", 'execute': "core_execute_pipe_pipe_reg_reg", 
                        'memory': "core_memory_pipe_pipe_reg_reg", 'writeback': "core_writeback_pipe_pipe_reg_reg"}
pipe_reg_stage_dict = {"core_execute_pipe_pipe_reg_reg": "Decode Stage",    # excluding fetch!
                           "core_memory_pipe_pipe_reg_reg": "Execute Stage",
                           "core_writeback_pipe_pipe_reg_reg": "Memory Stage"}
in_path_pipe_reg_stage_dict = { "core_decode_pipe_pipe_reg_reg": "Decode Stage",
                                    "core_execute_pipe_pipe_reg_reg": "Execute Stage",
                                    "core_memory_pipe_pipe_reg_reg": "Memory Stage",
                                    "core_writeback_pipe_pipe_reg_reg": "Write-Back Stage"}

def detect_pipereg_output_names(gate_name_outp):
    detected_pipereg_output_names = {}

    for stg in all_pipe_names:
        detected_pipereg_output_names[stg] = []

        for bit in range(pipe_width[stg]):
            pipe_reg_stage_name = pipe_reg_stage_names[stg]+'['+str(bit)+']'

            if pipe_reg_stage_name in gate_name_outp.keys():
                outp_names = gate_name_outp[pipe_reg_stage_name]#.split('[')[0]
                for outp_name in outp_names:
                    if outp_name not in detected_pipereg_output_names[stg]:
                        detected_pipereg_output_names[stg].append(outp_name)

    return detected_pipereg_output_names


def find_pipe_reg_stage (gate_output, netlist_graph, detected_pipereg_output_names):
    # traverses the netlist graph from the gate_output given to see which pipeline stage register it feeds 


    if not (gate_output in netlist_graph.nodes()):
        if REPORT:
            print('ERROR: {} not in the netlist graph'.format(gate_output))
        return None

    # the direct outputs of pipeline registers are updated by the contents of the previous stage --> source of leakage will be the previous stage
    gate_output_ = gate_output
    if '[' in gate_output_:
        gate_output_ = gate_output_.split('[')[0]
    for in_edge in netlist_graph.in_edges(gate_output, data=True): # find if it is output of a pipeline register
        if '[' in in_edge:
            in_edge = in_edge.split('[')[0]
        in_edge_cell_name = in_edge[2]['gate_name']
        if '[' in in_edge_cell_name:
            in_edge_cell_name = in_edge_cell_name.split('[')[0]
        
        if in_edge_cell_name in in_path_pipe_reg_stage_dict.keys():
            stage = in_path_pipe_reg_stage_dict[in_edge_cell_name]
            return stage

    path_found = False
    for pipe_stage in pipe_names:
        break_bit = False
        for pipe_reg_node in detected_pipereg_output_names[pipe_stage]:

            try:
                path = nx.dijkstra_path(netlist_graph,gate_output,pipe_reg_node)

                if DEBUG:
                    print('INFO: found path between nodes {} and {}'.format(gate_output,pipe_reg_node))
                    print('\t {}'.format(path))
                for node in path: # extract the first stage register in the path
                    if DEBUG:
                        print('node: {}'.format(node))

                    stop_out_edge = False

                    for extra_core in EXTRA_PROCESSOR_MODULES:
                        if node.startswith(extra_core):
                            stage = EXTRA_PROCESSOR_UNITS_DICT[extra_core]
                            stop_out_edge = True

                    for out_edge in netlist_graph.out_edges(node, data=True): # find if is connected to a pipeline register input
                        if stop_out_edge:
                            break
                        out_edge_cell_name = out_edge[2]['gate_name']
                        if '[' in out_edge_cell_name:
                            out_edge_cell_name = out_edge_cell_name.split('[')[0]
                        if out_edge_cell_name in pipe_reg_stage_dict.keys():
                            stage = pipe_reg_stage_dict[out_edge_cell_name]
                            if REPORT:
                                print('\tfound stage {}'.format(stage))
                            stop_out_edge = True
                            break
                    if stop_out_edge:
                        break



                if DEBUG:
                    print('\tstage: {}'.format(stage))

                path_found = True
                
            except nx.exception.NetworkXNoPath:
                pass

            if path_found:
                
                if stage == 'Decode Stage': # check if it is from operand forwarding
                    in_path_found = False
                    for in_edge in netlist_graph.in_edges(gate_output):
                        for pipe_reg_node in detected_pipereg_output_names['writeback']:
                            try:
                                in_path = nx.dijkstra_path(netlist_graph,pipe_reg_node,gate_output)
                                if REPORT:
                                    print('found in_path for gate_output {}: {}'.format(gate_output, in_path))
                                in_path_found = True

                                in_path_reverse = in_path
                                in_path_reverse.reverse()
                                for in_node in in_path_reverse: # extract the last stage register in the path
                                    in_node = in_node.split('[')[0]
                                    if in_node.startswith(REGISTER_FILE):
                                        stage = 'Decode Stage'
                                        break
                                    elif in_node in in_path_pipe_reg_output_stage_dict.keys(): # find if is connected to a pipeline register output
                                        stage = in_path_pipe_reg_output_stage_dict[in_node]
                                        break
                                break

                            except nx.exception.NetworkXNoPath:
                                pass
                        if in_path_found:
                            break
                return stage

    return None


def gen_aca_results_summary_csv(G_FILE, MODULE_NAMES, aca_results, summary_csv_file_name, netlist_graph, detected_pipereg_output_names, gate_name_outp):
    # generates the csv file of ACA results from the dictionary
    not_found_gates = []
    info_csv = []
    info_csv.append('gate,rank,line,module,unit,gate_type,combined_score,lti range,lti start,'+correlation_or_welcht+',weight\n')
    with open(G_FILE,'r') as g_file_f:
        lines_g_file = g_file_f.readlines()
        with open(NETLIST,'r') as netlist_f:
            lines_netlist_file = netlist_f.readlines()
            words_netlist_file = []
            for line_netlist_file in lines_netlist_file:
                words_netlist_file.extend(line_netlist_file.split())

            for aca_result in tqdm(aca_results):
                found = False
                gate_name = aca_result['gatename'][1:] # skip the initial '/'
                rank = aca_result['rank']
                combined_score = aca_result['combinedscore']
                ltis = aca_result['LTIs']

                for line_g_file in lines_g_file:
                    if ('.file_row_col' in line_g_file) and (gate_name in line_g_file):
                        found = True              
                        line_info = line_g_file.split(".file_row_col")[1].strip()
                        line_info = gate_name + ',' + str(rank) + ',' + line_info 
                        for module in MODULE_NAMES:
                            if module in line_g_file:
                                line_info = line_info + ',' + module
                                if module=='pipeline_register.v':
                                    if 'decode_pipe' in gate_name:
                                        line_info = line_info + ',' + 'Decode Stage'
                                    elif 'instruction_execute_pipe' in gate_name:
                                        line_info = line_info + ',' + 'Control Unit'
                                    elif 'instruction_memory_pipe' in gate_name:
                                        line_info = line_info + ',' + 'Control Unit'
                                    elif 'instruction_writeback_pipe' in gate_name:
                                        line_info = line_info + ',' + 'Control Unit'
                                    elif 'execute_pipe' in gate_name:
                                        line_info = line_info + ',' + 'Execute Stage'
                                    elif 'memory_pipe' in gate_name:
                                        line_info = line_info + ',' + 'Memory Stage'
                                    elif 'writeback_pipe' in gate_name:
                                        line_info = line_info + ',' + 'Write-Back Stage'
                                    else: ### use the graph to find which pipeline stage
                                        for gate_output in gate_name_outp[gate_name[len(TOPLEVEL+'/'):]]: # output(s) of the gate
                                            stage = find_pipe_reg_stage (gate_output, netlist_graph, detected_pipereg_output_names)
                                            if stage:
                                                line_info = line_info + ',' + stage
                                                break
                                        if not stage:
                                            if REPORT:
                                                print('ERROR: stage for gate {} not found!'.format(gate_name))
                                            line_info = line_info + ',' + MODULE_NAME_PIPE_STAGE_DICT[module]


                                else:
                                    line_info = line_info + ',' + MODULE_NAME_PIPE_STAGE_DICT[module]
                                break
                        break
                
                if not found:
                    not_found_gates.append(gate_name+'\n')

                else:
                    # find gate type:
                    if gate_name.startswith(TOPLEVEL):
                        gate_name = gate_name[len(TOPLEVEL+'/'):]
                    for word_i, word_netlist_file in enumerate(words_netlist_file):
                        if gate_name in word_netlist_file:
                            gate_type = words_netlist_file[word_i-1]
                            break

                    line_info_base = line_info + ',' + gate_type + ',' + str(combined_score)
                    for lti in ltis:
                        for cc in range(int((lti['lti'][1]-lti['lti'][0]+1)*aca_time_scale/CLK_PER)): # multiple clock cycles

                            line_info = line_info_base + ',' + str(lti['lti'][0]) + '-' + str(lti['lti'][1]) + ','
                            lti_start = str(int(math.floor(int(lti['lti'][0]+cc*CLK_PER/aca_time_scale)*aca_time_scale/CLK_PER) * (CLK_PER/pc_log_timescale)))
                            line_info = line_info + lti_start + ',' + str(lti[correlation_or_welcht]) + ',' + str(lti['weight']) + '\n'
                            info_csv.append(line_info)


    with open(summary_csv_file_name, 'w') as output_csv_f:
        output_csv_f.writelines(info_csv)

    with open(MODULE+'_not_found.txt', 'w') as not_found_f:
        not_found_f.writelines(not_found_gates)

    if DEBUG:
        print('\nINFO: result stored in {}, gates not found reported in {}'.format(MODULE+'_output.csv', MODULE+'_not_found.txt'))


def find_pc(summary_csv_file_name, summary_plus_pc_csv_file_name, pc_log_dir, from_graph=False):
    # finds the PC for each gate from the prcoessor core based on its stage and leaky time interval
    pc_fetch_log = {}
    pc_decode_log = {}
    pc_execute_log = {}
    pc_memory_log = {}
    pc_writeback_log = {}
    with open(pc_log_dir+'/pc_fetch.txt', 'r') as pc_log_fetch_f:
        for line in pc_log_fetch_f.readlines():
            timestamp = line.strip().split()[0]
            pc_val = line.strip().split()[1]
            if pc_val!='00000000':
                last_nonzero_pc = pc_val
            if (int(timestamp)*pc_log_timescale/CLK_PER>1) and  (pc_val=='00000000'):
                if DEBUG:
                    print(timestamp)
                    print(CLK_PER)
                    print(int(timestamp)*pc_log_timescale/CLK_PER>1)
                pc_val = pc_val + ' (' + last_nonzero_pc + ' flushed)'
            pc_fetch_log[timestamp] = pc_val
    with open(pc_log_dir+'/pc_decode.txt', 'r') as pc_log_decode_f:
        for line in pc_log_decode_f.readlines():
            timestamp = line.strip().split()[0]
            pc_val = line.strip().split()[1]
            if pc_val!='00000000':
                last_nonzero_pc = pc_val
            if (int(timestamp)*pc_log_timescale/CLK_PER>1) and  (pc_val=='00000000'):
                pc_val = pc_val + ' (' + last_nonzero_pc + ' flushed)'
            pc_decode_log[timestamp] = pc_val
    with open(pc_log_dir+'/pc_execute.txt', 'r') as pc_log_execute_f:
        for line in pc_log_execute_f.readlines():
            timestamp = line.strip().split()[0]
            pc_val = line.strip().split()[1]
            if pc_val!='00000000':
                last_nonzero_pc = pc_val
            if (int(timestamp)*pc_log_timescale/CLK_PER>1) and  (pc_val=='00000000'):
                pc_val = pc_val + ' (' + last_nonzero_pc + ' flushed)'
            pc_execute_log[timestamp] = pc_val
    with open(pc_log_dir+'/pc_memory.txt', 'r') as pc_log_memory_f:
        for line in pc_log_memory_f.readlines():
            timestamp = line.strip().split()[0]
            pc_val = line.strip().split()[1]
            if pc_val!='00000000':
                last_nonzero_pc = pc_val
            if (int(timestamp)*pc_log_timescale/CLK_PER>1) and  (pc_val=='00000000'):
                pc_val = pc_val + ' (' + last_nonzero_pc + ' flushed)'
            pc_memory_log[timestamp] = pc_val
    with open(pc_log_dir+'/pc_writeback.txt', 'r') as pc_log_writeback_f:
        for line in pc_log_writeback_f.readlines():
            timestamp = line.strip().split()[0]
            pc_val = line.strip().split()[1]
            if pc_val!='00000000':
                last_nonzero_pc = pc_val
            if (int(timestamp)*pc_log_timescale/CLK_PER>1) and  (pc_val=='00000000'):
                pc_val = pc_val + ' (' + last_nonzero_pc + ' flushed)'
            pc_writeback_log[timestamp] = pc_val

    with open(summary_csv_file_name, 'r') as summary_csv_f:
        reader = csv.DictReader(summary_csv_f)
        fieldnames = reader.fieldnames
        
        if from_graph:
            pc_field_name = 'PC from graph'
            unit_field_name = 'stage from graph'
        else:
            pc_field_name = 'PC'
            unit_field_name = 'unit'
        
        with open(summary_plus_pc_csv_file_name, 'w') as summary_plus_pc_f:
            fieldnames.append(pc_field_name)
            
            writer = csv.DictWriter(summary_plus_pc_f, fieldnames=fieldnames)
            writer.writeheader()
            for row in reader:
                

                row_new = row
                unit = row[unit_field_name]
                time = row['lti start']

                pc_val = None
                if unit=='Fetch Stage':
                    if time in pc_fetch_log.keys():
                        pc_val = pc_fetch_log[time]
                    else:
                        pc_val = 'not found'
                elif unit=='Decode Stage':
                    if time in pc_decode_log.keys():
                        pc_val = pc_decode_log[time]
                    else:
                        pc_val = 'not found'
                elif unit=='Execute Stage':
                    if time in pc_execute_log.keys():
                        pc_val = pc_execute_log[time]
                    else:
                        pc_val = 'not found'
                elif unit=='Memory Stage':
                    if time in pc_memory_log.keys():
                        pc_val = pc_memory_log[time]
                    else:
                        pc_val = 'not found'
                elif unit=='Write-Back Stage':
                    if time in pc_writeback_log.keys():
                        pc_val = pc_writeback_log[time]
                    else:
                        pc_val = 'not found'
                elif unit=='Misc. Stages':
                    pc_val = 'multiple potential stages'
                else:
                    if time in pc_memory_log.keys():
                        pc_val = 'out of processor ' + str(pc_memory_log[time])
                    else:
                        time_int = int(time)
                        if DEBUG:
                            print('time: {}'.format(time))
                        log_time_prev = 0
                        for log_time in pc_memory_log.keys():
                            log_time_int = int(log_time)
                            if time_int < log_time_int:
                                if DEBUG:
                                    print('log_time: {}'.format(log_time))
                                pc_val = 'out of processor ' + str(pc_memory_log[log_time_prev])
                                break
                            log_time_prev = log_time

                row_new[pc_field_name] = pc_val
                writer.writerow(row_new)


def add_assembly_columns(summary_plus_pc_csv_file_name, summary_assembly_csv_file_name, assembly_file, from_graph=False):
    # adds the assembly code, function name, and the machine code of each PC in input csv file to the output csv file

    pcs = []
    functions_pc = {}
    instructions_pc = {}
    binarycode_pc = {}

    if from_graph:
        pc_field_name = 'PC from graph'
        instruction_field_name = 'instruction from graph'
        function_field_name = 'function from graph'
        machine_code_field_name = 'machine code from graph'
    else:
        pc_field_name = 'PC'
        instruction_field_name = 'instruction'
        function_field_name = 'function'
        machine_code_field_name = 'machine code'

    with open(summary_plus_pc_csv_file_name, 'r') as summary_plus_pc_f:
        reader = csv.DictReader(summary_plus_pc_f)
        fieldnames = reader.fieldnames

        for row in reader:

            row_new = row
            pc = row_new[pc_field_name]
            
            if 'flushed' in pc:
                pc = pc.split('(')[1]
                pc = pc.split()[0]
            
            if 'out of processor' in pc:
                pc = pc.split()[-1]

            if not 'multiple potential stages' in pc:
                leadingZeros = 0
                while pc[leadingZeros]=='0':
                    leadingZeros = leadingZeros+1
                inst_addr = pc[leadingZeros:]
                
                if not inst_addr in pcs:
                    pcs.append(inst_addr)

            else:
                row_new[instruction_field_name] = 'N/A'
                row_new[function_field_name] = 'N/A'

    print(pcs)

    # open assembly and find function and instruction
    function = ''
    with open(assembly_file, 'r') as assembly_f:
        lines = assembly_f.readlines()
        for line in lines:
            if not line.strip(): # skip empty lines
                continue
            if not line.startswith((' ', '\t')):
                l = line.strip()
                if l[0].isnumeric():
                    function = l[l.index('<')+1:l.index('>')]
            else:
                addr = line.strip().split(':')[0]
                if addr in pcs:
                    binarycode_pc[addr] = line.split()[1]
                    functions_pc[addr] = function
                    tmp = line.split()[2:]
                    tmp = ' '.join(tmp)
                    instructions_pc[addr] = tmp

    with open(summary_plus_pc_csv_file_name, 'r') as summary_plus_pc_f:
        reader = csv.DictReader(summary_plus_pc_f)
        fieldnames = reader.fieldnames

        with open(summary_assembly_csv_file_name, 'w') as summary_assembly_f:
            fieldnames.append(instruction_field_name)
            fieldnames.append(function_field_name)
            fieldnames.append(machine_code_field_name)
            writer = csv.DictWriter(summary_assembly_f, fieldnames=fieldnames)
            writer.writeheader()

            for row in reader:
                row_new = row
                pc = row_new[pc_field_name]
                if 'flushed' in pc:
                    pc = pc.split('(')[1]
                    pc = pc.split()[0]
                
                if 'out of processor' in pc:
                    pc = pc.split()[-1]
                
                try:
                    int(pc,16)    
                    leadingZeros = 0
                    while pc[leadingZeros]=='0':
                        leadingZeros = leadingZeros+1
                    inst_addr = pc[leadingZeros:]
                    row_new[machine_code_field_name] = binarycode_pc[inst_addr]
                    row_new[function_field_name] = functions_pc[inst_addr]
                    row_new[instruction_field_name] = instructions_pc[inst_addr]
                except ValueError:
                    row_new[machine_code_field_name] = 'N/A'
                    row_new[function_field_name] = 'N/A'
                    row_new[instruction_field_name] = 'N/A'

                writer.writerow(row_new)


def verify_processor_stage(summary_assembly_csv_file_name, summary_verified_csv_file_name, netlist_graph, detected_pipereg_output_names, gate_name_outp):
    # verifies the tagged pipeline stages from Genus HDL tracking output from the graph of the netlist
    pipe_stage_order = {"Fetch Stage": 0,
                       "Decode Stage": 1,
                       "Execute Stage": 2,
                       "Memory Stage": 3,
                       "Write-Back Stage": 4}

    with open(summary_assembly_csv_file_name, 'r') as summary_assembly_f:
        reader = csv.DictReader(summary_assembly_f)
        fieldnames = reader.fieldnames

        with open(summary_verified_csv_file_name, 'w') as summary_verified_f:
            fieldnames.append('stage from graph')
            fieldnames.append('verdict')
            writer = csv.DictWriter(summary_verified_f, fieldnames=fieldnames)
            writer.writeheader()

            for row in reader:
                row_new = row

                gate_name = row['gate']
                stage_found = None

                if gate_name[len(TOPLEVEL+'/'):] in gate_name_outp.keys(): # skip the gates from modules other than TOPLEVEL
                    for gate_output in gate_name_outp[gate_name[len(TOPLEVEL+'/'):]]: # output(s) of the gate
                        stage = find_pipe_reg_stage (gate_output, netlist_graph, detected_pipereg_output_names)
                        if stage:
                            if stage_found:
                                if (stage in WITHIN_PROCESSOR_CORE) and (stage_found in WITHIN_PROCESSOR_CORE):
                                    if pipe_stage_order[stage_found] > pipe_stage_order[stage]:
                                        stage_found = stage
                            else:
                                stage_found = stage

                if stage_found:
                    row_new['stage from graph'] = stage_found

                    if row['unit'] != stage_found:
                        row_new['verdict'] = 'conflict'

                else:
                    row_new['stage from graph'] = 'not found'
                    row_new['verdict'] = 'out of processor'
                    if REPORT:
                        print('ERROR: stage for gate {} not found!'.format(gate_name))
                    
                writer.writerow(row_new)



def final_unit_instruction(summary_verified_assembly_csv_file_name, summary_final_unit_instruction_csv_file_name):
    # for each gate, decides whether to take the results from genus or from the graph

    with open(summary_verified_assembly_csv_file_name, 'r') as summary_verified_f:
        reader = csv.DictReader(summary_verified_f)
        fieldnames = reader.fieldnames

        with open(summary_final_unit_instruction_csv_file_name, 'w') as summary_final_f:
            fieldnames.append('final unit')
            fieldnames.append('final PC')
            fieldnames.append('final instruction')
            fieldnames.append('final function')
            fieldnames.append('final machine code')
            fieldnames.append('final note')
            writer = csv.DictWriter(summary_final_f, fieldnames=fieldnames)
            writer.writeheader()

            for row in reader:
                row_new = row

                unit_genus = row['unit']
                unit_graph = row['stage from graph']
                pc_genus = row['PC']
                pc_graph = row['PC from graph']
                instr_genus = row['instruction']
                instr_graph = row['instruction from graph']
                function_genus = row['function']
                function_graph = row['function from graph']
                machcode_genus = row['machine code']
                machcode_graph = row['machine code from graph']

                row_new['final unit'] = unit_graph
                row_new['final PC'] = pc_graph
                row_new['final instruction'] = instr_graph
                row_new['final function'] = function_graph
                row_new['final machine code'] = machcode_graph

                if unit_genus not in WITHIN_PROCESSOR_CORE:
                    row_new['final unit'] = unit_genus
                    row_new['final PC'] = pc_genus
                    row_new['final instruction'] = instr_genus
                    row_new['final function'] = function_genus
                    row_new['final machine code'] = machcode_genus

                if row['module']=='regFile.v' and unit_graph=='not found':
                    row_new['final unit'] = unit_genus
                    row_new['final PC'] = pc_genus
                    row_new['final instruction'] = instr_genus
                    row_new['final function'] = function_genus
                    row_new['final machine code'] = machcode_genus

                if unit_graph=='Memory Stage':
                    row_new['final note'] = 'could be from out of processor modules'

                writer.writerow(row_new)



def create_instr_summary(summary_final_unit_instruction_csv_file_name, summary_short_csv_file_name):

    pcs = []
    pc_instruction_dict = {}
    pc_function_dict = {}
    pc_stage_dict = {}

    with open(summary_final_unit_instruction_csv_file_name, 'r') as summary_final_f:
        reader = csv.DictReader(summary_final_f)
        fieldnames = ['address','instruction','function','stage/unit']
        
        for row in reader:
            pc = row['final PC']
            instr = row['final instruction']
            funct = row['final function']
            stage = row['final unit']

            if pc not in pcs:
                pcs.append(pc)
                pc_instruction_dict[pc] = instr
                pc_function_dict[pc] = funct

            if pc not in pc_stage_dict.keys():
                pc_stage_dict[pc] = []

            if stage not in pc_stage_dict[pc]:
                pc_stage_dict[pc].append(stage)


    with open(summary_short_csv_file_name, 'w') as summary_short_f:
        writer = csv.DictWriter(summary_short_f, fieldnames=fieldnames)
        writer.writeheader()

        for pc in pcs:
            row_new = {}

            row_new['address'] = pc
            row_new['function'] = pc_function_dict[pc]
            row_new['instruction'] = pc_instruction_dict[pc]
            row_new['stage/unit'] = ''
            for st in pc_stage_dict[pc]:
                row_new['stage/unit'] = row_new['stage/unit'] + st + ','

            writer.writerow(row_new)

if __name__ == '__main__':

    summary_csv_file_name = MODULE+'_output.csv'
    summary_plus_pc_csv_file_name = MODULE+'_PC_output.csv'
    summary_assembly_csv_file_name = MODULE+'_assembly_output.csv'
    summary_verified_csv_file_name = MODULE+'_verified_output.csv'
    summary_verified_plus_pc_csv_file_name = MODULE+'_verified_PC_output.csv'
    summary_verified_assembly_csv_file_name = MODULE+'_verified_assembly_output.csv'
    summary_final_unit_instruction_csv_file_name = MODULE+'_final_output.csv'
    summary_short_csv_file_name = MODULE+'_short_summary.csv'

    print('INFO: reading ACA results ...')
    aca_results = read_aca_results (aca_results_file)

    print('INFO: generating netlist graph ...')
    netlist_graph, gate_name_outp = main_gen_graph (NETLIST)

    detected_pipereg_output_names = detect_pipereg_output_names(gate_name_outp)

    print('INFO: generating summary of ACA results ...')
    gen_aca_results_summary_csv (G_FILE, MODULE_NAMES, aca_results, summary_csv_file_name, netlist_graph, detected_pipereg_output_names, gate_name_outp)
    
    print('INFO: extracting line numbers for each RTL file from the g file ...')
    g_file_extract_line_numbers(G_FILE, MODULE_NAMES)

    print('INFO: finding PC for each instruction ...')
    find_pc(summary_csv_file_name, summary_plus_pc_csv_file_name, pc_log_dir, from_graph=False)

    print('INFO: finding assembly code for each PC ...')
    add_assembly_columns(summary_plus_pc_csv_file_name, summary_assembly_csv_file_name, assembly_file, from_graph=False)

    verify_processor_stage (summary_assembly_csv_file_name, summary_verified_csv_file_name, netlist_graph, detected_pipereg_output_names, gate_name_outp)

    find_pc(summary_verified_csv_file_name, summary_verified_plus_pc_csv_file_name, pc_log_dir, from_graph=True)
    
    add_assembly_columns(summary_verified_plus_pc_csv_file_name, summary_verified_assembly_csv_file_name, assembly_file, from_graph=True)

    final_unit_instruction(summary_verified_assembly_csv_file_name, summary_final_unit_instruction_csv_file_name)

    print('INFO: generating final summary file ...')
    create_instr_summary(summary_final_unit_instruction_csv_file_name, summary_short_csv_file_name)

    # delete intermediate results
    if not DEBUG:
        os.remove(summary_csv_file_name)
        os.remove(summary_plus_pc_csv_file_name)
        os.remove(summary_assembly_csv_file_name)
        os.remove(summary_verified_csv_file_name)
        os.remove(summary_verified_plus_pc_csv_file_name)
        os.remove(summary_verified_assembly_csv_file_name)
        os.remove(MODULE+'_not_found.txt')
        shutil.rmtree('line_numbers')

    print('\n\n>>> INFO: final output saved in ' + summary_final_unit_instruction_csv_file_name)
    print('>>> INFO: summary per instruction saved in ' + summary_short_csv_file_name)
