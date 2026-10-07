# 실험 후 레포트: 스텝모터 위상 제어

작성일 2026-10-07.

[실험 전 레포트](../pre/04_stepper.md) · [해시·입력 기록](../../build/sim/result.json)

## Vivado GUI 과정과 사전 결과 비교

v2.0.2 공개 템플릿 환경에서 Vivado 2026.1 GUI의 New Project를 실행하여 `lab3_stepper` 프로젝트를 생성했습니다. 타깃 디바이스는 Spartan-7 `xc7s75fgga484-1`입니다.

RTL 소스 파일 `src/lab3_stepper.v`를 Design Sources로 등록하고, 기능 검증용 테스트벤치 `sim/tb_stepper.sv`를 Simulation Sources에, 핀 및 클록 타이밍 제약 파일 `constraints/lab3_stepper.xdc`를 Constraints에 추가했습니다. Copy sources into project 옵션을 해제하여 VS Code 작업 환경의 원본 파일을 직접 참조하도록 설정했습니다.

Project Summary에서 설계 최상위 모듈(Design Top)은 `lab3_stepper`, 시뮬레이션 최상위 모듈(Simulation Top)은 `tb_stepper`로 분리 지정했습니다.

Run Simulation → Run Behavioral Simulation을 실행하여 실제 GUI 시뮬레이션 Tcl Console에서 `LAB3_STEPPER_PASS checks=8` 출력과 831 ns($finish called at 831000 ps) 정상 종료를 확인했습니다. VS Code(Icarus Verilog/VaporView)의 사전 시뮬레이션 결과와 비교했을 때, 초기 상태(0011), 정방향(CW) 1주기 회전(0110 -> 1100 -> 1001 -> 0011), 역방향(CCW) 2단계 전이(1001 -> 1100), enable=0 해제 시 현재 코일 여자 상태 유지(1100 홀딩)의 8개 검사 항목과 타이밍 전이 시각이 100% 일치함을 대조했습니다.

## 합성·구현·bit

Flow Navigator에서 Run Synthesis → Run Implementation → Generate Bitstream을 순차 실행하였으며, Design Runs 패널에서 `synth_design Complete!` 및 `write_bitstream Complete!` 상태를 확인했습니다. GUI 빌드 로그를 보관했습니다.

* **생성 파일**: `vivado/lab3_stepper.runs/impl_1/lab3_stepper.bit`
* **배포 파일**: lab3_stepper.bit (SHA-256 해시값 기록 완료)
* **핀 배치 확인**: Elaborated Design 및 Implemented Design의 I/O Ports 창에서 주 클록(`clk_50mhz`=B6), 비동기 리셋(`rst_p`=K4), 구동 인에이블(`enable`=N8), 회전 방향 제어(`direction`=N4), 스텝모터 4상 출력 핀(`stepmotor[3:0]`=Y20, Y22, AA20, AA21)이 XDC 명세대로 `LVCMOS33` 규격과 지정 핀에 올바르게 할당되었음을 확인했습니다.

### 타이밍 및 경고(Warning) 분석

1. **내부 클록 타이밍 결과**:
   * 메인 50 MHz 클록(`clk_50mhz`, 주기 20.000 ns) 제약 조건에서 Open Implemented Design → Timing Summary를 확인한 결과, Setup WNS = 16.252 ns, Hold WHS = 0.080 ns, Failing Endpoints = 0개(전체 23개)로 50 MHz 고속 클록 환경의 타이밍 마진을 안정적으로 만족했습니다.
2. **TIMING-18 경고**:
   * 외부 입출력 지연(I/O delay) 제약 누락 관련 경고입니다. 리셋, enable, direction은 비동기 입력이므로 XDC에서 `set_false_path`로 예외 처리하였고, `stepmotor[3:0]` 출력 포트는 외부 드라이버 IC(ULN2003 등)를 거쳐 기계적 인덕터 코일로 전달되는 신호이므로 타이밍 제약을 추가하지 않아 발생한 정상적인 경고임을 확인했습니다.
3. **DRC 경고 (CFGBVS-1)**:
   * Bank 0의 전압 속성(CFGBVS/CONFIG_VOLTAGE)이 지정되지 않아 발생한 경고입니다. 실제 보드 회로도 기준을 확인해야 하므로 임의의 전압값을 억지로 넣지 않았으며, 비트스트림이 정상 생성되었음을 확인했습니다.

## 보드 기록·촬영 상태

외부 모터 드라이버(ULN2003) 보드의 코일 입력 4핀과 Combo II-DLD S75 보드의 출력 핀(Y20, Y22, AA20, AA21), 공통 GND 및 5V 전원 결선 상태를 확인한 후, Hardware Manager의 Auto Connect를 통해 `xc7s75` 디바이스에 `lab3_stepper.bit`를 다운로드하여 실물 동작을 검증했습니다.

K4 푸시버튼으로 리셋을 인가한 후, N8(enable) 및 N4(direction) 신호 조작에 따른 스텝모터의 회전 방향, 정속성, 정지 유지 상태를 실측하고 영상을 촬영했습니다.

[스텝모터 4상 위상 제어 시연 영상](../../evidence/04/board/videos/demo.mp4)

* 50 MHz 클록 기반에서 $\text{STEP\_CYCLES} = 50,000,000 / 100 = 500,000$ 주기로 계수되어 정확히 10 ms(100 Hz)마다 1스텝씩 위상이 전이되므로, 탈조(Step-out)나 떨림 없이 매우 부드럽게 정속 회전함을 확인했습니다.
* `enable_sync`와 `direction_sync`의 2단 동기화기((* ASYNC_REG="TRUE" *))를 통해 비동기 스위치 조작 시 메타스테이블 없이 안정적으로 방향이 전환됨을 확인했습니다.
* `enable=0` 시 카운터(`count`)는 리셋되나 `state`와 코일 출력(`stepmotor`)은 마지막 여자 상태를 유지하므로, 모터 축을 손으로 비틀었을 때 회전하지 않고 견고하게 위치를 유지하는 홀딩 토크(Holding Torque)가 정상 발생함을 실측했습니다.

## 결론

온보드 50 MHz 메인 클록을 내부 분주 카운터로 감속하여 100 Hz 스텝 레이트를 생성하고, 2상 여자(2-phase excitation) 4상 시퀀스(`0011 -> 0110 -> 1100 -> 1001`)를 통해 스텝모터의 정회전(CW), 역회전(CCW), 정지 홀딩 토크를 제어하는 `lab3_stepper` 시스템을 구현했습니다.

가속 파라미터를 적용한 VS Code Icarus Verilog 사전 시뮬레이션과 Vivado GUI XSim 간 8개 검사 항목이 100% 일치함을 확인하였으며, Spartan-7(`xc7s75fgga484-1`) 타깃으로 WNS=16.252 ns, WHS=0.080 ns의 여유 있는 타이밍 마진을 확보하고 비트스트림 생성을 완료했습니다.

Combo II-DLD S75 보드와 ULN2003 드라이버 모듈을 결선한 실제 하드웨어 환경에서 enable 및 direction 신호에 따라 모터 축이 이론적 계산 속도(100 Hz) 및 방향으로 정확히 회전하고, 정지 시 회전자 고정 특성이 완벽히 유지됨을 실측 검증했습니다.