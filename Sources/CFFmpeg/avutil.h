#include <errno.h>
#include <stddef.h>

#include <libavutil/avutil.h>
#include <libavutil/opt.h>
#include <libavutil/timestamp.h>
#include <libavutil/pixdesc.h>
#include <libavutil/imgutils.h>
#include <libavutil/channel_layout.h>

/* error handling */
static inline int swift_AVERROR(int errnum) {
    return AVERROR(errnum);
}

static inline int swift_AVUNERROR(int errnum) {
    return AVUNERROR(errnum);
}
