VVC := iverilog
VVP := vvp
GTK := gtkwave

SRC_DIR := src
SIM_DIR := sim
OUT_DIR := output

M ?= top

VVP_OUT := $(OUT_DIR)/$(M).vvp
VCD_OUT := $(M).vcd

$(VVP_OUT): $(SRC_DIR)/$(M).v $(SIM_DIR)/tb_$(M).v
	@if not exist $(OUT_DIR) mkdir $(OUT_DIR)
	@echo --- Compiling $(M) ---
	$(VVC) -o $@ $^

run: $(VVP_OUT)
	@echo --- Running simulation ---
	$(VVP) $<

all: run wave

wave:
	@if exist $(OUT_DIR)/$(M).vcd ($(GTK) $(OUT_DIR)/$(M).vcd) else ($(GTK) $(M).vcd) 

clean:
	@if exist $(OUT_DIR) rmdir /s /q $(OUT_DIR)
	@if exist *.vcd del *.vcd
	@if exist *.vvp del *.vvp

.PHONY: all run wave clean