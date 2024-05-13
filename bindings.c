/*
 * Copyright (C) 2019-2024 Yahweasel and contributors
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <stdio.h>
#include <string.h>

#include <malloc.h>

#ifdef __EMSCRIPTEN_PTHREADS__
#include <emscripten.h>
#include <pthread.h>
#endif

#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavfilter/avfilter.h"
#include "libavutil/avutil.h"
#include "libavutil/opt.h"
#include "libavutil/pixdesc.h"
#include "libavutil/version.h"

#define ExportField(struc, type, field) \
    type struc ## _ ## field(struc *a) { return a->field; } \
    void struc ## _ ## field ## _s(struc *a, type b) { a->field = b; }

#define ExportLongField(struc, type, field) \
    uint32_t struc ## _ ## field(struc *a) { return (uint32_t) a->field; } \
    uint32_t struc ## _ ## field ## hi(struc *a) { return (uint32_t) (a->field >> 32); } \
    void struc ## _ ## field ## _s(struc *a, uint32_t b) { a->field = b; } \
    void struc ## _ ## field ## hi_s(struc *a, uint32_t b) { a->field |= (((type) b) << 32); }

#define ExportArrayField(struc, type, field) \
    type struc ## _ ## field ## _a(struc *a, size_t c) { return a->field[c]; } \
    void struc ## _ ## field ## _a_s(struc *a, size_t c, type b) { ((type *) a->field)[c] = b; }

#define ExportRational(struc, field) \
    int struc ## _ ## field ## _num(struc *a) { \
        return a->field.num; \
    } \
    \
    int struc ## _ ## field ## _den(struc *a) { \
        return a->field.den; \
    } \
    \
    void struc ## _ ## field ## _num_s(struc *a, int b) { \
        a->field.num = b; \
    } \
    \
    void struc ## _ ## field ## _den_s(struc *a, int b) { \
        a->field.den = b; \
    } \
    \
    void struc ## _ ## field ## _s(struc *a, int n, int d) { \
        a->field.num = n; \
        a->field.den = d; \
    }

/* Either way we expose the old channel layout API, but if the new channel
 * layout API is available, we use it */
#if LIBAVUTIL_VERSION_INT > AV_VERSION_INT(57, 23, 100)
/* New API */
#define ExportChannel(struc) \
void struc ## _channel_layoutmask_s(struc *a, uint32_t bl, uint32_t bh) { \
    uint64_t mask =  (((uint64_t) bl)) | (((uint64_t) bh) << 32); \
    av_channel_layout_uninit(&a->ch_layout); \
    av_channel_layout_from_mask(&a->ch_layout, mask);\
} \
uint64_t struc ## _channel_layoutmask(struc *a) { \
    return a->ch_layout.u.mask; \
}\
int struc ## _channels(struc *a) { \
    return a->ch_layout.nb_channels; \
} \
void struc ## _channels_s(struc *a, int b) { \
    a->ch_layout.nb_channels = b; \
}\
int struc ## _ch_layout_nb_channels(struc *a) { \
    return a->ch_layout.nb_channels; \
}\
void struc ## _ch_layout_nb_channels_s(struc *a, int b) { \
    a->ch_layout.nb_channels = b; \
}\
uint32_t struc ## _channel_layout(struc *a) { \
    return (uint32_t) a->ch_layout.u.mask; \
}\
uint32_t struc ##_channel_layouthi(struc *a) { \
    return (uint32_t) (a->ch_layout.u.mask >> 32);\
}\
void struc ##_channel_layout_s(struc *a, uint32_t b) { \
    a->ch_layout.u.mask = (a->ch_layout.u.mask & (0xFFFFFFFFull << 32)) | (((uint64_t) b));\
    uint64_t mask = a->ch_layout.u.mask;\
    av_channel_layout_uninit(&a->ch_layout);\
    av_channel_layout_from_mask(&a->ch_layout, mask);\
}\
void struc ##_channel_layouthi_s(struc *a, uint32_t b) { \
    a->ch_layout.u.mask = (a->ch_layout.u.mask & 0xFFFFFFFFull) | (((uint64_t) b) << 32);\
    uint64_t mask = a->ch_layout.u.mask;\
    av_channel_layout_uninit(&a->ch_layout);\
    av_channel_layout_from_mask(&a->ch_layout, mask);\
}

#else
/* Old API */
#define ExportChannel(struc) \
void struc ## _channel_layoutmask_s(struc *a, uint32_t bl, uint32_t bh) { \
    a->channel_layout = ((uint16_t) bh << 32) | bl; \
} \
uint64_t struc ## _channel_layoutmask(struc *a) { \
    return a->channel_layout; \
}\
int struc ## _channels(struc *a) { \
    return a->channels; \
} \
void struc ## _channels_s(struc *a, int b) { \
    a->channels = b; \
}\
int struc ## _ch_layout_nb_channels(struc *a) { \
    return a->channels; \
}\
void struc ## _ch_layout_nb_channels_s(struc *a, int b) { \
    a->channels = b; \
}\
uint32_t struc ## _channel_layout(struc *a) { \
    return a->channel_layout; \
}\
uint32_t struc ##_channel_layouthi(struc *a) { \
    return a->channel_layout >> 32; \
}\
void struc ##_channel_layout_s(struc *a, uint32_t b) { \
    a->channel_layout = \
        (a->channel_layout & (0xFFFFFFFFull << 32)) | \
        ((uint64_t) b); \
}\
void struc ##_channel_layouthi_s(struc *a, uint32_t b) { \
    a->channel_layout = \
        (((uint64_t) b) << 32) | \
        (a->channel_layout & 0xFFFFFFFFull); \
}

#endif /* Channel layout API version */

/* Not part of libav, just used to ensure a round trip to C for async purposes */
void ff_nothing() {}


/****************************************************************
 * libavutil
 ***************************************************************/

/* AVFrame */
ExportField(AVFrame, size_t, crop_bottom)
ExportField(AVFrame, size_t, crop_left)
ExportField(AVFrame, size_t, crop_right)
ExportField(AVFrame, size_t, crop_top)
ExportArrayField(AVFrame, uint8_t *, data)
ExportField(AVFrame, int, format)
ExportField(AVFrame, int, height)
ExportField(AVFrame, int, key_frame)
ExportArrayField(AVFrame, int, linesize)
ExportField(AVFrame, int, nb_samples)
ExportField(AVFrame, int, pict_type)
ExportLongField(AVFrame, int64_t, pts)
ExportField(AVFrame, int, sample_rate)
ExportField(AVFrame, int, width)

ExportChannel(AVFrame)

ExportRational(AVFrame, sample_aspect_ratio)

/* AVPixFmtDescriptor */
ExportField(AVPixFmtDescriptor, uint64_t, flags)
ExportField(AVPixFmtDescriptor, uint8_t, nb_components)
ExportField(AVPixFmtDescriptor, uint8_t, log2_chroma_h)
ExportField(AVPixFmtDescriptor, uint8_t, log2_chroma_w)

int AVPixFmtDescriptor_comp_depth(AVPixFmtDescriptor *fmt, int comp)
{
    return fmt->comp[comp].depth;
}

int av_opt_set_int_list_js(void *obj, const char *name, int width, void *val, int term, int flags)
{
    switch (width) {
        case 4:
            return av_opt_set_int_list(obj, name, ((int32_t *) val), term, flags);
        case 8:
            return av_opt_set_int_list(obj, name, ((int64_t *) val), term, flags);
        default:
            return AVERROR(EINVAL);
    }
}


/****************************************************************
 * libavcodec
 ***************************************************************/

/* AVCodec */
ExportField(AVCodec, enum AVSampleFormat *, sample_fmts)
ExportArrayField(AVCodec, enum AVSampleFormat, sample_fmts)
ExportField(AVCodec, int *, supported_samplerates)
ExportArrayField(AVCodec, int, supported_samplerates)
ExportField(AVCodec, enum AVMediaType, type)

/* AVCodecContext */
ExportField(AVCodecContext, enum AVCodecID, codec_id)
ExportField(AVCodecContext, enum AVMediaType, codec_type)
ExportLongField(AVCodecContext, int64_t, bit_rate)
ExportField(AVCodecContext, uint8_t *, extradata)
ExportField(AVCodecContext, int, extradata_size)
ExportField(AVCodecContext, int, frame_size)
ExportField(AVCodecContext, int, gop_size)
ExportField(AVCodecContext, int, height)
ExportField(AVCodecContext, int, keyint_min)
ExportField(AVCodecContext, int, level)
ExportField(AVCodecContext, int, max_b_frames)
ExportField(AVCodecContext, int, pix_fmt)
ExportField(AVCodecContext, int, profile)
ExportLongField(AVCodecContext, int64_t, rc_max_rate)
ExportLongField(AVCodecContext, int64_t, rc_min_rate)
ExportField(AVCodecContext, int, sample_fmt)
ExportField(AVCodecContext, int, sample_rate)
ExportField(AVCodecContext, int, qmax)
ExportField(AVCodecContext, int, qmin)
ExportField(AVCodecContext, int, width)

ExportChannel(AVCodecContext)

ExportRational(AVCodecContext, framerate)

ExportRational(AVCodecContext, sample_aspect_ratio)

ExportRational(AVCodecContext, time_base)

/* AVCodecDescriptor */
ExportField(AVCodecDescriptor, enum AVCodecID, id)
ExportField(AVCodecDescriptor, char *, long_name)
ExportArrayField(AVCodecDescriptor, char *, mime_types)
ExportField(AVCodecDescriptor, char *, name)
ExportField(AVCodecDescriptor, int, props)
ExportField(AVCodecDescriptor, enum AVMediaType, type)

/* AVCodecParameters */
ExportField(AVCodecParameters, enum AVCodecID, codec_id)
ExportField(AVCodecParameters, uint32_t, codec_tag)
ExportField(AVCodecParameters, enum AVMediaType, codec_type)
ExportField(AVCodecParameters, uint8_t *, extradata)
ExportField(AVCodecParameters, int, extradata_size)
ExportField(AVCodecParameters, int, format)
ExportField(AVCodecParameters, int64_t, bit_rate)
ExportField(AVCodecParameters, int, profile)
ExportField(AVCodecParameters, int, level)
ExportField(AVCodecParameters, int, width)
ExportField(AVCodecParameters, int, height)
ExportField(AVCodecParameters, enum AVColorRange, color_range)
ExportField(AVCodecParameters, enum AVColorPrimaries, color_primaries)
ExportField(AVCodecParameters, enum AVColorTransferCharacteristic, color_trc)
ExportField(AVCodecParameters, enum AVColorSpace, color_space)
ExportField(AVCodecParameters, enum AVChromaLocation, chroma_location)
ExportField(AVCodecParameters, int, sample_rate)

ExportChannel(AVCodecParameters)

/* AVPacket */
ExportField(AVPacket, uint8_t *, data)
ExportLongField(AVPacket, int64_t, dts)
ExportLongField(AVPacket, int64_t, duration)
ExportField(AVPacket, int, flags)
ExportLongField(AVPacket, int64_t, pos)
ExportLongField(AVPacket, int64_t, pts)
ExportField(AVPacket, AVPacketSideData *, side_data)
ExportField(AVPacket, int, side_data_elems)
ExportField(AVPacket, int, size)
ExportField(AVPacket, int, stream_index)


/* AVPacketSideData uses special accessors because it's usually an array */
uint8_t *AVPacketSideData_data(AVPacketSideData *a, int idx) {
    return a[idx].data;
}

int AVPacketSideData_size(AVPacketSideData *a, int idx) {
    return a[idx].size;
}

enum AVPacketSideDataType AVPacketSideData_type(AVPacketSideData *a, int idx) {
    return a[idx].type;
}

int avcodec_open2_js(
    AVCodecContext *avctx, const AVCodec *codec, AVDictionary *options
) {
    return avcodec_open2(avctx, codec, &options);
}

/* Implemented as a binding so that we don't have to worry about struct copies */
void av_packet_rescale_ts_js(
    AVPacket *pkt,
    int tb_src_num, int tb_src_den,
    int tb_dst_num, int tb_dst_den
) {
    AVRational tb_src = {tb_src_num, tb_src_den},
               tb_dst = {tb_dst_num, tb_dst_den};
    av_packet_rescale_ts(pkt, tb_src, tb_dst);
}


/****************************************************************
 * avformat
 ***************************************************************/

/* AVFormatContext */
ExportField(AVFormatContext, int, flags)
ExportField(AVFormatContext, unsigned int, nb_streams)
ExportField(AVFormatContext, struct AVOutputFormat *, oformat)
ExportField(AVFormatContext, AVIOContext *, pb)
ExportArrayField(AVFormatContext, AVStream *, streams)

/* AVStream */
ExportField(AVStream, AVCodecParameters *, codecpar)
ExportField(AVStream, enum AVDiscard, discard)
ExportLongField(AVStream, int64_t, duration)

ExportRational(AVStream, time_base)

ExportRational(AVStream, avg_frame_rate)

ExportRational(AVStream, r_frame_rate)

int avformat_seek_file_min(
    AVFormatContext *s, int stream_index, int64_t ts, int flags
) {
    return avformat_seek_file(s, stream_index, ts, ts, INT64_MAX, flags);
}

int avformat_seek_file_max(
    AVFormatContext *s, int stream_index, int64_t ts, int flags
) {
    return avformat_seek_file(s, stream_index, INT64_MIN, ts, ts, flags);
}

int avformat_seek_file_approx(
    AVFormatContext *s, int stream_index, int64_t ts, int flags
) {
    return avformat_seek_file(s, stream_index, INT64_MIN, ts, INT64_MAX, flags);
}


/****************************************************************
 * avfilter
 ***************************************************************/

/* AVFilterInOut */
ExportField(AVFilterInOut, AVFilterContext *, filter_ctx)
ExportField(AVFilterInOut, char *, name)
ExportField(AVFilterInOut, AVFilterInOut *, next)
ExportField(AVFilterInOut, int, pad_idx)


/****************************************************************
 * swscale
 ***************************************************************/
int libavjs_with_swscale() {
#ifdef LIBAVJS_WITH_SWSCALE
    return 1;
#else
    return 0;
#endif
}

#ifndef LIBAVJS_WITH_SWSCALE
/* swscale isn't included, but we need the symbols */
void sws_getContext() {}
void sws_freeContext() {}
void sws_scale_frame() {}

#elif LIBAVUTIL_VERSION_INT <= AV_VERSION_INT(57, 4, 101)
/* No sws_scale_frame in this version */
void sws_scale_frame() {}

#endif


/****************************************************************
 * CLI
 ***************************************************************/
int libavjs_with_cli() {
#ifdef LIBAVJS_WITH_CLI
    return 1;
#else
    return 0;
#endif
}

#ifndef LIBAVJS_WITH_CLI
int ffmpeg_main() { return 0; }
int ffprobe_main() { return 0; }
#endif


/****************************************************************
 * Threading
 ***************************************************************/

#ifdef __EMSCRIPTEN_PTHREADS__
EM_JS(void *, libavjs_main_thread, (void *ignore), {
    // Avoid exiting the runtime so we can receive normal requests
    noExitRuntime = Module.noExitRuntime = true;

    // Hijack the event handler
    var origOnmessage = onmessage;
    onmessage = function(ev) {
        var a;

        function reply(succ, ret) {
            var transfer = [];
            if (typeof ret === "object" && ret && ret.libavjsTransfer)
                transfer = ret.libavjsTransfer;
            postMessage({
                c: "libavjs_ret",
                a: [a[0], a[1], succ, ret]
            }, transfer);
        }

        if (ev.data && ev.data.c === "libavjs_run") {
            a = ev.data.a;
            var succ = true;
            var ret;
            try {
                ret = Module[a[1]].apply(Module, a.slice(2));
            } catch (ex) {
                succ = false;
                ret = ex + "\n" + ex.stack;
            }
            if (succ && ret && ret.then) {
                ret
                    .then(function(ret) { reply(true, ret); })
                    .catch(function(ret) { reply(false, ret + "\n" + ret.stack); });
            } else {
                reply(succ, ret);
            }

        } else if (ev.data && ev.data.c === "libavjs_wait_reader") {
            var name = "" + ev.data.fd;
            var waiters = Module.ff_reader_dev_waiters[name] || [];
            delete Module.ff_reader_dev_waiters[name];
            for (var i = 0; i < waiters.length; i++)
                waiters[i]();

        } else {
            return origOnmessage.apply(this, arguments);
        }
    };

    // And indicate that we're ready
    postMessage({c: "libavjs_ready"});
});

pthread_t libavjs_create_main_thread()
{
    pthread_t ret;
    if (pthread_create(&ret, NULL, libavjs_main_thread, NULL))
        return NULL;
    return ret;
}

#else
void *libavjs_create_main_thread() { return NULL; }

#endif

/****************************************************************
 * Other bindings
 ***************************************************************/

AVFormatContext *avformat_alloc_output_context2_js(AVOutputFormat *oformat,
    const char *format_name, const char *filename)
{
    AVFormatContext *ret = NULL;
    int err = avformat_alloc_output_context2(&ret, oformat, format_name, filename);
    if (err < 0)
        fprintf(stderr, "[avformat_alloc_output_context2_js] %s\n", av_err2str(err));
    return ret;
}

AVFormatContext *avformat_open_input_js(const char *url, AVInputFormat *fmt,
    AVDictionary *options)
{
    AVFormatContext *ret = NULL;
    AVDictionary** options_p = &options;
    int err = avformat_open_input(&ret, url, fmt, options_p);
    if (err < 0)
        fprintf(stderr, "[avformat_open_input_js] %s\n", av_err2str(err));
    return ret;
}

AVIOContext *avio_open2_js(const char *url, int flags,
    const AVIOInterruptCB *int_cb, AVDictionary *options)
{
    AVIOContext *ret = NULL;
    AVDictionary** options_p = &options;
    int err = avio_open2(&ret, url, flags, int_cb, options_p);
    if (err < 0)
        fprintf(stderr, "[avio_open2_js] %s\n", av_err2str(err));
    return ret;
}

AVFilterContext *avfilter_graph_create_filter_js(const AVFilter *filt,
    const char *name, const char *args, void *opaque, AVFilterGraph *graph_ctx)
{
    AVFilterContext *ret = NULL;
    int err = avfilter_graph_create_filter(&ret, filt, name, args, opaque, graph_ctx);
    if (err < 0)
        fprintf(stderr, "[avfilter_graph_create_filter_js] %s\n", av_err2str(err));
    return ret;
}

AVDictionary *av_dict_copy_js(
    AVDictionary *dst, const AVDictionary *src, int flags
) {
    av_dict_copy(&dst, src, flags);
    return dst;
}

AVDictionary *av_dict_set_js(
    AVDictionary *pm, const char *key, const char *value, int flags
) {
    av_dict_set(&pm, key, value, flags);
    return pm;
}

int av_compare_ts_js(
    unsigned int ts_a_lo, int ts_a_hi,
    int tb_a_num, int tb_a_den,
    unsigned int ts_b_lo, int ts_b_hi,
    int tb_b_num, int tb_b_den
) {
    int64_t ts_a = (int64_t) ts_a_lo + ((int64_t) ts_a_hi << 32);
    int64_t ts_b = (int64_t) ts_b_lo + ((int64_t) ts_b_hi << 32);
    AVRational tb_a = {tb_a_num, tb_b_den},
               tb_b = {tb_b_num, tb_b_den};
    return av_compare_ts(ts_a, tb_a, ts_b, tb_b);
}


/* Errors */
#define ERR_BUF_SZ 256
static char err_buf[ERR_BUF_SZ];

char *ff_error(int err)
{
    av_strerror(err, err_buf, ERR_BUF_SZ - 1);
    return err_buf;
}

int mallinfo_uordblks()
{
    return mallinfo().uordblks;
}
