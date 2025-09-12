import numpy as np
from pynq import Overlay, allocate
from time import sleep
from pynq import DefaultIP
import logging

class MatrixMultiplierDriver:
    """
    PYNQ driver for the AXI Matrix Multiplier with Systolic Array
    
    This driver handles matrix multiplication using DMA transfers to/from
    the hardware accelerator.
    """
    
    def __init__(self, bitstream_path, array_size=5, data_width=8):
        """
        Initialize the matrix multiplier driver
        
        Args:
            bitstream_path (str): Path to the .bit file
            array_size (int): Size of the square matrices (default: 2 for 2x2)
            data_width (int): Width of each matrix element in bits (default: 8)
        """
        self.array_size = array_size
        self.data_width = data_width
        self.matrix_elements = array_size * array_size
        self.total_input_elements = 2 * self.matrix_elements  # Matrix A + Matrix B
        
        # Load overlay
        self.overlay = Overlay(bitstream_path)
        
        # Get DMA instance
        self.dma = self.overlay.axi_dma_0
        self.dma_send = self.dma.sendchannel
        self.dma_recv = self.dma.recvchannel
        
        # Get matrix multiplier instance
        # self.matrix_mult = self.overlay.AXI_MATRIX_MULTIPLIER_0
        
        # Set up logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
    def _validate_matrix(self, matrix, name):
        """Validate input matrix dimensions and data type"""
        if not isinstance(matrix, np.ndarray):
            raise ValueError(f"{name} must be a numpy array")
        
        if matrix.shape != (self.array_size, self.array_size):
            raise ValueError(f"{name} must be {self.array_size}x{self.array_size}, got {matrix.shape}")
        
        # Check data range for the specified bit width
        max_val = (1 << self.data_width) - 1
        if matrix.max() > max_val or matrix.min() < 0:
            raise ValueError(f"{name} values must be in range [0, {max_val}] for {self.data_width}-bit data")
    
    def _pack_matrices(self, matrix_a, matrix_b):
        """
        Pack two matrices into the format expected by the hardware
        
        Based on your testbench, the expected order is:
        Matrix A elements followed by Matrix B elements
        """
        # Flatten matrices in row-major order
        a_flat = matrix_a.flatten()
        b_flat = matrix_b.flatten()
        
        # Combine matrices - A first, then B
        combined = np.concatenate([a_flat, b_flat])
        
        return combined.astype(np.int32)
    
    def _unpack_result(self, output_data):
        """
        Unpack the result data into a matrix format
        
        Args:
            output_data: Raw output from DMA
            
        Returns:
            numpy array: Result matrix
        """
        # Take only the first matrix_elements values (result matrix)
        result_flat = output_data[:self.matrix_elements]
        
        # Reshape to matrix form
        result_matrix = result_flat.reshape(self.array_size, self.array_size)
        
        return result_matrix.astype(np.int32)  # Results can be negative
    
    def multiply_matrices(self, matrix_a, matrix_b, timeout=5.0):
        """
        Multiply two matrices using the hardware accelerator
        
        Args:
            matrix_a (numpy.ndarray): First matrix (array_size x array_size)
            matrix_b (numpy.ndarray): Second matrix (array_size x array_size)
            timeout (float): Timeout in seconds for DMA transfers
            
        Returns:
            numpy.ndarray: Result matrix (array_size x array_size)
        """
        # Validate inputs
        self._validate_matrix(matrix_a, "Matrix A")
        self._validate_matrix(matrix_b, "Matrix B")
        
        self.logger.info(f"Multiplying {self.array_size}x{self.array_size} matrices")
        self.logger.info(f"Matrix A:\n{matrix_a}")
        self.logger.info(f"Matrix B:\n{matrix_b}")
        
        # Allocate DMA buffers
        input_buffer = allocate(shape=(self.total_input_elements,), dtype=np.int32)
        output_buffer = allocate(shape=(self.matrix_elements,), dtype=np.int32)
        
        try:
            # Pack input data
            input_data = self._pack_matrices(matrix_a, matrix_b)
            
            # Copy to input buffer
            input_buffer[:] = input_data
            
            # Clear output buffer
            output_buffer[:] = 0
            
            self.logger.info("Starting DMA transfers...")
            
            # Start receive transfer first (important for AXI Stream)
            self.dma_recv.transfer(output_buffer)
            
            # Small delay to ensure receive is ready
            # sleep(0.001)
            
            # Start send transfer
            self.dma_send.transfer(input_buffer)
            
            # Wait for both transfers to complete
            self.logger.info("Waiting for send completion...")
            self.dma_send.wait()
            self.logger.info("Send completed")
            
            self.logger.info("Waiting for receive completion...")
            self.dma_recv.wait()
            self.logger.info("Receive completed")
            
            # Unpack result
            result_matrix = self._unpack_result(output_buffer)
            
            self.logger.info(f"Result matrix:\n{result_matrix}")
            
            return result_matrix
            
        except Exception as e:
            self.logger.error(f"Matrix multiplication failed: {e}")
            raise
        finally:
            # Clean up buffers
            del input_buffer, output_buffer
