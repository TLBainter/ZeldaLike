#include "retroBitCrush.h"

#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

using namespace godot;

static constexpr double LOWPASS_Q = 0.707;

void RetroBitCrush::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_target_rate", "rate"), &RetroBitCrush::set_target_rate);
	ClassDB::bind_method(D_METHOD("get_target_rate"), &RetroBitCrush::get_target_rate);
	ClassDB::bind_method(D_METHOD("set_bit_depth", "depth"), &RetroBitCrush::set_bit_depth);
	ClassDB::bind_method(D_METHOD("get_bit_depth"), &RetroBitCrush::get_bit_depth);
	ClassDB::bind_method(D_METHOD("set_lowpass_cutoff", "cutoff"), &RetroBitCrush::set_lowpass_cutoff);
	ClassDB::bind_method(D_METHOD("get_lowpass_cutoff"), &RetroBitCrush::get_lowpass_cutoff);

	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "target_rate", PROPERTY_HINT_RANGE, "1000,48000,1,suffix:Hz"), "set_target_rate", "get_target_rate");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "bit_depth", PROPERTY_HINT_RANGE, "2,24,1"), "set_bit_depth", "get_bit_depth");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "lowpass_cutoff", PROPERTY_HINT_RANGE, "500,20000,1,suffix:Hz"), "set_lowpass_cutoff", "get_lowpass_cutoff");
}

void RetroBitCrush::set_target_rate(double p_rate) {
	target_rate = Math::clamp(p_rate, 1000.0, 48000.0);
}

double RetroBitCrush::get_target_rate() const {
	return target_rate;
}

void RetroBitCrush::set_bit_depth(int p_depth) {
	bit_depth = Math::clamp(p_depth, 2, 24);
}

int RetroBitCrush::get_bit_depth() const {
	return bit_depth;
}

void RetroBitCrush::set_lowpass_cutoff(double p_cutoff) {
	lowpass_cutoff = Math::clamp(p_cutoff, 500.0, 20000.0);
}

double RetroBitCrush::get_lowpass_cutoff() const {
	return lowpass_cutoff;
}

Ref<AudioEffectInstance> RetroBitCrush::_instantiate() {
	Ref<RetroBitCrushInstance> ins;
	ins.instantiate();
	ins->base = Ref<RetroBitCrush>(this);
	return ins;
}

// Cutoff is capped just under Nyquist because the RBJ formula degenerates at w0 = PI.
void RetroBitCrushInstance::_update_coefficients(double p_cutoff, double p_mix_rate) {
	double cutoff = Math::min(p_cutoff, p_mix_rate * 0.49);
	double w0 = Math::TAU * cutoff / p_mix_rate;
	double cos_w0 = Math::cos(w0);
	double alpha = Math::sin(w0) / (2.0 * LOWPASS_Q);
	double a0 = 1.0 + alpha;

	b0 = ((1.0 - cos_w0) * 0.5) / a0;
	b1 = (1.0 - cos_w0) / a0;
	b2 = b0;
	a1 = (-2.0 * cos_w0) / a0;
	a2 = (1.0 - alpha) / a0;

	coeff_cutoff = p_cutoff;
	coeff_mix_rate = p_mix_rate;
}

void RetroBitCrushInstance::_process(const void *p_src_buffer, AudioFrame *p_dst_buffer, int32_t p_frame_count) {
	if (p_frame_count <= 0 || base.is_null()) {
		return;
	}

	const AudioFrame *src = static_cast<const AudioFrame *>(p_src_buffer);

	double mix_rate = AudioServer::get_singleton()->get_mix_rate();
	if (mix_rate <= 0.0) {
		mix_rate = 44100.0;
	}

	double cutoff = base->lowpass_cutoff;
	if (cutoff != coeff_cutoff || mix_rate != coeff_mix_rate) {
		_update_coefficients(cutoff, mix_rate);
	}

	double step = Math::min(base->target_rate / mix_rate, 1.0);
	double q = double(1 << (base->bit_depth - 1));

	for (int32_t i = 0; i < p_frame_count; i++) {
		double in_l = src[i].left;
		double in_r = src[i].right;

		double out_l = b0 * in_l + z1_l;
		z1_l = b1 * in_l - a1 * out_l + z2_l;
		z2_l = b2 * in_l - a2 * out_l;

		double out_r = b0 * in_r + z1_r;
		z1_r = b1 * in_r - a1 * out_r + z2_r;
		z2_r = b2 * in_r - a2 * out_r;

		phase += step;
		if (phase >= 1.0) {
			phase -= 1.0;
			held_l = Math::round(Math::clamp(out_l, -1.0, 1.0) * q) / q;
			held_r = Math::round(Math::clamp(out_r, -1.0, 1.0) * q) / q;
		}

		p_dst_buffer[i].left = float(held_l);
		p_dst_buffer[i].right = float(held_r);
	}
}
