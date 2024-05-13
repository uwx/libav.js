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

#define ExportField(type, field) \
    type CurrentStruct ## _ ## field(CurrentStruct *a) { return a->field; } \
    void CurrentStruct ## _ ## field ## _s(CurrentStruct *a, type b) { a->field = b; }

#define ExportLongField(type, field) \
    uint32_t CurrentStruct ## _ ## field(CurrentStruct *a) { return (uint32_t) a->field; } \
    uint32_t CurrentStruct ## _ ## field ## hi(CurrentStruct *a) { return (uint32_t) (a->field >> 32); } \
    void CurrentStruct ## _ ## field ## _s(CurrentStruct *a, uint32_t b) { a->field = b; } \
    void CurrentStruct ## _ ## field ## hi_s(CurrentStruct *a, uint32_t b) { a->field |= (((type) b) << 32); }

#define ExportArrayField(type, field) \
    type CurrentStruct ## _ ## field ## _a(CurrentStruct *a, size_t c) { return a->field[c]; } \
    void CurrentStruct ## _ ## field ## _a_s(CurrentStruct *a, size_t c, type b) { ((type *) a->field)[c] = b; }

#define ExportRational(field) \
    int CurrentStruct##_##field##_num(CurrentStruct *a) { \
        return a->##field##.num; \
    } \
    \
    int CurrentStruct##_##field##_den(CurrentStruct *a) { \
        return a->##field##.den; \
    } \
    \
    void CurrentStruct##_##field##_num_s(CurrentStruct *a, int b) { \
        a->##field##.num = b; \
    } \
    \
    void CurrentStruct##_##field##_den_s(CurrentStruct *a, int b) { \
        a->##field##.den = b; \
    } \
    \
    void CurrentStruct##_##field##_s(CurrentStruct *a, int n, int d) { \
        a->##field##.num = n; \
        a->##field##.den = d; \
    }

/* Not part of libav, just used to ensure a round trip to C for async purposes */
void ff_nothing() {}


/****************************************************************
 * libavutil
 ***************************************************************/

/* AVFrame */
#define CurrentStruct AVFrame
#define ExportField(type, field) ExportField(AVFrame, type, field)
#define ExportLongField(type, field) ExportLongField(AVFrame, type, field)
#define ExportArrayField(type, field) ExportArrayField(AVFrame, type, field)
ExportField(size_t, crop_bottom)
ExportField(size_t, crop_left)
ExportField(size_t, crop_right)
ExportField(size_t, crop_top)
ExportArrayField(uint8_t *, data)
ExportField(int, format)
ExportField(int, height)
ExportField(int, key_frame)
ExportArrayField(int, linesize)
ExportField(int, nb_samples)
ExportField(int, pict_type)
ExportLongField(int64_t, pts)
ExportField(int, sample_rate)
ExportField(int, width)
ExportField(enum AVPictureType, pict_type)
#undef ExportField
#undef ExportLongField
#undef ExportArrayField

/* Either way we expose the old channel layout API, but if the new channel
 * layout API is available, we use it */
#if LIBAVUTIL_VERSION_INT > AV_VERSION_INT(57, 23, 100)
/* New API */
#define CHL() \
void CurrentStruct ## _channel_layoutmask_s(CurrentStruct *a, uint32_t bl, uint32_t bh) { \
    uint64_t mask =  (((uint64_t) bl)) | (((uint64_t) bh) << 32); \
    av_channel_layout_uninit(&a->ch_layout); \
    av_channel_layout_from_mask(&a->ch_layout, mask);\
} \
uint64_t CurrentStruct ## _channel_layoutmask(CurrentStruct *a) { \
    return a->ch_layout.u.mask; \
}\
int CurrentStruct ## _channels(CurrentStruct *a) { \
    return a->ch_layout.nb_channels; \
} \
void CurrentStruct ## _channels_s(CurrentStruct *a, int b) { \
    a->ch_layout.nb_channels = b; \
}\
int CurrentStruct ## _ch_layout_nb_channels(CurrentStruct *a) { \
    return a->ch_layout.nb_channels; \
}\
void CurrentStruct ## _ch_layout_nb_channels_s(CurrentStruct *a, int b) { \
    a->ch_layout.nb_channels = b; \
}\
uint32_t CurrentStruct ## _channel_layout(CurrentStruct *a) { \
    return (uint32_t) a->ch_layout.u.mask; \
}\
uint32_t CurrentStruct ##_channel_layouthi(CurrentStruct *a) { \
    return (uint32_t) (a->ch_layout.u.mask >> 32);\
}\
void CurrentStruct ##_channel_layout_s(CurrentStruct *a, uint32_t b) { \
    a->ch_layout.u.mask = (a->ch_layout.u.mask & (0xFFFFFFFFull << 32)) | (((uint64_t) b));\
    uint64_t mask = a->ch_layout.u.mask;\
    av_channel_layout_uninit(&a->ch_layout);\
    av_channel_layout_from_mask(&a->ch_layout, mask);\
}\
void CurrentStruct ##_channel_layouthi_s(CurrentStruct *a, uint32_t b) { \
    a->ch_layout.u.mask = (a->ch_layout.u.mask & 0xFFFFFFFFull) | (((uint64_t) b) << 32);\
    uint64_t mask = a->ch_layout.u.mask;\
    av_channel_layout_uninit(&a->ch_layout);\
    av_channel_layout_from_mask(&a->ch_layout, mask);\
}

#else
/* Old API */
#define CHL() \
void CurrentStruct ## _channel_layoutmask_s(CurrentStruct *a, uint32_t bl, uint32_t bh) { \
    a->channel_layout = ((uint16_t) bh << 32) | bl; \
} \
uint64_t CurrentStruct ## _channel_layoutmask(CurrentStruct *a) { \
    return a->channel_layout; \
}\
int CurrentStruct ## _channels(CurrentStruct *a) { \
    return a->channels; \
} \
void CurrentStruct ## _channels_s(CurrentStruct *a, int b) { \
    a->channels = b; \
}\
int CurrentStruct ## _ch_layout_nb_channels(CurrentStruct *a) { \
    return a->channels; \
}\
void CurrentStruct ## _ch_layout_nb_channels_s(CurrentStruct *a, int b) { \
    a->channels = b; \
}\
uint32_t CurrentStruct ## _channel_layout(CurrentStruct *a) { \
    return a->channel_layout; \
}\
uint32_t CurrentStruct ##_channel_layouthi(CurrentStruct *a) { \
    return a->channel_layout >> 32; \
}\
void CurrentStruct ##_channel_layout_s(CurrentStruct *a, uint32_t b) { \
    a->channel_layout = \
        (a->channel_layout & (0xFFFFFFFFull << 32)) | \
        ((uint64_t) b); \
}\
void CurrentStruct ##_channel_layouthi_s(CurrentStruct *a, uint32_t b) { \
    a->channel_layout = \
        (((uint64_t) b) << 32) | \
        (a->channel_layout & 0xFFFFFFFFull); \
}

#endif /* Channel layout API version */

CHL(AVFrame)

ExportRational(AVFrame, sample_aspect_ratio)

/* AVPixFmtDescriptor */
#define ExportField(type, field) ExportField(AVPixFmtDescriptor, type, field)
ExportField(uint64_t, flags)
ExportField(uint8_t, nb_components)
ExportField(uint8_t, log2_chroma_h)
ExportField(uint8_t, log2_chroma_w)
#undef ExportField

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
#define ExportField(type, field) ExportField(AVCodec, type, field)
#define ExportArrayField(type, field) ExportArrayField(AVCodec, type, field)
ExportField(enum AVSampleFormat *, sample_fmts)
ExportArrayField(enum AVSampleFormat, sample_fmts)
ExportField(int *, supported_samplerates)
ExportArrayField(int, supported_samplerates)
ExportField(enum AVMediaType, type)
#undef ExportField
#undef ExportArrayField

/* AVCodecContext */
#define ExportField(type, field) ExportField(AVCodecContext, type, field)
#define ExportLongField(type, field) ExportLongField(AVCodecContext, type, field)
ExportField(enum AVCodecID, codec_id)
ExportField(enum AVMediaType, codec_type)
ExportLongField(int64_t, bit_rate)
ExportField(uint8_t *, extradata)
ExportField(int, extradata_size)
ExportField(int, frame_size)
ExportField(int, gop_size)
ExportField(int, height)
ExportField(int, keyint_min)
ExportField(int, level)
ExportField(int, max_b_frames)
ExportField(int, pix_fmt)
ExportField(int, profile)
ExportLongField(int64_t, rc_max_rate)
ExportLongField(int64_t, rc_min_rate)
ExportField(int, sample_fmt)
ExportField(int, sample_rate)
ExportField(int, qmax)
ExportField(int, qmin)
ExportField(int, width)
#undef ExportField
#undef ExportLongField

CHL(AVCodecContext)

ExportRational(AVCodecContext, framerate)

ExportRational(AVCodecContext, sample_aspect_ratio)

ExportRational(AVCodecContext, time_base)

/* AVCodecDescriptor */
#define ExportField(type, field) ExportField(AVCodecDescriptor, type, field)
ExportField(enum AVCodecID, id)
ExportField(char *, long_name)
ExportArrayField(AVCodecDescriptor, char *, mime_types)
ExportField(char *, name)
ExportField(int, props)
ExportField(enum AVMediaType, type)
#undef ExportField

/* AVCodecParameters */
#define ExportField(type, field) ExportField(AVCodecParameters, type, field)
ExportField(enum AVCodecID, codec_id)
ExportField(uint32_t, codec_tag)
ExportField(enum AVMediaType, codec_type)
ExportField(uint8_t *, extradata)
ExportField(int, extradata_size)
ExportField(int, format)
ExportField(int64_t, bit_rate)
ExportField(int, profile)
ExportField(int, level)
ExportField(int, width)
ExportField(int, height)
ExportField(enum AVColorRange, color_range)
ExportField(enum AVColorPrimaries, color_primaries)
ExportField(enum AVColorTransferCharacteristic, color_trc)
ExportField(enum AVColorSpace, color_space)
ExportField(enum AVChromaLocation, chroma_location)
ExportField(int, sample_rate)
#undef ExportField

CHL(AVCodecParameters)
#undef CHL

/* AVPacket */
#define ExportField(type, field) ExportField(AVPacket, type, field)
#define ExportLongField(type, field) ExportLongField(AVPacket, type, field)
ExportField(uint8_t *, data)
ExportLongField(int64_t, dts)
ExportLongField(int64_t, duration)
ExportField(int, flags)
ExportLongField(int64_t, pos)
ExportLongField(int64_t, pts)
ExportField(AVPacketSideData *, side_data)
ExportField(int, side_data_elems)
ExportField(int, size)
ExportField(int, stream_index)
#undef ExportField
#undef ExportLongField


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
#define ExportField(type, field) ExportField(AVFormatContext, type, field)
#define ExportArrayField(type, field) ExportArrayField(AVFormatContext, type, field)
ExportField(int, flags)
ExportField(unsigned int, nb_streams)
ExportField(struct AVOutputFormat *, oformat)
ExportField(AVIOContext *, pb)
ExportArrayField(AVStream *, streams)
#undef ExportField
#undef ExportArrayField

/* AVStream */
#define ExportField(type, field) ExportField(AVStream, type, field)
#define ExportLongField(type, field) ExportLongField(AVStream, type, field)
ExportField(AVCodecParameters *, codecpar)
ExportField(enum AVDiscard, discard)
ExportLongField(int64_t, duration)
#undef ExportField
#undef ExportLongField

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
#define ExportField(type, field) ExportField(AVFilterInOut, type, field)
ExportField(AVFilterContext *, filter_ctx)
ExportField(char *, name)
ExportField(AVFilterInOut *, next)
ExportField(int, pad_idx)
#undef ExportField


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
