SPIFlashController Software Distribution
========================================
This is a SPI Flash Controller designed to brdige a basic FIFO interface 
and a SPI Flash device. The sources are relatively FPGA agnostic.

This controller has been verified in FPGA hardware with multiple
[Opal Kelly](https://www.opalkelly.com) devices.


Simulation
----------
A test fixture is provided for the controller in the Simulation folder. 
This text fixture is designed to interact with a SPI flash simulation 
model (see below). This test is intended to demonstrate usage of the SPI 
flash controller only and is not indended to be used in verification.


SPI Flash Device Simulation Models
----------------------------------
Simulation Models for Micron SPI Flash devices are used in the simulation 
of the controller. These models may be downloaded directly from Micron and 
are not included in this distribution.

License
-------
This project is released under the [MIT License](https://opensource.org/licenses/MIT).
Please see the LICENSE file for more information.
