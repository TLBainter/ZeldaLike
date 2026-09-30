#pragma once

#include <godot_cpp/classes/audio_effect.hpp>
#include <godot_cpp/classes/audio_effect_instance.hpp>
#include <godot_cpp/classes/audio_frame.hpp>
#include <godot_cpp/classes/ref.hpp>

namespace godot {

class RetroBitCrush : public AudioEffect {
	GDCLASS(RetroBitCrush, AudioEffect)

	friend class RetroBitCrushInstance;

	double target_rate = 11025.0;
	int bit_depth = 16;
	double lowpass_cutoff = 5500.0;

protected:
	static void _bind_methods();

public:
	void set_target_rate(double p_rate);
	double get_target_rate() const;

	void set_bit_depth(int p_depth);
	int get_bit_depth() const;

	void set_lowpass_cutoff(double p_cutoff);
	double get_lowpass_cutoff() const;

	Ref<AudioEffectInstance> _instantiate() override;
};

class RetroBitCrushInstance : public AudioEffectInstance {
	GDCLASS(RetroBitCrushInstance, AudioEffectInstance)

	friend class RetroBitCrush;

	Ref<RetroBitCrush> base;

	double b0 = 0.0;
	double b1 = 0.0;
	double b2 = 0.0;
	double a1 = 0.0;
	double a2 = 0.0;
	double coeff_cutoff = -1.0;
	double coeff_mix_rate = -1.0;

	double z1_l = 0.0;
	double z2_l = 0.0;
	double z1_r = 0.0;
	double z2_r = 0.0;

	double phase = 0.0;
	double held_l = 0.0;
	double held_r = 0.0;

	void _update_coefficients(double p_cutoff, double p_mix_rate);

protected:
	static void _bind_methods() {}

public:
	void _process(const void *p_src_buffer, AudioFrame *p_dst_buffer, int32_t p_frame_count) override;
};

} // namespace godot
