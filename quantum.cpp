#include <caterpillar/synthesis/strategies/mapping_strategy.hpp>
#include <caterpillar/synthesis/strategies/bennett_mapping_strategy.hpp>
#include <caterpillar/synthesis/strategies/pebbling_mapping_strategy.hpp>
#include <caterpillar/synthesis/strategies/eager_mapping_strategy.hpp>
#include <mockturtle/algorithms/xag_optimization.hpp>
#include <mockturtle/io/verilog_reader.hpp>
#include <mockturtle/networks/xag.hpp>
#include <mockturtle/mockturtle.hpp>
#include <lorina/lorina.hpp>
#include <tweedledum/tweedledum.hpp>
#include <caterpillar/caterpillar.hpp>
#include <tweedledum/networks/netlist.hpp>
#include <caterpillar/solvers/bsat_solver.hpp>
#include <fstream>
#include <string>
#include <iostream>

void print_usage(const char* prog_name);
void write_gate_types(caterpillar::stg_gate gate, std::ofstream& gate_output);

int main(int argc, char** argv) {
    if (argc < 3) {
        print_usage(argv[0]);
        return 1;
    }

    std::string input_file = argv[1];
    std::string strategy_name = "pebbling";
    bool optimize = false;
    bool verbose = false;

    // Parse command-line options
    for (int i = 2; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg.substr(0, 11) == "--strategy=") {
            strategy_name = arg.substr(11);
        } else if (arg == "--optimize") {
            optimize = true;
        } else if (arg == "--verbose") {
            verbose = true;
        } else {
            std::cerr << "Unknown option: " << arg << std::endl;
            print_usage(argv[0]);
            return 1;
        }
    }

    // Read the Verilog file and create an XAG network
    mockturtle::xag_network xag;
    lorina::return_code result = lorina::read_verilog(input_file, mockturtle::verilog_reader(xag));
    xag_constant_fanin_optimization( xag );
    
    if (result != lorina::return_code::success) {
        std::cerr << "Failed to read Verilog file: " << input_file << std::endl;
        return 1;
    }
    
    if (verbose) {
        std::cout << "XAG network statistics before optimization:\n"
                  << "  Inputs: " << xag.num_pis() << "\n"
                  << "  Outputs: " << xag.num_pos() << "\n"
                  << "  Gates: " << xag.num_gates() << std::endl;
    }

    // Optimize the XAG network if requested
    if (optimize) {
        auto opt_xag = mockturtle::xag_constant_fanin_optimization(xag);
        if (verbose) {
            std::cout << "XAG network statistics after optimization:\n"
                      << "  Gates: " << opt_xag.num_gates() << " (reduced by " 
                      << (xag.num_gates() - opt_xag.num_gates()) << ")" << std::endl;
        }
        xag = opt_xag;
    }

    // Create a quantum circuit
    tweedledum::netlist<caterpillar::stg_gate> circuit;

    // Select mapping strategy based on command-line option
    if (strategy_name == "pebbling") {
        caterpillar::pebbling_mapping_strategy<
            mockturtle::xag_network, 
            caterpillar::bsat_pebble_solver<mockturtle::xag_network>
        > strategy;
        
        caterpillar::logic_network_synthesis(circuit, xag, strategy);
    } 
    else if (strategy_name == "bennett") {
        caterpillar::bennett_mapping_strategy<mockturtle::xag_network> strategy;
        caterpillar::logic_network_synthesis(circuit, xag, strategy);
    } 
    else if (strategy_name == "eager") {
        caterpillar::eager_mapping_strategy<mockturtle::xag_network> strategy;
        caterpillar::logic_network_synthesis(circuit, xag, strategy);
    } 
    else {
        std::cerr << "Unknown strategy: " << strategy_name << std::endl;
        print_usage(argv[0]);
        return 1;
    }

    int t_count = 0;
    std::ofstream gate_output("quantum_circuit_analysis.txt");
    
    // Analyze the circuit
    circuit.foreach_cgate([&](auto const& gate) {
        write_gate_types(gate.gate, gate_output);
        if (gate.gate.operation() == tweedledum::gate_set::t)
            t_count++;
    });
    
    gate_output.close();

    std::cout << "Quantum circuit statistics:"
              << "\nQubits: " << circuit.num_qubits()
              << "\nTotal gates: " << circuit.num_gates() 
              << "\nT-count: " << t_count
              << std::endl;

    return 0;
}

void write_gate_types(caterpillar::stg_gate gate, std::ofstream& gate_output) {

    switch (gate.operation()) {
        case tweedledum::gate_set::t:
            gate_output << "T-Gate" << std::endl;
            break;
        case tweedledum::gate_set::t_dagger:
            gate_output << "T-Dagger Gate" << std::endl;
            break;
        case tweedledum::gate_set::phase:
            gate_output << "Phase Gate" << std::endl;
            break;
        case tweedledum::gate_set::phase_dagger:
            gate_output << "Phase-Dagger Gate" << std::endl;
            break;
        case tweedledum::gate_set::pauli_z:
            gate_output << "Pauli-Z Gate" << std::endl;
            break;
        case tweedledum::gate_set::hadamard:
            gate_output << "Hadamard Gate" << std::endl;
            break;
        case tweedledum::gate_set::cx:
            gate_output << "CX Gate" << std::endl;
            break;
        case tweedledum::gate_set::cz:
            gate_output << "CZ Gate" << std::endl;
            break;
        case tweedledum::gate_set::mcx:
            gate_output << "MCX Gate" << std::endl;
            break;
        case tweedledum::gate_set::identity:
            gate_output << "Identity Gate" << std::endl;
            break;
        case tweedledum::gate_set::mcz:
            gate_output << "MCZ Gate" << std::endl;
            break;
        case tweedledum::gate_set::pauli_x:
            gate_output << "Pauli-X Gate" << std::endl;
            break;
        case tweedledum::gate_set::rotation_z:
            gate_output << "Rotation-Z Gate" << std::endl;
            break;
        case tweedledum::gate_set::num_defined_ops:
            gate_output << "Num Defined Ops" << std::endl;
            break;
        case tweedledum::gate_set::input:
            gate_output << "Input Gate" << std::endl;
            break;
        case tweedledum::gate_set::output:
            gate_output << "Output Gate" << std::endl;
            break;
        default:
            gate_output << "Unknown Gate" << std::endl;
            break;
    }
}

void print_usage(const char* prog_name) {
    std::cerr << "Usage: " << prog_name << " input.v output.qasm [options]\n"
              << "Options:\n"
              << "  --strategy=<name>  Synthesis strategy (pebbling, bennett, eager) [default: pebbling]\n"
              << "  --optimize         Apply XAG optimization before synthesis\n"
              << "  --verbose          Print detailed statistics\n";
}