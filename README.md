# ASM_Dynamic_Software_UART_Half_Duplex

This project demonstrates the setup and usage of a dynamic UART to 
send the hexadecimal value 0xFE twice using HTerm as the serial 
communication tool.

Project Details

- Language: AVR Assembly
- Microcontroller: AVR
- Baud Rate: User-defined
- Data Bits: 8
- Stop Bits: 1
- Serial Communication Tool: HTerm

Getting Started

1. Clone or download the repository to your local machine.
2. Configure the project for your specific AVR microcontroller.
3. Upload the code to the microcontroller.
4. Connect the microcontroller's UART pins to your computer.
5. Install and launch HTerm on your computer.
6. Configure HTerm to match the following settings:
   - Baud Rate: Same as configured in the project
   - Data Bits: 8
   - Stop Bits: 1
   - Parity: None
7. Establish a serial connection with the microcontroller in HTerm.
8. Send the hexadecimal value 0xFE two times from HTerm to the microcontroller.
9. Observe the microcontroller's response or any desired behavior.

Usage

The provided code example sets up a dynamic UART for serial communication. Modify the code to adapt it to your specific requirements, such as different baud rates or data formats. Refer to the project's assembly code and comments for detailed information on configuration and usage.

License

This project is licensed under the [MIT License](LICENSE).

