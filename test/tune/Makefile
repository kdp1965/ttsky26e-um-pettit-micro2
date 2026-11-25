# The whole tune against the model, for a few ui_in values:  make [UIS="0 5 213"]
UIS ?= 0 1 21 42 63 128 170 64 77 255
all:
	iverilog -g2012 -o tune.vvp tune.v ../../src/tt_um_pettit_micro2.v
	@for u in $(UIS); do \
	  python3 -c "import sys; sys.path.insert(0, '..'); from model import sample; open('expect.hex', 'w').write(''.join('%02x\n' % sample(t, $$u) for t in range(65536)))"; \
	  vvp -n tune.vvp +UI=$$u | grep -v finish; done
wav:
	python3 ../model.py tune_$(or $(K),0).wav $(or $(K),0)
clean:
	rm -f tune.vvp expect.hex *.wav
