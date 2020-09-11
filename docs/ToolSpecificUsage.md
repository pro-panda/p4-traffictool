## Tool-specific Usage
* [Scapy](#scapy)
* [PcapPlusPlus](#pcapplusplus)
* [MoonGen](#moongen)
* [Wireshark (Tshark) Lua Dissector](#wireshark-tshark-lua-dissector)

## Scapy

[Scapy](https://scapy.net) is a powerful Python-based interactive packet manipulation program and library. The p4-traffictool generates code for Scapy such that your p4-defined protocol stack can be used in packet generation, packet capture, as well as parsing and dissecting packets (_on-wire_ or from a pcap file).

### Generating code for Scapy
Use the top-level script `p4-traffictool.sh` as following:
    
```    
./p4-traffictool.sh [-p4 <p4 src>] [-json <json file>] [--std {p4-14|p4-16}] [-o <dst dir>] --scapy 
```
If standard headers (Ethernet, IPv4, etc.) are detected, the user will be asked if s/he wants to use Scapy's built-in headers instead of re-defining them.

The user would also be asked to specify the length of the variable length field (if any is used). This length should be a multiple of 8 to ensure that the header is byte aligned.
A fixed length field would be produced for the current run of p4-traffictool. In order to modify this length, the user needs to rerun p4-traffictool. Note that this is a limitation of the target tool and p4-traffictool merely provides an option to choose the fixed length.


#### Generated Code
The code for Scapy would be generated in the output directory inside a subdirectory "scapy". It consists of a single Python file which contains:
  * Scapy class definitions for custom headers defined in the P4 program.
  * Scapy bindings between standard and custom headers based on the parser defined in the P4 program.
  * A list of all possible packet combinations using the defined headers.

### Integration and Usage with Scapy
1. In your Python code that uses Scapy, import the generated Python file using
    ```
    from <filename> import *
    ```

2. Then, you can generate packets using standard Scapy format. For example, if you want to generate a packet with custom P4-defined layers _foo_ and _bar_ with payload _"foobar"_ , then:
    ```
    a = Foo()/Bar()/"foobar"
    ```
    will generate the required packet.

3. Also you can access a list of possible packet combinations using the variable *possible_packets_*
4. To send packets on the wire, use the `send()` or `sendp()` methods:
    ```
    sendp(a, iface=<netdev interface>)
    ```
5. For receiving or parsing packets, simply use the standard Scapy methods and it should now be able to recognize and show the custom P4-defined layers.

## PcapPlusPlus

[PcapPlusPlus](http://seladb.github.io/PcapPlusPlus-Doc) is a multiplatform C++ network sniffing and packet parsing/crafting framework. It provides a very fast and efficient method for crafting and parsing network packets.

### Generating code for PcapPlusPlus
Use the top-level script `p4-traffictool.sh` as following:
```
./p4-traffictool.sh [-p4 <p4 src>] [-json <json file>] [--std {p4-14|p4-16}] [-o <dst dir>] --pcpp 
```
If standard headers (Ethernet, IPv4, etc.) are detected, the user will be asked if s/he wants to use PcapPlusPlus' built-in headers instead of re-defining them.

The user would also be asked to specify the length of variable length field(s) (if any is used). This length should be a multiple of 8 to ensure that the header is byte aligned.
A fixed length field would be produced for the current run of p4-traffictool. In order to modify this length, the user needs to rerun p4-traffictool. Note that this is a limitation of PcapPlusPlus and p4-traffictool merely provides an option to choose the fixed length.

#### Generated Code
The code for PcapPlusPlus would be generated in the output directory inside a subdirectory "pcapplusplus". It consists of C++ header and source file(s) defining class(es) for custom P4-defined protocol header(s). The code contains:
*  Definition of the header struct.
*  Getters and Setters for each field of the header.
*  A function named parseNextLayer which determines the next header to be parsed depending on the value of the "selector" field in the current header.

### Integration and Usage with PcapPlusPlus
1. Copy the files `uint24_t.h`,`uint40_t.h` and `uint48_t.h` present in the `templates` directory of the tool to `packet++/header` inside you PcapPlusPlus source tree. These files contain definitions for 24, 40 and 48 bit datatypes.

2. Copy the header (.h) files of custom P4-defined protocol(s) to packet++/header directory and the C++ (.cpp) files to Packet++/source directory inside your PcapPlusPlus source tree.

3. If you have used any standard PcapPlusPlus headers (e.g. Ethernet, IPv4, etc.) and if any of the new custom headers are the "next" layers, then add the new custom headers to the `parseNextLayer` function of the standard header.
   * For example, if a new custom header _foo_ appears after the Ethernet layer and is identified by etherType `0x123`, then add a new switch case inside the function `EthLayer::parseNextLayer()` in Packet++/src/EthLayer.cpp. 

4. Add the newly generated protocol(s) to the `enum ProtocolType` inside Packet++/header/ProtocolType.h. The `enum ProtocolType` specifies a separate bit for each protocol. So if the already defined last protocol in the `enum ProtocolType` has value 0x20000000, then to add a newly generated protocol _foo_, add `P4_FOO = 0x40000000` to the enum.

5. Now recompile PcapPlusPlus and also install it (if you are accessing it from a central location):
```
make clean
make all [-j4]
sudo make install
```

6. For using the new P4-defined layers in your PcapPlusPlus application", simply include the header (.h) files of the required layer(s) in your C++ program and call the constructor, getters, setters, etc. in the usual way of using PcapPlusPlus.

## MoonGen

[MoonGen](https://github.com/emmericp/MoonGen) is a Lua-based high-speed packet generator.

### Generating code for MoonGen
```
./p4-traffictool.sh [-p4 <p4 src>] [-json <json file>] [--std {p4-14|p4-16}] [-o <dst dir>] --moongen 
```
If standard headers (Ethernet, IPv4, etc.) are detected, the user will be asked if s/he wants to use MoonGen's built-in headers instead of re-defining them.

#### Generated Code
The code for MoonGen would be generated in the output directory inside a subdirectory "moongen". It consists of Lua files corresponding to each protocol (header). Each file contains:
*  Header struct definition.
*  Getters, Setters and String function for each field of the protocol.
*  A function named `resolveNextHeader` which determines the next header to be parsed depending on the value of the "selector" field in the current protocol.

### Integration and Usage with MoonGen
0. Copy the file `templates/bitfields_def.lua` to the directory `MoonGen/libmoon/lua/`. This is just a one-time requirement. This file contains struct definitions for 24, 40 and 48 bits fields.
1. Copy the newly generated protocol files (Lua files) to MoonGen/libmoon/lua/proto/    

2. If you used any default headers then add the corresponding next layer headers to the `resolveNextHeader` function of the default header.
   * Let's say you wanted to add protocol _foo_ on top of the standard UDP layer. Then you need to modify MoonGen/libmoon/lua/proto/udp.lua so that _foo_ gets recognized while parsing the UDP packet. Search for the function `resolveNextHeader` in the file udp.lua. Over that you will find a map `mapNamePort`. Add the pair `foo == udp.PORT_FOO` to the map. Here, `udp.PORT_FOO` is a constant defined in the same file (udp.lua).
    
3. In the file MoonGen/libmoon/lua/packet.lua, register the packet header combinations using the `createStack` function.
   * Say you have defined the layer _foo_ over UDP. Then inside the file packet.lua you need to define a `getFooPacket` function to generate a packet of the _foo_ protocol:
            ```
            pkt.getFooPacket = createStack("eth","ip4","udp","FOO")
            ```
4. Additional changes in MoonGen/libmoon/lua/packet.lua may also be required:
   * if the header has a length field that depends on the next layer's length, then adapt the function `packetSetLength` 
   * if the packet has a checksum, adapt `createStack` (the loop at end of function `createStack`) and `packetCalculateChecksums`

5. Add your protocol to MoonGen/libmoon/lua/proto/proto.lua so that it gets loaded : 
     ```
     proto.<protocol name> = require "proto.<file containing protocol without the .lua extension)>"
     ```
   * For example, the _foo_ protocol could be added as following:
     ```
     proto.foo = require "proto.foo"
     ```
6. Now you can run any of the examples (or otherwise scripts) in MoonGen by using the function `get<ProtoName>Packet()` instead of the usual `getUdpPacket()`.
   * For example, to get a packet of the protocol _foo_, use `getFooPacket()` which was defined in step #3 above.

## Wireshark (Tshark) Lua Dissector

### Generating code for Wireshark Lua dissector backend
```
./p4-traffictool.sh [-p4 <p4 src>] [-json <json file>] [--std {p4-14|p4-16}] [-o <dst dir>] --wireshark
```

The user would also be asked to specify the length of the variable length field (if any is used). This length should be a multiple of 8 to ensure that the header is byte aligned.
A fixed length field would be produced for the current run of p4-traffictool. In order to modify this length, the user needs to rerun p4-traffictool. Note that this is a limitation of the target tool and p4-traffictool merely provides an option to choose the fixed length.

#### Generated Code
The code for Lua dissector would be generated in the output directory inside a subdirectory "lua_dissector". It consists of lua files corresponding to each protocol. Each file contains:
*  Header struct definition
*  Table definitions for the next layers (if the current layer is not the final layer)
*  Addition of the current layer to table definition of previous layer

Apart from these, there would be a file named `init.lua` which contains the loading order of the script that needs to be followed to ensure that no conflicts arise in wireshark. 

### Integration and Usage with Wireshark (Tshark)

#### Quick short term usage
While running wireshark (or tshark) through command line just pass `-X lua_script:<path to the generated init.lua>` and you would be able to dissect the packets with your custom headers rightaway. e.g.
    ```
    wireshark -X lua_script:init.lua 
    tshark -X lua_script:init.lua -r captured_packets.pcap -Tfields -e <field_name>
    ```
The first examples shows how to open wireshark with your custom plugins imported into it.
The second example demonstrates extraction of a field values from the packets captured in a pcap file using tshark with your custom plugins enabled.

#### Long term usage
1. To register the protocol with Wireshark or Tshark you need access to the personal plugins folder of your Wireshark installation.
    To get a path to personal plugins folder open Wireshark, go to Help->About->Folders. 
    (If the given path doesn;t exist then create a plugins folder at the given path so that you can add personal plugins in the future).

2. (Recommended method) Append the contents of the init.lua file created to the init.lua file just outside your personal plugins folder 
(if it doesn't exist then copy the init.lua file at the path of your plugins folder)

    If you no longer need these plugins then simply delete this part from the init file of your wireshark

3. Another method is to simply copy these scripts in your wireshark personal plugins folder.

    That's it! Your plugins are ready to work. Restart Wireshark and open the pcap file which you wish to parse.

