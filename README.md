# Distributed MOESI Protocol (Verilog)

## Overview
This project implements a simplified **MOESI cache coherence protocol** for a 3-processor system using Verilog.  
Each processor has its own local cache state, and a distributed directory manages the coherence of shared memory blocks.

The design demonstrates how cache states transition across **Modified (M), Owned (O), Exclusive (E), Shared (S), and Invalid (I)** in response to read and write requests from different processors.

## Features
- Three processors (P0, P1, P2) with independent cache states  
- Full MOESI state machine (M, O, E, S, I)  
- Directory-based distributed control for each memory block  
- Handles read hits/misses, write hits/misses, invalidations, and ownership transfers  
- Testbench included with detailed scenarios  

## Design Details
- **Cache States per Processor:**  
  - `I` = Invalid  
  - `S` = Shared  
  - `E` = Exclusive  
  - `O` = Owned (dirty but shared)  
  - `M` = Modified (exclusive dirty owner)  

- **Directory Information (per memory block):**  
  - `dir_state` → current global state (M/E/S/O/I)  
  - `sharing` → bitmask of sharers  
  - `owner` → processor ID of the block owner  

- **Transitions:**  
  - **Read Miss:** First requester gets E. If another reads, both become S.  
  - **Write Hit on E:** Upgraded to M.  
  - **Write Hit on S/O:** Requester becomes M, all others invalidated.  
  - **Read While M/O Exists:** Owner moves to O, requester gets S.  
  - **Write Miss:** Requester becomes M, others invalidated.  

## Testbench Scenario
1. P0 reads → E  
2. P0 writes → M  
3. P0 writes again → stays M  
4. P1 reads → P0 O, P1 S  
5. P1 writes → P1 M, P0 invalidated  
6. P2 reads → P1 O, P2 S  
7. P2 writes → P2 M, P1 invalidated  
8. P2 writes again → stays M  
