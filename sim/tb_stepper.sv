`timescale 1ns/1ps

module tb_stepper;
  reg clk_50mhz = 0, rst_p = 1, enable = 0, direction = 0;
  wire [3:0] stepmotor;
  integer checks = 0;

  // 50 MHz 클록 생성 (#10 = 20 ns 주기)
  always #10 clk_50mhz = ~clk_50mhz;

  // 빠른 검증을 위한 파라미터 축소 설정 (STEP_CYCLES = 8 / 2 = 4 클록)
  lab3_stepper #(
    .CLK_HZ(8),
    .STEP_HZ(2)
  ) dut (
    .clk_50mhz(clk_50mhz),
    .rst_p(rst_p),
    .enable(enable),
    .direction(direction),
    .stepmotor(stepmotor)
  );

  task check_value(input [3:0] value);
    begin
      #1;
      if (stepmotor !== value)
        $fatal(1, "got=%b expected=%b", stepmotor, value);
      checks++;
    end
  endtask

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_stepper);

    repeat(2) @(posedge clk_50mhz);
    rst_p = 0;
    check_value(4'b0011); // Check 1: 리셋 초기 상태

    // 정방향(CW, direction=0) 1주기 회전 검증
    enable = 1;
    wait(dut.enable_sync);
    wait(dut.state == 1); check_value(4'b0110); // Check 2
    wait(dut.state == 2); check_value(4'b1100); // Check 3
    wait(dut.state == 3); check_value(4'b1001); // Check 4
    wait(dut.state == 0); check_value(4'b0011); // Check 5

    // 역방향(CCW, direction=1) 2단계 회전 검증
    direction = 1;
    wait(dut.direction_sync);
    wait(dut.state == 3); check_value(4'b1001); // Check 6
    wait(dut.state == 2); check_value(4'b1100); // Check 7

    // 정지(enable=0) 및 현재 코일 여자 상태 유지 검증
    enable = 0;
    wait(!dut.enable_sync);
    repeat(12) @(posedge clk_50mhz);
    check_value(4'b1100); // Check 8

    $display("LAB3_STEPPER_PASS checks=%0d", checks);
    $finish;
  end

  initial begin
    #5000;
    $fatal(1, "timeout");
  end

endmodule