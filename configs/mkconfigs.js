#!/usr/bin/env node
/*
 * Copyright (C) 2021-2024 Yahweasel and contributors
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

const cproc = require("child_process");
const fs = require("fs");

const opus = ["parser-opus", "codec-libopus"];
const flac = ["format-flac", "parser-flac", "codec-flac"];
const mp3 = ["format-mp3", "decoder-mp3", "encoder-libmp3lame"];
const vp8 = ["parser-vp8", "codec-libvpx_vp8"];
const vp9 = ["parser-vp9", "codec-libvpx_vp9"];
// Hopefully, a faster AV1 encoder will become an option soon...
const aomav1 = ["parser-av1", "codec-libaom_av1"];
const aomsvtav1 = ["parser-av1", "decoder-libaom_av1", "encoder-libsvtav1"];

// Misanthropic Patent Extortion Gang (formats/codecs by reprobates)
const aac = ["parser-aac", "codec-aac"];
const h264 = ["parser-h264", "decoder-h264", "codec-libopenh264"];
const hevc = ["parser-hevc", "decoder-hevc"];

const configsRaw = [
    // Audio sensible:
    ["default", [
        "format-ogg", "format-webm",
        opus, flac, "format-wav",
        "audio-filters"
    ], {cli: true}],

    ["opus", ["format-ogg", "format-webm", opus], {af: true}],
    ["flac", ["format-ogg", flac], {af: true}],
    ["wav", ["format-wav"], {af: true}],

    // Audio silly:
    ["obsolete", [
        // Modern:
        "format-ogg", "format-webm",
        opus, flac,

        // Timeless:
        "format-wav",

        // Obsolete:
        "codec-libvorbis", mp3,

        // (and filters)
        "audio-filters"
    ]],

    // Audio reprobate:
    ["aac", ["format-mp4", "format-aac", "format-webm", aac], {af: true}],

    // Video sensible:
    ["webm", [
        "format-ogg", "format-webm",
        opus, flac, "format-wav",
        "audio-filters",

        "libvpx", vp8,
        "swscale", "video-filters"
    ], {vp9: true, cli: true}],

    ["vp8-opus", ["format-ogg", "format-webm", opus, "libvpx", vp8], {avf: true}],
    ["vp9-opus", ["format-ogg", "format-webm", opus, "libvpx", vp9], {avf: true}],
    ["av1-opus", ["format-ogg", "format-webm", opus, aomav1], {avf: true}],

    // Video reprobate:
    ["h264-aac", ["format-mp4", "format-aac", "format-webm", aac, h264], {avf: true}],
    ["hevc-aac", ["format-mp4", "format-aac", "format-webm", aac, hevc], {avf: true}],

    // Mostly parsing:
    ["webcodecs", [
        "format-ogg", "format-webm", "format-mp4",
        opus, flac, "format-wav",
        "parser-aac",

        "parser-vp8", "parser-vp9", "parser-av1",
        "parser-h264", "parser-hevc",

        "bsf-extract_extradata",
        "bsf-vp9_metadata", "bsf-av1_metadata",
        "bsf-h264_metadata", "bsf-hevc_metadata"
    ], {avf: true}],

    // These are here so that "all" will have them for testing
    ["extras", [
        // Images
        "format-image2", "demuxer-image_gif_pipe", "demuxer-image_jpeg_pipe",
        "demuxer-image_png_pipe",
        "parser-gif", "codec-gif", "parser-mjpeg",
        "codec-mjpeg", "parser-png", "codec-png", "parser-webp", "decoder-webp",

        // Raw data
        "format-rawvideo", "codec-rawvideo",
        "format-pcm_f32le", "codec-pcm_f32le",

        // Apple-flavored lossless
        "codec-alac", "codec-prores", "codec-qtrle",

        // HLS
        "format-hls", "protocol-jsfetch"
    ]],

    ["fat", [
        'fat-build',
        ...makefflines(`protocol`, 'async,crypto,file,http,ipns_gateway,librtmpe,libsrt,mmst,rtmps,sctp,tls,bluray,data,ftp,httpproxy,jsfetch,librtmps,libssh,pipe,rtmpt,srtp,udp,cache,fd,gopher,https,libamqp,librtmpt,libzmq,prompeg,rtmpte,subfile,udplite,concat,ffrtmpcrypt,gophers,icecast,librist,librtmpte,md5,rtmp,rtmpts,tcp,unix,concatf,ffrtmphttp,hls,ipfs_gateway,librtmp,libsmbclient,mmsh,rtmpe,rtp,tee'),
        // `format-*`,
        ...makefflines(`demuxer`, 'aa,asf_o,data,g722,image_gem_pipe,ipmovie,mm,oma,realtext,sol,vobsub,aac,ass,daud,g723_1,image_gif_pipe,ipu,mmf,osq,redspark,sox,voc,aax,ast,dcstr,g726,image_hdr_pipe,ircam,mods,paf,rka,spdif,vpk,ac3,au,derf,g726le,image_j2k_pipe,iss,moflex,pcm_alaw,rl2,srt,vplayer,ac4,av1,dfa,g729,image_jpeg_pipe,iv8,mov,pcm_f32be,rm,stl,vqf,ace,avi,dfpwm,gdv,image_jpegls_pipe,ivf,mp3,pcm_f32le,roq,str,vvc,acm,avisynth,dhav,genh,image_jpegxl_pipe,ivr,mpc,pcm_f64be,rpl,subviewer,w64,act,avr,dirac,gif,image_pam_pipe,jacosub,mpc8,pcm_f64le,rsd,subviewer1,wady,adf,avs,dnxhd,gsm,image_pbm_pipe,jpegxl_anim,mpegps,pcm_mulaw,rso,sup,wav,adp,avs2,dsf,gxf,image_pcx_pipe,jv,mpegts,pcm_s16be,rtp,svag,wavarc,ads,avs3,dsicin,h261,image_pfm_pipe,kux,mpegtsraw,pcm_s16le,rtsp,svs,wc3,adx,bethsoftvid,dss,h263,image_pgm_pipe,kvag,mpegvideo,pcm_s24be,s337m,swf,webm_dash_manifest,aea,bfi,dts,h264,image_pgmyuv_pipe,laf,mpjpeg,pcm_s24le,sami,tak,webvtt,afc,bfstm,dtshd,hca,image_pgx_pipe,libgme,mpl2,pcm_s32be,sap,tedcaptions,wsaud,aiff,bink,dv,hcom,image_phm_pipe,libmodplug,mpsub,pcm_s32le,sbc,thp,wsd,aix,binka,dvbsub,hevc,image_photocd_pipe,libopenmpt,msf,pcm_s8,sbg,threedostr,wsvqa,alp,bintext,dvbtxt,hls,image_pictor_pipe,live_flv,msnwc_tcp,pcm_u16be,scc,tiertexseq,wtv,amr,bit,dxa,hnm,image_png_pipe,lmlm4,msp,pcm_u16le,scd,tmv,wv,amrnb,bitpacked,ea,ico,image_ppm_pipe,loas,mtaf,pcm_u24be,sdns,truehd,wve,amrwb,bmv,ea_cdata,idcin,image_psd_pipe,lrc,mtv,pcm_u24le,sdp,tta,xa,anm,boa,eac3,idf,image_qdraw_pipe,luodat,musx,pcm_u32be,sdr2,tty,xbin,apac,bonk,epaf,iff,image_qoi_pipe,lvf,mv,pcm_u32le,sds,txd,xmd,apc,brstm,evc,ifv,image_sgi_pipe,lxf,mvi,pcm_u8,sdx,ty,xmv,ape,c93,ffmetadata,ilbc,image_sunrast_pipe,m4v,mxf,pcm_vidc,segafilm,usm,xvag,apm,caf,filmstrip,image2,image_svg_pipe,matroska,mxg,pdv,ser,v210,xwma,apng,cavsvideo,fits,image2_alias_pix,image_tiff_pipe,mca,nc,pjs,sga,v210x,yop,aptx,cdg,flac,image2_brender_pix,image_vbn_pipe,mcc,nistsphere,pmp,shorten,vag,yuv4mpegpipe,aptx_hd,cdxl,flic,image2pipe,image_webp_pipe,mgsts,nsp,pp_bnk,siff,vapoursynth,aqtitle,cine,flv,image_bmp_pipe,image_xbm_pipe,microdvd,nsv,pva,simbiosis_imx,vc1,argo_asf,codec2,fourxm,image_cri_pipe,image_xpm_pipe,mjpeg,nut,pvf,sln,vc1t,argo_brp,codec2raw,frm,image_dds_pipe,image_xwd_pipe,mjpeg_2000,nuv,qcp,smacker,vividas,argo_cvg,concat,fsb,image_dpx_pipe,imf,mlp,obu,r3d,smjpeg,vivo,asf,dash,fwse,image_exr_pipe,ingenient,mlv,ogg,rawvideo,smush,vmd'),
        ...makefflines(`muxer`, 'a64,ass,daud,framehash,ilbc,mkvtimestamp_v2,mxf_d10,pcm_s16le,roq,streamhash,webm_chunk,ac3,ast,dfpwm,framemd5,image2,mlp,mxf_opatom,pcm_s24be,rso,sup,webm_dash_manifest,ac4,au,dirac,g722,image2pipe,mmf,null,pcm_s24le,rtp,swf,webp,adts,avi,dnxhd,g723_1,ipod,mov,nut,pcm_s32be,rtp_mpegts,tee,webvtt,adx,avif,dts,g726,ircam,mp2,obu,pcm_s32le,rtsp,tg2,wsaud,aiff,avm2,dv,g726le,ismv,mp3,oga,pcm_s8,sap,tgp,wtv,alp,avs2,eac3,gif,ivf,mp4,ogg,pcm_u16be,sbc,truehd,wv,amr,avs3,evc,gsm,jacosub,mpeg1system,ogv,pcm_u16le,scc,tta,yuv4mpegpipe,amv,bit,f4v,gxf,kvag,mpeg1vcd,oma,pcm_u24be,segafilm,ttml,apm,caf,ffmetadata,h261,latm,mpeg1video,opus,pcm_u24le,segment,uncodedframecrc,apng,cavsvideo,fifo,h263,lrc,mpeg2dvd,pcm_alaw,pcm_u32be,smjpeg,vc1,aptx,chromaprint,fifo_test,h264,m4v,mpeg2svcd,pcm_f32be,pcm_u32le,smoothstreaming,vc1t,aptx_hd,codec2,filmstrip,hash,matroska,mpeg2video,pcm_f32le,pcm_u8,sox,voc,argo_asf,codec2raw,fits,hds,matroska_audio,mpeg2vob,pcm_f64be,pcm_vidc,spdif,vvc,argo_cvg,crc,flac,hevc,md5,mpegts,pcm_f64le,psp,spx,w64,asf,dash,flv,hls,microdvd,mpjpeg,pcm_mulaw,rawvideo,srt,wav,asf_stream,data,framecrc,ico,mjpeg,mxf,pcm_s16be,rm,stream_segment,webm'),
        // `codec-*`,
        ...makefflines('decoder', 'aac,adpcm_sbpro_4,binkaudio_rdft,eamad,hdr,libspeex,mpeg4_crystalhd,pcm_s16le,ralf,tdsc,vp8_v4l2m2m,aac_at,adpcm_swf,bintext,eatgq,hevc,libuavs3d,mpeg4_cuvid,pcm_s16le_planar,rasc,text,vp9,aac_fixed,adpcm_thp,bitpacked,eatgv,hevc_cuvid,libvorbis,mpeg4_mediacodec,pcm_s24be,rawvideo,theora,vp9_cuvid,aac_latm,adpcm_thp_le,bmp,eatqi,hevc_mediacodec,libvpx_vp8,mpeg4_mmal,pcm_s24daud,realtext,thp,vp9_mediacodec,aasc,adpcm_vima,bmv_audio,eightbps,hevc_qsv,libvpx_vp9,mpeg4_v4l2m2m,pcm_s24le,rka,tiertexseqvideo,vp9_qsv,ac3,adpcm_xa,bmv_video,eightsvx_exp,hevc_rkmpp,libzvbi_teletext,mpegvideo,pcm_s24le_planar,rl2,tiff,vp9_rkmpp,ac3_at,adpcm_xmd,bonk,eightsvx_fib,hevc_v4l2m2m,loco,mpl2,pcm_s32be,roq,tmv,vp9_v4l2m2m,ac3_fixed,adpcm_yamaha,brender_pix,escape124,hnm4_video,lscr,msa1,pcm_s32le,roq_dpcm,truehd,vplayer,acelp_kelvin,adpcm_zork,c93,escape130,hq_hqa,m101,mscc,pcm_s32le_planar,rpza,truemotion1,vqa,adpcm_4xm,agm,cavs,evrc,hqx,mace3,msmpeg4_crystalhd,pcm_s64be,rscc,truemotion2,vqc,adpcm_adx,aic,cbd2_dpcm,exr,huffyuv,mace6,msmpeg4v1,pcm_s64le,rtv1,truemotion2rt,wady_dpcm,adpcm_afc,alac,ccaption,fastaudio,hymt,magicyuv,msmpeg4v2,pcm_s8,rv10,truespeech,wavarc,adpcm_agm,alac_at,cdgraphics,ffv1,iac,mdec,msmpeg4v3,pcm_s8_planar,rv20,tscc,wavpack,adpcm_aica,alias_pix,cdtoons,ffvhuff,idcin,media100,msnsiren,pcm_sga,rv30,tscc2,wbmp,adpcm_argo,als,cdxl,ffwavesynth,idf,metasound,msp2,pcm_u16be,rv40,tta,wcmv,adpcm_ct,amr_nb_at,cfhd,fic,iff_ilbm,microdvd,msrle,pcm_u16le,s302m,twinvq,webp,adpcm_dtk,amrnb,cinepak,fits,ilbc,mimic,mss1,pcm_u24be,sami,txd,webvtt,adpcm_ea,amrwb,clearvideo,flac,ilbc_at,misc4,mss2,pcm_u24le,sanm,ulti,wmalossless,adpcm_ea_maxis_xa,amv,cljr,flashsv,imc,mjpeg,msvideo1,pcm_u32be,sbc,utvideo,wmapro,adpcm_ea_r1,anm,cllc,flashsv2,imm4,mjpeg_cuvid,mszh,pcm_u32le,scpr,v210,wmav1,adpcm_ea_r2,ansi,comfortnoise,flic,imm5,mjpeg_qsv,mts2,pcm_u8,screenpresso,v210x,wmav2,adpcm_ea_r3,anull,cook,flv,indeo2,mjpegb,mv30,pcm_vidc,sdx2_dpcm,v308,wmavoice,adpcm_ea_xas,apac,cpia,fmvc,indeo3,mlp,mvc1,pcx,sga,v408,wmv1,adpcm_g722,ape,cri,fourxm,indeo4,mmvideo,mvc2,pdv,sgi,v410,wmv2,adpcm_g726,apng,cscd,fraps,indeo5,mobiclip,mvdv,pfm,sgirle,vb,wmv3,adpcm_g726le,aptx,cyuv,frwu,interplay_acm,motionpixels,mvha,pgm,sheervideo,vble,wmv3_crystalhd,adpcm_ima_acorn,aptx_hd,dca,ftr,interplay_dpcm,movtext,mwsc,pgmyuv,shorten,vbn,wmv3image,adpcm_ima_alp,arbc,dds,g2m,interplay_video,mp1,mxpeg,pgssub,simbiosis_imx,vc1,wnv1,adpcm_ima_amv,argo,derf_dpcm,g723_1,ipu,mp1_at,nellymoser,pgx,sipr,vc1_crystalhd,wrapped_avframe,adpcm_ima_apc,ass,dfa,g729,jacosub,mp1float,notchlc,phm,siren,vc1_cuvid,ws_snd1,adpcm_ima_apm,asv1,dfpwm,gdv,jpeg2000,mp2,nuv,photocd,smackaud,vc1_mmal,xan_dpcm,adpcm_ima_cunning,asv2,dirac,gem,jpegls,mp2_at,on2avc,pictor,smacker,vc1_qsv,xan_wc3,adpcm_ima_dat4,atrac1,dnxhd,gif,jv,mp2float,opus,pixlet,smc,vc1_v4l2m2m,xan_wc4,adpcm_ima_dk3,atrac3,dolby_e,gremlin_dpcm,kgv1,mp3,osq,pjs,smvjpeg,vc1image,xbin,adpcm_ima_dk4,atrac3al,dpx,gsm,kmvc,mp3_at,paf_audio,png,snow,vcr1,xbm,adpcm_ima_ea_eacs,atrac3p,dsd_lsbf,gsm_ms,lagarith,mp3adu,paf_video,ppm,sol_dpcm,vmdaudio,xface,adpcm_ima_ea_sead,atrac3pal,dsd_lsbf_planar,gsm_ms_at,libaom_av1,mp3adufloat,pam,prores,sonic,vmdvideo,xl,adpcm_ima_iss,atrac9,dsd_msbf,h261,libaribb24,mp3float,pbm,prosumer,sp5x,vmix,xma1,adpcm_ima_moflex,aura,dsd_msbf_planar,h263,libaribcaption,mp3on4,pcm_alaw,psd,speedhq,vmnc,xma2,adpcm_ima_mtf,aura2,dsicinaudio,h263_v4l2m2m,libcelt,mp3on4float,pcm_alaw_at,ptx,speex,vnull,xpm,adpcm_ima_oki,av1,dsicinvideo,h263i,libcodec2,mpc7,pcm_bluray,qcelp,srgc,vorbis,xsub,adpcm_ima_qt,av1_cuvid,dss_sp,h263p,libdav1d,mpc8,pcm_dvd,qdm2,srt,vp3,xwd,adpcm_ima_qt_at,av1_mediacodec,dst,h264,libdavs2,mpeg1_cuvid,pcm_f16le,qdm2_at,ssa,vp4,y41p,adpcm_ima_rad,av1_qsv,dvaudio,h264_crystalhd,libfdk_aac,mpeg1_v4l2m2m,pcm_f24le,qdmc,stl,vp5,ylc,adpcm_ima_smjpeg,avrn,dvbsub,h264_cuvid,libgsm,mpeg1video,pcm_f32be,qdmc_at,subrip,vp6,yop,adpcm_ima_ssi,avrp,dvdsub,h264_mediacodec,libgsm_ms,mpeg2_crystalhd,pcm_f32le,qdraw,subviewer,vp6a,yuv4,adpcm_ima_wav,avs,dvvideo,h264_mmal,libilbc,mpeg2_cuvid,pcm_f64be,qoi,subviewer1,vp6f,zero12v,adpcm_ima_ws,avui,dxa,h264_qsv,libjxl,mpeg2_mediacodec,pcm_f64le,qpeg,sunrast,vp7,zerocodec,adpcm_ms,ayuv,dxtory,h264_rkmpp,libopencore_amrnb,mpeg2_mmal,pcm_lxf,qtrle,svq1,vp8,zlib,adpcm_mtaf,bethsoftvid,dxv,h264_v4l2m2m,libopencore_amrwb,mpeg2_qsv,pcm_mulaw,r10k,svq3,vp8_cuvid,zmbv,adpcm_psx,bfi,eac3,hap,libopenh264,mpeg2_v4l2m2m,pcm_mulaw_at,r210,tak,vp8_mediacodec,adpcm_sbpro_2,bink,eac3_at,hca,libopus,mpeg2video,pcm_s16be,ra_144,targa,vp8_qsv,adpcm_sbpro_3,binkaudio_dct,eacmv,hcom,librsvg,mpeg4,pcm_s16be_planar,ra_288,targa_y216,vp8_rkmpp'),
        ...makefflines(`encoder`, 'a64multi,alac_at,dca,h264_mf,libgsm,libx264rgb,msmpeg4v3,pcm_s24le_planar,prores_aw,subrip,wavpack,a64multi5,alias_pix,dfpwm,h264_nvenc,libgsm_ms,libx265,msrle,pcm_s32be,prores_ks,sunrast,wbmp,aac,amv,dnxhd,h264_omx,libilbc,libxavs,msvideo1,pcm_s32le,prores_videotoolbox,svq1,webvtt,aac_at,anull,dpx,h264_qsv,libjxl,libxavs2,nellymoser,pcm_s32le_planar,qoi,targa,wmav1,aac_mf,apng,dvbsub,h264_v4l2m2m,libkvazaar,libxvid,opus,pcm_s64be,qtrle,text,wmav2,ac3,aptx,dvdsub,h264_vaapi,libmp3lame,ljpeg,pam,pcm_s64le,r10k,tiff,wmv1,ac3_fixed,aptx_hd,dvvideo,h264_videotoolbox,libopencore_amrnb,magicyuv,pbm,pcm_s8,r210,truehd,wmv2,ac3_mf,ass,eac3,hap,libopenh264,mjpeg,pcm_alaw,pcm_s8_planar,ra_144,tta,wrapped_avframe,adpcm_adx,asv1,exr,hdr,libopenjpeg,mjpeg_qsv,pcm_alaw_at,pcm_u16be,rawvideo,ttml,xbm,adpcm_argo,asv2,ffv1,hevc_amf,libopus,mjpeg_vaapi,pcm_bluray,pcm_u16le,roq,utvideo,xface,adpcm_g722,av1_amf,ffvhuff,hevc_mediacodec,librav1e,mlp,pcm_dvd,pcm_u24be,roq_dpcm,v210,xsub,adpcm_g726,av1_mediacodec,fits,hevc_mf,libshine,movtext,pcm_f32be,pcm_u24le,rpza,v308,xwd,adpcm_g726le,av1_nvenc,flac,hevc_nvenc,libspeex,mp2,pcm_f32le,pcm_u32be,rv10,v408,y41p,adpcm_ima_alp,av1_qsv,flashsv,hevc_qsv,libsvtav1,mp2fixed,pcm_f64be,pcm_u32le,rv20,v410,yuv4,adpcm_ima_amv,av1_vaapi,flashsv2,hevc_v4l2m2m,libtheora,mp3_mf,pcm_f64le,pcm_u8,s302m,vbn,zlib,adpcm_ima_apm,avrp,flv,hevc_vaapi,libtwolame,mpeg1video,pcm_mulaw,pcm_vidc,sbc,vc2,zmbv,adpcm_ima_qt,avui,g723_1,hevc_videotoolbox,libvo_amrwbenc,mpeg2_qsv,pcm_mulaw_at,pcx,sgi,vnull,adpcm_ima_ssi,ayuv,gif,huffyuv,libvorbis,mpeg2_vaapi,pcm_s16be,pfm,smc,vorbis,adpcm_ima_wav,bitpacked,h261,ilbc_at,libvpx_vp8,mpeg2video,pcm_s16be_planar,pgm,snow,vp8_mediacodec,adpcm_ima_ws,bmp,h263,jpeg2000,libvpx_vp9,mpeg4,pcm_s16le,pgmyuv,sonic,vp8_v4l2m2m,adpcm_ms,cfhd,h263_v4l2m2m,jpegls,libwebp,mpeg4_mediacodec,pcm_s16le_planar,phm,sonic_ls,vp8_vaapi,adpcm_swf,cinepak,h263p,libaom_av1,libwebp_anim,mpeg4_omx,pcm_s24be,png,speedhq,vp9_mediacodec,adpcm_yamaha,cljr,h264_amf,libcodec2,libx262,mpeg4_v4l2m2m,pcm_s24daud,ppm,srt,vp9_qsv,alac,comfortnoise,h264_mediacodec,libfdk_aac,libx264,msmpeg4v2,pcm_s24le,prores,ssa,vp9_vaapi'),
        ...makefflines(`parser`, 'aac,avs2,dca,dvbsub,g723_1,h264,misc4,opus,sipr,vp9,aac_latm,avs3,dirac,dvd_nav,g729,hdr,mjpeg,png,tak,vvc,ac3,bmp,dnxhd,dvdsub,gif,hevc,mlp,pnm,vc1,webp,adx,cavsvideo,dolby_e,evc,gsm,ipu,mpeg4video,qoi,vorbis,xbm,amr,cook,dpx,flac,h261,jpeg2000,mpegaudio,rv34,vp3,xma,av1,cri,dvaudio,ftr,h263,jpegxl,mpegvideo,sbc,vp8,xwd'),
        ...makefflines(`filter`, 'a3dscope,ametadata,atrim,colorhold,dilation,fspp,libplacebo,ocr,rubberband,sine,trim,abench,amix,avectorscope,colorize,dilation_opencl,gblur,libvmaf,ocv,sab,siti,unpremultiply,abitscope,amovie,avgblur,colorkey,displace,gblur_vulkan,libvmaf_cuda,openclsrc,scale,smartblur,unsharp,acompressor,amplify,avgblur_opencl,colorkey_opencl,dnn_classify,geq,life,oscilloscope,scale2ref,smptebars,unsharp_opencl,acontrast,amultiply,avgblur_vulkan,colorlevels,dnn_detect,gradfun,limitdiff,overlay,scale2ref_npp,smptehdbars,untile,acopy,anequalizer,avsynctest,colormap,dnn_processing,gradients,limiter,overlay_cuda,scale_cuda,sobel,uspp,acrossfade,anlmdn,axcorrelate,colormatrix,doubleweave,graphmonitor,loop,overlay_opencl,scale_npp,sobel_opencl,v360,acrossover,anlmf,azmq,colorspace,drawbox,grayworld,loudnorm,overlay_qsv,scale_qsv,sofalizer,vaguedenoiser,acrusher,anlms,backgroundkey,colorspace_cuda,drawgraph,greyedge,lowpass,overlay_vaapi,scale_vaapi,spectrumsynth,varblur,acue,anoisesrc,bandpass,colorspectrum,drawgrid,guided,lowshelf,overlay_vulkan,scale_vt,speechnorm,vectorscope,addroi,anull,bandreject,colortemperature,drawtext,haas,lumakey,owdenoise,scale_vulkan,split,vflip,adeclick,anullsink,bass,compand,drmeter,haldclut,lut,pad,scdet,spp,vflip_vulkan,adeclip,anullsrc,bbox,compensationdelay,dynaudnorm,haldclutsrc,lut1d,pad_opencl,scharr,sr,vfrdet,adecorrelate,apad,bench,concat,earwax,hdcd,lut2,pal100bars,scroll,ssim,vibrance,adelay,aperms,bilateral,convolution,ebur128,headphone,lut3d,pal75bars,segment,ssim360,vibrato,adenorm,aphasemeter,bilateral_cuda,convolution_opencl,edgedetect,hflip,lutrgb,palettegen,select,stereo3d,vidstabdetect,aderivative,aphaser,biquad,convolve,elbg,hflip_vulkan,lutyuv,paletteuse,selectivecolor,stereotools,vidstabtransform,adrawgraph,aphaseshift,bitplanenoise,copy,entropy,highpass,lv2,pan,sendcmd,stereowiden,vif,adrc,apsnr,blackdetect,coreimage,epx,highshelf,mandelbrot,perms,separatefields,streamselect,vignette,adynamicequalizer,apsyclip,blackframe,coreimagesrc,eq,hilbert,maskedclamp,perspective,setdar,subtitles,virtualbass,adynamicsmooth,apulsator,blend,corr,equalizer,histeq,maskedmax,phase,setfield,super2xsai,vmafmotion,aecho,arealtime,blend_vulkan,cover_rect,erosion,histogram,maskedmerge,photosensitivity,setparams,superequalizer,volume,aemphasis,aresample,blockdetect,crop,erosion_opencl,hqdn3d,maskedmin,pixdesctest,setpts,surround,volumedetect,aeval,areverse,blurdetect,cropdetect,estdif,hqx,maskedthreshold,pixelize,setrange,swaprect,vpp_qsv,aevalsrc,arls,bm3d,crossfeed,exposure,hstack,maskfun,pixscope,setsar,swapuv,vstack,aexciter,arnndn,boxblur,crystalizer,extractplanes,hstack_qsv,mcdeint,pp,settb,tblend,vstack_qsv,afade,asdr,boxblur_opencl,cue,extrastereo,hstack_vaapi,mcompand,pp7,sharpen_npp,telecine,vstack_vaapi,afdelaysrc,asegment,bs2b,curves,fade,hsvhold,median,premultiply,sharpness_vaapi,testsrc,w3fdif,afftdn,aselect,bwdif,datascope,feedback,hsvkey,mergeplanes,prewitt,shear,testsrc2,waveform,afftfilt,asendcmd,bwdif_cuda,dblur,fftdnoiz,hue,mestimate,prewitt_opencl,showcqt,thistogram,weave,afifo,asetnsamples,bwdif_vulkan,dcshift,fftfilt,huesaturation,metadata,procamp_vaapi,showcwt,threshold,xbr,afir,asetpts,cas,dctdnoiz,field,hwdownload,midequalizer,program_opencl,showfreqs,thumbnail,xcorrelate,afireqsrc,asetrate,ccrepack,ddagrab,fieldhint,hwmap,minterpolate,pseudocolor,showinfo,thumbnail_cuda,xfade,afirsrc,asettb,cellauto,deband,fieldmatch,hwupload,mix,psnr,showpalette,tile,xfade_opencl,aformat,ashowinfo,channelmap,deblock,fieldorder,hwupload_cuda,monochrome,pullup,showspatial,tiltshelf,xfade_vulkan,afreqshift,asidedata,channelsplit,decimate,fifo,hysteresis,morpho,qp,showspectrum,tinterlace,xmedian,afwtdn,asisdr,chorus,deconvolve,fillborders,iccdetect,movie,random,showspectrumpic,tlut2,xstack,agate,asoftclip,chromaber_vulkan,dedot,find_rect,iccgen,mpdecimate,readeia608,showvolume,tmedian,xstack_qsv,agraphmonitor,aspectralstats,chromahold,deesser,firequalizer,identity,mptestsrc,readvitc,showwaves,tmidequalizer,xstack_vaapi,ahistogram,asplit,chromakey,deflate,flanger,idet,msad,realtime,showwavespic,tmix,yadif,aiir,asr,chromakey_cuda,deflicker,flip_vulkan,il,multiply,remap,shuffleframes,tonemap,yadif_cuda,aintegral,ass,chromanr,deinterlace_qsv,flite,inflate,negate,remap_opencl,shufflepixels,tonemap_opencl,yadif_videotoolbox,ainterleave,astats,chromashift,deinterlace_vaapi,floodfill,interlace,nlmeans,removegrain,shuffleplanes,tonemap_vaapi,yaepblur,alatency,astreamselect,ciescope,dejudder,format,interleave,nlmeans_opencl,removelogo,sidechaincompress,tpad,yuvtestsrc,alimiter,asubboost,codecview,delogo,fps,join,nlmeans_vulkan,repeatfields,sidechaingate,transpose,zmq,allpass,asubcut,color,denoise_vaapi,framepack,kerndeint,nnedi,replaygain,sidedata,transpose_npp,zoneplate,allrgb,asupercut,color_vulkan,derain,framerate,kirsch,noformat,reverse,sierpinski,transpose_opencl,zoompan,allyuv,asuperpass,colorbalance,deshake,framestep,ladspa,noise,rgbashift,signalstats,transpose_vaapi,zscale,aloop,asuperstop,colorchannelmixer,deshake_opencl,freezedetect,lagfun,normalize,rgbtestsrc,signature,transpose_vt,alphaextract,atadenoise,colorchart,despill,freezeframes,latency,null,roberts,silencedetect,transpose_vulkan,alphamerge,atempo,colorcontrast,detelecine,frei0r,lenscorrection,nullsink,roberts_opencl,silenceremove,treble,amerge,atilt,colorcorrect,dialoguenhance,frei0r_src,lensfun,nullsrc,rotate,sinc,tremolo'),
        ...makefflines(`bsf`, 'aac_adtstoasc,chomp,dv_error_marker,filter_units,hapqa_extract,media100_to_mjpegb,mp3_header_decompress,null,prores_metadata,trace_headers,vp9_superframe,av1_frame_merge,dca_core,eac3_core,h264_metadata,hevc_metadata,mjpeg2jpeg,mpeg2_metadata,opus_metadata,remove_extradata,truehd_core,vp9_superframe_split,av1_frame_split,dts2pts,evc_frame_merge,h264_mp4toannexb,hevc_mp4toannexb,mjpega_dump_header,mpeg4_unpack_bframes,pcm_rechunk,setts,vp9_metadata,vvc_metadata,av1_metadata,dump_extradata,extract_extradata,h264_redundant_pps,imx_dump_header,mov2textsub,noise,pgs_frame_merge,text2movsub,vp9_raw_reorder,vvc_mp4toannexb'),
    ]]

    ["empty", []],
    ["all", null]
];
let all = Object.create(null);

function makefflines(key, str) {
    return str.split(',').map(e => `${key}-${e}`);
}

function configGroup(configs, nameExt, parts) {
    const toAdd = configs.map(config =>
        [`${config[0]}-${nameExt}`, config[1].concat(parts)]
    );
    configs.push.apply(configs, toAdd);
}

// Process the configs into groups
const configs = [];
for (const config of configsRaw) {
    const [name, inParts, extra] = config;

    // Expand the parts
    const parts = inParts ? [] : null;
    if (inParts) {
        for (const part of inParts) {
            if (part instanceof Array)
                parts.push.apply(parts, part);
            else
                parts.push(part);
        }
    }

    // Expand the extras
    const toAdd = [[name, parts]];
    if (extra && extra.vp9)
        configGroup(toAdd, "vp9", vp9);
    if (extra && extra.af)
        configGroup(toAdd, "af", ["audio-filters"]);
    if (extra && extra.avf)
        configGroup(toAdd, "avf", ["audio-filters", "swscale", "video-filters"]);
    if (extra && extra.cli)
        configGroup(toAdd, "cli", ["cli"]);

    configs.push.apply(configs, toAdd);
}

// Process arguments
let createOnes = false;
for (const arg of process.argv.slice(2)) {
    if (arg === "--create-ones")
        createOnes = true;
    else {
        console.error(`Unrecognized argument ${arg}`);
        process.exit(1);
    }
}

async function main() {
    for (let [name, config] of configs) {
        if (name !== "all" && name !== 'fat') {
            for (const fragment of config)
                all[fragment] = true;
        } else {
            config = [...new Set((config ?? []).concat(Object.keys(all)))];
        }

        const p = cproc.spawn('node', ["./mkconfig.js", name, JSON.stringify(config)], {
            stdio: "inherit"
        });
        await new Promise(res => p.on("close", res));
    }

    if (createOnes) {
        const allFragments = Object.keys(all).map(x => {
            // Split up codecs and formats
            const p = /^([^-]*)-(.*)$/.exec(x);
            if (!p)
                return [x];
            if (p[1] === "codec")
                return [`decoder-${p[2]}`, `encoder-${p[2]}`, x]
            else if (p[1] === "format")
                return [`demuxer-${p[2]}`, `muxer-${p[2]}`, x]
            else
                return [x];
        }).reduce((a, b) => a.concat(b));

        for (const fragment of allFragments) {
            // Fix fragment dependencies
            let fragments = [fragment];
            if (fragment.indexOf("libvpx") >= 0)
                fragments.unshift("libvpx");
            if (fragment === "parser-aac")
                fragments.push("parser-ac3");

            // And make the variant
            const p = cproc.spawn("./mkconfig.js", [
                `one-${fragment}`, JSON.stringify(fragments)
            ], {stdio: "inherit"});
            await new Promise(res => p.on("close", res));
        }
    }
}
main();
