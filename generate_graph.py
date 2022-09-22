import subprocess
import os

def run_protostar():
    tempfile = open(os.path.join(script_path,"temp_output.gv"), "w")
    subprocess.run(['protostar','--no-color', 'test','::test_generate_graphviz','--no-progress-bar'], stdout=tempfile)
    tempfile.close()

def generate_graph():
    graph_file = open(os.path.join(script_path,"graph.gv"), "w")
    r_tempfile = open(os.path.join(script_path,"temp_output.gv"), "r")
    contents = r_tempfile.readlines()
    found = False
    for i, line in enumerate(contents):
        if "[test]" in line:
            found = True
            graph_file.write("digraph {\n")
            continue
        if found and line!="\n":
            print(line)
            graph_file.write(line)
    graph_file.write("}")
    graph_file.close()


script_path = os.path.dirname(os.path.realpath(__file__))
run_protostar()
generate_graph()
os.remove(os.path.join(script_path,"temp_output.gv")) 


