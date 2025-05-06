#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: Term Project: BPM with SDR
# GNU Radio version: 3.10.1.1

from packaging.version import Version as StrictVersion

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print("Warning: failed to XInitThreads()")

from PyQt5 import Qt
from gnuradio import qtgui
from gnuradio.filter import firdes
import sip
from gnuradio import analog
from gnuradio import audio
from gnuradio import blocks
from gnuradio import filter
from gnuradio import gr
from gnuradio.fft import window
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import iio
from gnuradio.qtgui import Range, RangeWidget
from PyQt5 import QtCore



from gnuradio import qtgui

class TY_TermProject_ECE531(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "Term Project: BPM with SDR", catch_exceptions=True)
        Qt.QWidget.__init__(self)
        self.setWindowTitle("Term Project: BPM with SDR")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "TY_TermProject_ECE531")

        try:
            if StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
                self.restoreGeometry(self.settings.value("geometry").toByteArray())
            else:
                self.restoreGeometry(self.settings.value("geometry"))
        except:
            pass

        ##################################################
        # Variables
        ##################################################
        self.volume = volume = 700e-3
        self.sample_rate = sample_rate = 2.304e6
        self.gain_lpf = gain_lpf = 1
        self.gain_fm_demod = gain_fm_demod = 1
        self.fm_station = fm_station = 107.5e6

        ##################################################
        # Blocks
        ##################################################
        self._volume_range = Range(0, 1, 100e-3, 700e-3, 200)
        self._volume_win = RangeWidget(self._volume_range, self.set_volume, "Volume", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._volume_win)
        self._gain_lpf_range = Range(0, 50, 1, 1, 200)
        self._gain_lpf_win = RangeWidget(self._gain_lpf_range, self.set_gain_lpf, "gain_lpf", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._gain_lpf_win)
        self._gain_fm_demod_range = Range(0, 50, 1, 1, 200)
        self._gain_fm_demod_win = RangeWidget(self._gain_fm_demod_range, self.set_gain_fm_demod, "gain_fm_demod", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._gain_fm_demod_win)
        self._fm_station_range = Range(88.1e6, 107.5e6, 200e3, 107.5e6, 200)
        self._fm_station_win = RangeWidget(self._fm_station_range, self.set_fm_station, "FM Station", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._fm_station_win)
        self.qtgui_sink_x_0_0 = qtgui.sink_c(
            1024, #fftsize
            window.WIN_BLACKMAN_hARRIS, #wintype
            fm_station, #fc
            sample_rate, #bw
            'Received Spectrum', #name
            True, #plotfreq
            True, #plotwaterfall
            True, #plottime
            True, #plotconst
            None # parent
        )
        self.qtgui_sink_x_0_0.set_update_time(1.0/10)
        self._qtgui_sink_x_0_0_win = sip.wrapinstance(self.qtgui_sink_x_0_0.qwidget(), Qt.QWidget)

        self.qtgui_sink_x_0_0.enable_rf_freq(False)

        self.top_layout.addWidget(self._qtgui_sink_x_0_0_win)
        self.qtgui_sink_x_0 = qtgui.sink_f(
            1024, #fftsize
            window.WIN_BLACKMAN_hARRIS, #wintype
            fm_station, #fc
            sample_rate, #bw
            'Received FM Spectrum - Demod', #name
            True, #plotfreq
            True, #plotwaterfall
            True, #plottime
            True, #plotconst
            None # parent
        )
        self.qtgui_sink_x_0.set_update_time(1.0/10)
        self._qtgui_sink_x_0_win = sip.wrapinstance(self.qtgui_sink_x_0.qwidget(), Qt.QWidget)

        self.qtgui_sink_x_0.enable_rf_freq(False)

        self.top_layout.addWidget(self._qtgui_sink_x_0_win)
        self.low_pass_filter_0 = filter.fir_filter_ccf(
            4,
            firdes.low_pass(
                gain_lpf,
                sample_rate,
                100e3,
                48e3,
                window.WIN_HAMMING,
                6.76))
        self.iio_pluto_source_0 = iio.fmcomms2_source_fc32('usb:2.2.5' if 'usb:2.2.5' else iio.get_pluto_uri(), [True, True], 32768)
        self.iio_pluto_source_0.set_len_tag_key('packet_len')
        self.iio_pluto_source_0.set_frequency(int(fm_station))
        self.iio_pluto_source_0.set_samplerate(int(sample_rate))
        self.iio_pluto_source_0.set_gain_mode(0, 'manual')
        self.iio_pluto_source_0.set_gain(0, 64)
        self.iio_pluto_source_0.set_quadrature(True)
        self.iio_pluto_source_0.set_rfdc(True)
        self.iio_pluto_source_0.set_bbdc(True)
        self.iio_pluto_source_0.set_filter_params('Auto', '', 0, 0)
        self.blocks_multiply_const_vxx_0 = blocks.multiply_const_ff(volume)
        self.blocks_float_to_complex_0 = blocks.float_to_complex(1)
        self.blocks_file_sink_0 = blocks.file_sink(gr.sizeof_gr_complex*1, 'youshookmeallnightlong_acdc', True)
        self.blocks_file_sink_0.set_unbuffered(False)
        self.audio_sink_0 = audio.sink(48000, '', True)
        self.analog_fm_demod_cf_0 = analog.fm_demod_cf(
        	channel_rate=384e3,
        	audio_decim=12,
        	deviation=75000,
        	audio_pass=15000,
        	audio_stop=16000,
        	gain=gain_fm_demod,
        	tau=75e-6,
        )


        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_fm_demod_cf_0, 0), (self.blocks_multiply_const_vxx_0, 0))
        self.connect((self.blocks_float_to_complex_0, 0), (self.blocks_file_sink_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.audio_sink_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.blocks_float_to_complex_0, 1))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.blocks_float_to_complex_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.qtgui_sink_x_0, 0))
        self.connect((self.iio_pluto_source_0, 0), (self.low_pass_filter_0, 0))
        self.connect((self.iio_pluto_source_0, 0), (self.qtgui_sink_x_0_0, 0))
        self.connect((self.low_pass_filter_0, 0), (self.analog_fm_demod_cf_0, 0))


    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "TY_TermProject_ECE531")
        self.settings.setValue("geometry", self.saveGeometry())
        self.stop()
        self.wait()

        event.accept()

    def get_volume(self):
        return self.volume

    def set_volume(self, volume):
        self.volume = volume
        self.blocks_multiply_const_vxx_0.set_k(self.volume)

    def get_sample_rate(self):
        return self.sample_rate

    def set_sample_rate(self, sample_rate):
        self.sample_rate = sample_rate
        self.iio_pluto_source_0.set_samplerate(int(self.sample_rate))
        self.low_pass_filter_0.set_taps(firdes.low_pass(self.gain_lpf, self.sample_rate, 100e3, 48e3, window.WIN_HAMMING, 6.76))
        self.qtgui_sink_x_0.set_frequency_range(self.fm_station, self.sample_rate)
        self.qtgui_sink_x_0_0.set_frequency_range(self.fm_station, self.sample_rate)

    def get_gain_lpf(self):
        return self.gain_lpf

    def set_gain_lpf(self, gain_lpf):
        self.gain_lpf = gain_lpf
        self.low_pass_filter_0.set_taps(firdes.low_pass(self.gain_lpf, self.sample_rate, 100e3, 48e3, window.WIN_HAMMING, 6.76))

    def get_gain_fm_demod(self):
        return self.gain_fm_demod

    def set_gain_fm_demod(self, gain_fm_demod):
        self.gain_fm_demod = gain_fm_demod

    def get_fm_station(self):
        return self.fm_station

    def set_fm_station(self, fm_station):
        self.fm_station = fm_station
        self.iio_pluto_source_0.set_frequency(int(self.fm_station))
        self.qtgui_sink_x_0.set_frequency_range(self.fm_station, self.sample_rate)
        self.qtgui_sink_x_0_0.set_frequency_range(self.fm_station, self.sample_rate)




def main(top_block_cls=TY_TermProject_ECE531, options=None):

    if StrictVersion("4.5.0") <= StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls()

    tb.start()

    tb.show()

    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()

        Qt.QApplication.quit()

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    timer = Qt.QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)

    qapp.exec_()

if __name__ == '__main__':
    main()
