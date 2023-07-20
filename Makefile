

# NOTE: This file is generated by m4! Make sure you're editing the .m4 version,
# not the generated version!

LIBAVJS_VERSION=4.1.6.0
EMCC=emcc
MINIFIER=node_modules/.bin/uglifyjs -m
OPTFLAGS=-Oz
SIMDFLAGS=-msimd128
THRFLAGS=-pthread
EFLAGS=\
	--memory-init-file 0 \
	--pre-js pre.js \
	--post-js build/post.js --extern-post-js extern-post.js \
	-s "EXPORT_NAME='LibAVFactory'" \
	-s "EXPORTED_FUNCTIONS=@build/exports.json" \
	-s "EXPORTED_RUNTIME_METHODS=['cwrap']" \
	-s MODULARIZE=1 \
	-s STACK_SIZE=1048576 \
	-s ASYNCIFY \
	-s "ASYNCIFY_IMPORTS=['libavjs_wait_reader']" \
	-s ALLOW_MEMORY_GROWTH=1

# For debugging:
#EFLAGS+=\
#	-s ASSERTIONS=2 \
#	-s STACK_OVERFLOW_CHECK=2 \
#	-s MALLOC=emmalloc-memvalidate \
#	-s SAFE_HEAP=1

all: build-default

include mk/*.mk


build-%: dist/libav-$(LIBAVJS_VERSION)-%.js
	true

dist/libav-$(LIBAVJS_VERSION)-%.js: build/libav-$(LIBAVJS_VERSION).js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.js \
	dist/libav-$(LIBAVJS_VERSION)-%.asm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.asm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.wasm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.wasm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.simd.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.simd.js \
	dist/libav-$(LIBAVJS_VERSION)-%.thr.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.thr.js \
	dist/libav-$(LIBAVJS_VERSION)-%.thrsimd.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.thrsimd.js \
	node_modules/.bin/uglifyjs
	mkdir -p dist
	sed "s/@CONFIG/$*/g ; s/@DBG//g" < $< | $(MINIFIER) > $@
	-chmod a-x dist/*.wasm

dist/libav-$(LIBAVJS_VERSION)-%.dbg.js: build/libav-$(LIBAVJS_VERSION).js
	mkdir -p dist
	sed "s/@CONFIG/$*/g ; s/@DBG/.dbg/g" < $< > $@

# General build rule for any target
# Use: buildrule(target file name, target inst name, CFLAGS)


# asm.js version

dist/libav-$(LIBAVJS_VERSION)-%.asm.js: build/ffmpeg-$(FFMPEG_VERSION)/build-base-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) -s WASM=0 \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/base/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).asm.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).asm.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )


dist/libav-$(LIBAVJS_VERSION)-%.dbg.asm.js: build/ffmpeg-$(FFMPEG_VERSION)/build-base-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) -g2 -s WASM=0 \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/base/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.asm.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.asm.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )

# wasm version with no added features

dist/libav-$(LIBAVJS_VERSION)-%.wasm.js: build/ffmpeg-$(FFMPEG_VERSION)/build-base-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS)  \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/base/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).wasm.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).wasm.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )


dist/libav-$(LIBAVJS_VERSION)-%.dbg.wasm.js: build/ffmpeg-$(FFMPEG_VERSION)/build-base-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) -gsource-map \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-base-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/base/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.wasm.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.wasm.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )

# wasm + threads

dist/libav-$(LIBAVJS_VERSION)-%.thr.js: build/ffmpeg-$(FFMPEG_VERSION)/build-thr-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) $(THRFLAGS) -sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/thr/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).thr.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).thr.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )


dist/libav-$(LIBAVJS_VERSION)-%.dbg.thr.js: build/ffmpeg-$(FFMPEG_VERSION)/build-thr-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) -gsource-map $(THRFLAGS) -sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-thr-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/thr/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.thr.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.thr.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )

# wasm + simd

dist/libav-$(LIBAVJS_VERSION)-%.simd.js: build/ffmpeg-$(FFMPEG_VERSION)/build-simd-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) $(SIMDFLAGS) \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/simd/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).simd.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).simd.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )


dist/libav-$(LIBAVJS_VERSION)-%.dbg.simd.js: build/ffmpeg-$(FFMPEG_VERSION)/build-simd-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) -gsource-map $(SIMDFLAGS) \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-simd-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/simd/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.simd.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.simd.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )

# wasm + threads + simd

dist/libav-$(LIBAVJS_VERSION)-%.thrsimd.js: build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) $(THRFLAGS) -sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency $(SIMDFLAGS) \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/thrsimd/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).thrsimd.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).thrsimd.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )


dist/libav-$(LIBAVJS_VERSION)-%.dbg.thrsimd.js: build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-%/libavformat/libavformat.a \
	build/exports.json pre.js build/post.js extern-post.js bindings.c
	mkdir -p dist
	$(EMCC) $(OPTFLAGS) $(EFLAGS) -gsource-map $(THRFLAGS) -sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency $(SIMDFLAGS) \
		-Ibuild/ffmpeg-$(FFMPEG_VERSION) -Ibuild/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*) \
		`test ! -e configs/$(*)/link-flags.txt || cat configs/$(*)/link-flags.txt` \
		bindings.c \
                `grep LIBAVJS_WITH_CLI configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo ' \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_demux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_filter.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_hw.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_mux.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_mux_init.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffmpeg_opt.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/ffprobe.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/cmdutils.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/objpool.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/opt_common.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/sync_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/fftools/thread_queue.o \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavdevice/libavdevice.a \
		'` \
                `test ! -e build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libpostproc/libpostproc.a || echo build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libpostproc/libpostproc.a` \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavformat/libavformat.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavfilter/libavfilter.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavcodec/libavcodec.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libswresample/libswresample.a \
		build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libavutil/libavutil.a \
		`grep LIBAVJS_WITH_SWSCALE configs/$(*)/link-flags.txt > /dev/null 2>&1 && echo 'build/ffmpeg-$(FFMPEG_VERSION)/build-thrsimd-$(*)/libswscale/libswscale.a'` \
		`test ! -e configs/$(*)/libs.txt || sed 's/@TARGET/thrsimd/' configs/$(*)/libs.txt` -o $(@)
	sed 's/^\/\/.*include:.*//' $(@) | cat configs/$(*)/license.js - > $(@).tmp
	mv $(@).tmp $(@)
	if [ -e dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.thrsimd.wasm.map ] ; then \
		./adjust-sourcemap.js dist/libav-$(LIBAVJS_VERSION)-$(*).dbg.thrsimd.wasm.map \
			ffmpeg $(FFMPEG_VERSION) \
			libvpx $(LIBVPX_VERSION) \
			libaom $(LIBAOM_VERSION); \
	fi || ( rm -f $(@) ; false )


build/exports.json: libav.in.js post.in.js funcs.json apply-funcs.js
	mkdir -p build dist
	./apply-funcs.js $(LIBAVJS_VERSION)

build/libav-$(LIBAVJS_VERSION).js build/post.js: build/exports.json
	touch $@

node_modules/.bin/uglifyjs:
	npm install

# Targets
build/inst/base/cflags.txt:
	mkdir -p build/inst/base
	echo -gsource-map > $@

build/inst/thr/cflags.txt:
	mkdir -p build/inst/thr
	echo $(THRFLAGS) -gsource-map > $@

build/inst/simd/cflags.txt:
	mkdir -p build/inst/simd
	echo $(SIMDFLAGS) -gsource-map > $@

build/inst/thrsimd/cflags.txt:
	mkdir -p build/inst/thrsimd
	echo $(THRFLAGS) $(SIMDFLAGS) -gsource-map > $@

release: build-default build-lite build-fat build-obsolete build-opus build-flac \
        build-opus-flac build-webm build-webm-opus-flac \
	build-mediarecorder-transcoder build-open-media build-webcodecs
	mkdir libav.js-$(LIBAVJS_VERSION)
	cp -a README.md docs libav.js-$(LIBAVJS_VERSION)/
	mkdir libav.js-$(LIBAVJS_VERSION)/dist
	for v in default lite fat obsolete opus flac opus-flac webm \
		webm-opus-flac mediarecorder-transcoder open-media webcodecs; \
	do \
		cp dist/libav-$(LIBAVJS_VERSION)-$$v.* \
			libav.js-$(LIBAVJS_VERSION)/dist; \
	done
	mkdir libav.js-$(LIBAVJS_VERSION)/sources
	for t in ffmpeg lame libaom libogg libvorbis libvpx opus; \
	do \
		$(MAKE) $$t-release; \
	done
	git archive HEAD -o libav.js-$(LIBAVJS_VERSION)/sources/libav.js.tar
	xz libav.js-$(LIBAVJS_VERSION)/sources/libav.js.tar
	zip -r libav.js-$(LIBAVJS_VERSION).zip libav.js-$(LIBAVJS_VERSION)
	rm -rf libav.js-$(LIBAVJS_VERSION)

publish:
	unzip libav.js-$(LIBAVJS_VERSION).zip
	( cd libav.js-$(LIBAVJS_VERSION) && \
	  cp ../package.json . && \
	  rm -f dist/*.dbg.* && \
	  npm publish )
	rm -rf libav.js-$(LIBAVJS_VERSION)

halfclean:
	-rm -rf dist/
	-rm -f build/exports.json build/libav-$(LIBAVJS_VERSION).js build/post.js

clean: halfclean
	-rm -rf build/inst
	-rm -rf build/opus-$(OPUS_VERSION)
	-rm -rf build/libaom-$(LIBAOM_VERSION)
	-rm -rf build/libvorbis-$(LIBVORBIS_VERSION)
	-rm -rf build/libogg-$(LIBOGG_VERSION)
	-rm -rf build/libvpx-$(LIBVPX_VERSION)
	-rm -rf build/lame-$(LAME_VERSION)
	-rm -rf build/openh264-$(OPENH264_VERSION)
	-rm -rf build/ffmpeg-$(FFMPEG_VERSION)
	-rm -rf build/x265_$(X265_VERSION)

distclean: clean
	-rm -rf build/

.PRECIOUS: \
	build/ffmpeg-$(FFMPEG_VERSION)/build-%/libavformat/libavformat.a \
	dist/libav-$(LIBAVJS_VERSION)-%.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.js \
	dist/libav-$(LIBAVJS_VERSION)-%.asm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.asm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.wasm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.wasm.js \
	dist/libav-$(LIBAVJS_VERSION)-%.thr.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.thr.js \
	dist/libav-$(LIBAVJS_VERSION)-%.simd.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.simd.js \
	dist/libav-$(LIBAVJS_VERSION)-%.thrsimd.js \
	dist/libav-$(LIBAVJS_VERSION)-%.dbg.thrsimd.js
